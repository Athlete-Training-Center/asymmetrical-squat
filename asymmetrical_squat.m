%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%   asymmetrical squat
%
%   ~~
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% reset setting
clear

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bodyweight setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
[body_weight_kg, option] = MultiInputGUI('AS');
option = upper(option);

% gravity acceleration (m/s^2)
gravity = 9.80665;
bodyweight_N = body_weight_kg * gravity;

% Connect to QTM
ip = '127.0.0.1';
% Connects to QTM and keeps the connection alive.
QCM('connect', ip, 'frameinfo', 'force');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Create a figure window
figureHandle = figure(1);
hold on
% set the figure size
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
% remove ticks from axes
set(gca,'XTICK',[],'YTick',[])

% setting figure size to real force plate size
%           600mm      600mm
%        ---------------------
%      x↑         ¦           ¦
%       o → y     ¦           ¦ 400mm
%       ¦         ¦           ¦ 
%        ---------------------
% original coordinate : left end(x = 0) and center
xlim=[0 1200];
ylim = [0 100]; % 100 %
set(gca, 'xlim', xlim, 'ylim', ylim)

% center coordinate for figure size
centerpoint = [(xlim(1) + xlim(2)) / 2, (ylim(1) + ylim(2)) / 2];

% bar blank between vertical center line and each bar
margin = 300;

switch option
    case 'R'
        loc_x = [centerpoint(1)+margin, ylim(1)]; % x2 y
    case 'L'
        loc_x = [centerpoint(1)-margin, ylim(1)]; % x1 y
end

% each bar width
width = 100;
% each bar height
height = ylim(2) - ylim(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw target line
%% Perform a target force 10 times at a random rate based on weight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

target_value = 20; %  20 %
margin_of_error = 1; %  1 %
target_range = [target_value - margin_of_error, target_value + margin_of_error];

target_line1 = plot([loc_x(1) - width/2, loc_x(1) + width/2], [target_range(1) target_range(1)], 'LineWidth', 3, 'Color', 'black');
target_line2 = plot([loc_x(1) - width/2, loc_x(1) + width/2], [target_range(2) target_range(2)], 'LineWidth', 3, 'Color', 'black');
text(loc_x(1) - width/2 - 50, target_value+2, sprintf("%d %%", target_value + margin_of_error), 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');
text(loc_x(1) - width/2 - 50, target_value-2, sprintf("%d %%", target_value - margin_of_error), 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');

% make handles for each bar to update vGRF and AP COP data
plot_bar = plot([loc_x(1)-width/2, loc_x(1)-width/2], [ylim(1), ylim(1) + 100], 'LineWidth', width - 10,'Color','red');

% make bar frame
plot([loc_x(1)-width/2 loc_x(1)+width/2],[height height],'k', 'linewidth',1) % top
plot([loc_x(1)-width/2 loc_x(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc_x(1)+width/2 loc_x(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

%draw force plate line
plot([0 0],get(gca,'ylim'),'k', 'linewidth',3)
plot([xlim(2) xlim(2)],get(gca,'ylim'),'k', 'linewidth',3)
plot([centerpoint(1) centerpoint(1)],get(gca,'ylim'),'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(2) ylim(2)],'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(1) ylim(1)],'k', 'linewidth',3)
title('Left                                                            Right','fontsize',30)

grf_list = [];

while true
    %use event function to avoid crash
    try
        event = QCM('event');
        % ### Fetch data from QTM
        [frameinfo,force] = QCM;
        fig = get(groot, 'CurrentFigure');
        if isempty(fig)
            break
        end

        % error occurs when getting realtime grf data. Sometimes there is no data.
        if isempty(force{2,1}) || isempty(force{2,2})
            continue
        end
        
        %get GRF Z from plate 1, 2 unit: kgf
        GRF1 = abs(force{2,2}(1,3));
        GRF2 = abs(force{2,1}(1,3));

        relative_diff = abs(GRF2 - GRF1) / (GRF1 + GRF2) * 100;

        %Update each bar and COP line
        set(plot_bar, 'xdata', [loc_x(1), loc_x(1)],'ydata', [ylim(1), relative_diff])
        
        drawnow;

        grf_list = [grf_list, relative_diff];

    catch exception
        disp(exception.message);
        break
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw the graph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
n = length(grf_list);

[numRows, numCols] = size(grf_list);

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);

hold on;

title(sprintf('Percent Difference from Target Value plate (%s)', option), 'FontSize', 20);
xlabel('Time ', 'FontSize', 15);
ylabel('Difference ', 'FontSize', 15);
grid on;

plot((1: numCols), grf_list, 'black');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate RMSE(Root Mean Sqaure Error)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
text_position_x = round(numCols / 2);
center_rmse = sqrt(sum((grf_list - target_value).^2) / n);
disp(['Center Mean Percent Difference: ', num2str(center_rmse), '%']);
plot([1 numCols], [target_value target_value], ...
    'black','LineWidth', 1, 'LineStyle','--');
% 센터 평균 퍼센트 차이 텍스트 추가
center_text_position_y = target_value+10;
text(text_position_x, center_text_position_y, ['RMSE: ', num2str(center_rmse), '%'], ...
    'FontSize', 15, 'HorizontalAlignment', 'center', 'Color', 'black');