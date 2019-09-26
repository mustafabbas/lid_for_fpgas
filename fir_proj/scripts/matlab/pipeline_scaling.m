% load data file
file_path = '../../results/arria_10_par_reg';
%file_path = '../../results/stratix_10_par_unrestricted';
file_name = 'width_pipeline.m';
data_file = fullfile(file_path, file_name);
run(data_file)

% constansts
JUMP_AMT = 1;
END_PIPELINE_NUM = 14;
% JUMP_AMT = 10;
% END_PIPELINE_NUM = 100;
DESIGNS = {'nonli', 'credit','qsys','carloni'};

% create x axis
pipeline_num = 0:JUMP_AMT:END_PIPELINE_NUM;

figure;
plot(pipeline_num, nonli_32, ':v',...
    'Color', 'r',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r')
hold on
plot(pipeline_num, credit_32, ':d',...
    'Color', 'b',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','b')
hold on
plot(pipeline_num, qsys_32, ':s',...
    'Color', 'g',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g')
hold on
plot(pipeline_num, carloni_32, ':o',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')
legend('non-li', ...
       'credit', ...
       'ready valid', ...
       'carloni', ...
       'Location','southEast')
xlabel('Number of Pipeline Stages'), ylabel('Fmax [MHz]')
xlim([min(xlim) max(xlim)])
set(gca,'YMinorTick','on')
ax = gca;
ax.XAxis.MinorTick = 'on';
ax.XAxis.MinorTickValues = 0:JUMP_AMT:max(xlim);


% save figure
print('pipeline_scaling_plot', '-dpng')
print('pipeline_scaling_plot', '-depsc')
movefile('pipeline_scaling_plot.png', file_path)
movefile('pipeline_scaling_plot.eps', file_path)
