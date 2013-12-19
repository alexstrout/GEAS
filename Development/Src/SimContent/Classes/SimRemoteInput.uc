/**

 * TODO FINISH DOCUMENTING THIS

 * SimRemoteInput - GEAS 2013, Alex Strout
 * Handles the actual input for our controller
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
	local float F;

	F = float(Split(Line, " ", true)) / 100.0;
	switch (Left(Line, 1)) {
		//Reserved for testing
		//Sets a "RandomizeInputs" attract mode to easily test a bunch of agents moving around at once
		case "p":
			if (F > 0)
				SetTimer(3.0 * FRand() + 1.0, true, 'RandomizeInputs');
			else
				ClearTimer('RandomizeInputs');
			break;
		case "t": aVThrottle = F; break;
		case "s": aVStrafe = F; break;
		case "r": aVRise = F; break;
		case "x": aVYaw = F; break;
		case "y": aVPitch = F; break;
		case "z": aVRoll = F;
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
