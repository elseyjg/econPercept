try
% Clear the workspace
close all;
clear all;
clearvars;
sca;
global MouseInsteadOfGaze whichEye
maxTrlTime = 300; % seconds
  
tic
% which eye is being tracked left(1) or right(2)
whichEye = 2;
MouseInsteadOfGaze = 1; % 1 means mouse

%This if statement checks if the Eyelink can be connected to.
%There are two cases in which it cannot be connected to
%1 -> The eyelink is already connected to a machine, if your matlab script crashes while connected to the eyelink machine,
%     the eyelink will NOT disconnect, yet any request to connect or communicate with the eyelink machine by running a new
%     script will be rejected by the eyelink machine because it never recieved the command to disconnect. In this event,
%     you must restart the eyelink machine to enable it to accept requests for connection and communication. To do this,
%     press Ctrl+Alt+Q to turn off the eyelink application and return to eyelink OS command line.
%     To start the eyelink application, type elcl.exe (which should be located in the current working directory) and hit enter.
%     Wait until the Eyelink application finishes startup and then you can run your matlab script on your host machine.
%     As for Psychtoolbox applications, if they crash mid-script and the screen is being used, there is no easy way to stop the script.
%     To quit out of matlab press Windows Key+Alt+Esc. This will NOT send a disconnect signal to the eyelink machine and so
%     In order to reconnect to the eyelink machine you have to follow the steps above.
%2 -> The eyelink machine is not on or the eyelink application is not running. This is a simple press of the power button
%     and waiting for the eyelink application to finish startup. If this step fails then there is a high probability that
%     the machine is either broken or it is likely the eyelink files have been corrupted.
if ~MouseInsteadOfGaze
    if ~DebugFlag
        if ~EyelinkInit()
            fprintf('ERROR: Cannot connect to Eyelink. Perhaps it is offline/shutdown\n'); %KJ changed this to fprintf
            exit();
        end
    end
end

%Start edf file recording
if ~MouseInsteadOfGaze
    if ~DebugFlag
        edfFile = 'vsm.edf'; % the name of the datafile at the pc
        % [path,name,ext] = fileparts(filename);
        % edfFile = [name '.edf'];
        Eyelink('Openfile', edfFile);
        %This opens ^ECS^
        doCalibration=1;
        if(doCalibration == 1)
            el_settings=EyelinkInitDefaults(window);
            HideCursor;
            EyelinkDoTrackerSetup(el_settings);
            EyelinkDoDriftCorrection(el_settings);
        end
    end
end

% Setup PTB with some default values
PsychDefaultSetup(2);

% Seed the random number generator. Here we use the an older way to be
% compatible with older systems. Newer syntax would be rng('shuffle'). Look
% at the help function of rand "help rand" for more information
rand('seed', sum(100 * clock));

% Set the screen number to the external secondary monitor if there is one
% connected
screenNumber = max(Screen('Screens'));

% Define white, grey and black
white = WhiteIndex(screenNumber);
grey = white / 2;
black = BlackIndex(screenNumber);

% Open an on screen window
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, [0 0 0]);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Geneva');
Screen('TextSize', window, 36);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);


%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
escapeKey = KbName('ESCAPE');
leftKey = KbName('LeftArrow');
rightKey = KbName('RightArrow');
downKey = KbName('DownArrow');
upKey = KbName('UpArrow');

if ismac
    E_ButtonPress = 8;
    Q_ButtonPress = 20;
    End_ButtonPress = 39;
    one_ButtonPress = 30;
    two_ButtonPress = 31;
    three_ButtonPress = 32;
    four_ButtonPress = 33;

else %is Windows
    E_ButtonPress = 69;
    Q_ButtonPress = 81;
    End_ButtonPress = 35;
%     Left_ButtonPress = 37;
%     Up_ButtonPress = 38;
%     Right_ButtonPress = 39;
    one_ButtonPress = 30;
    two_ButtonPress = 31;
    three_ButtonPress = 32;
    four_ButtonPress = 33;
end
%----------------------------------------------------------------------
%                       Timing information
%----------------------------------------------------------------------

nFrames = 12;
nBlocks = 1;


%----------------------------------------------------------------------
%                       Fixation cross
%----------------------------------------------------------------------

% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 20;
FW = fixCrossDimPix*2
% Now we set the coordinates (these are all relative to zero we will let
% the drawing routine center the cross in the center of our monitor for us)
xCoords = [-fixCrossDimPix fixCrossDimPix 0 0];
yCoords = [0 0 -fixCrossDimPix fixCrossDimPix];
allCoords = [xCoords; yCoords];

% Set the line width for our fixation cross
lineWidthPix = 4;

%----------------------------------------------------------------------
%                  Rect dimensions and positions
%----------------------------------------------------------------------

% Make a base Rect of 150 by 150 pixels
baseRect = [0 0 150 150];

% Screen positions of the rectangles
squareXpos = [screenXpixels*0.40 screenXpixels*0.60 screenXpixels*0.5];
squareYpos = [screenYpixels*0.67 screenYpixels*0.67 screenYpixels*0.33];

numSquares1 = 3;
numSquares2 = 2;

% Make the rectangle coordinates
allRects = nan(4, 3); % First stage
for i = 1:numSquares1
    allRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), squareYpos(i));
end

twoRects = nan(4, 2); % Second stage
for i = 1:numSquares2
    twoRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), squareYpos(i));
end


% Pen width for the frames
penWidthPixels = 6;



%----------------------------------------------------------------------
%                  Randomise temporal order of trials
%----------------------------------------------------------------------
 
trialorder = [1 2 3 4];
randtemp = Shuffle(trialorder);

%----------------------------------------------------------------------
%                 Defining trial variable 
%----------------------------------------------------------------------
 
newtrial = 0;

%----------------------------------------------------------------------
%                       Results Matrix
%----------------------------------------------------------------------

% Make a  matrix which which will hold all of our results
resultsMatrix = struct('TrialType', {}, 'S1Numbers', {}, 'S1Mean', {}, 'S1Variance', {}, 'S1Position', {}, ...
'S2Numbers', {}, 'S2Mean', {}, 'S2Variance', {}, 'S2Position', {}, ...
'S3Numbers', {}, 'S3Mean', {}, 'S3Variance', {}, 'S3Position', {}, 'Key1', {},  'Timeq1', {}, ...
'Srightnumber', {}, 'Srightnumbers', {}, 'Srightmean', {}, 'Srightvariance', {}, ...
'Sleftnumber', {}, 'Sleftnumbers', {}, 'Sleftmean', {}, 'Sleftvariance', {}, 'Key2', {},  'Timeq2', {});

% Make a directory for the results
resultsDir = [cd '/Results/'];
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end

entryNumber = 1;

% Eye position results matrix
RECORD_DATA = cell([entryNumber, 4]);%The first variable entryNumber is going to grow very quickly
TRAINING_DATA = cell([entryNumber, 4]);%The first variable entryNumber is going to grow very quickly
%Variables are:
% (1) Trial number
% (2) System time
% (3) Event Type (String)
% (4) Event-Specific Data (Cell)*

%----------------------------------------------------------------------
%                   Generating grayscale images
%----------------------------------------------------------------------

% Make a base Rect of 150 by 150 pixels. 
baseRect = [0 0 150 150];

% Center the rectangle on the centre of the screen using fractional pixel
% values.
centeredRect_left = CenterRectOnPointd(baseRect, screenXpixels*0.40, screenYpixels*0.67);
centeredRect_up = CenterRectOnPointd(baseRect, screenXpixels*0.5, screenYpixels*0.33);
centeredRect_right = CenterRectOnPointd(baseRect, screenXpixels*0.60  , screenYpixels*0.67);

% Define grayscales 
rectColor{1} = [0.1 0.1 0.1];
rectColor{2} = [0.15 0.15 0.15];
rectColor{3} = [0.22 0.22 0.22];
rectColor{4} = [0.30 0.30 0.30];
rectColor{5} = [0.40 0.40 0.40];
rectColor{6} = [0.55 0.55 0.55];
rectColor{7} = [0.7 0.7 0.7];
rectColor{8} = [0.85 0.85 0.85];
rectColor{9} = [1 1 1];

%----------------------------------------------------------------------
%                           Experiment
%----------------------------------------------------------------------

% Experimental instructions
line1 = 'You will see a sequence of lights in 3 different positions';
line2 = 'Your task is to find the sequence with the brightest light overall';
line3 = 'You will do this in 2 steps';
line4 = 'When the first question mark appears, indicate the sequence with the DARKEST light';
line5 = 'by pressing the corresponding arrow key';
line6 = 'Press the left arrow key for the left sequence, the right arrow key for the right sequences';
line7 = 'and the up arrow key for the upper sequence';
line8 = 'This sequence will be removed and you will see the remaining 2 sequences of lights again';
line9 = 'When the second question mark appears, indicate the BRIGHTEST sequence'; 
line10 = 'of lights from the remaining 2';
line11 = 'Press any key to see the next instruction';
line12 = 'At the end of the experiment, you will be awarded a sum of money associated with your decisions';
line13 = 'Focus on the central cross at all times';
 
% Draw all the text in one go
Screen('TextSize', window, 25);
Screen('DrawText', window, line1, screenXpixels*0.1, screenYpixels*0.1, white);
Screen('DrawText', window, line2, screenXpixels*0.1, screenYpixels*0.175, white);
Screen('DrawText', window, line3, screenXpixels*0.1, screenYpixels*0.25, white);
Screen('DrawText', window, line4, screenXpixels*0.1, screenYpixels*0.325, white);
Screen('DrawText', window, line5, screenXpixels*0.1, screenYpixels*0.40, white);
Screen('DrawText', window, line6, screenXpixels*0.1, screenYpixels*0.475, white);
Screen('DrawText', window, line7, screenXpixels*0.1, screenYpixels*0.55, white);
Screen('DrawText', window, line8, screenXpixels*0.1, screenYpixels*0.625, white);
Screen('DrawText', window, line9, screenXpixels*0.1, screenYpixels*0.70, white);
Screen('DrawText', window, line10, screenXpixels*0.1, screenYpixels*0.775, white);
Screen('DrawText', window, line11, screenXpixels*0.1, screenYpixels*0.85, white);
Screen('Flip', window);  
KbStrokeWait;

Screen('DrawText', window, line12, screenXpixels*0.1, screenYpixels*0.4, white);
Screen('DrawText', window, line13, screenXpixels*0.1, screenYpixels*0.5, white);
Screen('Flip', window);
KbStrokeWait;


for currentblock = 1:nBlocks

    for currenttrialinblock = 1:numel(randtemp)

    % Coutning up the trial variable
    newtrial = newtrial + 1;

    % Define distributions 
        if randtemp(currenttrialinblock) == 1 % No mean difference (control)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        seq3 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 2  % Small mean difference
        seq1 = dis(1, 4, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        seq3 = dis(1, 6, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 3  % Large mean difference
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        seq3 = dis(1, 7, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 4 % No mean difference (manipulation)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        seq3 = dis(1, 5, 9, 1, 12);
        end  

    % Define color matrices
    seq1_colors = zeros(12,3);
    seq2_colors = zeros(12,3);
    seq3_colors = zeros(12,3);

    % Substitute numbers with grayscale images
    for i = 1:12
       seq1_colors(i, 1:3) = rectColor{seq1(i)};
    end

    for i = 1:12
       seq2_colors(i, 1:3) = rectColor{seq2(i)};     
    end

    for i = 1:12
       seq3_colors(i, 1:3) = rectColor{seq3(i)};     
    end

    % Randomise position of sequences
    randpos = Shuffle({centeredRect_left, centeredRect_up, centeredRect_right});

    % Randomise which sequence is chosen alongside the rejected sequence in the
    % manipulation condition
    rand1 = Shuffle({seq1_colors, seq2_colors});
    rand2 = Shuffle({seq1_colors, seq3_colors});
    rand3 = Shuffle({seq2_colors, seq3_colors});

    % Fixation cross
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
    Screen('Flip', window, [], 1);
    center_focused = 0;
    timer_set = 0;
    crosshairFixationTimePass = 0;
    
    % Trial count message for .edf file
    if ~MouseInsteadOfGaze
        sample = Eyelink('NewestFloatSample');
        status=Eyelink('message',['Trial ' num2str(currenttrialinblock)]);
        if status~=0
            error(['message error, status: ', num2str(status)])
        end
    end
    if ~MouseInsteadOfGaze
        status=Eyelink('message','Trial Start');
        if status~=0
            error(['message error, status: ', num2str(status)])
        end
    end
    
    % Check for initial fixation
    if(sample.gx(whichEye) >= xCenter-FW && sample.gx(whichEye) <= xCenter+FW && sample.gy(whichEye) >= yCenter-FW && sample.gy(whichEye) <= yCenter+FW)
        if(timer_set == 0)
            current_time = GetSecs;
            timer_set = 1;
        else
            running_time = GetSecs - current_time;
            if(running_time >= numSecs)
                crosshairFixationTimePass = 1;
            end
        end
        %sample = Eyelink('NewestFloatSample');
        if(crosshairFixationTimePass == 1)
            RECORD_DATA{entryNumber, 1} = currenttrialinblock;
            RECORD_DATA{entryNumber, 2} = GetSecs;
            RECORD_DATA{entryNumber, 3} = 'Central Cross Fixation';
            RECORD_DATA{entryNumber, 4} = [sample.gx(whichEye), sample.gy(whichEye), numSecs];
            entryNumber = entryNumber + 1;
            center_focused = 1;
        end
    else
        timer_set = 0;
    end
    while(center_focused == 1)
        ListenChar(2)
        if ~MouseInsteadOfGaze
            sample = Eyelink('NewestFloatSample');
        else
            [sample.gx(whichEye),sample.gy(whichEye),buttons] = GetMouse(window);
        end
        % Eye Position Data
        RECORD_DATA{entryNumber, 1} = currenttrialinblock;
        RECORD_DATA{entryNumber, 2} = GetSecs;
        RECORD_DATA{entryNumber, 3} = 'Eye Position';
        RECORD_DATA{entryNumber, 4} = [sample.gx(whichEye), sample.gy(whichEye)];
        entryNumber = entryNumber + 1;

        Screen('DrawLines', window, allCoords, lineWidthPix, grey, [xCenter yCenter], 2);
        [VBLTimestamp StimulusOnset Fliptime] = Screen('Flip', window, 0, 1);

        if(sample.gx(whichEye) >= xCenter-FW && sample.gx(whichEye) <= xCenter+FW && sample.gy(whichEye) >= yCenter-FW && sample.gy(whichEye) <= yCenter+FW)
            %sample = Eyelink('NewestFloatSample');
            RECORD_DATA{entryNumber, 1} = currenttrialinblock;
            RECORD_DATA{entryNumber, 2} = GetSecs;
            RECORD_DATA{entryNumber, 3} = 'Central Cross Fixation';
            RECORD_DATA{entryNumber, 4} = [sample.gx(whichEye), sample.gy(whichEye), numSecs];
            entryNumber = entryNumber + 1;
            center_focused = 1;
        else
            return;  
        end
        [keyIsDown,secs, keyCode, deltaSecs] = KbCheck();
        if(keyCode(Q_ButtonPress))% Someone pressed 'q'
            RECORD_DATA{entryNumber, 1} = currenttrialinblock;
            RECORD_DATA{entryNumber, 2} = GetSecs;
            RECORD_DATA{entryNumber, 3} = 'Calibrate_key Pressed';
            RECORD_DATA{entryNumber, 4} = 0;
            entryNumber = entryNumber + 1;
            calibrate_flag = 1;
            %             disp(find(keyCode))%*
            return;
        end
        %         elseif(keyCode(End_ButtonPress))% Someone pressed 'End'
        if(keyCode(End_ButtonPress))% Someone pressed 'End'
            RECORD_DATA{entryNumber, 1} = currenttrialinblock;
            RECORD_DATA{entryNumber, 2} = GetSecs;
            RECORD_DATA{entryNumber, 3} = 'Quit_key Pressed';
            RECORD_DATA{entryNumber, 4} = 0;
            entryNumber = entryNumber + 1;
            quit_flag = 1;
            %             disp(find(keyCode))%*
            return;
        else
        end
        if toc > maxTrlTime
            if ~MouseInsteadOfGaze
                if ~DebugFlag
                    Eyelink('StopRecording');
                    Eyelink('Shutdown');
                end
            end
            Screen('CloseAll');
            sca;
            ListenChar(0)
            keyboard
        end
        % Present stimulus
        for currentFrame1 = 1:nFrames

            Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);

            Screen('FillRect', window, seq1_colors(currentFrame1, 1:3), centeredRect_left);
            Screen('FillRect', window, seq2_colors(currentFrame1, 1:3), centeredRect_up);    
            Screen('FillRect', window, seq3_colors(currentFrame1, 1:3), centeredRect_right); 
            Screen('Flip', window);
            WaitSecs(0.75);

            Screen('FillRect', window, [0 0 0]);
            Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
            Screen('Flip', window);
            WaitSecs(0.1);
        end

        % Question mark
        Screen('TextSize', window, 120);
        Screen('DrawText', window, '?', screenXpixels*0.48, screenYpixels*0.45, white);
        Screen('Flip', window)

        % Timestamp
        questionmarkOnset1 = GetSecs();

        % Check the keyboard to see if a button has been pressed
        [secs1, keyCode1] = KbStrokeWait;

        % Make sure that only arrow keys are pressed
        number_tries = 1;
        while number_tries < 3
            if ismember(KbName(keyCode1), {'LeftArrow' 'RightArrow' 'UpArrow'})
            break;
            else
                Screen('TextSize', window, 25);
                Screen('DrawText', window, 'Please only select an arrow key to indicate your choice', screenXpixels*0.1, screenYpixels*0.5, white);
                Screen('Flip', window);
                WaitSecs(2.0);

                % Question mark
                Screen('TextSize', window, 120);
                Screen('DrawText', window, '?', screenXpixels*0.48, screenYpixels*0.45, white);
                Screen('Flip', window)

                % Timestamp
                questionmarkOnset1 = GetSecs();

                % Check the keyboard to see if a button has been pressed
                [secs1, keyCode1] = KbStrokeWait;

                number_tries = number_tries + 1;
            end
        end

        % Second stage
        Screen('FillRect', window, [0 0 0]);
        Screen('Flip', window);  

        % Fixation cross
        Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
        Screen('Flip', window, [], 1);
        WaitSecs(1);

        % Present stimulus
        for currentFrame2 = 1:nFrames

            Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);


        if randtemp(currenttrialinblock) < 4
            if keyCode1(escapeKey)
               ShowCursor;  
               sca;
               return
            elseif keyCode1(leftKey)
               if randpos{1} == centeredRect_left  
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_left
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_left
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq2_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            elseif keyCode1(rightKey)
               if randpos{1} == centeredRect_right   
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_right
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_right
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq2_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            elseif keyCode1(upKey)
               if randpos{1} == centeredRect_up  
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_up
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq3_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_up
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window,  seq2_colors(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            end

        elseif randtemp(currenttrialinblock) == 4
           if keyCode1(leftKey)
               if randpos{1} == centeredRect_left    
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand3{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_left
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand2{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_left
               Screen('FillRect', window, seq3_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand1{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            elseif keyCode1(rightKey)
               if randpos{1} == centeredRect_right  
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand3{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_right
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand2{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_right
               Screen('FillRect', window, seq3_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand1{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            elseif keyCode1(upKey)
              if randpos{1} == centeredRect_up   
               Screen('FillRect', window, seq1_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand3{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{2} == centeredRect_up
               Screen('FillRect', window, seq2_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand2{1}(currentFrame2, 1:3), centeredRect_left);
               Screen('Flip', window);
               WaitSecs(0.5);  
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               elseif randpos{3} == centeredRect_up
               Screen('FillRect', window, seq3_colors(currentFrame2, 1:3), centeredRect_right);    
               Screen('FillRect', window, rand1{1}(currentFrame2, 1:3), centeredRect_left); 
               Screen('Flip', window);
               WaitSecs(0.5);
               Screen('FillRect', window, [0 0 0]);
               Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
               Screen('Flip', window);
               WaitSecs(0.1);
               end
            end
        end

        end  

        % Question mark
        Screen('TextSize', window, 120);
        Screen('DrawText', window, '?', screenXpixels*0.48, screenYpixels*0.45, white);  
        Screen('Flip', window)

        % Timestamp
        questionmarkOnset2 = GetSecs();

        % Check the keyboard to see if a button has been pressed
        [secs2, keyCode2] = KbStrokeWait;

        % Ensure only left or right arrow key is pressed
        number_tries_2 = 1;
        while number_tries_2 < 3
            if ismember(KbName(keyCode2), {'LeftArrow' 'RightArrow'})
            break;
            else
                Screen('TextSize', window, 25);
                Screen('DrawText', window, 'Please only select the left or right arrow key to indicate your choice', screenXpixels*0.1, screenYpixels*0.5, white);
                Screen('Flip', window);
                WaitSecs(2.0);

                % Question mark
                Screen('TextSize', window, 120);
                Screen('DrawText', window, '?', screenXpixels*0.48, screenYpixels*0.45, white);
                Screen('Flip', window)

                % Timestamp
                questionmarkOnset2 = GetSecs();

                % Check the keyboard to see if a button has been pressed
                [secs2, keyCode2] = KbStrokeWait;

                number_tries_2 = number_tries_2 + 1;
            end
        end
    end
    % Change screen back to blue
    Screen('FillRect', window, [0 0 0]);
    Screen('Flip', window);

    % Results matrix 
    if randtemp(currenttrialinblock) == 1
    resultsMatrix(newtrial).TrialType = randtemp(1); % Type of trial (see definitions of sequences)
    resultsMatrix(newtrial).S1Numbers = num2str(seq1); % List of numbers in the first sequence 
    resultsMatrix(newtrial).S1Mean = 5;
    resultsMatrix(newtrial).S1Variance = 1;
    resultsMatrix(newtrial).S1Position = randpos{1};
    resultsMatrix(newtrial).S2Numbers = num2str(seq2);
    resultsMatrix(newtrial).S2Mean = 5;
    resultsMatrix(newtrial).S2Variance = 4;
    resultsMatrix(newtrial).S2Position = randpos{2};
    resultsMatrix(newtrial).S3Numbers = num2str(seq3);
    resultsMatrix(newtrial).S3Mean = 5;
    resultsMatrix(newtrial).S3Variance = 1;
    resultsMatrix(newtrial).S3Position = randpos{3};
    resultsMatrix(newtrial).Key1 = KbName(keyCode1);
    resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
    if keyCode1(rightKey)
          if randpos{1} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
          end
    elseif keyCode1(leftKey)
        if randpos{1} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
        end
    elseif keyCode1(upKey)
         if randpos{1} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 20;
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
         end
    end
    resultsMatrix(newtrial).Key2 = KbName(keyCode2);
    resultsMatrix(newtrial).Timeq2 = questionmarkOnset2 - secs2;

    elseif randtemp(currenttrialinblock) == 2
    resultsMatrix(newtrial).TrialType = randtemp(2);
    resultsMatrix(newtrial).S1Numbers = num2str(seq1);
    resultsMatrix(newtrial).S1Mean = 4;
    resultsMatrix(newtrial).S1Variance = 1;
    resultsMatrix(newtrial).S1Position = randpos{1};
    resultsMatrix(newtrial).S2Numbers = num2str(seq2);
    resultsMatrix(newtrial).S2Mean = 5;
    resultsMatrix(newtrial).S2Variance = 4;
    resultsMatrix(newtrial).S2Position = randpos{2};
    resultsMatrix(newtrial).S3Numbers = num2str(seq3);
    resultsMatrix(newtrial).S3Mean = 6;
    resultsMatrix(newtrial).S3Variance = 1;
    resultsMatrix(newtrial).S3Position = randpos{3};
    resultsMatrix(newtrial).Key1 = KbName(keyCode1);
    resultsMatrix(newtrial).Timeq1 = secs1;
    if keyCode1(rightKey)
          if randpos{1} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
          end
    elseif keyCode1(leftKey)
        if randpos{1} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
        end
    elseif keyCode1(upKey)
         if randpos{1} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 6;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 4;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
         end
    end
    resultsMatrix(newtrial).Key2 = KbName(keyCode2);
    resultsMatrix(newtrial).Timeq2 = secs2;


    elseif randtemp(currenttrialinblock) == 3
    resultsMatrix(newtrial).TrialType = randtemp(3);
    resultsMatrix(newtrial).S1Numbers = num2str(seq1);
    resultsMatrix(newtrial).S1Mean = 3;
    resultsMatrix(newtrial).S1Variance = 1;
    resultsMatrix(newtrial).S1Position = randpos{1};
    resultsMatrix(newtrial).S2Numbers = num2str(seq2);
    resultsMatrix(newtrial).S2Mean = 5;
    resultsMatrix(newtrial).S2Variance = 1;
    resultsMatrix(newtrial).S2Position = randpos{2};
    resultsMatrix(newtrial).S3Numbers = num2str(seq3);
    resultsMatrix(newtrial).S3Mean = 7;
    resultsMatrix(newtrial).S3Variance = 1;
    resultsMatrix(newtrial).S3Position = randpos{3};
    resultsMatrix(newtrial).Key1 = KbName(keyCode1);
    resultsMatrix(newtrial).Timeq1 = secs1;
    if keyCode1(rightKey)
          if randpos{1} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
          end
    elseif keyCode1(leftKey)
        if randpos{1} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_left
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
        end
    elseif keyCode1(upKey)
         if randpos{1} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{2} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 7;
              resultsMatrix(newtrial).Sleftvariance = 1;
          elseif randpos{3} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 3;
              resultsMatrix(newtrial).Srightvariance = 1;
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
         end
    end
    resultsMatrix(newtrial).Key2 = KbName(keyCode2);
    resultsMatrix(newtrial).Timeq2 = secs2;

    elseif randtemp(currenttrialinblock) == 4
    resultsMatrix(newtrial).TrialType = randtemp(4);
    resultsMatrix(newtrial).S1Numbers = num2str(seq1);
    resultsMatrix(newtrial).S1Mean = 5;
    resultsMatrix(newtrial).S1Variance = 1;
    resultsMatrix(newtrial).S1Position = randpos{1};
    resultsMatrix(newtrial).S2Numbers = num2str(seq2);
    resultsMatrix(newtrial).S2Mean = 5;
    resultsMatrix(newtrial).S2Variance = 4;
    resultsMatrix(newtrial).S2Position = randpos{2};
    resultsMatrix(newtrial).S3Numbers = num2str(seq3);
    resultsMatrix(newtrial).S3Mean = 5;
    resultsMatrix(newtrial).S3Variance = 1;
    resultsMatrix(newtrial).S3Position = randpos{3};
    resultsMatrix(newtrial).Key1 = KbName(keyCode1);
    resultsMatrix(newtrial).Timeq1 = secs1;
    if keyCode1(leftKey)
         if randpos{1} == centeredRect_left   
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand3{1} == seq3_colors
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand3{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
              end
          elseif randpos{2} == centeredRect_left   
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              if rand2{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand2{1} == seq3_colors
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1; 
              end
         elseif randpos{3} == centeredRect_left   
              resultsMatrix(newtrial).Srightnumber = 3;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand1{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand1{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4; 
              end 
         end
    elseif keyCode1(rightKey)
         if randpos{1} == centeredRect_right   
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand3{1} == seq3
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand3{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
              end
          elseif randpos{2} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              if rand2{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand2{1} == seq3
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1; 
              end
          elseif randpos{3} == centeredRect_right
              resultsMatrix(newtrial).Srightnumber = 3;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand1{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand1{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4; 
              end 
         end
    elseif keyCode1(upKey)
          if randpos{1} == centeredRect_up   
              resultsMatrix(newtrial).Srightnumber = 1;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand3{1} == seq3
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand3{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4;
              end
          elseif randpos{2} == centeredRect_up
              resultsMatrix(newtrial).Srightnumber = 2;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 4;
              if rand2{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand2{1} == seq3
              resultsMatrix(newtrial).Sleftnumber = 3;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1; 
              end
         elseif randpos{3} == centeredRect_up  
              resultsMatrix(newtrial).Srightnumber = 3;
              resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
              resultsMatrix(newtrial).Srightmean = 5;
              resultsMatrix(newtrial).Srightvariance = 1;
              if rand1{1} == seq1_colors
              resultsMatrix(newtrial).Sleftnumber = 1;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 1;
              elseif rand1{1} == seq2_colors
              resultsMatrix(newtrial).Sleftnumber = 2;
              resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
              resultsMatrix(newtrial).Sleftmean = 5;
              resultsMatrix(newtrial).Sleftvariance = 4; 
              end 
          end
    end


    resultsMatrix(newtrial).Key2 = KbName(keyCode2)                ;
    resultsMatrix(newtrial).Timeq2 = secs2;

    end


    end

end

choosing_trial_prize_1 = randi(4); % Would be 200
choosing_trial_prize_2 = randi(4); % Would be 200   
if resultsMatrix(choosing_trial_prize_1).Key2 == "LeftArrow"
    winning_distribution_1 = resultsMatrix(choosing_trial_prize_1).Sleftnumbers;
elseif resultsMatrix(choosing_trial_prize_1).Key2 == "RightArrow"
    winning_distribution_1 = resultsMatrix(choosing_trial_prize_1).Srightnumbers;
end
  
if resultsMatrix(choosing_trial_prize_2).Key2 == "LeftArrow"
    winning_distribution_2 = resultsMatrix(choosing_trial_prize_2).Sleftnumbers;
elseif resultsMatrix(choosing_trial_prize_2).Key2 == "RightArrow"         
    winning_distribution_2 = resultsMatrix(choosing_trial_prize_2).Srightnumbers;
end

prize_1_numbers = str2num(winning_distribution_1);
prize_1 = prize_1_numbers(randperm(length(prize_1_numbers),1));
prize_2_numbers = str2num(winning_distribution_2);
prize_2 = prize_2_numbers(randperm(length(prize_2_numbers),1));
  overall_prize = prize_1 + prize_2;

line10 = 'Congratulations, you have won:';
line11 = num2str(overall_prize);
line12 = 'dollars';
 
% Draw all the text in one go
Screen('TextSize', window, 30);
Screen('DrawText', window, line10, screenXpixels*0.2, screenYpixels*0.4, white);
Screen('DrawText', window, line11, screenXpixels*0.2, screenYpixels*0.5, white);
Screen('DrawText', window, line12, screenXpixels*0.25  , screenYpixels*0.5, white);



% Flip to the screen
Screen('Flip', window);

% Wait for a key press
KbStrokeWait;

% Clear the screen
sca;

catch me
    sca
    rethrow(me)
end


