/*================================================================================
	
	---------------------------------
	-*- [ZP] Class: Zombie: Light -*-
	---------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <zp50_class_zombie>

// Light Zombie Attributes
new const zombieclass3_name[] = "Fast Zombie"
new const zombieclass3_info[] = "\r=Speed=" 
new const zombieclass3_models[][] = { "z_fast" }
new const zombieclass3_clawmodels[][] = { "models/zombie_plague/zow_claws.mdl" }
const zombieclass3_health = 2000
const Float:zombieclass3_speed = 1.10
const Float:zombieclass3_gravity = 0.80
const Float:zombieclass3_knockback = 1.30

new g_ZombieClassID

public plugin_precache()
{
	register_plugin("[ZP] Class: Zombie: Light", ZP_VERSION_STRING, "ZP Dev Team")
	
	new index
	
	g_ZombieClassID = zp_class_zombie_register(zombieclass3_name, zombieclass3_info, zombieclass3_health, zombieclass3_speed, zombieclass3_gravity)
	zp_class_zombie_register_kb(g_ZombieClassID, zombieclass3_knockback)
	for (index = 0; index < sizeof zombieclass3_models; index++)
		zp_class_zombie_register_model(g_ZombieClassID, zombieclass3_models[index])
	for (index = 0; index < sizeof zombieclass3_clawmodels; index++)
		zp_class_zombie_register_claw(g_ZombieClassID, zombieclass3_clawmodels[index])
}
