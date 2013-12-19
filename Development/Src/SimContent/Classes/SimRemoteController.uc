/*
 * TODO document this
 */
class SimRemoteController extends UDKPlayerController;

const INPUT_SCALE = 50; //TODO Where is aTurn scaled?

//Resolve inputs received from our LinkAgent (and possibly act on them)
function ResolveInputs(SimLinkServerChild LinkAgent, string Line)
{
	local SimRemoteInput In;
	local SimVehicle V;

	//Make sure we have a valid SimRemoteInput
	In = SimRemoteInput(PlayerInput);
	if (In == None)
		return;

	//Send the requested inputs to our input class to resolve
	In.ResolveInputs(Line);

	//Possibly query info for all vehicles
	if (Left(Line, 1) == "i") {
		foreach WorldInfo.AllPawns(class'SimVehicle', V) {
			LinkAgent.SendText(((V.Controller == Self) ? "* Vehicle" : "  Vehicle") @ V
				@ "at" @ V.Location
				@ "rot" @ V.Rotation
				@ "vel" @ V.Velocity
				@ "(" $ VSize(V.Velocity) $ ")");
		}
		return;
	}

	//Regardless of input, send info of our vehicle
	LinkAgent.SendText("* Vehicle" @ Pawn
		@ "at" @ Pawn.Location
		@ "rot" @ Pawn.Rotation
		@ "vel" @ Pawn.Velocity
		@ "(" $ VSize(Pawn.Velocity) $ ")");
	LinkAgent.SendText("	-- Throttle" @ In.aVThrottle);
	LinkAgent.SendText("	-- Strafe  " @ In.aVStrafe);
	LinkAgent.SendText("	-- Rise    " @ In.aVRise);
	LinkAgent.SendText("	-- Yaw     " @ In.aVYaw);
	LinkAgent.SendText("	-- Pitch   " @ In.aVPitch);
	LinkAgent.SendText("	-- Roll    " @ In.aVRoll);
}

//Not needed, as all SimRemoteControllers are spawned on the server
unreliable server function ServerDrive(float InForward, float InStrafe, float aUp, bool InJump, int View) {}

function UpdateRotation(float DeltaTime)
{
	local Rotator DeltaRot, ViewRotation;
	local SimRemoteInput In;

	In = SimRemoteInput(PlayerInput);
	if (In == None)
		return;

	ViewRotation = Rotation;
	if (Pawn != None)
		Pawn.SetDesiredRotation(ViewRotation);

	//`Log(Self $ ":" @ In.aVYaw @ In.aVPitch @ "vs." @ In.aTurn @ In.aLookUp);
	DeltaRot.Yaw = In.aVYaw * INPUT_SCALE;
	DeltaRot.Pitch = In.aVPitch * INPUT_SCALE;
	DeltaRot.Roll = In.aVRoll * INPUT_SCALE;

	ProcessViewRotation(DeltaTime, ViewRotation, DeltaRot);
	SetRotation(ViewRotation);

	ViewShake(DeltaTime);

	if (Pawn != None)
		Pawn.FaceRotation(ViewRotation, DeltaTime);
}

state PlayerDriving
{
	//Support swimming vehicles
	event bool NotifyLanded(vector HitNormal, Actor FloorActor)
	{
		if (Pawn.PhysicsVolume.bWaterVolume)
			Pawn.SetPhysics(PHYS_Swimming);
		else
			GotoState(Pawn.LandMovementState);
		return bUpdating;
	}

	//Read from SimRemoteInput directly
	function PlayerMove(float DeltaTime)
	{
		local SimRemoteInput In;

		In = SimRemoteInput(PlayerInput);
		if (In == None)
			return;

		UpdateRotation(DeltaTime);

		//SimRemoteInput doesn't currently use jump (bPressedJump), but read it in-case it does in the future
		ProcessDrive(In.aVThrottle, In.aVStrafe, In.aVRise, bPressedJump);
		bPressedJump = false;
	}

// 	function ProcessMove(float DeltaTime, vector NewAccel, eDoubleClickDir DoubleClickMove, rotator DeltaRot)
// 	{
// 		Pawn.Acceleration = NewAccel;
// 	}
// 
// 	function PlayerMove(float DeltaTime)
// 	{
// 		local Rotator OldRotation;
// 		local Vector X,Y,Z, NewAccel;
// 		local SimRemoteInput In;
// 
// 		In = SimRemoteInput(PlayerInput);
// 		if (In == None)
// 			return;
// 
// 		if (Pawn == None)
// 			GotoState('Dead');
// 		else {
// 			GetAxes(Rotation,X,Y,Z);
// 
// 			NewAccel = Pawn.AccelRate * Normal(In.aVThrottle * X + In.aVStrafe * Y + In.aVRise * vect(0,0,1));
// 
// 			OldRotation = Rotation;
// 			UpdateRotation(DeltaTime);
// 
// 			ProcessMove(DeltaTime, NewAccel, DCLICK_None, OldRotation - Rotation);
// 			bPressedJump = false;
// 		}
// 	}

	//SimPawns will never leave vehicle, so disable Use
	unreliable server function ServerUse() {}

// 	event Timer()
// 	{
// 		if (!Pawn.PhysicsVolume.bWaterVolume && Role == ROLE_Authority)
// 			GotoState(Pawn.LandMovementState);
// 		ClearTimer();
// 	}
// 
// 	event BeginState(Name PreviousStateName)
// 	{
// 		CleanOutSavedMoves();
// 		ClearTimer();
// 		Pawn.SetPhysics(PHYS_Swimming);
// 	}
}

defaultproperties
{
	InputClass=class'SimRemoteInput'
}
