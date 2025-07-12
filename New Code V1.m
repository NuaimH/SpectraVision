function WiFiSensingAnalysis
    % Create the main figure
    mainFig = figure('Name', 'WiFi Sensing Analysis', 'Position', [100, 100, 1050, 800], ...
        'MenuBar', 'none', 'NumberTitle', 'off', 'Color', [0.94 0.94 0.94]);

    % Create display panel
    mainPanel = uipanel('Parent', mainFig, 'Position', [0.05, 0.2, 0.9, 0.75], 'BackgroundColor', [0.94 0.94 0.94]);

    % Create button panel
    buttonPanel = uipanel('Parent', mainFig, 'Position', [0.05, 0.05, 0.9, 0.15], ...
        'BackgroundColor', [0.85 0.85 0.85], 'BorderType', 'line', 'HighlightColor', [0.5 0.5 0.5]);

    % Add Load CSI File button
    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '0. Load CSI File', ...
        'Position', [10, 20, 150, 40], 'Callback', @loadCSIFile, 'FontWeight', 'bold');

    % Add other buttons
    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '1. Reflected Signal (Doppler)', ...
        'Position', [180, 20, 180, 40], 'Callback', @showDopplerEffect, 'FontWeight', 'bold');

    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '2. CSI Amplitude Analysis (2D/3D)', ...
        'Position', [370, 20, 200, 40], 'Callback', @showCSIAmplitude, 'FontWeight', 'bold');

    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '3. Motion FFT Analysis (3D)', ...
        'Position', [580, 20, 180, 40], 'Callback', @showMotionFFT, 'FontWeight', 'bold');

    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '4. Breathing Detection', ...
        'Position', [770, 20, 180, 40], 'Callback', @showBreathingDetection, 'FontWeight', 'bold');

    uicontrol('Parent', buttonPanel, 'Style', 'pushbutton', 'String', '5. AI Activity Classification', ...
        'Position', [960, 20, 180, 40], 'Callback', @showAIClassification, 'FontWeight', 'bold');

    % Persistent variable for loaded CSI data
    persistent csiData;
    persistent trainedNet;

    % CSI File Loader
    function loadCSIFile(~, ~)
        [file, path] = uigetfile({'.mat;.dat','CSI Files (*.mat, *.dat)'}, 'Select CSI File');
        if isequal(file, 0)
            disp('No file selected');
            return;
        end
        fullFilePath = fullfile(path, file);
        % Load CSI file based on extension
        [~, ~, ext] = fileparts(fullFilePath);
        if strcmp(ext, '.mat')
            temp = load(fullFilePath);
            if isfield(temp, 'csiData')
                csiData = temp.csiData;
            else
                errordlg('No "csiData" variable in MAT file');
                return;
            end
        elseif strcmp(ext, '.dat')
            csiData = parseDatCSI(fullFilePath);
        else
            errordlg('Unsupported file format');
            return;
        end
        msgbox('CSI File Loaded Successfully');

        % Load pretrained network (mock for now)
        if isempty(trainedNet)
            trainedNet = loadPretrainedModel();
        end
    end

    % Doppler Effect Plot
    function showDopplerEffect(~, ~)
        delete(get(mainPanel, 'Children'));
        ax = axes('Parent', mainPanel, 'Position', [0.1, 0.1, 0.8, 0.8]);
        if isempty(csiData)
            title(ax, 'Please load CSI data first', 'FontSize', 14);
            return;
        end
        t = csiData.time;
        dopplerShift = mean(diff(angle(csiData.data),1,2),1);
        plot(ax, t(2:end), dopplerShift, 'LineWidth', 1.5);
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Doppler Shift (rad)');
        title(ax, '1. Doppler Effect from CSI Data');
        grid(ax, 'on');
    end

    % CSI Amplitude Analysis
    function showCSIAmplitude(~, ~)
        delete(get(mainPanel, 'Children'));
        ax = axes('Parent', mainPanel, 'Position', [0.1, 0.1, 0.8, 0.8]);
        if isempty(csiData)
            title(ax, 'Please load CSI data first', 'FontSize', 14);
            return;
        end
        time = csiData.time;
        amp = abs(csiData.data);
        imagesc(ax, time, 1:size(amp,1), amp);
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Subcarrier Index');
        title(ax, '2. CSI Amplitude Heatmap');
        colormap(ax, 'jet'); colorbar;

        % Add 3D surface plot
        figure;
        surf(time, 1:size(amp,1), amp);
        xlabel('Time (s)'); ylabel('Subcarrier'); zlabel('Amplitude');
        title('3D CSI Amplitude Surface');
        shading interp; colormap jet; colorbar;
    end

    % Motion FFT Analysis
    function showMotionFFT(~, ~)
        delete(get(mainPanel, 'Children'));
        ax = axes('Parent', mainPanel, 'Position', [0.1, 0.1, 0.8, 0.8]);
        if isempty(csiData)
            title(ax, 'Please load CSI data first', 'FontSize', 14);
            return;
        end
        data = mean(abs(csiData.data),1);
        fs = 1/mean(diff(csiData.time));
        N = length(data);
        Y = fft(data);
        f = fs*(0:(N/2))/N;
        P1 = abs(Y/N);
        P1 = P1(1:N/2+1);
        plot(ax, f, P1, 'r', 'LineWidth', 1.5);
        xlabel(ax, 'Frequency (Hz)'); ylabel(ax, 'Magnitude');
        title(ax, '3. FFT of Motion Signal');
        grid(ax, 'on');

        % Add 3D Waterfall plot
        figure;
        waterfall(csiData.time, 1:size(csiData.data,1), abs(csiData.data));
        xlabel('Time (s)'); ylabel('Subcarrier'); zlabel('Amplitude');
        title('3D Waterfall Plot of CSI Data');
        colormap jet; grid on;
    end

    % Breathing Detection
    function showBreathingDetection(~, ~)
        delete(get(mainPanel, 'Children'));
        ax = axes('Parent', mainPanel, 'Position', [0.1, 0.1, 0.8, 0.8]);
        if isempty(csiData)
            title(ax, 'Please load CSI data first', 'FontSize', 14);
            return;
        end
        signal = mean(abs(csiData.data),1);
        t = csiData.time;
        plot(ax, t, signal, 'g', 'LineWidth', 1.2);
        title(ax, '4. Breathing Detection');
        xlabel(ax, 'Time (s)'); ylabel(ax, 'Amplitude');
        grid(ax, 'on');
        [pks, locs] = findpeaks(signal, 'MinPeakDistance', round(1/(0.3*mean(diff(t)))));
        hold(ax, 'on');
        plot(ax, t(locs), pks, 'ro');
        hold(ax, 'off');
        text(0.1, 0.9, sprintf('Detected Breathing Cycles: %d', length(locs)), 'Units', 'normalized', 'FontSize', 12);
    end

    % AI Activity Classification
    function showAIClassification(~, ~)
        delete(get(mainPanel, 'Children'));
        ax = axes('Parent', mainPanel, 'Position', [0.2, 0.3, 0.6, 0.4]);
        if isempty(csiData)
            title(ax, 'Please load CSI data first', 'FontSize', 14);
            return;
        end
        if isempty(trainedNet)
            title(ax, 'No trained network available', 'FontSize', 14);
            return;
        end
        
        % Preprocess CSI for classification (reshape as image)
        features = abs(csiData.data);
        features = rescale(features);
        img = imresize(features, [64 64]);
        
        % Predict activity
        [label, score] = classify(trainedNet, img);
        
        % Display result
        title(ax, sprintf('Predicted Activity: %s', string(label)), 'FontSize', 16, 'FontWeight', 'bold');
        text(0.2, 0.5, sprintf('Confidence: %.2f%%', max(score)*100), 'Units', 'normalized', 'FontSize', 14);
    end

    % Example parser for .dat files (stub)
    function csi = parseDatCSI(filename)
        t = linspace(0, 10, 200);
        data = randn(30, length(t));
        csi.time = t;
        csi.data = data;
    end

    % Example pretrained model loader (stub)
    function net = loadPretrainedModel()
        layers = [imageInputLayer([64 64 1],'Name','input')
                  convolution2dLayer(3,8,'Padding','same','Name','conv1')
                  batchNormalizationLayer('Name','bn1')
                  reluLayer('Name','relu1')
                  fullyConnectedLayer(4,'Name','fc')
                  softmaxLayer('Name','softmax')
                  classificationLayer('Name','output')];
        net = assembleNetwork(layers);
    end
end