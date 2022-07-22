(
~vecEvents = [
	{ //event -2 -- set everything up
		{
			var ampEnv;

			"--> event -2 started".postln();

			//ambisonics decoder
			(~outSetup == \stereo).if({
				~speakerDecoder = Synth(\stereoDecoder,
					[
						\inbusBF, ~busA_BF_toDecode,
						\outbus, ~busA_speakersOut,
						\amp, 1,
						\faderBus, ~vecMIDIFadersBuses[8]
					], ~group_decoders
				);

				"|--> decoder stereo/out added".postln;
			});

			//reverb ambisonics
			~synth_bfGVerb = Synth(\bfGVerb,[
				\inbus,~busA_BF_reverb,
				\outbus, ~busA_BF_toDecode,
				\faderBus,  ~vecMIDIFadersBuses[7], //
				\amp, 3.dbamp,
				\iroom, 40, //NAO MODULAR!      //usar knobs? * 100
			//	\diffuse, ~bpf2000kBusArr[0][10].asMap, //usar knobs? 0-1
			//	\rtime, ~bpf2000kBusArr[0][11].asMap ,// NAO MODULAR! ~bpf2000kBusArr[0][11],//~bpf2000kBusArr[0][11],      //usar knobs? * 10
			//	\damp, ~bpf2000kBusArr[0][12].asMap ,    //0 damps the reverb signal completely, 1 not at all.
				//\inbw, ~bpf2000kBusArr[0][13].asMap ,//~bpf2000kBusArr[0][13],     //0 damps the reverb signal completely, 1 not at all. (in)
				\dry, 0,        //usar knobs?
				//\early, ~bpf2000kBusArr[0][14].asMap,    //usar knobs?
				//\tail, ~bpf2000kBusArr[0][15].asMap,     //usar knobs?
				\imaxroom, 300,
				\gate,1,
				\doneAction,2,
				\env, Env([0,1,0],[1,10],\sin,1)
			], ~group_reverb );
			"|--> bfGVerb added".postln;

			// Ambisonics routing for decoding and reverb
			//1.liveRoute
			~synth_hardRoute4ch_liveRoute_toDecode = Synth(\hardRoute4ch, [
				\inbus, ~busA_BF_liveRoute,
				\outbus, ~busA_BF_toDecode,
				\amp, 1
			], target: ~group_liveRoute, addAction:\addAfter);

			~synth_hardRoute4ch_liveRoute_reverb = Synth(\hardRoute4ch, [
				\inbus, ~busA_BF_liveRoute,
				\outbus, ~busA_BF_reverb,
				\amp, 1
			], target: ~group_liveRoute, addAction:\addAfter);

			".. liveRoute -> toDecode / reverb: ok".postln;

			//2.electronics
			~synth_hardRoute4ch_electronics_toDecode = Synth(\hardRoute4ch, [
				\inbus, ~busA_BF_electronics,
				\outbus, ~busA_BF_toDecode,
				\amp, 1
			], target: ~group_electronics, addAction:\addAfter);

			~synth_hardRoute4ch_eletronics_reverb = Synth(\hardRoute4ch, [
				\inbus, ~busA_BF_electronics,
				\outbus, ~busA_BF_reverb,
				\amp, 1
			], target: ~group_electronics, addAction:\addAfter);

			".. electronics -> toDecode / reverb: ok".postln;

			// micsIn
			~ampEnv = Env.new([0, 1, 0], [1, 0.1], releaseNode: 1);

			~mic1InSynth = Synth(\in1ToBf, [
				\inbus, ~violin_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[2],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[0],
				\ampEnv, ~ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: Color(255/255, 200/255, 200/255, 0.6),
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 0,
				timeToDeath: nil
			);

			~mic2InSynth = Synth(\in2ToBf, [
				\inbus, ~cello_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[3],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[1],
				\ampEnv, ~ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: Color(200/255, 255/255, 180/255, 0.6),
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 1,
				timeToDeath: nil
			);
		}.fork();
	},
	{// event -1 --- prepare for first
		{
			"--> event -1 started".postln();

			//micsIn out
			~mic1InSynth.release;
			~mic2InSynth.release;

			~funcRemoveAllRoutesAmbiObj.value(0.1);
		}.fork();
	},
	{ // event 0
		{// micsIn
			var ampEnv = Env.new([0, 0.95, 0], [12.5, 4], \cub, releaseNode: 1);

			"--> event 0 started".postln();

			~mic1InSynth = Synth.new(\in1ToBf, [
				\inbus, ~violin_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[2],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[0],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in1Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 0,
				timeToDeath: nil
			);

			~mic2InSynth = Synth.new(\in2ToBf, [
				\inbus, ~cello_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[3],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[1],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in2Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 1,
				timeToDeath: nil
			);
		}.fork();
	},
	{ // event 1
		//começa pizz eletronica (baixa densidade)
		{
			"--> event 1 started".postln();

			~minTimeBetweenPizz = 1.25; ~maxTimeBetweenPizz = 3.75;
			~minRandomPizzAzi = -pi; ~maxRandomPizzAzi = pi;
			~minRandomPizzVelocityFactor = 0.975; ~maxRandomPizzVelocityFactor = 1.025;
			~minRandomPizzFreq = 250.0; ~maxRandomPizzFreq = 2500.0;
			~minRandomPizzRq = 0.8; ~maxRandomPizzRq = 4.0;
			~minRandomPizzAmp = 0.35; ~maxRandomPizzAmp = 0.5;

			~event1_taskKill = ~funcRandomPizz.value();
		}.fork();
	},
	{ // event 2
		//aumenta densidade devagar (5 segundos - densidade media)
		{
			var densityIncreaseDur = 5.0, minTimeStepChange = -0.115, maxTimeStepChange = -0.165;

			"--> event 2 started".postln();

			~minTimeBetweenPizz = 2.25; ~maxTimeBetweenPizz = 4.75;
			~minRandomPizzAzi = -pi; ~maxRandomPizzAzi = pi;
			~minRandomPizzVelocityFactor = 0.975; ~maxRandomPizzVelocityFactor = 1.025;
			~minRandomPizzFreq = 250.0; ~maxRandomPizzFreq = 2500.0;
			~minRandomPizzRq = 0.8; ~maxRandomPizzRq = 4.0;
			~minRandomPizzAmp = 0.15; ~maxRandomPizzAmp = 0.35;

			~event2_taskKill = ~funcRandomPizz.value();

			~event2_taskIncreasePizzDensity = Task.new({
				var clock = 0, numSteps = 10, timeStep;

				timeStep = densityIncreaseDur/numSteps;

				inf.do({
					clock = clock + timeStep;

					~minTimeBetweenPizz = ~minTimeBetweenPizz + minTimeStepChange;
					~maxTimeBetweenPizz = ~maxTimeBetweenPizz + maxTimeStepChange;

					if(clock >= densityIncreaseDur, {
						~event2_taskIncreasePizzDensity.stop;
						~event2_taskIncreasePizzDensity.free;
					});

					timeStep.wait;
				});
			}, SystemClock);

			~event2_taskIncreasePizzDensity.play;

			{
				~event22_taskKill = ~funcRandomPizz.value();
			}.defer(3);
		}.fork();
	},
	{ // event 3
		//aumenta rápido (2.5 segundos - densidade super alta!)
		{
			var densityIncreaseDur = 2.5, minTimeStepChange = -0.0875, maxTimeStepChange = -0.2825,
			minAmpStepChange = 0.055, maxAmpStepChange = 0.045;

			"--> event 3 started".postln();

			~event2_taskIncreasePizzDensity.stop;
			~event2_taskIncreasePizzDensity.free;

			~minTimeBetweenPizz = 1.1; ~maxTimeBetweenPizz = 3.15;
			~minRandomPizzAzi = -pi; ~maxRandomPizzAzi = pi;
			~minRandomPizzVelocityFactor = 0.975; ~maxRandomPizzVelocityFactor = 1.025;
			~minRandomPizzFreq = 250.0; ~maxRandomPizzFreq = 2500.0;
			~minRandomPizzRq = 0.8; ~maxRandomPizzRq = 4.0;
			~minRandomPizzAmp = 0.15; ~maxRandomPizzAmp = 0.35;

			~event3_taskIncreasePizzDensity = Task.new({
				var clock = 0, numSteps = 10, timeStep;

				timeStep = densityIncreaseDur/numSteps;

				inf.do({
					clock = clock + timeStep;

					~minTimeBetweenPizz = ~minTimeBetweenPizz + minTimeStepChange;
					~maxTimeBetweenPizz = ~maxTimeBetweenPizz + maxTimeStepChange;

					~minRandomPizzAmp = ~minRandomPizzAmp + minAmpStepChange;
					~maxRandomPizzAmp = ~maxRandomPizzAmp + maxAmpStepChange;

					if(clock >= densityIncreaseDur, {
						~event3_taskIncreasePizzDensity.stop;
						~event3_taskIncreasePizzDensity.free;
					});

					timeStep.wait;
				});
			}, SystemClock);

			~event3_taskIncreasePizzDensity.play;

			~event3_taskKill = ~funcRandomPizz.value();
			~event35_taskKill = ~funcRandomPizz.value();

			{

				~event32_taskKill = ~funcRandomPizz.value();
			}.defer(densityIncreaseDur/3);

			{

				~event33_taskKill = ~funcRandomPizz.value();
			}.defer(densityIncreaseDur * 2/3);

			{

				~event34_taskKill = ~funcRandomPizz.value();
			}.defer(densityIncreaseDur);
		}.fork();

	},
	{ // event 4
		//+som violino; focando em partes mais agudas do espectro (transientes) e centralizando espacializacao
		{
			var densityIncreaseDur = 13,
			minAmpStepChange = 0.06, maxAmpStepChange = 0.07,
			minFreqStepChange = 97.5, maxFreqStepChange = 105,
			minRqStepChange = -0.00752, maxRqStepChange = -0.03798,
			minAziStepChange = 2pi/100, maxAziStepChange = 0;

			"--> event 4 started".postln();

			~event3_taskIncreasePizzDensity.stop;
			~event3_taskIncreasePizzDensity.free;

			~minTimeBetweenPizz = 0.25; ~maxTimeBetweenPizz = 0.4;
			~minRandomPizzAzi = -pi - (pi/7); ~maxRandomPizzAzi = pi + (pi/7);
			~minRandomPizzVelocityFactor = 0.975; ~maxRandomPizzVelocityFactor = 1.025;
			~minRandomPizzFreq = 250.0; ~maxRandomPizzFreq = 2500.0;
			~minRandomPizzRq = 0.8; ~maxRandomPizzRq = 4.0;
			~minRandomPizzAmp = 0.7; ~maxRandomPizzAmp = 0.95;

			~event4_taskPizzFiltering = Task.new({
				var clock = 0, numSteps = 100, timeStep;

				timeStep = densityIncreaseDur/numSteps;

				inf.do({
					clock = clock + timeStep;

					~minRandomPizzFreq = ~minRandomPizzFreq + minFreqStepChange;
					~maxRandomPizzFreq = ~maxRandomPizzFreq + maxFreqStepChange;

					~minRandomPizzRq = ~minRandomPizzRq + minRqStepChange;
					~maxRandomPizzRq = ~maxRandomPizzRq + maxRqStepChange;

					~minRandomPizzAmp = ~minRandomPizzAmp + minAmpStepChange;
					~maxRandomPizzAmp = ~maxRandomPizzAmp + maxAmpStepChange;

					~minRandomPizzAzi = ~minRandomPizzAzi + minAziStepChange;
					~maxRandomPizzAzi = ~maxRandomPizzAzi + maxAziStepChange;

					if(clock >= densityIncreaseDur, {
						~event4_taskPizzFiltering.stop;
						~event4_taskPizzFiltering.free;
					});

					timeStep.wait;
				});
			}, SystemClock);

			~event4_taskPizzFiltering.play;

		}.fork();
	},
	{ // event 5
		//força filtragem, abre espacializacao
		{
			var densityIncreaseDur = 10,
			minAmpStepChange = -0.04, maxAmpStepChange = 0.03,
			minAziStepChange = ((pi/2)/100), maxAziStepChange = ((pi/2)/100) ;

			"--> event 5 started".postln();

			~event4_taskPizzFiltering.stop;
			~event4_taskPizzFiltering.free;

			~minTimeBetweenPizz = 0.25; ~maxTimeBetweenPizz = 0.4;
			~minRandomPizzAzi = pi - (pi/7) + (pi/9); ~maxRandomPizzAzi = pi + (pi/8);
			~minRandomPizzVelocityFactor = 0.925; ~maxRandomPizzVelocityFactor = 1.075;
			~minRandomPizzFreq = 10000; ~maxRandomPizzFreq = 13000;
			~minRandomPizzRq = 0.048; ~maxRandomPizzRq = 0.202;
			~minRandomPizzAmp = 6; ~maxRandomPizzAmp = 7.2;

			~event5_taskPizzFiltering = Task.new({
				var clock = 0, numSteps = 100, timeStep;

				timeStep = densityIncreaseDur/numSteps;

				inf.do({
					clock = clock + timeStep;
					~minRandomPizzAmp = ~minRandomPizzAmp + minAmpStepChange;
					~maxRandomPizzAmp = ~maxRandomPizzAmp + maxAmpStepChange;

					~minRandomPizzAzi = ~minRandomPizzAzi + minAziStepChange;
					~maxRandomPizzAzi = ~maxRandomPizzAzi + maxAziStepChange;

					if(clock >= densityIncreaseDur, {
						~event5_taskPizzFiltering.stop;
						~event5_taskPizzFiltering.free;
					});

					timeStep.wait;
				});
			}, SystemClock);

			~event5_taskPizzFiltering.play;

		}.fork();
	},
	{ // event 6
		//para tudo
		{
			"--> event 6 started".postln();

			~mic1InSynth.release();
			~mic2InSynth.release();

			~funcRemoveAllRoutesAmbiObj.value(4);

			~event1_taskKill.play();

			~event2_taskKill.play();
			~event22_taskKill.play();

			~event3_taskKill.play();
			~event32_taskKill.play();
			~event33_taskKill.play();
			~event34_taskKill.play();
			~event35_taskKill.play();
		}.fork();
	},
	{ // event 7
		//abre routes lentamente (8 segundos); prepara entrada quiques
		{
			// micsIn
			var ampEnv = Env.new([0, 1, 0], [8, 10], \cub, releaseNode: 1);

			"--> event 7 started".postln();

			~mic1InSynth = Synth.new(\in1ToBf, [
				\inbus, ~violin_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[2],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[0],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in1Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 0,
				timeToDeath: nil
			);

			~mic2InSynth = Synth.new(\in2ToBf, [
				\inbus, ~cello_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[3],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[1],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in2Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 1,
				timeToDeath: nil
			);
		}.fork();
	},
	{ // event 8
		//parando de reagir aos quiques devagar (14 segundos)
	},
	{ // event 9
		//fecha routes lentamente; forca parada de quiques
		{
			"--> event 9 started".postln();

			~mic1InSynth.release();
			~mic2InSynth.release();

			~funcRemoveAllRoutesAmbiObj.value(6);
		}.fork;
	},
	{ // event 10
		//força parada de tudo
		{
			"--> event 10 started".postln();

			~mic1InSynth.release(0.1);
			~mic2InSynth.release(0.1);
		}
	},
	{ // event 11
		//abre routes rápido (1 segundo?) - triga ruído de cavelete com próximo ataque (contínuo)
		{
			// micsIn
			var ampEnv = Env.new([0, 1, 0], [1, 10], \cub, releaseNode: 1);

			"--> event 11 started".postln();

			~mic1InSynth = Synth.new(\in1ToBf, [
				\inbus, ~violin_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[2],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[0],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in1Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 0,
				timeToDeath: nil
			);

			~mic2InSynth = Synth.new(\in2ToBf, [
				\inbus, ~cello_busNum,
				\outbus, ~busA_BF_liveRoute,
				\faderBus, ~vecMIDIFadersBuses[3],
				\ambiPositionKnobBus, ~vecMIDIKnobsBuses[1],
				\ampEnv, ampEnv,
				\done, 2
			], ~group_liveRoute);

			~funcInstantiateNewAmbiObj.value(
				aziEnv: nil,
				rhoEnv: nil,
				ampEnv: nil,
				curAzi: nil,
				curRho: 1,
				curSize: 2,
				curColor: ~in2Color,
				objType: ~ambiObjTypes[\instRoute],
				aziKnobIndex: 1,
				timeToDeath: nil
			);
		}.fork();
	},
	{ // event 12
		//para ruído de cavalete
	},
	{ // event 13
		//bartoks aumentando número de nodes que ativam ruídos de cavalete randômicos
	},
	{ // event 14
		//mater ruídos de cavelete, parar de trigar mais nodes
	},
	{//last event  - 15
		//deixar desinência dos ruídos, descrescendo; fechar routes lentamente
		{
			"--> event 15 started".postln();

			~mic1InSynth.release();
			~mic2InSynth.release();

			~funcRemoveAllRoutesAmbiObj.value(10);

			("--> ELECTRONICS END <--|").defer(10);
		}.fork;
	}
];
)