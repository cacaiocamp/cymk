( //WORLDE easy control main faders, knobs and buttons mapping
{
	~funcMapMIDIChannel = {
		arg midiChannelToWatch;
		var faderIndexing = midiChannelToWatch - 3, knobIndexing = midiChannelToWatch - 14, buttonIndexing = midiChannelToWatch - 23;

		if(midiChannelToWatch <= 11, { //faders 3-11
			MIDIdef.cc(("fader" ++ faderIndexing.asString).asSymbol, {
				arg value;

				~vecMIDIFadersValues[faderIndexing] = value.linlin(0, 126, 0.0, 1.0);
				~vecMIDIFadersBuses[faderIndexing].set(~vecMIDIFadersValues[faderIndexing]);

				if(~vecMIDIButtonsValues[faderIndexing] == 1, {
					("MIDI: fader" ++ faderIndexing.asString ++ ": " ++ ~vecMIDIFadersValues[faderIndexing].asString).postln;
				});

				switch(faderIndexing,
					0, {
						{
							~in1BgLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					1, {
						{
							~in2BgLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					2, {
						{
							~in1LevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					3, {
						{
							~in2LevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					4, {
						{
							~liveRoutesOutLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					5, {
						{
							~electronicsOutLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					6, {
						{
						}.fork(AppClock)
					},
					7, {
						{
							~reverbOutLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					},
					8, {
						{
							~speakersOutLevelSlider.valueAction_(~vecMIDIFadersValues[faderIndexing])
						}.fork(AppClock)
					}
				);
			}, midiChannelToWatch); // match to midi channel 'midiChannelToWatch'
		}, {
			if(midiChannelToWatch <= 22, { //knobs 14-22
				MIDIdef.cc(("knob" ++ knobIndexing.asString).asSymbol, {
					arg value;

					~vecMIDIKnobsValues[knobIndexing] = value.linlin(0, 126, 0.0, 1.0);
					~vecMIDIKnobsBuses[knobIndexing].set(~vecMIDIKnobsValues[knobIndexing]);

					if(~vecMIDIButtonsValues[knobIndexing] == 1, {
						("MIDI: knob" ++ knobIndexing.asString ++ ": " ++ ~vecMIDIKnobsValues[knobIndexing].asString).postln;
					});
				}, midiChannelToWatch); // match to midi channel 'midiChannelToWatch'
			}, { //buttons 23-31
				MIDIdef.cc(("button" ++ buttonIndexing.asString).asSymbol, {
					arg value;

					~vecMIDIButtonsValues[buttonIndexing] = value.linlin(0, 127, 0, 1);
				}, midiChannelToWatch); // match to midi channel 'midiChannelToWatch'
			});
		});
	};

	~funcMapOscToVUs = {
		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					~vecIn1RMS.removeAt(0);
					~vecIn1RMS = ~vecIn1RMS.add(message[4].ampdb.linlin(-120, 0, 0, 1));
					~in1MultiSliderView.value = ~vecIn1RMS;

					~in1LevelIndicator.peakLevel = message[3].ampdb.linlin(-120, 0, 0, 1);
					~in1LevelIndicator.value = message[4].ampdb.linlin(-120, 0, 0, 1);

				}.fork(AppClock);

				{
					(~rmsTriggerActive == true).if({
						~funcRMSTriggerElectronics.value(0, message[4].ampdb.linlin(-120, 0, 0, 1));
					});
				}.fork(SystemClock);

			}, '/in1PeakRMS');
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					~vecIn2RMS.removeAt(0);
					~vecIn2RMS = ~vecIn2RMS.add(message[4].ampdb.linlin(-120, 0, 0, 1));
					~in2MultiSliderView.value = ~vecIn2RMS;

					~in2LevelIndicator.peakLevel = message[3].ampdb.linlin(-120, 0, 0, 1);
					~in2LevelIndicator.value = message[4].ampdb.linlin(-120, 0, 0, 1);
				}.fork(AppClock);

				{
					(~rmsTriggerActive == true).if({
						~funcRMSTriggerElectronics.value(1, message[4].ampdb.linlin(-120, 0, 0, 1));
					});
				}.fork(SystemClock);
			}, '/in2PeakRMS', s.addr);
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					var numChannels=2;
					numChannels.do{
						arg index;
						~speakersOutLevelIndicators[index].peakLevel = message[3+(index*2)].ampdb.linlin(-120, 0, 0, 1);
						~speakersOutLevelIndicators[index].value = message[3+(index*2)+1].ampdb.linlin(-120, 0, 0, 1);
					};
				}.fork(AppClock);
			}, '/outDecoderPeakRMS', s.addr);
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					var numChannels=4;
					numChannels.do{
						arg index;
						~reverbLevelIndicators[index].peakLevel = message[3+(index*2)].ampdb.linlin(-120, 0, 0, 1);
						~reverbLevelIndicators[index].value = message[3+(index*2)+1].ampdb.linlin(-120, 0, 0, 1);
					};
				}.fork(AppClock);
			}, '/outReverbPeakRMS', s.addr);
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					var numChannels=4;
					numChannels.do{
						arg index;
						~electronicsLevelIndicators[index].peakLevel = message[3+(index*2)].ampdb.linlin(-120, 0, 0, 1);
						~electronicsLevelIndicators[index].value = message[3+(index*2)+1].ampdb.linlin(-120, 0, 0, 1);
					};
				}.fork(AppClock);
			}, '/outElectronicsPeakRMS', s.addr);
		);
	};

	~funcPlayNextEvent = {
		if(~pedalAvaible == true, {
			~pedalCooldown = 0;
			~pedalAvaible = false;

			~currentEvent = ~currentEvent + 1;

			//("--> next event called: " ++ ~currentEvent).postln();

			~vecEvents[~currentEvent].value();
		});
	};

	~funcUpdateScoreWebView = {
		arg systemNumber;

		~scoreWebView.url_((Document.current.dir +/+ "score" +/+ ~scoreSystems[systemNumber-1]).standardizePath);
	};
}.fork(SystemClock);
)