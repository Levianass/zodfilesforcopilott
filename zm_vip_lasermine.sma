#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <zmvip>
#include <zp50_colorchat>


// Item Cost
const ITEM_COST = 20;

new const g_item_name[] = { "Lasermine" } // Item name
new const g_item_descritpion[] = { "Free" } // Item descritpion
const g_item_cost = 0 // Price (ammo)


// Constants
const m_pOwner = EV_INT_iuser1;
const m_pBeam = EV_INT_iuser2;
const m_rgpDmgTime = EV_INT_iuser3;
const m_flPowerUp = EV_FL_starttime;
const m_vecEnd = EV_VEC_endpos;
const m_flSparks = EV_FL_ltime;

const MAXPLAYERS = 32;
new limit[33]
const OFFSET_CSMENUCODE = 205;

// Enums
enum _:tripmine_e
{
    TRIPMINE_IDLE1 = 0,
    TRIPMINE_IDLE2,
    TRIPMINE_ARM1,
    TRIPMINE_ARM2,
    TRIPMINE_FIDGET,
    TRIPMINE_HOLSTER,
    TRIPMINE_DRAW,
    TRIPMINE_WORLD,
    TRIPMINE_GROUND,
};

enum
{
    BEAM_POINTS = 0,
    BEAM_ENTPOINT,
    BEAM_ENTS,
    BEAM_HOSE,
};

// Tasks
const TASK_SETLASER = 100;
const TASK_DELLASER = 200;
const TASK_IDLE = 300;

// Variables
new g_iMsgBarTime;
new g_iTripmine[MAXPLAYERS+1], g_iTripmineHealth[MAXPLAYERS+1][100], bool:g_bCantPlant[MAXPLAYERS+1];
new g_iTripmineId, cvar_tripmine_health, cvar_tripmine_bonus;
new g_iMsgSayTxt
new g_PlayerArmor[33]

public plugin_init()
{
    register_plugin("[ZP] Extra Item: Laser Tripmine", "1.0", "Lost-Souls")

    // Register Message
    g_iMsgBarTime = get_user_msgid("BarTime");

    // Register Event
    register_event("HLTV", "EventNewRound", "a", "1=0", "2=0");

    // Register Item
    g_iTripmineId = zv_register_extra_item(g_item_name, g_item_descritpion, g_item_cost, ZV_TEAM_HUMAN)


    // Register Forwards
    RegisterHam(Ham_Killed, "player", "CBasePlayer_Killed_Post", 1);
    RegisterHam(Ham_TakeDamage, "player", "CBasePlayer_TakeDamage_Pre");
    RegisterHam(Ham_TakeDamage, "info_target", "Tripmine_TakeDamage_Pre");
    RegisterHam(Ham_TakeDamage, "info_target", "Tripmine_TakeDamage_Post", 1);
    RegisterHam(Ham_Killed, "info_target", "Tripmine_Killed_Post", 1);

    register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
    register_forward(FM_TraceLine, "Tripmine_ShowInfo_Post", 1);

    // Register Think
    register_think("zp_tripmine", "Tripmine_Think");

    // Register Cvars
    cvar_tripmine_health = register_cvar("zp_tripmine_health", "650");
    cvar_tripmine_bonus = register_cvar("zp_tripmine_bonus", "5");

    g_iMsgSayTxt = get_user_msgid("SayText")

    // Register Binds
    register_concmd("+setlaser", "CmdSetLaser");
    register_concmd("-setlaser", "CmdUnsetLaser");
    register_concmd("+dellaser", "CmdDelLaser");
    register_concmd("-dellaser", "CmdUndelLaser");

    // Register Commands
    register_clcmd("say /lmv", "showMenuLasermine");
    register_clcmd("say_team /lmv", "showMenuLasermine");
}

public plugin_precache()
{
    precache_model("models/zod_lasermine.mdl");
    precache_model("sprites/laserbeam.spr");
    precache_sound("weapons/mine_deploy.wav");
    precache_sound("weapons/mine_charge.wav");
    precache_sound("weapons/mine_activate.wav");
    precache_sound("debris/beamstart9.wav");
    precache_sound("items/gunpickup2.wav");
}

// The first three public fuctions below make sure that this plugin won't stop running if the modules below ain't running
public plugin_natives()
{
    set_module_filter("moduleFilter")
    set_native_filter("nativeFilter")
}

public moduleFilter(const szModule[])
{
    
    return PLUGIN_CONTINUE;
}

public nativeFilter(const szName[], iId, iTrap)
{
    if (!iTrap)
        return PLUGIN_HANDLED;
    
    return PLUGIN_CONTINUE;
}

public client_disconnected(this)
{
    g_iTripmine[this] = 0;

    Tripmine_Kill(this);
}

public EventNewRound()
{
    new pTripmine = -1;

    while ((pTripmine = find_ent_by_class(pTripmine, "zp_tripmine")) != 0)
        remove_entity(pTripmine);

    arrayset(g_iTripmine, 0, sizeof g_iTripmine);

    for ( new id; id <= get_maxplayers(); id++)
    g_PlayerArmor[1] = false

    new rgpPlayers[MAXPLAYERS], iPlayersCount, pPlayer;
    get_players(rgpPlayers, iPlayersCount);

    for (new i = 0; i < iPlayersCount; i++)
    {
        pPlayer = rgpPlayers[i];
        limit[pPlayer] = 0
        Tripmine_Kill(pPlayer);
    }
}

public CmdSetLaser(this)
{
    if (!is_user_alive(this))
        return PLUGIN_HANDLED;
    
    if (zp_get_user_zombie(this))
        return PLUGIN_HANDLED;

    if (task_exists(this+TASK_SETLASER))
        return PLUGIN_HANDLED;

    if (!g_iTripmine[this])
    {
        client_printcolor(this, "!y[!gZoD *| VIP!y] You do not have lasermines to plant");
        return PLUGIN_HANDLED;
    }

    if (task_exists(this+TASK_DELLASER))
        return PLUGIN_HANDLED;
	
	
    new rgpData[1];

    new pTripmine = rgpData[0] = Tripmine_Spawn(this);
    Tripmine_RelinkTripmine(pTripmine);

    if (g_bCantPlant[this])
    {
        client_printcolor(this, "!y[!gZoD *| VIP!y] You can't plant a !gLasermine !yat this location!");

        Tripmine_Kill(this);
        return PLUGIN_HANDLED;
    }

    set_task(0.27, "TaskIdle", this+TASK_IDLE, rgpData, sizeof rgpData, "b");
    set_task(1.0, "TaskSetLaser", this+TASK_SETLASER, rgpData, sizeof rgpData);

    BarTime(this, 1);
    emit_sound(this, CHAN_ITEM, "weapons/c4_disarm.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return PLUGIN_HANDLED;
}

public CmdUnsetLaser(this)
{
    if (!task_exists(this+TASK_SETLASER))
        return PLUGIN_HANDLED;

    Tripmine_Kill(this);
    return PLUGIN_HANDLED;
}

public CmdDelLaser(this)
{
    if (!is_user_alive(this))
        return PLUGIN_HANDLED;

    if (zp_get_user_zombie(this))
        return PLUGIN_HANDLED;

    if (task_exists(this+TASK_SETLASER))
        return PLUGIN_HANDLED;

    new iBody, pEnt;

    get_user_aiming(this, pEnt, iBody, 128);

    if (!is_valid_ent(pEnt))
        return PLUGIN_HANDLED;

    new szClassName[32];

    entity_get_string(pEnt, EV_SZ_classname, szClassName, charsmax(szClassName));

    if (!equal(szClassName, "zp_tripmine"))
        return PLUGIN_HANDLED;

    if (entity_get_int(pEnt, m_pOwner) != this)
        return PLUGIN_HANDLED;

    new rgpData[1];

    rgpData[0] = pEnt;

    set_task(1.0, "TaskDelLaser", this+TASK_DELLASER, rgpData, sizeof rgpData);
    set_task(0.27, "TaskIdle", this+TASK_IDLE, rgpData, sizeof rgpData, "b");
    
    BarTime(this, 1);
    emit_sound(this, CHAN_ITEM, "weapons/c4_disarm.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    return PLUGIN_HANDLED;
}

public CmdUndelLaser(this)
{
    if (!task_exists(this+TASK_DELLASER))
        return PLUGIN_HANDLED;

    Tripmine_Kill(this);
    return PLUGIN_HANDLED;
}

public TaskIdle(rgpData[], iTaskId)
{
    new Float:vecVelocity[3], pEnt, iBody;

    new pPlayer = iTaskId - TASK_IDLE;

    get_user_aiming(pPlayer, pEnt, iBody, 128);
    entity_get_vector(pPlayer, EV_VEC_velocity, vecVelocity);

    if (vector_length(vecVelocity) > 6.0 || task_exists(pPlayer+TASK_DELLASER) && rgpData[0] != pEnt)
        Tripmine_Kill(pPlayer);
}

public TaskSetLaser(rgpData[], iTaskId)
{
    new pPlayer = iTaskId - TASK_SETLASER;

    if (g_bCantPlant[pPlayer])
    {
        client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] couldn't plant a !gLasermine!");

        Tripmine_Kill(pPlayer);
        return;
    }
    
    g_iTripmine[pPlayer] -= 1;

    if (!g_iTripmine[pPlayer])
        client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] You do not have any more lasermines");
    else
        client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] You have !g%d !ymore Lasermine(s) to plant", g_iTripmine[pPlayer]);

    new pBeam = entity_get_int(rgpData[0], m_pBeam);

    remove_task(pPlayer+TASK_IDLE);

    entity_set_vector(pBeam, EV_VEC_rendercolor, Float:{150.0, 0.0, 0.0});
    entity_set_int(pBeam, EV_INT_effects, entity_get_int(pBeam, EV_INT_effects) | EF_NODRAW);

    Tripmine_Render(rgpData[0]);

    entity_set_float(rgpData[0], EV_FL_nextthink, get_gametime() + 2.5);
    entity_set_float(rgpData[0], m_flPowerUp, 1.0);
    entity_set_int(rgpData[0], EV_INT_rendermode, kRenderNormal);

    emit_sound(rgpData[0], CHAN_VOICE, "weapons/mine_deploy.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    emit_sound(rgpData[0], CHAN_BODY, "weapons/mine_charge.wav", 0.2, ATTN_NORM, 0, PITCH_NORM);
    set_rendering(rgpData[0], kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 16)
}

public TaskDelLaser(rgpData[], iTaskId)
{
    if (!is_valid_ent(rgpData[0]))
        return;
    
    new pPlayer = iTaskId - TASK_DELLASER;

    g_iTripmineHealth[pPlayer][g_iTripmine[pPlayer]] = floatround(entity_get_float(rgpData[0], EV_FL_health));

    remove_entity(rgpData[0]);
    remove_task(pPlayer+TASK_IDLE);

    emit_sound(pPlayer, CHAN_ITEM, "weapons/c4_disarmed.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    g_iTripmine[pPlayer]++;
}

public zp_user_humanized_post(this)
{
	g_iTripmine[this] = 0;

	Tripmine_Kill(this);

	new Array:hDmgTime = Array:entity_get_int(this, m_rgpDmgTime);
	
	ArrayDestroy(hDmgTime);
}

public zp_user_infected_post(this)
{
	g_iTripmine[this] = 0;

	Tripmine_Kill(this);

	new Array:hDmgTime = Array:entity_get_int(this, m_rgpDmgTime);

	remove_entity(entity_get_int(this, m_pBeam));
	
	ArrayDestroy(hDmgTime);
}

public remove_preview(id)
{
	g_iTripmine[id] = 0;

	Tripmine_Kill(id);

	new Array:hDmgTime = Array:entity_get_int(id, m_rgpDmgTime);

	remove_entity(entity_get_int(id, m_pBeam));
	
	ArrayDestroy(hDmgTime);
}


public zv_extra_item_selected(pPlayer, iItemId)
{
    if (iItemId != g_iTripmineId)
        return;

    if (g_PlayerArmor[1])
    {
        zp_colored_print(pPlayer, "You can only buy one per round!!") 
        return;
    }

    new iHealth = get_pcvar_num(cvar_tripmine_health);
    g_iTripmineHealth[pPlayer][g_iTripmine[pPlayer]] = iHealth;
    g_iTripmine[pPlayer] += 1;
    g_PlayerArmor[1] = true
    emit_sound(pPlayer, CHAN_BODY, "items/gunpickup2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
    client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] You have bought a !g%d !yLasermine!y!", g_iTripmine[pPlayer]);
    client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] To plant a !yLasermine type on console !g'bind key +setlaser'!y!");
    client_printcolor(pPlayer, "!y[!gZoD *| VIP!y] To remove a !yLasermine type on console !g'bind key +dellaser'!y!");

}
public CBasePlayer_Killed_Post(this)
{
    g_iTripmine[this] = 0;

    Tripmine_Kill(this);
}

public CBasePlayer_TakeDamage_Pre(this, pInflictor, pAttacker, Float:flDamage)
{
    if (!FClassnameIs(pInflictor, "zp_tripmine_exp"))
        return HAM_IGNORED;

    if (!zp_get_user_zombie(this))
        return HAM_SUPERCEDE;

    SetHamParamInteger(5, DMG_GENERIC);
    SetHamParamEntity(3, entity_get_int(pInflictor, EV_INT_iuser1));
    SetHamParamFloat(4, floatmax(flDamage * 6.0, 600.0));

    return HAM_HANDLED;
}

public OnFreeEntPrivateData(this)
{
    new szClassName[32];

    entity_get_string(this, EV_SZ_classname, szClassName, charsmax(szClassName));

    if (!equal(szClassName, "zp_tripmine"))
        return FMRES_IGNORED;

    new Array:hDmgTime = Array:entity_get_int(this, m_rgpDmgTime);

    remove_entity(entity_get_int(this, m_pBeam));
    
    ArrayDestroy(hDmgTime);
    return FMRES_IGNORED;
}

Tripmine_Spawn(pOwner)
{
    new pTripmine = create_entity("info_target");
    new Array:hDmgTime = ArrayCreate(1, 1);

    for (new i = 0; i < MAXPLAYERS+1; i++)
        ArrayPushCell(hDmgTime, 0.0);

    entity_set_int(pTripmine, EV_INT_movetype, MOVETYPE_FLY);
    entity_set_int(pTripmine, EV_INT_solid, SOLID_NOT);
    entity_set_model(pTripmine, "models/zod_lasermine.mdl");
    entity_set_int(pTripmine, EV_INT_body, 11);
    entity_set_int(pTripmine, EV_INT_sequence, TRIPMINE_WORLD);
    entity_set_string(pTripmine, EV_SZ_classname, "zp_tripmine");
    entity_set_size(pTripmine, Float:{-8.0, -8.0, -8.0}, Float:{8.0, 8.0, 8.0});
    entity_set_int(pTripmine, EV_INT_rendermode, kRenderTransAdd);
    entity_set_float(pTripmine, EV_FL_renderamt, 200.0);
    entity_set_int(pTripmine, m_pOwner, pOwner);
    entity_set_int(pTripmine, m_rgpDmgTime, _:hDmgTime);
    entity_set_float(pTripmine, EV_FL_health, float(g_iTripmineHealth[pOwner][g_iTripmine[pOwner] - 1]));
    entity_set_float(pTripmine, EV_FL_max_health, 455.0);
    entity_set_float(pTripmine, EV_FL_nextthink, get_gametime() + 0.02);
    
    new pBeam = Beam_BeamCreate("sprites/laserbeam.spr", 6.0);
    Beam_EntsInit(pBeam, pTripmine, pOwner);

    entity_set_vector(pBeam, EV_VEC_rendercolor, Float:{150.0, 0.0, 0.0});
    entity_set_float(pBeam, EV_FL_frame, 10.0);
    entity_set_float(pBeam, EV_FL_animtime, 255.0);
    entity_set_float(pBeam, EV_FL_renderamt, 200.0);
    entity_set_int(pTripmine, m_pBeam, pBeam);
    entity_set_int(pBeam, EV_INT_effects, entity_get_int(pBeam, EV_INT_effects));
    
    return pTripmine;
}

public Tripmine_TakeDamage_Pre(this, pInflictor, pAttacker)
{
    if (!FClassnameIs(this, "zp_tripmine"))
        return HAM_IGNORED;

    if (!is_user_alive(pAttacker))
        return HAM_SUPERCEDE;

    if (!zp_get_user_zombie(pAttacker))
        return HAM_SUPERCEDE;

    return HAM_IGNORED;
}

public Tripmine_TakeDamage_Post(this, pInflictor, pAttacker)
{
    if (!FClassnameIs(this, "zp_tripmine"))
        return;

    if (GetHamReturnStatus() == HAM_SUPERCEDE)
        return;

    Tripmine_Render(this);
}

public Tripmine_Killed_Post(this, pAttacker)
{
    if (!FClassnameIs(this, "zp_tripmine"))
        return;

    if (!is_user_alive(pAttacker))
        return;

    if (!zp_get_user_zombie(pAttacker))
        return;

    new szName[32];
    get_user_name(pAttacker, szName, charsmax(szName));
    
    new Float:vecOrigin[3];
    new iBonus = get_pcvar_num(cvar_tripmine_bonus);

    zp_set_user_ammo_packs(pAttacker, zp_get_user_ammo_packs(pAttacker) + iBonus);
    client_printcolor(0, "!y[!gZoD *| VIP!y] !g%s !yhas earned !g5 !ypoints for destroying a !gLasermine!y!", szName, iBonus);
    

    entity_get_vector(this, EV_VEC_origin, vecOrigin);

    ExplosionCreate(vecOrigin, 110, entity_get_int(this, m_pOwner));
}

ExplosionCreate(const Float:vecOrigin[3], iMagnitude, pAttacker = 0, bool:bDoDamage = true)
{
    new szMagnitude[11];

    new pExplosion = create_entity("env_explosion");

    formatex(szMagnitude, charsmax(szMagnitude), "%3d", iMagnitude);

    entity_set_origin(pExplosion, vecOrigin);
    entity_set_int(pExplosion, EV_INT_iuser1, pAttacker);
    entity_set_string(pExplosion, EV_SZ_classname, "zp_tripmine_exp");

    if (!bDoDamage)
        entity_set_int(pExplosion, EV_INT_spawnflags, entity_get_int(pExplosion, EV_INT_spawnflags) | SF_ENVEXPLOSION_NODAMAGE);

    DispatchKeyValue(pExplosion, "iMagnitude", szMagnitude);
    DispatchSpawn(pExplosion);

    force_use(pExplosion, pExplosion);
}

public Tripmine_Think(this)
{
    static Float:flGameTime;

    flGameTime = get_gametime();
    
    if (entity_get_int(this, EV_INT_renderfx) == kRenderFxGlowShell)
    {
        static pBeam, Array:hDmgTime, Float:vecEnd[3], Float:vecSrc[3];

        pBeam = entity_get_int(this, m_pBeam);
        hDmgTime = Array:entity_get_int(this, m_rgpDmgTime);

        entity_get_vector(this, EV_VEC_origin, vecSrc);
        entity_get_vector(this, m_vecEnd, vecEnd);

        if (entity_get_float(this, m_flPowerUp) == 1.0)
        {
            static Float:vecAngles[3], Float:vecDir[3];

            entity_get_vector(this, EV_VEC_angles, vecAngles);
            entity_get_vector(this, EV_VEC_origin, vecSrc);

            MakeAimVectors(vecAngles);

            global_get(glb_v_forward, vecDir);
            xs_vec_mul_scalar(vecDir, 2048.0, vecDir);
            xs_vec_add(vecSrc, vecDir, vecEnd);
            
            entity_set_int(pBeam, EV_INT_effects, entity_get_int(pBeam, EV_INT_effects) & ~EF_NODRAW);

            Beam_PointEntInit(pBeam, vecEnd, this);

            entity_set_int(this, EV_INT_solid, SOLID_BBOX);
            entity_set_float(this, EV_FL_takedamage, DAMAGE_YES);
            entity_set_vector(this, m_vecEnd, vecEnd);
            entity_set_float(this, m_flPowerUp, 0.0);

            emit_sound(this, CHAN_VOICE, "weapons/mine_activate.wav", 0.5, ATTN_NORM, 0, 75);
        }
        
        engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, 0);

        static Float:flFraction;

        get_tr2(0, TR_flFraction, flFraction);

        if (flFraction < 1.0)
        {
            get_tr2(0, TR_vecEndPos, vecEnd);

            entity_set_vector(pBeam, EV_VEC_origin, vecEnd);

            Beam_RelinkBeam(pBeam);
        }

        static Float:vecAbsMin[3], Float:vecAbsMax[3];

        vecAbsMin[0] = floatmin(vecEnd[0], vecSrc[0]);
        vecAbsMin[1] = floatmin(vecEnd[1], vecSrc[1]);
        vecAbsMin[2] = floatmin(vecEnd[2], vecSrc[2]);

        vecAbsMax[0] = floatmax(vecEnd[0], vecSrc[0]);
        vecAbsMax[1] = floatmax(vecEnd[1], vecSrc[1]);
        vecAbsMax[2] = floatmax(vecEnd[2], vecSrc[2]);

        static i, Float:flLastDamageTime, rgpPlayers[MAXPLAYERS], iPlayersCount, pPlayer, pOwner;

        iPlayersCount = 0;
        pOwner = entity_get_int(this, m_pOwner);

        PlayersInBox(rgpPlayers, iPlayersCount, vecAbsMin, vecAbsMax);
        for (i = 0; i < iPlayersCount; i++)
        {
            pPlayer = rgpPlayers[i];

            if (!zp_get_user_zombie(pPlayer))
                continue;

            flLastDamageTime = ArrayGetCell(hDmgTime, pPlayer);

            if (flGameTime - flLastDamageTime < 1.0)
                continue;

            ArraySetCell(hDmgTime, pPlayer, flGameTime);

            entity_get_vector(pPlayer, EV_VEC_origin, vecSrc);

            ExecuteHam(Ham_TakeDamage, pPlayer, this, pOwner, 70.0, DMG_GENERIC | DMG_ALWAYSGIB);
            emit_sound(pPlayer, CHAN_BODY, "debris/beamstart9.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
        }

        if (flGameTime - entity_get_float(this, m_flSparks) >= 1.0)
        {
            engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vecEnd, 0);
            {
                write_byte(TE_SPARKS);
                engfunc(EngFunc_WriteCoord, vecEnd[0]);
                engfunc(EngFunc_WriteCoord, vecEnd[1]);
                engfunc(EngFunc_WriteCoord, vecEnd[2]);
            }
            message_end();

            entity_set_float(this, m_flSparks, flGameTime);
        }
    }
    else
        Tripmine_RelinkTripmine(this);

    entity_set_float(this, EV_FL_nextthink, flGameTime + 0.023);
}

Tripmine_RelinkTripmine(this)
{
    static hTr, pOwner, pBeam, pHit, Float:vecPlaneNormal[3], Float:vecSrc[3], Float:vecEnd[3];

    pOwner = entity_get_int(this, m_pOwner);
    pBeam = entity_get_int(this, m_pBeam);

    GetGunPosition(pOwner, vecSrc);
    GetAimPosition(pOwner, 128, vecEnd);

    hTr = create_tr2();

    engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, pOwner, hTr);

    static iBody, Float:flVecColor[3], Float:flFraction, Float:vecAngles[3], Float:vecVelocity[3];

    get_tr2(hTr, TR_flFraction, flFraction);
    pHit = max(get_tr2(hTr, TR_pHit), 0);

    velocity_by_aim(pOwner, 128, vecVelocity);
    xs_vec_neg(vecVelocity, vecVelocity);
    vector_to_angle(vecVelocity, vecAngles);

    g_bCantPlant[pOwner] = true;
    iBody = 11;
    xs_vec_set(flVecColor, 150.0, 0.0, 0.0);

    if (flFraction < 1.0)
    {
        get_tr2(hTr, TR_vecPlaneNormal, vecPlaneNormal);
        get_tr2(hTr, TR_vecEndPos, vecEnd);

        xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
        xs_vec_add(vecEnd, vecPlaneNormal, vecEnd);
        
        if (!pHit)
        {
            vector_to_angle(vecPlaneNormal, vecAngles);

            g_bCantPlant[pOwner] = false;
            iBody = 15;
            xs_vec_set(flVecColor, 0.0, 150.0, 0.0);
        }
    }

    entity_set_vector(pBeam, EV_VEC_rendercolor, flVecColor);

    entity_set_vector(this, EV_VEC_angles, vecAngles);
    entity_set_int(this, EV_INT_body, iBody);
    entity_set_origin(this, vecEnd);

    free_tr2(hTr);
}

Tripmine_Kill(pOwner)
{
    new pTripmine = -1;
    new bool:bIsConnected = bool:(is_user_connected(pOwner));

    while ((pTripmine = find_ent_by_class(pTripmine, "zp_tripmine")))
    {
        if (entity_get_int(pTripmine, m_pOwner) != pOwner)
            continue;

        if (!bIsConnected) 
            entity_set_int(pTripmine, m_pOwner, pTripmine);

        if (entity_get_int(pTripmine, EV_INT_rendermode) != kRenderTransAdd)
            continue;

        remove_entity(pTripmine);
        break;
    }

    remove_task(pOwner+TASK_SETLASER);
    remove_task(pOwner+TASK_DELLASER);
    remove_task(pOwner+TASK_IDLE);

    if (bIsConnected)
        BarTime(pOwner, 0);
}

Tripmine_Render(this)
{
    new Float:vecColor[3];

    new iPercent = floatround((entity_get_float(this, EV_FL_health) / entity_get_float(this, EV_FL_max_health)) * 100.0); 
    vecColor[0] = float(clamp(255 - iPercent * 3, 0, 255));
    vecColor[1] = float(clamp(3 * iPercent, 0, 255));

    entity_set_int(this, EV_INT_body, 1);
    entity_set_int(this, EV_INT_renderfx, kRenderFxGlowShell);
    entity_set_vector(this, EV_VEC_rendercolor, vecColor);
    entity_set_float(this, EV_FL_renderamt, 25.0);
}

PlayersInBox(rgpPlayers[MAXPLAYERS], &iPlayersCount, const Float:vecMins[3], const Float:vecMaxs[3])
{
    static i, _rgpPlayers[MAXPLAYERS], Float:vecAbsMin[3], Float:vecAbsMax[3], _iPlayersCount, pPlayer;

    _iPlayersCount = 0;

    get_players(_rgpPlayers, _iPlayersCount, "a");

    for (i = 0; i < _iPlayersCount; i++)
    {
        pPlayer = _rgpPlayers[i];

        entity_get_vector(pPlayer, EV_VEC_absmin, vecAbsMin);
        entity_get_vector(pPlayer, EV_VEC_absmax, vecAbsMax);

        if (vecMins[0] > vecAbsMax[0] || vecMins[1] > vecAbsMax[1] || vecMins[2] > vecAbsMax[2] || 
            vecMaxs[0] < vecAbsMin[0] || vecMaxs[1] < vecAbsMin[1] || vecMaxs[2] < vecAbsMin[2])
            continue;

        rgpPlayers[iPlayersCount] = pPlayer;
        iPlayersCount++;
    }
}

Beam_BeamCreate(const szSpriteName[], Float:flWidth)
{
    new pBeam = create_entity("env_beam");

    Beam_BeamInit(pBeam, szSpriteName, flWidth);
    return pBeam;
}

Beam_BeamInit(this, const szSpriteName[], Float:flWidth)
{
    entity_set_int(this, EV_INT_flags, entity_get_int(this, EV_INT_flags) | FL_CUSTOMENTITY);
    entity_set_vector(this, EV_VEC_rendercolor, Float:{255.0, 255.0, 255.0});
    entity_set_float(this, EV_FL_renderamt, 255.0);
    entity_set_int(this, EV_INT_body, 0);
    entity_set_float(this, EV_FL_frame, 0.0);
    entity_set_float(this, EV_FL_animtime, 0.0);
    entity_set_model(this, szSpriteName);
    entity_set_float(this, EV_FL_scale, flWidth);

    entity_set_int(this, EV_INT_skin, 0);
    entity_set_int(this, EV_INT_sequence, 0);
    entity_set_int(this, EV_INT_rendermode, 0);
}

Beam_EntsInit(this, pStartEnt, pEndEnt)
{
    entity_set_int(this, EV_INT_rendermode, (entity_get_int(this, EV_INT_rendermode) & 0xF0) | (BEAM_ENTS & 0x0F));

    entity_set_int(this, EV_INT_sequence, (pStartEnt & 0x0FFF) | ((entity_get_int(this, EV_INT_sequence) & 0xF000) << 12));
    entity_set_edict(this, EV_ENT_owner, pStartEnt);

    entity_set_int(this, EV_INT_skin, (pEndEnt & 0x0FFF) | ((entity_get_int(this, EV_INT_skin) & 0xF000) << 12));
    entity_set_edict(this, EV_ENT_aiment, pEndEnt);

    entity_set_int(this, EV_INT_sequence, (entity_get_int(this, EV_INT_sequence) & 0x0FFF) | ((0 & 0xF) << 12));

    entity_set_int(this, EV_INT_skin, (entity_get_int(this, EV_INT_skin) & 0x0FFF) | ((0 & 0xF) << 12));

    Beam_RelinkBeam(this);
}

Beam_PointEntInit(this, const Float:vecStart[3], pEndEnt)
{
    entity_set_int(this, EV_INT_rendermode, (entity_get_int(this, EV_INT_rendermode) & 0xF0) | (BEAM_ENTPOINT & 0x0F));
    entity_set_vector(this, EV_VEC_origin, vecStart);
    entity_set_int(this, EV_INT_skin, (pEndEnt & 0x0FFF) | ((entity_get_int(this, EV_INT_skin) & 0xF000) << 12));
    entity_set_edict(this, EV_ENT_aiment, pEndEnt);
    entity_set_int(this, EV_INT_sequence, (entity_get_int(this, EV_INT_sequence) & 0x0FFF) | ((0 & 0xF) << 12));
    entity_set_int(this, EV_INT_skin, (entity_get_int(this, EV_INT_skin) & 0x0FFF) | ((0 & 0xF) << 12));

    Beam_RelinkBeam(this);
}

Beam_RelinkBeam(this)
{
    new Float:vecStartPos[3], Float:vecOrigin[3], Float:vecEndPos[3], Float:vecMins[3], Float:vecMaxs[3];

    Beam_GetStartPos(this, vecStartPos);
    Beam_GetEndPos(this, vecEndPos);

    vecMins[0] = floatmin(vecStartPos[0], vecEndPos[0]);
    vecMins[1] = floatmin(vecStartPos[1], vecEndPos[1]);
    vecMins[2] = floatmin(vecStartPos[2], vecEndPos[2]);

    vecMaxs[0] = floatmax(vecStartPos[0], vecEndPos[0]);
    vecMaxs[1] = floatmax(vecStartPos[1], vecEndPos[1]);
    vecMaxs[2] = floatmax(vecStartPos[2], vecEndPos[2]);

    entity_get_vector(this, EV_VEC_origin, vecOrigin);

    xs_vec_sub(vecMins, vecOrigin, vecMins);
    xs_vec_sub(vecMaxs, vecOrigin, vecMaxs);

    entity_set_vector(this, EV_VEC_mins, vecMins);
    entity_set_vector(this, EV_VEC_maxs, vecMaxs);

    entity_set_size(this, vecMins, vecMaxs);
    entity_set_origin(this, vecOrigin);
}

Beam_GetStartPos(this, Float:vecDest[3])
{
    if ((entity_get_int(this, EV_INT_rendermode) & 0x0F) == BEAM_ENTS)
    {
        new pEnt = (entity_get_int(this, EV_INT_sequence) & 0xFFF);
        entity_get_vector(pEnt, EV_VEC_origin, vecDest);
        return;
    }
    
    entity_get_vector(this, EV_VEC_origin, vecDest);
}

Beam_GetEndPos(this, Float:vecDest[3])
{
    new iBeamType = (entity_get_int(this, EV_INT_rendermode) & 0x0F);

    if (iBeamType == BEAM_HOSE || iBeamType == BEAM_POINTS)
    {
        entity_get_vector(this, EV_VEC_angles, vecDest);
        return;
    }

    new pEnt = max((entity_get_int(this, EV_INT_skin) & 0xFFF), 0);

    if (pEnt)
    {
        entity_get_vector(pEnt, EV_VEC_origin, vecDest);
        return;
    }

    entity_get_vector(this, EV_VEC_angles, vecDest);
}

GetAimPosition(this, iDistance, Float:vecDest[3])
{
    static Float:vecVelocity[3], Float:vecSrc[3];

    GetGunPosition(this, vecSrc);

    velocity_by_aim(this, iDistance, vecVelocity);
    xs_vec_add(vecSrc, vecVelocity, vecDest);
}

GetGunPosition(this, Float:vecDest[3])
{
    static Float:vecViewOfs[3], Float:vecSrc[3];

    entity_get_vector(this, EV_VEC_view_ofs, vecViewOfs);
    entity_get_vector(this, EV_VEC_origin, vecSrc);

    xs_vec_add(vecSrc, vecViewOfs, vecDest);
}

BarTime(this, iTime)
{
    message_begin(MSG_ONE, g_iMsgBarTime, .player = this)
    {
        write_short(iTime);
    }
    message_end();
}

MakeAimVectors(const Float:vecAngles[3])
{
    new Float:vecTmpAngles[3];

    xs_vec_set(vecTmpAngles, vecAngles[0], vecAngles[1], vecAngles[2]);
    vecTmpAngles[0] = -vecTmpAngles[0];

    engfunc(EngFunc_MakeVectors, vecTmpAngles);
}

FClassnameIs(this, szClassName[])
{
    new _szClassName[32];

    if (!is_valid_ent(this))
        return 0;

    entity_get_string(this, EV_SZ_classname, _szClassName, charsmax(_szClassName));

    if (equali(szClassName, _szClassName))
        return 1;

    return 0;
}

public showMenuLasermine(id)
{
    new menuid = menu_create("\yLasermine Menu", "menuLasermine");
    menu_additem(menuid, "Buy/place from Extra Items.");

    menu_additem(menuid, "Remove a Lasermine");

    menu_display(id, menuid, 0);
}

public menuLasermine(id, menuid, item)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    if (zp_get_user_zombie(id))
        return PLUGIN_HANDLED;

    switch(item)
    {
        case MENU_EXIT:
        {
            menu_destroy(menuid);
            return PLUGIN_HANDLED;
        }
        case 0:
        {
            if (!g_iTripmine[id])
            {
                client_printcolor(id, "!y[!gZoD *| VIP!y] couldn't buy a !gLasermine!y!");
                showMenuLasermine(id);
                return PLUGIN_HANDLED;
            }

            if (g_iTripmine[id])
            {
                CmdSetLaser(id);
            }

            showMenuLasermine(id);
        }
        case 1:
        {
            CmdDelLaser(id);
            showMenuLasermine(id);
        }
    }

    return PLUGIN_HANDLED;
}

stock print_colored(const index, const input [ ], const any:...) 
{  
    new message[191] 
    vformat(message, 190, input, 3) 
    replace_all(message, 190, "!y", "^1") 
    replace_all(message, 190, "!t", "^3") 
    replace_all(message, 190, "!g", "^4") 

    if(index) 
    { 
        //print to single person 
        message_begin(MSG_ONE, g_iMsgSayTxt, _, index) 
        write_byte(index) 
        write_string(message) 
        message_end() 
    } 
    else 
    { 
        //print to all players 
        new players[32], count, i, id 
        get_players(players, count, "ch") 
        for( i = 0; i < count; i ++ ) 
        { 
            id = players[i] 
            if(!is_user_connected(id)) continue; 

            message_begin(MSG_ONE_UNRELIABLE, g_iMsgSayTxt, _, id) 
            write_byte(id) 
            write_string(message) 
            message_end() 
        } 
    } 
} 

public Tripmine_ShowInfo_Post(Float:flVecStart[3], Float:flVecEnd[3], Conditions, this, Trace)
{
    if (!is_user_connected(this) || !is_user_alive(this))
        return FMRES_IGNORED;

    static iHit;
    iHit = get_tr2(Trace, TR_pHit);

    if (pev_valid(iHit))
    {
        if (pev(iHit, pev_deadflag) == DEAD_NO)
        {
            new szClassName[32], szName[32];
            pev(iHit, pev_classname, szClassName, charsmax(szClassName))

            if (equali(szClassName, "zp_tripmine"))
            {
                static iOwner, iHealth;
                iOwner = pev(iHit, pev_iuser1);
                iHealth = pev(iHit, pev_health);
                get_user_name(iOwner, szName, charsmax(szName));

                set_hudmessage(0, 0, 255, -1.0, 0.60, 0, 6.0, 0.4, 0.0, 0.0, -1);
                show_hudmessage(this, "Owner: %s^nLaser HP :%d", szName, iHealth);
            }
        }
    }

    return FMRES_IGNORED;
}
stock client_printcolor(const id,const input[], any:...)
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1252\\ deff0{\\ fonttbl{\\ f0\\ fnil\\ fcharset0 Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
