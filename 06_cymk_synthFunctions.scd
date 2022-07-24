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
			\ampEnvelope, Env([0, 1, 0], [0.1, 0.1], releaseNode:1),
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

	~funcBridgeNoise = {
		arg possibleIndexes = (0..8), possibleDirections = [0, 1, -1], minMaxFadeInDur = [0.3, 3.0], minMaxFadeOutDur = [0.1, 3.0],
		minMaxVelocityFactor = [0.8, 1.4], minMaxBandFreq = [250, 10000], minMaxBandRq = [0.75, 1.75],
		aziMinDif = pi/3, aziMaxDif = pi, rhoMinDif = 0.05, rhoMaxDif = 0.2, aziMinMaxDeviation = [pi/3, 3pi/2], rhoMixMaxDeviation = [0, 0.8],
		groupFadeIn = 1, groupFadeOut = 1;
		var bridgeNoiseTask, taskKillAll,
		bridgeBus, bridgeGroup, bridgeGroupRoute;

		bridgeGroup = Group.new(~group_electronics);
		bridgeBus = Bus.audio(s, 4);

		bridgeGroupRoute = Synth(\electronicsBFRoute, [
			\inbus, bridgeBus,
			\outbus, ~busA_BF_electronics,
			\faderBus,  ~vecMIDIFadersBuses[5],
			\ampEnvelope, Env([0, 1, 0], [groupFadeIn, groupFadeOut], releaseNode:1),
			\amp, 1,
			\doneAction, 2
		], target: bridgeGroup,  addAction: 'addToTail');

		taskKillAll = Task({
			bridgeGroupRoute.release;
			{
				bridgeNoiseTask.stop;
				bridgeBus.free;
				bridgeGroup.free;
			}.defer(groupFadeOut);

			~numBridgesActive = ~numBridgesActive - 1;

			taskKillAll.stop;
		});

		bridgeNoiseTask = Task.new({
			var lastAzi = rrand(-pi, pi);

			inf.do({
				var newNoiseIndex = possibleIndexes.choose, duration, newSynth, ampEnv, aziEnv, waitTime, rhoEnv,
				velocityFactor, bandFreq, bandRq, fadeInDur, fadeOutDur, direction, secInit, secEnd, nextAzi;

				velocityFactor = rrand(minMaxVelocityFactor[0], minMaxVelocityFactor[1]);
				fadeInDur = rrand(minMaxFadeInDur[0], minMaxFadeInDur[1]);
				fadeOutDur = rrand(minMaxFadeOutDur[0], minMaxFadeOutDur[1]);

				bandFreq = rrand(minMaxBandFreq[0], minMaxBandFreq[1]);
				bandRq = rrand(minMaxBandRq[0], minMaxBandRq[1]);

				if((bandFreq >= 4500) && (bandFreq <= 7500), {
					bandFreq = bandFreq - ([-1, 1].choose * 3000);
				});

				duration = ~vecBridgeSoundFilesBuffers[newNoiseIndex].duration;

				direction = possibleDirections.choose;
				if(direction == 0, {
					if([1, -1].choose == 1, {
						secInit = 0;
						secEnd = duration;
					}, {
						secEnd = 0;
						secInit = duration;
					});

					ampEnv = Env.new([0, 1, 1, 0], [fadeInDur, (duration * velocityFactor) - (fadeInDur + fadeOutDur), fadeOutDur]);
					waitTime = (duration - fadeOutDur);
				}, {
					var newDuration = 0;

					secInit = rrand(0, duration - 0.3);

					if(secInit >= (duration/2), {
						secEnd = rrand(0, (duration/6));
					},{
						secEnd = rrand((duration/2), duration);
					});

					newDuration = abs(secEnd - secInit) * velocityFactor;

					ampEnv = Env.new(times: [newDuration/2, newDuration/2]);

					waitTime = newDuration;
				});

				nextAzi = lastAzi + ([-1, 1].choose * rrand(aziMinMaxDeviation[0], aziMinMaxDeviation[1]));
				aziEnv = Env.new([lastAzi, nextAzi], [waitTime]);
				rhoEnv = Env.new([rrand(rhoMixMaxDeviation[0], rhoMixMaxDeviation[1]), rrand(rhoMixMaxDeviation[0], rhoMixMaxDeviation[1]), rrand(rhoMixMaxDeviation[0], rhoMixMaxDeviation[1])], [waitTime/2, waitTime/2]);

				newSynth = Synth(\play1ChBuff, [
					\buffNum, ~vecBridgeSoundFilesBuffers[newNoiseIndex].bufnum,
					\secInit, secInit,
					\secEnd, secEnd,
					\velocityFactor, velocityFactor,
					\ampEnv, ampEnv,
					\aziEnv, aziEnv,
					\rhoEnv, rhoEnv,
					\bandFreq, bandFreq,
					\bandRq, bandRq,
					\outbus, bridgeBus
				], bridgeGroup);

				~funcInstantiateNewAmbiObj.value(
					aziEnv: aziEnv,
					rhoEnv: rhoEnv,
					ampEnv: ampEnv,
					curAzi: 0,
					curRho: 1,
					curSize: 0,
					curColor: Color(rrand(0.125, 1), rrand(0.125, 1), rrand(0.125, 1), rrand(0.25, 0.4)),
					objType: 0,
					timeToDeath: waitTime
				);

				waitTime.wait;
			});
		}, SystemClock);

		bridgeNoiseTask.play;

		~numBridgesActive = ~numBridgesActive + 1;

		taskKillAll;
	};

	/*~funcBridgeNoise.value(
		possibleDirections: [0, -1, 1],
		minMaxBandFreq: [500, 10000],
		minMaxFadeInDur: [1, 3],
		minMaxFadeOutDur: [1, 3],
	rhoMixMaxDeviation: [0.7, 0.9]

	);*/


	/*30.do({
		~funcBounce.value
	});*/

	//extracted from Sergio Freire's pandora Max/MSP patch
	~funcBounce = {
		arg velocity = rrand(1.8, 2.4), height = rrand(1.2, 2.2), gravity = rrand(9, 13), loss = rrand(0.6, 0.9), changeBartokChance = 0.075,
		minMaxVelocityFactor = [0.98, 1.02], minMaxBandFreq = [250, 8000], minMaxBandRq = [0.8, 2.5],
		aziMinDif = pi/3, aziMaxDif = pi, rhoMinDif = 0.05, rhoMaxDif = 0.2;
		var bounceTask, bartokFilesIndexes, chosenIndex, duration, newAttackSynth,
		bounceGroup, bounceBus, bounceGroupRoute, taskKillAll,
		aziEnv, rhoEnv, aziInit, aziDif = 0, rhoInit, rhoDif;

		~numBouncesActive = ~numBouncesActive + 1;

		bounceGroup = Group.new(~group_electronics);
		bounceBus = Bus.audio(s, 4);

		bartokFilesIndexes = (0..(~numBartokFiles - 1));
		chosenIndex = bartokFilesIndexes.choose;

		aziInit = rrand(-pi, pi);
		aziDif = aziInit + ([-1, 1].choose * rrand(aziMinDif, aziMaxDif));
		aziEnv = Env([aziInit, aziDif], rrand(3, 7.0));

		rhoInit = rrand(0.2, 0.25);
		rhoDif = rhoInit + ([1, -1].choose * rrand(rhoMinDif, rhoMaxDif));
		rhoEnv = Env([rhoInit, rhoDif], rrand(3, 7.0));

		bounceGroupRoute = Synth(\electronicsBFRoute, [
			\inbus, bounceBus,
			\outbus, ~busA_BF_electronics,
			\faderBus,  ~vecMIDIFadersBuses[5],
			\ampEnvelope, Env([0, 1, 0], [0.1, 1], releaseNode:1),
			\aziEnvelope, aziEnv,
			\rhoEnvelope, rhoEnv,
			\amp, 1,
			\doneAction, 2
		], target: bounceGroup,  addAction: 'addToTail');

		taskKillAll = Task({
			bounceGroupRoute.release;
			{
				bounceTask.stop;
				bounceBus.free;
				bounceGroup.free;

				~numBouncesActive = ~numBouncesActive - 1;
			}.defer(1);

			taskKillAll.stop;
		});

		bounceTask = Task.new({
			var amplitude, timeBetweenBounces, timeEnroled = 0, color = Color(rrand(0.125, 1), rrand(0.125, 1), rrand(0.125, 1), rrand(0.25, 0.4));

			amplitude = (velocity.squared + (2*height*gravity)).sqrt;

			inf.do({
				var mappedAmplitude, changeBartokRoll,
				duration, velocityFactor, ampEnv, bandFreq, bandRq;

				amplitude = amplitude * loss;

				//("|--> bounceTask: cur amp = " ++ amplitude).postln;

				if((amplitude < ~bounceAmplitudeTresh) || (amplitude > 8.0) , {
					//"|--> bounceTask: stopped".postln;
					taskKillAll.play;

					if(amplitude > 8, {
						"//".postln;
						velocity.postln;
						height.postln;
						gravity.postln;
						loss.postln;
						"//".postln;
					});

					bounceTask.stop;
				});

				velocityFactor = rrand(minMaxVelocityFactor[0], minMaxVelocityFactor[1]);
				bandFreq = rrand(minMaxBandFreq[0], minMaxBandFreq[1]);
				bandRq = rrand(minMaxBandRq[0], minMaxBandRq[1]);
				mappedAmplitude = amplitude.linlin(0.0, 7.0, 0.0, 1.2);
				//{Out.ar([0,1], (SinOsc.ar(440) * EnvGen.kr(Env.perc) * 0.1))}.play;


				duration = ~vecBartokSoundFilesBuffers[chosenIndex].duration * velocityFactor;

				newAttackSynth = Synth(\play1ChBuff, [
					\buffNum, ~vecBartokSoundFilesBuffers[chosenIndex].bufnum,
					\secInit, 0,
					\secEnd, duration,
					\velocityFactor, velocityFactor,
					\ampEnv, Env.new([0, mappedAmplitude, 0], [0.01, duration]),
					\bandFreq, bandFreq,
					\bandRq, bandRq,
					\outbus, bounceBus
				], bounceGroup);

				~funcInstantiateNewAmbiObj.value(
					aziEnv: Env([aziEnv.at(timeEnroled), aziEnv.at(timeEnroled)], [0.1]),
					rhoEnv: Env([rhoEnv.at(timeEnroled), rhoEnv.at(timeEnroled)], [0.1]),
					ampEnv: Env.new([0, mappedAmplitude, 0], [0.01, duration]),
					curAzi: 0,
					curRho: 1,
					curSize: 0,
					curColor: color,
					objType: 0,
					timeToDeath: duration
				);

				changeBartokRoll = rrand(0.0, 1.0);

				if(changeBartokRoll < changeBartokChance, {
					chosenIndex = bartokFilesIndexes.choose;
				});

				timeBetweenBounces = ((2*amplitude)/gravity);

				//("|--> bounceTask:cur time = " ++ timeBetweenBounces).postln;

				timeBetweenBounces.wait;
				timeEnroled = timeEnroled + timeBetweenBounces;
			});
		}, SystemClock);

		bounceTask.play;

		taskKillAll;
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

					if(~curRMSTrigger == ~rmsTriggerTypes[\bartok], {
						if(~numBouncesActive <= 30, {
							~funcBounce.value();
						});
					}, {

						if((~curRMSTrigger == ~rmsTriggerTypes[\bridge]) && (~numBridgesActive <= 30) , {
							if((~currentEvent == 13) && (inputIndex == 1), {
								var taskKill;

								{
									taskKill = ~funcBridgeNoise.value(
										possibleIndexes: [0],
										possibleDirections: [0],
										minMaxBandFreq: [1500, 2000],
										minMaxFadeInDur: [1, 3],
										minMaxFadeOutDur: [3, 4],
										rhoMixMaxDeviation: [0.7, 0.9],
										groupFadeIn: 1.5,
										groupFadeOut: 0.1
									);
									~vecKillTasks = ~vecKillTasks.add(
										taskKill
									);
									taskKill = ~funcBridgeNoise.value(
										possibleIndexes: [0],
										possibleDirections: [0],
										minMaxBandFreq: [1500, 2000],
										minMaxFadeInDur: [1, 3],
										minMaxFadeOutDur: [3, 4],
										rhoMixMaxDeviation: [0.7, 0.9],
										groupFadeIn: rrand(2.5, 4),
										groupFadeOut: 0.1
									);
									~vecKillTasks = ~vecKillTasks.add(
										taskKill
									);
									taskKill = ~funcBridgeNoise.value(
										possibleIndexes: [0],
										possibleDirections: [0],
										minMaxBandFreq: [1500, 2000],
										minMaxFadeInDur: [1, 3],
										minMaxFadeOutDur: [3, 4],
										rhoMixMaxDeviation: [0.7, 0.9],
										groupFadeIn: rrand(2.5, 4),
										groupFadeOut: 0.1
									);
									~vecKillTasks = ~vecKillTasks.add(
										taskKill
									);

									~rmsTriggerActive = false;
								}.fork;
							}, {
								var taskKill;
								if(rrand(0, 1.0) > 0.85, {
									taskKill = ~funcBridgeNoise.value(
										possibleIndexes: [0,1],
										possibleDirections: [0],
										minMaxBandFreq: [1500, 2000],
										minMaxFadeInDur: [1, 3],
										minMaxFadeOutDur: [3, 4],
										rhoMixMaxDeviation: [0.7, 0.9],
										groupFadeIn: 2,
										groupFadeOut: 16
									);
									~vecKillTasks = ~vecKillTasks.add(taskKill);
								}, {
									taskKill = ~funcBridgeNoise.value(
										possibleDirections: [0, -1, 1],
										minMaxBandFreq: [750, 10000],
										groupFadeIn: 1,
										groupFadeOut: 2
									);
									~vecKillTasks = ~vecKillTasks.add(taskKill);
								});
							});
						});
					});
				})
			});
		});
	};
}.fork(SystemClock);
)