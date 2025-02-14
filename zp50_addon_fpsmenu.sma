/*-----------------------------------------------------------------------------------------------------
				[ZP] Addon: FPS Menu

		- Plugin Information:

		* This Plugin is Made For Optimazing Players FPS By Changing Map Lightning, Changing NightVision Settings, Removing The Aura or Keep it

		- Credits:
		
		Gaspatcho: For The Original Plugin And The idea From This Link, For Fixing My NightVision Changer
		
		ShaunCraft: Fix The Lightning Problem And Make The NightVision Changer System
		
		- YouTube:
		
		* Link: https://www.youtube.com/channel/UCWVhiguRxt4tyacImGjiqQw
		
		- Releases:
		
		V1.0:
		
		* First Release
		* Fix The Lightning
		* Supported For All ZPS
		* With Natives
		
		V1.1:
		
		* Added Disabling Flare Lighting
		* Fix The Menu And The Variables
		* Fix The Lightning (Again)
		* New NightVision Style Added (Hybrid)
		
		
		Sorry For bad english!!!
		
		Enjoy With This Plugin :)
		
------------------------------------------------------------------------------------------------------*/

#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <zp50_nightvision>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#include <zp50_colorchat>
#include <zp50_gamemodes>

#define LOWMAP_LIGHT "c"

#define DEFAULT_LIGHT "h"

//Allow Custom Classes (Dragon, Plasma, Knifer, NightCrawler)
//#define CUSTOM_CLASS

//Allow Custom Classes (Assassin, Sniper)
//#define CUSTOM_CLASS_2

#if defined CUSTOM_CLASS

#define LIBRARY_DRAGON "zp50_class_dragon"
#include <zp50_class_dragon>

#define LIBRARY_NIGHTCRAWLER "zp50_class_nightcrawler"
#include <zp50_class_nightcrawler>

#define LIBRARY_KNIFER "zp50_class_knifer"
#include <zp50_class_knifer>

#define LIBRARY_PLASMA "zp50_class_plasma"
#include <zp50_class_plasma>

#endif

#if defined CUSTOM_CLASS_2

#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>

#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>

#endif
#define PLUGIN "FPS Menu (Full Package) [ZP50 VERSION]"
#define VERSION "1.1"
#define AUTHOR "ShaunCraft"

//Map Low Light Task
#define TASK_LIGHT 100
#define ID_LIGHT (taskid - TASK_LIGHT)

//Max Players
#define MAXPLAYERS 32

new AuraMode[33], nVision[33], MapLight[33], iFlare[33]

const PEV_FLARE_COLOR = pev_punchangle

//All This Cvars For The New Style Of NightVision (Old Style)
new cvar_nem_r, cvar_nem_g, cvar_nem_b
new cvar_surv_r, cvar_surv_g, cvar_surv_b
new cvar_zombie_r, cvar_zombie_g, cvar_zombie_b
new cvar_hum_r, cvar_hum_g, cvar_hum_b
new cvar_spec_r, cvar_spec_g, cvar_spec_b

#if defined CUSTOM_CLASS
new cvar_drag_r, cvar_drag_g, cvar_drag_b
new cvar_knif_r, cvar_knif_g, cvar_knif_b
new cvar_plasm_r, cvar_plasm_g, cvar_plasm_b
new cvar_craw_r, cvar_craw_g, cvar_craw_b
#endif

#if defined CUSTOM_CLASS_2
new cvar_snip_r, cvar_snip_g, cvar_snip_b
new cvar_assassin_r, cvar_assassin_g, cvar_assassin_b
#endif

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

// Menu keys (Here i use Zombie Plague Menu Style Not The New Style Because The Keys Doesn't Work)
const KEYSMENU = MENU_KEY_1|MENU_KEY_2|MENU_KEY_3|MENU_KEY_4|MENU_KEY_5|MENU_KEY_6|MENU_KEY_7|MENU_KEY_8|MENU_KEY_9|MENU_KEY_0

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("say /fps", "showMenuFPS")
	register_clcmd("say /nvisionmenu", "showMenuNV")
	
	// Menus
	register_menu("FPS Menu", KEYSMENU, "menu_command")
	register_menu("NVMenu", KEYSMENU, "menu_nv")
	
	cvar_hum_r = register_cvar("zp_nvision14_hum_r", "1")
	cvar_hum_g = register_cvar("zp_nvision14_hum_g", "5")
	cvar_hum_b = register_cvar("zp_nvision14_hum_b", "0")
	
	cvar_zombie_r = register_cvar("zp_nvision14_zombie_r", "1")
	cvar_zombie_g = register_cvar("zp_nvision14_zombie_g", "5")
	cvar_zombie_b = register_cvar("zp_nvision14_zombie_b", "0")
	
	cvar_spec_r = register_cvar("zp_nvision14_spec_r", "1")
	cvar_spec_g = register_cvar("zp_nvision14_spec_g", "5")
	cvar_spec_b = register_cvar("zp_nvision14_spec_b", "0")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
	{
		cvar_nem_r = register_cvar("zp_nvision14_nem_r", "5")
		cvar_nem_g = register_cvar("zp_nvision14_nem_g", "1")
		cvar_nem_b = register_cvar("zp_nvision14_nem_b", "0")
	}
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
	{
		cvar_surv_r = register_cvar("zp_nvision14_surv_r", "0")
		cvar_surv_g = register_cvar("zp_nvision14_surv_g", "0")
		cvar_surv_b = register_cvar("zp_nvision14_surv_b", "10")
	}
	
	#if defined CUSTOM_CLASS
	
	// Dragon Class loaded?
	if (LibraryExists(LIBRARY_DRAGON, LibType_Library))
	{
		cvar_drag_r = register_cvar("zp_nvision14_drag_r", "5")
		cvar_drag_g = register_cvar("zp_nvision14_drag_g", "1")
		cvar_drag_b = register_cvar("zp_nvision14_drag_b", "0")
	}
	
	// Knifer Class loaded?
	if (LibraryExists(LIBRARY_KNIFER, LibType_Library))
	{
		cvar_knif_r = register_cvar("zp_nvision14_knif_r", "0")
		cvar_knif_g = register_cvar("zp_nvision14_knif_g", "0")
		cvar_knif_b = register_cvar("zp_nvision14_knif_b", "0")
	}
	
	// Plasma Class loaded?
	if (LibraryExists(LIBRARY_PLASMA, LibType_Library))
	{
		cvar_plasm_r = register_cvar("zp_nvision14_plasm_r", "0")
		cvar_plasm_g = register_cvar("zp_nvision14_plasm_g", "0")
		cvar_plasm_b = register_cvar("zp_nvision14_plasm_b", "0")
	}
	
	// NightCrawler Class loaded?
	if (LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library))
	{
		cvar_craw_r = register_cvar("zp_nvision14_craw_r", "5")
		cvar_craw_g = register_cvar("zp_nvision14_craw_g", "1")
		cvar_craw_b = register_cvar("zp_nvision14_craw_b", "0")
	}
	
	#endif
	
	#if defined CUSTOM_CLASS_2
	
	if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library))
	{
		cvar_assassin_r = register_cvar("zp_nvision14_assassin_r", "10")
		cvar_assassin_g = register_cvar("zp_nvision14_assassin_g", "0")
		cvar_assassin_b = register_cvar("zp_nvision14_assassin_b", "0")
	}
	
	// Knifer Class loaded?
	if (LibraryExists(LIBRARY_SNIPER, LibType_Library))
	{
		cvar_snip_r = register_cvar("zp_nvision14_snip_r", "0")
		cvar_snip_g = register_cvar("zp_nvision14_snip_g", "0")
		cvar_snip_b = register_cvar("zp_nvision14_snip_b", "0")
	}
	
	#endif
	
}
public plugin_natives()
{
	register_native("zp_get_nivison_info", "native_info", 1)
	register_native("zp_set_player_aura", "native_aura", 1)
	register_native("zp_set_player_flare", "native_flare", 1)
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	#if defined CUSTOM_CLASS
	if (equal(module, LIBRARY_DRAGON) || equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_NIGHTCRAWLER) || equal(module, LIBRARY_SNIPER) || equal(module, LIBRARY_KNIFER) || equal(module, LIBRARY_PLASMA))
		return PLUGIN_HANDLED;
	#endif
	
	#if defined CUSTOM_CLASS_2
	if (equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_SNIPER))
		return PLUGIN_HANDLED;
	#endif
	
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_SURVIVOR))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public native_info(id, c1, c2, c3) SetPlayerVision(id, c1, c2, c3)

public native_aura(id, c1, c2, c3, radius) SetPlayerAura(id, c1, c2, c3, radius)

public native_flare(id, c1, c2, c3, radius, duration) SetPlayerFlare(id, c1,c2,c3, radius, duration)

public client_connect(id) 
{
	if(is_user_connected(id))
	{
		MapLight[id] = false
		AuraMode[id] = false
		nVision[id] = 0
	}
}

public client_disconnect(id) 
{
	MapLight[id] = false
	AuraMode[id] = false
	nVision[id] = 0
}

public showMenuFPS(id)
{
	static menu[250]
	new len
	
	new Text[64], TextL[64], TextF[64]
	
	if(!AuraMode[id]) format(Text, charsmax(Text), "\r1.\w Disable Aura \r[OFF]^n")
	else format(Text, charsmax(Text), "\r1.\w Disable Aura \y[ON]^n")
	
	if(!MapLight[id]) format(TextL, charsmax(TextL), "\r2.\w Lower Map Lightning \r[OFF]^n")
	else format(TextL, charsmax(TextL), "\r2.\w Lower Map Lightning \y[ON]^n")
	
	if(!iFlare[id]) format(TextF, charsmax(TextF), "\r3.\w Disable Flare Lightning \r[OFF]^n^n^n")
	else format(TextF, charsmax(TextF), "\r3.\w Disable Flare Lightning \y[ON]^n^n^n")
	
	// Title
	len += formatex(menu[len], charsmax(menu) - len, "\y[Zombie Plague 5.0 | FPS Menu]^n^n")
	
	//Aura Text
	len += formatex(menu[len], charsmax(menu) - len, Text)
	
	//Map Light Text
	len += formatex(menu[len], charsmax(menu) - len, TextL)
	
	//Flare Text
	len += formatex(menu[len], charsmax(menu) - len, TextF)
	
	//NightVision Menu
	len += formatex(menu[len], charsmax(menu) - len, "\r4.\w Change NightVision Settings^n^n^n^n^n")
	
	len += formatex(menu[len], charsmax(menu) - len, "\r0.\w Exit^n")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu, -1, "FPS Menu")
	
}

public menu_command(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0:
		{
			AuraSwitch(id)
			set_task(0.3, "showMenuFPS", id)
		}
		case 1:
		{
			if(zp_gamemodes_get_current() == zp_gamemodes_get_id("Assassin Mode"))
			{
				zp_colored_print(id, "Sorry, You Can't Change Map Lightning on Assassin Round")
				return PLUGIN_HANDLED
			}
			else
			{
				LightSwitch(id)
				set_task(0.3, "showMenuFPS", id)
			}
		}
		case 2:
		{
			FlareSwitch(id)
			set_task(0.3, "showMenuFPS", id)
		}
		case 3: set_task(0.6, "showMenuNV", id)
	}
	
	return PLUGIN_HANDLED;
}
public LightSwitch(id)
{
	if(!MapLight[id])
	{
		if(nVision[id] == 3 && !zp_nightvision_get(id))
		return PLUGIN_HANDLED
		else MapLight[id] = true
	}
	else 
	{
		if(nVision[id] == 3 && !zp_nightvision_get(id))
		return PLUGIN_HANDLED
		else MapLight[id] = false
	}
	
	//Repeating The Task
	set_task(0.000001, "ChangeLight", id+TASK_LIGHT, _, _, "b", 1)
	
	return PLUGIN_CONTINUE
}
public ChangeLight(taskid)
{
	if(MapLight[ID_LIGHT]) set_player_light(ID_LIGHT, LOWMAP_LIGHT)
	else set_player_light(ID_LIGHT, DEFAULT_LIGHT)
	
	return PLUGIN_CONTINUE
}
	
public AuraSwitch(id)
{
	if(!AuraMode[id]) AuraMode[id] = true
	
	else AuraMode[id] = false
}

public FlareSwitch(id)
{
	if(!iFlare[id]) iFlare[id] = true
	
	else iFlare[id] = false
}
public showMenuNV(id)
{
	static menu1[250]
	new len

	new Text1[64], Text2[64], Text3[64], Text4[64]
	
	if(!nVision[id]) format(Text1, charsmax(Text1), "\r1.\w Default CS NightVision \r[Choosed]^n")
	else format(Text1, charsmax(Text1), "\r1.\w Default CS NightVision^n")
	
	if(nVision[id] == 1) format(Text2, charsmax(Text2), "\r2.\w Old Style \r[Choosed]^n")
	else format(Text2, charsmax(Text2), "\r2.\w Old Style^n")
	
	if(nVision[id] == 2) format(Text3, charsmax(Text3), "\r3.\w New Style (Best FPS) \r[Choosed]^n")
	else format(Text3, charsmax(Text3), "\r3.\w New Style (Best FPS) ^n")
	
	if(nVision[id] == 3) format(Text4, charsmax(Text4), "\r4.\w Hybird \r[Choosed]^n^n^n^n^n^n")
	else format(Text4, charsmax(Text4), "\r4.\w Hybird ^n^n^n^n^n^n")
	
	// Title
	len += formatex(menu1[len], charsmax(menu1) - len, "\y[Zombie Plague 5.0 | Change NightVision Settings]^n^n")
	
	//NightVision Style (Default)
	len += formatex(menu1[len], charsmax(menu1) - len, Text1)
	
	//NightVision Style1
	len += formatex(menu1[len], charsmax(menu1) - len, Text2)
	
	//NightVision Style2
	len += formatex(menu1[len], charsmax(menu1) - len, Text3)
	
	//NightVision Style3
	len += formatex(menu1[len], charsmax(menu1) - len, Text4)
	
	//Exit
	len += formatex(menu1[len], charsmax(menu1) - len, "\r0.\w Exit^n")
	
	// Fix for AMXX custom menus
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	show_menu(id, KEYSMENU, menu1, -1, "NVMenu")
}
public menu_nv(id, key)
{
	// Player disconnected?
	if (!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	switch (key)
	{
		case 0: 
		{
			nVision[id] = 0, set_task(0.5, "showMenuNV", id)
			if(zp_nightvision_get(id)) zp_nightvision_set(id, false)
		}
		case 1: 
		{
			nVision[id] = 1, set_task(0.5, "showMenuNV", id)
			if(zp_nightvision_get(id)) zp_nightvision_set(id, false)
		}
		case 2: 
		{
			nVision[id] = 2, set_task(0.5, "showMenuNV", id)
			if(zp_nightvision_get(id)) zp_nightvision_set(id, false)
		}
		case 3: 
		{
			nVision[id] = 3, set_task(0.5, "showMenuNV", id)
			if(zp_nightvision_get(id)) zp_nightvision_set(id, false)
		}
		
	}
	
	return PLUGIN_HANDLED;
}	
public SetPlayerFlare(id, c1, c2, c3, radius, duration)
{
	new Float:org[3]
	pev(id, pev_origin, org)
	
	new Players[MAXPLAYERS], i, PlayerCount, iPlayer
	get_players(Players, PlayerCount, "c")

	for (i = 0; i < PlayerCount; i++)
	{
		iPlayer = Players[i];
		
		if(iFlare[iPlayer]) continue;

		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = iPlayer)
		write_byte(TE_DLIGHT) // TE i
		engfunc(EngFunc_WriteCoord, org[0]) // x
		engfunc(EngFunc_WriteCoord, org[1]) // y
		engfunc(EngFunc_WriteCoord, org[2]) // z
		write_byte(radius) // radius
		write_byte(c1) // r
		write_byte(c2) // g
		write_byte(c3) // b
		write_byte(21) // life
		write_byte(duration) // decay rate
		message_end()
		
		// Sparks
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = iPlayer)
		write_byte(TE_SPARKS) // TE id
		engfunc(EngFunc_WriteCoord, org[0]) // x
		engfunc(EngFunc_WriteCoord, org[1]) // y
		engfunc(EngFunc_WriteCoord, org[2]) // z
		message_end()

	}
	
	return PLUGIN_CONTINUE

}
	
public SetPlayerVision(id, c1, c2, c3)
{
	new org[3];
	get_user_origin(id, org);
	
	switch(nVision[id])
	{
		case 0:
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT); // TE id
			write_coord(org[0]); // x
			write_coord(org[1]); // y
			write_coord(org[2]); // z
			write_byte(50); // radius
			write_byte(c1); // r
			write_byte(c2); // g
			write_byte(c3); // b
			write_byte(2); // life
			write_byte(0); // decay rate
			message_end();
		}
		case 1:
		{
			static r, g, b
			
			if(!is_user_alive(id))
			{
				r = get_pcvar_num(cvar_spec_r)
				g = get_pcvar_num(cvar_spec_g)
				b = get_pcvar_num(cvar_spec_b)
			}
			else if(zp_core_is_zombie(id))
			{
				if(LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
				{
					r = get_pcvar_num(cvar_nem_r)
					g = get_pcvar_num(cvar_nem_g)
					b = get_pcvar_num(cvar_nem_b)
				}
				
				#if defined CUSTOM_CLASS
				
				else if(LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
				{
					r = get_pcvar_num(cvar_drag_r)
					g = get_pcvar_num(cvar_drag_g)
					b = get_pcvar_num(cvar_drag_b)
				}
				
				else if(LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(id))
				{
					r = get_pcvar_num(cvar_craw_r)
					g = get_pcvar_num(cvar_craw_g)
					b = get_pcvar_num(cvar_craw_b)
				}
				
				#endif
				
				#if defined CUSTOM_CLASS_2
				
				else if(LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(id))
				{
					r = get_pcvar_num(cvar_assassin_r)
					g = get_pcvar_num(cvar_assassin_g)
					b = get_pcvar_num(cvar_assassin_b)
				}
				
				#endif
				
				else
				{
					r = get_pcvar_num(cvar_zombie_r)
					g = get_pcvar_num(cvar_zombie_g)
					b = get_pcvar_num(cvar_zombie_b)
				}
					
			}
			else
			{
				if(LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
				{
					r = get_pcvar_num(cvar_surv_r)
					g = get_pcvar_num(cvar_surv_g)
					b = get_pcvar_num(cvar_surv_b)
				}
				
				#if defined CUSTOM_CLASS
				
				else if(LibraryExists(LIBRARY_KNIFER, LibType_Library) && zp_class_knifer_get(id))
				{
					r = get_pcvar_num(cvar_knif_r)
					g = get_pcvar_num(cvar_knif_g)
					b = get_pcvar_num(cvar_knif_b)
				}
				
				else if(LibraryExists(LIBRARY_PLASMA, LibType_Library) && zp_class_plasma_get(id))
				{
					r = get_pcvar_num(cvar_plasm_r)
					g = get_pcvar_num(cvar_plasm_g)
					b = get_pcvar_num(cvar_plasm_b)
				}
				
				#endif
				
				#if defined CUSTOM_CLASS_2
				
				else if(LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(id))
				{
					r = get_pcvar_num(cvar_snip_r)
					g = get_pcvar_num(cvar_snip_g)
					b = get_pcvar_num(cvar_snip_b)
				}
				
				#endif
				
				else
				{
					r = get_pcvar_num(cvar_hum_r)
					g = get_pcvar_num(cvar_hum_g)
					b = get_pcvar_num(cvar_hum_b)
				}
			}
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT); // TE id
			write_coord(org[0]); // x
			write_coord(org[1]); // y
			write_coord(org[2]); // z
			write_byte(100); // radius
			write_byte(r); // r
			write_byte(g); // g
			write_byte(b); // b
			write_byte(2); // life
			write_byte(0); // decay rate
			message_end();
		}
		case 2:
		{
			if(!cs_get_user_nvg(id))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
				write_short(0); // duration
				write_short(0); // hold time
				write_short(0x0004); // fade type
				write_byte(c1);
				write_byte(c2);
				write_byte(c3);
				write_byte(70);
				message_end();
				if(MapLight[id]) set_player_light(id, LOWMAP_LIGHT)
				else set_player_light(id, DEFAULT_LIGHT)
			}
			else
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id);
				write_short(1<<10);
				write_short(1<<10);
				write_short(0x0000);
				write_byte(c1);
				write_byte(c2);
				write_byte(c3);
				write_byte(70);
				message_end();
				set_player_light(id, "z")
			}
		}
		case 3:
		{
			if(!cs_get_user_nvg(id))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id);
				write_short(0); // duration
				write_short(0); // hold time
				write_short(0x0004); // fade type
				write_byte(c1);
				write_byte(c2);
				write_byte(c3);
				write_byte(70);
				message_end();
			}
			else
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), {0,0,0}, id);
				write_short(1<<10);
				write_short(1<<10);
				write_short(0x0000);
				write_byte(c1);
				write_byte(c2);
				write_byte(c3);
				write_byte(70);
				message_end();
			}
			
			static r, g, b
			
			if(!is_user_alive(id))
			{
				r = get_pcvar_num(cvar_spec_r)
				g = get_pcvar_num(cvar_spec_g)
				b = get_pcvar_num(cvar_spec_b)
			}
			else if(zp_core_is_zombie(id))
			{
				if(LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
				{
					r = get_pcvar_num(cvar_nem_r)
					g = get_pcvar_num(cvar_nem_g)
					b = get_pcvar_num(cvar_nem_b)
				}
				
				#if defined CUSTOM_CLASS
				
				else if(LibraryExists(LIBRARY_DRAGON, LibType_Library) && zp_class_dragon_get(id))
				{
					r = get_pcvar_num(cvar_drag_r)
					g = get_pcvar_num(cvar_drag_g)
					b = get_pcvar_num(cvar_drag_b)
				}
				
				else if(LibraryExists(LIBRARY_NIGHTCRAWLER, LibType_Library) && zp_class_nightcrawler_get(id))
				{
					r = get_pcvar_num(cvar_craw_r)
					g = get_pcvar_num(cvar_craw_g)
					b = get_pcvar_num(cvar_craw_b)
				}
				
				#endif
				
				#if defined CUSTOM_CLASS_2
				
				else if(LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(id))
				{
					r = get_pcvar_num(cvar_assassin_r)
					g = get_pcvar_num(cvar_assassin_g)
					b = get_pcvar_num(cvar_assassin_b)
				}
				
				#endif
				
				else
				{
					r = get_pcvar_num(cvar_zombie_r)
					g = get_pcvar_num(cvar_zombie_g)
					b = get_pcvar_num(cvar_zombie_b)
				}
					
			}
			else
			{
				if(LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(id))
				{
					r = get_pcvar_num(cvar_surv_r)
					g = get_pcvar_num(cvar_surv_g)
					b = get_pcvar_num(cvar_surv_b)
				}
				
				#if defined CUSTOM_CLASS
				
				else if(LibraryExists(LIBRARY_KNIFER, LibType_Library) && zp_class_knifer_get(id))
				{
					r = get_pcvar_num(cvar_knif_r)
					g = get_pcvar_num(cvar_knif_g)
					b = get_pcvar_num(cvar_knif_b)
				}
				
				else if(LibraryExists(LIBRARY_PLASMA, LibType_Library) && zp_class_plasma_get(id))
				{
					r = get_pcvar_num(cvar_plasm_r)
					g = get_pcvar_num(cvar_plasm_g)
					b = get_pcvar_num(cvar_plasm_b)
				}
				
				#endif
				
				#if defined CUSTOM_CLASS_2
				
				else if(LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(id))
				{
					r = get_pcvar_num(cvar_snip_r)
					g = get_pcvar_num(cvar_snip_g)
					b = get_pcvar_num(cvar_snip_b)
				}
				
				#endif
				
				else
				{
					r = get_pcvar_num(cvar_hum_r)
					g = get_pcvar_num(cvar_hum_g)
					b = get_pcvar_num(cvar_hum_b)
				}
			}
			
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id);
			write_byte(TE_DLIGHT); // TE id
			write_coord(org[0]); // x
			write_coord(org[1]); // y
			write_coord(org[2]); // z
			write_byte(100); // radius
			write_byte(r); // r
			write_byte(g); // g
			write_byte(b); // b
			write_byte(2); // life
			write_byte(0); // decay rate
			message_end();
		}
		
		
	}
}
public SetPlayerAura(id, c1, c2, c3, radius)
{
	new org[3], color[3]

	color[0] = c1 // <--- RED
	color[1] = c2 // <--- GREEN
	color[2] = c3 // <--- BLUE

	get_user_origin(id, org)

	new Players[MAXPLAYERS], i, PlayerCount, iPlayer
	get_players(Players, PlayerCount, "c")

	for (i = 0; i < PlayerCount; i++)
	{
		iPlayer = Players[i];
		
		if(AuraMode[iPlayer]) continue;

		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, .player = iPlayer)
		write_byte(TE_DLIGHT) // TE id
		write_coord(org[0]) // x
		write_coord(org[1]) // y
		write_coord(org[2]) // z
		write_byte(radius) // radius
		write_byte(color[0]) // r
		write_byte(color[1]) // g		
		write_byte(color[2]) // b
		write_byte(2) // life
		write_byte(0) // decay rate
		message_end()

	}

}

stock set_player_light(id, const LightStyle[])
{
	message_begin(MSG_ONE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
	
	return 1
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1046\\ f0\\ fs16 \n\\ par }
*/
