(
{
	~funcRandomPizz = {
		var taskKillAll, randomPizzTask, pizzGroup, pizzBus, pizzGroupRoute;
			//250-2500
			//rq alto

		pizzGroup = Group.new(~group_electronics);
		pizzBus = Bus.audio(s, 4);

		randomPizzTask = Task.new({
			inf.do({
				var synth, possibleBuffNums = (0..(~numPizzFiles-1)), chosenBuffNum, bandFreq, duration, azi, rho, ampEnv, aziEnv, rhoEnv, velocityFactor;

				chosenBuffNum = possibleBuffNums.choose;
				duration = ~vecPizzSoundFilesBuffers[chosenBuffNum].duration;
				velocityFactor = rrand(~minRandomPizzVelocityFactor, ~maxRandomPizzVelocityFactor);
				//velocityFactor = rrand(0.87, 1.13);

				bandFreq = rrand(~minRandomPizzFreq, ~maxRandomPizzFreq);
				//bandFreq = rrand(13000, 16500.0);
				azi = rrand(~minRandomPizzAzi, ~maxRandomPizzAzi);
				rho = rrand(0, 0.3);

				//ampEnv = Env.new([0, rrand(40, 52), 0], [0.01 ,duration - 0.01]);
				ampEnv = Env.new([0, rrand(~minRandomPizzAmp, ~maxRandomPizzAmp), 0], [0.01 ,duration - 0.01]);
				aziEnv = Env.new([0, azi, azi], [0.01, duration]);
				rhoEnv = Env.new([0, rho, rho], [0.01, duration]);

				synth = Synth(\play1ChBuff, [
					\buffNum, chosenBuffNum,
					\secInit, 0,
					\secEnd, duration,
					\velocityFactor, velocityFactor,
					\ampEnv, ampEnv,
					\aziEnv, aziEnv,
					\rhoEnv, rhoEnv,
					\bandFreq, bandFreq,
					\bandRq, rrand(~minRandomPizzRq, ~maxRandomPizzRq),
					\outbus, pizzBus
					//\bandRq, rrand(0.8, 4) 4 - 0.005
					//\bandRq, rrand(0.003, 0.005)
				], pizzGroup);

				~funcInstantiateNewAmbiObj.value(
					aziEnv: aziEnv,
					rhoEnv: rhoEnv,
					ampEnv: ampEnv,
					curAzi: 0,
					curRho: 1,
					curSize: 0,
					curColor: Color(rrand(0.125, 1), rrand(0.125, 1), rrand(0.125, 1), rrand(0.25, 0.4)),
					objType: 0,
					timeToDeath: duration
				);

				rrand(~minTimeBetweenPizz, ~maxTimeBetweenPizz).wait;
			});
		}, SystemClock);

		randomPizzTask.play;

		pizzGroupRoute = Synth(\electronicsBFRoute, [
			\inbus, pizzBus,
			\outbus, ~busA_BF_electronics,
			\faderBus,  ~vecMIDIFadersBuses[5],
			\ampEnv, Env([0, 1, 0], [0.1, 0.1], releaseNode:1),
			\amp, 1,
			\doneAction, 2
		], target: pizzGroup,  addAction: 'addToTail');

		taskKillAll = Task({
			pizzGroupRoute.release;
			{
				randomPizzTask.stop;
				pizzBus.free;
				pizzGroup.free;
			}.defer(0.01);

			taskKillAll.stop;
		});

		taskKillAll;
	};

	//extracted from Sergio Freire's pandora Max/MSP patch
	~funcBounce = {
		arg velocity = 2.8, height = 1.8, gravity = 13, loss = 0.8;
		var bounceTask;

		bounceTask = Task.new({
			var amplitude, timeBetweenBounces;

			amplitude = (velocity.squared + (2*height*gravity)).sqrt;

			inf.do({
				amplitude = amplitude * loss;

				//("|--> bounceTask: cur amp = " ++ amplitude).postln;

				if((amplitude < ~bounceAmplitudeTresh) || (amplitude > 6.0) , {
					//"|--> bounceTask: stopped".postln;

					bounceTask.stop;
				});

				//{Out.ar([0,1], (SinOsc.ar(440) * EnvGen.kr(Env.perc) * 0.1))}.play;

				timeBetweenBounces = ((2*amplitude)/gravity);

				//("|--> bounceTask:cur time = " ++ timeBetweenBounces).postln;

				timeBetweenBounces.wait;
			});
		}, SystemClock);

		bounceTask.play;
	};

	~funcBridgeNoise = {

	};

	~funcRMSTriggerElectronics = {
		arg inputIndex, currentRMSValue;
		var cooldownTask;

		if(~inputTriggered[inputIndex] == true, {
			if((currentRMSValue <= (~vecMIDIFadersValues[0] + ~triggerOffFactor)) && (~inputTriggerCooldown[inputIndex] == false), {
				cooldownTask = Task.new({
					var duration = ~cooldownTriggerDur, clock = 0;

					~inputTriggerCooldown[inputIndex] = true;

					inf.do({
						(clock >= ~cooldownTriggerDur).if({
							~inputTriggered[inputIndex] = false;
							~inputTriggerCooldown[inputIndex] = false;

							//("|--> triggerRMS: cooleddown for input " ++ inputIndex).postln;

							cooldownTask.stop;
							cooldownTask.free;
						});
						clock = clock + 0.1;

						(0.1).wait;
					});
				}, SystemClock);

				cooldownTask.play;
			});
		}, { //isnt triggered
			if(~inputTriggerCooldown[inputIndex] == false, {
				if(currentRMSValue > ~vecMIDIFadersValues[inputIndex], {
					~inputTriggered[inputIndex] = true;

					//("|--> triggerRMS: triggered for input " ++ inputIndex).postln;
				})
			});
		});
	};
}.fork(SystemClock);
)