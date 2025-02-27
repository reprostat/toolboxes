classdef toolboxClass < statusClass
    properties
        name = ''
        version
        toolPath = ''
        autoLoad = false % (re-)load sub-toolbox with its parent
        keepInPath = false % keep the toolbox in the path after deletion
        showGUI = false % show GUI upon load
    end

    properties (Hidden, SetAccess = protected)
        toolInPath = {}
        toolClassPath

        workspace

        collections = struct('name',{},'path',{},'toolbox',{})

        toolboxes = cell(1,0)

        loadedFromStruct = false
    end

    properties (Access = protected, Constant = true)
        STATUS = containers.Map(...
            {'undefined' 'defined' 'unloaded' 'loaded'},...
            [-1 0 1 2] ...
            );
    end

    properties (Access = protected, Abstract)
        hGUI % GUI handles
    end

    methods
        function this = toolboxClass(name,path,doAddToPath,workspaceVariableNames)
            if isstruct(path) % load from struct
                this.loadedFromStruct = path;

                name = this.loadedFromStruct.name;
                path = this.loadedFromStruct.path;
                doAddToPath = this.loadedFromStruct.doAddToPath;
            end

            this.name = name;
            this.toolPath = strrep(path,'/',filesep);

            this.toolClassPath = fileparts(which([class(this) '.m']));

            if doAddToPath
                addpath(this.toolPath);
                this.toolInPath = cellstr(this.toolPath);
                this.setAutoLoad();
            end
            this.pStatus = this.STATUS('defined');

            this.workspace = cellfun(@jsondecode, workspaceVariableNames);
            if ~isempty(this.workspace), this.workspace(1).value = []; end
        end

        function val = struct(this)
            val = struct('className',class(this),...
                         'name',this.name,...
                         'path',this.toolPath,...
                         'doAddToPath',this.autoLoad,...
                         'status',this.status);
            val.toolInPath = this.toolInPath;
            val.workspace = this.workspace;
        end

        function updateAfterLoadedFromStruct(this)
            clearLoadStruct = true;
            if isstruct(this.loadedFromStruct) % load from struct
                for prop = reshape(setdiff(fieldnames(this.loadedFromStruct),{'className','name','path','doAddToPath','status'}),1,[])
                    mc = metaclass(this);
                    if iscell(mc.PropertyList)
                        mp = mc.PropertyList{cellfun(@(p) strcmp(p.Name,prop{1}), mc.PropertyList)};
                    else
                        mp = mc.PropertyList(arrayfun(@(p) strcmp(p.Name,prop{1}), mc.PropertyList));
                    end
                    if strcmp(mp.SetAccess,'public') || strcmp(mp.DefiningClass.Name,'toolboxClass')
                        this.(prop{1}) = this.loadedFromStruct.(prop{1});
                    else
                        clearLoadStruct = false;
                        if iscell(mc.MethodList)
                            mm = mc.MethodList{cellfun(@(p) strcmp(p.Name,'updateAfterLoadedFromStruct'), mc.MethodList)};
                        else
                            mm = mc.MethodList(arrayfun(@(p) strcmp(p.Name,'updateAfterLoadedFromStruct'), mc.MethodList));
                        end
                        if ~strcmp(mm.DefiningClass.Name,mc.Name)
                            warning(['Unique property ''%s'' of class ''%s'' is not public and cannot be updated and\n' ...
                                     '\tthe class has no unique method ''updateAfterLoadedFromStruct'''],...
                            prop{1},mc.Name);
                        end
                    end
                end
                if strcmp(this.loadedFromStruct.status,'loaded') && (this.pStatus < this.STATUS('loaded'))
                    this.reload(true);
                end
                if clearLoadStruct, this.loadedFromStruct = false; end
            end
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
                    if isOctave(), addpath(genpath(modDir));
                    else
                        p_mod = strsplit(genpath(modDir),pathsep);
                        for p_oct = p_mod(endsWith(p_mod, 'octave'))
                            p_mod(startsWith(p_mod, p_oct{1})) = [];
                        end
                        addpath(strjoin(p_mod,pathsep));
                    end
                    modDir = strsplit(genpath(modDir),pathsep);
                    this.toolInPath = [reshape(modDir(~cellfun(@isempty, modDir)),[],1); reshape(this.toolInPath,[],1)];
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
            % close sub-toolboxes
            for t = this.toolboxes
                t{1}.close;
            end

            % remove from path
            if ~this.keepInPath, this.unload; end

            % GUI and workspace
            for h = this.hGUI, close(h); end
            for iw = 1:numel(this.workspace)
                evalin('base',['clear ' this.workspace(iw).name]);
                if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                    evalin('base',['clear global ' this.workspace(iw).name]);
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
                        evalin('base',['global ' this.workspace(iw).name]);
                    end
                    assignin('base', this.workspace(iw).name, this.workspace(iw).value);
                end
            end
        end

        function unload(this,updateWorkspace)
            % default
            if nargin < 2, updateWorkspace = false; end

            % unload sub-toolboxes
            for t = this.toolboxes
                t{1}.unload;
            end

            % remove from path
            if this.pStatus > this.STATUS('unloaded')
                warning('%s''s folders (and subfolders) will be removed from the MATLAB path',class(this));
                if any(strcmp(this.toolInPath,pwd)) % current path in toolInPath -> cd Octave (assume no tool in Octave)
                    cwd = pwd;
                    if isOctave(), cd(OCTAVE_HOME);
                    else, cd(matlabroot);
                    end
                end
                rmpath(strjoin(this.toolInPath,pathsep))
                if exist('cwd','var'), cd(cwd); end
                this.pStatus = this.STATUS('unloaded');
            end

            % GUI and workspace
            if this.showGUI, for h = this.hGUI, set(h,'visible','off'); end; end
            for iw = 1:numel(this.workspace)
                if updateWorkspace, this.workspace(iw).value = evalin('base',this.workspace(iw).name); end
                evalin('base',['clear ' this.workspace(iw).name]);
                if isfield(this.workspace(iw),'attributes') && any(strcmp(this.workspace(iw).attributes,'global'))
                    evalin('base',['clear global ' this.workspace(iw).name]);
                end
            end

            % make sure this class stays in path if not closed
            st = dbstack;
            if ~any(strcmp({st.name},'toolboxClass.close'))
                if ~exist(which([class(this) '.m']),'file'), addpath(this.toolClassPath); end
                if ~exist('toolboxClass.m','file'), addpath(fileparts(mfilename('fullpath'))); end
            end
        end

        %% sub-toolboxes
        function addToolbox(this,tb)
            if isempty(tb.name)
                warning('sub-toolbox MUST have a name');
                return
            end
            if this.hasToolbox(tb.name)
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

            isTb = this.hasToolbox(tbname);
            if ~isTb
                warning('toolbox %s is not a sub-toolbox', tbname);
            else
                this.toolboxes{isTb}.(task);
            end
        end

        function resp = hasToolbox(this,tbname)
            resp = find(cellfun(@(t) strcmp(tbname,t.name), this.toolboxes));
            if isempty(resp), resp = 0; end
        end

        function rmToolbox(this,tbname)
            isTb = this.hasToolbox(tbname);
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
