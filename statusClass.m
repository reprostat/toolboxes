classdef statusClass < handle
    properties (Dependent)
        status
    end

    properties (Abstract, Access = protected, Constant = true)
        STATUS
    end

    properties (Access = protected)
        pStatus = -1
    end

    methods
        function resp = get.status(this)
            keys = this.STATUS.keys;
            resp = keys{cell2mat(this.STATUS.values) == this.pStatus};
        end
    end
end
