/**
 * SimSensor - GEAS 2013, Alex Strout
 * Base class for sensor objects - currently provides a single function, "query", to query the sensor info
 * Abstract; can not be directly used. Sensor objects should base themselves off this and implement "query"
 */
class SimSensor extends ActorComponent
	abstract;

//Return whatever this sensor should query
function string Query(optional byte Mode = 0) {}

defaultproperties
{
}
