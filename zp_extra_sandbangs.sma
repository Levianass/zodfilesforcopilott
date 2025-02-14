#include <amxmodx> 

#include <amxmisc> 

#include <fakemeta> 

#include <hamsandwich> 

#include <engine> 

#include <xs> 

#include <fun> 

#include <zp50_items>

#include <zombieplague> 



// The sizes of models 

#define PALLET_MINS Float:{ -27.260000, -22.280001, -22.290001 } 

#define PALLET_MAXS Float:{  27.340000,  26.629999,  29.020000 } 





// from fakemeta util by VEN 

#define fm_find_ent_by_class(%1,%2) engfunc(EngFunc_FindEntityByString, %1, "classname", %2) 

#define fm_remove_entity(%1) engfunc(EngFunc_RemoveEntity, %1) 

// this is mine 

#define fm_drop_to_floor(%1) engfunc(EngFunc_DropToFloor,%1) 



#define fm_get_user_noclip(%1) (pev(%1, pev_movetype) == MOVETYPE_NOCLIP) 



// cvars 

new pnumplugin, remove_nrnd, maxpallets, phealth; 



// num of pallets with bags 

new palletscout = 0; 



/* Models for pallets with bags . 

  Are available 2 models, will be set a random of them  */ 

new g_models[][] = 

{ 

    "models/pallet_with_bags2.mdl"

//    "models/pallet_with_bags.mdl" 

} 



new stuck[33] 

new g_bolsas[33]; 

new g_bag[33]

new cvar[3] 



new const Float:size[][3] = { 

    {0.0, 0.0, 1.0}, {0.0, 0.0, -1.0}, {0.0, 1.0, 0.0}, {0.0, -1.0, 0.0}, {1.0, 0.0, 0.0}, {-1.0, 0.0, 0.0}, {-1.0, 1.0, 1.0}, {1.0, 1.0, 1.0}, {1.0, -1.0, 1.0}, {1.0, 1.0, -1.0}, {-1.0, -1.0, 1.0}, {1.0, -1.0, -1.0}, {-1.0, 1.0, -1.0}, {-1.0, -1.0, -1.0}, 

    {0.0, 0.0, 2.0}, {0.0, 0.0, -2.0}, {0.0, 2.0, 0.0}, {0.0, -2.0, 0.0}, {2.0, 0.0, 0.0}, {-2.0, 0.0, 0.0}, {-2.0, 2.0, 2.0}, {2.0, 2.0, 2.0}, {2.0, -2.0, 2.0}, {2.0, 2.0, -2.0}, {-2.0, -2.0, 2.0}, {2.0, -2.0, -2.0}, {-2.0, 2.0, -2.0}, {-2.0, -2.0, -2.0}, 

    {0.0, 0.0, 3.0}, {0.0, 0.0, -3.0}, {0.0, 3.0, 0.0}, {0.0, -3.0, 0.0}, {3.0, 0.0, 0.0}, {-3.0, 0.0, 0.0}, {-3.0, 3.0, 3.0}, {3.0, 3.0, 3.0}, {3.0, -3.0, 3.0}, {3.0, 3.0, -3.0}, {-3.0, -3.0, 3.0}, {3.0, -3.0, -3.0}, {-3.0, 3.0, -3.0}, {-3.0, -3.0, -3.0}, 

    {0.0, 0.0, 4.0}, {0.0, 0.0, -4.0}, {0.0, 4.0, 0.0}, {0.0, -4.0, 0.0}, {4.0, 0.0, 0.0}, {-4.0, 0.0, 0.0}, {-4.0, 4.0, 4.0}, {4.0, 4.0, 4.0}, {4.0, -4.0, 4.0}, {4.0, 4.0, -4.0}, {-4.0, -4.0, 4.0}, {4.0, -4.0, -4.0}, {-4.0, 4.0, -4.0}, {-4.0, -4.0, -4.0}, 

    {0.0, 0.0, 5.0}, {0.0, 0.0, -5.0}, {0.0, 5.0, 0.0}, {0.0, -5.0, 0.0}, {5.0, 0.0, 0.0}, {-5.0, 0.0, 0.0}, {-5.0, 5.0, 5.0}, {5.0, 5.0, 5.0}, {5.0, -5.0, 5.0}, {5.0, 5.0, -5.0}, {-5.0, -5.0, 5.0}, {5.0, -5.0, -5.0}, {-5.0, 5.0, -5.0}, {-5.0, -5.0, -5.0} 

} 





const g_item_bolsas = 30 

new g_itemid_bolsas 

new ZPSTUCK 



/************************************************************* 

************************* AMXX PLUGIN ************************* 

**************************************************************/ 

#define ZP_ITEM_NAME "Sandbags"

#define ZP_ITEM_DESC "Barricade"

#define ZP_ITEM_COST 30

#define ZP_ITEM_LIMIT_PLAYER 2

#define ZP_ITEM_LIMIT_ROUND 6



public plugin_init()  

{ 

    /* Register the plugin */ 

     

    register_plugin("[zp] Extra: SandBags", "1.1", "LARP") 

    set_task(0.1,"checkstuck",0,"",0,"b") 

    g_itemid_bolsas = zp_items_register( ZP_ITEM_NAME, ZP_ITEM_COST);
    /* Register the cvars */ 

    ZPSTUCK = register_cvar("zp_pb_stuck","1") 

    pnumplugin = register_cvar("zp_pb_enable","1"); // 1 = ON ; 0 = OFF 

    remove_nrnd = register_cvar("zp_pb_remround","1"); 

    maxpallets = register_cvar("zp_pb_limit","200"); // max number of pallets with bags 

    phealth = register_cvar("zp_pb_health","600"); // set the health to a pallet with bags 

     

    /* Game Events */ 

    register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 

     

    /* This is for menuz: */ 

    register_menucmd(register_menuid("\ySand Bags:"), 1023, "menu_command" ); 

    register_clcmd("say /pb","show_the_menu"); 

    register_clcmd("say_team /pb","show_the_menu"); 

   

    register_clcmd("say /buy_sb","gbuy"); 

    register_clcmd("say_team /buy_sb","gbuy");

      

    //RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage");  

    //cvar[0] = register_cvar("zp_autounstuck","1") 

    cvar[1] = register_cvar("zp_pb_stuckeffects","1") 

    cvar[2] = register_cvar("zp_pb_stuckwait","7") 

     

     

    RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage"); 

    RegisterHam(Ham_Killed, "func_wall", "fw_PlayerKilled", 1)

	

} 

//Here is what I am tryin to make just owner and zombie to be able to destroy sandbags 

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) 

{ 

    //Victim is not lasermine. 

    new sz_classname[32] 

    entity_get_string( victim , EV_SZ_classname , sz_classname, 31 ) 

    if( !equali(sz_classname,"amxx_pallets") ) 

        return HAM_IGNORED; 

     

    //Attacker is zombie 

    if( zp_core_is_zombie( attacker ) )  

        return HAM_IGNORED; 

     

    //Block Damage 

    return HAM_SUPERCEDE; 

} 



public fw_PlayerKilled(victim, attacker, shouldgib)

{     

    new sz_classname[32], Float: health 

    entity_get_string( victim , EV_SZ_classname , sz_classname, charsmax(sz_classname))



    health = entity_get_float(victim, EV_FL_health)

  

    if(equal(sz_classname, "amxx_pallets") && is_valid_ent(victim) && zp_core_is_zombie(attacker) && health <= 0.0)

    {

        zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 5)

        client_print(attacker, print_chat, "[zp] You earned 5 ammopacks by destroy sandbag!") 

        return HAM_IGNORED;

    } 

    return HAM_IGNORED;

} 



public plugin_precache() 

{ 

    for(new i;i < sizeof g_models;i++) 

        engfunc(EngFunc_PrecacheModel,g_models[i]); 

}



public zp_fw_items_select_pre( id, itemid, ignorecost )

{

	if( itemid != g_itemid_bolsas )

		return ZP_ITEM_AVAILABLE;



	if( zp_core_is_zombie( id ) )

		return ZP_ITEM_DONT_SHOW;

	

	return ZP_ITEM_AVAILABLE;

}



public show_the_menu(id,level,cid) 

{ 

    // check if user doesen't have admin  

    /*if( ! cmd_access( id,level, cid , 0 )) 

        return PLUGIN_HANDLED; 

    */ 

     

    // check if the plugin cvar is turned off 

    if( ! get_pcvar_num( pnumplugin ) ) 

        return PLUGIN_HANDLED; 

         

         

    // check if user isn't alive 

    if( ! is_user_alive( id ) ) 

    { 

        client_print( id, print_chat, "" ); //msg muerto 

        return PLUGIN_HANDLED; 

    } 

             

    if ( !zp_core_is_zombie(id) ) 

    {         

        new szMenuBody[256]; 

        new keys; 

         

        new nLen = format( szMenuBody, 255, "\ySand Bags:^n" ); 

        nLen += format( szMenuBody[nLen], 255-nLen, "^n\w1. Place a Sandbags" ); 

        //nLen += format( szMenuBody[nLen], 255-nLen, "^n\w2. Remove a pallet with bags" ); 

        nLen += format( szMenuBody[nLen], 255-nLen, "^n^n\w0. Exit" ); 



        keys = (1<<0|1<<1|1<<2|1<<3|1<<4|1<<5|1<<6|1<<9) 



        show_menu( id, keys, szMenuBody, -1 ); 



        // depends what you want, if is continue will appear on chat what the admin sayd 

        return PLUGIN_HANDLED; 

    } 

    client_print(id, print_chat, "[zp] The zombies can not use this command!") 

    return PLUGIN_HANDLED; 

} 





public menu_command(id,key,level,cid) 

{ 

     

    switch( key ) 

    { 

        // place a pallet with bags 

        case 0:  

        { 

            if ( !zp_core_is_zombie(id) ) 

            { 

                new money = g_bolsas[id] 

                if ( money < 1 ) 

                { 

                    client_print(id, print_chat, "[zp] You do not have to place sandbags!") 

                    return PLUGIN_CONTINUE 

                } 

                g_bolsas[id]-= 1 

                place_palletwbags(id); 

                show_the_menu(id,level,cid); 

                return PLUGIN_CONTINUE     

            } 

            client_print(id, print_chat, "[zp] The zombies can not use this!!") 

            return PLUGIN_CONTINUE     

        } 

         

        // remove a pallet with bags 

        /*case 1: 

        { 

            if ( !zp_core_is_zombie(id) ) 

            { 

                new ent, body, class[32]; 

                get_user_aiming(id, ent, body); 

                if (pev_valid(ent))  

                { 

                    pev(ent, pev_classname, class, 31); 

                     

                    if (equal(class, "amxx_pallets"))  

                    { 

                        g_bolsas[id]+= 1 

                        fm_remove_entity(ent); 

                    } 

                     

                    else 

                        client_print(id, print_chat, "[zp] You are not aiming at a pallet with bags"); 

                } 

                else 

                    client_print(id, print_chat, "[zp] You are not aiming at a valid entity !"); 

                     

                show_the_menu(id,level,cid); 

            } 

        } 

        */ 

         

        // remove all pallets with bags 

        /*case 2: 

        { 

            g_bolsas[id]= 0 

            remove_allpalletswbags(); 

            client_print(id,print_chat,"[AMXX] You removed all pallets with bags !"); 

            show_the_menu(id,level,cid); 

        } 

            */ 

             

    } 

     

    return PLUGIN_HANDLED; 

} 







public place_palletwbags(id) 

{ 

     

    if( palletscout == get_pcvar_num(maxpallets) ) 

    { 

        client_print(id,print_chat,"[zp] For security reasons only allow %d Sandbags on the server!",get_pcvar_num 



(maxpallets)); 

        return PLUGIN_HANDLED; 

    } 

     

    // create a new entity  

    new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall")); 

     

     

    // set a name to the entity 

    set_pev(ent,pev_classname,"amxx_pallets"); 



     

    // set model         

    engfunc(EngFunc_SetModel,ent,g_models[random(sizeof g_models)]); 

     

    // register a new var. for origin 

    static Float:xorigin[3]; 

    get_user_hitpoint(id,xorigin); 

     

     

    // check if user is aiming at the air  

    if(engfunc(EngFunc_PointContents,xorigin) == CONTENTS_SKY) 

    { 

        client_print(id,print_chat,"[zp] You can not put sandbags in the sky!"); 

        return PLUGIN_HANDLED; 

    } 

     

     

    // set sizes 

    static Float:p_mins[3], Float:p_maxs[3]; 

    p_mins = PALLET_MINS; 

    p_maxs = PALLET_MAXS; 

    engfunc(EngFunc_SetSize, ent, p_mins, p_maxs); 

    set_pev(ent, pev_mins, p_mins); 

    set_pev(ent, pev_maxs, p_maxs ); 

    set_pev(ent, pev_absmin, p_mins); 

    set_pev(ent, pev_absmax, p_maxs ); 



     

    // set the rock of origin where is user placed 

    engfunc(EngFunc_SetOrigin, ent, xorigin); 

     

     

    // make the rock solid 

    set_pev(ent,pev_solid,SOLID_BBOX); // touch on edge, block 

     

    // set the movetype 

    set_pev(ent,pev_movetype,MOVETYPE_FLY); // no gravity, but still collides with stuff 

     

    // now the damage stuff, to set to take it or no 

    // if you set the cvar "pallets_wbags_health" 0, you can't destroy a pallet with bags 

    // else, if you want to make it destroyable, just set the health > 0 and will be 

    // destroyable. 

    new Float:p_cvar_health = get_pcvar_float(phealth); 

    switch(p_cvar_health) 

    { 

        case 0.0 : 

        { 

            set_pev(ent,pev_takedamage,DAMAGE_NO); 

        } 

         

        default : 

        { 

            set_pev(ent,pev_health,p_cvar_health); 

            set_pev(ent,pev_takedamage,DAMAGE_YES); 

        } 

    } 

     

             

    static Float:rvec[3]; 

    pev(id,pev_v_angle,rvec); 

     

    rvec[0] = 0.0; 

     

    set_pev(ent,pev_angles,rvec); 

     

    // drop entity to floor 

    fm_drop_to_floor(ent); 



    set_pev(ent, pev_owner, id);

     

    // num .. 

    palletscout++; 



    set_task(0.1, "glow_sandbags", ent, _,_, "b") 

	

    // confirm message 

    client_print(id, print_chat, "[zp] You have placed a Sandbags, you have %i remaining", g_bolsas[id]) 

    

    return PLUGIN_HANDLED; 

} 

     

/* ==================================================== 

get_user_hitpoin stock . Was maked by P34nut, and is  

like get_user_aiming but is with floats and better :o 

====================================================*/     

stock get_user_hitpoint(id, Float:hOrigin[3])  

{ 

    if ( ! is_user_alive( id )) 

        return 0; 

     

    new Float:fOrigin[3], Float:fvAngle[3], Float:fvOffset[3], Float:fvOrigin[3], Float:feOrigin[3]; 

    new Float:fTemp[3]; 

     

    pev(id, pev_origin, fOrigin); 

    pev(id, pev_v_angle, fvAngle); 

    pev(id, pev_view_ofs, fvOffset); 

     

    xs_vec_add(fOrigin, fvOffset, fvOrigin); 

     

    engfunc(EngFunc_AngleVectors, fvAngle, feOrigin, fTemp, fTemp); 

     

    xs_vec_mul_scalar(feOrigin, 9999.9, feOrigin); 

    xs_vec_add(fvOrigin, feOrigin, feOrigin); 

     

    engfunc(EngFunc_TraceLine, fvOrigin, feOrigin, 0, id); 

    global_get(glb_trace_endpos, hOrigin); 

     

    return 1; 

}  





/* ==================================================== 

This is called on every round, at start up, 

with HLTV logevent. So if the "pallets_wbags_nroundrem" 

cvar is set to 1, all placed pallets with bugs will be 

removed. 

==================================================== */

public event_newround() 

{ 

  for ( new id; id <= get_maxplayers(); id++) 

{ 

    if( get_pcvar_num ( remove_nrnd ) == 1) 

        remove_allpalletswbags(); 



    g_bolsas[id] = 0;

    g_bag[id] = 0;

  } 

         

}  

 

/*

public event_newround()

{

	if( get_pcvar_num ( remove_nrnd ) == 1)

			remove_allpalletswbags();

	for(new id = 0; id < 34; id++){

	g_bag[id] = 0

	}

}

*/



/* ==================================================== 

This is a stock to help for remove all pallets with 

bags placed . Is called on new round if the cvar 

"pallets_wbags_nroundrem" is set 1. 

====================================================*/ 

stock remove_allpalletswbags() 

{ 

    new pallets = -1; 

    while((pallets = fm_find_ent_by_class(pallets, "amxx_pallets"))) 

        fm_remove_entity(pallets); 

         

    palletscout = 0; 

} 



public checkstuck() { 

    if ( get_pcvar_num(ZPSTUCK) == 1 ) 

    { 

        static players[32], pnum, player 

        get_players(players, pnum) 

        static Float:origin[3] 

        static Float:mins[3], hull 

        static Float:vec[3] 

        static o,i 

        for(i=0; i<pnum; i++){ 

            player = players[i] 

            if (is_user_connected(player) && is_user_alive(player)) { 

                pev(player, pev_origin, origin) 

                hull = pev(player, pev_flags) & FL_DUCKING ? HULL_HEAD : HULL_HUMAN 

                if (!is_hull_vacant(origin, hull,player) && !fm_get_user_noclip(player) && !(pev(player,pev_solid) &  



SOLID_NOT)) { 

                    ++stuck[player] 

                    if(stuck[player] >= get_pcvar_num(cvar[2])) { 

                        pev(player, pev_mins, mins) 

                        vec[2] = origin[2] 

                        for (o=0; o < sizeof size; ++o) { 

                            vec[0] = origin[0] - mins[0] * size[o][0] 

                            vec[1] = origin[1] - mins[1] * size[o][1] 

                            vec[2] = origin[2] - mins[2] * size[o][2] 

                            if (is_hull_vacant(vec, hull,player)) { 

                                engfunc(EngFunc_SetOrigin, player, vec) 

                                effects(player) 

                                set_pev(player,pev_velocity,{0.0,0.0,0.0}) 

                                o = sizeof size 

                            } 

                        } 

                    } 

                } 

                else 

                { 

                    stuck[player] = 0 

                } 

            } 

        } 

     

    } 

     

} 



stock bool:is_hull_vacant(const Float:origin[3], hull,id) { 

    static tr 

    engfunc(EngFunc_TraceHull, origin, origin, 0, hull, id, tr) 

    if (!get_tr2(tr, TR_StartSolid) || !get_tr2(tr, TR_AllSolid)) //get_tr2(tr, TR_InOpen)) 

        return true 

     

    return false 

} 



public effects(id) { 

    if(get_pcvar_num(cvar[1])) { 

        set_hudmessage(255,150,50, -1.0, 0.65, 0, 6.0, 1.5,0.1,0.7) // HUDMESSAGE 

        show_hudmessage(id,"Automatic Unstuck!") // HUDMESSAGE 

        message_begin(MSG_ONE_UNRELIABLE,105,{0,0,0},id )       

        write_short(1<<10)   // fade lasts this long duration 

        write_short(1<<10)   // fade lasts this long hold time 

        write_short(1<<1)   // fade type (in / out) 

        write_byte(20)            // fade red 

        write_byte(255)    // fade green 

        write_byte(255)        // fade blue 

        write_byte(255)    // fade alpha 

        message_end() 

        client_cmd(id,"spk fvox/blip.wav") 

    } 

} 

public plugin_natives()
{
    register_native("give_sandbangs", "menu_pub1", 1)   
}

public menu_pub1(id)
{
    if(g_bag[id] > 1) 

    { 

    	client_print(id, print_chat, "Max Sandbags reached !!!") 

    	return ZP_PLUGIN_HANDLED

    }

    g_bolsas[id]+= 2 

    g_bag[id]+=2 

    set_task(0.3,"show_the_menu",id) 

    client_print(id, print_chat, "[zp] You have %i sandbags, to use type 'say / sb'", g_bolsas[id]) 
    return PLUGIN_CONTINUE 
}
public zp_extra_item_selected(id, itemid) 

{ 

  if (itemid == g_itemid_bolsas) 

  {  

    if(g_bag[id] > 1) 

    { 

    	client_print(id, print_chat, "Max Sandbags reached !!!") 

    	return ZP_PLUGIN_HANDLED

    }

    g_bolsas[id]+= 2 

    g_bag[id]+=2 

    set_task(0.3,"show_the_menu",id) 

    client_print(id, print_chat, "[zp] You have %i sandbags, to use type 'say / sb'", g_bolsas[id]) 

  }



  return PLUGIN_CONTINUE 

}  



public gbuy(id)

{

       if ( zp_core_is_zombie(id) || !is_user_alive(id) ){    

       return PLUGIN_HANDLED

       }



       if (zp_get_user_ammo_packs(id) < g_item_bolsas) {

       client_print(id, print_chat, "You don't have enough ammo pack.")    

       return PLUGIN_HANDLED

       }



       //if(!zp_core_is_zombie(id) && is_user_alive(id))

       {

       if(g_bag[id] > 1) 

       { 

      	client_print(id, print_chat, "Max Sandbags reached !!!") 

       	return ZP_PLUGIN_HANDLED

       }

       g_bolsas[id]+= 2 

       g_bag[id]+=2

       set_task(0.3,"show_the_menu",id) 

       client_print(id, print_chat, "[zp] You have %i sandbags, to use type 'say / sb'", g_bolsas[id]) 

       zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) - g_item_bolsas)

       }



       return PLUGIN_CONTINUE   



}



public glow_sandbags(Ent) 

{ 

    if (!pev_valid(Ent)) return PLUGIN_HANDLED 



    new classname[32] 

    pev(Ent, pev_classname, classname, charsmax(classname)) 

    if (!equali(classname, "amxx_pallets")) return PLUGIN_HANDLED 



    if (pev(Ent, pev_health) >= 600) 

        set_rendering(Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 5) 

    if (pev(Ent, pev_health) < 300) 

        set_rendering(Ent, kRenderFxGlowShell, 255, 255, 0, kRenderNormal, 5) 

    if (pev(Ent, pev_health) < 150) 

        set_rendering(Ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5) 



    return PLUGIN_CONTINUE 

} 



stock ChatColor(const id, const input[], any:...) 

{ 

    new count = 1, players[32] 

    static msg[191] 

    vformat(msg, 190, input, 3) 



    replace_all(msg, 190, "!g", "^4") // Cor Verde 

    replace_all(msg, 190, "!y", "^1") // Cor Normal 

    replace_all(msg, 190, "!t", "^3") // Cor do Time [TR = Vermelho] [CT = Azul] [SPECT = Branco] 

    replace_all(msg, 190, "!t2", "^0") // Cor do Time [TR = Vermelho] [CT = Azul] [SPECT = Branco] 



    if (id) players[0] = id; else get_players(players, count, "ch") 



    for (new i = 0; i < count; i++) 

    { 

        if (is_user_connected(players[i])) 

        { 

            message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]) 

            write_byte(players[i]) 

            write_string(msg) 

            message_end() 

        } 

    } 

}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ ansicpg1254\\ deff0\\ deflang1055{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ f0\\ fs16 \n\\ par }
*/
