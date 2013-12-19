/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

var vector SpawnLoc;
var rotator SpawnRot;

var SimRemoteController SimC;
var SimVehicle SimV;

function LogAndSend(string S)
{
	`Log(S);
	SendText(S);
}

event Accepted()
{
	`Log(Self $ ": New client connected");

	//TODO Must be set here instead of defaultproperties for some reason
	LinkMode = MODE_Line;

	SpawnThings();
}
function SpawnThings()
{
	local NavigationPoint SpawnPoint;

	//Attempt to spawn something
	SpawnPoint = WorldInfo.Game.FindPlayerStart(None, 255, "");
	if (SpawnPoint != None)
		LogAndSend(Self $ ": Successfully found spawn point" @ SpawnPoint);
	else {
		LogAndSend(Self $ ": Could not find spawn point! Aborting...");
		return;
	}

	SpawnLoc = SpawnPoint.Location;
	SpawnRot = SpawnPoint.Rotation;

   	SetTimer(0.2, false, 'SpawnController');
}
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

	SetTimer(0.2, false, 'SpawnVehicle');
}
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

	SetTimer(0.2, false, 'SpawnPawn');
}
function SpawnPawn()
{
	//Attempt to spawn the controller pawn (which will drive the vehicle)
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

	SetTimer(0.2, false, 'PossessVehicle');
}
function PossessVehicle()
{
	//Attempt to possess the vehicle
	if (SimC.Pawn != None && SimC.Pawn != SimV && SimV.TryToDrive(SimC.Pawn))
		LogAndSend(SimC $ ": Successfully possessed" @ SimV);

	SendText("Awaiting input... (? for help)");
}

event Closed()
{
	`Log(Self $ ": Connection closed");

	if (SimV != None) {
		`Log(Self $ ": Destroying" @ SimV);
		SimV.DriverLeave(true);
		SimV.Suicide(); //Blow it up instead of disappearing :)
	}

	if (SimC != None) {
		`Log(Self $ ": Destroying" @ SimC);
		SimC.Destroy();
	}

	Destroy();
}

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
	SendText("q              Query Info on Current Vehicle");
	SendText("i              List All Vehicles");
	SendText("?              This Help");
}

defaultproperties
{
}
