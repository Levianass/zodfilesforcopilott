#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <zp50_core>
#include <zp50_items>
#include <zp50_class_nemesis>
#include <zmvip>


new const g_item_name[] = { "Midnight's Darkness" } // Item name
new const g_item_descritpion[] = { "\r50% off" } // Item descritpion
const g_item_cost = 40 // Price (Points)

#define DEF_LIGHT "g"

new item_md, md_used, cvar_duration

public plugin_init()
{
    register_plugin("[ZP50] Midnight's Darkness", "1.3", "Catastrophe")
    register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
    
    cvar_duration = register_cvar("zp_midnight_duration", "0.0")
  
}
public plugin_precache( )
{
    item_md = zv_register_extra_item(g_item_name, g_item_descritpion, g_item_cost, ZV_TEAM_ZOMBIE)	
    
    precache_sound("ambience/alien_hollow.wav")

}

public zv_extra_item_selected(player, itemid)
{
    if (itemid == item_md)
    {
            client_print(player, print_chat, "[ZoD *| VIP] You have bought Midnight's Darkness, everything goes dark now.")
            set_hudmessage(255, 10, 10, -1.0, -1.0, 2, 6.0, 12.0)
            show_hudmessage(0 , "The clock struck twelve and here comes the wrath of zombies")
            set_task(10.0, "md_start")
    }
    return PLUGIN_CONTINUE
}

public event_round_start()
{
    md_used = false
    
    server_cmd("zp_lighting %s", DEF_LIGHT)
   
}

public md_start()
{    
    md_used = true
    
    server_cmd("zp_lighting a")  
    
    client_cmd(0, "spk sound/ambience/alien_hollow.wav")

    if(get_pcvar_float(cvar_duration) > 0)
    {
    set_task(get_pcvar_float(cvar_duration), "md_end")
    }
}

public md_end()
{
    md_used = false
    
    server_cmd("zp_lighting %s", DEF_LIGHT)
}
