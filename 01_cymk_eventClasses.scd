// --- Classes as Events

(
{
	// --- ambiObj Class
	~newAmbiObj = {
		arg ambiObjCount, aziEnv, rhoEnv, ampEnv, curAzi, curRho, curSize, curColor, objType, aziKnobIndex = nil, timeToDeath = 0;
		var vecCount = ambiObjCount,
		    aziEnvelope = aziEnv,
		    rhoEnvelope = rhoEnv,
		    ampEnvelope = ampEnv,
		    azimuth = curAzi,
		    rho = curRho,
		    size = curSize,
	    	color = curColor,
	    	tp = objType,
		    aziKIndex = aziKnobIndex,
		    tTD = timeToDeath
	    ;
		(
			id: vecCount,
			azimuthEnvelope: aziEnvelope,
			rhoEnvelope: rhoEnvelope,
			amplitudeEnvelope: ampEnv,

			currentAzimuth: azimuth,
			currentRho: rho,
			currentSize: size,
			color: color,
			timeUntilDeath: tTD,
			type: tp,

			azimuthKnobIndex: aziKIndex,

			timePointer: 0,
			updateTask: nil,
			currentPoint: Point.new(),

			updateAmbiObj: {
				arg self;
				var minLevel, maxLevel, curLevel;

				minLevel = self.amplitudeEnvelope.minLevel;
				maxLevel = self.amplitudeEnvelope.maxLevel;

				curLevel = self.amplitudeEnvelope.at(self.timePointer);

				self.currentSize = (curLevel - minLevel)/(maxLevel - minLevel);
				self.currentAzimuth = self.azimuthEnvelope.at(self.timePointer);
				self.currentRho = self.rhoEnvelope.at(self.timePointer);

				self.currentPoint = Polar.new((self.currentRho - 1), self.currentAzimuth - (pi/2)).scale(~ambisonicsCircleDiameter/2).asPoint;
			},

			addUpdateAmbiObjTask: {
				arg self;

				self.updateTask = Routine.new({
					inf.do({
						self.timePointer = self.timePointer + (1.0/~fps);
						self.updateAmbiObj.value();

						if((self.timePointer >= self.timeUntilDeath), {
							~funcRemoveWithId.value(idToRemove: self.id);
							self.updateTask.stop;
							self.updateTask.free;
						});
						(1.0/~fps).wait;
					});
				});

				self.updateTask.play;
			}
		)
	};

}.fork(AppClock);
)