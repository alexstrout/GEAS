/**
 * SimSensorDepth - GEAS 2013, Alex Strout
 * Return our owner's depth
 */
class SimSensorDepth extends SimSensor;

//Our water level is actually at Z -128 in SimTerrain, so factor that in
function string Query(optional byte Mode = 0)
{
	return string(-(Owner.Location.Z + 128.0));
}

defaultproperties
{
}
