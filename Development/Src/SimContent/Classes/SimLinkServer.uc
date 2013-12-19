/**
 * SimLinkServer - GEAS 2013, Alex Strout
 * The socket listener responsible for managing incoming connections
 * Spawns new SimLinkServerChild objects for each new connection, which then handle the individual Controller-AUV communiciations
 * Many thanks to Michiel 'elmuerte' Hendriks for his contributions to the UDN on TcpLink, including example classes which this is based off of
 * http://udn.epicgames.com/Three/TcpLink.html
 */
class SimLinkServer extends TcpLink;

//Maximum number of socket clients allowed, if desired
//Set to or below 0 in defaultproperties to allow unlimited connections
var int MaxClients;

//Number of socket clients currently connected (for above)
var int NumClients;

//The port to listen on; set in defaultproperties
var int ListenPort;

//When spawned, begin listening for connections
event PostBeginPlay()
{
	local int BoundPort; //The port we've successfuly bound

	//Do the usual stuff - see IpDrv::TcpLink.PostBeginPlay()
	Super.PostBeginPlay();

	//Attempt to bind ListenPort
	BoundPort = BindPort(ListenPort, false);
	if (BoundPort == 0)
		`Log(Self $ ": Failed binding port "$ListenPort);
	else {
		//Attempt to start listening for connections
		if (Listen())
			`Log(Self $ ": Listening on port" @ BoundPort @ "for incoming connections");
		else
			`Log(Self $ ": Failed listening on port" @ BoundPort);
	}
}

//As defined in Engine::Actor, GainedChild is called for every child class gained
//In this case, this is for every new socket connection - so track number of connections here
event GainedChild(Actor C)
{
	`Log(Self $ ": Gained child" @ C);

	Super.GainedChild(C);
	NumClients++;

	//If we have defined a number of maximum clients and passed that, stop listening for new connections
	if (MaxClients > 0 && NumClients >= MaxClients && LinkState == STATE_Listening) {
		`Log(Self $ ": Maximum number of clients connected, rejecting new clients");
		Close();
	}
}

//As defined in Engine::Actor, LostChild is called for every child class lost
//In this case, this is for every lost socket connection - so track number of connections here
event LostChild( Actor C )
{
	`Log(Self $ ": Lost child" @ C);

	Super.LostChild(C);
	NumClients--;

	//If we have fallen below our defined number of maximum clients, attempt to listen for new connections again
	if (NumClients < MaxClients && LinkState != STATE_Listening) {
		`Log(Self $ ": Listening for incoming connections");
		Listen();
	}
}

defaultproperties
{
	MaxClients=0 //0 or below: Unlimited
	ListenPort=3742

	//As defined in IpDrv::TcpLink, the child class spawned for each new incoming connection
	//SimLinkServerChild handles the individual Controller-AUV interactions
	AcceptClass=class'SimLinkServerChild'
}
