#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <zp50_items>
#include <zp50_colorchat>

#define ITEM_NAME "Violingun"
#define ITEM_COST 35

#define WEAPON_BITSUM ((1<<CSW_SCOUT) | (1<<CSW_XM1014) | (1<<CSW_MAC10) | (1<<CSW_AUG) | (1<<CSW_UMP45) | (1<<CSW_SG550) | (1<<CSW_GALIL) | (1<<CSW_FAMAS) | (1<<CSW_AWP) | (1<<CSW_MP5NAVY) | (1<<CSW_M249) | (1<<CSW_M3) | (1<<CSW_M4A1) | (1<<CSW_TMP) | (1<<CSW_G3SG1) | (1<<CSW_SG552) | (1<<CSW_AK47) | (1<<CSW_P90))

new const VERSION[] = "1.3";

new g_clipammo[33], g_has_violingun[33], g_itemid, g_hamczbots, g_event_violingun, g_primaryattack, cvar_violingun_damage_x, cvar_violingun_bpammo, cvar_violingun_shotspd, cvar_violingun_oneround, cvar_violingun_clip, cvar_botquota;

new const SHOT_SOUND[][] = {"weapons/violingun_shoot1.wav", "weapons/violingun_shoot2.wav"};

new const VIOLIN_SOUNDS[][] = {"weapons/violingun_idle2.wav", "weapons/violingun_draw.wav", "weapons/violingun_clipout.wav", "weapons/violingun_clipin.wav"};

new const GUNSHOT_DECALS[] = {41, 42, 43, 44, 45};

new const V_VIOLIN_MDL[64] = "models/zombie_plague/v_violingun.mdl";
new const P_VIOLIN_MDL[64] = "models/zombie_plague/p_violingun.mdl";
new const W_VIOLIN_MDL[64] = "models/zombie_plague/w_violingun.mdl";

public plugin_init()
{
    // Plugin Register
    register_plugin("[ZP:50] Extra Item: Violingun", VERSION, "CrazY");

    // Extra Item Register
    g_itemid = zp_items_register(ITEM_NAME, ITEM_COST);

    // Cvars Register
    cvar_violingun_damage_x = register_cvar("zp_violingun_damage_x", "3.0");
    cvar_violingun_clip = register_cvar("zp_violingun_clip", "40");
    cvar_violingun_bpammo = register_cvar("zp_violingun_bpammo", "200");
    cvar_violingun_shotspd = register_cvar("zp_violingun_shot_speed", "0.10");
    cvar_violingun_oneround = register_cvar("zp_violingun_oneround", "0");

    // Cvar Pointer
    cvar_botquota = get_cvar_pointer("bot_quota");

    // Admin command
    register_concmd("amx_give_violingun", "cmd_give_violingun", 0);

    // Events
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0");

    // Forwards
    register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1);
    register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1);
    register_forward(FM_PlaybackEvent, "fw_PlaybackEvent");
    register_forward(FM_SetModel, "fw_SetModel");

    // HAM Forwards
    RegisterHam(Ham_Item_PostFrame, "weapon_galil", "fw_ItemPostFrame");
    RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack");
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack");
    RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_galil", "fw_PrimaryAttack_Post", 1);
    RegisterHam(Ham_Item_Deploy, "weapon_galil", "fw_ItemDeploy_Post", 1);
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
    RegisterHam(Ham_Item_AddToPlayer, "weapon_galil", "fw_AddToPlayer");
}

public plugin_precache()
{
    precache_model(V_VIOLIN_MDL);
    precache_model(P_VIOLIN_MDL);
    precache_model(W_VIOLIN_MDL);
    for(new i = 0; i < sizeof SHOT_SOUND; i++) precache_sound(SHOT_SOUND[i]);
    for(new i = 0; i < sizeof VIOLIN_SOUNDS; i++) precache_sound(VIOLIN_SOUNDS[i]);
}

public client_disconnect(id)
{
    g_has_violingun[id] = false;
}

public client_connect(id)
{
    g_has_violingun[id] = false;
}

public zp_fw_core_infect_post(id)
{
    g_has_violingun[id] = false;
}

public zp_fw_core_cure_post(id)
{
    g_has_violingun[id] = false;
}

public client_putinserver(id)
{
    g_has_violingun[id] = false;

    if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
    {
        set_task(0.1, "register_ham_czbots", id);
    }
}

public event_round_start()
{
    if (get_pcvar_num(cvar_violingun_oneround))
        for (new i = 1; i <= get_maxplayers(); i++) g_has_violingun[i] = false;
}

public register_ham_czbots(id)
{
    if (g_hamczbots || !is_user_bot(id) || !get_pcvar_num(cvar_botquota))
        return;

    RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage");

    g_hamczbots = true;
}

// Your custom print function
stock zod_colored_print(player, const message[], any:...)
{
    static formatted_message[192];
    vformat(formatted_message, charsmax(formatted_message), message, 3);
    static final_message[224];
    formatex(final_message, charsmax(final_message), "[ZoD *|] %s", formatted_message);
    client_print(player, print_chat, final_message);
    return 1;
}

public zp_fw_items_select_pre(id, itemid)
{
    if(itemid != g_itemid) return ZP_ITEM_AVAILABLE;
    
    if(zp_core_is_zombie(id)) return ZP_ITEM_DONT_SHOW;
    
    if(g_has_violingun[id])
    {
        zp_items_menu_text_add("\r[Bought]");
        return ZP_ITEM_NOT_AVAILABLE;
    }
    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(player, itemid)
{
    if(itemid != g_itemid)
        return;
    
    command_give_violingun(player);
}

public cmd_give_violingun(id, level, cid)
{
    if((get_user_flags(id) & level) != level)
    {
        return PLUGIN_HANDLED;
    }

    static arg[32], player;
    read_argv(1, arg, charsmax(arg));
    player = cmd_target(id, arg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));
    
    if (!player) return PLUGIN_HANDLED;

    zod_colored_print(player, "You won a %s.", ITEM_NAME);
    command_give_violingun(player);

    return PLUGIN_HANDLED;
}

public command_give_violingun(player)
{
    drop_primary(player);
    g_has_violingun[player] = true;
    new weaponid = give_item(player, "weapon_galil");
    cs_set_weapon_ammo(weaponid, get_pcvar_num(cvar_violingun_clip));
    cs_set_user_bpammo(player, CSW_GALIL, get_pcvar_num(cvar_violingun_bpammo));
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
    if (is_user_alive(id) && get_user_weapon(id) == CSW_GALIL && g_has_violingun[id])
    {
        set_cd(cd_handle, CD_flNextAttack, halflife_time () + 0.001);
    }
}

public fw_PrecacheEvent_Post(type, const name[])
{
    if (equal("events/galil.sc", name))
    {
        g_event_violingun = get_orig_retval();
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
    if ((eventid != g_event_violingun) || !g_primaryattack)
        return FMRES_IGNORED;

    if (!(1 <= invoker <= get_maxplayers()))
        return FMRES_IGNORED;

    playback_event(flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2);
    return FMRES_SUPERCEDE;
}

public fw_SetModel(entity, model[])
{
    if(!pev_valid(entity) || !equal(model, "models/w_galil.mdl")) return FMRES_IGNORED;
    
    static szClassName[33]; pev(entity, pev_classname, szClassName, charsmax(szClassName));
    if(!equal(szClassName, "weaponbox")) return FMRES_IGNORED;
    
    static owner, wpn;
    owner = pev(entity, pev_owner);
    wpn = find_ent_by_owner(-1, "weapon_galil", entity);
    
    if(g_has_violingun[owner] && pev_valid(wpn))
    {
        g_has_violingun[owner] = false;
        set_pev(wpn, pev_impulse, 10991);
        engfunc(EngFunc_SetModel, entity, W_VIOLIN_MDL);
        
        return FMRES_SUPERCEDE;
    }
    return FMRES_IGNORED;
}

public fw_AddToPlayer(wpn, id)
{
    if(pev_valid(wpn) && is_user_connected(id) && pev(wpn, pev_impulse) == 10991)
    {
        g_has_violingun[id] = true;
        set_pev(wpn, pev_impulse, 0);
        return HAM_HANDLED;
    }
    return HAM_IGNORED;
}

public fw_ItemPostFrame(weapon_entity)
{
    new id = pev(weapon_entity, pev_owner);

    if(!g_has_violingun[id] || !is_user_connected(id) || !pev_valid(weapon_entity))
        return HAM_IGNORED;

    static iClipExtra; iClipExtra = get_pcvar_num(cvar_violingun_clip);

    new Float:flNextAttack = get_pdata_float(id, 83, 5);

    new iBpAmmo = cs_get_user_bpammo(id, CSW_GALIL);
    new iClip = get_pdata_int(weapon_entity, 51, 4);

    new fInReload = get_pdata_int(weapon_entity, 54, 4);

    if(fInReload && flNextAttack <= 0.0)
    {
        new Clp = min(iClipExtra - iClip, iBpAmmo);
        set_pdata_int(weapon_entity, 51, iClip + Clp, 4);
        cs_set_user_bpammo(id, CSW_GALIL, iBpAmmo-Clp);
        set_pdata_int(weapon_entity, 54, 0, 4);
        fInReload = 0;

        return HAM_SUPERCEDE;
    }
    return HAM_IGNORED;
}

public fw_TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
    if (is_user_alive(iAttacker) && get_user_weapon(iAttacker) == CSW_GALIL && g_has_violingun[iAttacker])
    {
        static Float:flEnd[3];
        get_tr2(ptr, TR_vecEndPos, flEnd);
        if(iEnt)
        {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
            write_byte(TE_DECAL);
            engfunc(EngFunc_WriteCoord, flEnd[0]);
            engfunc(EngFunc_WriteCoord, flEnd[1]);
            engfunc(EngFunc_WriteCoord, flEnd[2]);
            write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)]);
            write_short(iEnt);
            message_end();
        } else {
            message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
            write_byte(TE_WORLDDECAL);
            engfunc(EngFunc_WriteCoord, flEnd[0]);
            engfunc(EngFunc_WriteCoord, flEnd[1]);
            engfunc(EngFunc_WriteCoord, flEnd[2]);
            write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)]);
            message_end();
        }
        message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
        write_byte(TE_GUNSHOTDECAL);
        engfunc(EngFunc_WriteCoord, flEnd[0]);
        engfunc(EngFunc_WriteCoord, flEnd[1]);
        engfunc(EngFunc_WriteCoord, flEnd[2]);
        write_short(iAttacker);
        write_byte(GUNSHOT_DECALS[random_num (0, sizeof GUNSHOT_DECALS -1)]);
        message_end();
    }
}

public fw_PrimaryAttack(weapon_entity)
{
    new id = get_pdata_cbase(weapon_entity, 41, 4);

    if (g_has_violingun[id])
    {
        g_clipammo[id] = cs_get_weapon_ammo(weapon_entity);
        g_primaryattack = 1;
    }
}

public fw_PrimaryAttack_Post(weapon_entity)
{
    new id = get_pdata_cbase(weapon_entity, 41, 4);

    if (g_has_violingun[id] && g_clipammo[id])
    {
        g_primaryattack = 0;
        set_pdata_float(weapon_entity, 46, get_pcvar_float(cvar_violingun_shotspd), 4);
        emit_sound(id, CHAN_WEAPON, SHOT_SOUND[random_num(0, sizeof SHOT_SOUND - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        UTIL_PlayWeaponAnimation(id, random_num(3, 5));
    }
}

public fw_ItemDeploy_Post(weapon_entity)
{
    static id; id = get_weapon_ent_owner(weapon_entity);

    if (pev_valid(id) && g_has_violingun[id])
    {
        set_pev(id, pev_viewmodel2, V_VIOLIN_MDL);
        set_pev(id, pev_weaponmodel2, P_VIOLIN_MDL);
    }
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
    if(is_user_alive(attacker) && get_user_weapon(attacker) == CSW_GALIL && g_has_violingun[attacker])
    {
        SetHamParamFloat(4, damage * get_pcvar_float(cvar_violingun_damage_x));
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

stock get_weapon_ent_owner(ent)
{
    return get_pdata_cbase(ent, 41, 4);
}

stock give_item(index, const item[])
{
    if (!equal(item, "weapon_", 7) && !equal(item, "ammo_", 5) && !equal(item, "item_", 5) && !equal(item, "tf_weapon_", 10))
        return 0;

    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
    
    if (!pev_valid(ent))
        return 0;

    new Float:origin[3];
    pev(index, pev_origin, origin);
    set_pev(ent, pev_origin, origin);
    set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
    dllfunc(DLLFunc_Spawn, ent);

    new save = pev(ent, pev_solid);
    dllfunc(DLLFunc_Touch, ent, index);
    if (pev(ent, pev_solid) != save)
        return ent;

    engfunc(EngFunc_RemoveEntity, ent);

    return -1;
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
