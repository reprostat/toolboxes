classdef fieldtripClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end

    methods
        function this = fieldtripClass(path,varargin)
            defaultAddToPath = false;

            argParse = inputParser;
            argParse.addRequired('path',@(x) ischar(x) || isstruct(x));
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});

            this = this@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,{});

            this.updateAfterLoadedFromStruct();
        end

        function load(this)
            addpath(this.toolPath);
            ft_defaults
            spmVer = '';
            try spmVer = spm('ver'); catch, warning('SPM is not detected'); end
            if ~isempty(spmVer)
                global ft_default
                ft_default.trackcallinfo = 'no';
                ft_default.showcallinfo = 'no';
                if ~isempty(spmVer), ft_default.spmversion = lower(spmVer); end
            end

            load@toolboxClass(this)
        end

        function close(this)
            global ft_default
            ft_default = [];
            clear ft_default;
            close@toolboxClass(this)
        end

        function addExternal(this,toolbox)
            if this.pStatus < this.CONST_STATUS.loaded
                warning('Fieldtrip is not loaded')
                return
            end
            tbpath = '';
            lastwarn('')
            ft_hastoolbox(toolbox,1);
            if ~isempty(strfind(lastwarn,toolbox))
                tbpath = strsplit(lastwarn); tbpath = tbpath{2};
            end
            p = strsplit(path,pathsep);
            this.toolInPath = vertcat(this.toolInPath, p(cellfun(@(x) ~isempty(strfind(x,tbpath)), p)));

            if ~isempty(strfind(toolbox,'spm'))
                spmVer = spm('ver');
                global ft_default
                ft_default.trackcallinfo = 'no';
                ft_default.showcallinfo = 'no';
                if ~isempty(spmVer), ft_default.spmversion = lower(spmVer); end
                fprintf('info:SPM version %s is set\n',spmVer);
            end
        end

        function rmExternal(this,toolbox)
            indtbp = cellfun(@(x) ~isempty(strfind(x,toolbox)), this.toolInPath);
            p = this.toolInPath(indtbp);
            rmpath(sprintf(['%s' pathsep],p{:}))
            this.toolInPath(indtbp) = [];
        end
    end
end
