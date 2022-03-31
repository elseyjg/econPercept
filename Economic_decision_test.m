try
% Clear the workspace
close all;
clearvars;
sca;

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

%----------------------------------------------------------------------
%                           Experiment
%----------------------------------------------------------------------


% Experimental instructions
line1 = 'You will see a sequence of numbers in 3 different positions';
line2 = 'Your task is to find the sequence with the highest numbers overall';
line3 = 'You will do this in 2 steps';
line4 = 'When the first question mark appears, indicate the sequence with the lowest numbers';
line5 = 'by pressing the corresponding arrow key';
line6 = 'Press the left arrow key for the left sequence, the right arrow key for the right sequences';
line7 = 'and the up arrow key for the upper sequence';
line8 = 'This sequence will be removed and you will see the remaining 2 sequences of numbers again';
line9 = 'When the second question mark appears, indicate the sequence with';
line10 = 'the highest numbers from the remaining 2';
line11 = 'Press any key to see the next instruction';
line12 = 'At the end of the trial, you will be awarded a sum of money associated with your decisions';
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

Screen('DrawText', window, line12, screenXpixels*0.1  , screenYpixels*0.4, white);
Screen('DrawText', window, line13, screenXpixels*0.1  , screenYpixels*0.5, white);
Screen('Flip', window);
KbStrokeWait;

% Trial loop

for currentblock = 1:nBlocks

for currenttrialinblock = 1:numel(randtemp)

% Counting up the trial variable
newtrial = newtrial + 1;

% Derive distributions    
    if randtemp(currenttrialinblock) == 1 % No mean difference (control)
    seq1 = dis(1, 5, 9, 1, 12);
    seq2 = dis(4, 5, 9, 1, 12);
    seq3 = dis(1, 5, 9, 1, 12);
    elseif randtemp(currenttrialinblock) == 2  % Small mean difference
    seq1 = dis(1, 4, 9, 1, 12);
    seq2 = dis(1, 5, 9, 1, 12);
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

% Randomise position of sequences
randpos = Shuffle({left, right, up});

% Randomise which sequence is chosen alongside the rejected sequence in the
% manipulation condition
rand1 = Shuffle({seq1, seq2});
rand2 = Shuffle({seq1, seq3});
rand3 = Shuffle({seq2, seq3});

% Fixation cross
Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window, [], 1);
WaitSecs(1);

% Present stimulus
for currentFrame1 = 1:nFrames  
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
    Screen('TextSize', window, 120);
    Screen('DrawText', window, num2str(seq1(currentFrame1)), randpos{1}(1), randpos{1}(2), [1 1 1]);
    Screen('DrawText', window, num2str(seq2(currentFrame1)), randpos{2}(1), randpos{2}(2), [1 1 1]);
    Screen('DrawText', window, num2str(seq3(currentFrame1)), randpos{3}(1), randpos{3}(2), [1 1 1]);
    Screen('Flip', window);
    WaitSecs(0.75);
    Screen('FillRect', window, black);
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
Screen('FillRect', window, black);
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
       if randpos{1} == left    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == left
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == left
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq2(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       end
    elseif keyCode1(rightKey)
       if randpos{1} == right    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == right
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == right
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq2(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       end
    elseif keyCode1(upKey)
       if randpos{1} == up    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == up
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq3(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == up
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(seq2(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       end
    end

elseif randtemp(currenttrialinblock) == 4
   if keyCode1(leftKey)
       if randpos{1} == left    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand3{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == left
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand2{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == left
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq3(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand1{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       end
    elseif keyCode1(rightKey)
       if randpos{1} == right    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand3{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == right
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand2{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == right
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq3(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand1{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       end
    elseif keyCode1(upKey)
      if randpos{1} == up    
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq1(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand3{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{2} == up
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq2(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand2{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
       Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
       Screen('Flip', window);
       WaitSecs(0.1);
       elseif randpos{3} == up
       Screen('TextSize', window, 120);
       Screen('DrawText', window, num2str(seq3(currentFrame2)), rightX, rightY, [1 1 1]);
       Screen('DrawText', window,  num2str(rand1{1}(currentFrame2)), leftX, leftY, [1 1 1]);
       Screen('Flip', window);
       WaitSecs(0.5);
       Screen('FillRect', window, black);
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

% Ensure that only the left or right arrow key is pressed
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


% Turn screen back to black
Screen('FillRect', window, black);
Screen('Flip', window);

% Results matrix 
if randtemp(currenttrialinblock) == 1
resultsMatrix(newtrial).TrialType = randtemp(currenttrialinblock);
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
resultsMatrix(newtrial).Timeq1 = questionmarkOnset1 - secs1;
if keyCode1(rightKey)
      if randpos{1} == right
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 10;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 10;
      elseif randpos{2} == right
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == right
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
    if randpos{1} == left
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == left
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == left
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
     if randpos{1} == up
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == up
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == up
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
resultsMatrix(newtrial).TrialType = randtemp(currenttrialinblock);
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
      if randpos{1} == right
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == right
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 4;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == right
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
    if randpos{1} == left
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == left
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 4;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == left
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
     if randpos{1} == up
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == up
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 4;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 6;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == up
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
resultsMatrix(newtrial).TrialType = randtemp(currenttrialinblock);
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
      if randpos{1} == right
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == right
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 3;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == right
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
    if randpos{1} == left
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == left
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 3;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == left
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
     if randpos{1} == up
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{2} == up
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 3;
          resultsMatrix(newtrial).Srightvariance = 1;
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 7;
          resultsMatrix(newtrial).Sleftvariance = 1;
      elseif randpos{3} == up
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
resultsMatrix(newtrial).TrialType = randtemp(currenttrialinblock);
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
     if randpos{1} == left    
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand3{1} == seq3
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand3{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4;
          end
      elseif randpos{2} == left
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          if rand2{1} == seq1
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
     elseif randpos{3} == left
          resultsMatrix(newtrial).Srightnumber = 3;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand1{1} == seq1
          resultsMatrix(newtrial).Sleftnumber = 1;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand1{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4; 
          end 
     end
elseif keyCode1(rightKey)
     if randpos{1} == right    
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand3{1} == seq3
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand3{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4;
          end
      elseif randpos{2} == right
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          if rand2{1} == seq1
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
      elseif randpos{3} == right
          resultsMatrix(newtrial).Srightnumber = 3;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand1{1} == seq1
          resultsMatrix(newtrial).Sleftnumber = 1;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand1{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4; 
          end 
     end
elseif keyCode1(upKey)
      if randpos{1} == up   
          resultsMatrix(newtrial).Srightnumber = 1;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq1);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand3{1} == seq3
          resultsMatrix(newtrial).Sleftnumber = 3;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq3);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand3{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4;
          end
      elseif randpos{2} == up
          resultsMatrix(newtrial).Srightnumber = 2;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq2);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 4;
          if rand2{1} == seq1
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
     elseif randpos{3} == up
          resultsMatrix(newtrial).Srightnumber = 3;
          resultsMatrix(newtrial).Srightnumbers = num2str(seq3);
          resultsMatrix(newtrial).Srightmean = 5;
          resultsMatrix(newtrial).Srightvariance = 1;
          if rand1{1} == seq1
          resultsMatrix(newtrial).Sleftnumber = 1;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq1);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 1;
          elseif rand1{1} == seq2
          resultsMatrix(newtrial).Sleftnumber = 2;
          resultsMatrix(newtrial).Sleftnumbers = num2str(seq2);
          resultsMatrix(newtrial).Sleftmean = 5;
          resultsMatrix(newtrial).Sleftvariance = 4; 
          end 
      end
end

resultsMatrix(newtrial).Key2 = KbName(keyCode2)  ;
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
Screen('DrawText', window, line12, screenXpixels*0.25, screenYpixels*0.5, white);

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