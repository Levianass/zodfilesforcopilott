#include <amxmodx>
#include <zombieplague>
#include <cstrike> 

// This plugin will kill all remaining humans if survivor dies on Plague round
// Suggestion has been made to abdul to make mode based on this idea

#define PLUGIN "[ZP] Addon: Protect the Survivor"
#define VERSION "1.0"
#define AUTHOR "fiendshard"

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("DeathMsg", "player_die", "a")
}

public player_die()
{
	new victim = read_data(2) 
	if( zp_get_user_survivor(victim ))
	{
		new players[32], totalplayers
		get_players(players, totalplayers)   
		for(new i = 0; i < totalplayers; i++)
		{
			if(cs_get_user_team(players[i]) == CS_TEAM_CT)
			user_kill(players[i])
		}
	}
}