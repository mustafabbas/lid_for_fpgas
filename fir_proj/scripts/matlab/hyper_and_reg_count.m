% load data file
file_path = '../../results/stratix_10_par_unrestricted_bak';
file_name = 'width_pipeline.m';
data_file = fullfile(file_path, file_name);
run(data_file)

% constansts
JUMP_AMT = 10;
END_PIPELINE_NUM = 100;
DESIGNS = {'nonli', 'credit','qsys','carloni'};

% create x axis
pipeline_num = 0:JUMP_AMT:END_PIPELINE_NUM;

% figure settings
fig = figure('units','inches');
pos = get(gcf,'pos');
set(gcf,'pos',[pos(1) pos(2) 7 5])
left_color = [0 0 0];
right_color = [0 0 0];
set(fig,'defaultAxesColorOrder',[left_color; right_color]);

plot(pipeline_num, nonli_32_hyper_regs, '-v',...
    'Color', 'r',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r')
hold on
plot(pipeline_num, credit_32_hyper_regs, '-d',...
    'Color', 'b',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','b')
hold on
plot(pipeline_num, qsys_32_hyper_regs, '-s',...
    'Color', 'g',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g')
hold on
plot(pipeline_num, carloni_32_hyper_regs, '-o',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')

hold on
plot(pipeline_num, carloni_32_total_regs, ':',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')
hold on
plot(pipeline_num, carloni_32_hyper_regs, '-',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')
hold on
plot(pipeline_num, 32*pipeline_num, '--x',...
    'Color', 'm',...
    'MarkerEdgeColor','m',...
    'MarkerFaceColor','m')

hold on
plot(pipeline_num, nonli_32_total_regs, ':v',...
    'Color', 'r',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r')
hold on
plot(pipeline_num, credit_32_total_regs, ':d',...
    'Color', 'b',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','b')
hold on
plot(pipeline_num, qsys_32_total_regs, ':s',...
    'Color', 'g',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g')
hold on
plot(pipeline_num, carloni_32_total_regs, ':o',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')
legend('non-li', ...
       'credit', ...
       'ready valid', ...
       'carloni', ...
       'total regs', ...
       'hyper regs', ...
       'expected # of hyper regs', ...
       'Location','northWest')
xlabel('Number of Pipeline Stages'), ylabel('Number of Registers')
xlim([min(xlim) 70])
set(gca,'YMinorTick','on')
ax = gca;
ax.XAxis.MinorTick = 'on';
ax.XAxis.MinorTickValues = 0:10:max(xlim);


% save figure
print('pipeline_scaling_reg_plot', '-dpng')
print('pipeline_scaling_reg_plot', '-depsc')
movefile('pipeline_scaling_reg_plot.png', file_path)
movefile('pipeline_scaling_reg_plot.eps', file_path)