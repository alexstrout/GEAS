/*
 * TODO document this
 */
class SimPlayerController extends UDKPlayerController;

exec function PTest()
{
	local Vehicle V;

	foreach WorldInfo.AllPawns(class'Vehicle', V)
		if (V.TryToDrive(Pawn))
			return;
}

defaultproperties
{
}
