/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

var SimPlayerController CC;
var Vehicle CV;

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
		`Log(Self $ ": Successfully found spawn point" @ SpawnPoint);
	else {
		`Log(Self $ ": Could not find spawn point! Aborting...");
		return;
	}

	SpawnLoc = SpawnPoint.Location;
	SpawnRot = SpawnPoint.Rotation;

	CC = WorldInfo.Game.Spawn(class'SimPlayerController', , , SpawnLoc, SpawnRot);
	if (CC != None)
		`Log(Self $ ": Successfully spawned" @ CC);
	else {
		`Log(Self $ ": Could not spawn controller! Aborting...");
		return;
	}

	//Give the Controller some room to spawn in
	SpawnLoc.Z += 1024.0;

	CV = WorldInfo.Game.Spawn(class'UTVehicle_Manta_Content', , , SpawnLoc, SpawnRot);
	if (CV != None)
		`Log(Self $ ": Successfully spawned" @ CV);
	else {
		`Log(Self $ ": Could not spawn vehicle! Aborting...");
		return;
	}

	//Attempt to spawn the controller pawn (which will drive the vehicle)
	CC.StartSpot = SpawnPoint;
	WorldInfo.Game.RestartPlayer(CC);
	if (CC.Pawn != None)
		`Log(Self $ ": Successfully spawned" @ CC.Pawn);
	else {
		`Log(Self $ ": Could not spawn driver pawn! Aborting...");
		return;
	}

	//Attempt to possess the vehicle
	SetTimer(1.0, false, 'TimedPossess');
}
function TimedPossess()
{
	local Pawn P;

	P = CC.Pawn;
	if (CV.TryToDrive(P)) {
		`Log(CC $ ": Successfully possessed" @ CV $ ", destroying" @ P);
		P.Destroy();
	}
}

event Closed()
{
	`Log(Self $ ": Connection closed");

	if (CC != None) {
		`Log(Self $ ": Destroying" @ CC);
		CC.Destroy();
	}

	if (CV != None) {
		`Log(Self $ ": Destroying" @ CV);
		CV.Destroy();
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
	local SimPlayerInput In;
	local UTVehicle V;

	In = SimPlayerInput(CC.PlayerInput);
	switch (Left(Line, 1)) {
		case "t":
			In.aForwardOverride = float(Split(Line, " ", true));
			break;
		case "s":
			In.aStrafeOverride = float(Split(Line, " ", true));
			break;
		case "r":
			In.aUpOverride = float(Split(Line, " ", true));
			break;
		case "x":
			In.aTurnOverride = float(Split(Line, " ", true));
			break;
		case "y":
			In.aLookUpOverride = float(Split(Line, " ", true));
	}
	switch (Left(Line, 1)) {
		case "t":
		case "s":
		case "r":
		case "x":
		case "y":
		case "q":
			SendText(((CV.Controller != None) ? "* Vehicle" : "	Vehicle") @ CV
			@ "at" @ CV.Location
			@ "rot" @ CV.Rotation
			@ "vel" @ CV.Velocity
			@ "(" $ VSize(CV.Velocity) $ ")");
			SendText("	-- Throttle" @ In.aForwardOverride);
			SendText("	-- Strafe  " @ In.aStrafeOverride);
			SendText("	-- Rise    " @ In.aUpOverride);
			SendText("	-- X Turn  " @ In.aTurnOverride);
			SendText("	-- Y Turn  " @ In.aLookUpOverride);
			break;
		case "i":
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				SendText(((V.Controller != None) ? "* Vehicle" : "	Vehicle") @ V
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

defaultproperties
{
}
