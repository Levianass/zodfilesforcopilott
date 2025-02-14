#include < amxmodx >
#include < hamsandwich >
#include < cs_player_models_api >
#include < zp50_core >
#include < zp50_class_nemesis >
#include < zp50_class_survivor >
#include < zp50_class_predator >
#include < zp50_class_dragon >
#include < zp50_class_knifer >
#include < zp50_class_plasma >
#include < zp50_class_sniper >
#include < zp50_class_nightcrawler >
#include < zmvip >

new g_pluginInfo[][] =
{
	"[ZP50] Addon: VIP Model",
	"1.0",
	"De{a}gLe"
};

#define IsPlayer(%0) ( 1 <= (%0) <= get_maxplayers() ) // Thank you Connor !

new const g_vipModelHuman[][] = { "ns_vip_human" };
new const g_vipModelZombie[][] = { "ls_admin_zombie" };

public plugin_precache()
{
	register_plugin( g_pluginInfo[0], g_pluginInfo[1], g_pluginInfo[2] );
	RegisterHam( Ham_Spawn, "player", "forwardClientSpawn_Post", 1 );
	
	static index;
	for (index = 0; index < sizeof g_vipModelHuman; index++ )
	{
		static patch[126];
		formatex( patch, sizeof patch, "models/player/%s/%s.mdl", g_vipModelHuman[index], g_vipModelHuman[index] );
		precache_model( patch );
	}
	
	for (index = 0; index < sizeof g_vipModelZombie; index++ )
	{
		static patch[126];
		formatex( patch, sizeof patch, "models/player/%s/%s.mdl", g_vipModelZombie[index], g_vipModelZombie[index] );
		precache_model( patch );
	}
}

public forwardClientSpawn_Post( client, attacker )
{	
	if ( IsPlayer(client) && (zv_get_user_flags(client) & ZV_MAIN) )		
		cs_set_player_model( client, g_vipModelHuman[random_num(0, sizeof g_vipModelHuman  - 1)] );	
}

public zp_fw_core_cure_post( client, survvior )
{
	if ( zp_class_survivor_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_knifer_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_sniper_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_plasma_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_knifer_get(client) )
		return PLUGIN_HANDLED;
		
	if ( IsPlayer(client) && (zv_get_user_flags(client) & ZV_MAIN) )	
		cs_set_player_model( client, g_vipModelHuman[random_num(0, sizeof g_vipModelHuman  - 1)] );
		
	return PLUGIN_CONTINUE;
}

public zp_fw_core_infect_post( client, attacker )
{
	if ( zp_class_nemesis_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_predator_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_dragon_get(client) )
		return PLUGIN_HANDLED;

	if ( zp_class_nightcrawler_get(client) )
		return PLUGIN_HANDLED;
		
	if ( IsPlayer(client) && (zv_get_user_flags(client) & ZV_MAIN) )	
		cs_set_player_model( client, g_vipModelZombie[random_num(0, sizeof g_vipModelZombie - 1)] );
		
	return PLUGIN_CONTINUE;
}