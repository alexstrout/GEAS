/*
 * TODO document this
 */
class SimPlayerController extends UDKPlayerController;

reliable client function ClientSetHUD(class<HUD> newHUDType)
{
	Super.ClientSetHUD(newHUDType);

	if (myHUD != None)
		myHUD.bShowDebugInfo = true;
}

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
