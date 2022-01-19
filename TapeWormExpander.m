classdef TapeWormExpander < handle
    % Basic Digital Expander
    properties (Access = public)
        % Attack and Release
        attack = 0.025;
        release = 0.050;
    end

    properties (Access = private)
        % Static Characteristics
        ratio = 4;
        thresh = -36;
        
        % Smoothing
        attackSmooth = 0;
        releaseSmooth = 0;
        gainM = [-144 -144];
    end

    methods
        % DSP - Process Block
        function out= process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);

            for c = 1 : C
                for n = 1 : N
                    out(n, c) = o.processSample(in(n, c), c);
                end
            end
        end

        % DSP - Process Sample
        function y = processSample(o, x, c)
            % Convert input into dB magnitude
            dBx = o.convertInput(x);

            % Determine compression amount
            gainChange = o.staticChar(dBx);

            % Smooth Gain Change
            gainSmooth = o.smooth(gainChange, c);

            % Convert to Linear Scalar
            linX = 10^(gainSmooth/20);

            % Apply Linear Scalar to Input
            y = linX * x;
        end
        
        % Convert input signal into dB Magnitude
        function dBx = convertInput(o, x)
            dBx = 20 * log10(abs(x));

            if dBx < -144
                dBx = -144;
            end
        end

        % Determine Compression Amount
        function gainChange = staticChar(o, dBx)
            if dBx < o.thresh
                expanded = o.thresh + (dBx - o.thresh) * o.ratio;
            else
                expanded = dBx;
            end
            
            gainChange = expanded - dBx;
        end

        % Smooth Gain Change
        function gainSmooth = smooth(o, gainChange, c)
            if gainChange > o.gainM(c)
                gainSmooth = ((1 - o.attackSmooth) * gainChange) + o.attackSmooth...
                    * o.gainM(c);
            else
                gainSmooth = ((1 - o.releaseSmooth) * gainChange) + o.releaseSmooth...
                     * o.gainM(c);
            end

            o.gainM(c) = gainSmooth;
        end

        % Prepare to Play
        function setFs(o, Fs)
            o.attackSmooth = exp(-log(9)/(Fs * o.attack));
            o.releaseSmooth = exp(-log(9)/(Fs * o.release));
        end
    end
end