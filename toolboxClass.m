classdef toolboxClass < handle
    properties
        name = ''
        version
        toolPath = ''
        autoLoad = false % (re-)load sub-toolbox with its parent
        keepInPath = false % keep the toolbox in the path after deletion
        showGUI = false % show GUI upon load
    end

    properties (Dependent)
        status
    end

    properties (Access = protected, Constant = true)
        STATUS = containers.Map(...
            {'undefined' 'defined' 'unloaded' 'loaded'},...
            [-1 0 1 2] ...
            );
    end

    properties (Access = protected)
        pStatus = -1

        toolInPath = {}

        workspace

        collections = struct('name',{},'path',{},'toolbox',{})

        toolboxes = cell(1,0)
    end

    properties (Access = protected, Abstract)
        hGUI % GUI handles
    end

    methods
        function this = toolboxClass(name,path,doAddToPath,workspaceVariableNames)
            this.name = name;
            this.toolPath = path;
            if doAddToPath
                addpath(this.toolPath);
                this.toolInPath = cellstr(this.toolPath);
                this.setAutoLoad();
            end
            this.pStatus = this.STATUS('defined');

            this.workspace = cellfun(@jsondecode, workspaceVariableNames);
            if ~isempty(this.workspace), this.workspace(1).value = []; end
        end

        function val = get.status(this)
            val = this.STATUS.keys(cell2mat(this.STATUS.values) == this.pStatus);
        end

        function load(this,keepWorkspace)
            if nargin < 2, keepWorkspace = false; end
            if this.pStatus < this.STATUS('loaded')
                p = strsplit(path,pathsep);
                this.toolInPath = p(cellfun(@(x) ~isempty(strfind(x,this.toolPath)), p));

                % add modification
                tbname = this.name;
                if isempty(tbname), tbname = strrep(class(this),'Class',''); end
                modDir = fullfile(fileparts(mfilename('fullpath')),[tbname '_mods']);
                if exist(modDir,'dir')
                    addpath(genpath(modDir));
                    modDir = strsplit(genpath(modDir),pathsep);
                    this.toolInPath = [modDir(1:end-1)'; this.toolInPath];
                end
                this.pStatus = this.STATUS('loaded');
            end
            toRemove = [];
            for iw = 1:numel(this.workspace)
                if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                    eval(['global ' this.workspace(iw).name]);
                    assignin('base', this.workspace(iw).name, eval(this.workspace(iw).name));
                end
                if ~any(strcmp(evalin('base','who'),this.workspace(iw).name))
                    toRemove(end+1) = iw;
                    continue;
                end
                this.workspace(iw).value = evalin('base',this.workspace(iw).name);
                if ~keepWorkspace, evalin('base',['clear ' this.workspace(iw).name]); end
            end
            this.workspace(toRemove) = [];
        end

        function close(this)
            % remove from path
            if ~this.keepInPath, this.unload; end

            % close sub-toolboxes
            for t = this.toolboxes
                t{1}.close;
            end

            % GUI and workspace
            for h = this.hGUI, close(h); end
            for iw = 1:numel(this.workspace)
                evalin('base',['clear ' this.workspace(iw).name]);
                if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                    eval(['clear global ' this.workspace(iw).name]);
                end
            end

            this.pStatus = this.STATUS('undefined');
        end

        function reload(this,loadWorkspace)
            % default
            if nargin < 2, loadWorkspace = false; end

            % re-add to path
            if this.pStatus < this.STATUS('loaded')
                addpath(strjoin(this.toolInPath,pathsep))
                this.pStatus = this.STATUS('loaded');
            end

            % reload sub-toolboxes
            for t = this.toolboxes
                if t{1}.autoLoad, t{1}.reload; end
            end

            % GUI and workspace
            if this.showGUI, for h = this.hGUI, set(h,'visible','on'); end; end
            if loadWorkspace
                for iw = 1:numel(this.workspace)
                    if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                        eval(['global ' this.workspace(iw).name]);
                    end
                    assignin('base', this.workspace(iw).name, this.workspace(iw).value);
                end
            end
        end

        function unload(this,updateWorkspace)
            % default
            if nargin < 2, updateWorkspace = false; end

            % remove from path
            if this.pStatus > this.STATUS('unloaded')
                warning('%s''s folders (and subfolders) will be removed from the MATLAB path',class(this));
                if any(strcmp(this.toolInPath,pwd)) % current path in toolInPath -> cd Octave (assume no tool in Octave)
                    cwd = pwd;
                    cd(OCTAVE_HOME);
                end
                rmpath(strjoin(this.toolInPath,pathsep))
                if exist('cwd','var'), cd(cwd); end
                this.pStatus = this.STATUS('unloaded');
            end

            % unload sub-toolboxes
            for t = this.toolboxes
                t{1}.unload;
            end

            % GUI and workspace
            if this.showGUI, for h = this.hGUI, set(h,'visible','off'); end; end
            for iw = 1:numel(this.workspace)
                if updateWorkspace, this.workspace.(iw).value = evalin('base',this.workspace(iw).name); end
                evalin('base',['clear ' this.workspace(iw).name]);
                if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                    eval(['clear global ' this.workspace(iw).name]);
                end
            end
        end

        %% sub-toolboxes
        function addToolbox(this,tb)
            if isempty(tb.name)
                warning('sub-toolbox MUST have a name');
                return
            end
            isTb = cellfun(@(t) strcmp(tb.name,t.name), this.toolboxes);
            if isTb
                warning('toolbox %s is already added as a sub-toolbox', tb.name);
            else
                if tb.autoLoad, tb.load; end
                this.toolboxes{end+1} = tb;
            end
        end

        function doToolbox(this,tbname,task)
            if ~any(strcmp(methods('toolboxClass'),task))
                warning('unsupported task: %s',task)
                return
            end

            isTb = cellfun(@(t) strcmp(tbname,t.name), this.toolboxes);
            if ~isTb
                warning('toolbox %s is not a sub-toolbox', tbname);
            else
                this.toolboxes{isTb}.(task);
            end
        end

        function rmToolbox(this,tbname)
            isTb = cellfun(@(t) strcmp(tbname,t.name), this.toolboxes);
            if ~isTb
                warning('toolbox %s is not a sub-toolbox', tbname);
            else
                tb = this.toolboxes{isTb};
                tb.close;
                this.toolboxes(isTb) = [];
            end
        end

        function setAutoLoad(this)
            this.autoLoad = true;
        end
        function unsetAutoLoad(this)
            this.autoLoad = false;
        end

        %% collections
         function addCollection(this,collection)
            if this.pStatus < this.STATUS('loaded')
                warning('toolbox is not loaded')
                return
            end
            iC = strcmp(this.collections.name,collection);
            if ~any(iC)
                warning('external %s not specified',collection);
                return
            end
            for p = this.collections(iC).path
                currp = fullfile(this.toolPath,strrep(p{1},'/',filesep));
                addpath(currp);
                this.toolInPath = vertcat(this.toolInPath,currp);
            end
            for t = this.collections(iC).toolbox
                this.doToolbox(t{1},'load');
            end
        end

        function rmCollection(this,collection)
            iC = strcmp(this.collections.name,collection);
            if ~any(iC)
                warning('external %s not specified',collection);
                return
            end
            for p = this.collections(iC).path
                currp = fullfile(this.toolPath,strrep(p{1},'/',filesep));
                rmpath(currp);
                this.toolInPath(strcmp(this.toolInPath,currp)) = [];
            end
            for t = this.collections(iC).toolbox
                this.doToolbox(t{1},'unload');
            end
        end
    end
end
