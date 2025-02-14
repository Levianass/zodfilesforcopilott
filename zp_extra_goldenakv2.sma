/*
[ZP] Extra Item: Golden Ak 47
Team: Humans

Description: This plugin adds a new weapon for Human Teams.
Weapon Cost: 30

Features:
- This weapon do more damage
- This weapon has zoom
- Launch Lasers
- This weapon has unlimited bullets

Credits:

KaOs - For his Dual MP5 mod

Cvars:


- zp_goldenak_dmg_multiplier <5> - Damage Multiplier for Golden Ak 47
- zp_goldenak_gold_bullets <1|0> - Golden bullets effect ?
- zp_goldenak_custom_model <1|0> - Golden ak Custom Model
- zp_goldenak_unlimited_clip <1|0> - Golden ak Unlimited Clip 

*/



#include <amxmodx>
#include <fakemeta>
#include <fun>
#include <hamsandwich>
#include <cstrike>
#include <zombieplague>

#define is_valid_player(%1) (1 <= %1 <= 32)

new AK_V_MODEL[64] = "models/v_golden_ak47.mdl"
new AK_P_MODEL[64] = "models/zombie_plague/p_golden_ak47.mdl"

const BALROG_KEY = 45347;

/* Pcvars */
new cvar_dmgmultiplier, cvar_custommodel, cvar_uclip


new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 };

// Item ID
new g_itemid

new bool:g_HasAk[33]

new g_hasZoom[ 33 ]

// Sprite
new m_spriteTexture

const Wep_ak47 = ((1<<CSW_AK47))

public plugin_init()
{
	
	/* CVARS */
	cvar_dmgmultiplier = register_cvar("zp_goldenak_dmg_multiplier", "3")
	cvar_custommodel = register_cvar("zp_goldenak_custom_model", "1")
	cvar_uclip = register_cvar("zp_goldenak_unlimited_clip", "1")
	
	// Register The Plugin
	register_plugin("[ZP] Extra: Golden Ak 47", "1.1", "ShaunCraft")
	// Register Zombie Plague extra item
	g_itemid = zp_register_extra_item("Golden AK47 \r(3x damage)", 80, ZP_TEAM_HUMAN)
	// Death Msg
	register_event("DeathMsg", "Death", "a")
	// Weapon Pick Up
	register_event("WeapPickup","checkModel","b","1=19")
	// Current Weapon Event
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("CurWeapon", "fw_TraceAttack", "be", "1=1", "3>0")
	// Ham TakeDamage
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	register_forward( FM_CmdStart, "fw_CmdStart" )
	RegisterHam(Ham_Spawn, "player", "fwHamPlayerSpawnPost", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
        RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_Item_AddToPlayer_Post", 1);
	
}


public client_connect(id)
{
	g_HasAk[id] = false
}

public client_disconnect(id)
{
	g_HasAk[id] = false
}

public Death()
{
	g_HasAk[read_data(2)] = false
}

public fwHamPlayerSpawnPost(id)
{
	g_HasAk[id] = false
}

public plugin_precache()
{
	precache_model(AK_V_MODEL)
	precache_model(AK_P_MODEL)
	m_spriteTexture = precache_model("sprites/beam.spr")
	precache_sound("weapons/zoom.wav")
}  

public zp_user_infected_post(id)
{
	if (zp_get_user_zombie(id))
	{
		g_HasAk[id] = false
	}
}

public checkModel(id)
{
	if ( zp_get_user_zombie(id) )
		return PLUGIN_HANDLED
	
	new szWeapID = read_data(2)
	
	if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && get_pcvar_num(cvar_custommodel) )
	{
		set_pev(id, pev_viewmodel2, AK_V_MODEL)
		set_pev(id, pev_weaponmodel2, AK_P_MODEL)
	}
	return PLUGIN_HANDLED
}

public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeap[32]
	new plrWeapId
	
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if (plrWeapId == CSW_AK47 && g_HasAk[id])
	{
		checkModel(id)
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	if (plrClip == 0 && get_pcvar_num(cvar_uclip))
	{
		// If the user is out of ammo..
		get_weaponname(plrWeapId, plrWeap, 31)
		// Get the name of their weapon
		give_item(id, plrWeap)
		engclient_cmd(id, plrWeap) 
		engclient_cmd(id, plrWeap)
		engclient_cmd(id, plrWeap)
	}
	return PLUGIN_HANDLED
}



public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if ( is_valid_player( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_HasAk[attacker] )
    {
        SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmgmultiplier ) )
    }
}

public fw_CmdStart( id, uc_handle, seed )
{
	if( !is_user_alive( id ) ) 
		return PLUGIN_HANDLED
	
	if( ( get_uc( uc_handle, UC_Buttons ) & IN_ATTACK2 ) && !( pev( id, pev_oldbuttons ) & IN_ATTACK2 ) )
	{
		new szClip, szAmmo
		new szWeapID = get_user_weapon( id, szClip, szAmmo )
		
		if( szWeapID == CSW_AK47 && g_HasAk[id] == true && !g_hasZoom[id] == true)
		{
			g_hasZoom[id] = true
			cs_set_user_zoom( id, CS_SET_AUGSG552_ZOOM, 0 )
			emit_sound( id, CHAN_ITEM, "weapons/zoom.wav", 0.20, 2.40, 0, 100 )
		}
		
		else if ( szWeapID == CSW_AK47 && g_HasAk[id] == true && g_hasZoom[id])
		{
			g_hasZoom[ id ] = false
			cs_set_user_zoom( id, CS_RESET_ZOOM, 0 )
			
		}
		
	}
	return PLUGIN_HANDLED
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(iAttacker))
		return

	new g_currentweapon = get_user_weapon(iAttacker)

	if(g_currentweapon != CSW_AK47) return
	
	if(!g_HasAk[iAttacker]) return

	static Float:end[3]
	get_tr2(ptr, TR_vecEndPos, end)
	
	if(iEnt)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_DECAL)
		engfunc(EngFunc_WriteCoord, end[0])
		engfunc(EngFunc_WriteCoord, end[1])
		engfunc(EngFunc_WriteCoord, end[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		write_short(iEnt)
		message_end()
	}
	else
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, end[0])
		engfunc(EngFunc_WriteCoord, end[1])
		engfunc(EngFunc_WriteCoord, end[2])
		write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)])
		message_end()
	}
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMENTPOINT)
	write_short(iAttacker | 0x1000)
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(m_spriteTexture)
	write_byte(1) // framerate
	write_byte(1) // framerate
	write_byte(1) // life
	write_byte(5)  // width
	write_byte(0)// noise
	write_byte(249)// r, g, b
	write_byte(166)// r, g, b
	write_byte(2)// r, g, b
	write_byte(200)	// brightness
	write_byte(200)	// speed
	message_end()

}

public zp_extra_item_selected(player, itemid)
{
	if ( itemid == g_itemid )
	{
		if ( user_has_weapon(player, CSW_AK47) )
		{
			drop_prim(player)
		}
		
		give_item(player, "weapon_ak47")
		client_printcolor(player,"/g[ZoD *|]/y You have bought an /tGolden AK-47")
		g_HasAk[player] = true;
	}
}

stock drop_prim(id) 
{
	new weapons[32], num
	get_user_weapons(id, weapons, num)
	for (new i = 0; i < num; i++) {
		if (Wep_ak47 & (1<<weapons[i])) 
		{
			static wname[32]
			get_weaponname(weapons[i], wname, sizeof wname - 1)
			engclient_cmd(id, "drop", wname)
		}
	}
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
