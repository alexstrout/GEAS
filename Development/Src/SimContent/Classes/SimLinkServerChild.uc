/**
 * SimLinkServerChild - GEAS 2013, Alex Strout
 * The child class spawned by SimLinkServer for each new connection
 * Handles the individual Controller-AUV communiciations
 * Many thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

//Cached location and rotation for spawning the AUV, its controller, etc.
//This is global as we spawn things using timers, which can not accept arguments
//Also, we spawn multiple objects - first the AUV itself, then its "driver" pawn (see below), then its controller
//These can not overlap when spawning, so we increment the Z value of location for each
var vector SpawnLoc;
var rotator SpawnRot;

//Our spawned SimRemoteController and SimVehicle
var SimRemoteController SimC;
var SimVehicle SimV;

//Convenience function to both log and send some string
function LogAndSend(string S)
{
	`Log(S);
	SendText(S);
}

//As defined in IpDrv::TcpLink, called when link established
event Accepted()
{
	`Log(Self $ ": New client connected");

	//Set the LinkMode
	//This must be set here instead of defaultproperties for some reason
	//See IpDrv::TcpLink.LinkMode
	LinkMode = MODE_Line;

	//We want to spawn a new AUV etc. for our new connection (this will handle binding it to the RemoteController as well)
	SpawnThings();
}

//Entry point for spawning our AUV / RemoteController / etc.
function SpawnThings()
{
	local NavigationPoint SpawnPoint;

	//Resolve a point from our list of PlayerStart actors to use for spawning
	SpawnPoint = WorldInfo.Game.FindPlayerStart(None, 255, "");
	if (SpawnPoint != None)
		LogAndSend(Self $ ": Successfully found spawn point" @ SpawnPoint);
	else {
		LogAndSend(Self $ ": Could not find spawn point! Aborting...");
		return;
	}

	//Cache the location and rotation (will be used / modified later)
	SpawnLoc = SpawnPoint.Location;
	SpawnRot = SpawnPoint.Rotation;

	//We're ready to spawn our controller, so do that in .2 seconds
   	SetTimer(0.2, false, 'SpawnController');
}

//Spawn our SimRemoteController - this handles actually controlling the vehicle
function SpawnController()
{
	//Attempt to spawn the controller
	if (SimC == None) {
		SimC = WorldInfo.Game.Spawn(class'SimRemoteController', , , SpawnLoc, SpawnRot);
		if (SimC != None)
			LogAndSend(Self $ ": Successfully spawned" @ SimC);
		else {
			LogAndSend(Self $ ": Could not spawn controller! Aborting...");
			return;
		}
	}

	//We're ready to spawn our vehicle
	SetTimer(0.2, false, 'SpawnVehicle');
}

//Spawn our SimVehicle
function SpawnVehicle()
{
	//Attempt to spawn the vehicle
	if (SimV == None || SimV.Health < 0 || SimV.bDeleteMe) {
		SpawnLoc.Z += 512.0; //Always give the vehicle some room to spawn in
		SimV = WorldInfo.Game.Spawn(class'SimVehicle', , , SpawnLoc, SpawnRot);
		if (SimV != None)
			LogAndSend(Self $ ": Successfully spawned" @ SimV);
		else {
			LogAndSend(Self $ ": Could not spawn vehicle! Aborting...");
			return;
		}
	}

	//We're now ready to spawn the driver pawn (see below)
	SetTimer(0.2, false, 'SpawnPawn');
}

//Spawn our driver pawn - the vanilla Unreal vehicle class (which SimVehicle) inherets off of requires a Pawn driver in addition to a controller
//This could be worked around, but there are several points where vehicles check that they have valid drivers
//So, for the sake of simplicity, we'll simply spawn a "driver" pawn and use that to actually drive the vehicle
function SpawnPawn()
{
	//Attempt to spawn the controller pawn (which will drive the vehicle)
	//Our SimRemoteController needs something to control - so, we'll simply have it possess the driver pawn
	//As such, we're simply spawning the pawn as a parameter to a possess call for SimRemoteController
	//After, we'll instruct the driver pawn to possess the vehicle, which will simultaneously hand over
	//control of the vehicle to SimRemoteController while also giving the vehicle a valid driver. Everyone's happy!
	if (SimC.Pawn == None) {
		SpawnLoc.Z += 512.0; //Always give the controller pawn some room to spawn in
		SimC.Possess(WorldInfo.Game.Spawn(class'SimPawn', , , SpawnLoc, SpawnRot), false);
		if (SimC.Pawn != None)
			LogAndSend(Self $ ": Successfully spawned" @ SimC.Pawn);
		else {
			LogAndSend(Self $ ": Could not spawn driver pawn! Aborting...");
			return;
		}
	}

	//We're now ready for the driver pawn to possess the vehicle
	SetTimer(0.2, false, 'PossessVehicle');
}

//Possess the SimVehicle with our driver pawn - this will put our SimRemoteController in control of the vehicle
function PossessVehicle()
{
	//Attempt to possess the vehicle
	if (SimC.Pawn != None && SimC.Pawn != SimV && SimV.TryToDrive(SimC.Pawn))
		LogAndSend(SimC $ ": Successfully possessed" @ SimV);

	//Everything worked? We're finally ready for input!
	SendText("Awaiting input... (? for help)");
}

//As defined in IpDrv::TcpLink, called when link closed
event Closed()
{
	`Log(Self $ ": Connection closed");

	//Connection closing, time to destroy our vehicle
	if (SimV != None) {
		`Log(Self $ ": Destroying" @ SimV);
		SimV.DriverLeave(true);
		SimV.Suicide(); //Blow it up instead of disappearing :)
	}

	//Connection closing, time to destroy our controller
	//Since our controller is directly controlling our driver pawn, this destroy call will also destroy that pawn
	if (SimC != None) {
		`Log(Self $ ": Destroying" @ SimC);
		SimC.Destroy();
	}

	//Finally, no need for this to hang around
	//Self-destructing will also tell the SimLinkServer listener that we are closed via LostChild
	Destroy();
}

//As defined in IpDrv::TcpLink, called when we have received a line using MODE_Line over the link
event ReceivedLine(string Line)
{
	`Log(Self $ ": Received line:" @ Line);

	//If our vehicle somehow blew up, try and spawn another one
	if (SimV == None || SimV.Health < 0 || SimV.bDeleteMe
	|| SimC == None || SimC.Pawn == None)
		SpawnThings();

	//Possibly close by request
	if (Line ~= "close") {
		SendText("Closing by request");
		Close();
		return;
	}

	//Send help if needed
	if (Left(Line, 1) == "?") {
		SendHelp();
		return;
	}

	//Not one of the above? Send it to our SimRemoteController as input
	SimC.ResolveInputs(Self, Line);
}

//Help function - this should match what's supported in SimRemoteController / SimRemoteInput
function SendHelp()
{
	SendText("t [-100...100] Set Throttle");
	SendText("s [-100...100] Set Strafe");
	SendText("r [-100...100] Set Rise");
	SendText("x [-100...100] Set X Turn (Yaw)");
	SendText("y [-100...100] Set Y Turn (Pitch)");
	SendText("z [-100...100] Set Z Turn (Roll)");
	SendText("q              Query Vehicle Info");
	SendText("g [0...3]      Query GPS [0: Loc, 1: Rot, 2: Vel, 3: VelResolved]");
	SendText("d              Query Depth");
	SendText("i              List All Vehicles");
	SendText("?              This Help");
}

defaultproperties
{
}
