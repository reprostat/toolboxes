classdef statusClass < handle
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
    end

    methods
        function resp = get.status(this)
            resp = this.STATUS.keys{cell2mat(this.STATUS.values) == this.pStatus};
        end
    end
end
