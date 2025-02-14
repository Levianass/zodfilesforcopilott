#include <amxmodx>
#include <zombieplague>

#define PLUGIN "[ZP] Random AP CMD"
#define VERSION "1.0"
#define AUTHOR "DoNii"

new bool:g_HasAP[33] = false;

new const FREE_AP[][] = {
	
	"say get",
	"say /get",
	"say_team get",
	"say_team /get",
        "say /rtd",
        "say_team /rtd",
        "say rtd",
        "say_team rtd"
}

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	for (new i; i < sizeof FREE_AP; i++)
	register_clcmd(FREE_AP[i], "give_player_ap");
}

public give_player_ap(id) {
	
	if(g_HasAP[id]) {
		client_printcolor(id,"/g[ZoD *|]/t You've used this already");
		return PLUGIN_HANDLED;
	}
	
	new value = random_num(10, 40)
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + value);
	client_printcolor(id,"/g[ZoD *|]/t You've recieved /g%d points", value);
	g_HasAP[id] = true;
	
	return PLUGIN_HANDLED;
}


stock client_printcolor(const id,const input[], any:...)

{

	new msg[191], players[32], count = 1; vformat(msg,190,input,3);

	replace_all(msg,190,"/g","^4");    // green

	replace_all(msg,190,"/y","^1");    // normal

	replace_all(msg,190,"/t","^3");    // team

	    

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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1036\\ f0\\ fs16 \n\\ par }
*/
