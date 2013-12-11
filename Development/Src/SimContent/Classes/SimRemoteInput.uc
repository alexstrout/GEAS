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

defaultproperties
{
}
