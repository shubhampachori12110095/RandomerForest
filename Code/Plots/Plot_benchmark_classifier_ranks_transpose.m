%% Plot Performance Profiles for Benchmark Transformations
close all
clear
clc

C = [0 1 1;0 1 0;1 0 1;1 0 0;0 0 0;1 .5 0];
Colors.rf = C(1,:);
Colors.rerf = C(2,:);
Colors.rf_rot = C(3,:);
Colors.rerfr = C(4,:);
Colors.frc = C(5,:);
Colors.rerfdn = C(6,:);

FontSize = 16;

figWidth = 11;
figHeight = 8.5;

fig = figure;
fig.Units = 'inches';
fig.PaperUnits = 'inches';
fig.Position = [0 0 figWidth figHeight];
fig.PaperPosition = [0 0 figWidth figHeight];
fig.PaperSize = [figWidth figHeight];

Transformations = {'Untransformed' 'Rotated' 'Scaled' 'Affine'};

runSims = false;

load('~/Benchmarks/Results/Benchmark_untransformed_2016_08_05.mat')

Classifiers = fieldnames(TestError{1});
Classifiers(strcmp(Classifiers,'rerfd')) = [];

TestError = TestError(~cellfun(@isempty,TestError));

ErrorMatrix = [];
for i = 1:length(TestError)
    for j = 1:length(Classifiers)
        ErrorMatrix(i,j) = TestError{i}.(Classifiers{j});
    end
end

ClRanks = tiedrank(ErrorMatrix')';
IntRanks = floor(ClRanks);

RankCounts = NaN(length(Classifiers));
for i = 1:length(Classifiers)
    RankCounts(i,:) = sum(ClRanks==i);
end

bar(RankCounts')
ax = gca;
Bars = allchild(ax);
for i = 1:length(Bars)
    Bars(i).EdgeColor = 'w';
    Bars(i).BarWidth = 1;
end

xlabel('Rank')
ylabel('Frequency')
title('Untransformed')

ax.FontSize = FontSize;
ax.XTickLabel = {'RF' 'RF(r)' 'RerF' 'RerF(r)' 'F-RC' 'F-RC(r)' 'RR-RF' 'RR-RF(r)'};
ax.YLim = [0 35];
ax.LineWidth = 2;

l = legend('1st place','2nd place','3rd place','4th place','5th place',...
    '6th place','7th place','8th place');
l.Location = 'northwest';
l.Box = 'off';

line([1 1],[14.5 19.5],'Color','k','LineWidth',3)
line([3 3],[18.5 19.5],'Color','k','LineWidth',3)
line([1 3],[19.5 19.5],'Color','k','LineWidth',3)
t = text(2,19.5,'*','HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontSize',FontSize+2);

line([1 1],[20 21],'Color','k','LineWidth',3)
line([5 5],[16.5 21],'Color','k','LineWidth',3)
line([1 5],[21 21],'Color','k','LineWidth',3)
t = text(3,21,'*','HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontSize',FontSize+2);

line([1 1],[21.5 23.5],'Color','k','LineWidth',3)
line([7 7],[22.5 23.5],'Color','k','LineWidth',3)
line([1 7],[23.5 23.5],'Color','k','LineWidth',3)
t = text(4,23.5,'**','HorizontalAlignment','center',...
    'VerticalAlignment','bottom','FontSize',FontSize+2);

save_fig(gcf,'~/Benchmarks/Figures/Classifier_ranks_untransformed_transpose')