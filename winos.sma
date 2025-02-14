#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fun>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <zp50_colorchat>
#include <cs_weap_models_api>
#include <zp50_core>
#include <xs>
#include <beams>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <zp50_class_zombie>

new g_Iswinos

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

#define PRIMARY_WEAPONS_BIT_SUM ((1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90))

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

// Custom models
new Array:g_models_winos_player
new Array:g_models_winos_claw

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

// Default models
new const models_winos_player[][] = { "winos" }
new const models_winos_claw[][] = { "models/zombie_plague/v_knife_winos.mdl" }

new const winos_knife_sounds[][] =
{
	"zombie_plague/deimos/attack_1.wav",
	"zombie_plague/deimos/attack_2.wav",
	"zombie_plague/deimos/attack_1.wav",
	"zombie_plague/deimos/attack_2.wav",
	"zombie_plague/deimos/stab.wav"
}

new const old_knife_sounds[][] =
{
	"weapons/knife_hit1.wav",
	"weapons/knife_hit2.wav",
	"weapons/knife_hit3.wav",
	"weapons/knife_hit4.wav",
	"weapons/knife_stab.wav"
}

new const Resource[][] = 
{
    "sprites/fluxing.spr"
}
static g_Resource[sizeof Resource]

new const health_sound[] = "zombi_heal.wav"
new const fluxing_sound[] = "zombie_plague/winos_fluxing.wav"
new const mutate_sound[] = "zombie_plague/vomit.wav"
new const skill_sound_wave[] = "slash.wav"	
new const deimos_skill[] = "zombie_plague/deimos_skill_hit.wav"	
new const deimos_skill_start[] = "zombie_plague/deimos_skill_start.wav"	
new const infect_sound[] = "zombie_plague/zombie_infec1.wav"	

#define SKILL_WAVE_RADIUS_KILL 200.0							
new const skill_wave_color_kill[3] = {150, 0, 150}				

#define SKILL_WAVE_RADIUS_MUTATE 200.0							
new const skill_wave_color_mutate[3] = {0, 150, 0}	

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define TASK_ICON_ID	64
#define TASK_ICON_DELAY	2.0	

new g_pResHP;
new Float:gLastUseCmd[ 33 ]
new g_Has1[33]
new g_Has2[33]
new g_Has3[33]
new g_Has4[33]
new g_HasOpened[33]
new g_engel[33]
new g_pBeam_[33]
new g_heal
new FluxSpr

new cvar_winos_base_health, cvar_winos_speed, cvar_winos_gravity
new cvar_winos_glow
new cvar_winos_aura, cvar_winos_aura_color_R, cvar_winos_aura_color_G, cvar_winos_aura_color_B
new cvar_winos_kill_explode
new cvar_winos_grenade_frost, cvar_winos_grenade_fire
new cvar_winos_lightning_effect

new frostsprite, pcvar_winos_freez_distance, pcvar_winos_freez_cooldown
new g_Sprite, deimos_spr, deimos_trail
new SprThunder, SprSmoke


public plugin_init()
{
	register_plugin("[ZP] Class: Winos", "4.0", "OW3R")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	register_clcmd("drop", "menuyukur");	
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	register_forward(FM_EmitSound, "fw_EmitSound");
	RegisterHam(Ham_Player_Duck, "player", "Player_Duck", 1);
	
	cvar_winos_base_health = register_cvar("zp_winos_base_health", "500")
	cvar_winos_speed = register_cvar("zp_winos_speed", "1.05")
	cvar_winos_gravity = register_cvar("zp_winos_gravity", "0.5")
	cvar_winos_glow = register_cvar("zp_winos_glow", "1")
	cvar_winos_aura = register_cvar("zp_winos_aura", "0")
	cvar_winos_aura_color_R = register_cvar("zp_winos_aura_color_R", "150")
	cvar_winos_aura_color_G = register_cvar("zp_winos_aura_color_G", "0")
	cvar_winos_aura_color_B = register_cvar("zp_winos_aura_color_B", "0")
	cvar_winos_kill_explode = register_cvar("zp_winos_kill_explode", "1")
	cvar_winos_grenade_frost = register_cvar("zp_winos_grenade_frost", "0")
	cvar_winos_grenade_fire = register_cvar("zp_winos_grenade_fire", "1")
	pcvar_winos_freez_distance = register_cvar("zp_winos_freez_distance", "400")
	pcvar_winos_freez_cooldown = register_cvar("zp_winos_freez_cooldown", "22.0")
	cvar_winos_lightning_effect = register_cvar("zp_winos_lightning_effect", "1")    
	g_pResHP = register_cvar("zp_winos_restore_hp", "200")  
}

public plugin_precache()
{
	// Initialize arrays
	g_models_winos_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_winos_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "winos", g_models_winos_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE winos", g_models_winos_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_winos_player) == 0)
	{
		for (index = 0; index < sizeof models_winos_player; index++)
			ArrayPushString(g_models_winos_player, models_winos_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "winos", g_models_winos_player)
	}
	if (ArraySize(g_models_winos_claw) == 0)
	{
		for (index = 0; index < sizeof models_winos_claw; index++)
			ArrayPushString(g_models_winos_claw, models_winos_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE winos", g_models_winos_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_winos_player); index++)
	{
		ArrayGetString(g_models_winos_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_winos_claw); index++)
	{
		ArrayGetString(g_models_winos_claw, index, model, charsmax(model))
		precache_model(model)
	}
	
	for(new i = 0; i < sizeof winos_knife_sounds; i++)
		precache_sound(winos_knife_sounds[i])   
		
	for(new i; i <= charsmax(Resource); i++)
        g_Resource[i] = precache_model(Resource[i])

	
	engfunc(EngFunc_PrecacheSound, health_sound)
	engfunc(EngFunc_PrecacheSound, fluxing_sound)
	engfunc(EngFunc_PrecacheSound, mutate_sound)
	engfunc(EngFunc_PrecacheSound, skill_sound_wave)
	engfunc(EngFunc_PrecacheSound, deimos_skill)
	engfunc(EngFunc_PrecacheSound, deimos_skill_start)	
	engfunc(EngFunc_PrecacheSound, infect_sound)			
	
	g_Sprite = precache_model("sprites/shockwave.spr");
	SprSmoke = precache_model("sprites/steam1.spr")
	g_heal = precache_model("sprites/cso_heal.spr")  
	deimos_spr = precache_model("sprites/deimosexp.spr")
	deimos_trail = precache_model("sprites/trail.spr")
	frostsprite = precache_model( "sprites/green.spr" )
}

public plugin_natives()
{
	register_library("zp50_class_winos")
	register_native("zp_class_winos_get", "native_class_winos_get")
	register_native("zp_class_winos_set", "native_class_winos_set")
	register_native("zp_class_winos_get_count", "native_class_winos_get_count")
	
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}


public module_filter(const module[])
{
	if (equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}

public client_disconnected(id)
{
	if (flag_get(g_Iswinos, id))
	{
		// Remove winos glow
		if (get_pcvar_num(cvar_winos_glow))
			set_user_rendering(id)
		
		// Remove winos aura
		if (get_pcvar_num(cvar_winos_aura))
			remove_task(id+TASK_AURA)
	}
}

public fw_EmitSound(id, channel, const sound[])
{		
	if(!is_user_connected(id))
		return FMRES_HANDLED;	
		
	if (!flag_get(g_Iswinos, id))
		return FMRES_HANDLED;	
		
	for(new i = 0; i < sizeof winos_knife_sounds; i++)
	{
		if(equal(sound, old_knife_sounds[i]))
		{
			emit_sound(id, channel, winos_knife_sounds[i], 1.0, ATTN_NORM, 0, PITCH_NORM)
			return FMRES_SUPERCEDE
		}
	}

			
	return FMRES_IGNORED
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was winos before disconnecting)
	flag_unset(g_Iswinos, id)
}

public zp_fw_core_infect_post(player, attacker)
{
	// Apply winos attributes?
	if (!flag_get(g_Iswinos, player))
		return;
	
	// Health
	set_user_health(player, get_pcvar_num(cvar_winos_base_health) * GetAliveCount())
	
	// Gravity
	set_user_gravity(player, get_pcvar_float(cvar_winos_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(player, get_pcvar_float(cvar_winos_speed))
	
	// Apply winos player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_winos_player, random_num(0, ArraySize(g_models_winos_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(player, player_model)
	
	// Apply winos claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_winos_claw, random_num(0, ArraySize(g_models_winos_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(player, CSW_KNIFE, model)	
	
	// Winos glow
	if (get_pcvar_num(cvar_winos_glow))
		set_user_rendering(player, kRenderFxGlowShell, 100, 0, 0, kRenderNormal, 16)
	
	// Winos aura task
	if (get_pcvar_num(cvar_winos_aura))
		set_task(0.1, "winos_aura", player+TASK_AURA, _, _, "b")
		
	client_print_color(player, 0, "^1[^4ZP^1] ^3Press G ^1use to skill menu");
		
	g_Has1[player] = true
	g_Has2[player] = false
	g_Has3[player] = false
	g_Has4[player] = false
	g_HasOpened[player] = false
	g_engel[player] = false
	
	if(is_user_bot(player))
	{
		set_task(21.0, "bot_can_skill", player, _,_, "b")
	}
}

public menuyukur(player)
{
	if (flag_get(g_Iswinos, player) && is_user_alive(player))
	{
		if(!g_HasOpened[player])
		{
			set_task(0.1, "menuyuacildi", player)
		}
		if(g_engel[player])
		{
			set_task(0.2, "show_hud2", player)
		}

	}
}

public menuyuacildi(player)
{
		g_HasOpened[player] = true
		gLastUseCmd[ player ] = get_gametime( )
		set_task(1.0, "show_hud", player, _, _, "a", 21)
		set_task(get_pcvar_float( pcvar_winos_freez_cooldown ), "show_hud2", player)
		set_task(1.0, "yazi", player)
}

public yazi(player)
{
	client_print_color(player, 0, "^1[^4ZP^1] ^1Your skill will be ready in ^3%0.f ^1seconds", get_pcvar_float( pcvar_winos_freez_cooldown ) - (get_gametime( ) - gLastUseCmd[ player ]));
}


public show_hud(player)
{

		new szUserId[32];
		new menu = menu_create("Winos Skills:", "winos_skill");
		
		if(g_Has1[player])
		{
			menu_additem(menu, "\dNext skill [\rMutate Skill\d]", "", 0); // case 0
		}
		if(g_Has2[player])
		{
			menu_additem(menu, "\dNext skill [\rKill Skill\d]", "", 0); // case 0
		}
		if(g_Has3[player])
		{
			menu_additem(menu, "\dNext skill [\rFluxing Skill\d]", "", 0); // case 0
		}
		if(g_Has4[player])
		{
			menu_additem(menu, "\dNext skill [\rWeap drop Skill\d]", "", 0); // case 0
		}
		
		formatex( szUserId, charsmax( szUserId ), "\dSkill will be ready in: \r%.0f", get_pcvar_float( pcvar_winos_freez_cooldown ) - (get_gametime( ) - gLastUseCmd[ player ]) );
		

		menu_addtext2(menu, szUserId);	
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(player, menu, 0);	
		
}

public winos_skill(player, menu, item)
{

	new data[6], name[128], access, callback;

	menu_item_getinfo(menu, item, access, data, sizeof data - 1, name, sizeof name - 1, callback);


	switch(item)
	{
		case 0: 
		{
				client_print_color(player, 0, "^1[^4ZP^1] ^1Your skill will be ready in ^3%0.f ^1seconds", get_pcvar_float( pcvar_winos_freez_cooldown ) - (get_gametime( ) - gLastUseCmd[ player ]));
		}
	}

	menu_destroy(menu);
}

public show_hud2(player)
{
		g_engel[player] = true

		new menu = menu_create("Winos Skills:", "winos_skill2");
		
		if(g_Has1[player])
		{
			menu_additem(menu, "Mutate Skill", "", 0); // case 0
		}
		if(g_Has2[player])
		{
			menu_additem(menu, "Kill Skill", "", 0); // case 0
		}
		if(g_Has3[player])
		{
			menu_additem(menu, "Fluxing Skill", "", 0); // case 0
		}
		if(g_Has4[player])
		{
			menu_additem(menu, "Weap drop Skill", "", 0); // case 0
		}
		
		
		menu_addtext2(menu, "\wSkill is ready");
		menu_setprop(menu, MPROP_EXIT, MEXIT_NEVER);
		menu_display(player, menu, 0);
		
		client_print_color(player, 0, "^1[^4ZP^1] ^1Your skill is now ready. ^3Press 1 ^1to use a skill..");
		

}

public winos_skill2(player, menu, item)
{

	new data[6], name[128], access, callback;

	menu_item_getinfo(menu, item, access, data, sizeof data - 1, name, sizeof name - 1, callback);


	switch(item)
	{
		case 0:
		{
		    BarTime(player, 1)
		    if(g_Has1[player])
			{

				mutateskill(player)
				use_skill_wave_mutate(player)
				engfunc(EngFunc_EmitSound, player, CHAN_BODY, mutate_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_task(0.2, "skill_check1", player)
				g_HasOpened[player] = false
				g_engel[player] = false
				set_task(1.0, "menuyukur", player)
				
			}
		    if(g_Has2[player])
			{
				use_skill_wave_kill(player)
				set_task(0.1, "use_skill_wave_kill", player, _, _, "a", 4)	
				engfunc(EngFunc_EmitSound, player, CHAN_BODY, skill_sound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_task(0.2, "skill_check2", player)
				g_HasOpened[player] = false
				g_engel[player] = false
				set_task(1.0, "menuyukur", player)
			}

		    if(g_Has3[player])
			{
				set_task(0.1, "Puxar_players_Fluxing", player)
				engfunc(EngFunc_EmitSound, player, CHAN_BODY, fluxing_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_task(0.2, "skill_check3", player)
				g_HasOpened[player] = false
				g_engel[player] = false
				set_task(1.0, "menuyukur", player)

			}
		    if(g_Has4[player])
			{
				drop_weapon(player)
				engfunc(EngFunc_EmitSound, player, CHAN_BODY, deimos_skill_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
				set_task(0.2, "skill_check4", player)
				g_HasOpened[player] = false
				g_engel[player] = false
				set_task(1.0, "menuyukur", player)
			}

		}		
	}


	menu_destroy(menu);
	

}

public skill_check1(player) 
{
	g_Has1[player] = false
	g_Has2[player] = true
}
public skill_check2(player) 
{
	g_Has2[player] = false
	g_Has3[player] = true
}
public skill_check3(player) 
{
	g_Has3[player] = false
	g_Has4[player] = true
}
public skill_check4(player) 
{
	g_Has4[player] = false
	g_Has1[player] = true
}

public bot_can_skill(player)
{
	if(g_Has1[player]) skill_bot_1(player)
	if(g_Has2[player]) skill_bot_2(player)
	if(g_Has3[player]) skill_bot_3(player)
	if(g_Has4[player]) skill_bot_4(player)
}

skill_bot_1(player)
{
	BarTime(player, 1)
	mutateskill(player)
	use_skill_wave_mutate(player)
	engfunc(EngFunc_EmitSound, player, CHAN_BODY, mutate_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.2, "skill_check1", player)
}

skill_bot_2(player)
{
	BarTime(player, 1)
	use_skill_wave_kill(player)
	set_task(0.1, "use_skill_wave_kill", player, _, _, "a", 4)	
	engfunc(EngFunc_EmitSound, player, CHAN_BODY, skill_sound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.2, "skill_check2", player)
}

skill_bot_3(player)
{
	BarTime(player, 1)
	set_task(0.1, "Puxar_players_Fluxing", player)
	engfunc(EngFunc_EmitSound, player, CHAN_BODY, fluxing_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	set_task(0.2, "skill_check3", player)
}


skill_bot_4(player)
{
	BarTime(player, 1)
	drop_weapon(player)
	set_task(0.2, "skill_check4", player)
	engfunc(EngFunc_EmitSound, player, CHAN_BODY, deimos_skill_start, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

BarTime(id, iSeconds)
{
    message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), .player=id)
    write_short(iSeconds)
    message_end()
}

public zp_fw_core_spawn_post(player)
{
	if (flag_get(g_Iswinos, player))
	{
		// Remove winos glow
		if (get_pcvar_num(cvar_winos_glow))
			set_user_rendering(player)
		
		// Remove winos aura
		if (get_pcvar_num(cvar_winos_aura))
			remove_task(player+TASK_AURA)
		
		// Remove winos flag
		flag_unset(g_Iswinos, player)
		
		set_rendering(player)
		remove_preview(player)
		
		g_Has1[player] = true
		g_Has2[player] = false
		g_Has3[player] = false
		g_Has4[player] = false
		
		remove_task(player)
		
		
	}
}

public zp_fw_core_cure(player, attacker)
{
	if (flag_get(g_Iswinos, player))
	{
		// Remove winos glow
		if (get_pcvar_num(cvar_winos_glow))
			set_user_rendering(player)
		
		// Remove winos aura
		if (get_pcvar_num(cvar_winos_aura))
			remove_task(player+TASK_AURA)
		
		// Remove winos flag
		flag_unset(g_Iswinos, player)
		
		set_rendering(player)
		remove_preview(player)
		
		g_Has1[player] = true
		g_Has2[player] = false
		g_Has3[player] = false
		g_Has4[player] = false
		
		remove_task(player)
	}
}


public mutateskill(player)
{
    new target, body
    get_user_aiming( player, target, body, get_pcvar_num( pcvar_winos_freez_distance ) )
    
    if( is_user_alive( target ) && !zp_core_is_zombie( target ) && GetAliveCount() != 2 )
    {
		sprite_control( player )
		set_task(3.0, "infect_ol", target)
		set_task(0.1, "boya", target)
		set_task(0.1, "use_skill_wave_mutate_victim", target, _, _, "a", 5)	
		

		
		new pBeam_ = Beam_Create("sprites/laserbeam.spr", 6.0);
		
		g_pBeam_[player] = pBeam_;
		Beam_EntsInit(pBeam_, target, player);
		Beam_SetColor(pBeam_, Float:{0.0, 150.0, 0.0});
		Beam_SetScrollRate(pBeam_, 255.0);
		Beam_SetBrightness(pBeam_, 200.0);
		
		set_task(3.1, "boya_sil", target)
		set_task(3.1, "remove_preview", player)

    }
	else
	{
		sprite_control( player )
	}
}

public infect_ol(target)
{
	zp_core_infect(target)
	engfunc(EngFunc_EmitSound, target, CHAN_BODY, infect_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public boya(target)
{
set_rendering(target, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16)
}

public boya_sil(target)
{
set_rendering(target)
}

public remove_preview(player)
{
		if (g_pBeam_[player] && pev_valid(g_pBeam_[player]))
		engfunc(EngFunc_RemoveEntity, g_pBeam_[player]);
}


public te_spray( args[ ] )
{
    message_begin( MSG_BROADCAST,SVC_TEMPENTITY )
    write_byte( 120 ) // Throws a shower of sprites or models
    write_coord( args[ 0 ] ) // start pos
    write_coord( args[ 1 ] )
    write_coord( args[ 2 ] )
    write_coord( args[ 3 ] ) // velocity
    write_coord( args[ 4 ] )
    write_coord( args[ 5 ] )
    write_short( frostsprite ) // spr
    write_byte( 8 ) // count
    write_byte( 70 ) // speed
    write_byte( 100 ) //(noise)
    write_byte( 5 )
    message_end( )
    
    return PLUGIN_CONTINUE
}

public sqrt( num )
{
    new div = num
    new result = 1
    while( div > result )
    {
        div = ( div + result ) / 2
        result = num / div
    }
    return div
}


public sprite_control( player )
{
    new vec[ 3 ]
    new aimvec[ 3 ]
    new velocityvec[ 3 ]
    new length
    new speed = 10
    
    get_user_origin( player, vec )
    get_user_origin( player, aimvec, 2 )
    
    velocityvec[ 0 ] = aimvec[ 0 ] - vec[ 0 ]
    velocityvec[ 1 ] = aimvec[ 1 ] - vec[ 1 ]
    velocityvec[ 2 ] = aimvec[ 2 ] - vec[ 2 ]
    length = sqrt( velocityvec[ 0 ] * velocityvec[ 0 ] + velocityvec[ 1 ] * velocityvec[ 1 ] + velocityvec[ 2 ] * velocityvec[ 2 ] )
    velocityvec[ 0 ] = velocityvec[ 0 ] * speed / length
    velocityvec[ 1 ] = velocityvec[ 1 ] * speed / length
    velocityvec[ 2 ] = velocityvec[ 2 ] * speed / length
    
    new args[ 8 ]
    args[ 0 ] = vec[ 0 ]
    args[ 1 ] = vec[ 1 ]
    args[ 2 ] = vec[ 2 ]
    args[ 3 ] = velocityvec[ 0 ]
    args[ 4 ] = velocityvec[ 1 ]
    args[ 5 ] = velocityvec[ 2 ]
    
    set_task( 0.1, "te_spray", 0, args, 8, "a", 2 )
    
}

// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
    if (victim != attacker && is_user_alive(attacker))
	{
		if (flag_get(g_Iswinos, attacker))
		{
			SetHamParamFloat(4, 250.0)
		}
		if (flag_get(g_Iswinos, victim))
		{
			RestoreHP(victim)
		}	
	}
}

RestoreHP(victim)
{
	if(get_user_health(victim) <= 1000)
	{
		set_task(5.0, "regeneration", victim)
	}

}

public regeneration(victim)
{
		set_user_health(victim, get_user_health(victim) + get_pcvar_num(g_pResHP))
					
		engfunc(EngFunc_EmitSound, victim, CHAN_BODY, health_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		new origin[3] 
		get_user_origin(victim,origin) 

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY) 
		write_byte(TE_SPRITE) 
		write_coord(origin[0]) 
		write_coord(origin[1]) 
		write_coord(origin[2]+30) 
		write_short(g_heal) 
		write_byte(8) 
		write_byte(255) 
		message_end() 
}


// Ham Player Killed Forward
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	
	if (flag_get(g_Iswinos, victim))
	{
		
		// Remove winos aura
		if (get_pcvar_num(cvar_winos_aura))
			remove_task(victim+TASK_AURA)
			
		if (get_pcvar_num(cvar_winos_kill_explode))
		{
			SetHamParamInteger(3, 2)
		}
	
		LavaSplash(victim)	
		
		remove_task(victim)
			

	}
	if (flag_get(g_Iswinos, attacker))
	{

		new vOrigin[3], coord[3]
		get_user_origin(victim,vOrigin)
		vOrigin[2] -= 26
		coord[0] = vOrigin[0] + 150
		coord[1] = vOrigin[1] + 150
		coord[2] = vOrigin[2] + 800
		create_thunder(coord,vOrigin)
		
		if (get_pcvar_num(cvar_winos_kill_explode))
		{
			SetHamParamInteger(3, 2)
		}
	
		LavaSplash(victim)	
	}
	

}

LavaSplash(id)
{

		new origin[3]
		get_user_origin(id, origin)
		
		message_begin(MSG_PVS, SVC_TEMPENTITY, origin, 0)
		write_byte(TE_LAVASPLASH)
		write_coord(origin[0])
		write_coord(origin[1])
		write_coord(origin[2] - 26)
	
		message_end()
}

create_thunder(vec1[3], vec2[3])
{
	if(get_pcvar_num(cvar_winos_lightning_effect))
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(0); 
		write_coord(vec1[0])
		write_coord(vec1[1])
		write_coord(vec1[2])
		write_coord(vec2[0])
		write_coord(vec2[1])
		write_coord(vec2[2]) 
		write_short(SprThunder)
		write_byte(1)
		write_byte(5)
		write_byte(2)
		write_byte(20)
		write_byte(30)
		write_byte(200);
		write_byte(200)
		write_byte(200)
		write_byte(200)
		write_byte(200)
		message_end()
		
		message_begin( MSG_PVS, SVC_TEMPENTITY,vec2);
		write_byte(TE_SPARKS) 
		write_coord(vec2[0])
		write_coord(vec2[1])
		write_coord(vec2[2])
		message_end()
		
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY,vec2) 
		write_byte(TE_SMOKE)
		write_coord(vec2[0])
		write_coord(vec2[1])
		write_coord(vec2[2]) 
		write_short(SprSmoke)
		write_byte(10)
		write_byte(10)  
		message_end()
	}
}

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Winos
	if (flag_get(g_Iswinos, id) && !get_pcvar_num(cvar_winos_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Winos
	if (flag_get(g_Iswinos, id) && !get_pcvar_num(cvar_winos_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}



public native_class_winos_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_Iswinos, id);
}

public native_class_winos_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_Iswinos, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a winos (%d)", id)
		return false;
	}
	
	flag_set(g_Iswinos, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_winos_get_count(plugin_id, num_params)
{
	return GetwinosCount();
}

// Winos aura task
public winos_aura(taskid)
{
	// Get player's origin
	static origin[3]
	get_user_origin(ID_AURA, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_winos_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_winos_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_winos_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

// Get Alive Count -returns alive players number-
GetAliveCount()
{
	new iAlive, id
	
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (is_user_alive(id))
			iAlive++
	}
	
	return iAlive;
}

// Get Winos Count -returns alive winos number-
GetwinosCount()
{
	new iwinos, id
	
	for (id = 1; id <= get_maxplayers(); id++)
	{
		if (is_user_alive(id) && flag_get(g_Iswinos, id))
			iwinos++
	}
	
	return iwinos;
}


public Puxar_players_Fluxing(id)
{
	static Float:Origin[3]
	
	FluxSpr = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	set_rendering(FluxSpr, kRenderFxGlowShell, 0, 255, 127, kRenderNormal, 30)
	set_pev(FluxSpr, pev_rendermode, kRenderTransAdd)
	set_pev(FluxSpr, pev_renderfx, kRenderFxGlowShell)
	set_pev(FluxSpr, pev_renderamt, 100.0)
	
	pev(id, pev_origin, Origin)
	Origin[2] += 70
	engfunc(EngFunc_SetOrigin, FluxSpr, Origin)
	engfunc(EngFunc_SetModel, FluxSpr, Resource[0])
	set_pev(FluxSpr, pev_solid, SOLID_NOT)
	set_pev(FluxSpr, pev_movetype, MOVETYPE_NOCLIP)
	
	set_pev(FluxSpr, pev_framerate, 3.0)
	dllfunc(DLLFunc_Spawn, FluxSpr)
		
	for(new i = 1; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && entity_range(FluxSpr, i) <= 1000.0)
		{
			if(!zp_core_is_zombie(id) || !zp_core_is_zombie(i))
			{
				static arg[2]
				arg[0] = FluxSpr
				arg[1] = i
			
				set_task(0.1, "do_hook_player", 0, arg, sizeof(arg), "b")
			}

		}
	}
	set_task(4.0, "hook_Remove")
}
public hook_Remove()
{
	remove_task(0)
	engfunc(EngFunc_RemoveEntity, FluxSpr)
}

public do_hook_player(arg[2])
{
	static Float:Origin[3], Float:Speed
	pev(arg[0], pev_origin, Origin)
	
	Speed = 350.0
	
	hook_ent2(arg[1], Origin, Speed)
}


stock hook_ent2(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}
public use_skill_wave_kill(player)
{
	
	static Float:flOrigin[3], iVictim
	entity_get_vector(player, EV_VEC_origin, flOrigin);
	
	iVictim = -1;

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]);
	engfunc(EngFunc_WriteCoord, flOrigin[2]); 
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]); 
	engfunc(EngFunc_WriteCoord, flOrigin[2] + SKILL_WAVE_RADIUS_KILL);
	write_short(g_Sprite); 
	write_byte(0); 
	write_byte(0);
	write_byte(10);
	write_byte(25); 
	write_byte(0); 
	write_byte(skill_wave_color_kill[0]); 
	write_byte(skill_wave_color_kill[1]);
	write_byte(skill_wave_color_kill[2]); 
	write_byte(200); 
	write_byte(0); 
	message_end();
	
	while((iVictim = find_ent_in_sphere(iVictim, flOrigin, SKILL_WAVE_RADIUS_KILL)) != 0)
	{
		if(is_user_connected(iVictim) && is_user_alive(iVictim) && !zp_core_is_zombie(iVictim))
		{
				ExecuteHamB(Ham_TakeDamage, iVictim, 0, player, 50.0, 0);	
				set_task(0.1, "parlama_purple", iVictim)
				set_task(2.0, "parlama_off", iVictim)
				
		}
	}
}

use_skill_wave_mutate(player)
{
	
	static Float:flOrigin[3]
	entity_get_vector(player, EV_VEC_origin, flOrigin);

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]);
	engfunc(EngFunc_WriteCoord, flOrigin[2]); 
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]); 
	engfunc(EngFunc_WriteCoord, flOrigin[2] + SKILL_WAVE_RADIUS_MUTATE);
	write_short(g_Sprite); 
	write_byte(0); 
	write_byte(0);
	write_byte(10);
	write_byte(25); 
	write_byte(0); 
	write_byte(skill_wave_color_mutate[0]); 
	write_byte(skill_wave_color_mutate[1]);
	write_byte(skill_wave_color_mutate[2]); 
	write_byte(200); 
	write_byte(0); 
	message_end();
}

public use_skill_wave_mutate_victim(target)
{
	
	static Float:flOrigin[3]
	entity_get_vector(target, EV_VEC_origin, flOrigin);
	

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]);
	engfunc(EngFunc_WriteCoord, flOrigin[2]); 
	engfunc(EngFunc_WriteCoord, flOrigin[0]); 
	engfunc(EngFunc_WriteCoord, flOrigin[1]); 
	engfunc(EngFunc_WriteCoord, flOrigin[2] + SKILL_WAVE_RADIUS_MUTATE);
	write_short(g_Sprite); 
	write_byte(0); 
	write_byte(0);
	write_byte(10);
	write_byte(25); 
	write_byte(0); 
	write_byte(skill_wave_color_mutate[0]); 
	write_byte(skill_wave_color_mutate[1]);
	write_byte(skill_wave_color_mutate[2]); 
	write_byte(200); 
	write_byte(0); 
	message_end();
}

public parlama_purple(iVictim)
{

set_rendering(iVictim, kRenderFxGlowShell, 150, 0, 150, kRenderNormal, 16)

static origin[3]
get_user_origin(iVictim, origin)
	
// Colored Aura
message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
write_byte(TE_DLIGHT) // TE iVictim
write_coord(origin[0]) // x
write_coord(origin[1]) // y
write_coord(origin[2]) // z
write_byte(20) // radius
write_byte(150) // r
write_byte(0) // g
write_byte(150) // b
write_byte(10) // life
write_byte(0) // decay rate
message_end()
}


public parlama_off(iVictim)
{

set_rendering(iVictim)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return FMRES_IGNORED
	
	if (flag_get(g_Iswinos, id))
	{
		set_pev(id, pev_view_ofs, {0.0, 0.0, 40.0}) 
	}
	
	return FMRES_IGNORED
}

public Player_Duck(id)
{
	if (flag_get(g_Iswinos, id))
	{
   		static button, ducking
   		button = pev(id, pev_button)
		ducking = pev(id, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)

   		if (button & IN_DUCK || ducking)
		{
			set_pev(id, pev_view_ofs, {0.0, 0.0, 20.0})   
   		}

	}
}

drop_weapon(id)
{
	new target, body
	static Float:start[3]
	static Float:aim[3]
	
	pev(id, pev_origin, start)
	fm_get_aim_origin(id, aim)
	
	start[2] += 16.0; // raise
	aim[2] += 16.0; // raise
	get_user_aiming ( id, target, body, 1000 )
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(aim[0])); // origin x
	write_coord(floatround(aim[1])); // origin y
	write_coord(floatround(aim[2])); // origin z
	write_short(deimos_spr); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(0)
	engfunc(EngFunc_WriteCoord,start[0]);
	engfunc(EngFunc_WriteCoord,start[1]);
	engfunc(EngFunc_WriteCoord,start[2]);
	engfunc(EngFunc_WriteCoord,aim[0]);
	engfunc(EngFunc_WriteCoord,aim[1]);
	engfunc(EngFunc_WriteCoord,aim[2]);
	write_short(deimos_trail); // sprite index
	write_byte(0); // start frame
	write_byte(30); // frame rate in 0.1's
	write_byte(10); // life in 0.1's
	write_byte(10); // line width in 0.1's
	write_byte(1); // noise amplititude in 0.01's
	write_byte(209); // red
	write_byte(120); // green
	write_byte(9); // blue
	write_byte(200); // brightness
	write_byte(0); // scroll speed in 0.1's
	message_end();
	
	if( is_user_alive( target ) && !zp_core_is_zombie( target ) )
	{		
		drop(target)
		
		engfunc(EngFunc_EmitSound, target, CHAN_BODY, deimos_skill, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}	
}

stock drop(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (PRIMARY_WEAPONS_BIT_SUM & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
}
