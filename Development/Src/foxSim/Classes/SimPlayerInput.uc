/*
 * TODO document this
 */
class SimPlayerInput extends PlayerInput within SimPlayerController;

var float aBaseYOverride;
var float aStrafeOverride;
var float aUpOverride;
var float aTurnOverride;
var float aLookUpOverride;

event PlayerInput(float DeltaTime)
{
	aBaseY = aBaseYOverride;
	aStrafe = aStrafeOverride;
	aUp = aUpOverride;
	aTurn = aTurnOverride;
	aLookUp = aLookUpOverride;

	//These need to be set for vehicles
	RawJoyUp = aBaseY;
	RawJoyRight = aStrafe;
	RawJoyLookRight = aTurn;
	RawJoyLookUp = aLookUp;

	//`Log(Self @ "aBaseY" @ aBaseY @ "aStrafe" @ aStrafe @ "aUp" @ aUp @ "aTurn" @ aTurn @ "aLookUp" @ aLookUp);
}

defaultproperties
{
}
