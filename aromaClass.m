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
    
    methods
        function obj = aromaClass(path,varargin)
            defaultAddToPath = false;
            
            argParse = inputParser;
            argParse.addRequired('path',@ischar);
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});
            
            obj = obj@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,{});
        end
        
        function load(obj)
            load@toolboxClass(obj)

        end
    end
end