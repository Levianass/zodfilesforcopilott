#include < amxmodx >
#include < fun >
#include < cstrike >
#include < engine >
#include < fakemeta >
#include < hamsandwich >
#include < zp50_items >

#define WEAPON_BITSUM ((1<<CSW_FAMAS))

new const VERSION[] = "0.3";

const BALROG_KEY = 10992;




#define ITEM_NAME "AKM-12\r(2.0x Damage)"
#define ITEM_COST 50

new const V_AKM12_MDL[64] = "models/zombie_plague/v_akm-12.mdl";
new const P_AKM12_MDL[64] = "models/zombie_plague/p_akm-12.mdl";
new const W_AKM12_MDL[64] = "models/zombie_plague/w_akm-12.mdl";
new const OLD_W_MDL[64] = "models/w_famas.mdl";

new const SHOT_SOUND[] = {"weapons/akm12ds-1.wav", "weapons/akm12ds-2.wav"}

new const AKM12_SOUNDS[][] = {"weapons/akm_clipin.wav", "weapons/akm_clipout.wav", "weapons/akm_draw.wav"}

new const ZOOM_SOUND[] = "weapons/zoom.wav";

new const GUNSHOT_DECALS[] = { 41, 42, 43, 44, 45 }

new g_itemid , g_has_akm12[33] , g_hamczbots , g_has_zoom[33] , blood_spr[2] , cvar_akm12_damage_x , cvar_akm12_clip , cvar_akm12_bpammo , cvar_akm12_oneround , cvar_botquota;

new g_clip_ammo[33]

new cvar_rockguitar_shotspd


public plugin_init()
{
	// Plugin Register
	register_plugin("[ZP] Extra Item: AKM 12", VERSION, "CrazY");

	// Extra Item Register
	g_itemid = zp_items_register(ITEM_NAME, ITEM_COST);

	// Cvars Register
	cvar_akm12_damage_x = register_cvar("zp_akm12_damage_x", "2.0");
	cvar_akm12_clip = register_cvar("zp_akm12_clip", "40");
	cvar_akm12_bpammo = register_cvar("zp_akm12_bpammo", "200");
        cvar_rockguitar_shotspd = register_cvar("zp_akm12_shot_speed", "0.10")
	cvar_akm12_oneround = register_cvar("zp_akm12_oneround", "1");

	// Cvar Pointer
	cvar_botquota = get_cvar_pointer("bot_quota");

	// Events
	register_event("CurWeapon", "event_CurWeapon", "b", "1=1");
	register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0");
	register_event("DeathMsg", "event_DeathMsg", "a", "1>0");

	// Forwards
	register_forward(FM_SetModel, "fw_SetModel");
	register_forward(FM_CmdStart, "fw_CmdStart");
        register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);

	// Hams
	RegisterHam(Ham_Item_PostFrame, "weapon_famas", "fw_ItemPostFrame");
	RegisterHam(Ham_Item_AddToPlayer, "weapon_famas", "fw_AddToPlayer");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_famas", "fw_PrimaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_famas", "fw_PrimaryAttack_Post", 1);
        RegisterHam(Ham_Item_AddToPlayer, "weapon_famas", "fw_Item_AddToPlayer_Post", 1);
        RegisterHam( Ham_Item_Deploy , "weapon_famas" , "fw_Ham_BlockSilencer" );
        RegisterHam( Ham_Weapon_PrimaryAttack, "weapon_famas", "fw_Ham_BlockSilencer" , 1 );
}

public ClientCommand_SelectFlare( const client ) 
{ 
    engclient_cmd( client, "weapon_famas" ); 
}

public fw_Ham_BlockSilencer( iEnt)
{	
	set_pdata_float( iEnt , 47 , 9999.0 );

} 

public plugin_precache()
{
	// Models
	precache_model(V_AKM12_MDL);
	precache_model(P_AKM12_MDL);
	precache_model(W_AKM12_MDL);
	precache_model(OLD_W_MDL);

	// Blood Sprites
	blood_spr[0] = precache_model("sprites/blood.spr");
	blood_spr[1] = precache_model("sprites/bloodspray.spr");

	// Sounds
	for(new i = 0; i < sizeof AKM12_SOUNDS; i++) precache_sound(AKM12_SOUNDS[i]);
	precache_sound(ZOOM_SOUND);
        precache_sound(SHOT_SOUND);

	precache_generic( "sprites/weapon_akm.txt" );	
	precache_generic( "sprites/zod_akm.spr" );
        register_clcmd( "weapon_akm", "ClientCommand_SelectFlare" );
}

public client_putinserver(id)
{
	g_has_akm12[id] = false;

	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id);
	}
}

public client_disconnect(id)
{
	g_has_akm12[id] = false;
}

public client_connect(id)
{
	g_has_akm12[id] = false;
}

public zp_fw_core_infect_post(id)
{
	g_has_akm12[id] = false;
}

public zp_fw_core_cure_post(id)
{
	if(get_pcvar_num(cvar_akm12_oneround))
		g_has_akm12[id] = false;
}

public register_ham_czbots(id)
{
	if (g_hamczbots || !is_user_bot(id) || !get_pcvar_num(cvar_botquota))
		return;

	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");

	g_hamczbots = true;
}

public zp_fw_items_select_pre(id, itemid)
{
	if(itemid != g_itemid) return ZP_ITEM_AVAILABLE;
	
	if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
	
	if(g_has_akm12[id])
	{
		zp_items_menu_text_add("\r[Buyed]")
		return ZP_ITEM_NOT_AVAILABLE;
	}

	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(player, itemid)
{
	if(itemid != g_itemid)
		return;
	
	if(user_has_weapon(player, CSW_FAMAS))
	{
		drop_primary(player);
	}
	g_has_akm12[player] = true;
	new wpnid = give_item(player, "weapon_famas");
	client_print_color(player, "!y!gZoD *!y] You have !gbought !yan !tAKM-12.")
	cs_set_weapon_ammo(wpnid, get_pcvar_num(cvar_akm12_clip));
	cs_set_user_bpammo(player, CSW_FAMAS, get_pcvar_num(cvar_akm12_bpammo));
}

public event_CurWeapon(id)
{
	if (!is_user_alive(id) || zp_core_is_zombie(id)) return PLUGIN_HANDLED;
	
	if (read_data(2) == CSW_FAMAS && g_has_akm12[id])
	{
		set_pev(id, pev_viewmodel2, V_AKM12_MDL);
		set_pev(id, pev_weaponmodel2, P_AKM12_MDL);
	}
	return PLUGIN_CONTINUE;
}

public event_RoundStart()
{
	if(get_pcvar_num(cvar_akm12_oneround))
	{
		for(new id = 1; id <= get_maxplayers(); id++)
			g_has_akm12[id] = false;
	}
}

public event_DeathMsg()
{
	g_has_akm12[read_data(2)] = false;
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity) || !equal(model, OLD_W_MDL)) return FMRES_IGNORED;
	
	static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
	if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
	
	static owner, wpn;
	owner = pev(entity, pev_owner);
	wpn = find_ent_by_owner(-1, "weapon_famas", entity);
	
	if(g_has_akm12[owner] && pev_valid(wpn))
	{
		g_has_akm12[owner] = false;
		set_pev(wpn, pev_impulse, BALROG_KEY);
		engfunc(EngFunc_SetModel, entity, W_AKM12_MDL);
		
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
}

public M4A1_SecondaryAttack(iEnt)
{
    return HAM_SUPERCEDE
} 


public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_FAMAS && g_has_akm12[id])
	{
		set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
	}
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) &&  get_user_weapon(id) == CSW_FAMAS && g_has_akm12[id])
	{
		if((get_uc(uc_handle, UC_Buttons) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
		{
			if(!g_has_zoom[id])
			{
				g_has_zoom[id] = true;
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1);
				emit_sound(id, CHAN_ITEM, ZOOM_SOUND, 0.20, 2.40, 0, 100);
			}
			else
			{
				g_has_zoom[id] = false;
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
			}
		}

		if (g_has_zoom[id] && (pev(id, pev_button) & IN_RELOAD))
		{
			g_has_zoom[id] = false;
			cs_set_user_zoom(id, CS_RESET_ZOOM, 0);
		}
	}
}

public fw_ItemPostFrame(weapon_entity)
{
	new id = pev(weapon_entity, pev_owner);

	if(g_has_akm12[id] && is_user_alive(id))
	{
		static iClipExtra; iClipExtra = get_pcvar_num(cvar_akm12_clip);

		new Float:flNextAttack = get_pdata_float(id, 83, 5);

		new iBpAmmo = cs_get_user_bpammo(id, CSW_FAMAS);
		new iClip = get_pdata_int(weapon_entity, 51, 4);

		new fInReload = get_pdata_int(weapon_entity, 54, 4);

		if(fInReload && flNextAttack <= 0.0)
		{
			new Clp = min(iClipExtra - iClip, iBpAmmo);
			set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
			cs_set_user_bpammo(id, CSW_FAMAS, iBpAmmo-Clp);
			set_pdata_int(weapon_entity, 54, 0, 4);
	    }
    }
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;

	if (!is_user_alive(id))
		return HAM_IGNORED;

	if (pev(ent, pev_impulse) == BALROG_KEY)
	{
		g_has_akm12[id] = true;
		set_pev(ent, pev_impulse, 0);
	}

	message_begin(MSG_ONE, get_user_msgid("WeaponList"), _, id)
	write_string((g_has_akm12[id] ? "weapon_akm" : "weapon_famas"))
	write_byte(4)
	write_byte(90)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(18)
	write_byte(CSW_FAMAS)
	write_byte(0)
	message_end()

	return HAM_IGNORED;
}

public fw_AddToPlayer(weapon_entity, id)
{
	if(pev_valid(weapon_entity) && is_user_connected(id) && pev(weapon_entity, pev_impulse) == BALROG_KEY)
	{
		g_has_akm12[id] = true;
		set_pev(weapon_entity, pev_impulse, 0);
		return HAM_HANDLED;
	}
	return HAM_IGNORED;
}


public fw_PrimaryAttack(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);
	
	if(g_has_akm12[id])
	{
		g_clip_ammo[id] = cs_get_weapon_ammo(weapon_entity);
	}
}

public fw_PrimaryAttack_Post(weapon_entity)
{
	new id = get_pdata_cbase(weapon_entity, 41, 4);

	if (g_has_akm12[id] && g_clip_ammo[id])
	{
		set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_rockguitar_shotspd), 4);
		emit_sound(id, CHAN_WEAPON, SHOT_SOUND[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
		UTIL_PlayWeaponAnimation(id, random_num(3, 5));
		UTIL_MakeBloodAndBulletHoles(id);
	}
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_FAMAS && g_has_akm12[attacker])
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_akm12_damage_x));
	}
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

stock client_print_color(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1; vformat(msg,190,input,3);
	replace_all(msg,190,"!g","^4");    // green
	replace_all(msg,190,"!y","^1");    // normal
	replace_all(msg,190,"!t","^3");    // team
        
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


stock UTIL_PlayWeaponAnimation(const Player, const Sequence)
{
	set_pev(Player, pev_weaponanim, Sequence);
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = Player);
	write_byte(Sequence);
	write_byte(pev(Player, pev_body));
	message_end();
}

stock UTIL_MakeBloodAndBulletHoles(id)
{
	new aimOrigin[3], target, body;
	get_user_origin(id, aimOrigin, 3);
	get_user_aiming(id, target, body);
	
	if(target > 0 && target <= get_maxplayers() && zp_core_is_zombie(target))
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3];
		pev(id, pev_origin, fStart);
		
		velocity_by_aim(id, 64, fVel);
		
		fStart[0] = float(aimOrigin[0]);
		fStart[1] = float(aimOrigin[1]);
		fStart[2] = float(aimOrigin[2]);
		fEnd[0] = fStart[0]+fVel[0];
		fEnd[1] = fStart[1]+fVel[1];
		fEnd[2] = fStart[2]+fVel[2];
		
		new res;
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res);
		get_tr2(res, TR_vecEndPos, fRes);
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BLOODSPRITE);
		write_coord(floatround(fStart[0]));
		write_coord(floatround(fStart[1]));
		write_coord(floatround(fStart[2]));
		write_short(blood_spr[1]);
		write_short(blood_spr[0]);
		write_byte(70);
		write_byte(random_num(1,2));
		message_end();
		
		
	} 
	else if(!is_user_connected(target))
	{
		if(target)
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_DECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)]);
			write_short(target);
			message_end();
		} 
		else 
		{
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
			write_byte(TE_WORLDDECAL);
			write_coord(aimOrigin[0]);
			write_coord(aimOrigin[1]);
			write_coord(aimOrigin[2]);
			write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1)]);
			message_end()
		}
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_GUNSHOTDECAL);
		write_coord(aimOrigin[0]);
		write_coord(aimOrigin[1]);
		write_coord(aimOrigin[2]);
		write_short(id);
		write_byte(GUNSHOT_DECALS[random_num(0, sizeof GUNSHOT_DECALS -1 )]);
		message_end();
	}
}
