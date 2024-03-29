function [resultsMatrix] = Perceptual_trial_test(SubjectID, Date, RunNum, seed, nBlocks, TrainingTrials, filename, outDir)

global MouseInsteadOfGaze whichEye
    % which eye is being tracked left(1) or right(2)
    whichEye = 2;
    MouseInsteadOfGaze = 1; % 1 means mouse
    maxTrlTime = 300; % seconds

try

rng('default')
rng(str2num([SubjectID, seed]));

entryNumber = 1;
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
Screen('TextFont', window, 'Ariel');
Screen('TextSize', window, 36);

% Get the centre coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Length of time and number of frames we will use for each drawing test
ISI = 300;
numSecs = ISI/1000;
numFrames = round(numSecs / ifi);


%----------------------------------------------------------------------
%                       Keyboard information
%----------------------------------------------------------------------

% Define the keyboard keys that are listened for. We will be using the left
% and right arrow keys as response keys for the task and the escape key as
% a exit/reset key
% escapeKey = KbName('ESCAPE');
% leftKey = KbName('LeftArrow');
% rightKey = KbName('RightArrow');
% downKey = KbName('DownArrow');
% upKey = KbName('UpArrow');

if ismac
    E_ButtonPress = 8;
    Q_ButtonPress = 20;
    End_ButtonPress = 39;
    one_ButtonPress = 30;
    two_ButtonPress = 31;
    three_ButtonPress = 32;
    four_ButtonPress = 33;
    escapeKey = 41;
    leftKey = 80;
    rightKey = 79;
    downKey = 81;
    upKey = 82;
else %is Windows
    escapeKey = KbName('ESCAPE');
    leftKey = KbName('LeftArrow');
    rightKey = KbName('RightArrow');
    downKey = KbName('DownArrow');
    upKey = KbName('UpArrow');
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


%----------------------------------------------------------------------
%                       Fixation cross
%----------------------------------------------------------------------
% Here we set the size of the arms of our fixation cross
fixCrossDimPix = 20;
FW = fixCrossDimPix*1.5; % Fixation window to flip the fixation cross
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
 
trialorder = [1:28];
nTrials = size(trialorder,2);
randtemp = Shuffle(trialorder);

%----------------------------------------------------------------------
%                 Defining trial variable 
%----------------------------------------------------------------------
 
newtrial = 0;

%----------------------------------------------------------------------
%                       Results Matrix
%----------------------------------------------------------------------

% Make a  matrix which which will hold all of our results
resultsMatrix = struct('TrialType', {}, 'Srightnumbers', {}, 'Srightmean', {}, 'Srightvariance', {}, ...
'Sleftnumber', {}, 'Sleftnumbers', {}, 'Sleftmean', {}, 'Sleftvariance', {}, 'Key1', {},  'Timeq1', {});

% Make a directory for the results
resultsDir = [cd '/Results/'];
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end

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

PsychHID('KbQueueCreate');
PsychHID('KbQueueStart');
if ~MouseInsteadOfGaze
    Eyelink('StartRecording');
end

% Experimental instructions
line1 = 'You will see a sequence of lights in 2 different positions';
line2 = 'Your task is to find the sequence with the brightest/darkest light';
line3 = 'You will be instructed as to which choice to make at the start of each sequence';
line4 = 'When the question mark appears, indicate your choice';
line5 = 'by pressing the corresponding arrow key';
line6 = 'At the end of the experiment, you will be awarded a sum of money associated with your decisions';
line7 = 'Focus on the central cross at all times';
 
% Draw all the text in one go
Screen('TextSize', window, 25);
Screen('DrawText', window, line1, screenXpixels*0.1, screenYpixels*0.1, white);
Screen('DrawText', window, line2, screenXpixels*0.1, screenYpixels*0.175, white);
Screen('DrawText', window, line3, screenXpixels*0.1, screenYpixels*0.25, white);
Screen('DrawText', window, line4, screenXpixels*0.1, screenYpixels*0.325, white);
Screen('DrawText', window, line5, screenXpixels*0.1, screenYpixels*0.40, white);
Screen('DrawText', window, line6, screenXpixels*0.1, screenYpixels*0.475, white);
Screen('DrawText', window, line7, screenXpixels*0.1, screenYpixels*0.55, white);
Screen('Flip', window);  
KbStrokeWait;

currentblock = 1;
while currentblock <= nBlocks
    currenttrialinblock = 1;
    while currenttrialinblock <= numel(randtemp)
        if currenttrialinblock == 0
           currenttrialinblock = 1; 
        end
        
        blinkTime = 300; %allow 300 ms to pass between fixations for blinks
        redoTrialFlag = 0;

        % Counting up the trial variable
        newtrial = newtrial + 1;

        % Define distributions 
        if randtemp(currenttrialinblock) == 1 % Small mean difference (brightest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 4, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 2  % Small mean difference (darkest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 4, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 3  % Small mean difference (brightest)
        seq1 = dis(1, 4, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 4  % Small mean difference (darkest)
        seq1 = dis(1, 4, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 5  % Small mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(1, 6, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 6  % Small mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(1, 6, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 7  % Small mean difference (brightest)
        seq1 = dis(1, 6, 9, 1, 12);
        seq2 = dis(1, 7, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 8  % Small mean difference (darkest)
        seq1 = dis(1, 6, 9, 1, 12);
        seq2 = dis(1, 7, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 9  % Large mean difference (brightest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 10  % Large mean difference (darkest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 11  % Large mean difference (brightest)
        seq1 = dis(1, 4, 9, 1, 12);
        seq2 = dis(1, 6, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 12  % Large mean difference (darkest)
        seq1 = dis(1, 4, 9, 1, 12);
        seq2 = dis(1, 6, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 13  % Large mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(1, 7, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 14  % Large mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(1, 7, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 15  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 16  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 17  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 18  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 19  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 20  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 21  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 22  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 23  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 24  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 25  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 26  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 27  % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 28  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        end  

        % Define color matrices
        seq1_colors = zeros(12,3);
        seq2_colors = zeros(12,3);
        

        % Substitute numbers with grayscale images
        for i = 1:12
           seq1_colors(i, 1:3) = rectColor{seq1(i)};
        end

        for i = 1:12
           seq2_colors(i, 1:3) = rectColor{seq2(i)};     
        end

        % Randomise position of sequences
        randpos = Shuffle({centeredRect_left, centeredRect_right});

        % Fixation cross screen (FCS)
        center_focused = 0;
        timer_set = 0;
        crosshairFixationTimePass = 0;

        % Trial count message for .edf file
        if ~MouseInsteadOfGaze
            sample = Eyelink('NewestFloatSample');
            status=Eyelink('message',['Trial ' num2str(trialNumber)]);
            if status~=0
                error(['message error, status: ', num2str(status)])
            end
        end
        
        % Fixation cross
        tic
        Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
        Screen('Flip', window, [], 1);

        if ~MouseInsteadOfGaze
            status=Eyelink('message','Trial Start');
            if status~=0
                error(['message error, status: ', num2str(status)])
            end
        end

        ListenChar(2)
        if ~MouseInsteadOfGaze
            sample = Eyelink('NewestFloatSample');
            %             disp([sample.gx(whichEye),sample.gy(whichEye)])
        else
            [sample.gx(whichEye),sample.gy(whichEye),buttons] = GetMouse(window);
        end
        % Eye Position Data
        RECORD_DATA{entryNumber, 1} = currenttrialinblock;
        RECORD_DATA{entryNumber, 2} = GetSecs;
        RECORD_DATA{entryNumber, 3} = 'Eye Position';
        RECORD_DATA{entryNumber, 4} = [sample.gx(whichEye), sample.gy(whichEye)];
        entryNumber = entryNumber + 1;

        Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
        [VBLTimestamp StimulusOnset Fliptime] = Screen('Flip', window, 0, 1);

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
            center_focused = 0;
        end
        [keyIsDown,secs, keyCode, deltaSecs] = KbCheck();
        if(keyCode(Q_ButtonPress))% Someone pressed 'q'
            RECORD_DATA{entryNumber, 1} = currenttrialinblock;
            RECORD_DATA{entryNumber, 2} = GetSecs;
            RECORD_DATA{entryNumber, 3} = 'Calibrate_key Pressed';
            RECORD_DATA{entryNumber, 4} = 0;
            entryNumber = entryNumber + 1;
            calibrate_flag = 1;
            % disp(find(keyCode))%*
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
        
        % Give choice instruction
        Screen('TextSize', window, 120);
        if randtemp(currenttrialinblock) == 1
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 2
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 3
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 4
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 5
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 6
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 7
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 8
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 9
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 10
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 11
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 12
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 13
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 14
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 15
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 16
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 17
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 18
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 19
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 20
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 21
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 22
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 23
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 24
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
         elseif randtemp(currenttrialinblock) == 25
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 26
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 27
            Screen('DrawText', window, 'Accept the sequence with the brightest light', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 28
            Screen('DrawText', window, 'Reject the sequence with the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
        end
        Screen('Flip', window);
        WaitSecs(0.5);
        
        % Present stimulus
        currentFrame1 = 1;
        while currentFrame1 <= nFrames 
            if ~MouseInsteadOfGaze
                sample = Eyelink('NewestFloatSample');
            else
                [sample.gx(whichEye),sample.gy(whichEye),buttons] = GetMouse(window);
            end
            if(sample.gx(whichEye) >= xCenter-FW && sample.gx(whichEye) <= xCenter+FW && sample.gy(whichEye) >= yCenter-FW && sample.gy(whichEye) <= yCenter+FW)
                center_focused = 1;
                redoTrialFlag = 0;
            else
                center_focused = 0;
                currenttrialinblock = currenttrialinblock-1;
                redoTrialFlag = 1;
            end   
            if redoTrialFlag == 1
                break
            end
            
            Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);

            Screen('FillRect', window, seq1_colors(currentFrame1, 1:3), randpos{1}); 
            Screen('FillRect', window, seq2_colors(currentFrame1, 1:3), randpos{2}); 
            Screen('Flip', window);
            WaitSecs(0.5);

            Screen('FillRect', window, [0 0 0]);
            Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
            Screen('Flip', window);
            WaitSecs(0.1);
            
            currentFrame1 = currentFrame1+1;
        end
        if redoTrialFlag == 1
            continue
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
            if ismember(KbName(keyCode1), {'LeftArrow' 'RightArrow'})
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

        % Change screen back to blue
        Screen('FillRect', window, [0 0 0]);
        Screen('Flip', window);

        % Results matrix 
        if randtemp(currenttrialinblock) == 1
        resultsMatrix(newtrial).TrialType = 1;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;

        if randtemp(currenttrialinblock) == 2
        resultsMatrix(newtrial).TrialType = 2;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;


        elseif randtemp(currenttrialinblock) == 3
        resultsMatrix(newtrial).TrialType = 3;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
            end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = secs1;

        elseif randtemp(currenttrialinblock) == 4
        resultsMatrix(newtrial).TrialType = 4;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
            end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = secs1;

        elseif randtemp(currenttrialinblock) == 5
        resultsMatrix(newtrial).TrialType = 5;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 6
        resultsMatrix(newtrial).TrialType = 6;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 7
        resultsMatrix(newtrial).TrialType = 7;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 8
        resultsMatrix(newtrial).TrialType = 8;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 9
        resultsMatrix(newtrial).TrialType = 9;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 10
        resultsMatrix(newtrial).TrialType = 10;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 3;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 3;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 11
        resultsMatrix(newtrial).TrialType = 11;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 12
        resultsMatrix(newtrial).TrialType = 12;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 6;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 4;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 4;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 6;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 13
        resultsMatrix(newtrial).TrialType = 13;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 14
        resultsMatrix(newtrial).TrialType = 14;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 7;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 7;
                  resultsMatrix(newtrial).Sleftvariance = 1;
             end
        end
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 15
        resultsMatrix(newtrial).TrialType = 15;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 16
        resultsMatrix(newtrial).TrialType = 16;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 17
        resultsMatrix(newtrial).TrialType = 17;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 18
        resultsMatrix(newtrial).TrialType = 18;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        
        elseif randtemp(currenttrialinblock) == 19
        resultsMatrix(newtrial).TrialType = 19;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 20
        resultsMatrix(newtrial).TrialType = 20;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 21
        resultsMatrix(newtrial).TrialType = 21;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 22
        resultsMatrix(newtrial).TrialType = 22;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 23
        resultsMatrix(newtrial).TrialType = 23;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 24
        resultsMatrix(newtrial).TrialType = 24;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 25
        resultsMatrix(newtrial).TrialType = 25;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 26
        resultsMatrix(newtrial).TrialType = 26;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 27
        resultsMatrix(newtrial).TrialType = 27;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        elseif randtemp(currenttrialinblock) == 28
        resultsMatrix(newtrial).TrialType = 28;
        if keyCode1(rightKey)
              if randpos{1} == right
                  resultsMatrix(newtrial).Srightnumber = 1;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 1;
                  resultsMatrix(newtrial).Sleftnumber = 2;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 4;
              elseif randpos{2} == right
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              end
        elseif keyCode1(leftKey)
            if randpos{1} == left
                  resultsMatrix(newtrial).Srightnumber = 2;
                  resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
                  resultsMatrix(newtrial).Srightmean = 5;
                  resultsMatrix(newtrial).Srightvariance = 4;
                  resultsMatrix(newtrial).Sleftnumber = 1;
                  resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
                  resultsMatrix(newtrial).Sleftmean = 5;
                  resultsMatrix(newtrial).Sleftvariance = 1;
              elseif randpos{2} == left
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
        resultsMatrix(newtrial).Key1 = KbName(keyCode1);
        resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
        
        currenttrialinblock = currenttrialinblock + 1;
    end
    currentblock = currentblock + 1;
end


choosing_trial_prize_1 = randi(nTrials); % Would be 200
choosing_trial_prize_2 = randi(nTrials); % Would be 200  

% if resultsMatrix(choosing_trial_prize_1).Key2 == "LeftArrow"
%     winning_distribution_1 = resultsMatrix(choosing_trial_prize_1).Sleftnumbers;
% elseif resultsMatrix(choosing_trial_prize_1).Key2 == "RightArrow"
%     winning_distribution_1 = resultsMatrix(choosing_trial_prize_1).Srightnumbers;
% end
%   
% if resultsMatrix(choosing_trial_prize_2).Key2 == "LeftArrow"
%     winning_distribution_2 = resultsMatrix(choosing_trial_prize_2).Sleftnumbers;
% elseif resultsMatrix(choosing_trial_prize_2).Key2 == "RightArrow"         
%     winning_distribution_2 = resultsMatrix(choosing_trial_prize_2).Srightnumbers;
% end
% 
% prize_1_numbers = str2num(winning_distribution_1);
% prize_1 = prize_1_numbers(randperm(length(prize_1_numbers),1));
% prize_2_numbers = str2num(winning_distribution_2);
% prize_2 = prize_2_numbers(randperm(length(prize_2_numbers),1));
%   overall_prize = prize_1 + prize_2;
% 
% line10 = 'Congratulations, you have won:';
% line11 = num2str(overall_prize);
% line12 = 'dollars';
%  
% % Draw all the text in one go
% Screen('TextSize', window, 30);
% Screen('DrawText', window, line10, screenXpixels*0.2, screenYpixels*0.4, white);
% Screen('DrawText', window, line11, screenXpixels*0.2, screenYpixels*0.5, white);
% Screen('DrawText', window, line12, screenXpixels*0.25  , screenYpixels*0.5, white);
% 


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
