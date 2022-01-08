classdef ChorusEffect < handle
    
    properties (Access = private)
        % Objects
        noise;
        comp;
        randomModDelay;
        randomModDelay2;
        diodes;
        hpf;

        % Compressor Parameters
        CompOn = false;
        
        % Delay Parameters
        delaySamples = 0;
        delaySamples2 = 0;
        feedback = 0;
        Tri = false;
        
        % Mod/Random Parameteres
        depthN = 0;
        randomN = 0;

        % Saturation Parameters
        SatOn = false;
        
        % Effect Parameters
        inGain = 1;
        outGain = 1;
        mix = 0;
        Bypass = false;
        
        % Utility
        Fs = 48000;

        % Envelope
        envP = 0;
        
        % Memory
        m = [0 0];

        % Smoothing
        alpha = 0.9999;
        p = [0 0 0 0];
    end
    
    methods
        function o = ChorusEffect()
            % Noise
            o.noise = TapeNoise;

            % BiCompressor
            o.comp = Compander;

            % Delay
            o.randomModDelay = RandomModDelay(false);
            o.randomModDelay2 = RandomModDelay(true);

            % Saturation
            o.diodes = ClippingDiodes;

            % Filtering
            o.hpf = BQHPF;
        end
        
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
            % Smooth Params
            o.updateParams;

            % Input Gain
            gainX = x * o.p(1);

            % Noise
            hiss = o.noise.generateNoise(c);
            hissX = hiss + gainX;

            % Feedback
            fb = hissX + o.m(c) * o.p(2);

            % Modulation
            wet = o.randomModDelay.processSampleCubic (fb, c);
            
            if o.Tri
                fb2 = hissX + o.m(c) * o.p(2) * 0.20;
                delay2 = o.randomModDelay2.processSampleCubic (fb2, c);

                wet = 0.75 * (wet + delay2);
            end
            
            if o.SatOn
                % Saturation
                sat = o.diodes.processSample(wet);

                wet = o.hpf.processSample(sat, c);
            end

            % Update Memory
            o.m(c) = wet;

            % Compander
            if o.CompOn
                wet = o.comp.processSample(wet, c);
            end

            % Mix
            mixed = (1 - o.p(3)) * x + o.p(3) * wet;

            if o.Bypass
                y = x;
            else
                y = mixed * o.p(4);
            end
        end

        % Smooth Params
        function updateParams(o)
            % Update Input Gain
            o.p(1) = (1 - o.alpha) * o.inGain + o.alpha * o.p(1);

            % Update Feedbcak Gain
            o.p(2) = (1 - o.alpha) * o.feedback + o.alpha * o.p(2);

            % Update Mix Amount
            o.p(3) = (1 - o.alpha) * o.mix + o.alpha * o.p(3);

            % Update Output Gain
            o.p(4) = (1 - o.alpha) * o.outGain + o.alpha * o.p(4);
        end
        
        % Prepare To Play
        function setFs(o, Fs)
            o.Fs = Fs;

            o.noise.setFilters(Fs);

            o.comp.setFs(Fs);

            o.randomModDelay.setFs(Fs);
            o.randomModDelay2.setFs(Fs);
            o.setModShape;

            o.hpf.setParams(Fs, 40, 0.7071);
        end
        
        % Delay Parameters
        function setDelayMs(o, delayMs)
            % Delay Line 1
            o.randomModDelay.setDelayMs(delayMs);
            
            o.delaySamples = (delayMs / 1000) * o.Fs;
            modDepth = (o.delaySamples * 2) * o.depthN;
            randomAmount = (o.delaySamples * .25) * o.randomN;
            
            o.randomModDelay.setModDepth(modDepth);        
            o.randomModDelay.setRandomDepth(randomAmount);
            
            % Delay Line 2
            delayMs = 4 * ceil(delayMs / 7);
            o.randomModDelay2.setDelayMs(delayMs);
            
            o.delaySamples2 = (delayMs / 1000) * o.Fs;
            modDepth = (o.delaySamples2 * 2) * o.depthN;
            randomAmount = (o.delaySamples2 * .25) * o.randomN;
            
            o.randomModDelay2.setModDepth(modDepth);        
            o.randomModDelay2.setRandomDepth(randomAmount);    
        end

        function setTri(o, Tri)
            o.Tri = Tri;
        end

        function setFeedback (o, feedback)
            o.feedback = feedback * 0.95;
        end
        
        % Modulation Parameters
        function setModDepth(o, depthN)
            o.depthN = depthN;

            modDepth = (o.delaySamples * 2) * o.depthN;
            o.randomModDelay.setModDepth(modDepth);

            modDepth = (o.delaySamples2 * 2) * o.depthN;
            o.randomModDelay2.setModDepth(modDepth);
        end
        
        function setModRate(o, modRate)
            o.randomModDelay.setModRate(modRate);
            o.randomModDelay2.setModRate(modRate * 0.73);
        end
        
        function setModShape(o)
            o.randomModDelay.setModShape(0.5);
            o.randomModDelay2.setModShape(0.5);
        end

        function setModSt(o, ModSt)
            o.randomModDelay.setModSt(ModSt);
            o.randomModDelay2.setModSt(ModSt);
        end
        
        % Random Parameters
        function setRandomSmooth(o, smoothN)
            randomSmooth = (smoothN * .00029) + 0.9997;
            o.randomModDelay.setRandomSmoothing(randomSmooth);
            o.randomModDelay2.setRandomSmoothing(randomSmooth);
        end
        
        function setRandom(o, randomN)
            o.randomN = randomN;
            
            randomAmount = (o.delaySamples * .25) * o.randomN;
            o.randomModDelay.setRandomDepth(randomAmount);

            randomAmount = (o.delaySamples2 * .25) * o.randomN;
            o.randomModDelay2.setRandomDepth(randomAmount);
        end
        
        % Compressor
        function setCompOn(o, CompOn)
            o.CompOn = CompOn;
        end
        
        % Noise Parameters
        function setHiss(o, hiss)
            o.noise.setGain(hiss);
        end

        % Saturation Parameters
        function setSatOn(o, SatOn)
            o.SatOn = SatOn;
        end

        % Effect Parameters
        function setInGain(o, inGain)
            o.inGain = inGain;
        end

        function setOutGain(o, outGain)
            o.outGain = outGain;
        end

        function setMix(o, mix)
            o.mix = mix;
        end

        function setBypass(o, Bypass)
            o.Bypass = Bypass;
        end
    end
end