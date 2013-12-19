/**
 * SimPlayerController - GEAS 2013, Alex Strout
 * Defines functionality for the Unreal client's "view" of the world
 * Mostly extensions for the "spectator mode" free-floating camera
 * Not really important, just ignore this :)
 */
class SimPlayerController extends UDKPlayerController;

//For GetPlayerViewPoint
var float LastGetViewPointTime;

//Override the HUD to always display on-screen debug info
//See Engine::PlayerController.ClientSetHUD()
reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	Super.ClientSetHUD(newHUDType);
	if (myHUD != None)
		myHUD.bShowDebugInfo = true;
}

//Console test function - if our client is not a spectator, running this via console will possess the first available vehicle
exec function PTest()
{
	local Vehicle V;

	foreach WorldInfo.AllPawns(class'Vehicle', V)
		if (V.TryToDrive(Pawn))
			return;
}

//Camera position and orientation is determined by out parameters OutLocation and OutRotation
//When viewing another pawn in spectator mode, our view rotation is normally locked to theirs
//To allow looking around with the mouse instead, we'll force OutRotation to our controller's rotation
//See Engine::PlayerController.GetPlayerViewPoint()
simulated event GetPlayerViewPoint(out Vector OutLocation, out Rotator OutRotation)
{
	Super.GetPlayerViewPoint(OutLocation, OutRotation);
	OutRotation = Rotation;
}

//Normally, when viewing another pawn as a spectator and then returning to our own spectator camera,
//the camera snaps back to the location we started viewing the other pawn at. So instead, we'll implement
//a ServerViewSelf method that is more like UTPlayerController's
//See Engine::PlayerController.ServerViewSelf() and UTGame::UTPlayerController.ServerViewSelf()
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

//Spectator mode overrides
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

	//Use scroll-wheel to switch targets similarly to UTPlayerController
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
