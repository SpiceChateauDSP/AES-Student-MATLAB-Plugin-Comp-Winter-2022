classdef RandomModDelay < handle
    % Modulated Delay with additional Random LFO
    properties (Access = private)
        % Objects
        lfo;
        randomLFO;
        
        % Parameters
        Fs = 48000;
        delayMs = 0;
        delaySamples = 0;
        modDepth = 0;
        randomDepth = 0;
        
        % Buffer
        M = 96000;
        buffer = zeros(96000, 2);
        w = [96000 96000];
    end
    
    methods
        % Constructor
        function o = RandomModDelay(Inv)
            o.lfo = LFO(Inv);
            o.randomLFO = RandomLFO;
        end
        
        % DSP
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);
            
            for c = 1 : C
                for n = 1 : N
                    out(n, c) = o.processSampleCubic(in(n, c), c);
                end
            end
        end
        
        function y = processSampleCubic(o, x, c)
            % Add input to buffer at write pointer
            o.buffer(o.w(c), c) = x;
            
            fracDelay = o.updateDelay(c);
            
            [intDelay, frac] = o.delayModulation(fracDelay);
            
            [r1, r2, r3, r4] = o.findReadPointersCubic(intDelay, c);
            
            [a0, a1, a2, a3] = o.findCoefficients(r1, r2, r3, r4, c);
            
            % Output
            y = a0 * (frac^3) + a1 * (frac^2) + a2 * frac + a3;
            
            o.advanceWritePointer(c);
        end
        
        function y = processSampleLinear(o, x, c)
            o.buffer(o.w(c), c) = x;
            
            fracDelay = o.updateDelay(c);
            
            [intDelay, frac] = o.delayModulation(fracDelay);
            
            [r1, r2] = o.findReadPointersLinear(intDelay);
            
            y = (1 - frac) * o.buffer(r1, c) + frac * o.buffer(r2, c);
            
            o.advanceWritePointer(c);
        end
        
        function fracDelay = updateDelay(o, c)
            if o.modDepth > 0
                fracDelay = o.lfo.lfoPosition(c);
            else
                fracDelay = o.delaySamples;
            end
            
            if o.randomDepth > 0
                fracDelay = fracDelay + o.randomLFO.lfoPosition(c);
            end

            if fracDelay < 1
                fracDelay = 1;
            end
        end
        
        function [intDelay, frac] = delayModulation(o, fracDelay)
            intDelay = floor(fracDelay);
            frac = fracDelay - intDelay;
        end
        
        function [r1, r2, r3, r4] = findReadPointersCubic(o, intDelay, c)
            % Find Read Pointers
            r1 = o.w(c) - intDelay + 1;
            if r1 < 1
                r1 = r1 + o.M;
            elseif r1 > o.M
                r1 = r1 - o.M;
            end
            
            r2 = o.w(c) - intDelay;
            if r2 < 1
                r2 = r2 + o.M;
            end
            
            r3 = o.w(c) - intDelay - 1;
            if r3 < 1
                r3 = r3 + o.M;
            end
            
            r4 = o.w(c) - intDelay - 2;
            if r4 < 1
                r4 = r4 + o.M;
            end
        end
        
        function [r1, r2] = findReadPointersLinear (o, intDelay)
            r1 = o.w(c) - intDelay;
            if (r1 < 1)
                r1 = r1 + o.M;
            end
            
            r2 = r1 - 1;
            if (r2 < 1)
                r2 = r2 + o.M;
            end
        end
        
        function [a0, a1, a2, a3] = findCoefficients(o, r1, r2, r3, r4, c)
            a0 = o.buffer(r4, c) - o.buffer(r3, c) - o.buffer(r1, c) + o.buffer(r2, c);
            
            a1 = o.buffer(r1, c) - o.buffer(r2, c) - a0;
            
            a2 = o.buffer(r3, c) - o.buffer(r1, c);
            
            a3 = o.buffer(r2, c);
        end
        
        function advanceWritePointer(o, c)
            if o.w(c) < o.M
                o.w(c) = o.w(c) + 1;
            else
                o.w(c) = 1;
            end
        end
        
        % Prepare To Play
        function setFs(o, Fs)
            o.lfo.setFs(Fs);
            
            o.delaySamples = (o.delayMs / 1000) * o.Fs;
            
            o.lfo.setRefreshRate(Fs / 50);
            o.randomLFO.setRefreshRate(Fs / 25);
        end
        
        % Delay Parameters
        function setDelayMs(o, delayMs)
            o.delayMs = delayMs;
            o.delaySamples = (delayMs / 1000) * o.Fs;
            if o.modDepth/2 > o.delaySamples
                o.modDepth = 2 * o.delaySamples;
                o.lfo.setDepth(o.modDepth);
                o.lfo.setDc(o.delaySamples);
            else
                o.lfo.setDc (o.delaySamples);
            end
        end
        
        % Mod Parameters
        function setModDepth(o, modDepth)
            o.modDepth = modDepth;
            if o.modDepth/2 > o.delaySamples
                o.modDepth = 2 * o.delaySamples;
                o.lfo.setDepth(o.modDepth);
            else
                o.lfo.setDepth(modDepth);
            end
        end
        
        function setModRate(o, modRate)
            o.lfo.setRate(modRate);
        end
        
        function setModShape(o, modShape)
            o.lfo.setShape(modShape);
        end

        function setModSt(o, ModSt)
            o.lfo.setStereo(ModSt);
        end
        
        % Random Parameters
        function setRandomSmoothing(o, randomSmooth)
            o.randomLFO.setSmooth(randomSmooth);
        end
        
        function setRandomDepth(o, randomDepth)
            o.randomDepth = randomDepth;
            o.randomLFO.setDepth(randomDepth);
        end
    end
end