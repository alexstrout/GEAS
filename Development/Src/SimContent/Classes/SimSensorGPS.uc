/**
 * SimSensorGPS - GEAS 2013, Alex Strout
 * Return our owner's GPS-related info based on mode:
 * 0 - Position (XYZ Tuple)
 * 1 - Rotation (XYZ Tuple)
 * 2 - Velocity (XYZ Tuple)
 * 3 - Velocity (Resolved)
 */
class SimSensorGPS extends SimSensor;

function string Query(optional byte Mode = 0)
{
	switch (Mode) {
		case 3:
			return string(VSize(Owner.Velocity));
		case 2:
			return string(Owner.Velocity);
		case 1:
			return string(Owner.Rotation);
		default: //0
			return string(Owner.Location);
	}
}

defaultproperties
{
}
