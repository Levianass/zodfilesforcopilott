/*================================================================================
	
	-----------------------------
	-*- [ZP] Game Mode: tag -*-
	-----------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <cstrike>
#include <amx_settings_api>
#include <zp50_gamemodes>
#include <zp50_deathmatch>
#include <zp50_grenade_frost>
#include <fun>
#include <hamsandwich>
#include <cs_teams_api>
#include <engine>
#include <fakemeta>
#include <cs_teams_api>
#include <colorchat>
#include <zp50_ammopacks>
#include <dhudmessage>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_tag[][] = { "ambience/the_horror2.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_tag
new iMaxZ;
new iZ;
new g_Tag;
new iM_Time;
new g_UsersEntity[33];

new boom, RoundCount


// HUD messages
#define HUD_EVENT_X -1.0
#define HUD_EVENT_Y 0.17
#define HUD_EVENT_R 60
#define HUD_EVENT_G 129
#define HUD_EVENT_B 175

new g_MaxPlayers
new iHudSync
new cvar_tag_chance, cvar_tag_min_players
new cvar_tag_show_hud, cvar_tag_sounds
new cvar_tag_allow_respawn
new Float:iMaxTime
public plugin_init()
{
	register_event("CurWeapon", "block_weapons", "be", "1=1")
}
public plugin_precache()
{
	// Register game mode at precache (plugin gets paused after this)
	register_plugin("[ZP] Game Mode: tag", ZP_VERSION_STRING, "ZP Dev Team")
	zp_gamemodes_register("Zombie Tag Mode")
	
	// Create the HUD Sync Objects
	iHudSync = CreateHudSyncObj()
	
	g_MaxPlayers = get_maxplayers()
	register_concmd("say /check","heck_heck")
	register_concmd("say_team /check","heck_heck")
	register_clcmd("say ayy","wtf"); 
	cvar_tag_chance = register_cvar("zp_tag_chance", "95")
	cvar_tag_min_players = register_cvar("zp_tag_min_players", "0")
	cvar_tag_show_hud = register_cvar("zp_tag_show_hud", "1")
	cvar_tag_sounds = register_cvar("zp_tag_sounds", "1")
	cvar_tag_allow_respawn = register_cvar("zp_tag_allow_respawn", "0")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
        RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	// Initialize arrays
	g_sound_tag = ArrayCreate(SOUND_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND tag", g_sound_tag)
	
	// If we couldn't load custom sounds from file, use and save default ones
	new index
	if (ArraySize(g_sound_tag) == 0)
	{
		for (index = 0; index < sizeof sound_tag; index++)
			ArrayPushString(g_sound_tag, sound_tag[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ROUND tag", g_sound_tag)
	}
	
	// Precache sounds
	new sound[SOUND_MAX_LENGTH]
	for (index = 0; index < ArraySize(g_sound_tag); index++)
	{
		ArrayGetString(g_sound_tag, index, sound, charsmax(sound))
		if (equal(sound[strlen(sound)-4], ".mp3"))
		{
			format(sound, charsmax(sound), "sound/%s", sound)
			precache_generic(sound)
		}
		else
			precache_sound(sound)
	}
        boom = precache_model("sprites/zerogxplode.spr");

}

// Deathmatch module's player respawn forward
public zp_fw_deathmatch_respawn_pre(id)
{
	// Respawning allowed?
	if (!get_pcvar_num(cvar_tag_allow_respawn))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_choose_pre(game_mode_id, skipchecks)
{
	if (!skipchecks)
	{
		// Random chance
		if (random_num(1, get_pcvar_num(cvar_tag_chance)) != 1)
			return PLUGIN_HANDLED;
		
		// Min players
		if (GetAliveCount() < get_pcvar_num(cvar_tag_min_players))
			return PLUGIN_HANDLED;
	}
	
	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zp_fw_gamemodes_start()
{	
	g_Tag = 1;
	RoundCount = 0;

	zp_gamemodes_set_allow_infect()
	
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_alive(id))
			continue;
		

		cs_set_player_team(id, CS_TEAM_CT)
	
		strip_user_weapons(id)
		give_item(id,"weapon_knife")
		
		set_task(1.0, "check_weapon", id, _,_, "b")

	}
	

	set_task(2.0, "Check_Count");
	set_task(4.0,"Tag_Select");
	
	server_cmd("mp_round_infinite bf");
	server_cmd("zp_buy_custom_primary 0");
	server_cmd("zp_buy_custom_secondary 0");
	server_cmd("zp_buy_custom_time 0");
	server_cmd("zp_remove_dropped_weapons 0");
	
	ColorChat(0, GREEN, "^x01[^x04LG*|^x01] Game Begins!!!")	

	
	// Play tag sound
	if (get_pcvar_num(cvar_tag_sounds))
	{
		new sound[SOUND_MAX_LENGTH]
		ArrayGetString(g_sound_tag, random_num(0, ArraySize(g_sound_tag) - 1), sound, charsmax(sound))
		PlaySoundToClients(sound)
	}
	
	if (get_pcvar_num(cvar_tag_show_hud))
	{
		// Show tag HUD notice
		set_hudmessage(HUD_EVENT_R, HUD_EVENT_G, HUD_EVENT_B, HUD_EVENT_X, HUD_EVENT_Y, 1, 0.0, 2.0, 0.5, 0.5, -1)
		ShowSyncHudMsg(0, iHudSync, "Zombie Tag! Avoid infection!")
	}
}

public check_weapon(id)
{
	if(get_user_weapon(id) != CSW_KNIFE)
	{
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
	}
}
public zp_fw_gamemodes_end()
{
	g_Tag = 0;
	RoundCount = 0;
	server_cmd("mp_round_infinite 0");
	server_cmd("zp_buy_custom_primary 1");
	server_cmd("zp_buy_custom_secondary 1");
	server_cmd("zp_buy_custom_time 15");
	server_cmd("zp_remove_dropped_weapons 4");	
	iZ = 0;
	iMaxZ = 0;
	new id
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (!is_user_connected(id))
			continue;
			
		if(is_valid_ent(g_UsersEntity[id]))
			remove_entity(g_UsersEntity[id]);
			
		remove_task(id)
	}
	remove_task()

}
// Plays a sound on clients
PlaySoundToClients(const sound[])
{
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
public Tag_Select()
{

	// iMaxZombies is rounded up, in case there aren't enough players
	new id, alive_count = GetAliveCount()
	
	// Randomly turn iMaxZombies players into zombies
	while (iZ < iMaxZ)
	{
		// Choose random guy
		id = GetRandomAlive(random_num(1, alive_count))
		
		// Dead or already a zombie
		if (!is_user_alive(id) || zp_core_is_zombie(id))
			continue;
		
		// Turn into a zombie
		zp_core_infect(id, 0);
		iZ++;
	}
	//client_print(0,print_chat,"Selecting Zombies!");
	set_task(0.5,"heck_heck")
        set_task(iMaxTime, "beep_light");
        set_task(10.0 + iMaxTime,"make_zombies_explode");
        round();
}
public zp_fw_core_infect_post(id, attacker)
{
	if(g_Tag == 1)
	{
		if(is_user_connected(attacker) && is_user_alive(attacker) && is_user_connected(id) && is_user_alive(id))
		{
		zp_grenade_frost_set(id, true)
		zp_core_force_cure(attacker)
		set_task(2.0,"unfreeze",id)
		}
	}
}
public unfreeze(id)
{
	if(is_user_connected(id) && is_user_alive(id))
	{
		zp_grenade_frost_set(id, false)
	}
}
public block_weapons(id)
{
	if(g_Tag == 1 && is_user_connected(id) && is_user_alive(id))
	{
		if(get_user_weapon(id) != CSW_KNIFE)
         {
	 	strip_user_weapons(id)
		give_item(id,"weapon_knife")
         }
	}
}
public make_zombies_explode()
{
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
	// Only those of them who aren't zombies
	if (!is_user_alive(id) || !zp_core_is_zombie(id) || !is_user_connected(id) || g_Tag != 1)
		continue;
	// Make him explode
	user_kill(id, 0)

	}
	iZ = 0;
	set_task(4.0, "Tag_Select");
	client_cmd(0, "spk weapons/explode5")

}

// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	SetHamParamInteger(3, 2)

	new vOrigin[3],coord[3];
	get_user_origin(victim,vOrigin);
	vOrigin[2] -= 26
	coord[0] = vOrigin[0] + 150;
	coord[1] = vOrigin[1] + 150;
	coord[2] = vOrigin[2] + 800;
	create_explode(vOrigin);	
	
	if(is_valid_ent(g_UsersEntity[victim]))
		remove_entity(g_UsersEntity[victim]);
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	if (g_Tag == 1 && zp_core_is_last_human(victim))
	{
		zp_core_infect(victim, attacker)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	if (g_Tag == 1 && zp_core_is_last_human(victim))
	{
		zp_core_infect(victim, attacker)
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public wtf(player)
{
	client_print(0,print_chat,"lmao")
}

public heck_heck(id)
{
	//client_print(0,print_chat,"Current Max Zombies count : %d, Current Zombies Number : %d, Max round time : %d Seconds ", iMaxZ, iZ, iM_Time + 20);
}

public beep_light() 
{
	beep1()
	set_task(1.0, "beep1", 0, "", 0, "a", 7);
	set_task(8.0, "beep4");
	set_task(9.0, "beep5");
	red_light()
	set_task(2.0, "red_light", 0, "", 0, "a", 4);
}
public beep1() client_cmd(0, "spk weapons/c4_beep1")
public beep4() client_cmd(0, "spk weapons/c4_beep4")
public beep5() client_cmd(0, "spk weapons/c4_beep5")
 
public red_light()
{	
    for(new i = 1; i <= get_maxplayers(); i++) {

        if(!is_user_alive(i) || !zp_core_is_zombie(i))
            continue;

        new fOrigin[3];
        pev(i, pev_origin, fOrigin);
        new iEnt = create_entity("info_target");

        set_pev(iEnt, pev_classname, "redled_sprite");

        // Set the light origin //

        engfunc( EngFunc_SetOrigin, iEnt, fOrigin )


        set_pev(iEnt, pev_rendermode, 5);
        set_pev(iEnt, pev_renderamt, 150.0);
        set_pev(iEnt, pev_scale, 1.0);
        engfunc(EngFunc_SetModel, iEnt, "sprites/ledglow.spr");
        set_pev(iEnt, pev_movetype, MOVETYPE_FOLLOW);
        set_pev(iEnt, pev_aiment, i);
        g_UsersEntity[i] = iEnt;
		
        set_task(1.0, "remove_red_light", i);
 
    }
	
}

public remove_red_light(i)
{
	if(is_valid_ent(g_UsersEntity[i]))
		remove_entity(g_UsersEntity[i]);
}

round()
{
	RoundCount++
	SetRoundTime(11 + iM_Time)
	set_dhudmessage(60, 129, 175, -1.0, 0.17, 0, 0.0, 2.0, 1.0)
	if(GetAliveCount() <= 2 ) show_dhudmessage(0, "Last Round!")
	else show_dhudmessage(0, "Round %d !", RoundCount)	

	
	client_cmd(0, "spk zombie_plague/survivor1")
}

SetRoundTime(Time)
{
    message_begin(MSG_BROADCAST, get_user_msgid("RoundTime"), _, _)
    write_short(Time)
    message_end()
} 

public Check_Count()
{
if(g_Tag == 1)
{
	if(GetAliveCount() > 1) set_task(2.0,"Check_Count")
	else 
	{
		announce_winner()
	}
	if(GetAliveCount() <= 3 ) iMaxZ = 1;
	else if(GetAliveCount() < 5 ) iMaxZ = 2;
	else if(GetAliveCount() < 12 ) iMaxZ = 3;
	else if(GetAliveCount() < 18 ) iMaxZ = 4;
	else if(GetAliveCount() < 22 ) iMaxZ = 5;
	else if(GetAliveCount() < 28 ) iMaxZ = 6;
	else if(GetAliveCount() < 32 ) iMaxZ = 7;
	
	if(GetAliveCount() <= 3 ) iMaxTime = 20.0
	else if(GetAliveCount() < 5 ) iMaxTime = 16.0
	else if(GetAliveCount() < 12 ) iMaxTime = 14.0
	else if(GetAliveCount() < 18 ) iMaxTime = 11.0
	else if(GetAliveCount() < 22 ) iMaxTime = 9.0
	else if(GetAliveCount() < 28 ) iMaxTime = 6.0
	else if(GetAliveCount() < 32 ) iMaxTime = 3.0
	
	if(GetAliveCount() <= 3 ) iM_Time = 20
	else if(GetAliveCount() < 5 ) iM_Time = 16
	else if(GetAliveCount() < 12 ) iM_Time = 14
	else if(GetAliveCount() < 18 ) iM_Time = 11
	else if(GetAliveCount() < 22 ) iM_Time = 9
	else if(GetAliveCount() < 28 ) iM_Time = 6
	else if(GetAliveCount() < 32 ) iM_Time = 3
}	
}

create_explode(vec1[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION2); 
	write_coord(vec1[0]); 
	write_coord(vec1[1]); 
	write_coord(vec1[2]); 
	write_byte(185); 
	write_byte(10); 
	message_end();
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(3)
	write_coord(vec1[0])
	write_coord(vec1[1])
	write_coord(vec1[2]+10)
	write_short(boom)
	write_byte(40)
	write_byte(15)
	write_byte(0)
	message_end()
}

public announce_winner()
{

	server_cmd("mp_round_infinite 0");
	server_cmd("zp_buy_custom_primary 1");
	server_cmd("zp_buy_custom_secondary 1");
	server_cmd("zp_buy_custom_time 15");
	server_cmd("zp_remove_dropped_weapons 4");	
	server_cmd("endround");
	iMaxZ = 0;
	new gText[32]
	for (new id = 1; id <= g_MaxPlayers; id++)
	{
		
		if(!is_user_connected(id) || !is_user_alive(id))
			continue;
		get_user_name(id, gText, 31)
		zp_ammopacks_set(id, zp_ammopacks_get(id) + 50)
		client_printcolor(0,"/g[ZoP*|] /t%s /yearned /t50 points! /yfor winning zombie tag!", gText)

	}
        set_dhudmessage(60, 129, 175, -1.0, 0.17, 0, 0.0, 2.0, 0.1, 1.0)
        show_dhudmessage(0, "%s is the winner !!", gText)
	//client_print(0,print_chat,"Round has ended!");
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

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1055\\ f0\\ fs16 \n\\ par }
*/
