/**
 * SimRemoteInput - GEAS 2013, Alex Strout
 * Handles the actual input for our controller
 * As a bonus, also allows SimRemoteController to control anything a player normally would be able to
 */
class SimRemoteInput extends UDKPlayerInput within SimRemoteController;

//Input axis overrides set from the socket connection
var float aVThrottle; //Forward-Backward
var float aVStrafe; //Side-Side
var float aVRise; //Up-Down
var float aVYaw; //Yaw (X Rotation)
var float aVPitch; //Pitch (Y Rotation)
var float aVRoll; //Roll (Z Rotation)

//Input code is normally handled by the ProcessInput event - it's big and messy we just don't want to mess with it
//However, PreProcessInput gives us a chance to prepare some of our own input handling if we'd like
//For most games, this is a good place to do input sensitivity adjustments etc.
//Here, we're going to use this to override inputs that would normally be coming from a player
//We actually don't need to explicitly do this, as SimRemoteController reads vehicle control from the aV* inputs directly
//However, this also allows us to control anything else a player might normally control
//See Engine::PlayerInput.PreProcessInput() and Engine::PlayerInput.ProcessInput()
event PreProcessInput(float DeltaTime)
{
	aBaseY = aVThrottle;
	aStrafe = aVStrafe;
	aUp = aVRise;
	aTurn = aVYaw;
	aLookUp = aVPitch;

	//These also need to be set for non-SimVehicle pawns
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

	//Possibly set inputs based on the axis passed in (if any)
	//Split will take anything after the space as the magnitude of input for that axis
	//e.g. t 100 = throttle set to 1.00 (100%)
	//Magnitude will default to 0 if nothing was passed
	//e.g. t = throttle set to 0.00 (0%)
	F = float(Split(Line, " ", true)) / 100.0;
	switch (Left(Line, 1)) {
		//Reserved for testing
		//Sets a "RandomizeInputs" attract mode that will result in agent randomly moving around
		//Nice for easily testing a bunch of agents moving around at once
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
