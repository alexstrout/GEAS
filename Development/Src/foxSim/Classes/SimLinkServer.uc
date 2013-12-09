/*
 * TODO document this
 * Thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServer extends TcpLink;

var int NumClients;

var int MaxClients;
var int ListenPort;

event PostBeginPlay()
{
	local int BoundPort;

	Super.PostBeginPlay();

	BoundPort = BindPort(ListenPort, false);
	if (BoundPort == 0)
		`Log(Self $ ": Failed binding port "$ListenPort);
	else {
		// start listening for connections
		if (Listen())
			`Log(Self $ ": Listening on port" @ BoundPort @ "for incoming connections");
		else
			`Log(Self $ ": Failed listening on port" @ BoundPort);
	}
}

event GainedChild(Actor C)
{
	`Log(Self $ ": Gained child" @ C);

	Super.GainedChild(C);
	NumClients++;

	//if too many clients, stop accepting new connections
	if (MaxClients > 0 && NumClients >= MaxClients && LinkState == STATE_Listening) {
		`log(Self $ ": Maximum number of clients connected, rejecting new clients");
		Close();
	}
}

event LostChild( Actor C )
{
	`Log(Self $ ": Lost child" @ C);

	Super.LostChild(C);
	NumClients--;

	//check if there is room for accepting new clients
	if (NumClients < MaxClients && LinkState != STATE_Listening) {
		`log(Self $ ": Listening for incoming connections");
		Listen();
	}
}

defaultproperties
{
	MaxClients=-1
	ListenPort=3742
	AcceptClass=class'SimLinkServerChild'
}
