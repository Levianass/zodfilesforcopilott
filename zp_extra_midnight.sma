#include <amxmodx>

#include <amxmisc>

#include <hamsandwich>

#include <zp50_core>

#include <zp50_items>

#include <zp50_class_nemesis>

#include <zp50_gamemodes>



#define DEF_LIGHT "m"



new item_md, md_used, cvar_duration



public plugin_init()

{

    register_plugin("[ZP50] Midnight's Darkness", "1.3", "Catastrophe")

    item_md = zp_items_register("Midnights Darkness", 80)

    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")

	

   

    

    cvar_duration = register_cvar("zp_midnight_duration", "0.0")

	



  

}

public plugin_precache( )  precache_sound("ambience/alien_hollow.wav")







public zp_fw_items_select_pre(player, itemid)

{

	if(itemid != item_md) return ZP_ITEM_AVAILABLE;

		

	if(!zp_core_is_zombie(player) || md_used == 1) return ZP_ITEM_DONT_SHOW;

		

        if(zp_gamemodes_get_current() != zp_gamemodes_get_id("Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Nemesis Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Vengeance Mode")) return ZP_ITEM_DONT_SHOW;
		

        

	return ZP_ITEM_AVAILABLE;

}



public zp_fw_items_select_post(player, itemid)

{

	if(itemid != item_md)

		return;

		

	client_printcolor(player,"/gZoD *|/y You have bought the Midnight's Darkness, everything goes dark now.")

	set_hudmessage(255, 10, 10, -1.0, -1.0, 2, 6.0, 12.0)

	show_hudmessage(0 , "The clock struck twelve and here comes the wrath of zombies")

	md_used = 1

	set_task(10.0, "md_start")

}



public event_round_start()

{

    md_used = 0

    

    server_cmd("zp_lighting %s", DEF_LIGHT)

   

}



public md_start()

{    

    

    

    server_cmd("zp_lighting a")  

    

    client_cmd(0, "spk sound/ambience/alien_hollow.wav")

    client_printcolor(0,"/gZoD*|/t The clock has struck midnight. The zombies' power is at its peak! Zombies on Drugs incoming!")



    if(get_pcvar_float(cvar_duration) > 0)

    {

    set_task(get_pcvar_float(cvar_duration), "md_end")

    }

}



public md_end()

{

    md_used = 0

    

    server_cmd("zp_lighting %s", DEF_LIGHT)

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