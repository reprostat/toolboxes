% Also, AROMA requires python2.7 and pip.
%
% The easiest way to install is prolly:
%
%   % cd /users/abcd1234/tools
%   % git clone https://github.com/maartenmennes/ICA-AROMA.git
%   % python2.7 -m pip install -r ICA-AROMA/requirements.txt
%
%   (assuming that the repo link is still valid)
%
% TODO: add python virtual environment for shared systems without admin access
%
classdef aromaClass < toolboxClass
    properties (Access = protected)
        hGUI = []% GUI handles
    end

    properties (SetAccess = protected)
        condaEnvironment
    end

    methods
        function this = aromaClass(path,varargin)
            defaultAddToPath = false;

            argParse = inputParser;
            argParse.addRequired('path',@(x) ischar(x) || isstruct(x));
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.addParameter('condaEnvironment','',@ischar);
            argParse.parse(path,varargin{:});

            this = this@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,{});

            this.condaEnvironment = argParse.Results.condaEnvironment;

            this.updateAfterLoadedFromStruct();
        end

        function val = struct(this)
            val = struct@toolboxClass(this);
            val.condaEnvironment = this.condaEnvironment;
        end

        function updateAfterLoadedFromStruct(this)
            updateAfterLoadedFromStruct@toolboxClass(this);
            if isstruct(this.loadedFromStruct) % load from struct
                this.condaEnvironment = this.loadedFromStruct.condaEnvironment;
                this.loadedFromStruct = false;
            end
        end

        function load(this)
            load@toolboxClass(this)
        end
    end
end
