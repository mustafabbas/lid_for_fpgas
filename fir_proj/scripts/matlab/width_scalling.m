% load data file
file_path = '../../results/stratix_10_par_unrestricted';
file_name = 'width_pipeline.m';
data_file = fullfile(file_path, file_name);
run(data_file)

% constansts
START_WIDTH = 32;
NUM_WRAPPERS = 4;
NUM_WIDTHS = 6;
DESIGNS = {'nonli', 'credit','qsys','carloni'};

% initialize arrays
width_scaling = zeros(NUM_WRAPPERS, NUM_WIDTHS);
percent_decrease = zeros(NUM_WRAPPERS, NUM_WIDTHS);
widths = zeros(1, NUM_WIDTHS);

% populate width_scaling
for i = 1:NUM_WRAPPERS
    for j = 1:NUM_WIDTHS
        curr_width = START_WIDTH * 2 ^ (j - 1);
        ave_freq_for_width = ...
            char(strcat('mean(',DESIGNS(i),'_',int2str(curr_width), ')' ));
        width_scaling(i, j) =  eval(ave_freq_for_width);
    end
end

% populate percent_decrease
for i = 1:NUM_WRAPPERS
    for j = 1:NUM_WIDTHS
        curr_width = START_WIDTH * 2 ^ (j - 1);
        original = width_scaling(i, 1);
        change_from_original = abs(width_scaling(i, j) - original);
        percent_decrease(i, j) = (change_from_original / original) * 100;
    end
end

% populate widths
for i = 1:NUM_WIDTHS
    widths(i) = START_WIDTH * 2 ^ (i - 1);
end

% compute x acess indices 
log_of_widths = log2(widths);

% figure settings
fig = figure('units','inches');
pos = get(gcf,'pos');
set(gcf,'pos',[pos(1) pos(2) 7 5])
left_color = [0 0 0];
right_color = [0 0 0];
set(fig,'defaultAxesColorOrder',[left_color; right_color]);

% plot width scaling
yyaxis left

plot(log2(widths), width_scaling(1:1,:), '-v',...
    'Color', 'r',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r')
hold on
plot(log2(widths), width_scaling(2:2,:), '-d',...
    'Color', 'b',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','b')
hold on
plot(log2(widths),  width_scaling(3:3,:), '-s',...
    'Color', 'g',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g')
hold on
plot(log2(widths),  width_scaling(4:4,:), '-o',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k')
plot(log2(widths),width_scaling(4:4,:),'-')
ylabel('Fmax[MHz]')

% plot percent decrease
yyaxis right
plot(log2(widths),percent_decrease(4:4,:),':')
plot(log2(widths), percent_decrease(1:1,:), ':v',...
    'Color', 'r',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','r',...
    'MarkerSize', 5)
hold on
plot(log2(widths), percent_decrease(2:2,:), ':d',...
    'Color', 'b',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','b',...
    'MarkerSize', 5)
hold on
plot(log2(widths),  percent_decrease(3:3,:), ':s',...
    'Color', 'g',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','g',...
    'MarkerSize', 5)
hold on
plot(log2(widths),  percent_decrease(4:4,:), ':o',...
    'Color', 'k',...
    'MarkerEdgeColor','k',...
    'MarkerFaceColor','k',...
    'MarkerSize', 5)
ylabel('Percent Decrease')


legend('non-li', ... 
       'credit', ...
       'ready valid', ...
       'carloni', ... 
       'Fmax', ... 
       '%', ... 
       'Location','north', ...
       'Orientation','horizontal')

% x axis properties
xlabel('Data Width')
xticks(log2(widths))
xticklabels(widths)

% save figure
print('width_scaling_plot', '-dpng')
print('width_scaling_plot', '-depsc')
movefile('width_scaling_plot.png', file_path)
movefile('width_scaling_plot.eps', file_path)
