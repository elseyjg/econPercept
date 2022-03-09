% econPercept.m
% This is the sub-driver script that takes inputs from Main_EconPercept.m
%        
function econPercept(SubjectID, Date, RunNum, seed, TrainingTrials, filename, outDir)
%set DebugFlag to 0 if not debugging
global DebugFlag
global MouseInsteadOfGaze
% DebugFlag = 1; 
if ~nargin 
    seed = '111'; 
    filename = ['TEST_' date '.mat']; 
end

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
seed_num = sum(seed); %Turns string into number that can be put into RandStream. Note scrambling the seed string will result in the same seed_num.
%rng(seed_num);%doesn't work in this matlab version 
rng = RandStream('mrg32k3a','Seed', seed_num); 

% RandStream.setDefaultStream(rng); %comment this one out if not in eye-tracker room. 
RandStream.setGlobalStream(rng); %comment this one out if in eye-tracker room. 

if ~DebugFlag
    save(filename)
end

entryNumber = 1;

RECORD_DATA = cell([entryNumber, 4]);%The first variable entryNumber is going to grow very quickly
TRAINING_DATA = cell([entryNumber, 4]);%The first variable entryNumber is going to grow very quickly
%Variables are:
% (1) Trial number
% (2) System time
% (3) Event Type (String)
% (4) Event-Specific Data (Cell)*

% *Event Type Cases:
% 'Trial Onset'
    % Data = A_a, P_a, A_b, P_b, config_num, A_a_pos, P_a_pos, A_b_pos, P_b_pos;
% 'Central Cross Fixation'
    % Data = [gaze_x, gaze_y], fixation_time;
% 'Display screen Onset'
    % Data = null
% 'Button Press'
    % Data = keyCode;
% 'Show Selection Onset'
    % Data = Option Chosen {'left','right','up'};
% 'Dark Grey Screen Onset'
    % Data = null;
% 'Result Screen Onset'
    % Data = reward earned;
% 'Eye Position'
    % Data = [gaze_x, gaze_y]

% gaze_x, gaze_y, mask_x, mask_y, A_a_pos, P_a_pos, A_b_pos, P_b_pos, are in units of pixels.
% KeyCode is array of numbers repsresenting keys on the keyboard. 0 indicates a key is up, and 1 indicates it has been depressed.
%% This is my "shut up" section (turn it back on as needed)
Screen('Preference', 'Verbosity', 1);
Screen('Preference', 'SkipSyncTests', 1);
Screen('Preference', 'SuppressAllWarnings', 1);

KbName('UnifyKeyNames'); 

% Get the screen numbers and draw to the external screen if avaliable
screenNumber = max(Screen('Screens'));
% screenNumber=1;
% Define all the colors to be used in the experiment.
% They are [red green blue] and the values range between 0 and 255
% white = [255 255 255];
% black = [0 0 0];
white = WhiteIndex(screenNumber); 
black = BlackIndex(screenNumber);
%gray is 50% black;
% gray = [128 128 128];
gray = white / 2;
%light_gray is 20% black;
light_gray = [204 204 204];
red = [255 0 0];
yellow = [255 255 0];
blue = [0 0 255]; 
green = [0 128 0];

nextkey = KbName('SPACE'); 

% These few lines open a screen window for psychtoolbox to manipulate
%[window, windowRect] = PsychImaging('OpenWindow', screenNumber, white);
colorDepth = 32;
ExperimentStart = GetSecs; 
[scr_width, scr_height] = Screen('WindowSize',screenNumber); %Get screen size in pixels
[window, windowRect] = Screen('OpenWindow', screenNumber, white,[0 0 scr_width scr_height], colorDepth);

% Get the center coordinate of the window
[xCenter, yCenter] = RectCenter(windowRect);

% Get the size of the on screen window
[screenXpixels, screenYpixels] = Screen('WindowSize', window);

% Numer of frames to wait when specifying good timing
waitframes = 1;

% Query the frame duration
ifi = Screen('GetFlipInterval', window);

% Set up alpha-blending for smooth (anti-aliased) lines
Screen('BlendFunction', window, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

% Setup the text type for the window
Screen('TextFont', window, 'Arial');
% Screen('TextFont', window, 'Geneva');
Screen('TextSize', window, 42); 

% From accurateTimingDemo
% Retreive the maximum priority number
topPriorityLevel = MaxPriority(window);

account = 0;

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
% Set global variables 
global ValidResponseFlag
global PostCalib 

if ismac
    B_ButtonPress = 5;
else % Is Windows
    B_ButtonPress = 66;
end

config_num = 1;
trialNumber = 1;
if ~DebugFlag 
%     totalTrials = length(permutedOptions);
    totalTrials = 12;
else
    totalTrials = 12; %This is the quick version for debuging
end

trainingTrials = str2num(TrainingTrials); %This is determined by input in main.m 
break_flag = 0;
calibrate_flag = 0;
quit_flag = 0;
training_flag = 0;
Training = 1;
end_break_flag = 0;
TrialResults = zeros(1, totalTrials);
PostCalib = false;
TTA = 0;
save('Crash_Dump.mat') 



Training = 0;
entryNumber = 1;
account = 0;
TrialNumber = 1;

%% Press space bar to continue screen is created here. %%
if trainingTrials > 0 
%     runText = 'Press spacebar to begin'; 
    runText = 'Please keep your head still, and let the experimenter know when you are ready to begin.'; 
    Screen('FillRect', window, gray);    
%     Screen('TextSize', window, 64); 
    Screen('TextSize', window, 36); 
    CenterText(window, runText, black);     %This line requires CenterText.m to be in the current folder. 
    Screen('Flip', window); 
    %--------------------------------------
    while 1
        [KeyIsDown, endrt, keyCode] = KbCheck; %The first 2 entries here are output arguments that are not used. 
        if keyCode(nextkey) 
            break;
        end
        WaitSecs(0.001); 
    end 
end

Screen('TextFont', window, 'Arial');
% Screen('TextFont', window, 'Geneva');
Screen('TextSize', window, 42);
errcnt = 1;

try
%% This is the actual experimentation section %%%%%%
% for trialNumber = 1:totalTrials
if ~MouseInsteadOfGaze
    status=Eyelink('message','Experiment Trials');
end

while TrialNumber <= totalTrials
    trialOptions = permutedOptions(TrialNumber);
    amtWin1 = trialOptions{1}(1); 
    probWin1 = trialOptions{1}(2);
    amtLose1 = trialOptions{1}(3);
    probLose1 = trialOptions{1}(4);
    amtWin2 = trialOptions{1}(5); 
    probWin2 = trialOptions{1}(6);
    amtLose2 = trialOptions{1}(7);
    probLose2 = trialOptions{1}(8);
    amtWin3 = trialOptions{1}(9); 
    probWin3 = trialOptions{1}(10);
    amtLose3 = trialOptions{1}(11);
    probLose3 = trialOptions{1}(12);
    amtWin4 = trialOptions{1}(13); 
    probWin4 = trialOptions{1}(14);
    amtLose4 = trialOptions{1}(15);
    probLose4 = trialOptions{1}(16);
    trialConfig = permutedConfigs(TrialNumber,:);

    
%     config_num = permutedConfigs(TrialNumber);
    if ~PostCalib
    TrialTypeRandomizer = rand(1);
    end

    [RECORD_DATA, entryNumber, account, break_flag, calibrate_flag, quit_flag, TrialResults] = FourOptFourAttEV_Trial(amtWin1, probWin1, amtLose1, probLose1, amtWin2, probWin2, amtLose2, probLose2, amtWin3, probWin3, amtLose3, probLose3, amtWin4, probWin4, amtLose4, probLose4, RECORD_DATA, window, windowRect, screenNumber, account, entryNumber, TrialNumber, break_flag, calibrate_flag, quit_flag, training_flag, Training, TrialResults, permutedConfigs);


    if(calibrate_flag) % if 'q' was pressed
         if ~DebugFlag
             if ~MouseInsteadOfGaze
                 EyelinkDoTrackerSetup(el_settings);
                 EyelinkDoDriftCorrection(el_settings);
             end
         else
             runText = 'Calibration Screen';
             Screen('FillRect', window, gray);
%              Screen('TextSize', window, 64);
             CenterText(window, runText, black); %This line requires CenterText.m to be in the current folder.
             Screen('Flip', window);
%              WaitSecs(1);
             while calibrate_flag == 1
                 [KeyIsDown, endrt, keyCode] = KbCheck; %The first 2 entries here are output arguments that are not used.
                 if keyCode(nextkey)
%                      disp(find(keyCode))%*
                     break;
                 end
                 WaitSecs(0.001);
             end
         end 
        calibrate_flag = 0;
        PostCalib = true;
    end
    if(break_flag) % if 'e' was pressed
        break_flag = 0;
        while(end_break_flag~=1)
            Screen('DrawText', window, 'Break: press "b" to end break', 50, 65, [217 217 217], [64 64 64], 0, 0);
            Screen('DrawingFinished', window);
            Screen('Flip', window);
            [keyIsDown, secs, keyCode] = KbCheck();
            if(keyCode(B_ButtonPress)) 
                end_break_flag = 1;
            end
        end
        end_break_flag = 0;  
    end
    if(quit_flag) % if 'End' was pressed
        save(filename, 'RECORD_DATA');
        if ~DebugFlag
            if ~MouseInsteadOfGaze
                Eyelink('StopRecording');
                Eyelink('CloseFile');
                try % Test this part to see if it works!
                    fprintf('Receiving data file ''%s'' from EyeLink computer...\n', edfFile );
                    status=Eyelink('ReceiveFile');
                    if status > 0
                        fprintf('ReceiveFile status %d\n', status);
                    end
                    if 2==exist(edfFile, 'file')
                        [path,name,ext] = fileparts(filename);
                        RenameEDF = [name, '_CrashDump.edf'];
                        movefile(fullfile(pwd, edfFile), fullfile(outDir, RenameEDF));
                        fprintf('Data file ''%s'' can be found in ''%s''\n', RenameEDF, outDir);
                    end
                catch
                    fprintf('Problem receiving data file ''%s''\n', edfFile );
                    psychrethrow(psychlasterror);
                    sca;
                end
                Eyelink('Shutdown');
            end
        end
        Screen('CloseAll');
        sca;
        ListenChar(0)
        return;
    end
    if ValidResponseFlag
        TrialNumber = TrialNumber + 1;
    end
    save('Crash_Dump.mat') 
    save(filename, 'RECORD_DATA'); % Saves the RECORD_DATA after every trial
end
% end
%%%%%%%%%%%%%%%
catch ME
    message{errcnt, 1} = getReport(ME); 
    stack{errcnt, 1} = ME.stack; 
    % Maybe add something here to report which trial the error occurred on
    disp(ME.message)
    errcnt = errcnt + 1; 
end
%% RECORD_DATA 
ExperimentEnd = GetSecs; 
ExperimentDuration = ExperimentEnd-ExperimentStart; 
% save(filename, 'RECORD_DATA', 'account', 'seed'); %Saves RECORD_DATA, the amount scored, and the rng_seed used for the experiment
Bonus = sum(TrialResults(BonusTrials));  
fprintf('\n Bonus = $%.2f \n \n', Bonus); %This displays the bonus for the run
save(filename) 

%%%-End Screen---- ----------------------------------------------------------
    runText = 'The End.';  
    Screen('FillRect', window, light_gray);     
    Screen('TextSize', window, 64); 
    CenterText(window, runText, black);     %This line requires CenterText.m to be in the current folder. 
    Screen('Flip', window); 
    WaitSecs(2);
%%%--------------------------------------------------------------------------

 account % prints out the account in the console
% entryNumber
%%%%%%%%%%%%%%%
if ~MouseInsteadOfGaze
    if ~DebugFlag
        Eyelink('StopRecording');
        Eyelink('CloseFile');
        
        % download data file
        try
            fprintf('Receiving data file ''%s'' from EyeLink computer...\n', edfFile );
            status=Eyelink('ReceiveFile');
            if status > 0
                fprintf('ReceiveFile status %d\n', status);
            end
            if 2==exist(edfFile, 'file')
                [path,name,ext] = fileparts(filename);
                RenameEDF = [name, '.edf'];
                movefile(fullfile(pwd, edfFile), fullfile(outDir, RenameEDF));
                fprintf('Data file ''%s'' can be found in ''%s''\n', RenameEDF, outDir);
            end
        catch
            fprintf('Problem receiving data file ''%s''\n', edfFile );
            psychrethrow(psychlasterror);
            sca;
        end
        %The above code retrieves the .edf file from the EyeLink computer, renames
        %it, and moves it to the "Output" folder. From there, you need to copy BOTH
        %the .edf file and the .mat file to a flash drive after EVERY participant!
        %Then you'll need to convert the .edf file to .mat using the edf2mat script.
        
        Eyelink('Shutdown');
        sca; % JE added 2/26
    end
end
Screen('CloseAll');
sca;
ListenChar(0)
end