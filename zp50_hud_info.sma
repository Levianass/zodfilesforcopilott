#include <amxmodx>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <zp50_class_human>
#include <zp50_class_zombie>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>
#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>
#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#define LIBRARY_PLASMA "zp50_class_plasma"
#include <zp50_class_plasma>
#define LIBRARY_KNIFER "zp50_class_knifer"
#include <zp50_class_knifer>
#define LIBRARY_WINOS "zp50_class_winos"
#include <zp50_class_winos>
#define LIBRARY_HUNTER "zp50_class_hunter"
#include <zp50_class_hunter>
#define LIBRARY_DIONE "zp50_class_dione"
#include <zp50_class_dione>
#define LIBRARY_PREDATOR "zp50_class_predator"
#include <zp50_class_predator>
#define LIBRARY_PLASMA "zp50_class_plasma"
#include <zp50_class_plasma>
#define LIBRARY_KNIFER "zp50_class_knifer"
#include <zp50_class_knifer>
#define LIBRARY_AMMOPACKS "zp50_ammopacks"
#include <zp50_ammopacks>

enum Level 
{ 
    Level1, 
    Level2, 
    Level3, 
    Level4, 
    Level5, 
    Level6, 
    Level7, 
    Level8, 
    Level9, 
    Level10 
} 

new const LevelName[10][] = { 
    "Rookie",
    "Rookie",
    "Killer",
    "Slayer",
    "Ruthless",
    "Executioner",   
    "Executioner",
    "Predator",
    "Unhuman",
    "Legendary"
}

const Float:HUD_SPECT_X = 0.6 
const Float:HUD_SPECT_Y = 0.8 
const Float:HUD_STATS_X = 0.02
const Float:HUD_STATS_Y = 0.92 

const HUD_STATS_ZOMBIE_R = 200 
const HUD_STATS_ZOMBIE_G = 250 
const HUD_STATS_ZOMBIE_B = 0 

const HUD_STATS_HUMAN_R = 0 
const HUD_STATS_HUMAN_G = 200 
const HUD_STATS_HUMAN_B = 250 

const HUD_STATS_SPEC_R = 255 
const HUD_STATS_SPEC_G = 255 
const HUD_STATS_SPEC_B = 255 

#define TASK_SHOWHUD 100 
#define ID_SHOWHUD (taskid - TASK_SHOWHUD) 

const PEV_SPEC_TARGET = pev_iuser2 

new g_MsgSync 
new Level:PlayerLevels[33]   

new Float:g_flGameTime[33], g_iFrames[33], Float:g_flFrameRate[33];

public plugin_init() 
{ 
    register_plugin("[ZP] HUD Information", ZP_VERSION_STRING, "ZP Dev Team") 
     
    g_MsgSync = CreateHudSyncObj() 
} 

public plugin_natives() 
{ 
    set_module_filter("module_filter") 
    set_native_filter("native_filter") 
} 
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_NIGHTCRAWLER) || equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_SNIPER) || equal(module, LIBRARY_KNIFER) || equal(module, LIBRARY_PLASMA) || equal(module, LIBRARY_AMMOPACKS) || equal(module, LIBRARY_WINOS) || equal(module, LIBRARY_DIONE) || equal(module, LIBRARY_PREDATOR) || equal(module, LIBRARY_HUNTER))
	return PLUGIN_HANDLED;
     
        return PLUGIN_CONTINUE; 
} 

public native_filter(const name[], index, trap) 
{ 
    if (!trap) 
        return PLUGIN_HANDLED; 
     
    return PLUGIN_CONTINUE; 
} 

public client_putinserver(id) 
{ 
    if (!is_user_bot(id)) 
    { 
        // Set the custom HUD display task 
        set_task(1.0, "ShowHUD", id+TASK_SHOWHUD, _, _, "b") 
    } 
} 

public client_disconnect(id) 
{ 
    remove_task(id+TASK_SHOWHUD) 
} 

// Show HUD Task 
public ShowHUD(taskid) 
{ 
		new player = ID_SHOWHUD 
     
		// Player dead? 
		if (!is_user_alive(player)) 
		{ 
		// Get spectating target 
		player = pev(player, PEV_SPEC_TARGET) 
         
		// Target not alive 
		if (!is_user_alive(player)) 
		return; 
		} 
     
		// Format classname 
		static class_name[32], transkey[64] 
		new red, green, blue 
     
		checkear_ammopacks(player) 
     
		if (zp_core_is_zombie(player)) // zombies 
		{ 
		red = HUD_STATS_ZOMBIE_R 
		green = HUD_STATS_ZOMBIE_G 
		blue = HUD_STATS_ZOMBIE_B 
         
		// Nemesis Class loaded?
		if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_NEMESIS")

		// Dragon Class loaded?
		else if (LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_DRAGON")

		// Nightcrawler Class loaded?
		else if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_NIGHTCRAWLER")

		// Winos Class loaded?
		else if (LibraryExists(LIBRARY_WINOS, LibType_Library) && zp_class_winos_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_WINOS")

		// Hunter Class loaded?
		else if (LibraryExists(LIBRARY_HUNTER, LibType_Library) && zp_class_hunter_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_HUNTER")

		// Dione Class loaded?
		else if (LibraryExists(LIBRARY_DIONE, LibType_Library) && zp_class_dione_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_DIONE")

		// Predator Class loaded?
		else if (LibraryExists(LIBRARY_PREDATOR, LibType_Library) && zp_class_predator_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_PREDATOR")
		else
		{
			zp_class_zombie_get_name(zp_class_zombie_get_current(player), class_name, charsmax(class_name))
			
			// ML support for class name
			formatex(transkey, charsmax(transkey), "ZOMBIENAME %s", class_name)
			if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey)
		}
        }
    else // humans 
    { 
        red = HUD_STATS_HUMAN_R 
        green = HUD_STATS_HUMAN_G 
        blue = HUD_STATS_HUMAN_B 
         
		// Survivor Class loaded?
		if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_SURVIVOR")

		// Sniper Class loaded?
		else if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_SNIPER")
                                
                                // Plasma Class loaded?
		else if (LibraryExists(LIBRARY_PLASMA, LibType_Library) && zp_class_plasma_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_PLASMA")

                                 // Knifer Class loaded?
		else if (LibraryExists(LIBRARY_KNIFER, LibType_Library) && zp_class_knifer_get(player))
			formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, "CLASS_KNIFER")
                                 
		else
        { 
            zp_class_human_get_name(zp_class_human_get_current(player), class_name, charsmax(class_name)) 
             
            // ML support for class name 
            formatex(transkey, charsmax(transkey), "HUMANNAME %s", class_name) 
            if (GetLangTransKey(transkey) != TransKey_Bad) formatex(class_name, charsmax(class_name), "%L", ID_SHOWHUD, transkey) 
        } 
    } 
    new player_name[32] ,authid[32]

    get_user_name(player, player_name, charsmax(player_name))
    get_user_authid(player, authid, charsmax(authid))
    // Spectating someone else? 
    if (player != ID_SHOWHUD) 
    {          
        // Show name, health, class, and money 
        set_hudmessage(HUD_STATS_SPEC_R, HUD_STATS_SPEC_G, HUD_STATS_SPEC_B, HUD_SPECT_X, HUD_SPECT_Y, 0, 6.0, 1.1, 0.0, 0.0, -1) 
         
        if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library)) 
            ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "Name: %s - %s - FPS: %d^nHP: %d - %L %s - %L %d - %s", player_name, authid, floatround(g_flFrameRate[player]), get_user_health(player), ID_SHOWHUD, "CLASS_CLASS", class_name,  
            ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(player), LevelName[PlayerLevels[player]]) 
        else 
            ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "%L: %s^nHP: %d - %L %s - %L $ %d - %s", ID_SHOWHUD, "SPECTATING", player_name, get_user_health(player), ID_SHOWHUD, "CLASS_CLASS", class_name,  
            ID_SHOWHUD, "MONEY1", cs_get_user_money(player), LevelName[PlayerLevels[player]]) 
    } 
    else 
    { 
     
        set_hudmessage(red, green, blue, HUD_STATS_X, HUD_STATS_Y, 0, 6.0, 1.1, 0.0, 0.0, -1) 
         
        if (LibraryExists(LIBRARY_AMMOPACKS, LibType_Library)) 
            ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "Name: %s - %s - FPS: %d^nHP: %d - %L %s - %L %d - %s", player_name, authid, floatround(g_flFrameRate[ID_SHOWHUD]), get_user_health(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name,  
            ID_SHOWHUD, "AMMO_PACKS1", zp_ammopacks_get(ID_SHOWHUD), LevelName[PlayerLevels[player]]) 
        else 
            ShowSyncHudMsg(ID_SHOWHUD, g_MsgSync, "HP: %d - %L %s - %s", get_user_health(ID_SHOWHUD), ID_SHOWHUD, "CLASS_CLASS", class_name,  
            LevelName[PlayerLevels[ID_SHOWHUD]]) 
    } 
} 

public client_PreThink(this)
{
    if (!is_user_alive(this))
        return;
    
    static Float:flGameTime;

    flGameTime = get_gametime();
    g_iFrames[this]++;

    if (flGameTime - g_flGameTime[this] < 1.0)
        return;

    g_flFrameRate[this] = (g_iFrames[this] * 0.5) * 2;
    g_iFrames[this] = 0;
    g_flGameTime[this] = flGameTime;
}

public checkear_ammopacks(id) 
{ 
    new ammopacks = zp_ammopacks_get(id) 
  
    if(ammopacks > 0 && ammopacks < 49)   
    { 
        PlayerLevels[id] = Level1; 
    } 
    else if (ammopacks < 1000) 
    { 
        PlayerLevels[id] = Level2; 
    } 
    else if(ammopacks < 5000) 
    { 
        PlayerLevels[id] = Level3; 
    } 
    else if(ammopacks < 10000) 
    { 
        PlayerLevels[id] = Level4; 
    } 
    else if(ammopacks < 20000) 
    { 
        PlayerLevels[id] = Level5; 
    } 
    else if(ammopacks < 30000) 
    { 
        PlayerLevels[id] = Level6; 
    } 
    else if(ammopacks < 40000) 
    { 
        PlayerLevels[id] = Level7; 
    } 
    else if(ammopacks < 50000) 
    { 
        PlayerLevels[id] = Level8; 
    } 
    else if(ammopacks < 60000) 
    { 
        PlayerLevels[id] = Level9; 
    } 
    else if(ammopacks < 70000) 
    { 
        PlayerLevels[id] = Level10; 
    } 
    else 
    { 
        PlayerLevels[id] = Level10; 
    }   
    set_task(0, "checkear_ammopacks", id) 
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
