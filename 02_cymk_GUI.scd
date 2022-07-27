(
AppClock.sched(0,{
	var margin = ~defaultGUIMargin,
	    windowWidthProp = 0.72,
	    windowHeightProp = 0.75,

	    ambisonicsCircleDiameter = 0,
	    ambisonicsCenterPoint = Point.new(),

	    eventStaticText,

	    widthOffset = 0,
	    heightOffset = 0
	;

	//--------------- guiGeneral config
	~guiGeneralWinWidth = ~avaibleBounds.width * windowWidthProp;
	~guiGeneralWinHeight = ~avaibleBounds.height * windowHeightProp;
	~guiGeneralWin = Window.new(
		"cymk_GUI",
		Rect((~avaibleBounds.width - ~guiGeneralWinWidth)/2, (~avaibleBounds.height - ~guiGeneralWinHeight)/2, ~guiGeneralWinWidth, ~guiGeneralWinHeight),
		false
	).background_(Color.hsv(0.65,0.1,0.3,0.3)).front;
	~guiGeneralWin.alpha = 0.9;
	~guiGeneralWin.onClose = {

		"-->> stopping code...".postln;

		"--> removing ambiObjects".postln;
		~vecAmbiObjects.do({
			arg ambiObject;

			ambiObject.updateTask.stop;
			ambiObject.updateTask.free;

			~funcRemoveWithId.value(ambiObject.id);
		});

		~vecAmbiObjectsRoutes = [ ];

		"--> stopping ambisonics window refresh".postln;
		~userViewAmbisonicsRefreshTask.stop;

		"--> freeing buffers".postln;
		~vecSoundFilesBuffers.do({
			arg buffer;

			buffer.free;
		});

		"--> freeing decoder...".postln;
		if(~mainDecoder.isNil == false, {
			~mainDecoder.free;
		});
		~speakerDecoder.free;
		~binauralDecoder.free;
		"|--> decoder and decoderSynth freed".postln;

		s.freeAll;
		"\n|--------> code stopped <--------|".postln;

		if(~record == true, {
			"--> saving file...".postln;
			s.stopRecording;
		});

		MIDIdef.freeAll;
		MIDIIn.disconnectAll;
		MIDIClient.disposeClient;

		~vecOSCFuncsVu.do({
			arg oscFuncVu;

			oscFuncVu.free;
		});

		~pedalCooldownTask.stop;
		~pedalCooldownTask.free;
	};

	~guiGeneralWin.view.keyDownAction = {
		arg view, char, modifiers, unicode, keycode;

		//keycode.postln;

		(keycode == 32).if({
			~funcPlayNextEvent.value();
			~currentEventStaticText.string = (~currentEvent - 2);
		}, {
			if(keycode == 37, {
				~currentSystemNumber = ~currentSystemNumber - 1;
				~funcUpdateScoreWebView.value(~currentSystemNumber);
			}, {
				if(keycode == 39, {
					~currentSystemNumber = ~currentSystemNumber + 1;
					~funcUpdateScoreWebView.value(~currentSystemNumber);
				});
			});
		});
	};

	~compsBgWidth = ~guiGeneralWinWidth - (2*margin);
	~compsBgHeight = ~guiGeneralWinHeight - (2*margin);
	~compsBg = CompositeView(~guiGeneralWin,Rect(margin,margin,~compsBgWidth, ~compsBgHeight)).background_(Color.hsv(0.66,0.8,0.4,0.3));

	~textSizeGeneral = ~guiGeneralWinHeight/58;

	//--------------- errorWin
	~errorWinWidth = ~guiGeneralWinWidth;
	~errorWinHeigth = ~guiGeneralWinHeight/2;

	//--------------- pendrawings indexing and Ambisonics UserView
	~ambisonicsCircleDiameter = ~guiGeneralWinWidth/4;
	ambisonicsCenterPoint = Point.new((~ambisonicsCircleDiameter/2) + margin, (~ambisonicsCircleDiameter/2) + margin);

	~userViewAmbisonics = UserView.new(
		~guiGeneralWin, Rect(margin*3, margin*3, ~ambisonicsCircleDiameter + (2*margin), ~ambisonicsCircleDiameter + (2*margin))
	);
	~userViewAmbisonics.frameRate = ~fps;
	~userViewAmbisonics.animate = true;
	~userViewAmbisonics.background_(Color(150/255, 150/255, 210/255, 0.2));

	//--------------- Pen drawings
	~userViewAmbisonics.drawFunc = {
		//-- ambisonics circle
		Pen.strokeColor = Color.new(210/255, 51/255, 0, 1);
		Pen.fillColor = Color.new(50/255, 50/255, 90/255, 0.85);
		Pen.addArc(ambisonicsCenterPoint, ~ambisonicsCircleDiameter/2, pi, pi);
		Pen.addArc(ambisonicsCenterPoint, ~ambisonicsCircleDiameter/2, -pi, -pi);
		Pen.width = 1;
		Pen.draw(3);

		if(~vecAmbiObjects.size >= 1, {
			for(0, ~vecAmbiObjects.size - 1, {
				arg index;
				var aziEnvLevelArray, rhoEnvLevelArray, curAzi, curRho, curSize, curPoint = Point.new();

				if(~vecAmbiObjects[index].type == ~ambiObjTypes[\general], {
					//aziEnvLevelArray = ~vecAmbiObjects[index].azimuthEnvelope.levels;
					//rhoEnvLevelArray = ~vecAmbiObjects[index].rhoEnvelope.levels;
					curSize = ~minAmbiObjSize + (~vecAmbiObjects[index].currentSize * (~maxAmbiObjSize - ~minAmbiObjSize));
					curPoint.x = ambisonicsCenterPoint.x + ~vecAmbiObjects[index].currentPoint.x;
					curPoint.y = ambisonicsCenterPoint.y + ~vecAmbiObjects[index].currentPoint.y;

					Pen.fillColor = ~vecAmbiObjects[index].color;
					Pen.addArc(curPoint, curSize,  pi, pi);
					Pen.addArc(curPoint, curSize,  -pi, -pi);
					Pen.width = 1;
					Pen.draw(0);
				});
			});
		});

		if(~vecAmbiObjectsRoutes.size >= 1, {
			for(0, ~vecAmbiObjectsRoutes.size - 1, {
				arg index;
				var routePoint, curRho, curAzi, curSize, curPoint = Point.new();

				curRho = 0.95;
				curSize = ~minAmbiObjSize + (~vecAmbiObjectsRoutes[index].currentSize * (~maxAmbiObjSize - ~minAmbiObjSize));
				curAzi = (~vecMIDIKnobsValues[~vecAmbiObjectsRoutes[index].azimuthKnobIndex].linlin(0.0, 1.0, -pi, pi) -(pi/2));
				routePoint = Polar.new(curRho, curAzi).scale(~ambisonicsCircleDiameter/2).asPoint;

				Pen.fillColor = ~vecAmbiObjectsRoutes[index].color;
				Pen.addRect(Rect(routePoint.x + ambisonicsCenterPoint.x - (curSize/2), routePoint.y + ambisonicsCenterPoint.y - (curSize/2), curSize, curSize));
				Pen.width = 1;
				Pen.draw(0);
			});
		});
	};

	widthOffset = (margin * 3);
	heightOffset = (margin * 5) + ~ambisonicsCircleDiameter + (2*margin);

	// ----- COMPS CONTROL
	~compsControl = CompositeView(~guiGeneralWin, Rect(widthOffset, heightOffset, 2.75 * (~ambisonicsCircleDiameter + (2*margin)), ~compsBgHeight - (~ambisonicsCircleDiameter + (8*margin))));
	~compsControl.background_(Color(210/255, 120/255, 70/255, 0.55));

	// ---------- COMPS IN LEVEL CONTROL
	~compsInLevels = CompositeView(~compsControl, Rect(margin, margin, ~ambisonicsCircleDiameter + margin, ~compsControl.bounds.height - (2*margin)));
	~compsInLevels.background_(Color(0.85, 0.85, 0.85, 0.5));

	// --------------- IN1
	~in1BgLevelSlider = Slider(~compsInLevels, Rect(margin, margin, ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (margin)));
	~in1BgLevelSlider.thumbSize = 10;
	~in1BgLevelSlider.knobColor = Color(180/255, 50/255, 50/255, 1);

	widthOffset = ~in1BgLevelSlider.bounds.width + margin;

	~in1MultiSliderView = MultiSliderView(~compsInLevels, Rect(widthOffset, margin, ~compsInLevels.bounds.width - (2*widthOffset), (~compsInLevels.bounds.height/2) - (margin)));
	~in1MultiSliderView.background_(Color(30/255, 30/255, 70/255, 0.5));
	~in1MultiSliderView.size = ~fps * ~inLevelSlidersDur;
	~in1MultiSliderView.value = ~vecIn1RMS;
	~in1MultiSliderView.elasticMode = 1;
	~in1MultiSliderView.drawLines = true;
	~in1MultiSliderView.isFilled = true;
	~in1MultiSliderView.thumbSize = 0.1;
	~in1MultiSliderView.colors_(Color(0.8, 0.8, 0.8, 1), Color(0.8, 0.8, 0.8, 1));

	widthOffset = ~in1BgLevelSlider.bounds.width + margin + ~in1MultiSliderView.bounds.width;

	~in1LevelSlider = Slider(~compsInLevels, Rect(widthOffset, margin, ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (margin)));
	~in1LevelSlider.thumbSize = 10;
	~in1LevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	// --------------- IN2
	heightOffset = ~in1BgLevelSlider.bounds.height + (2*margin);

	~in2BgLevelSlider = Slider(~compsInLevels, Rect(margin, heightOffset, ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (margin)));
	~in2BgLevelSlider.thumbSize = 10;
	~in2BgLevelSlider.knobColor = Color(180/255, 50/255, 50/255, 1);

	widthOffset = ~in2BgLevelSlider.bounds.width + margin;

	~in2MultiSliderView = MultiSliderView(~compsInLevels, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width - (2*widthOffset), (~compsInLevels.bounds.height/2) - (margin)));
	~in2MultiSliderView.background_(Color(30/255, 30/255, 70/255, 0.5));
	~in2MultiSliderView.size = ~fps * ~inLevelSlidersDur;
	~in2MultiSliderView.value = ~vecIn2RMS;
	~in2MultiSliderView.elasticMode = 1;
	~in2MultiSliderView.drawLines = true;
	~in2MultiSliderView.isFilled = true;
	~in2MultiSliderView.thumbSize = 0.5;
	~in2MultiSliderView.colors_(Color(0.8, 0.8, 0.8, 1), Color(0.8, 0.8, 0.8, 1));

	widthOffset = ~in2BgLevelSlider.bounds.width + margin + ~in2MultiSliderView.bounds.width;

	~in2LevelSlider = Slider(~compsInLevels, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (margin)));
	~in2LevelSlider.thumbSize = 10;
	~in2LevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	// ----- LEVEL INDICATORS
	widthOffset = ~compsInLevels.bounds.width + (2*margin);
	~in1LevelIndicator = LevelIndicator(~compsControl, Rect(widthOffset + (~compsInLevels.bounds.width/15), 3*margin, ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (4*margin)))
	.numTicks_(11)
	.drawsPeak_(true)
	.warning_(0.75)
	.critical_(0.8);

	heightOffset = ~compsInLevels.bounds.height/2;
	~in2LevelIndicator = LevelIndicator(~compsControl, Rect(widthOffset + (~compsInLevels.bounds.width/15), heightOffset + (3*margin), ~compsInLevels.bounds.width/15, (~compsInLevels.bounds.height/2) - (4*margin)))
	.numTicks_(11)
	.drawsPeak_(true)
	.warning_(0.75)
	.critical_(0.8);

	widthOffset = ~compsInLevels.bounds.width + (3*margin)  + (2*(~compsInLevels.bounds.width/15));
	heightOffset = ~compsControl.bounds.height/4 - margin;
	~liveRoutesOutLevelSlider = Slider(~compsControl, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width/15, (~compsControl.bounds.height/2) + (2*margin)));
	~liveRoutesOutLevelSlider.thumbSize = 10;
	~liveRoutesOutLevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	widthOffset = (~compsControl.bounds.width/2);
	~electronicsOutLevelSlider = Slider(~compsControl, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width/15, (~compsControl.bounds.height/2) + (2*margin)));
	~electronicsOutLevelSlider.thumbSize = 10;
	~electronicsOutLevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	widthOffset = widthOffset + (2*margin) + (~compsInLevels.bounds.width/15);
	~electronicsLevelIndicators = Array.fill(4, {
		arg index;
		var plusOffset;

		plusOffset = index * ~compsInLevels.bounds.width/15;
		LevelIndicator(~compsControl, Rect(widthOffset+plusOffset, heightOffset + margin, ~compsInLevels.bounds.width/15, ~compsControl.bounds.height/2))
		.numTicks_(11)
		.drawsPeak_(true)
		.warning_(0.75)
		.critical_(0.8);
	});

	widthOffset = widthOffset + (2*margin) + (7*(~compsInLevels.bounds.width/15));
	heightOffset = ~compsControl.bounds.height/4 - margin;
	~reverbOutLevelSlider = Slider(~compsControl, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width/15, (~compsControl.bounds.height/2) + (2*margin)));
	~reverbOutLevelSlider.thumbSize = 10;
	~reverbOutLevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	widthOffset = widthOffset + (2*margin) + (~compsInLevels.bounds.width/15);
	~reverbLevelIndicators = Array.fill(4, {
		arg index;
		var plusOffset;

		plusOffset = index * ~compsInLevels.bounds.width/15;
		LevelIndicator(~compsControl, Rect(widthOffset+plusOffset, heightOffset + margin, ~compsInLevels.bounds.width/15, ~compsControl.bounds.height/2))
		.numTicks_(11)
		.drawsPeak_(true)
		.warning_(0.75)
		.critical_(0.8);
	});


	widthOffset = ~compsControl.bounds.width - (2*margin) - (4*(~compsInLevels.bounds.width/15));
	heightOffset = ~compsControl.bounds.height/4 - margin;
	~speakersOutLevelSlider = Slider(~compsControl, Rect(widthOffset, heightOffset, ~compsInLevels.bounds.width/15, (~compsControl.bounds.height/2) + (2*margin)));
	~speakersOutLevelSlider.thumbSize = 10;
	~speakersOutLevelSlider.knobColor = Color(50/255, 180/255, 50/255, 1);

	widthOffset = widthOffset + (2*margin) + (~compsInLevels.bounds.width/15);
	~speakersOutLevelIndicators = Array.fill(2, {
		arg index;
		var plusOffset;

		plusOffset = index * ~compsInLevels.bounds.width/15;
		LevelIndicator(~compsControl, Rect(widthOffset+plusOffset, heightOffset + margin, ~compsInLevels.bounds.width/15, ~compsControl.bounds.height/2))
		.numTicks_(11)
		.drawsPeak_(true)
		.warning_(0.75)
		.critical_(0.8);
	});

	widthOffset = ~compsControl.bounds.width + (5*margin);
	heightOffset = ~userViewAmbisonics.bounds.height + (5*margin);

	// ----- COMPS EVENTS
	~compsEvents = CompositeView(~guiGeneralWin, Rect(widthOffset, heightOffset, ~guiGeneralWinWidth - widthOffset - (2*margin), ~guiGeneralWinHeight - heightOffset - (3*margin)));
	~compsEvents.background_(Color(140/255, 210/255, 90/255, 0.55));

	eventStaticText = StaticText(~compsEvents, Rect(margin*10, margin*5, ~compsEvents.bounds.width/2, ~compsEvents.bounds.height/5))
	.align_(\left)
	.font_(Font("Avenir", 20))
	.stringColor_(Color.fromHexString("222222"))
	.string_("~currentEvent:");

	~currentEventStaticText = StaticText(~compsEvents, Rect((~compsEvents.bounds.width/2) - (margin*2), margin*3, ~compsEvents.bounds.width/2, ~compsEvents.bounds.height/5))
	.align_(\center)
	.font_(Font("Avenir", 65))
	.stringColor_(Color.fromHexString("FF3333"))
	.string_((~currentEvent - 2).asString);

	// ----- COMPS SCORE
	widthOffset = ~userViewAmbisonics.bounds.width + (5*margin);
	heightOffset = 3*margin;
	~compsScore =  CompositeView(~guiGeneralWin, Rect(widthOffset, heightOffset, ~guiGeneralWinWidth - (widthOffset + (2*margin)), ~guiGeneralWinHeight - (heightOffset + margin + ~compsEvents.bounds.height + (4*margin))));
	~compsScore.background_(Color(80/255, 110/255, 130/255, 0.55));

	~scoreWebView = WebView.new(~compsScore, Rect(margin,margin,~compsScore.bounds.width - (margin*2),~compsScore.bounds.height- (margin*2))).url_((
		Document.current.dir +/+ "score" +/+ ~scoreSystems[0]).standardizePath).canFocus_(false).acceptsMouse_(false);

});
)