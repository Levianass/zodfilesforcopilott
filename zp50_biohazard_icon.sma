#include <amxmodx>
#include <fakemeta>
#include <zp50_gamemodes>

#define PLUGIN "Biohazard Icon"
#define VERSION "1.0"
#define AUTHOR "Zombie Lurker - wicho + wicho - wicho"

// Menu Offset
const m_iMenu = 205;

new iconstatus

new g_GameModeSurvivorID, g_GameModeNemesisID, g_GameModeMultiID, g_GameModeSwarmID, g_GameModePlagueID, g_GameModeArmageddonID, g_GameModeSniperID, g_GameModesvnID, g_GameModeKniferID, g_GameModeNightCrawlerID, g_GameModePlasmaID, g_GameModeCannibalsID, g_GameModeZombietagID, g_GameModeWinosID, g_GameModeDioneID, g_GameModeHotPotatoID, g_GameModePredatorID, g_GameModeDragonID

public plugin_init() 
{
    register_plugin(PLUGIN, VERSION, AUTHOR)
    
    register_forward(FM_PlayerPreThink,"fw_prethink");
    iconstatus = get_user_msgid("StatusIcon")
}

public plugin_cfg()
{
    g_GameModeNemesisID = zp_gamemodes_get_id("Nemesis Mode")
    g_GameModeSurvivorID = zp_gamemodes_get_id("Survivor Mode")
    g_GameModePredatorID = zp_gamemodes_get_id("Predators Mode")
    g_GameModeMultiID    = zp_gamemodes_get_id("Multi Infection Mode")
    g_GameModeSwarmID = zp_gamemodes_get_id("Swarm Mode")
    g_GameModeKniferID = zp_gamemodes_get_id("Knifer Mode")
    g_GameModeNightCrawlerID = zp_gamemodes_get_id("NightCrawler Mode")
    g_GameModePlasmaID = zp_gamemodes_get_id("Plasma Mode")
    g_GameModePlagueID = zp_gamemodes_get_id("Plague Mode")
    g_GameModeCannibalsID = zp_gamemodes_get_id("Cannibals Mode")
    g_GameModeArmageddonID = zp_gamemodes_get_id("Armageddon Mode")
    g_GameModesvnID = zp_gamemodes_get_id("Sniper vs Nemesis")
    g_GameModeSniperID = zp_gamemodes_get_id("Sniper Mode")
    g_GameModeZombietagID = zp_gamemodes_get_id("Zombie Tag Mode")
    g_GameModeDioneID = zp_gamemodes_get_id("Dione Mode")
    g_GameModeWinosID = zp_gamemodes_get_id("Winos Mode")
    g_GameModeHotPotatoID = zp_gamemodes_get_id("Hot Potato Mode")
    g_GameModeDragonID = zp_gamemodes_get_id("Dragon Mode")
}

public fw_prethink(id) 
{
    if (is_user_connected(id))        
 
    {
        if (zp_gamemodes_get_current() == ZP_NO_GAME_MODE)
	return

        if (zp_gamemodes_get_current() == g_GameModeNemesisID) set_user_icon(id , 1 , 255 , 0 , 0)          
        else if (zp_gamemodes_get_current() == g_GameModeSurvivorID) set_user_icon(id , 1 , 0 , 0 , 255)   
        else if (zp_gamemodes_get_current() == g_GameModeMultiID) set_user_icon(id , 1 , 0 , 255 , 0) 
        else if (zp_gamemodes_get_current() == g_GameModeSwarmID) set_user_icon(id , 1 , 255 , 255 , 0)     
        else if (zp_gamemodes_get_current() == g_GameModePlagueID) set_user_icon(id , 1 , 255 , 0 , 0)
        else if (zp_gamemodes_get_current() == g_GameModeHotPotatoID) set_user_icon(id , 1 , 183 , 134 , 11)
        else if (zp_gamemodes_get_current() == g_GameModeArmageddonID) set_user_icon(id , 1 , 255 , 0 , 255)
        else if (zp_gamemodes_get_current() == g_GameModePredatorID) set_user_icon(id , 1 , 24 , 123 , 205)
        else if (zp_gamemodes_get_current() == g_GameModeDioneID) set_user_icon(id , 1 , 139 , 0 , 139)
        else if (zp_gamemodes_get_current() == g_GameModeSniperID) set_user_icon(id , 1 , 131 , 97 , 167)
        else if (zp_gamemodes_get_current() == g_GameModeKniferID) set_user_icon(id , 1 , 24 , 123 , 205)
        else if (zp_gamemodes_get_current() == g_GameModeNightCrawlerID) set_user_icon(id , 1 , 255 , 69 , 0)
        else if (zp_gamemodes_get_current() == g_GameModePlasmaID) set_user_icon(id , 1 , 213 , 156 , 252)
        else if (zp_gamemodes_get_current() == g_GameModeWinosID) set_user_icon(id , 1 , 255 , 69 , 0)
        else if (zp_gamemodes_get_current() == g_GameModeCannibalsID) set_user_icon(id , 1 , 182 , 158 , 135)
        else if (zp_gamemodes_get_current() == g_GameModeZombietagID) set_user_icon(id , 1 , 138 , 43 , 226)
        else if (zp_gamemodes_get_current() == g_GameModeDragonID) set_user_icon(id , 1 , 138 , 43 , 226)
        else if (zp_gamemodes_get_current() == g_GameModesvnID) set_user_icon(id , 1 , 0 , 50 , 200)
        else set_user_icon(id , 1 , 0 , 255 , 0)  
    }
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

stock set_user_icon(id , mode , red , green , blue) 
{
    mode = is_player_in_menu( id ) ? 0 : 1;
    message_begin(MSG_ONE,iconstatus,{0,0,0},id);
    write_byte(mode);
    write_string("dmg_bio");
    write_byte(red);
    write_byte(green);
    write_byte(blue);
    message_end();
}