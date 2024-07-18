function [paramter, option] = MultiInputGUI(Criteria)
    % Initialize output variables
    paramter = '';
    option = '';

    switch Criteria
        case "AP"
            sentence = {'Input the foot size (mm) : ', 'Input the option (1,2,3) : '};
        case "WS"
            sentence = {'Input the body weight (kg) : ', 'Input the option (R,L) : '};
        case "AS"
            sentence = {'Input the body weight (kg) : ', 'Input the option (R,L) : '};
        case "ML"
            sentence = {'Input the body weight (kg) : ', ''};
    end

    % Create a figure for the GUI
    fig = figure('Position', [300, 300, 400, 200], 'MenuBar', 'none', 'Name', 'Dual Input GUI', 'NumberTitle', 'off', 'Resize', 'off', 'CloseRequestFcn', @closeCallback);

    % Create the first input label and text box
    uicontrol('Style', 'text', 'Position', [50, 140, 200, 30], 'String', sentence{1}, 'HorizontalAlignment', 'left', 'FontSize', 10);
    paramter_Box = uicontrol('Style', 'edit', 'Position', [250, 140, 100, 30], 'FontSize', 10);

    % Create the second input label and text box
    uicontrol('Style', 'text', 'Position', [50, 80, 200, 30], 'String', sentence{2}, 'HorizontalAlignment', 'left', 'FontSize', 10);
    option_Box = uicontrol('Style', 'edit', 'Position', [250, 80, 100, 30], 'FontSize', 10);

    % Create a submit button
    uicontrol('Style', 'pushbutton', 'Position', [150, 20, 100, 40], 'String', 'Submit', 'FontSize', 10, 'Callback', @submitCallback);

    % Store initial data in the figure's UserData property
    data.paramter = '';
    data.option = '';
    set(fig, 'UserData', data);

    % Wait for the user to close the figure
    uiwait(fig);

    % Check if the figure still exists before retrieving data
    if isvalid(fig)
        data = get(fig, 'UserData');
        paramter = data.paramter;
        option = data.option;
        delete(fig);
    else
        disp('Figure was closed before data could be retrieved.');
    end

    % Callback function for the submit button
    function submitCallback(~, ~)
        paramter = str2double(get(paramter_Box, 'String'));
        option = get(option_Box, 'String');
        
        %{ Check the input values
%        if isnan(paramter) || paramter < 30 || paramter > 200
%            errordlg('Bad size! body weight must be between 30 and 220 kg.', 'Input Error');
%            return;
%        end
        
%        if isnan(option) || ~ismember(option, ['R','L'])
%            errordlg('Option must be R or L', 'Input Error');
%            return;
%        end

        % Store the inputs in the figure's UserData property
        data.paramter = paramter;
        data.option = option;
        set(fig, 'UserData', data);

        % Resume the GUI
        uiresume(fig);
    end

    % Callback function for closing the figure
    function closeCallback(~, ~)
        % Resume the GUI
        uiresume(fig);
        % Delete the figure
        delete(fig);
    end

    disp(paramter);
    disp(option);
end
