close all
clear
clc

fpath = mfilename('fullpath');
rerfPath = fpath(1:strfind(fpath,'RandomerForest')-1);

rng(1);

load Sparse_parity_vary_n_data
load Random_matrix_adjustment_factor

Classifiers = {'rf' 'rerf' 'frc'};

for j = 1:length(ps)
    p = ps(j);
    fprintf('p = %d\n',p)
      
    if p <= 5
        mtrys = [1:p ceil(p.^[1.5 2])];
    elseif p > 5 && p <= 20
        mtrys = ceil(p.^[1/4 1/2 3/4 1 1.5 2]);
    else
        mtrys = [ceil(p.^[1/4 1/2 3/4 1]) 10*p 20*p];
    end
    mtrys_rf = mtrys(mtrys<=p);
    
    for i = 1:length(ns{j})
        fprintf('n = %d\n',ns{j}(i))

        for c = 1:length(Classifiers)
            fprintf('%s start\n',Classifiers{c})
            
            Params{i,j}.(Classifiers{c}).nTrees = 499;
            Params{i,j}.(Classifiers{c}).Stratified = true;
            Params{i,j}.(Classifiers{c}).NWorkers = 16;
            if strcmp(Classifiers{c},'rfr') || strcmp(Classifiers{c},...
                    'rerfr') || strcmp(Classifiers{c},'frcr') || ...
                    strcmp(Classifiers{c},'rr_rfr')
                Params{i,j}.(Classifiers{c}).Rescale = 'rank';
            elseif strcmp(Classifiers{c},'rfn') || strcmp(Classifiers{c},...
                    'rerfn') || strcmp(Classifiers{c},'frcn') || ...
                    strcmp(Classifiers{c},'rr_rfn')
                Params{i,j}.(Classifiers{c}).Rescale = 'normalize';
            elseif strcmp(Classifiers{c},'rfz') || strcmp(Classifiers{c},...
                    'rerfz') || strcmp(Classifiers{c},'frcz') || ...
                    strcmp(Classifiers{c},'rr_rfz')
                Params{i,j}.(Classifiers{c}).Rescale = 'zscore';
            else
                Params{i,j}.(Classifiers{c}).Rescale = 'off';
            end
            if strcmp(Classifiers{c},'rerfd')
                Params{i,j}.(Classifiers{c}).mdiff = 'node';
            else
                Params{i,j}.(Classifiers{c}).mdiff = 'off';
            end
            if strcmp(Classifiers{c},'rf') || strcmp(Classifiers{c},'rfr')...
                    || strcmp(Classifiers{c},'rfn') || strcmp(Classifiers{c},'rfz') || ...
                    strcmp(Classifiers{c},'rr_rf') || strcmp(Classifiers{c},'rr_rfr') || ...
                    strcmp(Classifiers{c},'rr_rfn') || strcmp(Classifiers{c},'rr_rfz')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'rf';
                Params{i,j}.(Classifiers{c}).d = mtrys_rf;
            elseif strcmp(Classifiers{c},'rerf') || strcmp(Classifiers{c},'rerfr')...
                    || strcmp(Classifiers{c},'rerfn') || strcmp(Classifiers{c},'rerfz') || ...
                    strcmp(Classifiers{c},'rerfd')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'sparse-adjusted';
                Params{i,j}.(Classifiers{c}).d = mtrys;
                for k = 1:length(Params{i,j}.(Classifiers{c}).d)
                    Params{i,j}.(Classifiers{c}).dprime(k) = ...
                        ceil(Params{i,j}.(Classifiers{c}).d(k)^(1/interp1(dims,...
                        slope,p)));
                end
            elseif strcmp(Classifiers{c},'frc') || strcmp(Classifiers{c},'frcr') || ...
                    strcmp(Classifiers{c},'frcn') || strcmp(Classifiers{c},'frcz')
                Params{i,j}.(Classifiers{c}).ForestMethod = 'frc';
                Params{i,j}.(Classifiers{c}).d = mtrys;
                Params{i,j}.(Classifiers{c}).nmix = 2:min(p,6);
            end
            if strcmp(Classifiers{c},'rr_rf') || strcmp(Classifiers{c},'rr_rfr') || ...
                    strcmp(Classifiers{c},'rr_rfn') || strcmp(Classifiers{c},'rr_rfz')
                Params{i,j}.(Classifiers{c}).Rotate = true;
            end

        if strcmp(Classifiers{c},'frc')
            OOBError{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).nmix));
            OOBAUC{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).nmix));
            TrainTime{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d)*length(Params{i,j}.(Classifiers{c}).nmix));
        else
            OOBError{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
            OOBAUC{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
            TrainTime{i,j}.(Classifiers{c}) = NaN(ntrials,length(Params{i,j}.(Classifiers{c}).d));
        end

            for trial = 1:ntrials
                fprintf('Trial %d\n',trial)

                % train classifier
                poolobj = gcp('nocreate');
                if isempty(poolobj)
                    parpool('local',Params{i,j}.(Classifiers{c}).NWorkers,...
                        'IdleTimeout',360);
                end

                [Forest,~,TrainTime{i,j}.(Classifiers{c})(trial,:)] = ...
                    RerF_train(Xtrain{i,j}(:,:,trial),...
                    Ytrain{i,j}(:,trial),Params{i,j}.(Classifiers{c}));

                % select best hyperparameter

                for k = 1:length(Forest)
                    Scores = rerf_oob_classprob(Forest{k},...
                        Xtrain{i,j}(:,:,trial),'last');
                    Predictions = predict_class(Scores,Forest{k}.classname);
                    OOBError{i,j}.(Classifiers{c})(trial,k) = ...
                        misclassification_rate(Predictions,Ytrain{i,j}(:,trial),...
                        false);
                    if size(Scores,2) > 2
                        Yb = binarize_labels(Ytrain{i,j}(:,trial),Forest{k}.classname);
                        [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k)] = ...
                            perfcurve(Yb(:),Scores(:),'1');
                    else
                        [~,~,~,OOBAUC{i,j}.(Classifiers{c})(trial,k)] = ...
                            perfcurve(Ytrain{i,j}(:,trial),Scores(:,2),'1');
                    end
                end
                BestIdx = hp_optimize(OOBError{i,j}.(Classifiers{c})(trial,:),...
                    OOBAUC{i,j}.(Classifiers{c})(trial,:));
                if length(BestIdx)>1
                    BestIdx = BestIdx(end);
                end

                if strcmp(Forest{BestIdx}.Rescale,'off')
                    Scores = rerf_classprob(Forest{BestIdx},Xtest{j},'last');
                else
                    Scores = rerf_classprob(Forest{BestIdx},Xtest{j},...
                        'last',Xtrain{i,j}(:,:,trial));
                end
                Predictions = predict_class(Scores,Forest{BestIdx}.classname);
                TestError{i,j}.(Classifiers{c})(trial) = misclassification_rate(Predictions,...
                    Ytest{j},false);

                clear Forest

                save([rerfPath 'RandomerForest/Results/Sparse_parity_vary_n.mat'],'ps',...
                    'ns','Params','OOBError','OOBAUC','TestError','TrainTime')
            end
            fprintf('%s complete\n',Classifiers{c})
        end
    end   
end
