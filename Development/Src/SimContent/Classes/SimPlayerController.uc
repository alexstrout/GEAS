/*
 * TODO document this
 */
class SimPlayerController extends UDKPlayerController;

//For GetPlayerViewPoint
var float LastGetViewPointTime;

reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	Super.ClientSetHUD(newHUDType);

	if (myHUD != None)
		myHUD.bShowDebugInfo = true;
}

exec function PTest()
{
	local Vehicle V;

	foreach WorldInfo.AllPawns(class'Vehicle', V)
		if (V.TryToDrive(Pawn))
			return;
}

//Allow UT-style free-cam... sorta -- TODO make not awful
simulated event GetPlayerViewPoint(out Vector OutLocation, out Rotator OutRotation)
{
	Super.GetPlayerViewPoint(OutLocation, OutRotation);
	OutRotation = Rotation;
}

//Use UT-style ViewSelf so our camera doesn't snap back to its previous position when no longer spectating a vehicle
unreliable server function ServerViewSelf(optional ViewTargetTransitionParams TransitionParams)
{
	local Vector OutLocation;
	local Rotator OutRotation;

	GetPlayerViewPoint(OutLocation, OutRotation);
	SetLocation(OutLocation);
	SetRotation(OutRotation);

	SetViewTarget(Self, TransitionParams);
	ClientSetViewTarget(Self, TransitionParams);
}

state Spectating
{
	//Do not allow spectator to go below KillZ, but allow above StallZ
	function bool LimitSpectatorVelocity()
	{
		if (Location.Z < WorldInfo.KillZ) {
			Velocity.Z = FMin(SpectatorCameraSpeed, WorldInfo.KillZ - Location.Z + 2.0);
			return true;
		}
		return false;
	}

	//Use scroll-wheel to switch targets UT-style
	//exec function StartFire(optional byte FireModeNum) {}
	exec function PrevWeapon()
	{
		ServerViewPrevPlayer();
	}
	exec function NextWeapon()
	{
		ServerViewNextPlayer();
	}

	//Keep viewing from current position instead of resetting to old position
	exec function StartAltFire(optional byte FireModeNum)
	{
		ServerViewSelf();
	}
}

defaultproperties
{
}
