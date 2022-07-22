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
						}.fork(AppClock)
					},
					5, {
						{
						}.fork(AppClock)
					},
					6, {
						{
						}.fork(AppClock)
					},
					7, {
						{
						}.fork(AppClock)
					},
					8, {
						{
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
					~vecIn1RMS = ~vecIn1RMS.add(message[3]);
					~in1MultiSliderView.value = ~vecIn1RMS;
				}.fork(AppClock);

				{
					(~rmsTriggerActive == true).if({
						~funcRMSTriggerElectronics.value(0, message[3]);
					});
				}.fork(SystemClock);

			}, '/in1PeakRMS');
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{
					~vecIn2RMS.removeAt(0);
					~vecIn2RMS = ~vecIn2RMS.add(message[3]);
					~in2MultiSliderView.value = ~vecIn2RMS;
				}.fork(AppClock);

				{
					(~rmsTriggerActive == true).if({
						~funcRMSTriggerElectronics.value(1, message[3]);
					});
				}.fork(SystemClock);
			}, '/in2PeakRMS', s.addr);
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{

				}.fork(AppClock);
			}, '/outDecoderPeakRMS', s.addr);
		);

		~vecOSCFuncsVu = ~vecOSCFuncsVu.add(
			OSCFunc({
				arg message;
				{

				}.fork(AppClock);
			}, '/outReverbPeakRMS', s.addr);
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
}.fork(SystemClock);
)