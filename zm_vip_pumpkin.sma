#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <zombieplague>
#include <bulletdamage>
#include <zp50_colorchat>
#include <zmvip>

#define PLUGIN "[CSO] Weapon Pumpkin"
#define VERSION "1.0"
#define AUTHOR "PaXaN-ZOMBIE"

#define PA_LOW  35.0
#define PA_HIGH 65.0

#define DAMAGE 700
#define RADIUS 300

#define BODY_SKIN_W_PUMPKIN 0

#define NAME "Pumpkin"
#define COST 50

new const g_item_name[] = { "Pumpkin" } // Item name
new const g_item_descritpion[] = { "50% off" } // Item descritpion
const g_item_cost = 25 // Price (ammo)


#define V_MODEL_PUMPKIN "models/zp_new/v_pumpkin.mdl"
#define P_MODEL_PUMPKIN "models/zp_new/p_pumpkin.mdl"
#define W_MODEL_PUMPKIN "models/zp_new/w_pumpkin.mdl"

#define SOUND_EXPLODE    "weapons/pumpkin_exp.wav"

#define SPRITE_TRAIL             "sprites/lgtning.spr"
#define SPRITE_GIBS              "sprites/hotglow.spr"
#define SPRITE_EXPLODE    "sprites/zp_new/pumpkin_exp.spr"

new g_PlayerArmor[33]

new const NADE_TYPE_PUMPKIN = 125

new const wpnlist_txt_name[] = "weapon_pumpkin_paxan"

new const Pumpkin_Sound[ ] [ ] =  
{
	"weapons/pump_deploy.wav",
	"weapons/pump_in.wav",
	"weapons/pump_throw.wav"
}

new const hud_spr[][] = 
{ 
	"sprites/zp_new/640hud41.spr", 
	"sprites/zp_new/640hud7.spr"
}

new gMsgScreenShake , 
gMsgScreenFade,
g_pumpgibs,
item_id,
g_has_pumpkin[33],
spriteexpl,
g_trail,
gmsgWeaponList

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	//RegisterHam(Ham_Item_AddToPlayer, "weapon_smokegrenade", "fw_AddToPlayer")

        item_id = zv_register_extra_item(g_item_name, g_item_descritpion, g_item_cost, ZV_TEAM_HUMAN) 


        register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 

	register_forward(FM_SetModel, "fw_SetModel")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
	
	gMsgScreenShake = get_user_msgid("ScreenShake");
	gMsgScreenFade = get_user_msgid("ScreenFade");
	gmsgWeaponList = get_user_msgid("WeaponList")
	
	item_id = zp_register_extra_item(NAME,COST,ZP_TEAM_HUMAN)
}

public plugin_precache()
{
	precache_model(V_MODEL_PUMPKIN)
	precache_model(P_MODEL_PUMPKIN)
	precache_model(W_MODEL_PUMPKIN)

	precache_sound(SOUND_EXPLODE)
	
	new iFile 
	new iLenFile = sizeof Pumpkin_Sound
	
	for( iFile = 0 ; iFile < iLenFile; iFile++ )
	precache_sound( Pumpkin_Sound[ iFile ] ) 
	
	g_pumpgibs = precache_model(SPRITE_GIBS);
	spriteexpl = precache_model(SPRITE_EXPLODE);
	g_trail = precache_model(SPRITE_TRAIL);
	
	new sFile[64]
	formatex(sFile, charsmax(sFile), "sprites/%s.txt", wpnlist_txt_name)
	precache_generic(sFile)
	
	for(new i = 0; i < sizeof(hud_spr); i++)
	{
		precache_generic(hud_spr[i])
	}
	
	register_clcmd("weapon_pumpkin_paxan", "Hook_Select")
} 

public event_newround() 
{ 
        for ( new id; id <= get_maxplayers(); id++)
        g_PlayerArmor[1] = false

} 

public Hook_Select(id)
{
    engclient_cmd(id, "weapon_smokegrenade")
    return PLUGIN_HANDLED
}

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_has_pumpkin[id] = false
	}
}

public client_connect(id)
{
	g_has_pumpkin[id] = false
}

public client_disconnect(id)
{
	g_has_pumpkin[id] = false
}

/*
public fw_AddToPlayer(ent, Player)
{
    if( pev_valid(ent) && is_user_connected(Player))
    {
	if(g_has_pumpkin[Player])
	{
		Wpnlist(Player)
	}
    }
} 
*/

public zv_extra_item_selected(player, itemid)
{
	if(itemid == item_id)
	{
		if (g_has_pumpkin[player])
		{
			return ZP_PLUGIN_HANDLED
		}

		if (g_PlayerArmor[1])
		{
			zp_colored_print(player, "You can only buy one per round!!") 
			return ZP_PLUGIN_HANDLED;
		}
		
		g_has_pumpkin[player] = 1	
		give_item(player,"weapon_smokegrenade")
		Wpnlist(player)
		if(get_user_weapon(player) == CSW_SMOKEGRENADE) set_pev(player, pev_viewmodel2, V_MODEL_PUMPKIN)
                g_PlayerArmor[1] = true
	}
	return PLUGIN_CONTINUE	
}

public fw_PlayerKilled(victim, attacker, shouldgib)
{
	g_has_pumpkin[victim] = 0	
}

public fw_ThinkGrenade(entity)
{	
	if(!pev_valid(entity))
		return HAM_IGNORED
		
	static Float:dmgtime	
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime > get_gametime())
		return HAM_IGNORED	
	
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_PUMPKIN)
		pumpkin_explode(entity)
	
	return HAM_SUPERCEDE
}

public fw_SetModel(ent, const model[])
{
	new id = pev(ent, pev_owner)
	
	if(!pev_valid(ent) || !equal(model[9], "smokegrenade.mdl") || !g_has_pumpkin[id] || zp_get_user_zombie(id))
		return FMRES_IGNORED
	static classname[32]; pev(ent, pev_classname, classname, 31)
	if(equal(classname, "grenade"))
	{
		set_rendering(ent, kRenderFxGlowShell, 218, 165, 32, kRenderNormal, 1);
		engfunc(EngFunc_SetModel, ent, W_MODEL_PUMPKIN)
		set_pev(ent, pev_body, BODY_SKIN_W_PUMPKIN)
		g_has_pumpkin[id] = 0
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(ent) // entity
		write_short(g_trail) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(218) // r
		write_byte(165) // g
		write_byte(32) // b
		write_byte(255) // brightness
		message_end()
		
		set_pev(ent, pev_flTimeStepSound, NADE_TYPE_PUMPKIN)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
	
}

public pumpkin_explode(ent)
{
	static Float:flOrigin [ 3 ]
	pev ( ent, pev_origin, flOrigin )
	new id = pev(ent, pev_owner)
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON,SOUND_EXPLODE, 1.0, ATTN_NORM, 0, PITCH_NORM)
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, flOrigin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, flOrigin[0]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, flOrigin[1]+random_float(-5.0, 5.0))
	engfunc(EngFunc_WriteCoord, flOrigin[2]+50.0)
	write_short(spriteexpl)
	write_byte(30)
	write_byte(200)
	message_end()	

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, flOrigin[0])
	engfunc(EngFunc_WriteCoord, flOrigin[1])
	engfunc(EngFunc_WriteCoord, flOrigin[2])
	write_byte(15)//Radius
	write_byte(250)	// r
	write_byte(150)	// g
	write_byte(50)	// b
	write_byte(15)	//Life
	write_byte(10)
	message_end()
	
	message_begin (MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte( TE_SPRITETRAIL ) // Throws a shower of sprites or models
	engfunc(EngFunc_WriteCoord, flOrigin[ 0 ]) // start pos
	engfunc(EngFunc_WriteCoord, flOrigin[ 1 ])
	engfunc(EngFunc_WriteCoord, flOrigin[ 2 ] + 200.0)
	engfunc(EngFunc_WriteCoord, flOrigin[ 0 ]) // velocity
	engfunc(EngFunc_WriteCoord, flOrigin[ 1 ])
	engfunc(EngFunc_WriteCoord, flOrigin[ 2 ] + 20.0)
	write_short(g_pumpgibs) // spr
	write_byte(15) // (count)
	write_byte(random_num(27,30)) // (life in 0.1's)
	write_byte(1) // byte (scale in 0.1's)
	write_byte(random_num(30,70)) // (velocity along vector in 10's)
	write_byte(20) // (randomness of velocity in 10's)
	message_end()
	
	for ( new victim = 1; victim < get_maxplayers(); victim++ )
	if(is_user_connected(victim))
	if(is_user_alive(victim))
	if(zp_get_user_zombie(victim))
	{
	new Float:flVictimOrigin [ 3 ]
	pev ( victim, pev_origin, flVictimOrigin )
	if ( get_distance_f ( flOrigin, flVictimOrigin )<= RADIUS)
	{
	
	new Float:fVec[3];
	fVec[0] = random_float(PA_LOW , PA_HIGH);
	fVec[1] = random_float(PA_LOW , PA_HIGH);
	fVec[2] = random_float(PA_LOW , PA_HIGH);
	
	entity_set_vector(victim, EV_VEC_punchangle , fVec);
	message_begin(MSG_ONE , gMsgScreenShake , {0,0,0} ,victim)
	write_short( 1<<14 );
	write_short( 1<<14 );
	write_short( 1<<14 );
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE , gMsgScreenFade , {0,0,0} , victim);
	write_short( 1<<10 );
	write_short( 1<<10 );
	write_short( 1<<12 );
	write_byte( 225 );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 125 );
	message_end();
         }
         }
	for ( new victim = 1; victim < get_maxplayers(); victim++ )
	{

		new Float:flVictimOrigin [ 3 ]
		pev ( victim, pev_origin, flVictimOrigin )
		new Float:flDistance = get_distance_f ( flOrigin, flVictimOrigin )
		if ( flDistance <= RADIUS && zp_get_user_zombie(victim))
		{
			if (!is_user_alive(victim))
				continue;
			if(get_user_health(victim) >DAMAGE)
			set_user_health(victim,get_user_health(victim) - DAMAGE)
			else
			ExecuteHam(Ham_Killed, victim, id, 0, float(DAMAGE))
			bd_show_damage(victim, DAMAGE, 0, 1)
			bd_show_damage(id, DAMAGE, 0, 1)
		}
	}
	remove_entity(ent)
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	replace_models(msg_entity)
}

public replace_models(id)
{	
	if (!is_user_alive(id))
	return PLUGIN_CONTINUE		

	if(get_user_weapon(id) == CSW_SMOKEGRENADE && g_has_pumpkin[id])
	{
		set_pev(id, pev_viewmodel2, V_MODEL_PUMPKIN)
		set_pev(id, pev_weaponmodel2, P_MODEL_PUMPKIN)
		
	}
	return PLUGIN_CONTINUE
}        

public Wpnlist(id)
{
  
    message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
    write_string(wpnlist_txt_name)
    write_byte(13)
    write_byte(1)
    write_byte(-1)
    write_byte(-1)
    write_byte(3)
    write_byte(3)
    write_byte(9)
    write_byte(24)
    message_end()

}

public Wpnlist2(id)
{
    
    message_begin(MSG_ONE, gmsgWeaponList, {0,0,0}, id)
    write_string("weapon_smokegrenade")
    write_byte(13)
    write_byte(1)
    write_byte(-1)
    write_byte(-1)
    write_byte(3)
    write_byte(3)
    write_byte(9)
    write_byte(24)
    message_end()

}
