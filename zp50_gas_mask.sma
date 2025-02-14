#include < amxmodx >
#include < hamsandwich >
#include < engine >

	#include < zp50_core >
	#include < zp50_items >
	#include < zp50_gamemodes >
#define _MarkPlayerHasMask(%0)   _bitPlayerHasMask |= (1 << (%0 & 31))
#define _ClearPlayerWithMask(%0)  _bitPlayerHasMask &= ~(1 << (%0 & 31))
#define _PlayerHasMask(%0)       _bitPlayerHasMask & (1 << (%0 & 31))
	
#define _PLUGIN   "[ZP50] Extra item: Gas Mask"
#define _VERSION             "3.0"
#define _AUTHOR           "H.RED.ZONE"

#define EV_INT_nadetype     EV_INT_flTimeStepSound
#define NADETYPE_INFECTION  1111 

new _ItemID

new _bitPlayerHasMask

new _gMaxPlayers, _gIcon, _gMsgSayText

public plugin_init() {
	register_plugin( _PLUGIN, _VERSION, _AUTHOR )
	
	RegisterHam( Ham_Spawn, "player", "_FW_PlayerSpawn", 1 )
	RegisterHam( Ham_Killed, "player", "_FW_PlayerKilled" )
		
	_ItemID = zp_items_register( "Gas Mask", 30 )
	
	_gMaxPlayers = get_maxplayers( )
	_gIcon = get_user_msgid( "StatusIcon" ) 
	_gMsgSayText = get_user_msgid( "SayText" )
}

public plugin_precache() {
	RegisterHam( Ham_Think, "grenade", "_FW_ThinkGrenade", 1 ) 
}

public zp_fw_items_select_post( plr, itemid, ignorecost ) {
        
	if( itemid == _ItemID ) {
		_MarkPlayerHasMask( plr )
		Icon_On( plr )
		ProtoChat(plr, "You now have a Zombie Infection Gas Mask.")
	}
}

public zp_fw_items_select_pre( plr, itemid )	
{
	if (itemid != _ItemID)
		return ZP_ITEM_AVAILABLE;

	// Corrected line: Replace 'id' with 'plr'
	if (zp_core_is_zombie(plr))
		return ZP_ITEM_DONT_SHOW;
		
	if (zp_gamemodes_get_current() != zp_gamemodes_get_id("Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Multiple Infection Mode"))
		return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}

public _FW_ThinkGrenade( iEnt ) {
	
	if( is_valid_ent(iEnt) ) {
		
		if( entity_get_int(iEnt, EV_INT_nadetype) == NADETYPE_INFECTION ) {
			
			for( new plr = 1; plr <= _gMaxPlayers; plr++ ) {
				
				if( is_user_alive(plr) 
				
				&& _PlayerHasMask(plr) ) {
					
					if( get_entity_distance(iEnt, plr) <= 240 ) {
						
						_ClearPlayerWithMask( plr )
						remove_entity( iEnt )
						Icon_Off( plr )
						
						ProtoChat( plr, "You've just survived a zombie infection bomb!" )
					}
				}
			}
		}
	}
}

public zp_fw_core_infect( plr ) {
	_ClearPlayerWithMask( plr ) 
	Icon_Off( plr )
}

public _FW_PlayerSpawn( plr ) {
	_ClearPlayerWithMask( plr ) 
	Icon_Off( plr )
}

public _FW_PlayerKilled( plr ) {
	_ClearPlayerWithMask( plr ) 
	Icon_Off( plr )
}

public client_disconnect( plr ) {
	Icon_Off( plr )
}

public Icon_On( plr ) {
	message_begin( MSG_ONE_UNRELIABLE, _gIcon, { 0, 0, 0 }, plr );
	write_byte( 1 )
	write_string( "dmg_gas" )
	write_byte( 0 )
	write_byte( 255 )
	write_byte( 0 )
	message_end( )
}

public Icon_Off( plr ) {
	message_begin( MSG_ONE_UNRELIABLE, _gIcon, { 0, 0, 0 }, plr )
	write_byte( 0 )
	write_string( "dmg_gas" )
	write_byte( 0 )
	write_byte( 255 )
	write_byte( 0 )
	message_end( )
}

ProtoChat( plr, const sFormat[], any:... ) {
	
	static i; i = plr ? plr : get_player( )
	
	if ( !i ) {
		return PLUGIN_HANDLED;
	}
	
	new sMessage[ 256 ]
	new len = formatex( sMessage, 255, "^x01[^x04ZP^x01] ")
	
	vformat( sMessage[len], 255-len, sFormat, 3 )
	sMessage[ 192 ] = '^0' 
	
	Make_SayText( plr, i, sMessage )
	
	return PLUGIN_CONTINUE
}

get_player( ) {
	for ( new plr; plr <= _gMaxPlayers; plr++ ) {
		if ( is_user_connected(plr) ) {
			return plr
		}
	}
	return PLUGIN_HANDLED
}

Make_SayText( Receiver, Sender, sMessage[] ) {
	if ( !Sender ) {
		return PLUGIN_HANDLED;
	}
	
	message_begin( Receiver ? MSG_ONE_UNRELIABLE : MSG_ALL, _gMsgSayText, {0,0,0}, Receiver )
	write_byte( Sender )
	write_string( sMessage )
	message_end( )
	
	return PLUGIN_CONTINUE;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
