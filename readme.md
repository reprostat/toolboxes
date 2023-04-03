# Toolboxes

The toolbox is a framework for interacting with tools. They ensure tight integration and transparent control over their operation. The main concept is that a tool SHOULD be present in only where and when it is needed to avoid ambiguity due to unintended "shadowing" caused by similar or same function names. This is an issue primarily for MATLAB/Octave-based tools; therefore, the toolbox framework also primarily concerns these tools.

## Components of the framework

To integrate an external tool for a particular module, a developer MUST
1. Decide for a __toolbox name__
2. Write an __interface object__
3. Ensure that the corresponing __module__ checks, loads, and unloads the tool.

Also, if a user wants to use this module, they MUST
1. manually download the external tool 
2. Add a corresponding toolbox entry to the (site-specific) __parameterset__

### Toolbox name

The toolbox name is a unique descriptive identitfier for the tool. It can be any combination of letters and numbers, but it MUST
- start with a letter
- be lower cased
  
This toolbox name connects the several components of the integration, e.g., the name of the __interface object__ has a form of `<toolbox name>Class`

### Interface object

The interface is an object derived from the [toolboxClass](toolboxClass.m)

The minimum interface MUST 
- have name of `<toolbox name>Class`
- be a subclass of `toolboxClass`
- contain a protected property `hGUI` to store handles to GUI even if the toolbox has none
- contain an initialisation method parsing the arguments and setting argument defaults
- contain a `load` method adding the requires folders to the MATLAB/Octave path. This `load` methods overrides and calls `toolboxClass.load`.

[fwsClass](fwsClass.m) is a good example for any tool only requires to be added to the MATLAB/Octave path 

(CAVE: This is a demonstration of the `toolbox` interface only and does not imply anything on the compatibility of Fusion-Watershed with MATLAB and Octave):

```matlab
% toolbox interface for Fusion-Watershed (Computational, Cognitive and Clinical Neuroimaging Laboratory, ICL, London, UK)
classdef fwsClass < toolboxClass % fwsClass is a subclass of toolboxClass 
    properties (Access = protected)
        hGUI = [] % protected compuslory store for GUI handles
    end
    
    methods
        function obj = fwsClass(path,varargin)
            defaultAddToPath = false; % default for doAddToPath, typically true only for SPM because its function are used throughout aa
            
            argParse = inputParser;
            argParse.addRequired('path',@ischar);
            argParse.addParameter('name','',@ischar);
            argParse.addParameter('doAddToPath',defaultAddToPath,@(x) islogical(x) || isnumeric(x));
            argParse.parse(path,varargin{:});
            
            % calling overriden method with preset arguments
            %     name                      - Name of the tool corresponding to the name of the object (i.e. 'fws' in this case)
            %     path                      - Path to the tool's main folder
            %     doAddToPath               - Add tool to the path upon initialisation (not the same as loading)
            %     workspaceVariableNames    - List of variables to be stored, typically an empty cell array for no variables
            obj = obj@toolboxClass(argParse.Results.name,argParse.Results.path,argParse.Results.doAddToPath,{}); 
        end
        
        function load(obj)
            addpath(obj.toolPath); % adding tool folder to the MATLAB path
            
            load@toolboxClass(obj) % calling overriden method
        end
    end
end
```

### Usage

Tool can be managed via the interface. The minimum management includes
- loading the the toolbox before any related operation
```matlab        
        TDT.load;
```

- unloading the toolbox after any related operation
```matlab
        TDT.unload;
```

## Optional extras
