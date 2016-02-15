function [stat_clus] = mm_ft_clusterplotTFR(cfg_ft,cfg_plot,ana,files,dirs)
%[stat_clus] = mm_ft_clusterplotTFR Plot (and save) significant clusters
%

if ~isfield(cfg_ft,'avgoverfreq')
  cfg_ft.avgoverfreq = 'yes';
end

if isequal(cfg_ft.avgoverfreq,'no')
  cfg_ft.showlabels = 'yes';
  if ~isfield(cfg_plot,'ftFxn')
    cfg_plot.ftFxn = 'ft_multiplotTFR';
  end
  if ~isfield(cfg_ft,'showlabels')
    cfg_ft.showlabels = 'yes';
  end
end

if ~isfield(cfg_plot,'mask')
  cfg_plot.mask = 'no';
end

if isequal(cfg_plot.mask,'yes')
  if ~isfield(cfg_ft,'maskparameter')
    cfg_ft.maskparameter = 'mask';
  end
  if ~isfield(cfg_ft,'maskstyle')
    if files.saveFigs == 1
      cfg_ft.maskstyle = 'saturation';
    else
      cfg_ft.maskstyle = 'opacity';
    end
  end
end

% for using nk plotting functions
if ~isfield(cfg_plot,'noplot')
  cfg_plot.noplot = false;
end

close all
fprintf('Plotting clusters...\n');

% p-val markers; default ['*','x','+','o','.'], p < [0.01 0.05 0.1 0.2 0.3]
cfg_ft.highlightsymbolseries = ['*','x','+','o','.'];
cfg_ft.highlightcolorpos = [0.5 0 1];
cfg_ft.highlightcolorneg = [0 0.5 0];
cfg_ft.elec = ana.elec;
cfg_ft.contournum = 0;
cfg_ft.emarker = '.';
%cfg_ft.xparam = 'time';
%cfg_ft.yparam = 'freq';
cfg_ft.parameter = 'stat';
if ~isfield(cfg_ft,'alpha')
  cfg_ft.alpha  = 0.05;
end
if ~isfield(cfg_ft,'zlim')
  cfg_ft.zlim = [-5 5];
end

% make sure cfg_plot.conditions is set correctly
if ~isfield(cfg_plot,'condMethod')
  if ~iscell(cfg_plot.conditions) && (strcmp(cfg_plot.conditions,'all') || strcmp(cfg_plot.conditions,'all_across_types') || strcmp(cfg_plot.conditions,'all_within_types'))
    cfg_plot.condMethod = 'pairwise';
  elseif iscell(cfg_plot.conditions) && ~iscell(cfg_plot.conditions{1}) && length(cfg_plot.conditions) == 1 && (strcmp(cfg_plot.conditions{1},'all') || strcmp(cfg_plot.conditions{1},'all_across_types') || strcmp(cfg_plot.conditions{1},'all_within_types'))
    cfg_plot.condMethod = 'pairwise';
  elseif iscell(cfg_plot.conditions) && iscell(cfg_plot.conditions{1}) && length(cfg_plot.conditions{1}) == 1 && (strcmp(cfg_plot.conditions{1},'all') || strcmp(cfg_plot.conditions{1},'all_across_types') || strcmp(cfg_plot.conditions{1},'all_within_types'))
    cfg_plot.condMethod = 'pairwise';
  else
    cfg_plot.condMethod = [];
  end
end
cfg_plot.conditions = mm_ft_checkConditions(cfg_plot.conditions,ana,cfg_plot.condMethod);

% extra identification in directory name when saving results
if ~isfield(cfg_plot,'dirStr')
  cfg_plot.dirStr = '';
end

% set the directory to load the file from
dirs.saveDirClusStat = fullfile(dirs.saveDirProc,sprintf('tfr_stat_clus_%d_%d%s',round(cfg_ft.latency(1)*1000),round(cfg_ft.latency(2)*1000),cfg_plot.dirStr));

for cnd = 1:length(cfg_plot.conditions)
  % set the number of conditions that we're testing
  cfg_plot.numConds = size(cfg_plot.conditions{cnd},2);
  vs_str = sprintf('%s%s',cfg_plot.conditions{cnd}{1},sprintf(repmat('vs%s',1,cfg_plot.numConds-1),cfg_plot.conditions{cnd}{2:end}));
  
  fprintf('%s, %d--%d ms, %.1f--%.1f Hz\n',vs_str,round(cfg_ft.latency(1)*1000),round(cfg_ft.latency(2)*1000),cfg_ft.frequency(1),cfg_ft.frequency(2));
  
  savedFile = fullfile(dirs.saveDirClusStat,sprintf('tfr_stat_clus_%s_%.1f_%.1f_%d_%d.mat',vs_str,cfg_ft.frequency(1),cfg_ft.frequency(2),round(cfg_ft.latency(1)*1000),round(cfg_ft.latency(2)*1000)));
  if exist(savedFile,'file')
    fprintf('Loading %s\n',savedFile);
    load(savedFile);
    
    % for running nk_ft_avgpowerbytime
    if cfg_plot.noplot
      return
    end
  else
    warning([mfilename,':FileNotFound'],'No stat_clus file found for %s: %s. Going to next comparison.\n',vs_str,savedFile);
    continue
  end
  
  if ~isfield(stat_clus.(vs_str),'posclusters') && ~isfield(stat_clus.(vs_str),'negclusters')
    fprintf('%s:\tNo positive or negative clusters found.\n',vs_str);
    continue
  end
  
  if isfield(stat_clus.(vs_str),'posclusters') || isfield(stat_clus.(vs_str),'negclusters')
    if ~isempty(stat_clus.(vs_str).posclusters)
      %for i = 1:length(stat_clus.(vs_str).posclusters)
      %  fprintf('%s, Pos (%d of %d) p=%.5f\n',vs_str,i,length(stat_clus.(vs_str).posclusters),stat_clus.(vs_str).posclusters(i).prob);
      %end
      fprintf('%s\tSmallest Pos: p=%.5f\n',vs_str,stat_clus.(vs_str).posclusters(1).prob);
    end
    if ~isempty(stat_clus.(vs_str).negclusters)
      %for i = 1:length(stat_clus.(vs_str).negclusters)
      %  fprintf('%s, Neg (%d of %d) p=%.5f\n',vs_str,i,length(stat_clus.(vs_str).negclusters),stat_clus.(vs_str).negclusters(i).prob);
      %end
      fprintf('%s\tSmallest Neg: p=%.5f\n',vs_str,stat_clus.(vs_str).negclusters(1).prob);
    end
    
    if ~isempty(stat_clus.(vs_str).posclusters) || ~isempty(stat_clus.(vs_str).negclusters)
      sigpos = [];
      if ~isempty(stat_clus.(vs_str).posclusters)
        for iPos = 1:length(stat_clus.(vs_str).posclusters)
          sigpos(iPos) = stat_clus.(vs_str).posclusters(iPos).prob < cfg_ft.alpha;
        end
        sigpos = find(sigpos == 1);
      end
      signeg = [];
      if ~isempty(stat_clus.(vs_str).negclusters)
        for iNeg = 1:length(stat_clus.(vs_str).negclusters)
          signeg(iNeg) = stat_clus.(vs_str).negclusters(iNeg).prob < cfg_ft.alpha;
        end
        signeg = find(signeg == 1);
      end
      Nsigpos = length(sigpos);
      Nsigneg = length(signeg);
      Nsigall = Nsigpos + Nsigneg;
      
      clus_str = '';
      if Nsigpos > 0
        clus_str = cat(2,clus_str,'positive');
      end
      if Nsigneg > 0 && isempty(clus_str)
        clus_str = cat(2,clus_str,'negative');
      elseif Nsigneg > 0 && ~isempty(clus_str)
        clus_str = cat(2,clus_str,' and negative');
      end
      
      if Nsigall > 0
        if Nsigall == 1
          clus_str = cat(2,clus_str,' cluster');
        elseif Nsigall > 1
          clus_str = cat(2,clus_str,' clusters');
        end
        fprintf('%s:\t***Found significant %s at p<%.3f***\n',vs_str,clus_str,cfg_ft.alpha);
        
        if isequal(cfg_ft.avgoverfreq,'yes')
          ft_clusterplot(cfg_ft,stat_clus.(vs_str));
          keyboard
        elseif isequal(cfg_ft.avgoverfreq,'no')
          % save the fields
          conditions_orig = cfg_plot.conditions;
          eventValues_orig = ana.eventValues;
          
          % do the plot
          cfg_plot.conditions = vs_str;
          cfg_plot.condMethod = 'check';
          ana.eventValues = {{vs_str}};
          mm_ft_plotTFR_old(cfg_ft,cfg_plot,ana,files,dirs,stat_clus);
          
          % put the fields back
          cfg_plot.conditions = conditions_orig;
          ana.eventValues = eventValues_orig;
          
          % for when we're looking at multiplots
          keyboard
        end
        
        if files.saveFigs
          fignums = findobj('Type','figure');
          for f = 1:length(fignums)
            figure(f)
            
            cfg_plot.figfilename = sprintf('tfr_clus_ga_%s_%d_%d_%d_%d_fig%d',vs_str,round(cfg_ft.frequency(1)),round(cfg_ft.frequency(2)),round(cfg_ft.latency(1)*1000),round(cfg_ft.latency(2)*1000),f);
            
            dirs.saveDirFigsClus = fullfile(dirs.saveDirFigs,sprintf('tfr_stat_clus_%d_%d%s',round(cfg_ft.latency(1)*1000),round(cfg_ft.latency(2)*1000),cfg_plot.dirStr),vs_str);
            if ~exist(dirs.saveDirFigsClus,'dir')
              mkdir(dirs.saveDirFigsClus)
            end
            
            if strcmp(files.figPrintFormat(1:2),'-d')
              files.figPrintFormat = files.figPrintFormat(3:end);
            end
            if ~isfield(files,'figPrintRes')
              files.figPrintRes = 150;
            end
            print(gcf,sprintf('-d%s',files.figPrintFormat),sprintf('-r%d',files.figPrintRes),fullfile(dirs.saveDirFigsClus,cfg_plot.figfilename));
          end
        end % if
        close all
        
      elseif Nsigall == 0
        fprintf('%s:\tNo significant positive or negative clusters at p<%.3f\n',vs_str,cfg_ft.alpha);
      end
    elseif isempty(stat_clus.(vs_str).posclusters) && isempty(stat_clus.(vs_str).negclusters)
      fprintf('%s:\tNo positive or negative clusters found.\n',vs_str);
    end
  end % if isfield
  
end % for cnd

fprintf('Done.\n');

end
