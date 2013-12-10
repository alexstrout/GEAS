/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

var SimRemoteController CC;
var Vehicle CV;

function LogAndSend(string S)
{
	`Log(S);
	SendText(S);
}

event Accepted()
{
	local NavigationPoint SpawnPoint;
	local vector SpawnLoc;
	local rotator SpawnRot;

	`Log(Self $ ": New client connected");

	//TODO Must be set here instead of defaultproperties for some reason
	LinkMode = MODE_Line;

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

	//Attempt to spawn the controller
	CC = WorldInfo.Game.Spawn(class'SimRemoteController', , , SpawnLoc, SpawnRot);
	if (CC != None)
		LogAndSend(Self $ ": Successfully spawned" @ CC);
	else {
		LogAndSend(Self $ ": Could not spawn controller! Aborting...");
		return;
	}


	//Attempt to spawn the vehicle
	SpawnLoc.Z += 512.0; //Always give the vehicle some room to spawn in
	CV = WorldInfo.Game.Spawn(class'UTVehicle_Manta_Content', , , SpawnLoc, SpawnRot);
	if (CV != None)
		LogAndSend(Self $ ": Successfully spawned" @ CV);
	else {
		LogAndSend(Self $ ": Could not spawn vehicle! Aborting...");
		return;
	}

	//Attempt to spawn the controller pawn (which will drive the vehicle) -- TODO UDKPawn should be fine but it has some bugs with vehicle driving
	SpawnLoc.Z += 512.0; //Always give the controller pawn some room to spawn in
	CC.Possess(WorldInfo.Game.Spawn(class'UTPawn', , , SpawnLoc, SpawnRot), false);
	if (CC.Pawn != None)
		LogAndSend(Self $ ": Successfully spawned" @ CC.Pawn);
	else {
		LogAndSend(Self $ ": Could not spawn driver pawn! Aborting...");
		return;
	}

	//Attempt to possess the vehicle
	if (CV.TryToDrive(CC.Pawn))
		LogAndSend(CC $ ": Successfully possessed" @ CV);

	SendText("Awaiting input... (? for help)");
}

event Closed()
{
	`Log(Self $ ": Connection closed");

	if (CV != None) {
		`Log(Self $ ": Destroying" @ CV);
		CV.Destroy();
	}

	if (CC.Pawn != None) {
		`Log(Self $ ": Destroying" @ CC.Pawn);
		CC.Pawn.Destroy();
	}

	if (CC != None) {
		`Log(Self $ ": Destroying" @ CC);
		CC.Destroy();
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
	local UTVehicle V;

	//Input
	In = SimRemoteInput(CC.PlayerInput);
	switch (Left(Line, 1)) {
		case "t":
			In.aBaseYOverride = float(Split(Line, " ", true)) / 100.0;
			break;
		case "s":
			In.aStrafeOverride = float(Split(Line, " ", true)) / 100.0;
			break;
		case "r":
			In.aUpOverride = float(Split(Line, " ", true)) / 100.0;
			break;
		case "x":
			In.aTurnOverride = float(Split(Line, " ", true)) / 100.0;
			break;
		case "y":
			In.aLookUpOverride = float(Split(Line, " ", true)) / 100.0;
	}
	
	//Output
	switch (Left(Line, 1)) {
		case "?":
			SendHelp();
			break;
		case "t":
		case "s":
		case "r":
		case "x":
		case "y":
		case "q":
			SendText(((CV.Controller == CC) ? "* Vehicle" : "  Vehicle") @ CV
			@ "at" @ CV.Location
			@ "rot" @ CV.Rotation
			@ "vel" @ CV.Velocity
			@ "(" $ VSize(CV.Velocity) $ ")");
			SendText("	-- Throttle" @ In.aBaseYOverride);
			SendText("	-- Strafe  " @ In.aStrafeOverride);
			SendText("	-- Rise    " @ In.aUpOverride);
			SendText("	-- X Turn  " @ In.aTurnOverride);
			SendText("	-- Y Turn  " @ In.aLookUpOverride);
			break;
		case "i":
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				SendText(((V.Controller == CC) ? "* Vehicle" : "  Vehicle") @ V
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
	SendText("x [-100...100] Set X Turn");
	SendText("y [-100...100] Set Y Turn");
	SendText("q              Query Info on Current Vehicle");
	SendText("i              List All Vehicles");
	SendText("?              This Help");
}

defaultproperties
{
}
