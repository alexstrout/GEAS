/*
 * TODO document this
 */
class SimPlayerInput extends PlayerInput within SimPlayerController;

var float aForwardOverride;
var float aStrafeOverride;
var float aUpOverride;
var float aTurnOverride;
var float aLookUpOverride;

function PreProcessInput(float DeltaTime)
{
	Super.PreProcessInput(DeltaTime);

	aForward = aForwardOverride;
	aStrafe = aStrafeOverride;
	aUp = aUpOverride;
	aTurn = aTurnOverride;
	aLookUp = aLookUpOverride;

	//These need to be set again for vehicles
	RawJoyUp = aForward;
	RawJoyRight = aStrafe;
	RawJoyLookRight = aTurn;
	RawJoyLookUp = aLookUp;

	//`Log(Self @ "aForward" @ aForward @ "aStrafe" @ aStrafe @ "aUp" @ aUp @ "aTurn" @ aTurn @ "aLookUp" @ aLookUp);
}

defaultproperties
{
	aForwardOverride=1.0
}
