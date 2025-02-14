#include <amxmodx> 
#include <amxmisc> 
#include <cstrike>
#include <fakemeta> 
#include <hamsandwich> 
#include <engine>
#include <zp50_colorchat>
#include <zp50_core>
#include <zp50_gamemodes>
#include <zp50_items>
#include <xs> 
#include <fun> 
#include <zombieplague> 
#include <beams>
#include <zp50_grenade_frost>
#include <zp50_class_survivor>
#include <dhudmessage>

// The sizes of models 
#define PALLET_MINS Float:{ -27.260000, -22.280001, -22.290001 } 
#define PALLET_MAXS Float:{  27.340000,  26.629999,  29.020000 } 
// from fakemeta util by VEN 
#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2) 
#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1) 
// this is mine 
#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1) 
#define fm_get_user_noclip(%1) (pev(%1, pev_movetype) == MOVETYPE_NOCLIP) 
#define MAX_PLAYERS 32  // Typically 32 for Counter-Strike 1.6

// cvars 
new remove_nrnd

const OFFSET_CSMENUCODE = 205;

new const SB_CLASSNAME[] = "FakeSandBag"
// num of pallets with bags 
/* Models for pallets with bags .
Are available 2 models, will be set a random of them  */ 
new g_models[][] =
{
    "models/zod_sandbags.mdl"
}

new const BALROG_SOUNDS[][] = { "debris/bustconcrete1.wav", "debris/concrete2.wav" };

new const SANDBAG_DESTROY[][] = { "debris/bustconcrete2.wav" };

new const Float:g_flCoords[] = {-0.10, -0.15, -0.20}
new g_iPos[33]
new stuck[33] 
new g_bolsas[33]; 
new g_MaxSB[33]
new cvar[3] 
new const Float:size[][3] =
{
    {0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.1, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0},
    {0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0},
    {0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0},
    {0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0},
    {0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0}
}
const g_item_bolsas = 30 
new g_itemid_bolsas
new ZPSTUCK 
new SBText[33]
new Sb_owner[33]
new cvar_units, g_iMaxPlayers;
new iSandBagHealth[33]
new iTeamLimit, gAlreadyBought[33];
new g_pSB[33], g_pBeam[33], iSBCanBePlaced[33]
new Float:ivecOrigin[3]
new rock_model[] = "models/rockgibs.mdl"
new rockmodel

/*************************************************************
************************* AMXX PLUGIN *************************
**************************************************************/
public plugin_init()  
{ 
    /* Register the plugin */ 
    
    register_plugin("[ZP] Extra: SandBags", "1.1", "LARP") 
    g_itemid_bolsas = zp_items_register("Sandbags \rBlockade", 30)
    /* Register the cvars */ 
    ZPSTUCK = register_cvar("zp_pb_stuck","1") 
    remove_nrnd = register_cvar("zp_pb_remround","1"); 
    cvar_units = register_cvar("zp_sandbag_units", "42")
    
    g_iMaxPlayers = get_maxplayers();
    
    /* Game Events */ 
    register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 
    
    /* This is for menuz: */ 
    register_clcmd("say /sb1","show_the_menu"); 
    register_clcmd("say_team /sbp","show_the_menu"); 
    register_think(SB_CLASSNAME, "SB_Think");

    // Register Commands
    register_clcmd("say /sb", "showMenuLasermine");
    register_clcmd("say_team /sb", "showMenuLasermine");

    //cvar[0] = register_cvar("zp_autounstuck","1") 
    cvar[1] = register_cvar("zp_pb_stuckeffects","1") 
    cvar[2] = register_cvar("zp_pb_stuckwait","7") 
    RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage"); 
    RegisterHam(Ham_Killed, "func_wall", "fw_PlayerKilled", 1)
    register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
} 

public OnFreeEntPrivateData(this)
{
    if (!FClassnameIs(this, SB_CLASSNAME))
        return FMRES_IGNORED;

    new pOwner = pev(this, pev_owner);

    if ((1 <= pOwner <= g_iMaxPlayers))
    {
        if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
            remove_entity(g_pBeam[pOwner]);

        g_pBeam[pOwner] = 0;
        g_pSB[pOwner] = 0;
    }
    return FMRES_IGNORED;
}

// Global variable to track if the reward has been given for each sandbag
new g_bRewardGiven[MAX_PLAYERS];

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)  
{ 
    // Victim is not a sandbag
    new sz_classname[32]; 
    entity_get_string(victim, EV_SZ_classname, sz_classname, 31);

    // If the attacker is not a zombie, return
    if (equali(sz_classname, "amxx_pallets") && !zp_core_is_zombie(attacker))
        return HAM_IGNORED; 

    // Handle sandbag damage effects
    new Float:origin1[3];
    pev(victim, pev_origin, origin1);

    engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin1, 0);
    write_byte(TE_BREAKMODEL);
    engfunc(EngFunc_WriteCoord, origin1[0]);
    engfunc(EngFunc_WriteCoord, origin1[1]);
    engfunc(EngFunc_WriteCoord, origin1[2]);
    write_coord(10); 
    write_coord(10); 
    write_coord(10); 
    write_coord(5); 
    write_coord(5); 
    write_coord(5);
    write_byte(5); 
    write_short(rockmodel); 
    write_byte(10); 
    write_byte(25);
    write_byte(0x08); 
    message_end();

    emit_sound(attacker, CHAN_WEAPON, BALROG_SOUNDS[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

    // Health check
    new iHealth = pev(victim, pev_health) - floatround(damage);
    if (iHealth <= 0)
    {
        iHealth = 1;
    }

    // Set glow effect based on health
    if (equali(sz_classname, "amxx_pallets") && !zp_core_is_zombie(attacker))
        return HAM_IGNORED; 
    
    if (iHealth < 400) 
    {
        set_rendering(victim, kRenderFxGlowShell, 242, 38, 206, kRenderNormal, 16);
    }
    else if (iHealth < 600) 
    {
        set_rendering(victim, kRenderFxGlowShell, 255, 203, 26, kRenderNormal, 16);
    }

    if (iHealth <= 600) 
    {
        set_rendering(victim, kRenderFxGlowShell, 255 - 255 * iHealth / 600, 255 * iHealth / 600, 0, kRenderNormal, 16);
    }
    else if (iHealth <= 800) 
    {
        set_rendering(victim, kRenderFxGlowShell, 0, 255 - (255 * iHealth - 600) / 200, 255 * (iHealth - 600) / 200, kRenderNormal, 16);
    }

    client_print(attacker, print_center, "Sandbags Health: %d", iHealth);

    return HAM_IGNORED;  // Ensure the function returns a value
}

public fw_PlayerKilled(victim, attacker, shouldgib) 
{      
    new sz_classname[32], name[32], Float: health;  
    entity_get_string(victim, EV_SZ_classname, sz_classname, charsmax(sz_classname)); 

    get_user_name(attacker, name, charsmax(name)); 
    health = entity_get_float(victim, EV_FL_health); 

    // Check if the victim is a sandbag, the attacker is a zombie, and health is 0 (destroyed)
    if (equal(sz_classname, "amxx_pallets") && is_valid_ent(victim) && zp_get_user_zombie(attacker) && health <= 0.0) 
    { 
        // Ensure the reward is given only once per sandbag destruction
        if (!g_bRewardGiven[victim]) 
        {
            zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 5); 
            emit_sound(attacker, CHAN_WEAPON, SANDBAG_DESTROY[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM);

            // Manually format the name without any existing community tag
            new custom_name[64];  // Increase the size of custom_name to ensure it's big enough
            format(custom_name, sizeof(custom_name), "[ZoD *|] %s", name);  // Custom community tag

            // Print the message with the custom community tag
            zp_colored_print(0, "^03%s ^01earned^03 5 points ^01by destroying sandbag!", custom_name); 

            // Mark the reward as given for this sandbag
            g_bRewardGiven[victim] = true;

            new iPos = ++g_iPos[attacker];
            if (iPos == sizeof(g_flCoords))
            {
                iPos = g_iPos[attacker] = 0;
            }

            set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0);
            show_dhudmessage(attacker, "+5 points [Sandbags]");
        }
        return HAM_IGNORED;
    }

    return HAM_IGNORED;
}

public plugin_precache() 
{ 
    for(new i; i < sizeof g_models; i++) 
        engfunc(EngFunc_PrecacheModel, g_models[i]); 

    rockmodel = precache_model(rock_model);

    for (new i = 0; i < sizeof BALROG_SOUNDS; i++)
        engfunc(EngFunc_PrecacheSound, BALROG_SOUNDS[i]);

    for (new i = 0; i < sizeof SANDBAG_DESTROY; i++)
        engfunc(EngFunc_PrecacheSound, SANDBAG_DESTROY[i]);
}

public show_the_menu(id) 
{ 
    if(zp_core_is_zombie(id) || zp_core_is_nemesis(id) || zp_core_is_survivor(id)) 
    { 
        zp_colored_print(id, "^03Zombies can't use this.");
        return PLUGIN_CONTINUE;
    } 

    // Create the menu 
    new menu = menu_create("\y[Sandbags]", "handler_sandbags") 

    // Add items to the menu 
    menu_additem(menu, "\rSandbags", "1", 0); 

    // Display the menu 
    menu_display(id, menu, 0); 
    return PLUGIN_HANDLED; 
} 

public handler_sandbags(id, menu, item) 
{ 
    if(!is_user_alive(id)) 
        return PLUGIN_HANDLED; 

    switch(item) 
    { 
        case 0: 
        { 
            if(g_bolsas[id] > 0) 
            { 
                place_palletwbags(id); 
                g_bolsas[id]--; 
                zp_colored_print(id, "^03[ZoD *|] You have ^04%i ^03sandbags left.", g_bolsas[id]); 
            } 
            else 
            { 
                zp_colored_print(id, "^03You have no sandbags left!"); 
            } 
            break; 
        } 
        case MENU_EXIT:
        { 
            if (g_pSB[id] && is_valid_ent(g_pSB[id]))
                remove_entity(g_pSB[id]);

            if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
                remove_entity(g_pBeam[id]);
        } 
    } 
    return PLUGIN_HANDLED; 
}

public CreateFakeSandBag(id) 
{ 
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);

    new iSB = create_entity("info_target");

    if (!iSB)
        return;

    static Float:vecAngles[3];
    GetOriginAimEndEyes(id, 165, ivecOrigin, vecAngles);
    engfunc(EngFunc_SetModel, iSB, g_models[random(sizeof g_models)]);
    engfunc(EngFunc_SetOrigin, iSB, ivecOrigin);

    set_pev(iSB, pev_classname, SB_CLASSNAME);
    set_pev(iSB, pev_owner, id);
    set_pev(iSB, pev_rendermode, kRenderTransAdd);
    set_pev(iSB, pev_renderamt, 200.0);
    set_pev(iSB, pev_body, 1);
    set_pev(iSB, pev_nextthink, get_gametime());
    set_pev(iSB, pev_movetype, MOVETYPE_PUSHSTEP); // Movestep <- for Preview

    new pBeam = Beam_Create("sprites/laserbeam.spr", 6.0);

    if (pBeam != FM_NULLENT)
    {
        Beam_EntsInit(pBeam, iSB, id);
        Beam_SetColor(pBeam, Float:{150.0, 0.0, 0.0});
        Beam_SetScrollRate(pBeam, 255.0);
        Beam_SetBrightness(pBeam, 200.0);
    }
    else
    {
        pBeam = 0;
    }

    g_pBeam[id] = pBeam;
    g_pSB[id] = iSB;
}

public SB_Think(SandBag)
{
    if (pev_valid(SandBag) != 2)
        return;

    static pOwner;
    pOwner = pev(SandBag, pev_owner);

    if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
        return;

    static iBody, Float:vecColor[3], Float:vecAngles[3];

    GetOriginAimEndEyes(pOwner, 165, ivecOrigin, vecAngles);
    iBody = 2;
    xs_vec_set(vecColor, 155.0, 0.0, 0.0);
    engfunc(EngFunc_SetOrigin, SandBag, ivecOrigin);

    if (!IsHullVacant(ivecOrigin, HULL_HEAD, SandBag))
    {
        if (CheckSandBag() || CheckSandBagFake())
        {
            iBody = 1;
            xs_vec_set(vecColor, 0.0, 155.0, 0.0);
        }
    }

    if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
    {
        Beam_RelinkBeam(g_pBeam[pOwner]);
        Beam_SetColor(g_pBeam[pOwner], vecColor);
    }

    iSBCanBePlaced[pOwner] = iBody;
    set_pev(SandBag, pev_angles, vecAngles);
    set_pev(SandBag, pev_body, iBody);
    set_pev(SandBag, pev_nextthink, get_gametime() + 0.01);

    return;
}

public place_palletwbags(id)
{
    new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall"));

    set_pev(Ent, pev_classname, "amxx_pallets");

    engfunc(EngFunc_SetModel, Ent, g_models[random(sizeof g_models)]);

    static Float:p_mins[3], Float:p_maxs[3], Float:vecOrigin[3], Float:vecAngles[3];
    p_mins = PALLET_MINS;
    p_maxs = PALLET_MAXS;
    engfunc(EngFunc_SetSize, Ent, p_mins, p_maxs);
    set_pev(Ent, pev_mins, p_mins);
    set_pev(Ent, pev_maxs, p_maxs);
    set_pev(Ent, pev_absmin, p_mins);
    set_pev(Ent, pev_absmax, p_maxs);
    set_pev(Ent, pev_body, 3);
    GetOriginAimEndEyes(id, 165, vecOrigin, vecAngles);
    engfunc(EngFunc_SetOrigin, Ent, vecOrigin);

    set_pev(Ent, pev_solid, SOLID_BBOX); // touch on edge, block

    set_rendering(Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16);

    set_pev(Ent, pev_movetype, MOVETYPE_FLY); // no gravity, but still collides with stuff

    new Float:p_cvar_health = float(iSandBagHealth[id]);
    set_pev(Ent, pev_health, p_cvar_health);
    set_pev(Ent, pev_takedamage, DAMAGE_YES);

    static Float:rvec[3];
    pev(id, pev_v_angle, rvec);

    rvec[0] = 0.0;

    set_pev(Ent, pev_angles, rvec);

    set_pev(Ent, pev_owner, id);
    set_pev(Ent, pev_iuser1, id);
    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);

    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    new player_name[34];
    get_user_name(id, player_name, charsmax(player_name));
    zp_colored_print(id, "^03[ZoD *|] %s ^03has placed a sandbag!", player_name);
}

stock get_user_hitpoint(id, Float:hOrigin[3])
{
    if (!is_user_alive(id))
        return 0;

    new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3];
    new Float:fTemp[3];

    pev(id, pev_origin, fOrigin);
    pev(id, pev_v_angle, fvAngle);
    pev(id, pev_view_ofs, fvOffset);

    xs_vec_add(fOrigin, fvOffset, fvOrigin);

    engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp);

    xs_vec_mul_scalar(feOrigin, 9999.9, feOrigin);
    xs_vec_add(fvOrigin, feOrigin, feOrigin);

    engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id);
    global_get(glb_trace_endpos, hOrigin);

    return 1;
}

public event_newround()
{
    iTeamLimit = 0;
    for (new id; id <= get_maxplayers(); id++)
    {
        if (get_pcvar_num(remove_nrnd) == 1)
            remove_allpalletswbags();
        g_bolsas[id] = 0;
        g_MaxSB[id] = 0;
        Sb_owner[id] = 0;
        gAlreadyBought[id] = 0;

        if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
            remove_entity(g_pBeam[id]);
        if (g_pSB[id] && is_valid_ent(g_pSB[id]))
            remove_entity(g_pSB[id]);
    }
}

stock remove_allpalletswbags()
{
    new pallets = -1;
    while ((pallets = fm_find_ent_by_class(pallets, "amxx_pallets")))
        fm_remove_entity(pallets);
}

public checkstuck()
{
    if (get_pcvar_num(ZPSTUCK) == 1)
    {
        static players[32], pnum, player;
        get_players(players, pnum);
        static Float:origin[3];
        static Float:mins[3], hull;
        static Float:vec[3];
        static o, i;
        for (i = 0; i < pnum; i++)
        {
            player = players[i];
            if (is_user_connected(player) && is_user_alive(player))
            {
                pev(player, pev_origin, origin);
                hull = pev(player, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN;
                if (!is_hull_vacant(origin, hull, player) && !fm_get_user_noclip(player) && !(pev(player, pev_solid) & SOLID_NOT))
                {
                    ++stuck[player];
                    if (stuck[player] >= get_pcvar_num(cvar[2]))
                    {
                        pev(player, pev_mins, mins);
                        vec[2] = origin[2];
                        for (o = 0; o < sizeof size; ++o)
                        {
                            vec[0] = origin[0] - mins[0] * size[o][0];
                            vec[1] = origin[1] - mins[1] * size[o][1];
                            vec[2] = origin[2] - mins[2] * size[o][2];
                            if (is_hull_vacant(vec, hull, player))
                            {
                                engfunc(EngFunc_SetOrigin, player, vec);
                                effects(player);
                                set_pev(player, pev_velocity, {0.0, 0.0, 0.0});
                                o = sizeof size;
                            }
                        }
                    }
                }
                else
                {
                    stuck[player] = 0;
                }
            }
        }
    }
}

stock bool:is_hull_vacant(const Float:origin[3], hull, id)
{
    static tr;
    engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr);
    if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen))
        return true;

    return false;
}

public effects(id)
{
    if (get_pcvar_num(cvar[1]))
    {
        set_hudmessage(255, 150, 50, -1.0, 0.65, 0, 6.0, 1.5, 0.1, 0.7); // HUDMESSAGE
        show_hudmessage(id, "Automatic Unstuck!"); // HUDMESSAGE
        message_begin(MSG_ONE_UNRELIABLE, 105, {0, 0, 0}, id);
        write_short(1 << 10);   // fade lasts this long duration
        write_short(1 << 10);   // fade lasts this long hold time
        write_short(1 << 1);   // fade type (in / out)
        write_byte(20);            // fade red
        write_byte(255);    // fade green
        write_byte(255);        // fade blue
        write_byte(255);    // fade alpha
        message_end();
        client_cmd(id, "spk fvox/blip.wav");
    }
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    // This is not our item
    if (itemid != g_itemid_bolsas)
        return ZP_ITEM_AVAILABLE;

    // Antidote only available to zombies
    if (zp_core_is_zombie(id))
        return ZP_ITEM_DONT_SHOW;

    //Antidote only available during infection modes

    // Display remaining item count for this round
    static text[32];
    formatex(text, charsmax(text), "[%d/1]", g_MaxSB[id]);
    zp_items_menu_text_add(text);

    // Reached antidote limit for this round
    if (g_MaxSB[id] >= 1)
        return ZP_ITEM_NOT_AVAILABLE;
    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid)
{
    // This is not our item
    if (itemid != g_itemid_bolsas)
        return;
    g_bolsas[id] += 2;
    gAlreadyBought[id] = 1;
    iTeamLimit++;
    set_task(0.3, "show_the_menu", id);
    zp_colored_print(id, "^x03[ZoD *|] You have ^x04%i ^x03sandbags, to use type 'say ^x04/sb1'", g_bolsas[id]);
    Sb_owner[id] = 2;
    g_MaxSB[id] += 1;
    iSandBagHealth[id] = 650;
}

public client_disconnected(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);
}

public zp_fw_core_infect(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);
}

public zp_fw_core_cure(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);

    new ent = -1;
    while ((ent = find_ent_by_class(ent, "amxx_pallets")))
    {
        new pOwner = pev(ent, pev_iuser1);
        if (id == pOwner)
        {
            set_pev(ent, pev_owner, pOwner);
        }
    }
}

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
    engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
    return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}

GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
    static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
    static Float:flFraction;

    pev(this, pev_origin, vecSrc);
    pev(this, pev_view_ofs, vecViewOfs);

    xs_vec_add(vecSrc, vecViewOfs, vecSrc);
    velocity_by_aim(this, iDistance, vecVelocity);
    xs_vec_add(vecSrc, vecVelocity, vecEnd);

    engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);

    get_tr2(0, TR_flFraction, flFraction);

    if (flFraction < 1.0)
    {
        static Float:vecPlaneNormal[3];

        get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
        get_tr2(0, TR_vecEndPos, vecOut);

        xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
        xs_vec_add(vecOut, vecPlaneNormal, vecOut);
    }
    else
    {
        xs_vec_copy(vecEnd, vecOut);
    }

    vecVelocity[2] = 0.0;
    vector_to_angle(vecVelocity, vecAngles);
}

public CheckSandBag()
{
    static victim;
    victim = -1;
    while ((victim = find_ent_in_sphere(victim, ivecOrigin, get_pcvar_float(cvar_units))) != 0)
    {
        new sz_classname[32];
        entity_get_string(victim, EV_SZ_classname, sz_classname, 31);
        if (!equali(sz_classname, "amxx_pallets"))
        {
            //our dude has sandbags and wants to place them near to him
            if (is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
                return false;
        }
    }
    return true;
}

public CheckSandBagFake()
{
    static victim;
    victim = -1;
    while ((victim = find_ent_in_sphere(victim, ivecOrigin, get_pcvar_float(cvar_units))) != 0)
    {
        new sz_classname[32];
        entity_get_string(victim, EV_SZ_classname, sz_classname, 31);
        if (!equali(sz_classname, "FakeSandBag"))
        {
            //our dude has sandbags and wants to place them near to him
            if (is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
                return false;
        }
    }
    return true;
}

public showMenuLasermine(id)
{
    if (zp_core_is_zombie(id))
        return;
    new menuid = menu_create("\y[Sandbags Menu]", "menuLasermine");
    menu_additem(menuid, "Buy/place from Extra Items.");

    menu_setprop(menuid, MPROP_EXITNAME, "Exit^n\yZombiesOnDrugs");
    menu_display(id, menuid, 0);
}

public menuLasermine(id, menuid, item)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    if (zp_core_is_zombie(id))
        return PLUGIN_HANDLED;

    switch (item)
    {
        case MENU_EXIT:
        {
            menu_destroy(menuid);
            return PLUGIN_HANDLED;
        }
        case 0:
        {
            if (!g_bolsas[id])
            {
                if (!zp_items_force_buy(id, g_itemid_bolsas))
                {
                    zp_colored_print(id, "Couldn't buy a^x04 Sandbags^x01!");
                }
                else
                {
                    showMenuLasermine(id);
                }
                return PLUGIN_HANDLED;
            }

            if (g_bolsas[id])
            {

            }

            showMenuLasermine(id);
        }
        case 1:
        {
            showMenuLasermine(id);
        }
    }

    return PLUGIN_HANDLED;
}

FClassnameIs(this, const szClassName[])
{
    if (pev_valid(this) != 2)
        return 0;

    new szpClassName[32];
    pev(this, pev_classname, szpClassName, charsmax(szpClassName));

    return equal(szClassName, szpClassName);
}

public Task_CheckAiming(iTaskIndex)
{
    static iClient;
    iClient = iTaskIndex - 3389;

    if (is_user_alive(iClient))
    {
        static iEntity, iDummy, cClassname[32];
        get_user_aiming(iClient, iEntity, iDummy, 9999);

        if (pev_valid(iEntity))
        {
            pev(iEntity, pev_classname, cClassname, 31);

            if (equal(cClassname, "amxx_pallets"))
            {
                new name[32];
                new aim = pev(iEntity, pev_iuser1);
                get_user_name(aim, name, charsmax(name) - 1);
            }
        }
    }
}

public client_putinserver(id)
{
    set_task(1.0, "Task_CheckAiming", id + 3389, _, _, "b");
    return PLUGIN_CONTINUE;
}

public zp_fw_core_infect(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);
}

public zp_fw_core_cure(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);

    new ent = -1;
    while ((ent = find_ent_by_class(ent, "amxx_pallets")))
    {
        new pOwner = pev(ent, pev_iuser1);
        if (id == pOwner)
        {
            set_pev(ent, pev_owner, pOwner);
        }
    }
}

public client_disconnected(id)
{
    if (g_pSB[id] && is_valid_ent(g_pSB[id]))
        remove_entity(g_pSB[id]);

    if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
        remove_entity(g_pBeam[id]);
}

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
    engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
    return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}

GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
    static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
    static Float:flFraction;

    pev(this, pev_origin, vecSrc);
    pev(this, pev_view_ofs, vecViewOfs);

    xs_vec_add(vecSrc, vecViewOfs, vecSrc);
    velocity_by_aim(this, iDistance, vecVelocity);
    xs_vec_add(vecSrc, vecVelocity, vecEnd);

    engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);

    get_tr2(0, TR_flFraction, flFraction);

    if (flFraction < 1.0)
    {
        static Float:vecPlaneNormal[3];

        get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
        get_tr2(0, TR_vecEndPos, vecOut);

        xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
        xs_vec_add(vecOut, vecPlaneNormal, vecOut);
    }
    else
    {
        xs_vec_copy(vecEnd, vecOut);
    }

    vecVelocity[2] = 0.0;
    vector_to_angle(vecVelocity, vecAngles);
}

public CheckSandBag()
{
    static victim;
    victim = -1;
    while ((victim = find_ent_in_sphere(victim, ivecOrigin, get_pcvar_float(cvar_units))) != 0)
    {
        new sz_classname[32];
        entity_get_string(victim, EV_SZ_classname, sz_classname, 31);
        if (!equali(sz_classname, "amxx_pallets"))
        {
            //our dude has sandbags and wants to place them near to him
            if (is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
                return false;
        }
    }
    return true;
}

public CheckSandBagFake()
{
    static victim;
    victim = -1;
    while ((victim = find_ent_in_sphere(victim, ivecOrigin, get_pcvar_float(cvar_units))) != 0)
    {
        new sz_classname[32];
        entity_get_string(victim, EV_SZ_classname, sz_classname, 31);
        if (!equali(sz_classname, "FakeSandBag"))
        {
            //our dude has sandbags and wants to place them near to him
            if (is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
                return false;
        }
    }
    return true;
}

public showMenuLasermine(id)
{
    if (zp_core_is_zombie(id))
        return;
    new menuid = menu_create("\y[Sandbags Menu]", "menuLasermine");
    menu_additem(menuid, "Buy/place from Extra Items.");

    menu_setprop(menuid, MPROP_EXITNAME, "Exit^n\yZombiesOnDrugs");
    menu_display(id, menuid, 0);
}

public menuLasermine(id, menuid, item)
{
    if (!is_user_alive(id))
        return PLUGIN_HANDLED;

    if (zp_core_is_zombie(id))
        return PLUGIN_HANDLED;

    switch (item)
    {
        case MENU_EXIT:
        {
            menu_destroy(menuid);
            return PLUGIN_HANDLED;
        }
        case 0:
        {
            if (!g_bolsas[id])
            {
                if (!zp_items_force_buy(id, g_itemid_bolsas))
                {
                    zp_colored_print(id, "Couldn't buy a^x04 Sandbags^x01!");
                }
                else
                {
                    showMenuLasermine(id);
                }
                return PLUGIN_HANDLED;
            }

            if (g_bolsas[id])
            {

            }

            showMenuLasermine(id);
        }
        case 1:
        {
            showMenuLasermine(id);
        }
    }

    return PLUGIN_HANDLED;
}

FClassnameIs(this, const szClassName[])
{
    if (pev_valid(this) != 2)
        return 0;

    new szpClassName[32];
    pev(this, pev_classname, szpClassName, charsmax(szpClassName));

    return equal(szClassName, szpClassName);
}

public Task_CheckAiming(iTaskIndex)
{
    static iClient;
    iClient = iTaskIndex - 3389;

    if (is_user_alive(iClient))
    {
        static iEntity, iDummy, cClassname[32];
        get_user_aiming(iClient, iEntity, iDummy, 9999);

        if (pev_valid(iEntity))
        {
            pev(iEntity, pev_classname, cClassname, 31);

            if (equal(cClassname, "amxx_pallets"))
            {
                new name[32];
                new aim = pev(iEntity, pev_iuser1);
                get_user_name(aim, name, charsmax(name) - 1);
            }
        }
    }
}

public client_putinserver(id)
{
    set_task(1.0, "Task_CheckAiming", id + 3389, _, _, "b");
    return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
