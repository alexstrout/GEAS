/**
 * SimVehicle - GEAS 2013, Alex Strout
 * The actual "physical" AUV object
 * Simply an extension of an existing sample vehicle (in this case, the "Cicada" sample vehicle)
 * Mostly changes to vehicle handling etc. values in defaultproperties block to suit being underwater (vehicles normally blow up underwater)
 * Also contains sensors that may be queried
 */
class SimVehicle extends UTVehicle_Cicada_Content;

//Sensors for this vehicle - see defaultproperties block below
var SimSensorGPS SensorGPS;
var SimSensorDepth SensorDepth;

//Query general info about this vehicle using sensors in a nicely formatted statement
//See SimContent::SimSensor*.Query() for info on querying specific sensors
function string QueryInfo()
{
	return Self @ "at" @ SensorGPS.Query(0)
	@ "depth" @ SensorDepth.Query()
	@ "rot" @ SensorGPS.Query(1)
	@ "vel" @ SensorGPS.Query(2)
	@ "(" $ SensorGPS.Query(3) $ ")";
}

//Set proper physics when exploding
//See Engine::Pawn.Died() and Engine::Vehicle.Died()
function bool Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
	if (Super.Died(Killer, DamageType, HitLocation)) {
		//SetMovementPhysics();
		SetPhysics(PHYS_Swimming);
		return true;
	}

	return false;
}

defaultproperties
{
	//Add a SimSensorGPS as an attached component
	Begin Object class=SimSensorGPS name=SenGPS
		//defaultproperties for components (if any) may be defined here
		//See Engine::Pawn::defaultproperties for good examples of component definitions
	End Object
	Components.Add(SenGPS)
	SensorGPS=SenGPS //We don't have to explicitly carry a reference for this (we could loop components instead), but it's convenient

	//Do the same for SimSensorDepth
	Begin Object class=SimSensorDepth name=SenDepth
	End Object
	Components.Add(SenDepth)
	SensorDepth=SenDepth

	//Now for vehicle attributes
	//Don't allow vehicles to take water damage
	WaterDamage=0
	bTakeWaterDamageWhileDriving=false

	//Don't kick driver out when flipped
	bEjectPassengersWhenFlipped=false

	//Don't take misc. damage
	FireDamagePerSec=0
	UpsideDownDamagePerSec=0
	OccupiedUpsideDownDamagePerSec=0

	//Set handling values
	Mass=10240.0
	AccelRate=128.0
	AirSpeed=256.0
	WaterSpeed=256.0
	GroundSpeed=64.0

	//Make sure our vehicle can swim...
	bCanSwim=true
	Buoyancy=0.99

	//... and not fly
	bCanFly=false
	bJostleWhileDriving=false
// 	bFloatWhenDriven=false
//
// 	//Allow rolling
// 	//TODO this currently allows the vehicle to flip extremely easily; vehicle handling needs some work
// 	bMustBeUpright=false
// 	bStayUpright=false
// 	RotationRate=(Pitch=20000,Yaw=20000,Roll=20000)
}
