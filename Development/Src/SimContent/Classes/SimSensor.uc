/**
 * SinSensor - GEAS 2013, Alex Strout
 * Base class for sensor objects - currently provides a single function, "query", to query the sensor info
 * Defined "within" SimVehicle so it directly access vehicle info
 */
class SimSensor extends ActorComponent
	abstract;

//Return whatever this sensor should query
function string Query(optional byte Mode = 0) {}

defaultproperties
{
}
