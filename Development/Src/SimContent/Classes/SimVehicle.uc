/*
 * TODO document this
 */
class SimVehicle extends UTVehicle_Cicada_Content;

//Set proper physics when exploding
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

// 	//Allow rolling
// 	bMustBeUpright=false
// 	bStayUpright=false
// 	RotationRate=(Pitch=20000,Yaw=20000,Roll=20000)
}
