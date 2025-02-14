#include <amxmodx>
#include <hamsandwich>
#include <fun>
#include <colorchat>

#include <zp50_items>
#include <zp50_class_survivor>
#include <zp50_class_nemesis>

#define _PLUGIN           "2000 HP"
#define _COST                     25
#define _VERSION                "1.0"
#define _AUTHOR              "H.RED.ZONE"
    
new _gItemID
new _gLimit[33]

new g_MaxPlayers

public plugin_init() {
    register_plugin(_PLUGIN, _VERSION, _AUTHOR)
    
    _gItemID = zp_items_register(_PLUGIN, _COST)
    
    register_event("HLTV", "NewRound", "a", "1=0", "2=0")
    
    g_MaxPlayers = get_maxplayers()
}

public zp_fw_items_select_pre(id, itemid) {
    if (itemid == _gItemID) {
        if (!zp_core_is_zombie(id) 
        || zp_class_survivor_get(id)
        || zp_class_nemesis_get(id)) {
            return ZP_ITEM_DONT_SHOW;
        }
                  
        if ( _gLimit[id] >= 1 )
            return ZP_ITEM_NOT_AVAILABLE;
        
        return ZP_ITEM_AVAILABLE;
    }
    return ZP_ITEM_AVAILABLE;
}

public zp_fw_items_select_post(id, _itemid, ignorecost) {
    if (_itemid == _gItemID) {
          
        if(is_user_alive(id)) {
            _gLimit[id]++   
    
            new _RandomNum = random_num(2000,2000)
    
            set_user_health(id, get_user_health(id) + _RandomNum)
            ColorChat(id, TEAM_COLOR, "^x04[^x04ZoD *|^x04]^x01 You Bought^x04 %d ^x01health.", _RandomNum)
        }
    }
    return ZP_ITEM_AVAILABLE;
} 

public NewRound() {
    for ( new plr; plr <= g_MaxPlayers; plr++) {
        _gLimit[plr] = 0
    }
}  