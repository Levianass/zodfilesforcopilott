#include <amxmodx>
#include <fun>
#include <fakemeta>
#include <zp50_core>
#include <zp50_items>
#include <zp50_class_nemesis>
#include <zp50_class_survivor>

new g_item_unlimited_clip

new const sound[] = {"zombie_plague/zpdam_item_unlimited_clip.wav"}

#if cellbits == 32
const OFFSET_CLIPAMMO = 51
#else
const OFFSET_CLIPAMMO = 65
#endif
const OFFSET_LINUX_WEAPONS = 4

new const MAXCLIP[] = { -1, 13, -1, 10, 1, 7, -1, 30, 30, 1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, 2, 7, 30, 30, -1, 50 }

new g_unlimited_clip[33]

new cvar_unlimited_clip_humain, cvar_unlimited_clip_survivor, cvar_unlimited_clip_sound

public plugin_init()
{
	register_plugin("[ZP] Item: Unlimited clip", "1.1", "Daminou")
	
	g_item_unlimited_clip = zp_items_register("Unlimited Clip\r(Single Round)", 30)
	
	cvar_unlimited_clip_humain = register_cvar("zpdam_unlimited_clip_humain", "1")
	cvar_unlimited_clip_survivor = register_cvar("zpdam_unlimited_clip_survivor", "0")
	cvar_unlimited_clip_sound = register_cvar("zpdam_unlimited_clip_sound", "0")
	
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_message(get_user_msgid("CurWeapon"), "message_cur_weapon")
}

public plugin_precache()
{
	precache_sound("zombie_plague/zpdam_item_unlimited_clip.wav")    
}

public client_putinserver(id)
{
	g_unlimited_clip[id] = false
}

public client_connect(id)
{
	g_unlimited_clip[id] = false
}

public client_disconnect(id)
{
	g_unlimited_clip[id] = false
}

public event_round_start()
{
	for (new id; id <= 32; id++) g_unlimited_clip[id] = false;
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	if(itemid == g_item_unlimited_clip)
	{
		if(zp_core_is_zombie(id) || zp_class_nemesis_get(id))
		{
			return ZP_ITEM_DONT_SHOW;
		}
		if((get_pcvar_num(cvar_unlimited_clip_humain) == 0) && !zp_core_is_zombie(id) && !zp_class_nemesis_get(id) && !zp_class_survivor_get(id))
		{
			return ZP_ITEM_DONT_SHOW;
		}
		if((get_pcvar_num(cvar_unlimited_clip_survivor) == 0) && zp_class_survivor_get(id))
		{
			return ZP_ITEM_DONT_SHOW;
		}
		if(g_unlimited_clip[id])
		{
			return ZP_ITEM_NOT_AVAILABLE;
		}
	}
	return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
	if(itemid == g_item_unlimited_clip)
	{       client_printcolor(id,"/gZoD *| /yYou have bought /gUnlimited Clip /yfor one round!")
		g_unlimited_clip[id] = true
		if(get_pcvar_num(cvar_unlimited_clip_sound) == 1)
		{
			engfunc(EngFunc_EmitSound, id, CHAN_BODY, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}
	return ZP_ITEM_AVAILABLE;
}

public message_cur_weapon(msg_id, msg_dest, msg_entity)
{
	if (!g_unlimited_clip[msg_entity])
		return;
	
	if (!is_user_alive(msg_entity) || get_msg_arg_int(1) != 1)
		return;
	
	static weapon, clip
	weapon = get_msg_arg_int(2)
	clip = get_msg_arg_int(3)
	
	if (MAXCLIP[weapon] > 2)
	{
		set_msg_arg_int(3, get_msg_argtype(3), MAXCLIP[weapon])
		
		if (clip < 2)
		{
			static wname[32], weapon_ent
			get_weaponname(weapon, wname, sizeof wname - 1)
			weapon_ent = fm_find_ent_by_owner(-1, wname, msg_entity)
			
			fm_set_weapon_ammo(weapon_ent, MAXCLIP[weapon])
		}
	}
}

stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

stock fm_set_weapon_ammo(entity, amount)
{
	set_pdata_int(entity, OFFSET_CLIPAMMO, amount, OFFSET_LINUX_WEAPONS);
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3082\\ f0\\ fs16 \n\\ par }
*/
