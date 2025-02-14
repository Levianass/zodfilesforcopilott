/*================================================================================ 
	
	--------------------------
	-*- [ZP] Items Manager -*-
	--------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <fakemeta>
#include <amx_settings_api>
#include <zp50_colorchat>
#include <zp50_core_const>
#include <zp50_gamemodes>
#include <zp50_items_const>
#include <zp50_class_nemesis>

// Extra Items file
new const ZP_EXTRAITEMS_FILE[] = "zp_extraitems.ini"

// CS Player PData Offsets (win32)
const OFFSET_CSMENUCODE = 205

#define MAXPLAYERS 32

// For item list menu handlers
#define MENU_PAGE_ITEMS g_menu_data[id]
new g_menu_data[MAXPLAYERS+1]

enum _:TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST
}
new g_Forwards[TOTAL_FORWARDS]
new g_ForwardResult

// Items data
new Array:g_ItemRealName
new Array:g_ItemName
new Array:g_ItemCost
new g_ItemCount
new g_AdditionalMenuText[32]
new Mode1, Mode2, Mode3, Mode4, Mode5, Mode6, Mode7, Mode8
new g_iMsgSayTxt

public plugin_init()
{
	register_plugin("[ZP] Items Manager", ZP_VERSION_STRING, "ZP Dev Team")
 
    g_iMsgSayTxt = get_user_msgid("SayText")
	
	register_clcmd("say /items", "clcmd_items")
	register_clcmd("say items", "clcmd_items")
    Mode1 = zp_gamemodes_get_id("Nemesis Mode")
    Mode2 = zp_gamemodes_get_id("Assassin Mode")
    Mode3 = zp_gamemodes_get_id("Winos Mode")
    Mode4 = zp_gamemodes_get_id("Dione Mode")
    Mode5 = zp_gamemodes_get_id("Predator Mode")
    Mode6 = zp_gamemodes_get_id("Zombie Tag Mode")
    Mode7 = zp_gamemodes_get_id("Cannibals Mode")
    Mode8 = zp_gamemodes_get_id("Infection Wars Mode")
	
	g_Forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("zp_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("zp_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
}

// Items Menu
public show_items_menu(id)
{
	if (!is_user_alive(id))
		return;

	static menu[128], name[32], cost, transkey[64]
	new menuid, index, itemdata[2]
	
	// Title
	formatex(menu, charsmax(menu), "%L:\r", id, "MENU_EXTRABUY")
	menuid = menu_create(menu, "menu_extraitems")
	
	// Item List
	for (index = 0; index < g_ItemCount; index++)
	{
		g_AdditionalMenuText[0] = 0
		
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_ForwardResult, id, index, 0)
		
		if (g_ForwardResult >= ZP_ITEM_DONT_SHOW)
			continue;
		
		ArrayGetString(g_ItemName, index, name, charsmax(name))
		cost = ArrayGetCell(g_ItemCost, index)
		
		formatex(transkey, charsmax(transkey), "ITEMNAME %s", name)
		if (GetLangTransKey(transkey) != TransKey_Bad) formatex(name, charsmax(name), "%L", id, transkey)
		
		if (g_ForwardResult >= ZP_ITEM_NOT_AVAILABLE)
			formatex(menu, charsmax(menu), "\d%s %d %s", name, cost, g_AdditionalMenuText)
		else
			formatex(menu, charsmax(menu), "%s \y%d \w%s", name, cost, g_AdditionalMenuText)
		
		itemdata[0] = index
		itemdata[1] = 0
		menu_additem(menuid, menu, itemdata)
	}

	// VIP Extra Items (Only for VIPs)
	if (player_is_vip(id))
	{
		menu_additem(menuid, "VIP Extra Items", "3");
	}
	
	if (menu_items(menuid) <= 0)
	{
		zp_colored_print(id, "%L", id, "NO_EXTRA_ITEMS")
		menu_destroy(menuid)
		return;
	}
	
	formatex(menu, charsmax(menu), "%L", id, "MENU_BACK")
	menu_setprop(menuid, MPROP_BACKNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_NEXT")
	menu_setprop(menuid, MPROP_NEXTNAME, menu)
	formatex(menu, charsmax(menu), "%L", id, "MENU_EXIT")
	menu_setprop(menuid, MPROP_EXITNAME, menu)
	
	MENU_PAGE_ITEMS = min(MENU_PAGE_ITEMS, menu_pages(menuid)-1)
	set_pdata_int(id, OFFSET_CSMENUCODE, 0)
	menu_display(id, menuid, MENU_PAGE_ITEMS)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
