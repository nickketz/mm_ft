function mm_ft_contrastTFR(cfg_ft,cfg_plot,ana,exper,files,dirs,data,sesNum)
%MM_FT_CONTRASTTFR plot (and save) contast topoplots of time-freq data
%
%   mm_ft_contrastTFR(cfg_ft,cfg_plot,ana,exper,files,dirs,data,sesNum)
%
% Inputs:
%   cfg_ft: parameters passed into the FT plotting function
%
%   cfg_plot.ftFxn      = FieldTrip plotting function to use. Supported
%                         functions: ft_singleplotTFR, ft_topoplotTFR, and
%                         ft_multiplotTFR
%   cfg_plot.conditions = Cell array containing cells of pairwise
%                         comparisons; Can be used for comparing a subset
%                         of events within a type.
%                         e.g., {{'T1a','T1c'}, {'T2a','T2c'}}, or it can
%                         be {{'all_within_types'}} or
%                         {{'all_across_types'}} to automatically create
%                         pairwise comparisons of event values. See
%                         MM_FT_CHECKCONDITIONS for more details.
%   cfg_plot.plotTitle  = 1 or 0. Whether to plot the title.
%   cfg_plot.subplot    = 1 or 0. Whether to make a subplot. cfg_ft.xlim
%                         can be a range of time values, otherwise 50ms
%                         steps between min and max. ft_topoplotER only.
%   cfg_plot.numCols    = If subplot == 1, the number of columns to plot
%   files.saveFigs     = 1 or 0. Whether to save the figures.
%
%   data                = output from ft_freqgrandaverage
%
% See also:
%   MM_FT_CHECKCONDITIONS

if ~isfield(cfg_ft,'parameter')
  error('Must specify cfg_ft.parameter, denoting the data to plot (e.g., ''avg'' or ''individual'')');
end

if ~isfield(cfg_ft,'maskparameter')
  cfg_ft.maskparameter = [];
end
if ~isempty(cfg_ft.maskparameter)
  if ~isfield(cfg_plot,'maskvalue')
    cfg_plot.maskvalue = 0;
  end
end

if ~isfield(cfg_plot,'plotTitle')
  cfg_ft.plotTitle = 0;
end

cfg_plot.type = strrep(strrep(cfg_plot.ftFxn,'ft_',''),'plotTFR','');

% good default z-limits
if ~isfield(cfg_ft,'zlim')
  if strcmp(ft_findcfg(data.(exper.sesStr{sesNum}).(ana.eventValues{1}{1}).cfg,'baselinetype'),'absolute')
    cfg_ft.zlim = [-400 400];
  elseif strcmp(ft_findcfg(data.(exper.sesStr{sesNum}).(ana.eventValues{1}{1}).cfg,'baselinetype'),'relative')
    cfg_ft.zlim = [0 2.0];
  elseif strcmp(ft_findcfg(data.(exper.sesStr{sesNum}).(ana.eventValues{1}{1}).cfg,'baselinetype'),'relchange')
    cfg_ft.zlim = [-1.0 1.0];
  end
end

% for automatically resizing figure windows
cfg_plot.screenXY = get(0,'ScreenSize');
cfg_plot.screenXY = cfg_plot.screenXY(3:4);

if ~isfield(cfg_plot,'plotTitle')
  cfg_plot.plotTitle = 0;
end
% % check on the labels
% if ~isfield(cfg_plot,'xlabel')
%   cfg_plot.xlabel = 'Time (s)';
% end
% if ~isfield(cfg_plot,'ylabel')
%   cfg_plot.ylabel = 'Voltage (\muV)';
% end

if strcmp(cfg_plot.type,'single') || strcmp(cfg_plot.type,'multi')
  if ~isfield(cfg_ft,'fontsize')
    cfg_ft.fontsize = 9;
  end
  if ~isfield(cfg_ft,'linewidth')
    if strcmp(cfg_plot.type,'single')
      cfg_ft.linewidth = 2;
    elseif strcmp(cfg_plot.type,'multi')
      cfg_ft.linewidth = 1;
    end
  end
  if ~isfield(cfg_ft,'graphcolor')
    cfg_ft.graphcolor = 'rbkgcmyrbkgcmyrbkgcmy';
  end
  if ~isfield(cfg_ft,'linestyle')
    cfg_ft.linestyle = {'-','--','-.','-','--','-.','-','--','-.','-','--','-.','-','--','-.','-','--','-.','-','--','-.'};
  end
end
% not sure if this gets used
if ~isfield(cfg_plot,'excludeBadSub')
  cfg_plot.excludeBadSub = 1;
end

if (strcmp(cfg_plot.type,'multi') || strcmp(cfg_plot.type,'topo'))
  % need a layout if doing a topo or multi plot
  if isfield(ana,'elec')
    cfg_ft.layout = ft_prepare_layout([],ana);
  else
    error('''ana'' struct must have ''elec'' field');
  end
  
  if ~isfield(cfg_plot,'roi')
    % use all channels in a topo or multi plot
    cfg_plot.roi = {'all'};
  end
  
  if strcmp(cfg_plot.type,'topo')
    if isfield(cfg_ft,'showlabels')
      % not allowed
      cfg_ft = rmfield(cfg_ft,'showlabels');
    end
    % not sure fontsize does anything
    if ~isfield(cfg_ft,'fontsize')
      cfg_ft.fontsize = 10;
    end
    if ~isfield(cfg_ft,'markerfontsize')
      cfg_ft.markerfontsize = 9;
    end
    if ~isfield(cfg_ft,'colormap')
      cfg_ft.colormap = hot(64);
    end
    
    % colorbar label
    if ~isfield(cfg_plot,'zlabel')
      cfg_plot.zlabel = 'Power';
    end
  end
end

% % make sure conditions are set correctly
% if ~isfield(cfg_plot,'condMethod')
%   if ~iscell(cfg_plot.conditions) && (strcmp(cfg_plot.conditions,'all') || strcmp(cfg_plot.conditions,'all_across_types') || strcmp(cfg_plot.conditions,'all_within_types'))
%     cfg_plot.condMethod = 'pairwise';
%   elseif iscell(cfg_plot.conditions) && ~iscell(cfg_plot.conditions{1}) && length(cfg_plot.conditions) == 1 && (strcmp(cfg_plot.conditions{1},'all') || strcmp(cfg_plot.conditions{1},'all_across_types') || strcmp(cfg_plot.conditions{1},'all_within_types'))
%     cfg_plot.condMethod = 'pairwise';
%   elseif iscell(cfg_plot.conditions) && iscell(cfg_plot.conditions{1}) && length(cfg_plot.conditions{1}) == 1 && (strcmp(cfg_plot.conditions{1},'all') || strcmp(cfg_plot.conditions{1},'all_across_types') || strcmp(cfg_plot.conditions{1},'all_within_types'))
%     cfg_plot.condMethod = 'pairwise';
%   else
%     cfg_plot.condMethod = [];
%   end
% end
% cfg_plot.conditions = mm_ft_checkConditions(cfg_plot.conditions,ana,cfg_plot.condMethod);

% make sure conditions are set up for the for loop
if ~isfield(cfg_plot,'types')
  cfg_plot.types = repmat({''},size(cfg_plot.conditions));
end

% set the channel information
if ~isfield(cfg_plot,'roi')
  error('Must specify either ROI names or channel names in cfg_plot.roi');
elseif isfield(cfg_plot,'roi')
  if ismember(cfg_plot.roi,ana.elecGroupsStr)
    % if it's in the predefined ROIs, get the channel numbers
    if strcmp(cfg_plot.type,'topo')
      cfg_ft.highlight = 'on';
      cfg_ft.highlightsize = 10;
      cfg_ft.highlightchannel = cat(2,ana.elecGroups{ismember(ana.elecGroupsStr,cfg_plot.roi)});
    else
      cfg_ft.channel = cat(2,ana.elecGroups{ismember(ana.elecGroupsStr,cfg_plot.roi)});
    end
    
    % set the string for the filename
    %chan_str = sprintf(repmat('%s_',1,length(cfg_plot.roi)),cfg_plot.roi{:});
    if iscell(cfg_plot.roi) && length(cellflat(cfg_plot.roi)) <= 10
      chan_str = cellflat(cfg_plot.roi);
      chan_str = sprintf(repmat('_%s',1,length(chan_str)),chan_str{:});
    elseif iscell(cfg_plot.roi) && length(cellflat(cfg_plot.roi)) > 10
      chan_str = sprintf('_%dROIs',length(cellflat(cfg_plot.roi)));
    else
      keyboard
    end
  else
    % otherwise it should be the channel number(s) or 'all'
    if ~iscell(cfg_plot.roi)
      cfg_plot.roi = {cfg_plot.roi};
    end
    
    if strcmp(cfg_plot.type,'topo')
      if ~strcmp(cfg_plot.roi,'all')
        cfg_ft.highlight = 'on';
        cfg_ft.highlightsize = 10;
        cfg_ft.highlightchannel = cfg_plot.roi;
      end
    else
      cfg_ft.channel = cfg_plot.roi;
    end
    
    % set the string for the filename
    %chan_str = sprintf(repmat('%s_',1,length(cfg_plot.roi)),cfg_plot.roi{:});
    if iscell(cfg_plot.roi) && length(cellflat(cfg_plot.roi)) <= 10
      chan_str = cellflat(cfg_plot.roi);
      chan_str = sprintf(repmat('_%s',1,length(chan_str)),chan_str{:});
    elseif iscell(cfg_plot.roi) && length(cellflat(cfg_plot.roi)) > 10
      chan_str = sprintf('_%dROIs',length(cellflat(cfg_plot.roi)));
    else
      keyboard
    end
  end
end

% time - get this info for the figure name
if isfield(cfg_ft,'xlim')
  if strcmp(cfg_ft.xlim,'maxmin')
    cfg_ft.xlim = [min(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).time) max(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).time)];
  end
else
  cfg_ft.xlim = [min(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).time) max(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).time)];
end

% set parameters for the subplot
if isfield(cfg_plot,'subplot')
  if cfg_plot.subplot
    if ~strcmp(cfg_plot.type,'topo')
      fprintf('Subplot only works with topoplot! Changing to non-subplot.\n');
      cfg_plot.subplot = 0;
    else
      if length(cfg_ft.xlim) > 2
        % predefined time windows
        cfg_plot.timeS = cfg_ft.xlim;
      else
        % default: 50 ms time windows
        cfg_plot.timeS = (cfg_ft.xlim(1):0.05:cfg_ft.xlim(2));
      end
      
      if ~isfield(cfg_plot,'numCols')
        cfg_plot.numCols = 5;
      end
      if (length(cfg_plot.timeS)-1) < cfg_plot.numCols
        cfg_plot.numCols = (length(cfg_plot.timeS)-1);
      end
      cfg_plot.numRows = ceil((length(cfg_plot.timeS)-1)/cfg_plot.numCols);
      
      % a few settings to make the graphs viewable
      if ~isfield(cfg_ft,'comment')
        cfg_ft.comment = 'xlim';
      end
      cfg_ft.commentpos = 'title';
      cfg_ft.colorbar = 'no';
      cfg_ft.marker = 'on';
      if ~isfield(cfg_ft,'fontsize')
        cfg_ft.fontsize = 10;
      end
      if isfield(cfg_ft,'markerfontsize')
        cfg_ft = rmfield(cfg_ft,'markerfontsize');
      end
      cfg_plot.plotTitle = 0;
    end
  end
else
  cfg_plot.subplot = 0;
end

% freq
if isfield(cfg_ft,'ylim')
  if strcmp(cfg_ft.ylim,'maxmin')
    cfg_ft.ylim = [min(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).freq) max(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).freq)];
  end
else
  cfg_ft.ylim = [min(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).freq) max(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{1}{1}).freq)];
end

% initialize for storing the contrast topoplots
cont_plot = [];

for typ = 1:length(cfg_plot.conditions)
  % set the number of conditions that we're testing
  cfg_plot.numConds = size(cfg_plot.conditions{typ},2);
  
  vs_str = sprintf('%s%s',cfg_plot.conditions{typ}{1},sprintf(repmat('vs%s',1,cfg_plot.numConds-1),cfg_plot.conditions{typ}{2:end}));
  
  if cfg_plot.numConds > 2
    error('mm_ft_contrastTFR:numCondsGT2','Trying to compare %s, but this is a contrast plot and thus can only compare 2 conditions.\n',vs_str);
  end
  
  % create contrast
  cont_plot.(vs_str) = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1});
  cont_plot.(vs_str).(cfg_ft.parameter) = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).(cfg_ft.parameter) - data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{2}).(cfg_ft.parameter);
  
  % parameter
  timesel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time));
  tbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(1));
  tend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(2));
  timesel(tbeg:tend) = true;
  freqsel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq));
  fbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(1));
  fend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(2));
  freqsel(fbeg:fend) = true;
  if isfield(cfg_ft,'zlim')
    if strcmp(cfg_ft.zlim,'maxmin')
      usedMaxmin = 1;
%       %timesel = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time >= cfg_ft.xlim(1) & data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time <= cfg_ft.xlim(2);
%       timesel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time));
%       tbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(1));
%       tend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(2));
%       timesel(tbeg:tend) = true;
%       
%       %freqsel = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq >= cfg_ft.ylim(1) & data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq <= cfg_ft.ylim(2);
%       freqsel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq));
%       fbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(1));
%       fend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(2));
%       freqsel(fbeg:fend) = true;
      
      cfg_ft.zlim = [min(mean(cont_plot.(vs_str).(cfg_ft.parameter)(:,freqsel,timesel),2)) max(mean(cont_plot.(vs_str).(cfg_ft.parameter)(:,freqsel,timesel),2))];
    else
      usedMaxmin = 0;
    end
  else
%     %timesel = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time >= cfg_ft.xlim(1) & data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time <= cfg_ft.xlim(2);
%     timesel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time));
%     tbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(1));
%     tend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).time,cfg_ft.xlim(2));
%     timesel(tbeg:tend) = true;
%     
%     %freqsel = data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq >= cfg_ft.ylim(1) & data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq <= cfg_ft.ylim(2);
%     freqsel = false(1,length(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq));
%     fbeg = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(1));
%     fend = nearest(data.(exper.sesStr{sesNum}).(cfg_plot.conditions{typ}{1}).freq,cfg_ft.ylim(2));
%     freqsel(fbeg:fend) = true;
    
    cfg_ft.zlim = [min(mean(cont_plot.(vs_str).(cfg_ft.parameter)(:,freqsel,timesel),2)) max(mean(cont_plot.(vs_str).(cfg_ft.parameter)(:,freqsel,timesel),2))];
    usedMaxmin = 1;
  end
  
  % make a plot
  figure
  
  if strcmp(cfg_plot.type,'topo') && ~isempty(cfg_ft.maskparameter)
    % for some reason this 1-D version isn't working
    %cont_plot.(vs_str).(cfg_ft.maskparameter) = ones(size(cont_plot.(vs_str).label,1),1);
    %cont_plot.(vs_str).(cfg_ft.maskparameter)(~ismember(cont_plot.(vs_str).label,cfg_ft.highlightchannel)) = cfg_plot.maskvalue;
    
    % only 3-D is working
    cont_plot.(vs_str).(cfg_ft.maskparameter) = ones(size(cont_plot.(vs_str).(cfg_ft.parameter)));
    cont_plot.(vs_str).(cfg_ft.maskparameter)(~ismember(cont_plot.(vs_str).label,cfg_ft.highlightchannel),~freqsel,~timesel) = cfg_plot.maskvalue;
  end
  
  if cfg_plot.subplot
    for k = 1:length(cfg_plot.timeS)-1
      subplot(cfg_plot.numRows,cfg_plot.numCols,k);
      cfg_ft.xlim = [cfg_plot.timeS(k) cfg_plot.timeS(k+1)];
      feval(str2func(cfg_plot.ftFxn),cfg_ft,cont_plot.(vs_str));
    end
    % reset the xlim
    cfg_ft.xlim = [cfg_plot.timeS(1) cfg_plot.timeS(end)];
  else
    feval(str2func(cfg_plot.ftFxn),cfg_ft,cont_plot.(vs_str));
  end
  
  if ~isempty(cfg_plot.types{typ})
    set(gcf,'Name',sprintf('%s, %s vs. %s, %.1f--%.1f Hz, %.1f--%.1f s',cfg_plot.types{typ},strrep(cfg_plot.conditions{typ}{1},'_','-'),strrep(cfg_plot.conditions{typ}{2},'_','-'),cfg_ft.ylim(1),cfg_ft.ylim(2),cfg_ft.xlim(1),cfg_ft.xlim(2)))
  else
    set(gcf,'Name',sprintf('%s vs. %s, %.1f--%.1f Hz, %.1f--%.1f s',strrep(cfg_plot.conditions{typ}{1},'_','-'),strrep(cfg_plot.conditions{typ}{2},'_','-'),cfg_ft.ylim(1),cfg_ft.ylim(2),cfg_ft.xlim(1),cfg_ft.xlim(2)))
  end
  
  if strcmp(cfg_ft.colorbar,'yes')
    cfg_plot.colorbar_str = '_cb';
    h = colorbar;
    set(get(h,'YLabel'),'string',cfg_plot.zlabel);
  else
    cfg_plot.colorbar_str = '';
  end
  if cfg_plot.subplot
    cfg_plot.subplot_str = '_subplot';
  else
    cfg_plot.subplot_str = '';
  end
  if cfg_plot.plotTitle
    %title(sprintf('%s - %s, %.1f--%.1f Hz, %.1f--%.1f s',cfg_plot.conditionNames{c,1},cfg_plot.conditionNames{c,2},cfg_ft.ylim(1),cfg_ft.ylim(2),cfg_ft.xlim(1),cfg_ft.xlim(2)));
    title(sprintf('%s vs. %s, %.1f--%.1f Hz, %.1f--%.1f s',strrep(cfg_plot.conditions{typ}{1},'_','-'),strrep(cfg_plot.conditions{typ}{2},'_','-'),cfg_ft.ylim(1),cfg_ft.ylim(2),cfg_ft.xlim(1),cfg_ft.xlim(2)));
    cfg_plot.title_str = '_title';
  else
    cfg_plot.title_str = '';
  end
  if ~isfield(files,'figFontName')
    files.figFontName = 'Helvetica';
  end
  if ~cfg_plot.subplot
    publishfig(gcf,~cfg_plot.plotTitle,[],[],files.figFontName);
  end
  if exist('tightfig','file')
    tightfig(gcf);
  end
  
  if files.saveFigs
    % make a string indicating the z-limits; change the decimal to a p for
    % "point" because print.m and LaTeX won't find the right extension when
    % there's a period in the file name (or at least this makes things
    % easier for me right now).
    cfg_plot.zlim_str{1} = strrep(sprintf('%.1f',cfg_ft.zlim(1)),'.','p');
    cfg_plot.zlim_str{2} = strrep(sprintf('%.1f',cfg_ft.zlim(2)),'.','p');
    if ~isempty(cfg_plot.types{typ})
      cfg_plot.figfilename = sprintf('tfr_%scont_ga_%s_%s_%d_%d_%d_%d%s_%s_%s%s%s%s',cfg_plot.type,cfg_plot.types{typ},vs_str,round(cfg_ft.ylim(1)),round(cfg_ft.ylim(2)),round(cfg_ft.xlim(1)*1000),round(cfg_ft.xlim(2)*1000),chan_str,cfg_plot.zlim_str{1},cfg_plot.zlim_str{2},cfg_plot.colorbar_str,cfg_plot.subplot_str,cfg_plot.title_str);
    else
      cfg_plot.figfilename = sprintf('tfr_%scont_ga_%s_%d_%d_%d_%d%s_%s_%s%s%s%s',cfg_plot.type,vs_str,round(cfg_ft.ylim(1)),round(cfg_ft.ylim(2)),round(cfg_ft.xlim(1)*1000),round(cfg_ft.xlim(2)*1000),chan_str,cfg_plot.zlim_str{1},cfg_plot.zlim_str{2},cfg_plot.colorbar_str,cfg_plot.subplot_str,cfg_plot.title_str);
    end
    
    dirs.saveDirFigsTopo = fullfile(dirs.saveDirFigs,['tfr_',cfg_plot.type,'cont']);
    if ~exist(dirs.saveDirFigsTopo,'dir')
      mkdir(dirs.saveDirFigsTopo)
    end
    
    if strcmp(files.figPrintFormat(1:2),'-d')
      files.figPrintFormat = files.figPrintFormat(3:end);
    end
    if ~isfield(files,'figPrintRes')
      files.figPrintRes = 150;
    end
    print(gcf,sprintf('-d%s',files.figPrintFormat),sprintf('-r%d',files.figPrintRes),fullfile(dirs.saveDirFigsTopo,cfg_plot.figfilename));
  end
  
  % get the figure's current position and size
  cfg_plot.pos = get(gcf, 'Position');
  % get the height x width ratio
  hwRatio = cfg_plot.pos(3) / cfg_plot.pos(4);
  % % square figure
  % cfg_plot.figSize = [ceil(min(cfg_plot.screenXY) * 0.85) ceil(min(cfg_plot.screenXY) * 0.85)];
  % maintain figure height x width ratio
  cfg_plot.figSize = [ceil(min(cfg_plot.screenXY) * 0.85) ceil(min(cfg_plot.screenXY) * 0.85 * hwRatio)];
  % resize the figure window
  set(gcf, 'Units', 'pixels', 'Position', [ceil(cfg_plot.pos(1) * 0.6), cfg_plot.pos(2), cfg_plot.figSize(2), cfg_plot.figSize(1)]);
  
  % put maxmin back in
  if usedMaxmin
    cfg_ft.zlim = 'maxmin';
  end
end

end
