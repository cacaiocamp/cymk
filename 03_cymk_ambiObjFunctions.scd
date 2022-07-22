(
{
	~funcInstantiateNewAmbiObj = {
		arg aziEnv, rhoEnv, ampEnv, curAzi, curRho, curSize, curColor, objType = ~ambiObjTypes[\general], timeToDeath,
		    aziKnobIndex = nil;
		var newAmbiObj;

		~nodeCounter = ~nodeCounter + 1;

		newAmbiObj = ~newAmbiObj.value(
			ambiObjCount: ~nodeCounter,
			aziEnv: aziEnv,
			rhoEnv: rhoEnv,
			ampEnv: ampEnv,
			curAzi: curAzi,
			curRho: curRho,
			curSize: curSize,
			curColor: curColor,
			objType: objType,
			aziKnobIndex: aziKnobIndex,
			timeToDeath: timeToDeath
		);

		if(objType == ~ambiObjTypes[\general], {
			~vecAmbiObjects = ~vecAmbiObjects.add(newAmbiObj);
			~vecAmbiObjects.last.addUpdateAmbiObjTask.value();
		}, {
			~vecAmbiObjectsRoutes = ~vecAmbiObjectsRoutes.add(newAmbiObj);
		});
	};

	~funcRemoveWithId = {
		arg idToRemove;
		var index = 0;

		while ( { index < (~vecAmbiObjects.size())}, {
			if(~vecAmbiObjects[index].id == idToRemove,{
				~vecAmbiObjects.removeAt(index);
				index = ~vecAmbiObjects.size();
			});

			index = index + 1;
		});
	};

	~funcRemoveAllRoutesAmbiObj = {
		arg delay = 0;
		var index = 0;

		{
			delay.wait;
			while ( { index != (~vecAmbiObjectsRoutes.size())}, {
				~vecAmbiObjectsRoutes.removeAt(index);
			});
		}.fork();
	};
}.fork(SystemClock);
)