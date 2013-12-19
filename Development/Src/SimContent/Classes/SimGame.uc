/**
 * SimGame - GEAS 2013, Alex Strout
 * The "gametype" responsible for spawning the TcpLink server that listens for GEAS clients (incoming socket connections)
 * Also forces Unreal viewports into a "Spectator" mode
 * This is set on a per-level basis via View -> World Properties -> Game Type in the editor
 */
class SimGame extends UDKGame;

//Spawn the TcpLink server that will listen for GEAS clients
function StartMatch()
{
	//Do the usual stuff first...
	//See Engine::GameInfo.StartMatch()
	Super.StartMatch();

	//Actually spawn the TcpLink server to listen for socket connections
	//SimLinkServer will manage all incoming connections, so all we have to do here is spawn it
	Spawn(class'SimLinkServer');
}

//Force incoming Unreal clients to a "Spectator" mode
event PlayerController Login(string Portal, string Options, const UniqueNetID UniqueID, out string ErrorMessage)
{
	//Normally, a gametype's Login will spawn and possess a default pawn for an incoming player.
	//However, if SpectatorOnly is passed in on the URL (e.g. "UDK SimTerrain?Listen?SpectatorOnly=1")
	//it will prevent this and just keep the player as a floating camera (which is what we want).
	//SimPlayerController then provides additional functionality for viewing active AUVs using the scroll wheel
	//Thus, we'll force SpectatorOnly by concatnating the URL
	Options $= "?SpectatorOnly=1";

	//See Engine::GameInfo.Login()
	return Super.Login(Portal, Options, UniqueID, ErrorMessage);
}

defaultproperties
{
	//The PlayerController class spawned in Login - see SimPlayerController and Engine::GameInfo.Login()
	PlayerControllerClass=class'SimPlayerController'

	//The Pawn class spawned for a non-spectator player in Login - see Engine::GameInfo.Login()
	//Currently not used since we're forcing spectators only, but probably good to set anyway
	DefaultPawnClass=class'SimPawn'
}
