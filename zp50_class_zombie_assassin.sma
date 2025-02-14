/*================================================================================
	
	----------------------------------
	-*- [ZP] Class: Zombie: Raptor -*-
	----------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Raptor Zombie Attributes
new const zombieclass2_name[] = "Assassin Zombie"
new const zombieclass2_info[] = "\r=Gravity="
new const zombieclass2_models[][] = { "z_assassin" }
new const zombieclass2_clawmodels[][] = { "models/zombie_plague/zow_claws.mdl" }
const zombieclass2_health = 2000
const Float:zombieclass2_speed = 0.94
const Float:zombieclass2_gravity = 0.49
const Float:zombieclass2_knockback = 1.35

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Raptor", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass2_name, zombieclass2_info, zombieclass2_health, zombieclass2_speed, zombieclass2_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass2_knockback)
	for (index = 0; index < sizeof zombieclass2_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass2_models[index])
	for (index = 0; index < sizeof zombieclass2_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass2_clawmodels[index])
}
