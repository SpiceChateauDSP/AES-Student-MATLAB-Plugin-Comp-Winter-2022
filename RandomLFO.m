classdef RandomLFO < handle
    % Random LFO with smoothing
    properties (Access = public)
        depth = 0;
        smooth = 0;
    end
    
    properties (Access = private)
        count = [256 256];
        MAXCOUNT = 256;
        
        p = [0 0];
        smoothP = [0 0];
        
        % Smoothing
        alpha = .999;
        m = [0 0];
    end
    
    methods
        % Generate Random LFO
        function position = lfoPosition(o, c)
            o.updateParams;

            o.count(c) = o.count(c) + 1;
            if o.count(c) > o.MAXCOUNT
                o.count(c) = 1;
                o.p(c) = randn;
            end

            o.smoothP(c) = (1 - o.m(1)) * o.p(c) + o.m(1) * o.smoothP(c);

            position = o.smoothP(c)  * o.m(2);
        end

        function updateParams(o)
            o.m(1) = (1 - o.alpha) * o.smooth + o.alpha * o.m(1);
            o.m(2) = (1 - o.alpha) * o.depth + o.alpha * o.m(2);
        end
        
        % Prepare to Play
        function setRefreshRate(o, refreshRate)
            o.MAXCOUNT = refreshRate;
            o.count = [refreshRate refreshRate];
        end
        
        % Set Parameters
        function setDepth(o, depth)
            o.depth = depth;
        end
        
        function setSmooth(o, smooth)
            o.smooth = smooth;
        end
    end
    
end