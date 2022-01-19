classdef ChorusEffect < handle
    
    properties (Access = private)
        % Objects
        noise;
        comp;
        exp;
        randomModDelay;
        randomModDelay2;
        randomModDelay3;
        saturation;
        saturation2;
        hpf;

        % Compressor Parameters
        CompOn = false;
        
        % Delay Parameters
        delaySamples = 0;
        delaySamples2 = 0;
        delaySamples3 = 0;
        feedback = 0;
        Dim = false;
        
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
        
        % Memory
        m = [0 0];

        % Smoothing
        alpha = 0.9995;
        p = [0 0 0 0];
    end
    
    methods
        function o = ChorusEffect()
            % Noise
            o.noise = TapeNoise;

            % Compander
            o.comp = TapeWormCompressor;
            o.exp = TapeWormExpander;

            % Delay
            o.randomModDelay = RandomModDelay(false);
            o.randomModDelay2 = RandomModDelay(false);
            o.randomModDelay3 = RandomModDelay(true);

            % Saturation
            o.saturation = RCDiodes;
            o.saturation2 = RCDiodes;

            % Filtering
            o.hpf = BQHPF;
        end
        
        function out = process(o, in)
            [N, C] = size(in);
            out = zeros(N, C);
            
            for c = 1 : C
                for n = 1 : N
                    out(n, c) = o.processSample(in(n, c), c);
                end
            end
        end
        
        function y = processSample (o, x, c)
            % Smooth Params
            o.updateParams;

            % Compander (Compression)
            if o.CompOn
                x = o.comp.processSample(x, c);
            end

            % Input Gain
            gainX = x * o.p(1);

            % Noise
            hiss = o.noise.generateNoise(c);
            hissX = hiss + gainX;

            % Feedback
            fb = hissX + o.m(c) * o.p(2);

            % Modulation
            if o.Dim
                fbDim = fb * 0.4;

                delay1 = o.randomModDelay.processSample(fbDim, c);
                delay2 = o.randomModDelay2.processSample(fbDim, c);
                delay3 = o.randomModDelay3.processSample(fbDim, c);

                wet = 0.80 * (delay1 + delay2 + delay3);
            else
                wet = o.randomModDelay.processSample(fb, c);
            end
            
            % Saturation
            if o.SatOn
                sat = o.saturation.processSample(wet, c);
                sat = o.saturation2.processSample(sat, c);

                wet = o.hpf.processSample(sat, c);
            end

            % Update Memory
            o.m(c) = wet;

             % Compander (Expansion)
            if o.CompOn
                wet = o.exp.processSample(wet, c);
            end

            % Mix wet and dry signal
            mixed = (1 - o.p(3)) * x + o.p(3) * wet;

            % Apply Output Gain
            out = mixed * o.p(4);

            % Hard clip if output exceeds +6 dBFS
            if out > 2
                out = 2;
            end

            % Bypass
            if o.Bypass
                y = x;
            else
                y = out * o.p(4);
            end
        end

        % Smooth Params
        function updateParams(o)
            % Update Input Gain
            o.p(1) = (1 - o.alpha) * o.inGain + o.alpha * o.p(1);

            % Update Feedback Gain
            o.p(2) = (1 - o.alpha) * o.feedback + o.alpha * o.p(2);

            % Update Mix Amount
            o.p(3) = (1 - o.alpha) * o.mix + o.alpha * o.p(3);

            % Update Output Gain
            o.p(4) = (1 - o.alpha) * o.outGain + o.alpha * o.p(4);
        end
        
        % Prepare To Play
        function setFs(o, Fs)
            o.Fs = Fs;

            % Compander
            o.comp.setFs(Fs);
            o.exp.setFs(Fs);
            
            % Noise
            o.noise.setFilters(Fs);
            
            % Delay
            o.randomModDelay.setFs(Fs);
            o.randomModDelay2.setFs(Fs);
            o.randomModDelay3.setFs(Fs);
            o.setRandomSmooth(1);
            o.setModShape;
            
            % Saturation
            o.saturation.setFs(Fs);
            o.saturation2.setFs(Fs);
            o.setClipping;
            
            % Filtering
            o.hpf.setParams(Fs, 20, 0.7071);
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
            delayMs = ceil(delayMs / 3);
            o.randomModDelay2.setDelayMs(delayMs);
            
            o.delaySamples2 = (delayMs / 1000) * o.Fs;
            modDepth = (o.delaySamples2 * 2) * o.depthN;
            randomAmount = (o.delaySamples2 * .25) * o.randomN;

            o.randomModDelay2.setModDepth(modDepth);        
            o.randomModDelay2.setRandomDepth(randomAmount);

            % Delay Line 3
            delayMs = 2 * ceil(delayMs / 3);
            o.randomModDelay3.setDelayMs(delayMs);

            o.delaySamples3 = (delayMs / 1000) * o.Fs;
            modDepth = (o.delaySamples3 * 2) * o.depthN;
            randomAmount = (o.delaySamples3 * .25) * o.randomN;
            
            o.randomModDelay3.setModDepth(modDepth);        
            o.randomModDelay3.setRandomDepth(randomAmount);    
        end

        function setDim(o, Dim)
            o.Dim = Dim;
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

            modDepth = (o.delaySamples3 * 2) * o.depthN;
            o.randomModDelay3.setModDepth(modDepth);
        end
        
        function setModRate(o, modRate)
            o.randomModDelay.setModRate(modRate);
            o.randomModDelay2.setModRate(modRate * 0.33);
            o.randomModDelay3.setModRate(modRate * 0.66);
        end
        
        function setModShape(o)
            o.randomModDelay.setModShape(0.50);
            o.randomModDelay2.setModShape(0.25);
            o.randomModDelay3.setModShape(0.75);
        end

        function setModSt(o, ModSt)
            o.randomModDelay.setModSt(ModSt);
            o.randomModDelay2.setModSt(ModSt);
            o.randomModDelay3.setModSt(ModSt);
        end
        
        % Random Parameters
        function setRandomSmooth(o, smoothN)
            randomSmooth = (smoothN * .00029) + 0.9997;
            o.randomModDelay.setRandomSmoothing(randomSmooth);
            o.randomModDelay2.setRandomSmoothing(randomSmooth);
            o.randomModDelay3.setRandomSmoothing(randomSmooth);
        end
        
        function setRandom(o, randomN)
            o.randomN = randomN;
            
            randomAmount = (o.delaySamples * .25) * o.randomN;
            o.randomModDelay.setRandomDepth(randomAmount);

            randomAmount = (o.delaySamples2 * .25) * o.randomN;
            o.randomModDelay2.setRandomDepth(randomAmount);

            randomAmount = (o.delaySamples3 * .25) * o.randomN;
            o.randomModDelay3.setRandomDepth(randomAmount);
        end
        
        % Compander
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

        function setClipping(o)
            o.saturation.setParams(10^-16, 1.2, 0.026);
            o.saturation.setParams(10^-14, 1.4, 0.026);
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