classdef spmClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end

    methods
        function this = spmClass(path,varargin)
            defaultAddToPath = false;

            argParse = inputParser;
            argParse.addRequired('path',@(x) ischar(x) || isstruct(x));
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});


            if ischar(path)
                initStruct = argParse.Results;
            else % load from struct
                initStruct = path;
            end

            vars = {...
                '{"name": "defaults", "attributes": ["global"]}'...
                };

            this = this@toolboxClass(initStruct.name,initStruct.path,initStruct.doAddToPath,vars);

            this.addToolbox(fieldtripClass(fullfile(this.toolPath,'external','fieldtrip'),'name','fieldtrip'));

            this.collections(1).name = 'meeg';
            this.collections(1).path = {...
                    'external/bemcp'...
                    'external/ctf'...
                    'external/eeprobe'...
                    'external/mne'...
                    'external/yokogawa_meg_reader'...
                    'toolbox/dcm_meeg'...
                    'toolbox/spectral'...
                    'toolbox/Neural_Models'...
                    'toolbox/MEEGtools'...
                    };
            this.collections(1).toolbox = {'fieldtrip'};

            if isfield(initStruct,'workspace') % load from struct
                this.toolInPath = initStruct.toolInPath;
                this.workspace = initStruct.workspace;
                if strcmp(initStruct.status,'loaded') && (this.pStatus < this.STATUS('loaded'))
                    this.reload(true);
                end
            end

        end

        function val = struct(this)
            val = struct@toolboxClass(this);
            val.workspace = this.workspace;
        end

        function load(this)
            if this.pStatus < this.STATUS('loaded')
                addpath(this.toolPath);
                spm_jobman('initcfg');
                [~, r] = spm('Ver');
                this.version = spm('FnBanner', ['v' r]);
            end
            load@toolboxClass(this);
        end

        function unload(this,varargin)
            global defaults
            assignin('base', 'defaults', defaults);

            unload@toolboxClass(this,varargin{:});
        end
    end
end

%!test
%! SPM = spmClass('D:\Programs\spm12','doAddToPath',true);
%! SPM.load();
%! global defaults
%! defaults.extra = 'terefere';
%! SPM.unload(true);
%! SPM.reload(true);
%! assert(defaults.extra, 'terefere')
%! sSPM = struct(SPM);
%! save -mat sSPM.mat sSPM
%! clear sSPM
%! SPM.close();
%! load sSPM.mat sSPM
%! delete sSPM.mat
%! constr = str2func(sSPM.className);
%! SPM = constr(sSPM);
%! assert(defaults.extra, 'terefere')
