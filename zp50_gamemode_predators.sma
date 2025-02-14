/*================================================================================
 
	-------------------------------
	-*- [ZP] Game Mode: Predators -*-
	-------------------------------
 
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
 
================================================================================*/
 
#include <amxmodx>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_class_predator>
#include <zp50_deathmatch>
#include <zp50_grenade_frost>
#include <zp50_gamemodes>
#include <colorchat>
#include <zp50_ammopacks>
#include <fun> 
#include <amx_settings_api> 
#include <cs_teams_api> 
#include <dhudmessage>
 
// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"
 
// Default sounds
new const sound_predator[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/nemesis2.wav" }
 
#define SOUND_MAX_LENGTH 64
 
new Array:g_sound_predator
 
// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 24
#define HUD_EVENT_G 123
#define HUD_EVENT_B 205
 
new g_MaxPlayers
new g_HudSync
new g_TargetPlayer, g_TargetPlayer2, g_TargetPlayer3
 
new cvar_human_respawn_limit, cvar_respawn_delay
 
new cvar_predator_chance, cvar_predator_min_players
new cvar_predator_show_hud, cvar_predator_sounds
new cvar_predator_allow_respawn
 
new g_countdown
new CvrVoxType
new iMode
new g_hudmsg

new const Float:g_flCoords[] = {-0.10, -0.15, -0.20}
new g_iPos[33]
 
new cvar_pre_hp


#define TASK_NUM 333333
 
new respawn_limit[33]
 
public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Predators", ZP_VERSION_STRING, "xWOLETY")
	zp_gamemodes_register("Predators Mode")
 
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
 
        RegisterHam(Ham_Killed, "player", "fw_PlayerKilled", 1)
 
	g_MaxPlayers = get_maxplayers()
 
        g_hudmsg = CreateHudSyncObj()
 
	cvar_predator_chance = register_cvar("zp_predators_chance", "95")
	cvar_predator_min_players = register_cvar("zp_predators_min_players", "0")
	cvar_predator_show_hud = register_cvar("zp_predators_show_hud", "1")
	cvar_predator_sounds = register_cvar("zp_predators_sounds", "1")
	cvar_predator_allow_respawn = register_cvar("zp_predators_allow_respawn", "0")
	cvar_human_respawn_limit = register_cvar("zp_human_respawn_limit", "2")
	cvar_respawn_delay = register_cvar("cvar_respawn_delay", "3.0")
        CvrVoxType = register_cvar("zp_vox_type", "1") //0 - male voice | 1 - female voice
        cvar_pre_hp = register_cvar("zp_three_pre_hp", "10000")

	// Initialize arrays
	g_sound_predator = ArrayCreate(SOUND_MAX_LENGTH, 1)
 
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND PREDATORS", g_sound_predator)
 
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_predator) == 0)
	{
		for (index = 0; index < sizeof sound_predator; index++)
			ArrayPushString(g_sound_predator, sound_predator[index])
 
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND PREDATORS", g_sound_predator)
	}
 
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_predator); index++)
	{
		ArrayGetString(g_sound_predator, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else 
			precache_sound(sound)
	}
}
 
public zp_fw_core_spawn_post(id)
{
	// Always respawn as human on assassin rounds
	zp_core_respawn_as_zombie(id, false)
}
 
// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_predator_allow_respawn))
		return PLUGIN_HANDLED;
 
	return PLUGIN_CONTINUE;
}
 
public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_predator_chance)) != 1)
			return PLUGIN_HANDLED;
 
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_predator_min_players))
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
	g_countdown = 5
	
	new szPedo1[32], szPedo2[32], szPedo3[32]
 
	switch (GetAliveCount())
	{
		case 1..5: 
		{
			if (!zp_class_predator_get(g_TargetPlayer))
				zp_class_predator_set(g_TargetPlayer)
		}
		case 6..15: 
		{
			if (!zp_class_predator_get(g_TargetPlayer))
				zp_class_predator_set(g_TargetPlayer)
 
			if (!zp_class_predator_get(g_TargetPlayer2))
				zp_class_predator_set(g_TargetPlayer2)
		}
		case 16..32: 
		{
			if (!zp_class_predator_get(g_TargetPlayer))
				zp_class_predator_set(g_TargetPlayer)
 
			if (!zp_class_predator_get(g_TargetPlayer2))
				zp_class_predator_set(g_TargetPlayer2)
 
			if (!zp_class_predator_get(g_TargetPlayer3))
				zp_class_predator_set(g_TargetPlayer3)
		}
    }

	switch (GetAliveCount())
	{
	case 1..5:
	{
       
	zp_grenade_frost_set(g_TargetPlayer, 5.0)
	}
	case 6..15:
	{
	zp_grenade_frost_set(g_TargetPlayer, 5.0)
	zp_grenade_frost_set(g_TargetPlayer2, 5.0)
	}
	case 16..32:
	{
	zp_grenade_frost_set(g_TargetPlayer, 5.0)
	zp_grenade_frost_set(g_TargetPlayer2, 5.0)
	zp_grenade_frost_set(g_TargetPlayer3, 5.0)
	}
	}
        




 
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
	// Only those of them who aren't zombies
	if (!is_user_alive(id) || zp_core_is_zombie(id))
	continue;
 
        ColorChat (id, GREEN, "^x01[^x04LG*|^x01] You have only^x03 %d lives.^x01 Don't get killed by the predators!", get_pcvar_num(cvar_human_respawn_limit)) 
 
	cs_set_player_team(id, CS_TEAM_CT)
	respawn_limit[id] = 0
	}
 
	server_cmd("zp_deathmatch 0")
	
	
	set_task(1.0, "Countdown", 0, "", 0, "a", 5);
 
	// Play Predator sound
	if (get_pcvar_num(cvar_predator_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_predator, random_num(0, ArraySize(g_sound_predator) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
 
	if (get_pcvar_num(cvar_predator_show_hud))  
	{  
		// Show First Zombie HUD notice  
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 0, 0.0, 5.0, 1.0, 1.0, -1)  
 
		switch (GetAliveCount())
		{
			case 1..7: 
			{
				get_user_name(g_TargetPlayer, szPedo1, charsmax(szPedo1))
 
				ShowSyncHudMsg(0, g_HudSync, "%s is a Predator!", szPedo1)
                                ColorChat (0, GREEN, "^x01[^x04LG*|^x01] ^x04%s^x01 is the predator!", szPedo1)
			}
			case 8..15: 
			{
				get_user_name(g_TargetPlayer, szPedo1, charsmax(szPedo1))
				get_user_name(g_TargetPlayer2, szPedo2, charsmax(szPedo2))  
 
				ShowSyncHudMsg(0, g_HudSync, "%s and %s are the predators!", szPedo1, szPedo2) 
                                ColorChat (0, GREEN, "^x01[^x04LG*|^x01] ^x04%s^x01 and ^x04%s^x01 are the predators!", szPedo1, szPedo2)
			}
			case 16..32: 
			{
				get_user_name(g_TargetPlayer, szPedo1, charsmax(szPedo1))
				get_user_name(g_TargetPlayer2, szPedo2, charsmax(szPedo2))  
				get_user_name(g_TargetPlayer3, szPedo3, charsmax(szPedo3))  
 
				ShowSyncHudMsg(0, g_HudSync, "%s, %s and %s are predators!", szPedo1, szPedo2, szPedo3) 
                                ColorChat (0, GREEN, "^x01[^x04LG*|^x01] ^x04%s^x01,^x04%s^x01 and ^x04%s^x01 are the predators!", szPedo1, szPedo2, szPedo3) 
			}
    	}
	}
}

public Countdown()
{
	set_hudmessage(0, 50, 200, -1.0, 0.35, 2, 1.1, 1.0, 0.01, 0.01)
	ShowSyncHudMsg(0, g_hudmsg, "Predators will be released in %d", g_countdown)
	
        static szNum[20]; num_to_word(g_countdown, szNum, 5);
        if(iMode) client_cmd(0, "spk fvox/%s", szNum);
        else client_cmd(0, "spk %s", szNum);
 
	if (g_countdown == 0)
	{
		ColorChat(0, BLUE,"[LG*|] The predators has been released!!" )
 
	}
	g_countdown--
}
 
 
public fw_PlayerKilled(victim, attacker, shouldgib)
{
new limit; limit = zp_class_predator_get_count() 
if( respawn_limit[victim] < limit )
{
set_task(get_pcvar_float(cvar_respawn_delay), "respawn", victim)
respawn_limit[victim]++;
ColorChat (victim, GREEN, "^x01[^x04LG*|^x01] You have only^x03 %d lives.^x01 remaining", (get_pcvar_num(cvar_human_respawn_limit) - respawn_limit[victim]))
}else if( respawn_limit[victim] >= get_pcvar_num(cvar_human_respawn_limit) -1)
ColorChat (victim, GREEN, "^x01[^x04LG*|^x01] You have no more lives remaining!!")
return;
}
 
public respawn(victim) {
ExecuteHamB(Ham_CS_RoundRespawn, victim)
ColorChat (victim, GREEN, "^x01[^x04LG*|^x01] You have been respawned. Dont get killed by the predators!")
}

public zp_fw_gamemodes_end()
{
	new id
	new gText[32]
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue;
		if(is_user_alive(id) && zp_class_predator_get(id))
		{
			get_user_name(id, gText, 31)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + 15)
			new iPos = ++g_iPos[id]
			if(iPos == sizeof(g_flCoords))
			{
			iPos = g_iPos[id] = 0
			}
			set_dhudmessage(0, 50, 200, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
			show_dhudmessage(id, "+15 points")
			client_printcolor(0,"/y[/gLG*| Predators/y] /t%s /yearned /t15 points /yfor defeating the humans!", gText)
		}
	}

}
 
// Plays a sound on clients
PlaySoundToClients(const sound[])
{
        iMode = get_pcvar_num(CvrVoxType)
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(0, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(0, "spk ^"%s^"", sound)
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

stock client_printcolor(const id,const input[], any:...)

{

	new msg[191], players[32], count = 1; vformat(msg,190,input,3);

	replace_all(msg,190,"/g","^4");    // green

	replace_all(msg,190,"/y","^1");    // normal

	replace_all(msg,190,"/t","^3");    // team

	    

	if (id) players[0] = id; else get_players(players,count,"ch");

	    

	for (new i=0;i<count;i++)

	{

		if (is_user_connected(players[i]))

		{

			message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("SayText"),_,players[i]);

			write_byte(players[i]);

			write_string(msg);

			message_end();

		}

	}

} 