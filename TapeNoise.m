classdef TapeNoise < handle

    properties (Access = public)
        gain = 0;
    end

    properties (Access = private)
        % Objects
        lpf;
        hpf;

        % Noise
        noise = zeros(512, 2);

        % Update
        count = [512 512];
        MAXCOUNT = 512;

        % Smoothing
        alpha = 0.9999;
        m = 0;
    end

    methods
        % Constructor
        function o = TapeNoise()
            o.lpf = BQLPF;
            o.hpf = BQHPF;
        end
        
        % Generate Noise
        function y = generateNoise(o, c)
            % Smooth Gain Parameter
            o.updateParams;

            % Increase count
            o.count(c) = o.count(c) + 1;

            if o.count(c) > o.MAXCOUNT
                % Create randomized array
                o.noise = rand(512, 2) - .5;
                
                % Filter Noise
                o.noise = o.hpf.process(o.noise);
                o.noise = o.lpf.process(o.noise);
                
                % Reset count
                o.count(c) = 1;
            end
            
            % Scale filtered noise
            y = o.noise(o.count(c), c) * o.m;            
        end

        % Update Parameters
        function updateParams(o)
            o.m = (1 - o.alpha) * o.gain + o.alpha * o.m;
        end
        
        % Prepate To Play
        function setFilters(o, Fs)
            f0 = 80;
            f1 = 5000;
            Q = 0.7071;

            o.hpf.setParams(Fs, f0, Q);
            o.lpf.setParams(Fs, f1, Q);
        end
        
        % Set Parameters
        function setGain (o, gain)
            o.gain = gain;
        end
    end
end