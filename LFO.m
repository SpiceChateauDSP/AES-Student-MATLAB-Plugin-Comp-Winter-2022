classdef LFO < handle
    % Sin/Triangle LFO
    properties (Access = public)
        depth = 0;
        rate = 0.1;
        dc = 0;
        shape = 0.75;
        Stereo = false;
        Inv = false;
    end
    
    properties (Access = private)
        % LFO Position
        p = [0 0];
        smoothP = [0 0];
        smooth = 0.9995;

        angle = [0 0];
        phi = 0;
        
        % Refresh Rate
        count = [64 64];
        MAXCOUNT = 64;
        
        % Utility
        Ts = 1 / 48000;
        pi2 = 2 * pi;
        piD2 = pi / 2;
        piAndHalf = (3 * pi) / 2;

        % Smoothing
        m = 0;
        alpha = 0.9995;
    end
    
    methods
        % Constructor
        function o = LFO(Inv)
            o.Inv = Inv;
        end

        function position = lfoPosition(o, c)
            % Smooth Parameters
            o.updateParams;

            o.count(c) = o.count(c) + 1;
            if o.count(c) > o.MAXCOUNT
                o.count(c) = 1;

                if o.Inv
                    if o.Stereo
                        p1 = o.m * sin(o.angle(c) + (pi + c * o.piD2)) + o.dc;
                        p2 = o.m * sawtooth(o.angle(c) + (pi + c * o.piD2), .5) + o.dc;
                    else
                        p1 = o.m * sin(o.angle(c)+ pi) + o.dc;
                        p2 = o.m * sawtooth(o.angle(c) + o.piAndHalf, .5) + o.dc;
                    end
                else
                    if o.Stereo
                        p1 = o.m * sin(o.angle(c) + (c * o.piD2)) + o.dc;
                        p2 = o.m * sawtooth(o.angle(c) + (c * o.piD2), .5) + o.dc;
                    else
                        p1 = o.m * sin(o.angle(c)) + o.dc;
                        p2 = o.m * sawtooth(o.angle(c) + o.piD2, .5) + o.dc;
                    end
                end

                o.p(c) = o.shape * p2 + (1 - o.shape) * p1;

                % Update angle
                o.angle(c) = o.angle(c) + o.phi;
                if (o.angle(c) > o.pi2)
                    o.angle(c) = o.angle(c) - o.pi2;
                end
            end
            
            o.smoothP(c) = (1 - o.smooth) * o.p(c) + o.smooth * o.smoothP(c);
            position = o.smoothP(c);
        end

        % Smooth Parameters
        function updateParams(o)
            % Update Depth
            o.m = (1 - o.alpha) * o.depth + o.alpha * o.m;
        end
        
        % Prepare To Play
        function setFs(o, Fs)
            o.Ts = 1 / Fs;
        end
        
        % Set Parameters
        function setDepth(o, depth)
            o.depth = depth / 2;
        end
        
        function setRate(o, rate)
            o.rate = rate;
            o.phi = rate * o.Ts * o.pi2 * o.MAXCOUNT;
        end
        
        function setDc(o, dc)
            o.dc = dc;
        end
        
        function setShape(o, shape)
            o.shape = shape;
        end
        
        function setRefreshRate(o, refreshRate)
            o.MAXCOUNT = refreshRate;
            o.count = [o.MAXCOUNT o.MAXCOUNT];
            o.phi = o.rate * o.Ts * o.pi2 * o.MAXCOUNT;
        end
        
        function setStereo(o, Stereo)
            o.Stereo = Stereo;
        end
    end
    
end