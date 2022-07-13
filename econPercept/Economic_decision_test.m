function [resultsMatrix] = Economic_trial_test(SubjectID, Date, RunNum, seed, nBlocks, TrainingTrials, filename, outDir)

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
[window, windowRect] = PsychImaging('OpenWindow', screenNumber, black);

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
%                  Define positions of sequences
%----------------------------------------------------------------------

leftX = screenXpixels*0.40;
leftY = screenYpixels*0.55;
rightX = screenXpixels*0.55;
rightY = screenYpixels*0.55  ;
upX = screenXpixels*0.48;
upY = screenYpixels*0.31;

left = [leftX leftY];
right = [rightX rightY];
up = [upX upY];


%----------------------------------------------------------------------
%                  Rect dimensions and positions
%----------------------------------------------------------------------

% Make a base Rect of 200 by 200 pixels
baseRect = [0 0 120 120];

% Screen positions of our three rectangles
leftX_rect = screenXpixels*0.40;
leftY_rect = screenYpixels*0.67;
rightX_rect = screenXpixels*0.60;
rightY_rect = screenYpixels*0.67;
upX_rect = screenXpixels*0.5;
upY_rect =  screenYpixels*0.33;

squareXpos = [leftX_rect rightX_rect upX_rect];
squareYpos = [leftY_rect rightY_rect upY_rect];
numSquares1 = 3;
numSquares2 = 2;


% Make our rectangle coordinates
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
 
trialorder = [1:4];
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
resultsMatrix = struct('Srightnumber', {}, 'Srightnumbers', {}, 'Srightmean', {}, 'Srightvariance', {}, ...
'Sleftnumber', {}, 'Sleftnumbers', {}, 'Sleftmean', {}, 'Sleftvariance', {}, 'Key2', {},  'Timeq2', {});


% Make a directory for the results
resultsDir = [cd '/Results/'];
if exist(resultsDir, 'dir') < 1
    mkdir(resultsDir);
end

%----------------------------------------------------------------------
%                           Experiment
%----------------------------------------------------------------------

PsychHID('KbQueueCreate');
PsychHID('KbQueueStart');
if ~MouseInsteadOfGaze
    Eyelink('StartRecording');
end

% Experimental instructions
line1 = 'You will see a sequence of numbers in 2 different positions';
line2 = 'Your task is to find the sequence with the highest/lowest numbers';
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
        if randtemp(currenttrialinblock) == 1 % No mean difference (brightest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 2  % No mean difference (darkest)
        seq1 = dis(1, 5, 9, 1, 12);
        seq2 = dis(4, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 3  % Large mean difference (brightest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        elseif randtemp(currenttrialinblock) == 4  % Large mean difference (darkest)
        seq1 = dis(1, 3, 9, 1, 12);
        seq2 = dis(1, 5, 9, 1, 12);
        end  

        % Randomise position of sequences
        randpos = Shuffle({left, right, up});

        % Randomise which sequence is chosen alongside the rejected sequence in the
        % manipulation condition
        rand1 = Shuffle({seq1, seq2});
        rand2 = Shuffle({seq1, seq3});
        rand3 = Shuffle({seq2, seq3});

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
        
        % Give choice instruction
        Screen('TextSize', window, 120);
        if randtemp(currenttrialinblock) == 1
            Screen('DrawText', window, 'Accept the highest value sequence', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 2
            Screen('DrawText', window, 'Reject the lowest value sequence', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 3
            Screen('DrawText', window, 'Accept the highest value sequence ', screenXpixels*0.48, screenYpixels*0.45, white);
        elseif randtemp(currenttrialinblock) == 4
            Screen('DrawText', window, 'Choose the darkest light', screenXpixels*0.48, screenYpixels*0.45, white);
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
            Screen('TextSize', window, 120);
            Screen('DrawText', window, num2str(seq1(currentFrame1)), randpos{1}(1), randpos{1}(2), [1 1 1]);
            Screen('DrawText', window, num2str(seq2(currentFrame1)), randpos{2}(1), randpos{2}(2), [1 1 1]);
            Screen('Flip', window);
            WaitSecs(0.75);
            Screen('FillRect', window, black);
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

        
        % Turn screen back to black
        Screen('FillRect', window, black);
        Screen('Flip', window);

        % Results matrix 
        if randtemp(currenttrialinblock) == 1
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

        elseif randtemp(currenttrialinblock) == 2
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


        elseif randtemp(currenttrialinblock) == 3
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
        resultsMatrix(newtrial).Timeq1 = secs1;

        elseif randtemp(currenttrialinblock) == 4
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
        resultsMatrix(newtrial).Timeq1 = secs1;

        
        end
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
% Screen('DrawText', window, line12, screenXpixels*0.25, screenYpixels*0.5, white);

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

end
