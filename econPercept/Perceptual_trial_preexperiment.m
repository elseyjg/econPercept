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
%                  Rect dimensions and positions
%----------------------------------------------------------------------

% Make a base Rect of 150 by 150 pixels
baseRect = [0 0 150 150];

% Screen positions of the rectangles
squareXpos = [screenXpixels*0.40 screenXpixels*0.60 screenXpixels*0.5];
squareYpos = [screenYpixels*0.67 screenYpixels*0.67 screenYpixels*0.33];

numSquares = 2;

% Make the rectangle coordinates
twoRects = nan(4, 2); 
for i = 1:numSquares
    twoRects(:, i) = CenterRectOnPointd(baseRect, squareXpos(i), squareYpos(i));
end


% Pen width for the frames
penWidthPixels = 6;


%----------------------------------------------------------------------
%                 Defining trial variable 
%----------------------------------------------------------------------
 
newtrial = 0;
currentCombination = 1;
nCombinations = 36;
Combinations = [1 2 1 3 1 4 1 5 1 6 1 7 1 8 1 9 2 3 2 4 2 5 2 6 2 7 2 8 2 9 3 4 3 5 3 6 3 7,...
    3 8 3 9 4 5 4 6 4 7 4 8 4 9 5 6 5 7 5 8 5 9 6 7 6 8 6 9 7 8 7 9 8 9];

%----------------------------------------------------------------------
%                       Results Matrix
%----------------------------------------------------------------------
% Make a  matrix which which will hold all of our results
resultsMatrix = struct('Leftcolor1', {}, 'Rightcolor1', {}, ...
'Key1', {}, 'Timeq1', {}, 'Leftcolor2', {}, 'Rightcolor2', {}, ...
'Key2', {}, 'Timeq2', {});

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
line1 = 'You will see a sequence of lights in 2 different positions';
line2 = 'When the question mark appears, indicate the sequence with the darkest light by pressing the corresponding arrow key';
line3 = 'Press the left arrow key for the left sequence, the right arrow key for the right sequences and the up arrow key for the upper sequence';
line4 = 'Focus on the central cross at all times';
 
% Draw all the text in one go
Screen('TextSize', window, 17);
Screen('DrawText', window, line1, screenXpixels*0.1, screenYpixels*0.1, white);
Screen('DrawText', window, line2, screenXpixels*0.1, screenYpixels*0.2, white);
Screen('DrawText', window, line3, screenXpixels*0.1, screenYpixels*0.3, white);
Screen('DrawText', window, line4, screenXpixels*0.1, screenYpixels*0.4, white);
Screen('Flip', window);  
KbStrokeWait;

for currenttrialinblock = 1:nCombinations

% Counting up the trial variable
newtrial = newtrial + 1;

% Randomise position of sequences
randpos = Shuffle({centeredRect_left, centeredRect_right}); 

% Fixation cross
Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window, [], 1);
WaitSecs(1);  

% Present stimulus
    
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
     
    Screen('FillRect', window, rectColor{Combinations(currentCombination)}, randpos{1}); 
    Screen('FillRect', window, rectColor{Combinations(currentCombination + 1)}, randpos{2});
    Screen('Flip', window);
    WaitSecs(0.75);
       
    Screen('FillRect', window, [0 0 0]);
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
    Screen('Flip', window);

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
        Screen('TextSize', window, 17);
        Screen('DrawText', window, 'Please only select either the left or right arrow key to indicate your choice', screenXpixels*0.1, screenYpixels*0.5, white);
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



% Results matrix
if randpos{1} == centeredRect_left
resultsMatrix(newtrial).Leftcolor1 = Combinations(currentCombination); 
resultsMatrix(newtrial).Rightcolor1 = Combinations(currentCombination + 1);
else
resultsMatrix(newtrial).Leftcolor1 = Combinations(currentCombination + 1);
resultsMatrix(newtrial).Rightcolor1 = Combinations(currentCombination);
end
resultsMatrix(newtrial).Key1 = KbName(keyCode1);
resultsMatrix(newtrial).Timeq1 = questionmarkOnset1;

currentCombination = currentCombination + 2;

end 

 
% Experimental instructions
line1 = 'You will see a sequence of lights in 2 different positions';
line2 = 'When the question mark appears, indicate the sequence with the brightest light by pressing the corresponding arrow key';
line3 = 'Press the left arrow key for the left sequence, the right arrow key for the right sequences and the up arrow key for the upper sequence';
line4 = 'Focus on the central cross at all times';
 
% Draw all the text in one go
Screen('TextSize', window, 17);
Screen('DrawText', window, line1, screenXpixels*0.1, screenYpixels*0.1, white);
Screen('DrawText', window, line2, screenXpixels*0.1, screenYpixels*0.2, white);
Screen('DrawText', window, line3, screenXpixels*0.1, screenYpixels*0.3, white);
Screen('DrawText', window, line4, screenXpixels*0.1, screenYpixels*0.4, white);
Screen('Flip', window);  
KbStrokeWait;


for currenttrialinblock = 1:nCombinations

% Counting up the trial variable
newtrial = newtrial + 1;

% Randomise position of sequences
randpos = Shuffle({centeredRect_left, centeredRect_right}); 

% Fixation cross
Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
Screen('Flip', window, [], 1);
WaitSecs(1);  

% Present stimulus
    
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
     
    Screen('FillRect', window, rectColor{Combinations(currentCombination2)}, randpos{1}); 
    Screen('FillRect', window, rectColor{Combinations(currentCombination2 + 1)}, randpos{2});
    Screen('Flip', window);
    WaitSecs(0.75);
       
    Screen('FillRect', window, [0 0 0]);
    Screen('DrawLines', window, allCoords,lineWidthPix, white, [xCenter yCenter], 2);
    Screen('Flip', window);

% Question mark
Screen('TextSize', window, 120);
Screen('DrawText', window, '?', screenXpixels*0.48, screenYpixels*0.45, white);
Screen('Flip', window)

% Timestamp
questionmarkOnset2 = GetSecs();

% Check the keyboard to see if a button has been pressed
[secs2, keyCode2] = KbStrokeWait;

% Make sure that only arrow keys are pressed
number_tries = 1;
while number_tries < 3
    if ismember(KbName(keyCode2), {'LeftArrow' 'RightArrow'})
    break;
    else
        Screen('TextSize', window, 17);
        Screen('DrawText', window, 'Please only select either the left or right arrow key to indicate your choice', screenXpixels*0.1, screenYpixels*0.5, white);
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
        
        number_tries = number_tries + 1;
    end
end



% Results matrix
if randpos{1} == centeredRect_left
resultsMatrix(newtrial).Leftcolor2 = Combinations(currentCombination2); 
resultsMatrix(newtrial).Rightcolor2 = Combinations(currentCombination2 + 1);
else
resultsMatrix(newtrial).Leftcolor2 = Combinations(currentCombination2 + 1);
resultsMatrix(newtrial).Rightcolor2 = Combinations(currentCombination2);
end
resultsMatrix(newtrial).Key2 = KbName(keyCode2);
resultsMatrix(newtrial).Timeq2 = questionmarkOnset2;

currentCombination2 = currentCombination2 + 2;

end  

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

