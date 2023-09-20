% niworkfows requires Python 3.9
% The integration requires a named conda virtual environment.
%
%   cd /users/abcd1234/tools
%   conda create -n niworkfows python=3.9
%   conda activate niworkfows
%   pip install niworkfows
%
% For full functionality, you need to have reproanalysis set up
%
classdef niwfClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end

    properties (SetAccess = protected)
        condaEnvironment
        scriptDir
    end

    methods
        function this = niwfClass(path,varargin)
            defaultAddToPath = false;

            argParse = inputParser;
            argParse.addRequired('path',@(x) ischar(x) || isstruct(x)); % N.B.: path is not used
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('condaEnvironment','',@ischar);
            argParse.parse(path,varargin{:});

            this = this@toolboxClass(argParse.Results.name,argParse.Results.path,false,{});

            this.condaEnvironment = argParse.Results.condaEnvironment;
            this.scriptDir = fullfile(fileparts(mfilename('fullpath')),'niwf_mods');

            this.updateAfterLoadedFromStruct();
        end

        function val = struct(this)
            val = struct@toolboxClass(this);
            val.condaEnvironment = this.condaEnvironment;
            val.scriptDir = this.scriptDir;
        end

        function updateAfterLoadedFromStruct(this)
            updateAfterLoadedFromStruct@toolboxClass(this);
            if isstruct(this.loadedFromStruct) % load from struct
                this.condaEnvironment = this.loadedFromStruct.condaEnvironment;
                this.scriptDir = this.loadedFromStruct.scriptDir;
                this.loadedFromStruct = false;
            end
        end

        function load(this)
            load@toolboxClass(this)
        end


        function pyCmd = generateCifti(this,rap,fnVol,fnSurf,TR)
            indLH = find(lookFor(fnSurf,'_lh'));
            indRH = find(lookFor(fnSurf,'_rh'));
            if numel(indLH)==1 && numel(indLH)==1 && indLH~=indRH
                fnSurf = fnSurf([indLH indRH]);
                fprintf('Hemispheric order detected -> [L R]: %s %s',fnSurf{:});
            else
                warning('Hemispheric order of surface data cannot be detected -> assume OK');
            end

            pyCmd = sprintf('python %s/generateCifti_fmri.py --vol %s --surf %s %s --tr %1.3f',...
                            this.scriptDir, fnVol, fnSurf{:}, TR);

            if isstruct(rap) % reproa assumed
                logging.info('reproa assumed -> running niworkflows.generateCifti...')
                runPyCommand(rap,pyCmd,this.condaEnvironment);
            else
                warning('reproa is not detected -> you can use the returned command in the conda environment "%s"',this.condaEnvironment);
            end
        end
    end
end
