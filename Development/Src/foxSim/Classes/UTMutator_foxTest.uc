/**
 * Simple mutator to spawn a TcpLinkServer test class
 */
class UTMutator_foxTest extends UTMutator
	config(Mutator_foxTest);

function InitMutator(string Options, out string ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);
	Spawn(class'TcpLinkServer');
}

defaultproperties
{
}