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
[body_weight_kg, selectedFoot] = InputGUI_AS;
FootDict = containers.Map({'right', 'left'}, {1, 2});

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

loc_x = [centerpoint(1) + margin .* (-1)^(FootDict(selectedFoot)+1), ylim(1)]; % x y

% each bar width
width = 100;
% each bar height
height = ylim(2) - ylim(1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% draw target line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

target_value = 20; %  20 %
margin_of_error = 1; %  1 %
target_range = [target_value - margin_of_error, target_value + margin_of_error];

target_line = plot([loc_x(1) - width/2, loc_x(1) + width/2], [target_value target_value], 'LineWidth', 10, 'Color', 'black');

text(loc_x(1) - width/2 - 50, target_value, sprintf("%d %%", target_value), 'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');

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

grf_diff_array = cell(1,1);
i = 1;

while true
    %use event function to avoid crash
    try
        event = QCM('event');
        % ### Fetch data from QTM
        [frameinfo,force] = QCM;
        if ~ishandle(figureHandle)
            QCM("disconnect");
            break;
        end

        % error occurs when getting realtime grf data. Sometimes there is no data.
        if isempty(force{2,1}) || isempty(force{2,2})
            continue
        end
        
        %get GRF Z from plate 1, 2 unit: kgf
        GRF1 = abs(force{2,2}(1,3));
        GRF2 = abs(force{2,1}(1,3));
        %{
        if GRF1 < 10 && GRF2 < 10
            continue
        end
        %}
        relative_diff = abs(GRF2 - GRF1) / (GRF1 + GRF2) * 100;

        %Update each bar and COP line
        set(plot_bar, 'xdata', [loc_x(1), loc_x(1)],'ydata', [ylim(1), relative_diff])
        
        drawnow;

        grf_diff_array{i} = relative_diff;
        i = i+1;

    catch exception
        disp(exception.message);
        break
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% draw the graph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
grf_diff_array = cell2mat(grf_diff_array);
n = length(grf_diff_array);

[numRows, numCols] = size(grf_diff_array);

set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);

hold on;

title(sprintf('Percent Difference from Target Value plate (%s)', selectedFoot), 'FontSize', 20);
xlabel('Time ', 'FontSize', 15);
ylabel('Difference ', 'FontSize', 15);
grid on;

plot((1: numCols), grf_diff_array, 'black');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% calculate RMSE(Root Mean Sqaure Error)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
text_position_x = round(numCols / 2);
center_rmse = sqrt(sum((grf_diff_array - target_value).^2) / n);
disp(['Center Mean Percent Difference: ', num2str(center_rmse), '%']);
plot([1 numCols], [target_value target_value], ...
    'black','LineWidth', 1, 'LineStyle','--');
% 센터 평균 퍼센트 차이 텍스트 추가
center_text_position_y = target_value+10;
text(text_position_x, center_text_position_y, ['RMSE: ', num2str(center_rmse), '%'], ...
    'FontSize', 15, 'HorizontalAlignment', 'center', 'Color', 'black');