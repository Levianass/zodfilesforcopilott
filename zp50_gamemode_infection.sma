
/*================================================================================  
	
	---------------------------------  
	-*- [ZP] Game Mode: Infection -*-  
	---------------------------------  
	
	This plugin is part of Zombie Plague Mod and is distributed under the  
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.  
	
================================================================================*/  

#include <amxmodx>  
#include <fun>  
#include <fakemeta>  
#include <hamsandwich>  
#include <cs_teams_api>  
#include <cs_ham_bots_api>  
#include <zp50_gamemodes>  
#include <zp50_deathmatch>  
#include <colorchat>

// HUD messages  
#define HUD_EVENT_X -1.0  
#define HUD_EVENT_Y 0.17  
#define HUD_EVENT_R 255  
#define HUD_EVENT_G 0  
#define HUD_EVENT_B 0  

new g_MaxPlayers  
new g_HudSync  
new g_TargetPlayer, g_TargetPlayer2, g_TargetPlayer3

new cvar_infection_chance, cvar_infection_min_players  
new cvar_infection_show_hud  
new cvar_infection_allow_respawn, cvar_respawn_after_last_human  
new cvar_zombie_first_hp_multiplier 
new cvar_zombie_second_hp   
new cvar_zombie_secondt_hp   


public plugin_precache()  
{  
	// Register game mode at precache (plugin gets paused after this)  
	register_plugin("[ZP] Game Mode: Infection", ZP_VERSION_STRING, "ZP Dev Team")  
	new game_mode_id = zp_gamemodes_register("Infection Mode")  
	zp_gamemodes_set_default(game_mode_id)  
	
	// Create the HUD Sync Objects  
	g_HudSync = CreateHudSyncObj()  
	
	g_MaxPlayers = get_maxplayers()  
	
	cvar_infection_chance = register_cvar("zp_infection_chance", "1")  
	cvar_infection_min_players = register_cvar("zp_infection_min_players", "0")  
	cvar_infection_show_hud = register_cvar("zp_infection_show_hud", "1")  
	cvar_infection_allow_respawn = register_cvar("zp_infection_allow_respawn", "1")  
	cvar_respawn_after_last_human = register_cvar("zp_respawn_after_last_human", "1")  
	cvar_zombie_first_hp_multiplier = register_cvar("zp_zombie_first_hp_multiplier", "4.0") 
	cvar_zombie_second_hp = register_cvar("zp_zombie_second_hp", "2.0")  
	cvar_zombie_secondt_hp = register_cvar("zp_zombie_secondt_hp", "2.0")  

}  

// Deathmatch module's player respawn forward  
public zp_fw_deathmatch_respawn_pre(id)  
{  
	// Respawning allowed?  
	if (!get_pcvar_num(cvar_infection_allow_respawn))  
	return PLUGIN_HANDLED;  
	
	// Respawn if only the last human is left?  
	if (!get_pcvar_num(cvar_respawn_after_last_human) && zp_core_get_human_count() == 1)  
	return PLUGIN_HANDLED;  
	
	return PLUGIN_CONTINUE;  
}  

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)  
{  
	if (!skipchecks)  
	{  
		
		// Random chance  
		if (random_num(1, get_pcvar_num(cvar_infection_chance)) != 1)  
		return PLUGIN_HANDLED;  
		
		// Min players  
		if (GetAliveCount() < get_pcvar_num(cvar_infection_min_players))  
		return PLUGIN_HANDLED; 
		
	}  
	
	// Game mode allowed  
	return PLUGIN_CONTINUE;  
}  

public zp_fw_gamemodes_choose_post(game_mode_id, target_player) 
{ 
	
	
	// Pick player randomly? 
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player 

	g_TargetPlayer2 = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player 
	
	g_TargetPlayer3 = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player 

	
}  

public zp_fw_gamemodes_start()  
{  
	// Allow infection for this game mode  
	zp_gamemodes_set_allow_infect() 

	new szZombie1[32], szZombie2[32], szZombie3[32]
	
	if (GetAliveCountHuman() >= 28)  
	{     
		if(!zp_core_is_zombie(g_TargetPlayer3)) 
		{ 
			zp_core_infect(g_TargetPlayer3, g_TargetPlayer3)  
			set_user_health(g_TargetPlayer3, floatround(get_user_health(g_TargetPlayer3) * get_pcvar_float(cvar_zombie_secondt_hp)))  
		} 

		if(!zp_core_is_zombie(g_TargetPlayer2)) 
		{ 
			zp_core_infect(g_TargetPlayer2, g_TargetPlayer2)  
			set_user_health(g_TargetPlayer2, floatround(get_user_health(g_TargetPlayer2) * get_pcvar_float(cvar_zombie_second_hp)))  
		} 

		if(!zp_core_is_zombie(g_TargetPlayer)) 
		{ 
			zp_core_infect(g_TargetPlayer, g_TargetPlayer) 
			set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_zombie_first_hp_multiplier)))  
			
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			get_user_name(g_TargetPlayer2, szZombie2, charsmax(szZombie2))  
			get_user_name(g_TargetPlayer3, szZombie3, charsmax(szZombie3)) 

			
			ColorChat (0, GREEN, "^x01[^x04ZoP*|^x01] ^x04%s^x01,^x04%s^x01 and ^x04%s^x01 are the first infected!", szZombie1 ,szZombie2, szZombie3  )
		} 

	} 

	if (GetAliveCountHuman() >= 7)  
	{     

		if(!zp_core_is_zombie(g_TargetPlayer2)) 
		{ 
			zp_core_infect(g_TargetPlayer2, g_TargetPlayer2)  
			set_user_health(g_TargetPlayer2, floatround(get_user_health(g_TargetPlayer2) * get_pcvar_float(cvar_zombie_second_hp)))  
		} 

		if(!zp_core_is_zombie(g_TargetPlayer)) 
		{ 
			zp_core_infect(g_TargetPlayer, g_TargetPlayer) 
			set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_zombie_first_hp_multiplier)))  
			
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			get_user_name(g_TargetPlayer2, szZombie2, charsmax(szZombie2))

			
			ColorChat (0, GREEN, "[ZoP*|] ^x04%s^x01 and ^x04%s^x01 are the first infected!", szZombie1 ,szZombie2 )
		} 

	} 

	else if (GetAliveCountHuman() < 7 ) 
	{ 
		
		if(!zp_core_is_zombie(g_TargetPlayer)) 
		{ 
			zp_core_infect(g_TargetPlayer, g_TargetPlayer)  
			set_user_health(g_TargetPlayer, floatround(get_user_health(g_TargetPlayer) * get_pcvar_float(cvar_zombie_first_hp_multiplier)))  
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			
			ColorChat (0, GREEN, "^x01[^x04ZoP*|^x01] ^x04%s^x01 is the first zombie!", szZombie1)
		} 

	} 
	
	// Remaining players should be humans (CTs)  
	new id  
	for (id = 1; id <= g_MaxPlayers; id++)  
	{  
		// Not alive  
		if (!is_user_alive(id))  
		continue;  
		
		// This is our first zombie  
		if (zp_core_is_zombie(id))  
		continue;  
		
		// Switch to CT  
		cs_set_player_team(id, CS_TEAM_CT)  
	}  
	
	if (get_pcvar_num(cvar_infection_show_hud))  
	{  
		// Show First Zombie HUD notice  
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)  
		
		if (GetAliveCountHuman() >= 28)  
		{     
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			get_user_name(g_TargetPlayer2, szZombie2, charsmax(szZombie2))  
			get_user_name(g_TargetPlayer3, szZombie3, charsmax(szZombie3)) 
			
			ShowSyncHudMsg(0, g_HudSync, "%s is the first zombie!^n%s is second zombie!^n%s is third zombie!", szZombie1, szZombie2, szZombie3) 
		} 

		if (GetAliveCountHuman() >= 7)  
		{     
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			get_user_name(g_TargetPlayer2, szZombie2, charsmax(szZombie2))  
			
			ShowSyncHudMsg(0, g_HudSync, "%s and %s are the first infected!", szZombie1, szZombie2) 
		} 

		else if (GetAliveCountHuman() < 7 ) 
		{ 
			get_user_name(g_TargetPlayer, szZombie1, charsmax(szZombie1))
			
			ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_FIRST", szZombie1) 
		} 
	}  
}  

// Get Alive Count -returns alive players number-  
GetAliveCount()  
{  
	new iAlive, id  
	
	for (id = 1; id <= g_MaxPlayers; id++)  
	{  
		if (is_user_alive(id))  
		iAlive++  
	}  
	
	return iAlive;  
}  

// Get Alive Count -returns alive players number-  
GetAliveCountHuman()  
{  
	new iAlive, id  
	
	for (id = 1; id <= g_MaxPlayers; id++)  
	{  
		if (is_user_alive(id) && !zp_core_is_zombie(id))  
		iAlive++  
	}  
	
	return iAlive;  
}  

// Get Random Alive -returns index of alive player number target_index -  
GetRandomAlive(target_index)  
{  
	new iAlive, id  
	
	for (id = 1; id <= g_MaxPlayers; id++)  
	{  
		if (is_user_alive(id))  
		iAlive++  
		
		if (iAlive == target_index)  
		return id;  
	}  
	
	return -1;  
}  

stock ColorPrint(const id, const input[], any: ...)
{
	new count = 1, players[32]
	static msg[192]
	vformat(msg, 191, input, 3)
	
	replace_all(msg, 191, "!g", "^4")
	replace_all(msg, 191, "!y", "^1")
	replace_all(msg, 191, "!t", "^3")
	replace_all(msg, 191, "!t2", "^0")
	
	if (id) players[0] = id;else get_players(players, count, "ch")
	{
		for (new i = 0; i < count; i++)
		{
			if (is_user_connected( players[i]))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i])
				write_byte(players[i])
				write_string(msg)
				message_end()
			}
		}
	}
}

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ fbidis\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ ltrpar\\ lang1025\\ f0\\ fs16 \n\\ par }
*/