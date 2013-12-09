/**
 * TODO add description
 */
class SimGame extends UDKGame;

function StartMatch()
{
	Super.StartMatch();

	//Spawn the TcpLink server that will listen for GEAS clients
	Spawn(class'SimLinkServer');
}

event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	//Unreal clients should serve only as viewports here, so force the SpectatorOnly option
	//Options $= "?SpectatorOnly=1";

	return Super.Login(Portal, Options, UniqueID, ErrorMessage);
}

defaultproperties
{
}