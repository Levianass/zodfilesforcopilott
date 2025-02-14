#include <amxmodx>
#include <fun>
#include <cstrike>
#include <engine> 
#include <fakemeta> 
#include <fakemeta_util> 
#include <hamsandwich>
#include <zombieplague>
#include <zp50_items>
#include <zp50_grenade_fire>
#include <zp50_grenade_frost>
#include <zmvip>


new const g_item_name[] = { "Fire M4A1" } // Item name
new const g_item_descritpion[] = { "\r50% off vip" } // Item descritpion
const g_item_cost = 25

new const g_item_name2[] = { "Frost M4A1" } // Item name
new const g_item_descritpion2[] = { "\r50% off vip" } // Item descritpion
const g_item_cost2 = 25

new const g_item_name3[] = { "Nuke M4A1" } // Item name
new const g_item_descritpion3[] = { "\r50% off vip" } // Item descritpion
const g_item_cost3 = 25


new g_ItemID, g_ItemID2, g_ItemID3
new g_bHasFireM4[33], g_bHasFrostM4[33], g_bHasNukeM4[33]

new g_iSpriteLaser, g_iSpriteLaser2
new g_iDmg[33]

new g_iFire, g_iFrost, g_iNuke
new g_iDmgMultiplier, g_iDmgMultiplier2, g_iDmgMultiplier3


#define V_MODEL "models/zombie_plague/v_fire.mdl"
#define P_MODEL "models/zombie_plague/p_fire.mdl"
#define W_MODEL "models/zombie_plague/w_fire.mdl"

#define V_MODEL2 "models/zombie_plague/v_zod_frost_m4a1.mdl"
#define P_MODEL2 "models/zombie_plague/p_zod_frost_m4a1.mdl"
#define W_MODEL2 "models/zombie_plague/w_zod_frost_m4a1.mdl"

#define V_MODEL3 "models/zombie_plague/v_nuke.mdl"
#define P_MODEL3 "models/zombie_plague/p_nuke.mdl"
#define W_MODEL3 "models/zombie_plague/w_nuke.mdl"

#define OLD_W_MODEL "models/w_m4a1.mdl"


#define WEAPON_BITSUM ((1<<CSW_M4A1))

new g_msgWeaponList, g_msgWeaponList2, g_msgWeaponList3

public plugin_init()
{
	register_plugin("ZP Fire M4A1", "1.0", "teNsk")
        g_ItemID = zv_register_extra_item(g_item_name, g_item_descritpion, g_item_cost, ZV_TEAM_HUMAN) 
        g_ItemID2 = zv_register_extra_item(g_item_name2, g_item_descritpion2, g_item_cost2, ZV_TEAM_HUMAN) 
        g_ItemID3 = zv_register_extra_item(g_item_name3, g_item_descritpion3, g_item_cost3, ZV_TEAM_HUMAN)
	
	
	g_iFire = register_cvar("zp_fire_m4_burn", "1200") // Damage Requried for fire burn
	g_iDmgMultiplier = register_cvar("zp_fire_m4_dmg", "2") // Multiplie Weapon Damage
	
	g_iFrost = register_cvar("zp_frost_m4", "1200") // Damage Requried for frost 
	g_iDmgMultiplier2 = register_cvar("zp_frost_m4_dmg", "2") // Multiplie Weapon Damage

	g_iNuke = register_cvar("zp_nuke_m4_blind", "1200") // Damage Requried for nuke 
	g_iDmgMultiplier3 = register_cvar("zp_nuke_m4_dmg", "2") // Multiplie Weapon Damage
	
	register_forward(FM_SetModel, "fw_SetModel")
	
	g_msgWeaponList = get_user_msgid("WeaponList");
	g_msgWeaponList2 = get_user_msgid("WeaponList");
	g_msgWeaponList3 = get_user_msgid("WeaponList");
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m4a1", "fw_AddToPlayer", 1);
	RegisterHam(Ham_Item_Deploy, "weapon_m4a1", "fw_Item_Deploy_Post", 1)
	RegisterHam( Ham_Item_ItemSlot, "weapon_m4a1", "OnItemSlotm4" );
	//RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_breakable", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "func_wall", "fw_TraceAttack", 1) 
	RegisterHam(Ham_TraceAttack, "func_door", "fw_TraceAttack", 1) 
	RegisterHam(Ham_TraceAttack, "func_door_rotating", "fw_TraceAttack", 1) 
	RegisterHam(Ham_TraceAttack, "func_plat", "fw_TraceAttack", 1) 
	RegisterHam(Ham_TraceAttack, "func_rotating", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack", 1)	

}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL2)
	engfunc(EngFunc_PrecacheModel, P_MODEL2)
	engfunc(EngFunc_PrecacheModel, W_MODEL2)
	
	engfunc(EngFunc_PrecacheModel, V_MODEL3)
	engfunc(EngFunc_PrecacheModel, P_MODEL3)
	engfunc(EngFunc_PrecacheModel, W_MODEL3)
	
	precache_generic( "sprites/weapon_m4a1_fire.txt" );
	precache_generic( "sprites/weapon_m4a1_frost.txt" );
	precache_generic( "sprites/weapon_m4a1_nuke.txt" );
	precache_generic( "sprites/zod_m4a1s.spr" );
	precache_generic( "sprites/zod_m4a1s_2.spr" );

	g_iSpriteLaser = precache_model( "sprites/xenobeam.spr")
	g_iSpriteLaser2 = precache_model( "sprites/Newlightning.spr")
	
	register_clcmd("weapon_m4a1_fire", "hook_weapon")
	register_clcmd("weapon_m4a1_frost", "hook_weapon")
	register_clcmd("weapon_m4a1_nuke", "hook_weapon")
}


public zp_user_humanized_post(id)
{
g_bHasFireM4[id] = false
g_bHasFrostM4[id] = false
g_bHasNukeM4[id] = false
g_iDmg[id] = 0
} 

public event_round_start()
{
	for (new i = 1; i <= get_maxplayers(); i++)
	{
		g_bHasFireM4[i] = false
		g_bHasFrostM4[i] = false
		g_bHasNukeM4[i] = false
		g_iDmg[i] = 0
	}
}


public zv_extra_item_selected(player, itemid)
{
	if (itemid == g_ItemID) 
	{
		if(user_has_weapon(player, CSW_M4A1))
		{
			drop_primary(player);
		}
		g_bHasFireM4[player] = true
		g_bHasFrostM4[player] = false
		g_bHasNukeM4[player] = false
		fm_give_item(player, "weapon_m4a1")
		cs_set_user_bpammo(player, CSW_M4A1, 90)
		new sName[32]
		get_user_name(player, sName, 31)
		set_hudmessage(random(255), random(255), random(255), -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		client_printcolor(player,"/y[/gZoD*| VIP/y] /yYou have bought a /tFire M4A1!")

		
	}
	if (itemid == g_ItemID2) 
	{
		if(user_has_weapon(player, CSW_M4A1))
		{
			drop_primary(player);
		}
		g_bHasFireM4[player] = false
		g_bHasFrostM4[player] = true
		g_bHasNukeM4[player] = false
		fm_give_item(player, "weapon_m4a1")
		cs_set_user_bpammo(player, CSW_M4A1, 90)
		new sName[32]
		get_user_name(player, sName, 31)
		set_hudmessage(random(255), random(255), random(255), -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		client_printcolor(player,"/y[/gZoD*| VIP/y] /yYou have bought a /tFrost M4A1!")

		
	}
	if (itemid == g_ItemID3) 
	{
		if(user_has_weapon(player, CSW_M4A1))
		{
			drop_primary(player);
		}
		g_bHasFireM4[player] = false
		g_bHasFrostM4[player] = false
		g_bHasNukeM4[player] = true
		fm_give_item(player, "weapon_m4a1")
		cs_set_user_bpammo(player, CSW_M4A1, 90)
		new sName[32]
		get_user_name(player, sName, 31)
		set_hudmessage(random(255), random(255), random(255), -1.0, 0.17, 1, 0.0, 5.0, 1.0, 1.0, -1)
		client_printcolor(player,"/y[/gZoD*| VIP/y] /yYou have bought a /gNuke M4A1!")

		
	}
}



public fw_Item_Deploy_Post(pEntity)
{
   static pPlayer;
   pPlayer = get_pdata_cbase(pEntity, 41, 4);

   if(pev_valid(pPlayer) && g_bHasFireM4[pPlayer])
   {	
		
      set_pev(pPlayer, pev_viewmodel2, V_MODEL)
      set_pev(pPlayer, pev_weaponmodel2, P_MODEL)
	
   }
   if(pev_valid(pPlayer) && g_bHasFrostM4[pPlayer])
   {	
		
      set_pev(pPlayer, pev_viewmodel2, V_MODEL2)
      set_pev(pPlayer, pev_weaponmodel2, P_MODEL2)
	
   }
   if(pev_valid(pPlayer) && g_bHasNukeM4[pPlayer])
   {	
		
      set_pev(pPlayer, pev_viewmodel2, V_MODEL3)
      set_pev(pPlayer, pev_weaponmodel2, P_MODEL3)
	
   }
}

public OnItemSlotm4( const item )
{
    SetHamReturnInteger(5);
    return HAM_SUPERCEDE;
}



public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType) // Added By ShaunCraft
{
	if(is_user_alive(iAttacker))
	{
		if( get_user_weapon(iAttacker) == CSW_M4A1 && g_bHasFireM4[iAttacker]) 
		{
			static Float:end[3]
			get_tr2(ptr, TR_vecEndPos, end)
	
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte(TE_BEAMENTPOINT)
			write_short(iAttacker | 0x1000)
			engfunc(EngFunc_WriteCoord, end[0])
			engfunc(EngFunc_WriteCoord, end[1])
			engfunc(EngFunc_WriteCoord, end[2])
			write_short(g_iSpriteLaser)
			write_byte(1) // framerate
			write_byte(5) // framerate
			write_byte(1) // life
			write_byte(5)  // width
			write_byte(0)// noise
			write_byte(255)// r, g, b
			write_byte(50)// r, g, b
			write_byte(0)// r, g, b
			write_byte(200)	// brightness
			write_byte(20)	// speed
			message_end()
			
		}
		if( get_user_weapon(iAttacker) == CSW_M4A1 && g_bHasFrostM4[iAttacker]) 
		{
			static Float:end[3]
			get_tr2(ptr, TR_vecEndPos, end)
	
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte(TE_BEAMENTPOINT)
			write_short(iAttacker | 0x1000)
			engfunc(EngFunc_WriteCoord, end[0])
			engfunc(EngFunc_WriteCoord, end[1])
			engfunc(EngFunc_WriteCoord, end[2])
			write_short(g_iSpriteLaser2)
			write_byte(1) // framerate
			write_byte(5) // framerate
			write_byte(1) // life
			write_byte(10)  // width
			write_byte(0)// noise
			write_byte(0)// r, g, b
			write_byte(196)// r, g, b
			write_byte(255)// r, g, b
			write_byte(80)	// brightness
			write_byte(155)	// speed
			message_end()
			
		}
		if( get_user_weapon(iAttacker) == CSW_M4A1 && g_bHasNukeM4[iAttacker]) 
		{
			static Float:end[3]
			get_tr2(ptr, TR_vecEndPos, end)
	
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY )
			write_byte(TE_BEAMENTPOINT)
			write_short(iAttacker | 0x1000)
			engfunc(EngFunc_WriteCoord, end[0])
			engfunc(EngFunc_WriteCoord, end[1])
			engfunc(EngFunc_WriteCoord, end[2])
			write_short(g_iSpriteLaser)
			write_byte(1) // framerate
			write_byte(5) // framerate
			write_byte(1) // life
			write_byte(5)  // width
			write_byte(0)// noise
			write_byte(50)// r, g, b
			write_byte(255)// r, g, b
			write_byte(50)// r, g, b
			write_byte(100)	// brightness
			write_byte(20)	// speed
			message_end()
			
		}
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	if(is_user_alive(attacker) && attacker != victim)
	{
		if(g_bHasFireM4[attacker] && (get_user_weapon(attacker) == CSW_M4A1))
			SetHamParamFloat(4, damage * get_pcvar_num(g_iDmgMultiplier))
	
		if((get_user_weapon(attacker) == CSW_M4A1) && g_bHasFireM4[attacker])
		{
			g_iDmg[attacker] += (floatround(damage) * get_pcvar_num(g_iDmgMultiplier))
		}
	
		if((g_iDmg[attacker] >= get_pcvar_num(g_iFire)) && (get_user_weapon(attacker) == CSW_M4A1) && g_bHasFireM4[attacker])
		{
			new sName[32]
			get_user_name(victim, sName, charsmax(sName))
			if(zp_get_user_zombie(victim))
			{
				zp_grenade_fire_set(victim, true)
                                set_task(1.0,"Task_Unfire",victim)
			}
			g_iDmg[attacker] = 0
		}	
		
		if(g_bHasFrostM4[attacker] && (get_user_weapon(attacker) == CSW_M4A1))
			SetHamParamFloat(4, damage * get_pcvar_num(g_iDmgMultiplier2))
	
		if((get_user_weapon(attacker) == CSW_M4A1) && g_bHasFrostM4[attacker])
		{
			g_iDmg[attacker] += (floatround(damage) * get_pcvar_num(g_iDmgMultiplier2))
		}
	
		if((g_iDmg[attacker] >= get_pcvar_num(g_iFrost)) && (get_user_weapon(attacker) == CSW_M4A1) && g_bHasFrostM4[attacker])
		{
			new sName[32]
			get_user_name(victim, sName, charsmax(sName))
			if(zp_get_user_zombie(victim))
			{
				zp_grenade_frost_set(victim, true)
                                set_task(1.0,"Task_Unfreeze",victim)
			}
			g_iDmg[attacker] = 0
		}	
		
		if(g_bHasNukeM4[attacker] && (get_user_weapon(attacker) == CSW_M4A1))
			SetHamParamFloat(4, damage * get_pcvar_num(g_iDmgMultiplier3))
	
		if((get_user_weapon(attacker) == CSW_M4A1) && g_bHasNukeM4[attacker])
		{
			g_iDmg[attacker] += (floatround(damage) * get_pcvar_num(g_iDmgMultiplier3))
		}
	
		if((g_iDmg[attacker] >= get_pcvar_num(g_iNuke)) && (get_user_weapon(attacker) == CSW_M4A1) && g_bHasNukeM4[attacker])
		{
			new sName[32]
			get_user_name(victim, sName, charsmax(sName))
			if(zp_get_user_zombie(victim))
			{
				set_user_rendering(victim, kRenderFxGlowShell, 0, 200, 0, kRenderNormal, 16)
				set_task(3.5, "render", victim)
				ScreenFade(victim, 3.5, 0, 0, 0, 255)
			}
			g_iDmg[attacker] = 0
		}	
	}
}

public Task_Unfreeze(id)

{

	if(is_user_alive(id))

		zp_grenade_frost_set(id, false)

}

public Task_Unfire(id)

{

	if(is_user_alive(id))

		zp_grenade_fire_set(id, false)

}



public render(victim) set_user_rendering(victim)

public hook_weapon(id)
{
	engclient_cmd(id, "weapon_m4a1")
}



public fw_AddToPlayer(ent, id)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;

	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (pev(ent, pev_impulse) == 43556 && pev(ent, pev_impulse) != 53557 && pev(ent, pev_impulse) != 63558)
	{
		g_bHasFireM4[id] = true;
		set_pev(ent, pev_impulse, 0);
	}
	if (pev(ent, pev_impulse) == 53557 && pev(ent, pev_impulse) != 43556 && pev(ent, pev_impulse) != 63558)
	{
		g_bHasFrostM4[id] = true;
		set_pev(ent, pev_impulse, 0);
	}
	if (pev(ent, pev_impulse) == 63558 && pev(ent, pev_impulse) != 53557 && pev(ent, pev_impulse) != 43556)
	{
		g_bHasNukeM4[id] = true;
		set_pev(ent, pev_impulse, 0);
	}

	if(!g_bHasFrostM4[id] && !g_bHasNukeM4[id])
	{
	message_begin(MSG_ONE, g_msgWeaponList, _, id)
	write_string((g_bHasFireM4[id] ? "weapon_m4a1_fire" : "weapon_m4a1"))
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(6)
	write_byte(CSW_M4A1)
	write_byte(0)
	message_end()
	}
	
	if(!g_bHasFireM4[id] && !g_bHasNukeM4[id])
	{
	message_begin(MSG_ONE, g_msgWeaponList2, _, id)
	write_string((g_bHasFrostM4[id] ? "weapon_m4a1_frost" : "weapon_m4a1"))
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(6)
	write_byte(CSW_M4A1)
	write_byte(0)
	message_end()
	}
	if(!g_bHasFireM4[id] && !g_bHasFrostM4[id])
	{
	message_begin(MSG_ONE, g_msgWeaponList3, _, id)
	write_string((g_bHasNukeM4[id] ? "weapon_m4a1_nuke" : "weapon_m4a1"))
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(6)
	write_byte(CSW_M4A1)
	write_byte(0)
	message_end()
	}
	return HAM_IGNORED;	

}


public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_M4A1)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_bHasFireM4[id])
		{
			set_pev(weapon, pev_impulse, 43556)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			g_bHasFireM4[id] = false;
			
			return FMRES_SUPERCEDE
		}
		if(g_bHasFrostM4[id])
		{
			set_pev(weapon, pev_impulse, 53557)
			engfunc(EngFunc_SetModel, entity, W_MODEL2)

			g_bHasFrostM4[id] = false;
			
			return FMRES_SUPERCEDE
		}
		if(g_bHasNukeM4[id])
		{
			set_pev(weapon, pev_impulse, 63558)
			engfunc(EngFunc_SetModel, entity, W_MODEL3)
			
			g_bHasNukeM4[id] = false;
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}
stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
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