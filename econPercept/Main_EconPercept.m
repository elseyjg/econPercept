%Main_EconPercept.m
%This is the primary driver to run in order to run the whole experiment
try
    close all; %closes all extraneous windows created by matlab in previous scripts
    clear all; %clears the workspace, deletes all variables, cells, and matrices created by matlab in previous scripts
    clc;       %clears the command window
    global MouseInsteadOfGaze whichEye
    % which eye is being tracked left(1) or right(2)
    whichEye = 2;
    MouseInsteadOfGaze = 1; % 1 means mouse
    plotflag = false;
    [ret, name] = system('hostname');
    %%
    if isequal(deblank(name),'Emeric-PC')
        cd('C:\Users\Emeric\Documents\MATLAB\MADMakS\TaskScripts\4Opt4AttEV');
    else
        cd('/Users/stuphornlab/Documents/MATLAB/econPercept');
    end
    %%
    % % This is my "shut up" section (turn it back on as needed) % Screen('Preference', 'SkipSyncTests', 1);
    % Screen('Preference', 'Verbosity', 1);
    % Screen('Preference', 'SuppressAllWarnings', 1);1
    warning('off','MATLAB:dispatcher:InexactMatch');
    oldlevel = PsychPortAudio('Verbosity', 0); %This is how you set the verbosity of PsychPort Audio to "Shut up"
    oldlevel = IOPort('Verbosity', 2);
    
    %% Important directories
    expDir = pwd;
    outDir = [pwd filesep 'Output' filesep];
    
    %Input information
    global DebugFlag
    DebugFlag = str2double(input('Debug version? (1 for yes, 0 for no) ', 's'));
    if DebugFlag == 0
        SubjectID = input('Enter Participant ID #: ', 's'); %Make this a number (to ensure confidentiality) including any zeros (ex. 01)
        % Date = input('Enter todays date: ', 's'); %Enter the date as one number without spaces (ex. 3282017)
        Date = datestr(now,1);
        RunNum = input('Enter run #: ', 's'); %Enter which of the 3 runs the participant is on.
        %seed will predefine all random events in the experiment, such as shuffling and waiting times for certain screens.
        seed = input('Enter seed #: ', 's'); %Make sure it still works as expected after removing the "rng_" part!
        if str2double(RunNum) == 1
            TrainingTrials = '5'; %This is a number which best acclimates the subject to the experiment
        else
            TrainingTrials = '0';
        end
    else
        SubjectID = '99';
        Date = datestr(now,1);
        RunNum ='1';
        seed='111';
        TrainingTrials='0';
    end
    %%
    %If the filename entered already exists this will produce an error
    filename = [outDir 'econPercept'];
    if str2num(SubjectID)<10
        SubjectID=['0' SubjectID];
    end
    
    filename = [filename '_' SubjectID '_' Date '_' RunNum '.mat'];
    if exist(filename, 'file')
        disp('Output file already exists!');
        cd(expDir)
        return
    end

    if isequal(deblank(name),'Emeric-PC')
        screenNum=1;
        [scr_width, scr_height] = Screen('WindowSize',screenNum); %Get screen size in pixels
        SetResolution(screenNum,scr_width,scr_height,60);
    else
        screenNum=0;
        try
            SetResolution(screenNum,1920,1080,60); %This sets the screen size to 1080

        catch
            screenNumber = max(Screen('Screens'));
            [scr_width, scr_height] = Screen('WindowSize',screenNumber); %Get screen size in pixels
            SetResolution(screenNum,scr_width,scr_height,60);
        end
    end
    Screen('Preference','TextRenderer', 0)
%     SetResolution(screenNum,1680, 1050,60); %This sets the screen size to 1080

%     if isequal(RunNum,'1')
%              MADMakS(SubjectID, Date, RunNum, seed, TrainingTrials, filename, outDir);
%         MADMakS_4Opt(SubjectID, Date, RunNum, seed, TrainingTrials, filename, outDir);
%         %% IF THE TARGET AND DECOYS FILE IS NOT CREATED RUN THIS SECTION 
%         %  load datafile
%         load(filename,'RECORD_DATA')%,'RecordData'
%         % get TOD/Infos_MAD
%         [dpath,datafile,EXT] = fileparts(filename);
%         TOD =  getTrialData(dpath, [datafile,EXT]);
%         [buttonPresses] = getButtonPresses_R_D(RECORD_DATA);
%         [MAD_Infos]=getMADInfos(TOD, buttonPresses);
%         MAD_Infos(~isnan(TOD(:,19)),:)=[];
%         % get SVmap
%         % get targets' and decoys' locations
%         [targetsAndDecoys,SVmap] = get4OptTargetsAndDecoys(MAD_Infos,false);
%         % save targetsAndDecoys to .mat file
%         save(fullfile(dpath,[SubjectID '_targetsAndDecoys.mat']),'targetsAndDecoys','SVmap')
%         %%
%         if plotflag
%             contourf(SVmap.P_hat,fliplr(SVmap.A_hat),(SVmap.SV_PT))
%             hold on
%             plot(table2array(targetsAndDecoys(:,1)),table2array(targetsAndDecoys(:,2)),'or','markerfacecolor','r')
%         end
%         disp(targetsAndDecoys)
%     else
        % This will run the rest of the experiment
        Economic_decision_test(SubjectID, Date, RunNum, seed, TrainingTrials, filename, outDir);
        Perceptual_trial_test(SubjectID, Date, RunNum, seed, TrainingTrials, filename, outDir);        
%     end
catch ME
    % for debugging when trial hangs
    
    Screen('CloseAll');
    sca;
    ListenChar(0)
    if ~MouseInsteadOfGaze
        if ~DebugFlag
            Eyelink('StopRecording');
            Eyelink('Shutdown');
        end
    end
    disp(ME)
end