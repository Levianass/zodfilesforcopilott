/*================================================================================
    
    ---------------------------------
    -*- [ZP] Item: Zombie Madness -*-
    ---------------------------------
    
    This plugin is part of Zombie Plague Mod and is distributed under the
    terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
    
================================================================================*/

#define ITEM_NAME "Zombie Madness"
#define ITEM_COST 15

#include <amxmodx>
#include <cstrike>
#include <fun>
#include <hamsandwich>
#include <amx_settings_api>
#include <cs_ham_bots_api>
#include <zp50_items>
#define LIBRARY_GRENADE_FROST "zp50_grenade_frost"
#include <zp50_grenade_frost>
#define LIBRARY_GRENADE_FIRE "zp50_grenade_fire"
#include <zp50_grenade_fire>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>

// Settings file
new const ZP_SETTINGS_FILE[] = "zombieplague.ini"

// Default sounds
new const sound_zombie_madness[][] = { "zombie_plague/zombie_madness1.wav" }

#define SOUND_MAX_LENGTH 64

new Array:g_sound_zombie_madness

#define TASK_MADNESS 100
#define ID_MADNESS (taskid - TASK_MADNESS)

#define flag_get(%1,%2) (%1 & (1 << (%2 & 31)))
#define flag_get_boolean(%1,%2) (flag_get(%1,%2) ? true : false)
#define flag_set(%1,%2) %1 |= (1 << (%2 & 31))
#define flag_unset(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_ItemID
new g_MadnessBlockDamage

new cvar_zombie_madness_time

public plugin_init()
{
    register_plugin("[ZP] Item: Zombie Madness", ZP_VERSION_STRING, "ZP Dev Team")
    
    RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
    RegisterHamBots(Ham_Spawn, "fw_PlayerSpawn_Post", 1)
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
    RegisterHamBots(Ham_TraceAttack, "fw_TraceAttack")
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
    RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage")
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
    RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
    
    cvar_zombie_madness_time = register_cvar("zp_zombie_madness_time", "5.0")
    
    g_ItemID = zp_items_register(ITEM_NAME, ITEM_COST)
}

public plugin_precache()
{
    // Initialize arrays
    g_sound_zombie_madness = ArrayCreate(SOUND_MAX_LENGTH, 1)
    
    // Load from external file
    amx_load_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MADNESS", g_sound_zombie_madness)
    
    // If we couldn't load custom sounds from file, use and save default ones
    new index
    if (ArraySize(g_sound_zombie_madness) == 0)
    {
        for (index = 0; index < sizeof sound_zombie_madness; index++)
            ArrayPushString(g_sound_zombie_madness, sound_zombie_madness[index])
        
        // Save to external file
        amx_save_setting_string_arr(ZP_SETTINGS_FILE, "Sounds", "ZOMBIE MADNESS", g_sound_zombie_madness)
    }
    
    // Precache sounds
    new sound[SOUND_MAX_LENGTH]
    for (index = 0; index < ArraySize(g_sound_zombie_madness); index++)
    {
        ArrayGetString(g_sound_zombie_madness, index, sound, charsmax(sound))
        precache_sound(sound)
    }
}

public plugin_natives()
{
    register_library("zp50_item_zombie_madness")
    register_native("zp_item_zombie_madness_get", "native_item_zombie_madness_get")
    
    set_module_filter("module_filter")
    set_native_filter("native_filter")
}
public module_filter(const module[])
{
    if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_GRENADE_FROST) || equal(module, LIBRARY_GRENADE_FIRE))
        return PLUGIN_HANDLED;
    
    return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
    if (!trap)
        return PLUGIN_HANDLED;
        
    return PLUGIN_CONTINUE;
}

public native_item_zombie_madness_get(plugin_id, num_params)
{
    new id = get_param(1)
    
    if (!is_user_alive(id))
    {
        log_error(AMX_ERR_NATIVE, "[ZP] Invalid Player (%d)", id)
        return false;
    }
    
    return flag_get_boolean(g_MadnessBlockDamage, id);
}

public zp_fw_items_select_pre(id, itemid, ignorecost)
{
    // This is not our item
    if (itemid != g_ItemID)
        return ZP_ITEM_AVAILABLE;
    
    // Zombie madness only available to zombies
    if (!zp_core_is_zombie(id))
        return ZP_ITEM_DONT_SHOW;
    
    // Zombie madness not available to Nemesis
    if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(id))
        return ZP_ITEM_DONT_SHOW;
    
    // Player already has madness
    if (flag_get(g_MadnessBlockDamage, id))
        return ZP_ITEM_NOT_AVAILABLE;
    
    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, itemid, ignorecost)
{
    // This is not our item
    if (itemid != g_ItemID)
        return;
    
    // Do not take damage
    flag_set(g_MadnessBlockDamage, id)
    
    // Madness aura
    set_user_rendering(id, kRenderFxGlowShell,255 ,0 ,0 ,kRenderNormal,25)
    
    // Set time
    set_task(5.0, "remove_glow", id)
    
    // Madness sound
    new sound[SOUND_MAX_LENGTH]
    ArrayGetString(g_sound_zombie_madness, random_num(0, ArraySize(g_sound_zombie_madness) - 1), sound, charsmax(sound))
    emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
    
    // Set task to remove it
    set_task(get_pcvar_float(cvar_zombie_madness_time), "remove_zombie_madness", id+TASK_MADNESS)
}


// Ham Player Spawn Post Forward
public fw_PlayerSpawn_Post(id)
{
    // Not alive or didn't join a team yet
    if (!is_user_alive(id) || !cs_get_user_team(id))
        return;
    
    // Remove zombie madness from a previous round
    remove_task(id+TASK_MADNESS)
    set_user_rendering(id)
    flag_unset(g_MadnessBlockDamage, id)
}

// Ham Trace Attack Forward
public fw_TraceAttack(victim, attacker)
{
    // Non-player damage or self damage
    if (victim == attacker || !is_user_alive(attacker))
        return HAM_IGNORED;
    
    // Prevent attacks when victim has zombie madness
    if (flag_get(g_MadnessBlockDamage, victim))
        return HAM_SUPERCEDE;
    
    return HAM_IGNORED;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public fw_TakeDamage(victim, inflictor, attacker)
{
    // Non-player damage or self damage
    if (victim == attacker || !is_user_alive(attacker))
        return HAM_IGNORED;
    
    // Prevent attacks when victim has zombie madness
    if (flag_get(g_MadnessBlockDamage, victim))
        return HAM_SUPERCEDE;
    
    return HAM_IGNORED;
}

public zp_fw_grenade_frost_pre(id)
{
    // Prevent burning when victim has zombie madness
    if (flag_get(g_MadnessBlockDamage, id))
    {
        zp_grenade_frost_set(id, false) 
        return PLUGIN_HANDLED;
    }    
    return PLUGIN_CONTINUE;
}

public zp_fw_grenade_fire_pre(id)
{
    // Prevent burning when victim has zombie madness
    if (flag_get(g_MadnessBlockDamage, id))
    {
        zp_grenade_fire_set(id, false) 
        return PLUGIN_HANDLED;
    }    
    return PLUGIN_CONTINUE;
}
public zp_fw_core_cure(id, attacker)
{
    // Remove zombie madness task
    remove_task(id+TASK_MADNESS)
    set_user_rendering(id)
    flag_unset(g_MadnessBlockDamage, id)
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
    // Remove zombie madness task
    remove_task(victim+TASK_MADNESS)
    set_user_rendering(victim)
    flag_unset(g_MadnessBlockDamage, victim)
}

// Remove Spawn Protection Task
public remove_zombie_madness(taskid)
{    
    // Remove zombie madness
    flag_unset(g_MadnessBlockDamage, ID_MADNESS)
}

public client_disconnect(id)
{
    // Remove tasks on disconnect
    remove_task(id+TASK_MADNESS)
    set_user_rendering(id)
    flag_unset(g_MadnessBlockDamage, id)
}

// Madness glow
public madness_glow(id)
{
    set_user_rendering(id,kRenderFxGlowShell,255 ,0 ,0 ,kRenderNormal,25)
    set_task(5.0, "remove_glow", id)
} 

public remove_glow(id)
{
    // Remove Glow
    set_user_rendering(id)
}  