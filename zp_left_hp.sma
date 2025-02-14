#include <amxmodx>
#include <zombieplague>

new g_hudmsg1

public plugin_init() 
{
    register_plugin("Show HP + Armor", "1.0", "<VeCo>")
    
    register_event("Damage","event_damage", "b", "2!0", "3=0", "4!0")
    g_hudmsg1 = CreateHudSyncObj()
}

public event_damage(id)
{
    new iAttac = get_user_attacker(id)
    
    if(iAttac == id || !is_user_alive(iAttac) || !is_user_alive(id))
        return
    
    if(zp_get_user_zombie(id))
    {
       set_hudmessage(255, 0, 0, -1.0, 0.25, 0, 0.0, 0.2, 0.2, 3.0, -1 );
       ShowSyncHudMsg(iAttac, g_hudmsg1, "%i", get_user_health(id))
    }
    else
    {
        set_hudmessage(255, 0, 0, 0.50, 0.25, 0, 6.0, 1.0)
         ShowSyncHudMsg(iAttac, g_hudmsg1, "%i", get_user_health(id))
    }
} 

