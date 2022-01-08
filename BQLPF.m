classdef BQLPF < handle
    
    properties
        % Intermediate Variables
        w0 = 0; % Angular Freq. (Radians/sample) 
        alpha = 0; % Filter Width
        
        % Coefficients
        a0 = 1;
        a1 = 0;
        a2 = 0;
        b0 = 1;
        b1 = 0;
        b2 = 0;
        
        % Memory
        w1 = [0 0];
        w2 = [0 0];
        
        % Utilities
        pi2 = 2 * pi;
    end
    
    methods
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);
            
            for c = 1 : C
                for n = 1 : N
                    out(n, c) = processSample(o, in(n, c), c);
                end
            end
        end
        
        function y = processSample(o, x, c)
            w = x + (-o.a1 / o.a0) * o.w1(c) + (-o.a2 / o.a0) * o.w2(c);  
            y = (o.b0 / o.a0) * w + (o.b1 / o.a0) * o.w1(c) + (o.b2 / o.a0) * o.w2(c);
            o.w2(c) = o.w1(c);
            o.w1(c) = w;
        end
        
        function setParams(o, Fs, f0, Q)
            o.w0 = o.pi2 * f0 / Fs; % Angular Freq. (Radians/sample) 
            o.alpha = sin(o.w0) / (2 * Q); % Filter Width
            o.updateCoefficients(o.w0, o.alpha);
        end
        
        function updateCoefficients(o, w0, alpha)
                o.b0 =  (1 - cos(w0)) / 2;
                o.b1 =   1 - cos(w0);
                o.b2 =  (1 - cos(w0)) / 2;
                o.a0 =   1 + alpha;
                o.a1 =  -2 * cos(w0);
                o.a2 =   1 - alpha;
        end
    end
end