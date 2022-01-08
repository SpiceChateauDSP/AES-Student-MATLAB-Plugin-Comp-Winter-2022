classdef Compander < handle
    properties (Access = public)
        Fs = 48000;
    end

    properties (Access = private)
        % Compressor Parameters
        attack = 0.050;
        alphaA = 0;
        release = 0.250;
        alphaR = 0;

        % Static Characteristics
        threshhold = -12;
        r = 4;
        w = 24;
        t = -12 - 24/2; % threshhold - w/2

        % Feedback
        fb = [0 0];

        % Memory
        m = [-144 -144];
    end

    methods
        % DSP
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);

            for c = 1 : C
                for n = 1 : N
                    out(n, c) = o.processSample(in(n, c), c);
                end
            end
        end

        function y = processSample(o, x ,c)
            % Convert to dB
            xDB = 20 * log10(abs(x));

            if xDB < -144
                xDB = -144;
            end

            % Determine Decibel Gain Change
            g = o.smoothGain(xDB, c);

            % Determine Linear Gain Change
            linChange = 10^(g/20);

            % Apply Linear Gain Change
            y = x * linChange;
        end

        function g = smoothGain(o, xDB, c)
            if xDB > (o.t)
                if xDB > (o.threshhold + o.w/2)
                    sidechain = o.threshhold + (xDB - o.threshhold) / o.r;
                else
                    sidechain = xDB + ((1 / o.r - 1) * (xDB - o.threshhold + o.w/2)^2) / (2 * o.w);
                end

                gainChange = sidechain - xDB;

                if gainChange < o.m(c)
                    g = ((1 - o.alphaA) * gainChange) + (o.alphaA * o.m(c));
                else
                    g = ((1 - o.alphaR) * gainChange) + (o.alphaR * o.m(c));
                end
            else
                sidechain = o.t + (xDB - o.t) * o.r/2;
                gainChange = sidechain - xDB;

                if gainChange > o.m(c)
                    g = ((1 - o.alphaA) * gainChange) + (o.alphaA * o.m(c));
                else
                    g = ((1 - o.alphaR) * gainChange) + (o.alphaR * o.m(c));
                end
            end

            o.m(c) = g;
        end
        
        % Prepare To Play
        function setFs(o, Fs)
            o.Fs = Fs;

            o.alphaA = exp(-log(9)/(Fs * o.attack));
            o.alphaR = exp(-log(9)/(Fs * o.release));
        end
    end
end