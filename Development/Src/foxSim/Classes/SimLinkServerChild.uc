/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

var Vehicle CV;

event Accepted()
{
	local NavigationPoint SpawnPoint;

	`Log(Self $ ": New client connected");

    //TODO Must be set here instead of defaultproperties for some reason
	LinkMode = MODE_Line;

	//Attempt to spawn something
	SpawnPoint = WorldInfo.Game.FindPlayerStart(None, 255, "");
	if (SpawnPoint != None)
		`Log(Self $ ": Successfully found spawn point" @ SpawnPoint);
	else {
		`Log(Self $ ": Could not find spawn point!");
		return;
	}

	CV = WorldInfo.Game.Spawn(class'UTVehicle_Manta_Content', , , SpawnPoint.Location, SpawnPoint.Rotation);
	if (CV != None) {
		CV.bRunPhysicsWithNoController = true;
		CV.SetDriving(true);
		`Log(Self $ ": Successfully spawned" @ CV);
	}
}

event Closed()
{
	`Log(Self $ ": Connection closed");

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
	local float T, S, R;
	local UTVehicle V;

	T = CV.Throttle;
	S = CV.Steering;
	R = CV.Rise;

	switch (Left(Line, 1)) {
		case "t":
			T = float(Split(Line, " ", true)); break;
		case "s":
			S = float(Split(Line, " ", true)); break;
		case "r":
			R = float(Split(Line, " ", true)); break;
	}
	switch (Left(Line, 1)) {
		case "t":
		case "s":
		case "r":
		case "q":
			CV.SetInputs(T, S, R);
			SendText(((CV.Controller != None) ? "* Vehicle" : "	Vehicle") @ CV
			@ "at" @ CV.Location
			@ "rot" @ CV.Rotation
			@ "vel" @ CV.Velocity
			@ "(" $ VSize(CV.Velocity) $ ")");
			SendText("	-- Throttle" @ T);
			SendText("	-- Steering" @ S);
			SendText("	-- Rise    " @ R);
			break;
		case "i":
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				V.SetInputs(T, S, R);
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
