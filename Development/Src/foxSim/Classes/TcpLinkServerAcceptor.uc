/*
 * An example usage of the TcpLink class
 *  
 * By Michiel 'elmuerte' Hendriks for Epic Games, Inc.
 *  
 * You are free to use this example as you see fit, as long as you 
 * properly attribute the origin. 
 */ 
class TcpLinkServerAcceptor extends TcpLink;

var float T, S, R;

event Accepted()
{
    `log("[TcpLinkServerAcceptor] New client connected");
    // make sure the proper mode is set
    LinkMode=MODE_Line;
}

event ReceivedLine( string Line )
{
    `log("[TcpLinkServerAcceptor] Received line: "$line);
    if (line ~= "close")
    {
        SendText("Closing by request");
        Close();
        return;
    }
    DoStuff(line);
    //SendText(line);
}

function DoStuff(string line)
{
	local UTVehicle V;

	switch (Left(line, 1)) {
		case "t":
			T = float(Split(line, " ", true)); break;
		case "s":
			S = float(Split(line, " ", true)); break;
		case "r":
			R = float(Split(line, " ", true)); break;
	}
	switch (Left(line, 1)) {
		case "t":
		case "s":
		case "r":
		case "q":
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				V.SetInputs(T, S, R);
				if (V.Controller != None) {
				    SendText("* Vehicle" @ V
					@ "at" @ V.Location
					@ "rot" @ V.Rotation
					@ "vel" @ V.Velocity
					@ "(" $ VSize(V.Velocity) $ ")");
					SendText("  -- Throttle" @ T);
					SendText("  -- Steering" @ S);
					SendText("  -- Rise    " @ R);
				}
			}
			break;
		case "i":
			foreach WorldInfo.AllPawns(class'UTVehicle', V) {
				V.SetInputs(T, S, R);
			    SendText(((V.Controller != None) ? "* Vehicle" : "  Vehicle") @ V
				@ "at" @ V.Location
				@ "rot" @ V.Rotation
				@ "vel" @ V.Velocity
				@ "(" $ VSize(V.Velocity) $ ")");
			}
	}
}

event Closed()
{
    `Log("[TcpLinkServerAcceptor] Connection closed");
    // It's important to destroy the object so that the parent knows
    // about it and can handle the closed connection. You can not
    // reuse acceptor instances.
 	Destroy();
}
