/*================================================================================
	
	-------------------------------
	-*- [ZP] Game Mode: Nemesis -*-
	-------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amx_settings_api>
#include <cs_teams_api>
#include <zp50_gamemodes>
#include <zp50_class_nemesis>
#include <zp50_deathmatch>
#include <hamsandwich>
#include <fakemeta>
#include <engine>
#include <fun>
#include <zp50_grenade_frost>
#include <colorchat>
#include <zp50_colorchat>
#include <zp50_random_spawn>
#include <zp50_ammopacks>
#include <dhudmessage>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

const TASK_COUNTDOWN = 3000

// Default sounds
new const sound_nemesis[][] = { "zombie_plague/nemesis1.wav" , "zombie_plague/nemesis2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_nemesis

// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 255
#define HUD_EVENT_G 20
#define HUD_EVENT_B 20

new g_MaxPlayers
new g_HudSync
new g_TargetPlayer
new g_countdown
new iMode
new CvrVoxType
new g_hudmsg
new g_iMsgSayTxt
new cvar_nemesis_chance, cvar_nemesis_min_players
new cvar_nemesis_show_hud, cvar_nemesis_sounds
new cvar_nemesis_allow_respawn

new const Float:g_flCoords[] = {-0.10, -0.15, -0.20}
new g_iPos[33]


public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: Nemesis", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Nemesis Mode")
	
	// Create the HUD Sync Objects
	g_HudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()

        g_hudmsg = CreateHudSyncObj()

        g_iMsgSayTxt = get_user_msgid("SayText")
	
	cvar_nemesis_chance = register_cvar("zp_nemesis_chance", "20")
	cvar_nemesis_min_players = register_cvar("zp_nemesis_min_players", "0")
	cvar_nemesis_show_hud = register_cvar("zp_nemesis_show_hud", "1")
	cvar_nemesis_sounds = register_cvar("zp_nemesis_sounds", "1")
        CvrVoxType = register_cvar("zp_vox_type", "1") //0 - male voice | 1 - female voice
	cvar_nemesis_allow_respawn = register_cvar("zp_nemesis_allow_respawn", "0")
	
	// Initialize arrays
	g_sound_nemesis = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND NEMESIS", g_sound_nemesis)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_nemesis) == 0)
	{
		for (index = 0; index < sizeof sound_nemesis; index++)
			ArrayPushString(g_sound_nemesis, sound_nemesis[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND NEMESIS", g_sound_nemesis)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_nemesis); index++)
	{
		ArrayGetString(g_sound_nemesis, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_nemesis_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	// Always respawn as human on nemesis rounds
	zp_core_respawn_as_zombie(id, false)
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_nemesis_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_nemesis_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_post(game_mode_id, target_player)
{
	// Pick player randomly?
	g_TargetPlayer = (target_player == RANDOM_TARGET_PLAYER) ? GetRandomAlive(random_num(1, GetAliveCount())) : target_player
        
}

public zp_fw_gamemodes_start()
{
	// Turn player into nemesis
        zp_grenade_frost_set(g_TargetPlayer)
	zp_class_nemesis_set(g_TargetPlayer)
	g_countdown = 5
        set_user_rendering(g_TargetPlayer, kRenderFxGlowShell, 0, 100, 200, kRenderNormal, 25)

	set_task(1.0, "Countdown", TASK_COUNTDOWN, .flags="b")

	
	// Remaining players should be humans (CTs)
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Not alive
		if (!is_user_alive(id))
			continue;
		
		// This is our Nemesis
		if (zp_class_nemesis_get(id))
			continue;
		
		// Switch to CT
		cs_set_player_team(id, CS_TEAM_CT)
	}
	
	// Play Nemesis sound
	if (get_pcvar_num(cvar_nemesis_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_nemesis, random_num(0, ArraySize(g_sound_nemesis) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)                
	}
	
	if (get_pcvar_num(cvar_nemesis_show_hud))
	{

		// Show Nemesis HUD notice
		new name[32]
		get_user_name(g_TargetPlayer, name, charsmax(name))
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 6.5, 1.0, 1.0, -1)
		ShowSyncHudMsg(0, g_HudSync, "%L", LANG_PLAYER, "NOTICE_NEMESIS", name) 
    
	}
}

public Countdown(task)
{
	set_hudmessage(255, 0, 0, -1.0, 0.35, 2, 1.1, 1.0, 0.01, 0.01, -2)
	ShowSyncHudMsg(0, g_hudmsg, "The Nemesis will be released in %d", g_countdown)
        static szNum[20]; num_to_word(g_countdown, szNum, 19);
        if(iMode) client_cmd(0, "spk fvox/%s", szNum);
        else client_cmd(0, "spk %s", szNum);

	g_countdown--;

	if (!g_countdown)
	{
		remove_task(TASK_COUNTDOWN)
		ColorChat(0, RED,"[LG*|] The Nemesis has been released!!" )
                
		
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

stock print_colored(const index, const input [ ], const any:...) 
{  
    new message[191] 
    vformat(message, 190, input, 3) 
    replace_all(message, 190, "!y", "^1") 
    replace_all(message, 190, "!t", "^3") 
    replace_all(message, 190, "!g", "^4") 

    if(index) 
    { 
        //print to single person 
        message_begin(MSG_ONE, g_iMsgSayTxt, _, index) 
        write_byte(index) 
        write_string(message) 
        message_end() 
    } 
    else 
    { 
        //print to all players 
        new players[32], count, i, id 
        get_players(players, count, "ch") 
        for( i = 0; i < count; i ++ ) 
        { 
            id = players[i] 
            if(!is_user_connected(id)) continue; 

            message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayTxt, _, id) 
            write_byte(id) 
            write_string(message) 
            message_end() 
        } 
    } 
}

public zp_round_started(gamemode, id)
{
	if(g_TargetPlayer)
	{
		zp_random_spawn_do(id,false)
	}

}

public zp_fw_gamemodes_end()
{
	new id
	new gText[32]
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue;
		if(is_user_alive(id) && zp_class_nemesis_get(id))
		{
			get_user_name(id, gText, 31)
			zp_ammopacks_set(id, zp_ammopacks_get(id) + 50)
			new iPos = ++g_iPos[id]
			if(iPos == sizeof(g_flCoords))
			{
			iPos = g_iPos[id] = 0
			}
			set_dhudmessage(255, 0, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
			show_dhudmessage(id, "+50 points")
			print_colored(0, "!g[LG*|] !t%s !yearned !t50 points !yfor defeating the humans!", gText)
		}
	}

}

