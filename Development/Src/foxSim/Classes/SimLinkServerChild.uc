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

	if (Line ~= "close") {
		SendText("Closing by request");
		Close();
		return;
	}

	DoStuff(Line);
}

function DoStuff(string Line)
{
	local SimRemoteInput In;
	local SimVehicle V;

	//If our vehicle somehow blows up, try and spawn another one
	if (SimV == None || SimV.Health < 0 || SimV.bDeleteMe
	|| SimC == None || SimC.Pawn == None)
		SpawnThings();

	In = SimRemoteInput(SimC.PlayerInput);
	if (In == None)
		return;

	//Input
	switch (Left(Line, 1)) {
		case "p":
			//Reserved for testing
			break;
		case "t":
			In.aVThrottle = float(Split(Line, " ", true)) / 100.0;
			break;
		case "s":
			In.aVStrafe = float(Split(Line, " ", true)) / 100.0;
			break;
		case "r":
			In.aVRise = float(Split(Line, " ", true)) / 100.0;
			break;
		case "x":
			In.aVYaw = float(Split(Line, " ", true)) / 100.0;
			break;
		case "y":
			In.aVPitch = float(Split(Line, " ", true)) / 100.0;
			break;
		case "z":
			In.aVRoll = float(Split(Line, " ", true)) / 100.0;
	}

	//Output
	switch (Left(Line, 1)) {
		case "?":
			SendHelp();
			break;
		case "p":
		case "t":
		case "s":
		case "r":
		case "x":
		case "y":
		case "z":
		case "q":
			SendText(((SimV.Controller == SimC) ? "* Vehicle" : "  Vehicle") @ SimV
			@ "at" @ SimV.Location
			@ "rot" @ SimV.Rotation
			@ "vel" @ SimV.Velocity
			@ "(" $ VSize(SimV.Velocity) $ ")");
			SendText("	-- Throttle" @ In.aVThrottle);
			SendText("	-- Strafe  " @ In.aVStrafe);
			SendText("	-- Rise    " @ In.aVRise);
			SendText("	-- Yaw     " @ In.aVYaw);
			SendText("	-- Pitch   " @ In.aVPitch);
			SendText("	-- Roll    " @ In.aVRoll);
			break;
		case "i":
			foreach WorldInfo.AllPawns(class'SimVehicle', V) {
				SendText(((V.Controller == SimC) ? "* Vehicle" : "  Vehicle") @ V
				@ "at" @ V.Location
				@ "rot" @ V.Rotation
				@ "vel" @ V.Velocity
				@ "(" $ VSize(V.Velocity) $ ")");
			}
			break;
		default:
			SendText("Huh?");
	}
}

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
