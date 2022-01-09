classdef Compander < handle
    properties (Access = public)
        Fs = 48000;
    end

    properties (Access = private)
        % Compressor Parameters
        Compress = true;

        attack = 0.01;
        release = 0.250;
        alphaA = 0;
        alphaR = 0;

        % Compression Static Characteristics
        threshholdC = -18;
        rC = 4;
        wC = 24;

        % Expansion Parameters
        expansion = .010;
        alphaE = 0;
        
        % Expansion Static Characteristics
        threshholdE = -36;

        % Feedback
        fb = [0 0];

        % Memory
        mC = [0 0]
        mE = [-144 -144];
    end

    methods
        % Constructor
        function o = Compander(Compress)
            o.Compress = Compress;
        end

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
            if o.Compress
                g = o.compress(xDB, c);
            else
                g = o.expand(xDB, c);
            end

            % Determine Linear Gain Change
            linChange = 10^(g/20);

            % Apply Linear Gain Change
            y = x * linChange;
        end
        
        % Compression
        function g = compress(o, xDB, c)
            if xDB > (o.threshholdC + o.wC/2)
                sidechain = o.threshholdC + (xDB - o.threshholdC) / o.rC;
            elseif xDB > (o.threshholdC - o.wC/2)
                sidechain = xDB + ((1 / o.rC - 1) * (xDB - o.threshholdC + o.wC/2)^2) / (2 * o.wC);
            else
                sidechain = xDB;
            end

            gainChange = sidechain - xDB;

            if gainChange < o.mC(c)
                g = ((1 - o.alphaA) * gainChange) + (o.alphaA * o.mC(c));
            else
                g = ((1 - o.alphaR) * gainChange) + (o.alphaR * o.mC(c));
            end
            
            o.mC(c) = g;
        end

        % Expansion
        function g = expand(o, xDB, c)
            if xDB > (o.threshholdE)
                sidechain = xDB;
            else
                sidechain = o.threshholdE + (xDB - o.threshholdE) * 1.5;
            end

            gainChange = sidechain - xDB;

            g = ((1 - o.alphaE) * gainChange) + (o.alphaE * o.mE(c));

            o.mE(c) = g;
        end

        % Prepare To Play
        function setFs(o, Fs)
            o.Fs = Fs;

            o.alphaA = exp(-log(9)/(Fs * o.attack));
            o.alphaR= exp(-log(9)/(Fs * o.release));
            o.alphaE= exp(-log(9)/(Fs * o.expansion));
        end
    end
end