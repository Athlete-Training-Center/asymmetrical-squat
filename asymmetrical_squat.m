clear

ip = '127.0.0.1';
% ### Connect to QTM
QCM('connect', ip, 'frameinfo', 'force'); % Connects to QTM and keeps the connection alive.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
figureHandle = figure('CloseRequestFcn', @closeRequest);
function closeRequest(src, callbackdata)
    % figure 창을 닫을 때 실행할 코드
    disp('Figure is being closed.');
    delete(src); % figure 창 삭제
end

hold on
set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
set(gca,'XTICK',[],'YTick',[])

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% bodyweight setting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%foot_size = inputdlg("input the your body weight (kg): ");
bodyweight_kg = '80'; % kg
bodyweight_kg = str2double(bodyweight_kg);
if bodyweight_kg <= 0 || bodyweight_kg >= 150
    disp('bad weight! try again');
end

% gravity acceleration (m/s^2)
gravity = 9.80665; 
bodyweight_N = bodyweight_kg * gravity;

% figure size setting
xlim=[0 1200]; % 600 mm x 2
ylim = [0 bodyweight_N * 0.5];
set(gca, 'xlim',xlim, 'ylim',ylim)

centerpoint = [(xlim(1)+xlim(2))/2 (ylim(1)+ylim(2))/2];

margin = 300;

side = randi(2); % 1:left, 2:right

switch side
    case 1
        loc_x = [centerpoint(1)-margin 0]; % x1 y
    case 2
        loc_x = [centerpoint(1)+margin 0]; % x2 y
end

width = 100; % each bar width

% make handles for each bar to update vGRF and AP COP data
plot_bar = plot([loc_x(1)-width/2, loc_x(1)-width/2], [ylim(1), ylim(1) + 100], 'LineWidth', width - 10,'Color','red');

height = ylim(2)*0.8;
% make bar frame
plot([loc_x(1)-width/2 loc_x(1)+width/2],[height height],'k', 'linewidth',1) % top
plot([loc_x(1)-width/2 loc_x(1)-width/2],[ylim(1) height],'k', 'linewidth',1); % left
plot([loc_x(1)+width/2 loc_x(1)+width/2],[ylim(1) height],'k', 'linewidth',1); % right

target_value = bodyweight_N * 0.2; % 120% for body weight
target_line = plot([loc_x(1)-50 loc_x(1)+50], [target_value target_value], 'LineWidth', 10, 'Color', 'black');
    text(centerpoint(1), target_value+20, ['target value: ', num2str(round(target_value, 2)), ' N'], ...
        'FontSize', 20, 'HorizontalAlignment', 'center', 'Color', 'black');

%draw force plate line
plot([0 0],get(gca,'ylim'),'k', 'linewidth',3)
plot([xlim(2) xlim(2)],get(gca,'ylim'),'k', 'linewidth',3)
plot([centerpoint(1) centerpoint(1)],get(gca,'ylim'),'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(2) ylim(2)],'k', 'linewidth',3)
plot(get(gca,'xlim'),[ylim(1) ylim(1)],'k', 'linewidth',3)
title('Left                                                            Right','fontsize',30)

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

        if isempty(force{2,1}) || isempty(force{2,2})%error occurs when getting realtime grf data. Sometimes there is no data.
            continue
        end
        
        GRF1 = abs(force{2,2}(1,3));%get GRF Z from plate 1
        GRF2 = abs(force{2,1}(1,3));%get GRF Z from plate 2 unit: kgf

        GRF_diff = abs(GRF1 - GRF2);

        %Update each bar and COP line
        set(plot_bar,'xdata',[loc_x(1) loc_x(1)],'ydata',[ylim(1) GRF_diff])
        
        drawnow;

    catch exception
        disp(exception.message);
        break
    end
end
