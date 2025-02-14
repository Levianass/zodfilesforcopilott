#include <amxmodx>
#include <zombieplague>
#include <cstrike> 



#define PLUGIN "[ZP] Addon: Protect the menesis"
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
	if( zp_get_user_nemesis(victim ))
	{
		new players[32], totalplayers
		get_players(players, totalplayers)   
		for(new i = 0; i < totalplayers; i++)
		{
			if(cs_get_user_team(players[i]) == CS_TEAM_T)
			user_kill(players[i])
		}
	}
}