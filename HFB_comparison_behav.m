% want to load the epochData file PER electrode, want wave
% the columns are the individual trials and the rows are the time points
%get ready with the addpath,plz adjust accordingly
addpath(genpath('/Users/chao/Documents/Stanford/code/lbcn_personal-master/'))
addpath(genpath('/Users/chao/Documents/Stanford/code/lbcn_preproc-master/'))
%addpath(genpath('/Users/chao/Desktop/function_tools/gramm-master'))% this is a matlab based graph toolbox which is similar to the ggplot2
[server_root, comp_root, code_root] = AddPaths('Chao_iMAC');%home

%% need to load in the subject ROI! 
sbj_names_all = {'C17_20';'C17_21';'C18_22';'C18_23';'C18_24';'C18_25';'C18_26';'C18_27';'C18_28';'C18_29';'C18_30'...
    ;'C18_31';'C18_32';'C18_33';'C18_34';'C18_35';'C18_37';'C18_38';'C18_39';'C18_40';'C18_41';'C18_42';'C18_43';'C18_44'...
    ;'C18_45';'C18_46';'C18_47';'C18_49';'C19_50';'C19_51';'C19_52';'C19_53';'C19_55';'C19_58';'C19_60';'C19_62';'S17_114_EB'...
    ;'S17_116_AA';'S17_118_TW';'S19_145_PC';'S20_148_SM';'S20_149_DR';'S20_150_CM';'S20_152_HT'};

%sbj_names_all = {'C18_37'} %do we want to it at the individual subject level?
indxcohort = [10,17,28,36];%china
sbj_names = sbj_names_all(indxcohort)
% define the the abbreviations of kinds of brian structures
anat_all = {'SFG','SFS','MFG','IFS','IFG','OFC','MPG','SMA','VMPFC','ACC','MCC','PCC','STG','STS','MTG','ITS','ITG','AMY','HIPPO A','HIPPO M','HIPPO P'...
    ,'TP','OTS','FG','CS','PHG','PRECENTRAL G','POSTCENTRAL G','SPL','IPL','IPS','PCG','CG','POF','CF','LG','SOG','MOG','IOG','WM','OUT','EC',...
    'FOP','POP','TOP','EMPTY','PARL','LESION','INSULA','BASAL'};
anat = {'INSULA'};anat_name = 'INSULA';
side = 'none';%'L','R','none'
anat_displ =  importdata('/Users/clara/Documents/code/lbcn_personal/personal/race_project/anat_abbreviation.txt');%pls select a directory to store the 
disp(anat_displ);

%check the excel sheet
load('/Users/chao/Documents/Stanford/code/lbcn_personal-master/Chao/cell_of_44_race_cases_tables.mat');%if there is any change of the excel sheet, 
%then this need to update,go to 'Creat_cell_of_tables.mat'
T = T(indxcohort,1);

%Creat another table with rows of specific cohorts and column of specific anatomical
%structures
sz = [size(sbj_names,1) size(anat,2)];
varTypes = cell(1,size(anat,2));
varTypes(:) = {'cell'};
T2 = table('Size',sz,'VariableTypes',varTypes,'VariableNames',anat,'RowNames',sbj_names);
%put the glv_index into each space of the table as a vector
if isempty(side)||strcmp(side,'none')
    for i = 1:length(sbj_names)
        for j = 1:length(anat)
            idx1 = strcmp(T{i}.label,anat{j});
            idx2 = T{i}.group_diff;%or idx2 = T{i}.any_activation/T{i}.all_trials_activation/T{i}.group_diff %default
            idx = idx1 & idx2;
            T2{sbj_names{i},anat{j}} = {T{i}.glv_index(idx)'};
        end
    end
else
    for i = 1:length(sbj_names)
        for j = 1:length(anat)
            idx1 = strcmp(T{i}.label,anat{j});
            idx2 = T{i}.group_diff;%or idx2 = T{i}.any_activation/T{i}.all_trials_activation
            idx3 = strcmp(T{i}.LvsR,side);
            idx = idx1 & idx2 & idx3;
            T2{sbj_names{i},anat{j}} = {T{i}.glv_index(idx)'};
        end
    end
end
%Since there may be empty electrodes in the stats sheet, Glv_index may be str. Here, all Glv_index in T2 will be transformed into vetor
for i = 1:length(sbj_names)
    for j = 1:length(anat)
        if iscell(T2{sbj_names{i},anat{j}}{:})
            T2{sbj_names{i},anat{j}}{:} = str2double(T2{sbj_names{i},anat{j}}{:});
        end
    end
end
%Creat a third table that horizontally concatenate all the specific
%anatomical structures in together and get rid of the empty rows in T3
sz = [size(sbj_names,1) 1];
varTypes = cell(1,1);
varTypes(:) = {'cell'};
T3 = table('Size',sz,'VariableTypes',varTypes,'VariableNames',{'anat'},'RowNames',sbj_names);
for i = 1:size(T3,1)
    T3{i,:}{:} = horzcat(T2{i,:}{:});
end
loc=cellfun('isempty', T3{:,'anat'} );
T3(loc,:)=[];


behv = readtable(['/Users/clara/Documents/code/lbcn_personal/personal/race_project/results_summary.xlsx']);
behv_indx = ismember(behv.Chao_patient_ID_in_server,T3.Properties.RowNames);
disp(['the mean of accuracy in ' anat{:} ' is ' num2str(mean(behv.Race_CatAcc_SR(behv_indx))) ' and the std is ' num2str(std(behv.Race_CatAcc_SR(behv_indx)))])

%% getting the conditions that I want to move across
project_name = 'race_encoding_simple';
conditions = {'asian','black','white'}; column = 'condNames';
%define the plot and stats parameters first
project_name ='race_encoding_simple';% 'race_encoding_simple'or'Grad_CPT'  % The might be error here because of the naming some are GradCPT and some are Grad_CPT
plot_params = genPlotParams(project_name,'timecourse');
plot_params.single_trial_replot = true;
plot_params.single_trial_thr = 15;%the threshold of HFB it could be like 10 15 20 ...
stats_params = genStatsParams(project_name);
plot_params.single_trial = false;
plot_params.clust_per = true;% clusterd based permuation
plot_params.clust_per_win = [0 1.5]; %


plot_data = cell(1,length(conditions));
plot_data_all = cell(1,length(conditions));
plot_data_trials = cell(1,length(conditions));
plot_data_trials_all = cell(1,length(conditions));
stats_data = cell(1,length(conditions));
stats_data_all = cell(1,length(conditions));




for i = 1:length(T3.Properties.RowNames)
    if ~isempty(T3.anat{i})
        indx = i;
        sbj_name = T3.Properties.RowNames{indx};%set basic pipeline parameters
        if contains(sbj_name,'C17')||contains(sbj_name,'C18')||contains(sbj_name,'C19')
            center = 'China';
        else
            center = 'Stanford';
        end
        block_names = BlockBySubj(sbj_name,project_name);
        dirs = InitializeDirs(project_name, sbj_name, comp_root, server_root, code_root);
        load([dirs.data_root,filesep,'OriginalData',filesep,sbj_name,filesep,'global_',project_name,'_',sbj_name,'_',block_names{1},'.mat'])
        for j = 1:length(T3.anat{i})
            data_all = concatBlocks(sbj_name, block_names,dirs,T3.anat{i}(j),'HFB','Band',{'wave'},['stimlock_bl_corr']);%'stimlock'
            %concatBlocks(sbj_name, project_name, block_names,dirs,el,freq_band,datatype,concatfields,tag)

            %smooth is in the trial level
            winSize = floor(data_all.fsample*plot_params.sm);
            gusWin = gausswin(winSize)/sum(gausswin(winSize));
            data_all.wave_sm = convn(data_all.wave,gusWin','same');
            
            [grouped_trials_all,~] = groupConds(conditions,data_all.trialinfo,column,'none',[],false);
            [grouped_trials,cond_names] = groupConds(conditions,data_all.trialinfo,column,stats_params.noise_method,stats_params.noise_fields_trials,false);
            % this part is to exclude HFB over a fixed threshold
            if plot_params.single_trial_replot
                thr_raw =[];
                for di = 1:size(data_all.wave,1)
                    if ~isempty(find(data_all.wave(di,:)>=plot_params.single_trial_thr))
                        fprintf('You have deleted the data over threshold %d from the data \n',plot_params.single_trial_thr);
                    else
                    end
                end
                [thr_raw,thr_column] = find(data_all.wave >= plot_params.single_trial_thr);
                thr_raw = unique(thr_raw);
            end
            
            for ci = 1:length(conditions)
                grouped_trials{ci} = setdiff(grouped_trials{ci},thr_raw);% make the grouped_trial and thr_raw in together
                plot_data{ci} = [plot_data{ci};nanmean(data_all.wave_sm(grouped_trials{ci},:),1)];% we use smoothed data for plotting
                plot_data_all{ci} = [plot_data_all{ci};nanmean(data_all.wave_sm(grouped_trials_all{ci},:),1)];
                stats_data{ci} = [stats_data{ci};nanmean(data_all.wave(grouped_trials{ci},:),1)]; % this part of data were prepared for further comparison (original non-smoothed data)
                stats_data_all{ci} = [stats_data_all{ci};nanmean(data_all.wave(grouped_trials_all{ci},:),1)];
            end
        end
    else
    end
end


data_all = concatBlocks_Multisubj_Clara_tmp(sbj_names, project_name, [],dirs,T3,'HFB','Band',{'wave'},['stimlock_bl_corr']);%'stimlock'

% Need to concat blocks across subjects

%% Loading the recall
% want to use the plot_params to grab the time points and see if the ones
% that are statistically significant are predictive of the accuracy

%rec = load('/Volumes/CSS_backup/data/neuralData/BandData/HFB/C18_37/RACE_3/EpochData/HFBiEEG_stimlock_bl_corr_RACE_3_150.mat')

for i = 1:length(T3.Properties.RowNames)
    if ~isempty(T3.anat{i})
        project_name_tmp = 'race_recall';
      
        data_all_rec = concatBlocks_Multisubj_Clara_tmp(sbj_names, project_name_tmp, [],dirs,T3,'HFB','Band',{'wave'},['stimlock_bl_corr']);%'stimlock'
    end
end



%% Modifying the trialinfo & recall

%encoding
for sb = 1:length(T3.Properties.RowNames)
    
    if ~isempty(T3.anat{sb})
        indx = sb;
        sbj_name = T3.Properties.RowNames{indx};%set basic pipeline parameters
        if contains(sbj_name,'C17')||contains(sbj_name,'C18')||contains(sbj_name,'C19')
            center = 'China';
        else
            center = 'Stanford';
        end
        project_name = 'race_encoding_simple';
        
        block_names = BlockBySubj(sbj_name,project_name);
        load([dirs.data_root,filesep,'OriginalData',filesep,sbj_name,filesep,'global_',project_name,'_',sbj_name,'_',block_names{1},'.mat'])
        %load([dirs.data_root,filesep,'psychData',filesep,sbj_name,filesep,'global_',project_name_tmp,'_',sbj_name,'_',block_names{1},'.mat'])
        
        % Load behavioral file
        soda_name = dir(fullfile(globalVar.psych_dir, 'sodata*.mat'));
        K = load([globalVar.psych_dir '/' soda_name.name]);
        
        for j = 1: length(T3.anat{sb})
            el = T3.anat{sb}(j);
            
            list_stim = K.seq.active.race;
            %need to find which part of the data_all is relevant to use for
            %below
            for x = 1:size(data_all.trialinfo,1)
                seed(x) = strcmp(sbj_name,data_all.trialinfo.sbj{x}) && strcmp(block_names{1},data_all.trialinfo.block{x}) && el==data_all.trialinfo.el(x);
            end
            ne = (find(seed,1,'first')):((find(seed,1,'first'))+length(list_stim)-1);
            %only doing the below so that you can do the same indentation
            %for the rest 
            ne_for1 = ne-1;
                    
            for i= 1:length(list_stim)
                new=ne_for1(1) + i;
                data_all.trialinfo.stim_list(new) = string(list_stim(i,:));
            end
            
            %can use the sodata from the encoding for recall
            list_stim = K.seq.memory.active.race;
            for i= 1:length(list_stim)
                new=ne_for1(1) + i;
                data_all_rec.trialinfo.stim_list(new) = string(list_stim(i,:));
            end
            
            %stupid change here, but moving it back to 1 for the rest of it
            %find better solution

            %need to modify this to include only those encoding correctly 2x!
            for i = ne(1):ne(end)
                if data_all_rec.trialinfo.isCorrect(i)==0
                    tmp = data_all_rec.trialinfo.stim_list(i);
                    for k = 1:size(data_all.trialinfo,1)
                        if strcmp(tmp,data_all.trialinfo.stim_list(k)) %if this is true
                            %then mark that this is a trial we want to look at
                            data_all.trialinfo.mem_inc(k) = 1;
                        else
                            %enc.data.trialinfo.mem_inc(k) = 0;
                        end
                    end
                end
            end
            
            %also want to add the order that the stim were presented in recall
            %here to make things easier later on
            for i = ne(1):ne(end)
                if data_all_rec.trialinfo.Presented(i)==1
                    tmp=data_all_rec.trialinfo.stim_list(i);
                    for k = 1:size(data_all.trialinfo,1)
                        if strcmp(tmp,data_all.trialinfo.stim_list(k))
                            data_all.trialinfo.recall_trial(k) = i;
                        else
                        end
                    end
                else
                end
            end
        end
    end
end
%need to make modification that works for 2 subjects! 

%% Looking at relationship between HFB and salience

%which time zones
%how to correlate it with a single value - I know IRSA but how would we do
%it with this dat?


% patient was showed 2x to the patient in the encoding so 2 HFB - take the
% mean of those 2 HFBs
% 1 list of ones remembered incorrectly and get the mean of that mean HFB
% from all subjecst with coverage in that ROI
% versus the ones remembererd correctly 
% t-test 


%higher the HFB in encoding, the higher the salience

%higher the HFB in encoding, the lower the RT in memory
% between race and other race x other race (or randomly choose the amount
% of trials)

%in each region one patient with one site
% do for each site and say if it is consistent 

%HFB - 0.5-1, 0 - 0.5
%0.2 - .7
%average HFB across time range for each trial that was correct in encoding
%also do each trial that was incorrect
% t-test comparing the 2

%do 2 things: 1. Look at the data_all and look across all conditions if
%there is a correlation between trials remembered correctly and not 

%want a list of the trials that were remembered correctly
idx = data_all.trialinfo.mem_inc==1

x_corr=[]
x_incorr = []
for p = 1:length(idx)
    if idx(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_corr)
            x_corr =mean(data_all.wave(p,201:451)) %p is the trial number
        else
            x_corr(end+1)= mean(data_all.wave(p,201:451))
        end
    end
    if idx(p)==0
        %want time window from .2 (201) to .7(451)
        if isempty(x_incorr)
            x_incorr =mean(data_all.wave(p,201:451)) %p is the trial number
        else
            x_incorr(end+1)= mean(data_all.wave(p,201:451))
        end
    end
end

mean(x_corr)
mean(x_incorr)
[h,p,ci,stats] = ttest2(x_corr,x_incorr)
%this gives you the statistical difference between the correct and
%incorrect trials (t-value and the p-value)
figure()
x = [x_corr'; x_incorr'];
g = [zeros(length(x_corr), 1); ones(length(x_incorr), 1)];
boxplot(x, g)
title('Average HFB power across trials for incorrect and correctly remembered trials')

%%
% 2. look at plot_data which has the separate condition and look at
% specific time points that are averaged across all the trials for that
% condition
%use wave or wave_sm


idx = data_all.trialinfo.mem_inc==1
%want to add an indx that indicates what the race was and then combine them
%in the loop below
indx_a = data_all.trialinfo.test_race==1
indx_b = data_all.trialinfo.test_race==2
indx_w = data_all.trialinfo.test_race==3


x_corr_a=[];
x_corr_b=[];
x_corr_w=[];
x_incorr_a = [];
x_incorr_b = [];
x_incorr_w = [];

for p = 1:length(idx)
    if idx(p)==1 && indx_a(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_corr_a)
            x_corr_a =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_corr_a(end+1)= mean(data_all.wave(p,201:451));
        end
    end
    if idx(p)==1 && indx_b(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_corr_b)
            x_corr_b =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_corr_b(end+1)= mean(data_all.wave(p,201:451));
        end
    end
    if idx(p)==1 && indx_w(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_corr_w)
            x_corr_w =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_corr_w(end+1)= mean(data_all.wave(p,201:451));
        end
    end
    
    
    if idx(p)==0 && indx_a(p)==1 %incorrect but same type of trial
        %want time window from .2 (201) to .7(451)
        if isempty(x_incorr_a)
            x_incorr_a =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_incorr_a(end+1)= mean(data_all.wave(p,201:451));
        end
    end
    if idx(p)==1 && indx_b(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_incorr_b)
            x_incorr_b =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_incorr_b(end+1)= mean(data_all.wave(p,201:451));
        end
    end
    if idx(p)==1 && indx_w(p)==1
        %want time window from .2 (201) to .7(451)
        if isempty(x_incorr_w)
            x_incorr_w =mean(data_all.wave(p,201:451)); %p is the trial number
        else
            x_incorr_w(end+1)= mean(data_all.wave(p,201:451));
        end
    end
end


mean(x_corr_a)
mean(x_corr_b)
mean(x_corr_w)
mean(x_incorr_a)
mean(x_incorr_b)
mean(x_incorr_w)
x = [x_corr_a'; x_incorr_a'; x_corr_b';x_incorr_b';x_corr_w';x_incorr_w'];
g = [zeros(length(x_corr_a), 1); ones(length(x_incorr_a), 1);2*ones(length(x_corr_b), 1); 3*ones(length(x_incorr_b), 1);4*ones(length(x_corr_w), 1); 5*ones(length(x_incorr_w), 1)];
boxplot(x, g,'Labels',{'asian correct ','asian incorrect ','black correct','black incorrect','white correct','white incorrect'})
title('Average HFB power across trials for incorrect and correctly remembered trials')

[p,t,stats] = anova1(x,g,'off') %actually even get significant differences even if there is only subject included




%% Salience value

% to do this, rather than average the salience value across trials - I can
% going to make a list of the salience values and mean HFB value across
% those trials 
% going to get at the relationship between 

behav_cts_table = table
for p = 1:size(data_all.trialinfo,1) %for all trials
    %need to match up the trials between rec and encoding
    behav_cts_table.HFB(p) = mean(data_all.wave(p,201:451));
    k = data_all.trialinfo.recall_trial(p);
    behav_cts_table.salience(p) = data_all_rec.trialinfo.salience(k);
    behav_cts_table.certainty(p) = data_all_rec.trialinfo.certainty(k);
    behav_cts_table.RT(p) = data_all_rec.trialinfo.RT(k);
end 

[rho,pval] = corr(behav_cts_table.HFB,behav_cts_table.salience)
[rho,pval] = corr(behav_cts_table.HFB,behav_cts_table.certainty)
[rho,pval] = corr(behav_cts_table.HFB,behav_cts_table.RT)

lsline
figure
ax1 = subplot(3,1,1);
ax2 = subplot(3,1,2);
ax3 = subplot(3,1,3);
scatter(ax1,behav_cts_table.HFB,behav_cts_table.salience)
scatter(ax2,behav_cts_table.HFB,behav_cts_table.certainty)
scatter(ax3,behav_cts_table.HFB,behav_cts_table.RT)
lsline(ax1);lsline(ax2);lsline(ax3)


%% 
% K = load('/Volumes/CSS_backup/data/psychData/C18_37/RACE_1/sodata.PT037_MAXIAOQI.active.28.08.2018.15.34.run1.mat')
% list_stim = K.seq.memory.active.race
% 
% 
% 
% 
% 
% % need to obviously write a loop to load this in
% % but want the time points with the HFB for encoding from enc
% enc = load('/Volumes/CSS_backup/data/neuralData/BandData/HFB/C18_37/RACE_1/EpochData/HFBiEEG_stimlock_bl_corr_RACE_1_150.mat')
% 
% % want the trialinfo from this and match them by the trial value
% rec = load('/Volumes/CSS_backup/data/neuralData/BandData/HFB/C18_37/RACE_3/EpochData/HFBiEEG_stimlock_bl_corr_RACE_3_150.mat')
% 
% % first want to get a list of the stimuli that were encoded correectly 
% 
% % then want to get a list of the stimuli that were remembered correctly
% % PROBLEM IS THAT WE DO NOT HAVE THE NAME OF THE STIMULI! SO WE NEED TO
% % LOAD IN THE SODATA FILE FIRST
% K = load('/Volumes/CSS_backup/data/psychData/C18_37/RACE_1/sodata.PT037_MAXIAOQI.active.28.08.2018.15.34.run1.mat')
% list_stim = K.seq.memory.active.race
% for i= 1:length(list_stim)
%     rec.data.trialinfo.stim_list(i) = string(list_stim(i,:))
% end 
% 
% list_stim = K.seq.active.race %overides 
% for i= 1:length(list_stim)
%     enc.data.trialinfo.stim_list(i) = string(list_stim(i,:))
% end 
% 
% %want to get the trials that are correct, get what the stimulus was and the
% %trial number 
% for i=1:size(rec.data.trialinfo,1)
%     if rec.data.trialinfo.isCorrect(i)==0
%         tmp = rec.data.trialinfo.stim_list(i);
%         for k = 1:size(enc.data.trialinfo,1)
%             if strcmp(tmp,enc.data.trialinfo.stim_list(k)) %if this is true
%             %then mark that this is a trial we want to look at
%                 enc.data.trialinfo.mem_inc(k) = 1;
%             else 
%                 %enc.data.trialinfo.mem_inc(k) = 0;
%             end 
%         end 
%     end 
% end


%% relationship between correct trial and HFB level


% patient was showed 2x to the patient in the encoding so 2 HFB - take the
% mean of those 2 HFBs
% 1 list of ones remembered incorrectly and get the mean of that mean HFB
% from all subjecst with coverage in that ROI
% versus the ones remembererd correctly 
% t-test 


%higher the HFB in encoding, the higher the salience

%higher the HFB in encoding, the lower the RT in memory
% between race and other race x other race (or randomly choose the amount
% of trials)

%in each region one patient with one site
% do for each site and say if it is consistent 

%HFB - 0.5-1, 0 - 0.5
%0.2 - .7
%average HFB across time range for each trial that was correct in encoding
%also do each trial that was incorrect
% t-test comparing the 2


