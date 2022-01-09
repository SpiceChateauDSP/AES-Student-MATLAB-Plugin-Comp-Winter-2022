classdef ClippingDiodes < handle
    
    properties (Access = private)
        % Germanium Diode Qualities
        Is = 10^-6;
        eta = 1.68;
        Vt = 0.026;
        
        % Components
        R = 1000;
    end
    
    methods
        % Constructor
        function o = ClippingDiodes()
        end
        
        % DSP
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);
            
            for c = 1 : C
                for n = 1 : N
                    out(n, c) = processSample(o, in(n, c));
                end
            end
        end
        
        function y = processSample (o, x)
            Vout = 0;
            
            num = 2 * o.Is * sinh(Vout/(o.eta * o.Vt)) + Vout/o.R - x/o.R;
            
            count = 1;
            
            while (abs(num) > .00000001 && count < 20)
                den = (2 * o.Is) / (o.eta * o.Vt) * cosh(Vout/(o.eta * o.Vt)) + 1/o.R;
                
                Vout = Vout - num / den;
                
                num = 2 * o.Is * sinh(Vout/(o.eta * o.Vt)) + Vout/o.R - x/o.R;
                
                count = count + 1;
            end
            
            y = Vout;
        end
    end
end