function Xtest_rank = interpolate_rank(Xtrain,Xtest)
%Takes a test set and projects into the training data rank space
%For example suppose Xtrain is a 1-dimensional set of 3 points: [1;-2;5].
%Then passing to ranks gives Xtrain_rank = [2;1;3]. Now suppose you have a single point
%Xtest = 3. Since Xtest is half between Xtrain(1) and Xtrain(3), linearly
%interpolating gives its rank as being halfway between Xtrain_rank(1) and
%Xtrain_rank(3), or 2.5

%Xtrain: ntrain x d matrix of training data
%Xtest: ntest x d matrix of test data

    Xtest_rank = zeros(size(Xtest));
    Xtrain_rank = passtorank(Xtrain);   %rank the training data
    
    %concatenate each test point to the training set and rerank to find out
    %where the test point lies relative to the training points
    %for each dimension. If the value of the test point is less than that
    %of all training points, then its rank is 1. If it's value is greater
    %than that of all training points, then its rank is equal to the
    %largest rank of the training points. Otherwise, it's rank is linearly
    %interpolated between the points immediately greater than and
    %immediately less than it.
    for i = 1:size(Xtest,1)
        Xcat = cat(1,Xtrain,Xtest(i,:));
        Xcat_rank = passtorank(Xcat);   
        for j = 1:size(Xtest(i,:),2)
            if Xcat_rank(end,j) == size(Xcat_rank,1)
                Xtest_rank(i,j) = Xcat_rank(end,j) - 1;
            elseif Xcat_rank(end,j) == 1
                Xtest_rank(i,j) = Xcat_rank(end,j);
            else
                lower_idx = find(Xtrain_rank(:,j)==Xcat_rank(end,j)-1);
                upper_idx = find(Xtrain_rank(:,j)==Xcat_rank(end,j)+1);
                Xtest_rank(i,j) = ((Xtest(i,j) - Xtrain(lower_idx,j))/(Xtrain(upper_idx,j) - Xtrain(lower_idx,j)))*(Xtrain_rank(upper_idx,j) - Xtrain_rank(lower_idx,j)) + Xtrain_rank(lower_idx,j);
            end
        end
    end
end