classdef RCDiodes < handle
    % Analog Model of a pair of 'germanium' diodes, with simple RC filter
    properties (Access = private)
        % Germanium Diode Qualities
        Is = 10^-16;
        eta = 1.2;
        Vt = 0.026;
        
        % Components
            % Capacitor
            C1 = 4e-8;

            % Resistor
            R1 = 0;
            R2 = 315;
        
        % Capicitor Memory
        x1 = [0 0];

        % Newton Raphson Memory
        Vout = [0 0];
    end
    
    methods
        % Constructor
        function o = RCDiodes()
        end
        
        % DSP
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);
            
            for c = 1 : C
                for n = 1 : N
                    out(n, c) = processSample(o, in(n, c), c);
                end
            end
        end
        
        function y = processSample (o, x, c)
            num = o.Vout(c) * (1/o.R1 + 1/o.R2) - x/o.R2 - o.x1(c) + 2 * o.Is * sinh(o.Vout(c)/(o.eta * o.Vt));

            % Newton Raphson Solver
            count = 1;
            if (abs(num) > .0000000001 && count < 10)
                den = (1/o.R1 + 1/o.R2) + 2 * o.Is / (o.eta * o.Vt) * cosh(o.Vout(c)/(o.eta * o.Vt));
                o.Vout(c) = o.Vout(c) - num/den;

                num = o.Vout(c) * (1/o.R1 + 1/o.R2) - x/o.R2 - o.x1(c) + 2 * o.Is * sinh(o.Vout(c)/(o.eta * o.Vt));

                count = count + 1;
            end

            y = o.Vout(c);

            % Update Capacitor Memory
            o.x1(c) = (2/o.R1) * o.Vout(c) - o.x1(c);
        end

        % Prepare to Play
        function setFs(o, Fs)
            Ts = 1/Fs;
            o.R1 = Ts / (2 * o.C1);
        end

        % Diode Parameters
        function setParams(o, Is, eta, Vt)
            o.Is = Is;
            o.eta = eta;
            o.Vt = Vt;
        end
    end
end