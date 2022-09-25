classdef spmClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end

    methods
        function this = spmClass(path,varargin)
            defaultAddToPath = false;

            argParse = inputParser;
            argParse.addRequired('path',@ischar);
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});

            this = this@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,{});

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
        end

        function load(this)
            addpath(this.toolPath);
            spm_jobman('initcfg');
            [~, r] = spm('Ver');
            this.version = spm('FnBanner', ['v' r]);

            load@toolboxClass(this)
        end
    end
end