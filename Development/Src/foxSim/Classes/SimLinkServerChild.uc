/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServerChild extends TcpLink;

var float T, S, R;

event Accepted()
{
	`log(Self $ ": New client connected");
	LinkMode = MODE_Line;
}

event Opened()
{
	`log(Self $ ": Connection opened");
}

event Closed()
{
	`Log(Self $ ": Connection closed");
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
	local UTVehicle V;

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
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				V.SetInputs(T, S, R);
				SendText(((V.Controller != None) ? "* Vehicle" : "	Vehicle") @ V
				@ "at" @ V.Location
				@ "rot" @ V.Rotation
				@ "vel" @ V.Velocity
				@ "(" $ VSize(V.Velocity) $ ")");
				SendText("	-- Throttle" @ T);
				SendText("	-- Steering" @ S);
				SendText("	-- Rise    " @ R);
			}
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
