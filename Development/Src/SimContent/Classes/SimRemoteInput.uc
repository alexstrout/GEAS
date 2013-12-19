/*
 * TODO document this
 */
class SimRemoteInput extends UDKPlayerInput within SimRemoteController;

var float aVThrottle;
var float aVStrafe;
var float aVRise;
var float aVYaw;
var float aVPitch;
var float aVRoll;

event PreProcessInput(float DeltaTime)
{
	aBaseY = aVThrottle;
	aStrafe = aVStrafe;
	aUp = aVRise;
	aTurn = aVYaw;
	aLookUp = aVPitch;

	//These need to be set for vehicles
	RawJoyUp = aBaseY;
	RawJoyRight = aStrafe;
	RawJoyLookRight = aTurn;
	RawJoyLookUp = aLookUp;

	//`Log(Self @ "aBaseY" @ aBaseY @ "aStrafe" @ aStrafe @ "aUp" @ aUp @ "aTurn" @ aTurn @ "aLookUp" @ aLookUp);
}

//Resolve remote inputs received from our SimRemoteController
function ResolveInputs(string Line)
{
	switch (Left(Line, 1)) {
		case "p":
			//Reserved for testing
			//Sets a "RandomizeInputs" attract mode to easily test a bunch of agents moving around at once
			if (float(Split(Line, " ", true)) > 0)
				SetTimer(3.0 * FRand() + 1.0, true, 'RandomizeInputs');
			else
				ClearTimer('RandomizeInputs');
			break;
		case "t":
			aVThrottle = float(Split(Line, " ", true)) / 100.0;
			break;
		case "s":
			aVStrafe = float(Split(Line, " ", true)) / 100.0;
			break;
		case "r":
			aVRise = float(Split(Line, " ", true)) / 100.0;
			break;
		case "x":
			aVYaw = float(Split(Line, " ", true)) / 100.0;
			break;
		case "y":
			aVPitch = float(Split(Line, " ", true)) / 100.0;
			break;
		case "z":
			aVRoll = float(Split(Line, " ", true)) / 100.0;
	}
}

//Randomize inputs (usually called from timer for a sort of "attract mode")
function RandomizeInputs()
{
	aVThrottle = 2.0 * FRand() - 1.0;
	aVStrafe = 2.0 * FRand() - 1.0;
	aVRise = 2.0 * FRand() - 1.0;
	aVYaw = 2.0 * FRand() - 1.0;
	aVPitch = 2.0 * FRand() - 1.0;
	aVRoll = 2.0 * FRand() - 1.0;
}

defaultproperties
{
}
