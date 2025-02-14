//AMXXPC compile.exe
// by the AMX Mod X Dev Team

// zp50_item_infection_bomb.sma

#include <amxmodx>
#include <fakemeta>
#include <fun>

#define ZP_NO_GAME_MODE         0
#define SOUND_MAX_LENGTH        128
#define NADE_EXPLOSION_RADIUS   300.0

// Declare global variables
new g_sound_grenade_infect_explode[3][SOUND_MAX_LENGTH] = {
    "weapons/explode3.wav",
    "weapons/explode4.wav",
    "weapons/explode5.wav"
};

new g_sound_grenade_infect_player[3][SOUND_MAX_LENGTH] = {
    "infected/virus_infect1.wav",
    "infected/virus_infect2.wav",
    "infected/virus_infect3.wav"
};

// Infection explosion logic
infection_explode(ent)
{
    // Round ended
    if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
    {
        // Get rid of the grenade
        engfunc(EngFunc_RemoveEntity, ent)
        return;
    }
    
    // Get origin
    static Float:origin[3]
    pev(ent, pev_origin, origin)
    
    // Make the explosion
    create_explosion(origin[0], origin[1], origin[2], 5, 200.0, 0); // Explosion effect

    // Infection nade explode sound
    static sound[SOUND_MAX_LENGTH]
    ArrayGetString(g_sound_grenade_infect_explode, random_num(0, ArraySize(g_sound_grenade_infect_explode) - 1), sound, charsmax(sound))
    emit_sound(ent, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
    
    // Get attacker
    new attacker = pev(ent, pev_owner)
    
    // Infection bomb owner disconnected or not zombie anymore?
    if (!is_user_connected(attacker) || !zp_core_is_zombie(attacker))
    {
        // Get rid of the grenade
        engfunc(EngFunc_RemoveEntity, ent)
        return;
    }
    
    // Count humans within the blast radius
    new human_count = 0
    new victim = -1
    
    while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
    {
        // Only count alive humans
        if (!is_user_alive(victim) || zp_core_is_zombie(victim))
            continue;

        // Count the human
        human_count++
    }
    
    // If there are fewer than 3 humans, do not infect anyone
    if (human_count < 3)
    {
        // Get rid of the grenade
        engfunc(EngFunc_RemoveEntity, ent)
        return;
    }

    // Otherwise, proceed with the infection logic
    // Collisions and infecting humans within the blast radius
    victim = -1
    while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, origin, NADE_EXPLOSION_RADIUS)) != 0)
    {
        // Only effect alive humans
        if (!is_user_alive(victim) || zp_core_is_zombie(victim))
            continue;
        
        // Last human is killed
        if (zp_core_get_human_count() == 1)
        {
            ExecuteHamB(Ham_Killed, victim, attacker, 0)
            continue;
        }
        
        // Turn into zombie
        zp_core_infect(victim, attacker)
        
        // Victim's sound
        static sound[SOUND_MAX_LENGTH]
        ArrayGetString(g_sound_grenade_infect_player, random_num(0, ArraySize(g_sound_grenade_infect_player) - 1), sound, charsmax(sound))
        emit_sound(victim, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
    }
    
    // Get rid of the grenade
    engfunc(EngFunc_RemoveEntity, ent)
}

public plugin_init()
{
    register_plugin("Infection Bomb", "1.0", "YourName")
    
    // Register forward
    register_forward(FM_Use, "forward_use")
}

public forward_use(id)
{
    // Check if player is holding the bomb
    if (is_user_alive(id) && is_user_connected(id) && zp_core_is_zombie(id))
    {
        // Create grenade with unique logic for infection
        create_infection_bomb(id)
    }
}

create_infection_bomb(id)
{
    // Custom grenade creation
    new ent = create_entity("weaponbox")
    
    if (ent != -1)
    {
        // Set its position and attributes
        set_pev(ent, pev_origin, pev(id, pev_origin))
        set_pev(ent, pev_owner, id)
        
        // Set up the grenade for triggering the explosion and infection logic
        set_task(1.0, "infection_explode", ent)
    }
}
