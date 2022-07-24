{
	(
		//ambisonics stereoDecoder
		SynthDef(\stereoDecoder, {
			arg inbusBF, outbus, amp=1, faderBus;
			var bfSignal, decode, outsig, fader;

			bfSignal = In.ar(inbusBF,4);
			fader = In.kr(faderBus,1).lincurve(0,1,-120,6,-2.695).dbamp;

			decode = FoaDecode.ar(bfSignal, ~mainDecoder);
			outsig = decode * amp * fader;
			outsig = Limiter.ar(outsig);

			SendPeakRMS.ar(outsig, cmdName:'/outDecoderPeakRMS');
			Out.ar(outbus, outsig)
		}).add;

		SynthDef(\sinTest, {
			arg freq = 200, freqImpulse = 15, outbus;
			var aziControl, rhoControl, ampControl, aziEnv, rhoEnv, ampEnv, signal, bfSignal;


			ampControl = Control.names([\ampEnv]).kr(Env.newClear(100).asArray);
			aziControl = Control.names([\aziEnv]).kr(Env.newClear(100).asArray);
			rhoControl = Control.names([\rhoEnv]).kr(Env.newClear(100).asArray);
			ampEnv = EnvGen.kr(ampControl, doneAction: 2);
			aziEnv = EnvGen.kr(aziControl, doneAction: 0);
			rhoEnv = EnvGen.kr(rhoControl, doneAction: 0);

			signal = (SinOsc.ar(freq) * Impulse.kr(freqImpulse)) * ampEnv;
			bfSignal = FoaEncode.ar(signal, ~encoder);
			bfSignal = FoaTransform.ar(bfSignal, 'directO', (rhoEnv) * (pi/2));
			bfSignal = FoaTransform.ar(bfSignal, 'rotate', aziEnv);

			Out.ar(outbus, bfSignal)
		}).add;

		SynthDef(\play1ChBuff, {
			arg buffNum, secInit = 0, secEnd, velocityFactor = 1, gate = 1, outbus, doneAction = 2,
			    bandFreq, bandRq;
			var aziControl, rhoControl, ampControl, aziEnv, rhoEnv, ampEnv,
			    pBuff, sampleInit, sampleEnd, buffSampleRate, dur, bufPointer,
			    bandpass,
			    signal, bfSignal
			;

			ampControl = Control.names([\ampEnv]).kr(Env.newClear(50).asArray);
			aziControl = Control.names([\aziEnv]).kr(Env.newClear(50).asArray);
			rhoControl = Control.names([\rhoEnv]).kr(Env.newClear(50).asArray);
			ampEnv = EnvGen.kr(ampControl, gate, doneAction: doneAction);
			aziEnv = EnvGen.kr(aziControl, doneAction: 0);
			rhoEnv = EnvGen.kr(rhoControl, doneAction: 0);

			buffSampleRate = BufSampleRate.ir(buffNum); //sampleRate do buff
			dur = abs(secEnd - secInit) / velocityFactor; //duracao em segundos entre secInit e secEnd

			sampleInit = secInit * buffSampleRate;//ponto inicial em samples
			sampleEnd = secEnd * buffSampleRate;//ponto final em samples

			//ponteiro que percorre os pontos de inicio e fim do arquivo, direcionando a leitura da UGen BufRd
			bufPointer = Line.ar(sampleInit, sampleEnd, dur, doneAction: doneAction);
			pBuff = BufRd.ar(1, buffNum, bufPointer, 0);
			bandpass = BPF.ar(pBuff, bandFreq, bandRq);

			signal = bandpass * ampEnv;
			bfSignal = FoaEncode.ar(signal, ~encoder);
			bfSignal = FoaTransform.ar(bfSignal, 'directO', (rhoEnv) * (pi/2));
			bfSignal = FoaTransform.ar(bfSignal, 'rotate', aziEnv);

			Out.ar(outbus, bfSignal);
		}).add;

		SynthDef(\in1ToBf, {
			arg inbus, outbus, faderBus, ambiPositionKnobBus, gate = 1, done = 2;
			var insig, fader, ambiPositionKnob, bfSignal,
			    aziControl, rhoControl, ampControl, aziEnv, rhoEnv, ampEnvGen
			;

			insig = In.ar(inbus, 1);
			fader = In.kr(faderBus,1).lincurve(0,1,-120,6,-2.695).dbamp;
			ambiPositionKnob = In.kr(ambiPositionKnobBus, 1).linlin(0, 1.0, pi, -pi);

			ampControl = Control.names([\ampEnv]).kr(Env.newClear(50).asArray);
			ampEnvGen = EnvGen.kr(ampControl, gate, doneAction: done);

			insig = insig * fader * ampEnvGen;
			insig = Limiter.ar(insig);

			aziControl = Control.names([\aziEnv]).kr(Env.newClear(50).asArray);
			rhoControl = Control.names([\rhoEnv]).kr(Env.newClear(50).asArray);
			aziEnv = EnvGen.kr(aziControl);
			rhoEnv = EnvGen.kr(rhoControl);

			bfSignal = FoaEncode.ar(insig, ~encoder);
			bfSignal = FoaTransform.ar(bfSignal, 'directO', (rhoEnv) * (pi/2));
			bfSignal = FoaTransform.ar(bfSignal, 'rotate', ambiPositionKnob);

			SendPeakRMS.ar(insig, cmdName: '/in1PeakRMS');
			Out.ar(outbus, bfSignal);
		}).add;

		SynthDef(\in2ToBf, {
			arg inbus, outbus, faderBus, ambiPositionKnobBus, gate = 1, done = 2;
			var insig, fader, ambiPositionKnob, bfSignal,
			    aziControl, rhoControl, ampControl, aziEnv, rhoEnv, ampEnvGen
			;

			insig = In.ar(inbus, 1);
			fader = In.kr(faderBus,1).lincurve(0,1,-120,6,-2.695).dbamp;
			ambiPositionKnob = In.kr(ambiPositionKnobBus, 1).linlin(0, 1.0, pi, -pi);

			ampControl = Control.names(\ampEnv).kr(Env.newClear(50).asArray);
			ampEnvGen = EnvGen.kr(ampControl, gate, doneAction: done);

			insig = insig * fader * ampEnvGen;
			insig = Limiter.ar(insig);

			aziControl = Control.names(\aziEnv).kr(Env.newClear(50).asArray);
			rhoControl = Control.names(\rhoEnv).kr(Env.newClear(50).asArray);
			aziEnv = EnvGen.kr(aziControl);
			rhoEnv = EnvGen.kr(rhoControl);

			bfSignal = FoaEncode.ar(insig, ~encoder);
			bfSignal = FoaTransform.ar(bfSignal, 'directO', (rhoEnv) * (pi/2));
			bfSignal = FoaTransform.ar(bfSignal, 'rotate', ambiPositionKnob);

			SendPeakRMS.ar(insig, cmdName: '/in2PeakRMS');
			Out.ar(outbus, bfSignal);
		}).add;

		SynthDef(\electronicsBFRoute, {
			arg inbus, outbus, faderBus, amp=1, gate = 1, done =  2;
			var bfSignal, outsig, faderIn, ampEnv, ampControl, aziControl, rhoControl, aziEnv, rhoEnv;

			bfSignal = In.ar(inbus,4);
			faderIn = In.kr(faderBus, 1).lincurve(0,1,-120,6,-2.695).dbamp;

			ampControl = Control.names(\ampEnvelope).kr(Env.newClear(50).asArray);
			ampEnv = EnvGen.kr(ampControl, gate, doneAction: done);

			aziControl = Control.names(\aziEnvelope).kr(Env.newClear(50).asArray);
			rhoControl = Control.names(\rhoEnvelope).kr(Env.newClear(50).asArray);
			aziEnv = EnvGen.kr(aziControl);
			rhoEnv = EnvGen.kr(rhoControl);

			bfSignal = FoaTransform.ar(bfSignal, 'directO', (rhoEnv) * (pi/2));
			bfSignal = FoaTransform.ar(bfSignal, 'rotate', aziEnv);

			bfSignal = bfSignal * faderIn * ampEnv;
			outsig = bfSignal * amp;

			SendPeakRMS.ar(outsig, cmdName:'/outElectronicsPeakRMS');
			Out.ar(outbus, outsig)
		}).add;

		SynthDef(\bfGVerb, {
			arg inbus, outbus, faderBus, amp=1, doneAction=0,
			    diffuse=0.0, iroom=32, rtime=0.1, damp=0.5, inbw=0.5, dry=0.5, early=0.2, tail=0.5, imaxroom=300, gate=1;
			var w, x, y, z, fader, envgen, bf, outsig;

			#w,x,y,z = In.ar(inbus,4);
			fader = In.kr(faderBus,1).lincurve(0,1,-120,6,-2.695).dbamp;

			damp = damp.linlin(0,1.0,0.01,0.99);
			envgen = EnvGen.kr(Control.names([\env]).kr(Env.newClear(24).asArray), gate: gate, doneAction: doneAction);

			bf = BFGVerb.ar(w,x,y,z,diffuse,iroom,rtime*10,damp,inbw,dry,early,tail,imaxroom);
			outsig = bf * amp * envgen * fader;

			SendPeakRMS.ar(outsig, cmdName:'/outReverbPeakRMS');
			Out.ar(outbus, outsig);
		}).add;

		SynthDef(\hardRoute4ch, {
			arg inbus, outbus, amp=1;
			var insig,outsig;
			insig = In.ar(inbus,4);
			outsig = insig*amp;
			Out.ar(outbus,outsig)
		}).add;

		SynthDef(\hardRoute4chMicIn, {
			arg inbus, outbus, faderBus, amp=1;
			var insig,outsig, fader;

			insig = In.ar(inbus,4);
			fader = In.kr(faderBus, 1);
			outsig = insig*amp*fader;

			Out.ar(outbus,outsig)
		}).add;
	)
}.fork(SystemClock)