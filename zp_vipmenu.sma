/* Sublime AMXX Editor v2.2 */

#include <amxmodx>
#include <fun>
#include <cstrike>
#include <zp50_ammopacks>
#include <zp50_core>

native give_weapon_ethereal(id)
native give_laser(id)
native give_sandbangs(id)
native give_akm12(id)
native give_rock(id)

#define PLUGIN  "[VIP/GOLD/BOSS Menu]"
#define VERSION "1.0"
#define AUTHOR  "Multipower"

new limit_sandbangs[33], limit_laser[33], limitg3[33], limitsg[33], limitw1[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_event("HLTV", "round_starts", "a", "1=0", "2=0")
	register_cvar("zp_vipgoldboss_by",AUTHOR,FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_UNLOGGED|FCVAR_SPONLY)	
        register_clcmd("say_team /vp", "show_menu_vip");
}

public round_starts()
{
	new players[32],inum,id
	get_players(players,inum)
	for(new i;i<inum;i++)
	{
		id = players[i]
		limit_sandbangs[id] = 0
		limit_laser[id] = 0
		limitg3[id] = 0
		limitsg[id] = 0
		limitw1[id] = 0
	}
}

public client_connect(id)
{
	limit_sandbangs[id] = 0
	limit_laser[id] = 0
	limitg3[id] = 0
	limitsg[id] = 0
	limitw1[id] = 0
}

public client_disconnect(id)
{
	limit_sandbangs[id] = 0
	limit_laser[id] = 0
	limitg3[id] = 0
	limitsg[id] = 0
	limitw1[id] = 0
}

public plugin_natives()
{
    register_native("show_menu_vip", "menu_pub1", 1)   
}

public menu_pub1(id)
{
	vip_menu(id)
} 

public vip_menu(id)
{
	new menuz;
	static amenu[512];
	formatex(amenu,charsmax(amenu),"\rVIP Menu")
	menuz = menu_create(amenu,"vip_devam")
	
	formatex(amenu,charsmax(amenu),"LaserMines \r[FREE] \y[0 Packs]")
	menu_additem(menuz,amenu,"1")
	
	formatex(amenu,charsmax(amenu),"Sandbangs \r[FREE] \y[0 Packs]")
	menu_additem(menuz,amenu,"2")
	
	formatex(amenu,charsmax(amenu),"AKM 12 \r[FREE] \y[0 Packs]")
	menu_additem(menuz,amenu,"3")
	
	formatex(amenu,charsmax(amenu),"Ethereal Plasma Rifle \r[FREE] \y[40 Packs]")
	menu_additem(menuz,amenu,"4")	

	formatex(amenu,charsmax(amenu),"Rock Guitar \r[FREE] \y[20 Packs]")
	menu_additem(menuz,amenu,"5")	

	formatex(amenu,charsmax(amenu),"G3SG1 \r[FREE] \y[0 Packs]")
	menu_additem(menuz,amenu,"6")	

	formatex(amenu,charsmax(amenu),"GS552 \r[FREE] \y[0 Packs]")
	menu_additem(menuz,amenu,"7")	

	menu_setprop(menuz,MPROP_EXIT,MEXIT_ALL)
	menu_display(id,menuz,0)
	
	return PLUGIN_HANDLED
}

public vip_devam(id,menu,item)
{
	if(item == MENU_EXIT || zp_core_is_zombie(id))
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new access,callback,data[6],iname[64]
	
	menu_item_getinfo(menu,item,access,data,5,iname,63,callback)
	
	new key = str_to_num(data)

	if(key == 1)
	{
		if(limit_laser[id] < 1)
		{
			give_laser(id)
			limit_laser[id]++
		}
		else
		{
			client_print(id, print_center, "You can buy one time per round")
		}
	}
	else if(key == 2)
	{
		if(limit_sandbangs[id] < 1)
		{
			give_sandbangs(id)
			limit_sandbangs[id]++
		}
		else
		{
			client_print(id, print_center, "You can buy one time per round")
		}
	}
	else if(key == 3)
	{
		if(limitw1[id] < 1)
		{
			give_akm12(id)
			limitw1[id]++
		}
		else
		{
			client_print(id, print_center, "You can buy weapon one time per round")
		}
	}
	else if(key == 4)
	{
		if(zp_ammopacks_get(id) >= 40)
		{
			give_weapon_ethereal(id)
			zp_ammopacks_set(id, zp_ammopacks_get(id) - 40)
		}
		else
		{
			client_print(id, print_center, "You have no enough aps")
		}
	}
	else if(key == 5)
	{
		if(zp_ammopacks_get(id) >= 20)
		{
			give_rock(id)	
			zp_ammopacks_set(id, zp_ammopacks_get(id) - 20)
		}
		else
		{
			client_print(id, print_center, "You have no enough aps")
		}
	}

	else if(key == 6)
	{
		if(limitg3[id] < 1)
		{
			give_item(id,"weapon_g3sg1")	
			cs_set_user_bpammo(id, CSW_G3SG1, 90)
			limitg3[id]++
		}
		else
		{
			client_print(id, print_center, "You can buy weapon one time per round")
		}
	}
	else if(key == 7)
	{
		if(limitsg[id] < 1)
		{
			give_item(id,"weapon_sg550")	
			cs_set_user_bpammo(id, CSW_SG550, 90)
			limitsg[id]++
		}
		else
		{
			client_print(id, print_center, "You can buy weapon one time per round")
		}
	}
	menu_destroy(menu)
	return PLUGIN_HANDLED
}