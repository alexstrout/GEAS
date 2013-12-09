/*
 * TODO document this
 */
class SimRemoteInput extends UDKPlayerInput within SimRemoteController;

var float aBaseYOverride;
var float aStrafeOverride;
var float aUpOverride;
var float aTurnOverride;
var float aLookUpOverride;

event PreProcessInput(float DeltaTime)
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
