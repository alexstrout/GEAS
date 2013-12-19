/**
 * SimRemoteController - GEAS 2013, Alex Strout
 * Defines functionality for the socket connection's in-world controller
 * This directly controls the in-game AUV it's bound to based on input from the socket class
 * It also reports requested information back to the socket class
 */
class SimRemoteController extends UDKPlayerController;

//Resolve inputs received from our LinkAgent (and possibly act on them)
//This is called whenever our LinkAgent receives a line of input
//This is the main entry point of socket communication with our AUV
function ResolveInputs(SimLinkServerChild LinkAgent, string Line)
{
	local SimRemoteInput In;
	local SimVehicle V;
	local byte SensorIn;

	//Make sure we have a valid SimRemoteInput
	In = SimRemoteInput(PlayerInput);
	if (In == None)
		return;

	//Send the requested inputs to our input class to resolve
	In.ResolveInputs(Line);

	//Query all vehicles?
	if (Left(Line, 1) == "i") {
		foreach WorldInfo.AllPawns(class'SimVehicle', V)
			LinkAgent.SendText(((V.Controller == Self) ? "* Vehicle" : "  Vehicle") @ V.QueryInfo());
		return;
	}

	//Regardless of input, send info of our vehicle (this used to be tied to "query" only, but why not?)
	V = SimVehicle(Pawn);
	if (V == None)
		return;

	//Possibly query info
	//Split will take anything after the space as the argument for SensorIn
	//SensorIn will default to 0 if nothing was passed
	SensorIn = byte(Split(Line, " ", true));
	switch (Left(Line, 1)) {
		//Query GPS?
		case "g":
			LinkAgent.SendText(V.SensorGPS.Query(SensorIn));
			return;
		//Query depth?
		case "d":
			LinkAgent.SendText(V.SensorDepth.Query(SensorIn));
			return;
		//Query everything?
		case "q":
			LinkAgent.SendText(V.QueryInfo());

			//TODO Hack: Also send current input information
			LinkAgent.SendText("	-- Throttle" @ In.aVThrottle);
			LinkAgent.SendText("	-- Strafe  " @ In.aVStrafe);
			LinkAgent.SendText("	-- Rise    " @ In.aVRise);
			LinkAgent.SendText("	-- Yaw     " @ In.aVYaw);
			LinkAgent.SendText("	-- Pitch   " @ In.aVPitch);
			LinkAgent.SendText("	-- Roll    " @ In.aVRoll);
	}
}

//Vehicles are normally handled server-side, while this controller may be a networked Unreal client
//However, all SimRemoteControllers are spawned on the server via SimLinkServerChild and will never be owned by an Unreal client
//Thus, this is not needed, so we'll empty the implementation
unreliable server function ServerDrive(float InForward, float InStrafe, float aUp, bool InJump, int View) {}

//Normally, controllers only accept Pitch and Yaw input and ignore Roll
//Pawns turn by slowly matching their controller's rotation
//We our AUV to be able to roll, so we'll implement our own UpdateRotation
//See Engine::Controller.UpdateRotation() and Engine::PlayerController.UpdateRotation()
function UpdateRotation(float DeltaTime)
{
	local Rotator DeltaRot, ViewRotation;
	local SimRemoteInput In;

	//Make sure we have a valid SimRemoteInput
	In = SimRemoteInput(PlayerInput);
	if (In == None)
		return;

	//Set our current rotation first...
	ViewRotation = Rotation;
	if (Pawn != None)
		Pawn.SetDesiredRotation(ViewRotation);

	//... And then determine how much we want to turn
	//Normally, Yaw is multiplied by LookRightScale in the input code, Pitch by LookUpScale
	//However, there is no scaling for roll, and we want them all to match up, so we'll
	//scale them by an arbitrary constant here
	DeltaRot.Yaw = In.aVYaw * 50;
	DeltaRot.Pitch = In.aVPitch * 50;
	DeltaRot.Roll = In.aVRoll * 50;

	//Process DeltaRot and set our new rotation
	ProcessViewRotation(DeltaTime, ViewRotation, DeltaRot);
	SetRotation(ViewRotation);

	//Apply any ViewShake (not really used at the moment, but might be handy later e.g. currents)
	ViewShake(DeltaTime);

	//Instruct pawn to begin facing the new rotation
	if (Pawn != None)
		Pawn.FaceRotation(ViewRotation, DeltaTime);
}

//... And here it gets messy. As it turns out, water physics in Unreal are uglier than I first thought
//A controller, for whatever reason, determines the physics state of its currently controlled Pawn (versus the pawn doing this itself, which would make more sense?)
//A pawn does, at least, define two movement states - LandMovementState (normally PlayerWalking) and WaterMovementState (normally PlayerSwimming)
//These correspond to the appropriate states the controller should be in
//However, vehicles define only a LandMovementState - PlayerDriving - and this is the only state used when driving vehicles
//Going further and further down the rabbit hole, I think this is because movement is determined by native physics handling code (and thus is why vehicles are handled server-side - I think)
//Thus, below is my attempt to shoehorn in water handling as best I could - unfortunately, no matter what, a vehicle would always be able to move outside of the water
//So, in the meantime as a hack, I set the map's StallZ value (which determines how high vehicles can go) to the water-level to prevent our swimming vehicle from also being a flying vehicle
//This works well enough and yields decently believeable underwater movement, but it obviously still needs some work
//See Engine::PlayerController::PlayerDriving
state PlayerDriving
{
	//Attempt to support swimming vehicles
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

	//SimPawns should never leave vehicle, so disable Use
	unreliable server function ServerUse() {}

	//... And lots of work-in-progress stuff
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
//
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
	//Use SimRemoteInput as our input class
	InputClass=class'SimRemoteInput'
}
