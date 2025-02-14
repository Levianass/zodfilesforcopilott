/**
 *
 * Anti DoubleDuck (DoubleDuck Blocker)
 *  by Numb
 *
 *
 * Description:
 *  Permanently blocks player ability to doubleduck.
 *
 *
 * Requires:
 *  AMX Mod 2010.1 or greater
 *  VexdUM module enabled
 *
 *
 * Additional Info:
 *  + Tested in Counter-Strike 1.6 with amxmod 2010.1, but should work with all Half-Life mods and some greater amx versions.
 *
 *
 * Notes:
 *  + I'm begging Valve to not use any ideas of this plugin for future updates of CS/CZ.
 *  + If your game mod is not Counter-Strike / Condition-Zero, you should take a look on plugins config.
 *
 *
 * ChangeLog:
 *
 *  + 1.8
 *  - Changed: Bool improvement (less usage of RAM).
 *
 *  + 1.7
 *  - Changed: Client-side doubleduck block uses almost twice less CPU power.
 *
 *  + 1.6
 *  - Fixed: There was one frame delay during what player was fully ducked while trying to doubleduck.
 *  - Changed: Plugin uses a bit less resources.
 *
 *  + 1.5
 *  - Added: Config in source code to disable client-side doubleduck block (when disabled uses less resources).
 *  - Changed: Plugin uses a bit less resources.
 *
 *  + 1.4
 *  - Fixed: Client-side bug moving up. (Suggesting to use sv_stepsize 17 instead of standard 18, but there aren't much blocks where you are going up more than 16 units.)
 *
 *  + 1.3
 *  - Fixed: If user is lagy and in a run - client-side doubleduck block isn't working properly.
 *  - Fixed: If user just landed and doubleducked client-side doubleduck block isn't working all the time (depends from ping).
 *  - Fixed: Client-side doubleduck block not working properly in random map areas.
 *  - Fixed: If user just unducked and made a doubleduck - client-side doubleduck block isn't working all the time (depends from ping).
 *
 *  + 1.2
 *  - Added: Client-side doubleduck block.
 *
 *  + 1.1
 *  - Changed: Made 1-based array (lower CPU usage).
 *  - Changed: Modified check when user is pre-doubleducking - now uses only 1 variable (lower cpu usage).
 *
 *  + 1.0
 *  - First release.
 *
 *
 */

// ========================================================================= CONFIG START =========================================================================

// Comment this line if you need more CPU or you don't want to block client-side doubleduck.
//#define BLOCK_CLIENT_SIDE_DD_VIEW // default: enabled (uncommented)

#if defined BLOCK_CLIENT_SIDE_DD_VIEW // this is only a notification (but a needed one) - do not change/remove it.
// Please write any world-view gun model what is automatically downloaded by the engine.
new const ENTITY_MDL[] = "models/w_awp.mdl" // default: ("models/w_awp.mdl") (for use in cs/cz)

// Class-Name of anti-doubleduck entity.
new const ENTITY_NAME[] = "anti_doubleducker" // default: ("anti_doubleducker")
#endif

// ========================================================================== CONFIG END ==========================================================================

#include <amxmod>
#include <VexdUM>

#if defined BLOCK_CLIENT_SIDE_DD_VIEW
new g_iFakeEnt
#endif
new g_bIsUserDead

public plugin_init() {
  register_plugin("Anti DoubleDuck", "1.8", "Numb")

  register_event("ResetHUD", "Event_ResetHUD", "be")
  register_event("Health", "Event_Health", "bd", "1=0")

#if defined BLOCK_CLIENT_SIDE_DD_VIEW
  if((g_iFakeEnt = create_entity("info_target")) > 0) { // if anti-doubleduck entity created successfully:
    entity_set_string(g_iFakeEnt, EV_SZ_classname, ENTITY_NAME) // lets register entity as non-standard
    entity_set_int(g_iFakeEnt, EV_INT_solid, SOLID_NOT) // why it should be solid to the server engine?
    entity_set_int(g_iFakeEnt, EV_INT_movetype, MOVETYPE_NONE) // lets make it unmovable
    entity_set_int(g_iFakeEnt, EV_INT_rendermode, kRenderTransAlpha) // we are starting to render it in invisible mode
    entity_set_float(g_iFakeEnt, EV_FL_renderamt, 0.0) // setting visibility level to zero (invinsible)

    entity_set_model(g_iFakeEnt, ENTITY_MDL) // we are setting model so client-side trace scan cold detect the entity
    entity_set_size(g_iFakeEnt, Float:{-16.0, -16.0, 53.0}, Float:{16.0, 16.0, 54.0}) // plugin will use less power if we wont change entity size at each FM_AddToFullPack
  }
#endif
}

public client_connect(id)
  g_bIsUserDead |= (1<<(id&31))

public Event_ResetHUD(id)
  g_bIsUserDead &= ~(1<<(id&31))

public Event_Health(id)
  g_bIsUserDead |= (1<<(id&31))

public client_prethink(id) {
  if(g_bIsUserDead & (1<<(id&31)))
    return PLUGIN_CONTINUE

  if(get_user_oldbutton(id)&IN_DUCK && !(get_user_button(id)&IN_DUCK)) { // if user unpressed duck key
    static s_iFlags
    s_iFlags = entity_get_int(id, EV_INT_flags)
    if(!(s_iFlags&FL_DUCKING) && entity_get_int(id, EV_INT_bInDuck)) { // if user wasn't fully ducked and is in ducking process
      entity_set_int(id, EV_INT_bInDuck, false) // set user not in ducking process
      entity_set_int(id, EV_INT_flags, (s_iFlags|FL_DUCKING)) // set user fully fucked
      entity_set_size(id, Float:{-16.0, -16.0, -25.0}, Float:{16.0, 16.0, 25.0}) // set user size as fully ducked (won't take one frame delay)
    }
  }
  return PLUGIN_CONTINUE
}

#if defined BLOCK_CLIENT_SIDE_DD_VIEW
public addtofullpack(es, e, iEnt, id, hostflags, player, pSet) {
  if(iEnt == g_iFakeEnt) {
    if(g_bIsUserDead & (1<<(id&31))) // we are just blocking the function if user is dead cause why on earth we need it in this case (plus saves a bit of inet speed)
      return PLUGIN_HANDLED // also I would block it if user is on ladder or in water, but it's unneeded CPU usage cause this two cases are rare

    static Float:s_fFallSpeed
    s_fFallSpeed = entity_get_float(id, EV_FL_flFallVelocity)
    if(s_fFallSpeed >= 0.0) { // vertical speed is always 0.0 if user is on ground, so we aren't checking FL_ONGROUND existence. Plus we need a check is user falling down
      static Float:s_fOrigin[3]
      entity_get_vector(id, EV_VEC_origin, s_fOrigin) // lets get player origin

      if(entity_get_int(id, EV_INT_flags)&FL_DUCKING) // this part teleports anti-doubleduck entity 17 units above player head
        s_fOrigin[2] += s_fFallSpeed ? 2.0 : 18.0 // or right on players head if he is falling down to avoid instant double-duck after landing
      else // and yes - if player is ducked we must teleport it a bit higher comparing to player center
        s_fOrigin[2] -= s_fFallSpeed ? 16.0 : 0.0

      //set_es(iEsHandle, ES_Origin, s_fOrigin) // don't care asking me why this doesn't work in certain areas - I really dunno. if it did - CPU would be much better...
      entity_set_origin(iEnt, s_fOrigin) // cause ES_Origin doesn't work I use this one (the one what takes all of this power)

      forward_return(FMV_CELL, dllfunc(DLLFunc_AddToFullPack, es, e, iEnt, id, hostflags, player, pSet))
      // cause ES_Origin doesn't work I forward my own function and block original one to
      // save CPU by not hooking it twice like I did in 1.6 and older versions of plugin

      set_es(es, ES_Solid, SOLID_BBOX) // now we are making anti-doubleduck entity solid to the client engine
    }
    return PLUGIN_HANDLED // now we block original AddToFullPack cause or we already forwarded our own one or to save and server 
    // and client CPU and internet power cause we don't need this entity to be sent to client this frame
  }
  return PLUGIN_CONTINUE
}
#endif
