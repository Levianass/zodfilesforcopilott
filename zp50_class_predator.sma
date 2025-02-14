/*===============================================================================
	
	---------------------------
	-*- [ZP] Class: Predator -*-
	---------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fun>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_maxspeed_api>
#include <cs_player_models_api>
#include <zp50_colorchat>
#include <cs_weap_models_api>
#include <zp50_core>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#include <xs>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default models
new const models_predator_player[][] = { "z_predator" }
new const models_predator_claw[][] = { "models/zombie_plague/v_predator_hand.mdl" }

#define PLAYERMODEL_MAX_LENGTH 32
#define MODEL_MAX_LENGTH 64

#define SKILL_WAVE_RADIUS_FROST 300.0							
new const skill_wave_color_frost[3] = {0, 100, 200}				


// Custom models
new Array:g_models_predator_player
new Array:g_models_predator_claw

#define TASK_AURA 100
#define ID_AURA (taskid - TASK_AURA)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_MaxPlayers
new g_IsPredator

new cvar_predator_health, cvar_predator_base_health, cvar_predator_speed, cvar_predator_gravity
new cvar_predator_glow
new cvar_predator_aura, cvar_predator_aura_color_R, cvar_predator_aura_color_G, cvar_predator_aura_color_B
new cvar_predator_damage, cvar_predator_kill_explode
new cvar_predator_grenade_frost, cvar_predator_grenade_fire

new skill_cooldown_frost, skill_cooldown_shock
new cvar_shock_reward_hp,cvar_shock_velocity, cvar_shock_duration, cvar_victim_frost_duration

new g_Sprite

new cvar_predator_kill_explode2

new g_skill_frost[33]
new g_skill_shock[33]
new Float:gLastUseCmd[33]
new const Resource[][] = 
{
	"sprites/fluxing.spr"
}
static g_Resource[sizeof Resource]

new shock_sound[] = "winos_fluxing.wav"

new const skill_sound_wave[] = "frostexp.wav"	

public plugin_init()
{
	register_plugin("[ZP] Class: Predator", "2.0", "OWER")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect_Post", 1)
	
	register_clcmd("drop", "skills");
	
	register_touch("shock__","*","ShockTouch")
	
	g_MaxPlayers = get_maxplayers()
	
	cvar_predator_health = register_cvar("zp_predator_health", "0")
	cvar_predator_base_health = register_cvar("zp_predator_base_health", "1000")
	cvar_predator_speed = register_cvar("zp_predator_speed", "1.05")
	cvar_predator_gravity = register_cvar("zp_predator_gravity", "0.5")
	cvar_predator_glow = register_cvar("zp_predator_glow", "1")
	cvar_predator_aura = register_cvar("zp_predator_aura", "0")
	cvar_predator_aura_color_R = register_cvar("zp_predator_aura_color_R", "150")
	cvar_predator_aura_color_G = register_cvar("zp_predator_aura_color_G", "0")
	cvar_predator_aura_color_B = register_cvar("zp_predator_aura_color_B", "0")
	cvar_predator_damage = register_cvar("zp_predator_damage", "250.0")
	cvar_predator_kill_explode = register_cvar("zp_predator_kill_explode", "1")
        cvar_predator_kill_explode2 = register_cvar("zp_predator_kill_explode2", "1")
	cvar_predator_grenade_frost = register_cvar("zp_predator_grenade_frost", "0")
	cvar_predator_grenade_fire = register_cvar("zp_predator_grenade_fire", "1")
	
	skill_cooldown_frost = register_cvar("predator_frost_skill_cooldown", "30.0")
	skill_cooldown_shock = register_cvar("predator_shock_skill_cooldown", "30.0")
	
	cvar_shock_velocity = register_cvar("predator_shock_velocity", "800")
	cvar_shock_reward_hp = register_cvar("predator_shock_reward_hp", "1000")
	cvar_shock_duration = register_cvar("predator_shock_victim_duration", "5.0")
	cvar_victim_frost_duration = register_cvar("predator_victim_frost_dur", "5.0")

}

public plugin_precache()
{
	// Initialize arrays
	g_models_predator_player = ArrayCreate(PLAYERMODEL_MAX_LENGTH, 1)
	g_models_predator_claw = ArrayCreate(MODEL_MAX_LENGTH, 1)
	
	// Load from external file
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "PREDATOR", g_models_predator_player)
	amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE PREDATOR", g_models_predator_claw)
	
	// If we couldn't load from file, use and save default ones
	new index
	if (ArraySize(g_models_predator_player) == 0)
	{
		for (index = 0; index < sizeof models_predator_player; index++)
			ArrayPushString(g_models_predator_player, models_predator_player[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Player Models", "PREDATOR", g_models_predator_player)
	}
	if (ArraySize(g_models_predator_claw) == 0)
	{
		for (index = 0; index < sizeof models_predator_claw; index++)
			ArrayPushString(g_models_predator_claw, models_predator_claw[index])
		
		// Save to external file
		amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Weapon Models", "V_KNIFE PREDATOR", g_models_predator_claw)
	}
	
	// Precache models
	new player_model[PLAYERMODEL_MAX_LENGTH], model[MODEL_MAX_LENGTH], model_path[128]
	for (index = 0; index < ArraySize(g_models_predator_player); index++)
	{
		ArrayGetString(g_models_predator_player, index, player_model, charsmax(player_model))
		formatex(model_path, charsmax(model_path), "models/player/%s/%s.mdl", player_model, player_model)
		precache_model(model_path)
		// Support modelT.mdl files
		formatex(model_path, charsmax(model_path), "models/player/%s/%sT.mdl", player_model, player_model)
		if (file_exists(model_path)) precache_model(model_path)
	}
	for (index = 0; index < ArraySize(g_models_predator_claw); index++)
	{
		ArrayGetString(g_models_predator_claw, index, model, charsmax(model))
		precache_model(model)
	}
	
	g_Sprite = precache_model("sprites/shockwave.spr");
	
	for(new i; i <= charsmax(Resource); i++)
		g_Resource[i] = precache_model(Resource[i])
		
	precache_sound(shock_sound)
	engfunc(EngFunc_PrecacheSound, skill_sound_wave)
}

public plugin_natives()
{
	register_library("zp50_class_predator")
	register_native("zp_class_predator_get", "native_class_predator_get")
	register_native("zp_class_predator_set", "native_class_predator_set")
	register_native("zp_class_predator_get_count", "native_class_predator_get_count")
	
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
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
	}
}

public fw_ClientDisconnect_Post(id)
{
	// Reset flags AFTER disconnect (to allow checking if the player was predator before disconnecting)
	flag_unset(g_IsPredator, id)
}


// Ham Take Damage Forward
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return HAM_IGNORED;
	
	// Predator attacking human
	if (flag_get(g_IsPredator, attacker) && !zp_core_is_zombie(victim))
	{
		// Ignore predator damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (inflictor == attacker)
		{
			// Set predator damage
			SetHamParamFloat(4, get_pcvar_float(cvar_predator_damage))
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

// Ham Player Killed Forward

public fw_PlayerKilled(victim, attacker, shouldgib)
{

	if (flag_get(g_IsPredator, victim))
	{
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(victim+TASK_AURA)

		if (get_pcvar_num(cvar_predator_kill_explode2))

		{

			SetHamParamInteger(3, 2)
		}
		remove_task(victim)		

	}

	if (flag_get(g_IsPredator, attacker))

	{

		new vOrigin[3], coord[3]
		get_user_origin(victim,vOrigin)
		vOrigin[2] -= 26
		coord[0] = vOrigin[0] + 150
		coord[1] = vOrigin[1] + 150
		coord[2] = vOrigin[2] + 800

		if (get_pcvar_num(cvar_predator_kill_explode))
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

public zp_fw_grenade_frost_pre(id)
{
	// Prevent frost for Predator
	if (flag_get(g_IsPredator, id) && !get_pcvar_num(cvar_predator_grenade_frost))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
	// Prevent burning for Predator
	if (flag_get(g_IsPredator, id) && !get_pcvar_num(cvar_predator_grenade_fire))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public zp_fw_core_spawn_post(id)
{
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
		
		// Remove predator flag
		flag_unset(g_IsPredator, id)
	}
}

public zp_fw_core_cure(id, attacker)
{
	if (flag_get(g_IsPredator, id))
	{
		// Remove predator glow
		if (get_pcvar_num(cvar_predator_glow))
			set_user_rendering(id)
		
		// Remove predator aura
		if (get_pcvar_num(cvar_predator_aura))
			remove_task(id+TASK_AURA)
		
		// Remove predator flag
		flag_unset(g_IsPredator, id)
	}
}

public zp_fw_core_infect_post(id, attacker)
{
	// Apply predator attributes?
	if (!flag_get(g_IsPredator, id))
		return;
	
	// Health
	if (get_pcvar_num(cvar_predator_health) == 0)
		set_user_health(id, get_pcvar_num(cvar_predator_base_health) * GetAliveCount())
	else
		set_user_health(id, get_pcvar_num(cvar_predator_health))
	
	// Gravity
	set_user_gravity(id, get_pcvar_float(cvar_predator_gravity))
	
	// Speed
	cs_set_player_maxspeed_auto(id, get_pcvar_float(cvar_predator_speed))
	
	// Apply predator player model
	new player_model[PLAYERMODEL_MAX_LENGTH]
	ArrayGetString(g_models_predator_player, random_num(0, ArraySize(g_models_predator_player) - 1), player_model, charsmax(player_model))
	cs_set_player_model(id, player_model)
	
	// Apply predator claw model
	new model[MODEL_MAX_LENGTH]
	ArrayGetString(g_models_predator_claw, random_num(0, ArraySize(g_models_predator_claw) - 1), model, charsmax(model))
	cs_set_player_view_model(id, CSW_KNIFE, model)	
	
	// Predator glow
	if (get_pcvar_num(cvar_predator_glow))
		set_user_rendering(id, kRenderFxGlowShell, 0, 50, 200, kRenderNormal, 25)
	
	// Predator aura task
	if (get_pcvar_num(cvar_predator_aura))
		set_task(0.1, "predator_aura", id+TASK_AURA, _, _, "b")
	
	g_skill_frost[id] = true
	g_skill_shock[id] = false


	if(is_user_bot(id))

	{

		set_task(5.0, "bot_can_skill", id, _,_, "b")

	}
}

public native_class_predator_get(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return -1;
	}
	
	return flag_get_boolean(g_IsPredator, id);
}

public native_class_predator_set(plugin_id, num_params)
{
	new id = get_param(1)
	
	if (!is_user_alive(id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
		return false;
	}
	
	if (flag_get(g_IsPredator, id))
	{
		log_error(AMX_ERR_NATIVE, "[ZP] Player already a predator (%d)", id)
		return false;
	}
	
	flag_set(g_IsPredator, id)
	zp_core_force_infect(id)
	return true;
}

public native_class_predator_get_count(plugin_id, num_params)
{
	return GetpredatorCount();
}

public skills(player)
{
	if (flag_get(g_IsPredator, player) && is_user_alive(player))
	{
		if(g_skill_frost[player]) frost_skill(player)
		if(g_skill_shock[player]) shock_skill(player)
	}
}

public bot_can_skill(player)

{

	if(g_skill_frost[player]) skill_bot_1(player)

	if(g_skill_shock[player]) skill_bot_2(player)

}

skill_bot_1(player)

{

	frost_skill(player)

	use_skill_wave_frost(player)

	engfunc(EngFunc_EmitSound, player, CHAN_BODY, skill_sound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(0.2, "skill_check1", player)

}

skill_bot_2(player)

{


	shock_skill(player)

	set_task(0.1, "use_skill_shock", player, _, _, "a", 4)	

	engfunc(EngFunc_EmitSound, player, CHAN_BODY, skill_sound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)

	set_task(0.2, "skill_check2", player)

}


// FROST WAVE

public frost_skill(player)
{
	if( get_gametime( ) - gLastUseCmd[ player ] < get_pcvar_float( skill_cooldown_frost ) ) 
	{
		client_printcolor(player,"^1[^4LG*| Predator^1] ^1You can use your frost ability in ^3%0.f ^1seconds", get_pcvar_float( skill_cooldown_frost ) - (get_gametime( ) - gLastUseCmd[ player ]));
		return PLUGIN_HANDLED;
	}
	
	gLastUseCmd[ player ] = get_gametime( )
	
	if(get_gametime( ) - gLastUseCmd[ player ] == 0.0)
	{
		set_task(0.2, "use_skill_wave_frost", player, _,_, "a", 4)
		engfunc(EngFunc_EmitSound, player, CHAN_BODY, skill_sound_wave, 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_task(0.11, "skill_check1", player)
	}
	
	return PLUGIN_HANDLED;
		
}



public shock_skill(player)
{
	if( get_gametime( ) - gLastUseCmd[ player ] < get_pcvar_float( skill_cooldown_shock ) ) 
	{
		client_printcolor(player,"^1[^4LG*| Predator^1] ^1You can use your blind ability in ^3%0.f ^1seconds", get_pcvar_float( skill_cooldown_shock ) - (get_gametime( ) - gLastUseCmd[ player ]));
		return PLUGIN_HANDLED;
	}
	
	gLastUseCmd[ player ] = get_gametime( )
	
	if(get_gametime( ) - gLastUseCmd[ player ] == 0.0)
	{
		use_skill_shock(player)
		set_task(0.11, "skill_check2", player)	

	}
	
	return PLUGIN_HANDLED;
		
}

public skill_check1(player) 
{
	g_skill_frost[player] = false
	g_skill_shock[player] = true
}
public skill_check2(player) 
{
	g_skill_shock[player] = false
	g_skill_frost[player] = true
}

public use_skill_wave_frost(player)
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
	engfunc(EngFunc_WriteCoord, flOrigin[2] + SKILL_WAVE_RADIUS_FROST);
	write_short(g_Sprite); 
	write_byte(0); 
	write_byte(0);
	write_byte(10);
	write_byte(25); 
	write_byte(0); 
	write_byte(skill_wave_color_frost[0]); 
	write_byte(skill_wave_color_frost[1]);
	write_byte(skill_wave_color_frost[2]); 
	write_byte(255); 
	write_byte(0); 
	message_end();
	
	while((iVictim = find_ent_in_sphere(iVictim, flOrigin, SKILL_WAVE_RADIUS_FROST)) != 0)
	{
		if(is_user_connected(iVictim) && is_user_alive(iVictim) && !zp_core_is_zombie(iVictim))
		{	
			       zp_grenade_frost_set(iVictim, get_pcvar_float(cvar_victim_frost_duration))
                               client_printcolor(iVictim,"^1[^4LG*| Predator^1] You have been frozen by the Predator.")
                               client_print(iVictim, print_center, "You are frozen...")
		}
	}
}


// SHOCK


public use_skill_shock(id)
{
	new Float:Origin[3]
	new Float:Velocity[3]
	new Float:vAngle[3]

	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)

	new NewEnt = create_entity("env_sprite")
	
	entity_set_string(NewEnt, EV_SZ_classname, "shock__")

	entity_set_model(NewEnt, Resource[0])

	entity_set_size(NewEnt, Float:{-1.5, -1.5, -1.5}, Float:{1.5, 1.5, 1.5})

	entity_set_origin(NewEnt, Origin)
	entity_set_vector(NewEnt, EV_VEC_angles, vAngle)
	entity_set_int(NewEnt, EV_INT_solid, 2)

	entity_set_int(NewEnt, EV_INT_rendermode, 5)
	entity_set_float(NewEnt, EV_FL_renderamt, 200.0)
	entity_set_float(NewEnt, EV_FL_scale, 1.00)

	entity_set_int(NewEnt, EV_INT_movetype, 5)
	entity_set_edict(NewEnt, EV_ENT_owner, id)

	velocity_by_aim(id, get_pcvar_num(cvar_shock_velocity), Velocity)
	entity_set_vector(NewEnt, EV_VEC_velocity ,Velocity)
	emit_sound(NewEnt, CHAN_BODY, shock_sound, 1.0, ATTN_NORM, 0, PITCH_HIGH)

}


public ShockTouch( ShockEnt, Touched )
{
	if ( !pev_valid ( ShockEnt ) )
		return
		
	static Class[ 32 ]
	entity_get_string( Touched, EV_SZ_classname, Class, charsmax( Class ) )
	new Float:origin[3]
		
	pev(Touched,pev_origin,origin)
	
	if( equal( Class, "player" ) )
	{
		if (is_user_alive(Touched))
		{
			if(!zp_core_is_zombie(Touched))
			{
				new TankKiller = entity_get_edict( ShockEnt, EV_ENT_owner )

				set_user_rendering(Touched, kRenderFxGlowShell, 102, 102, 255, kRenderNormal, 25)
				client_printcolor(Touched,"^1[^4LG*| Predator^1] The Predator has flashed you. You have temporarily lost your vision!")
                                client_print(Touched, print_center, "You are blind...")
				set_task(get_pcvar_float(cvar_shock_duration), "render", Touched)
				ScreenFade(Touched, get_pcvar_float(cvar_shock_duration), 255, 255, 255, 255)
				
				set_user_health(TankKiller, get_user_health(TankKiller) + get_pcvar_num(cvar_shock_reward_hp))
			}
		}
	}	
		
	remove_entity(ShockEnt)
	
	if(!is_user_alive(Touched))
		return
		
}


public render(player) set_user_rendering(player)

// Stock

stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player)
	write_byte(Sequence)
	write_byte(pev(Player, pev_body))
	message_end()
}


stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
    new_velocity[0] = origin2[0] - origin1[0]
    new_velocity[1] = origin2[1] - origin1[1]
    new_velocity[2] = origin2[2] - origin1[2]
    new Float:num = floatsqroot(speed*speed /  (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] +  new_velocity[2]*new_velocity[2]))
    new_velocity[0] *= num
    new_velocity[1] *= num
    new_velocity[2] *= num
    
    return 1;
} 


stock ScreenFade(plr, Float:fDuration, red, green, blue, alpha)
{
    new i = plr ? plr : get_maxplayers();
    if( !i )
    {
        return 0;
    }
    
    message_begin(plr ? MSG_ONE : MSG_ALL, get_user_msgid( "ScreenFade"), {0, 0, 0}, plr);
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(floatround(4096.0 * fDuration, floatround_round));
    write_short(4096);
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    write_byte(alpha);
    message_end();
    
    return 1;
}

// Predator aura task
public predator_aura(taskid)
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
	write_byte(get_pcvar_num(cvar_predator_aura_color_R)) // r
	write_byte(get_pcvar_num(cvar_predator_aura_color_G)) // g
	write_byte(get_pcvar_num(cvar_predator_aura_color_B)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
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

// Get Predator Count -returns alive predator number-
GetpredatorCount()
{
	new ipredator, id
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if (is_user_alive(id) && flag_get(g_IsPredator, id))
			ipredator++
	}
	
	return ipredator;
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