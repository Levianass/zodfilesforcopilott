/*================================================================================

    [[ZP] Addon: Display the Current Mode
    Copyright (C) 2009 by meTaLiCroSS, Vińa del Mar, Chile
    
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    
    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    
    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
    
    In addition, as a special exception, the author gives permission to
    link the code of this program with the Half-Life Game Engine ("HL
    Engine") and Modified Game Libraries ("MODs") developed by Valve,
    L.L.C ("Valve"). You must obey the GNU General Public License in all
    respects for all of the code used other than the HL Engine and MODs
    from Valve. If you modify this file, you may extend this exception
    to your version of the file, but you are not obligated to do so. If
    you do not wish to do so, delete this exception statement from your
    version.
    
    ** Credits:
        
    - Exolent[jNr]: Big plugin optimization

=================================================================================*/

#include <amxmodx>
#include <zp50_gamemodes>
#include < fakemeta >
#include < amx_settings_api >
#include <dhudmessage>

#define TASK_UPDATE_STATUS_ICON	100

// Menu Offset
const m_iMenu = 205;

/*================================================================================
 [Customizations]
=================================================================================*/

// Hudmessage tag



new const g_szGameFile[ ] = "zp_gamemodes.ini";


// Arrays
new Array:g_GameModeColourR;
new Array:g_GameModeColourG;
new Array:g_GameModeColourB;


// Integers
new g_iGameModeCurrentColour[ 3 ];
new g_iGameModeColourR = 200;
new g_iGameModeColourG = 0;
new g_iGameModeColourB = 0;


// X Hudmessage Position ( --- )
const Float:HUD_MODE_X = 0.01

// Y Hudmessage Position ( ||| )
const Float:HUD_MODE_Y = 0.48

// Time at which the Hudmessage is displayed. (when user is puted into the Server)
const Float:START_TIME = 1.0

/*================================================================================
 Customization ends here! Yes, that's it. Editing anything beyond
 here is not officially supported. Proceed at your own risk...
=================================================================================*/

// Variables

new g_szGameModeCurrent[ 32 ];



// Cvar pointers
new cvar_enable, cvar_central

public plugin_init() 
{
    // Plugin Info
    register_plugin("[ZP] Addon: Display the Current Mode", "0.1.6", "meTaLiCroSS")
    
    // Round Start Event
    register_event("HLTV", "event_RoundStart", "a", "1=0", "2=0")

    // v2.0 - Updated plugin's functionalities, colour support for each individual game mode (AMX Settings API)
    
    // Enable Cvar
    cvar_enable = register_cvar("zp_display_mode", "1")
    
    // Server Cvar
    register_cvar("zp_addon_dtcm", "v0.1.6 by meTaLiCroSS", FCVAR_SERVER|FCVAR_SPONLY)
    
    
    // Getting "zp_on" cvar
    if(cvar_exists("zp_on"))
        cvar_central = get_cvar_pointer("zp_on")
    
    // If Zombie Plague is not running (bugfix)
    if(!get_pcvar_num(cvar_central))
        pause("a") 
}

public plugin_precache( )
{
	g_GameModeColourR = ArrayCreate( 1, 1 );
	g_GameModeColourG = ArrayCreate( 1, 1 );
	g_GameModeColourB = ArrayCreate( 1, 1 );

	new szGameModeRealName[ 40 ], iGameModeCount = zp_gamemodes_get_count( );

	for( new game_mode_id = 0; game_mode_id <= iGameModeCount; game_mode_id ++ )
	{
		zp_gamemodes_get_name( game_mode_id, szGameModeRealName, charsmax( szGameModeRealName ) );

		if( !amx_load_setting_int( g_szGameFile, szGameModeRealName, "COLOUR RED", g_iGameModeColourR ) )
			amx_save_setting_int( g_szGameFile, szGameModeRealName, "COLOUR RED", g_iGameModeColourR );

		ArrayPushCell( g_GameModeColourR, g_iGameModeColourR );

		if( !amx_load_setting_int( g_szGameFile, szGameModeRealName, "COLOUR GREEN", g_iGameModeColourG ) )
			amx_save_setting_int( g_szGameFile, szGameModeRealName, "COLOUR GREEN", g_iGameModeColourG );

		ArrayPushCell( g_GameModeColourG, g_iGameModeColourG );

		if( !amx_load_setting_int( g_szGameFile, szGameModeRealName, "COLOUR BLUE", g_iGameModeColourB ) )
			amx_save_setting_int( g_szGameFile, szGameModeRealName, "COLOUR BLUE", g_iGameModeColourB );

		ArrayPushCell( g_GameModeColourB, g_iGameModeColourB );
	}
}


public client_putinserver(id)
{
    // Setting Hud
    set_task(START_TIME, "mode_hud", id, _, _, "b")
}

public event_RoundStart()
{
    // Update var (no mode started / in delay)
    
}


public mode_hud(id)
{ 
       
    if (!is_user_connected(id))
    {
    return;
    }
    if (is_player_in_menu(id))
    {
    return;
    }
  
    // If the Cvar isn't enabled
    if(!get_pcvar_num(cvar_enable))
        return;

    if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	return
    
    // Hud Options
    set_dhudmessage( g_iGameModeCurrentColour[ 0 ], g_iGameModeCurrentColour[ 1 ], g_iGameModeCurrentColour[ 2 ], HUD_MODE_X, HUD_MODE_Y, 0, 0.0, 0.0)

    // Now the hud appears
    show_dhudmessage( id, "%s", g_szGameModeCurrent );
}

// This is so we just add/remove icon and texts correctly :D
is_player_in_menu( id )
{
	new old_menu_id, new_menu_id, in_menu = player_menu_info( id, old_menu_id, new_menu_id );

	if( old_menu_id > 0 || new_menu_id > -1 || in_menu )
		return true;

	in_menu = get_pdata_int( id, m_iMenu );

	if( in_menu )
		return true;

	return false;
}


public zp_fw_gamemodes_start( game_mode_id )
{

        //client_print(0, print_chat, "%d",game_mode_id )
	// Get game mode colour
	g_iGameModeCurrentColour[ 0 ] = ArrayGetCell( g_GameModeColourR, game_mode_id );
	g_iGameModeCurrentColour[ 1 ] = ArrayGetCell( g_GameModeColourG, game_mode_id );
	g_iGameModeCurrentColour[ 2 ] = ArrayGetCell( g_GameModeColourB, game_mode_id );
  

	// Define game mode name
	zp_gamemodes_get_name( game_mode_id, g_szGameModeCurrent, charsmax( g_szGameModeCurrent ) );

	// Remove the nasty " Mode" :P
	replace_all( g_szGameModeCurrent, charsmax( g_szGameModeCurrent ), " Mode", "" );

}


/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1034\\ f0\\ fs16 \n\\ par }
*/