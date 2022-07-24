// --- Ambisonics config
~binauralOut = false;
//~outSetup = \binauralOnly;
~outSetup = \stereo;
~mainDecoder = nil;
~speakerDistance = 1;
~speakerBuses = [0,1];

// --- In/Out devices config
//~outDevice, "CABLE Input";
~outDevice = nil;
~nodeCounter = 0;
//~outDevice = "AudioBox ASIO Driver";
~violin_busNum = 18; //input0 after 18 outputs
~cello_busNum = 19; //input1 after 18 outputs --- seek Server config

// -- MIDI controller config
//MIDIClient.sources;
~midiSourceIndex = 0;
~vecMIDIChannelsToWatch = (3..11) ++ (14..22) ++ (23..31); //faders ++ knobs ++ buttons vector
~vecMIDIFadersValues = Array.fill(9, {0});
~vecMIDIKnobsValues = Array.fill(9, {0.5});
~vecMIDIButtonsValues = Array.fill(9, {0});
~vecMIDIFadersBuses = Array.fill(9, {0});
~vecMIDIKnobsBuses = Array.fill(9, {0});
// --- Other configs
~record = false;
~withMidiController = false;

// --- Dictionaries
~ambiObjTypes = Dictionary.newFrom(List[\general, 0, \instRoute, 1]);
~rmsTriggerTypes = Dictionary.newFrom(List[\bartok, 0, \bridge, 1]);

// --- DEFAULT GUI values
~avaibleBounds = Window.screenBounds;  //- Rect containing the maximum width and height for the Views
~defaultGUIMargin = 3;

// --- Other DEFAULT values
~fps = 30;
~inLevelSlidersDur = 10; //seconds
~minAmbiObjSize = 2;
~maxAmbiObjSize = 12;
~pedalCooldownStep = 0.125;
~pedalCooldownTresh = 1.5;
~in1Color = Color(255/255, 200/255, 200/255, 0.6);
~in2Color = Color(200/255, 255/255, 180/255, 0.6);
~numPizzFiles = 12;
~numBartokFiles = 14;
~numBridgeFiles = 9;

// --- GUI vecs
~vecIn1RMS = Array.fill(~fps * ~inLevelSlidersDur, {1});
~vecIn2RMS = Array.fill(~fps * ~inLevelSlidersDur, {1});
~vecOSCFuncsVu = [];
~vecOSCTagSymbols = ['/in1PeakRMS', '/in2PeakRMS'];

// --- Initialisations
~vecAmbiObjects = [];
~vecAmbiObjectsRoutes = [];
~vecPizzSoundFilesBuffers = [];
~vecBartokSoundFilesBuffers = [];
~vecBridgeSoundFilesBuffers = [];
~currentEvent = -1;
~pedalCooldown = 0;
~pedalAvaible = true;

//pizz initizialization
~minTimeBetweenPizz = 1.75; ~maxTimeBetweenPizz = 4.25;
~minRandomPizzAzi = -pi; ~maxRandomPizzAzi = pi;
~minRandomPizzVelocityFactor = 0.95; ~maxRandomPizzVelocityFactor = 1.05;
~minRandomPizzFreq = 250.0; ~maxRandomPizzFreq = 2500.0;
~minRandomPizzRq = 0.8; ~maxRandomPizzRq = 4.0;
~minRandomPizzAmp = 0.35; ~maxRandomPizzAmp = 0.5;

//rms trigger initialization
~rmsTriggerActive = false;
~triggerOffFactor = -0.05;
~cooldownTriggerDur = 0;
~inputTriggered = Array.fill(2, {false});
~inputTriggerCooldown = Array.fill(2, {false});
~curRMSTrigger = ~rmsTriggerTypes[\bartok];

//bounce initialization
~bounceAmplitudeTresh = 0.1;
~numBouncesActive = 0;

//bridge initialization
~vecKillTasks = [];
~numBridgesActive = 0;

// --- Server config
s = Server.local;
o = s.options;
o.device = ~outDevice;
s.options.memSize = 16384;
s.options.numInputBusChannels = 2;
s.options.numOutputBusChannels = 18;
s.options.blockSize = 64;
s.options.sampleRate = 48000;
(
s.boot;

~mainroutine = Routine({

	s.waitForBoot({
		{
			var soundsPath = PathName.new(Document.current.dir +/+ "sounds/"), soundFileCount = 0;

			"|--> starting code".postln;
			"|--> freeing allocators".postln;
			s.newAllocators;
			s.sync;

			"|--> alloc sound file buffers".postln;
			soundsPath.files.do({
				arg pathName;
				var buffer;

				buffer = Buffer.read(s, pathName.fullPath);

				if(soundFileCount < ~numPizzFiles, {
					~vecPizzSoundFilesBuffers = ~vecPizzSoundFilesBuffers.add(buffer);
				}, {
					if(soundFileCount < (~numPizzFiles + ~numBartokFiles), {
						~vecBartokSoundFilesBuffers = ~vecBartokSoundFilesBuffers.add(buffer);
					}, {
						if(soundFileCount < (~numPizzFiles + ~numBartokFiles + ~numBridgeFiles), {
							~vecBridgeSoundFilesBuffers = ~vecBridgeSoundFilesBuffers.add(buffer);
						});
					});
				});

				soundFileCount = soundFileCount + 1;
			});
			s.sync;
			"|--> sound file buffers alloced".postln;

			if(~record == true, {
				{
					s.prepareForRecord(Document.current.dir +/+ "recs" +/+ "rec_0.wav", 14);
					s.sync;
					s.recHeaderFormat = "wav";
					s.sync;
					s.record;
					(0.02).wait;
				}.fork();
			});

			// define encoder / decoder matrices
			~encoder = FoaEncoderMatrix.newDirection;

			if(~binauralOut == true, {
				~binauralDecoder = FoaDecoderKernel.newCIPIC;
			});
			s.sync;

			if(~outSetup != \binauralOnly, {
				if(~outSetup == \stereo, {
					~mainDecoder = FoaDecoderMatrix.newStereo;
				});
			});
			s.sync;

			//documentos
			this.executeFile(Document.current.dir +/+ "01_cymk_eventClasses.scd");
			this.executeFile(Document.current.dir +/+ "02_cymk_GUI.scd");
			this.executeFile(Document.current.dir +/+ "03_cymk_ambiObjFunctions.scd");
			this.executeFile(Document.current.dir +/+ "04_cymk_synthDefs.scd");
			this.executeFile(Document.current.dir +/+ "05_cymk_functions.scd");
			this.executeFile(Document.current.dir +/+ "06_cymk_synthFunctions.scd");
			this.executeFile(Document.current.dir +/+ "07_cymk_events.scd");
			s.sync;

			//groups
			~group_master = Group.new();
			~group_liveRoute = Group.new(~group_master, \addToHead);
			~group_electronics = Group.new(~group_liveRoute, \addAfter);
			~group_reverb = Group.new(~group_electronics, \addAfter);
			~group_decoders = Group.new(~group_master, \addToTail); //needs to be the last group
			s.sync;

			//audio buses
			~busA_speakersOut = Bus.new('audio',~speakerBuses[0], 2); //0-1
			s.sync;

			~busA_BF_toDecode = Bus.new('audio', 2, 4, s); //2-5
			~busA_BF_liveRoute = Bus.new('audio', 6, 4, s); //6-9
			~busA_BF_electronics = Bus.new('audio', 10, 4, s); //10-13
			~busA_BF_reverb = Bus.new('audio', 14, 4, s); //14-17
			s.sync;

			~busA_violinIn = Bus.new('audio', ~violin_busNum, 1, s);
			~busA_celloIn = Bus.new('audio', ~cello_busNum, 1, s);
			s.sync;

			(//midi worldeasycontrol control buses - 9 faders, 9 knobs
				~vecMIDIFadersBuses = 9.collect({
					var faderBus;

					faderBus = Bus.control(s, 1);
				});
				s.sync;

				~vecMIDIKnobsBuses = 9.collect({
					var knobBus;

					knobBus = Bus.control(s, 1);
				});
				s.sync;
			);

			2.do({
				var aziEnv, rhoEnv, ampEnv,
				    globalDur = 0,
				    minAzi = rrand(-2pi, 2pi), maxAzi = minAzi + rrand(0, 2pi),
				    minRho = 0, maxRho = 0.1,
				    minDur = 2, maxDur = 6,
				    newSynth
				;

				aziEnv = Env.new(
					[rrand(minAzi, maxAzi), rrand(minAzi, maxAzi), rrand(minAzi, maxAzi)],
					[rrand(minDur, maxDur), rrand(minDur, maxDur)]
				);
				rhoEnv = Env.new(
					[rrand(minRho, maxRho), rrand(minRho, maxRho), rrand(minRho, maxRho)],
					[rrand(minDur, maxDur), rrand(minDur, maxDur)]
				);
				globalDur = [aziEnv.duration, rhoEnv.duration].maxItem;
				ampEnv = Env.new(times: [globalDur/2, globalDur/2]);

				newSynth = Synth(\sinTest, [
					\freq, rrand(100, 1500),
					\freqImpulse, rrand(5, 30),
					\ampEnv, ampEnv,
					\aziEnv, aziEnv,
					\rhoEnv, rhoEnv,
					\outbus, ~busA_BF_toDecode
				], ~group_electronics);

				~funcInstantiateNewAmbiObj.value(
					aziEnv: aziEnv,
					rhoEnv: rhoEnv,
					ampEnv: ampEnv,
					curAzi: 0,
					curRho: 1,
					curSize: 0,
					curColor: Color(rrand(0.125, 1), rrand(0.125, 1), rrand(0.125, 1), 0.25),
					objType: 0,
					timeToDeath: globalDur
				);
			});


			if(~withMidiController == true, {
				MIDIClient.disposeClient;
				MIDIClient.init;
				s.sync;
				MIDIClient.sources;
				MIDIIn.connect(~midiSourceIndex);
				s.sync;

				~vecMIDIChannelsToWatch.do({
					arg midiChannelToWatch;

					~funcMapMIDIChannel.value(midiChannelToWatch);
				});

				//button to test
				MIDIdef.cc(\test1, {arg ...args; ("MIDI working!").postln; args.postln}, 1); // match cc 1, first button
				s.sync;
			});

			~funcMapOscToVUs.value();
			s.sync;

			~pedalCooldownTask = Task.new({
				inf.do({
					~pedalCooldown = ~pedalCooldown + ~pedalCooldownStep;

					(~pedalCooldown >= ~pedalCooldownTresh).if({
						~pedalAvaible = true;
					}, {
						~pedalAvaible = false;
					});

					(~pedalCooldownStep).wait;
				});
			}, SystemClock);

			~pedalCooldownTask.play;

			"\n|--------> code started <--------|".postln;

		}.fork(SystemClock);
	});
}).play(SystemClock);
)