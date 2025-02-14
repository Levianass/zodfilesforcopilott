#include <amxmodx> 
#include <amxmisc> 
#include <fakemeta> 
#include <hamsandwich> 
#include <engine>
#include <xs> 
#include <fun> 
#include <zombieplague> 
#include <beams>

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
new remove_nrnd 

new const SB_CLASSNAME[] = "FakeSandBag"
// num of pallets with bags 
/* Models for pallets with bags . 
Are available 2 models, will be set a random of them  */ 
new g_models[][] = 
{ 
	"models/ls_sandbags.mdl"
} 
new stuck[33] 
new g_bolsas[33]; 
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
new Sb_owner[33]
new cvar_units, g_iMaxPlayers;
new iSandBagHealth[33]
new iTeamLimit, gAlreadyBought[33];
new g_pSB[33], g_pBeam[33], iSBCanBePlaced[33]
new Float:ivecOrigin[3]
/************************************************************* 
************************* AMXX PLUGIN ************************* 
**************************************************************/ 
public plugin_init()  
{ 
	/* Register the plugin */ 
	
	register_plugin("[ZP] Extra: SandBags", "1.1", "LARP") 
	g_itemid_bolsas = zp_register_extra_item("Sandbags", 30, ZP_TEAM_HUMAN) 
	/* Register the cvars */ 
	ZPSTUCK = register_cvar("zp_pb_stuck","1") 
	remove_nrnd = register_cvar("zp_pb_remround","1"); 
	cvar_units = register_cvar("zp_sandbag_units", "42")
	
	g_iMaxPlayers = get_maxplayers();
	
	/* Game Events */ 
	register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 
	
	/* This is for menuz: */ 
	register_clcmd("say /sb","show_the_menu"); 
	register_clcmd("say_team /sb","show_the_menu"); 
	register_think(SB_CLASSNAME, "SB_Think");

	//RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage");  
	//cvar[0] = register_cvar("zp_autounstuck","1") 
	cvar[1] = register_cvar("zp_pb_stuckeffects","1") 
	cvar[2] = register_cvar("zp_pb_stuckwait","7") 
	RegisterHam(Ham_TakeDamage,"func_wall","fw_TakeDamage"); 
	RegisterHam(Ham_Killed, "func_wall", "fw_PlayerKilled", 1)
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
	
} 
public OnFreeEntPrivateData(this)
{
	if (!FClassnameIs(this, SB_CLASSNAME))
		return FMRES_IGNORED;

	new pOwner = pev(this, pev_owner);

	if ((1 <= pOwner <= g_iMaxPlayers))
	{
		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
			remove_entity(g_pBeam[pOwner]);

		g_pBeam[pOwner] = 0;
		g_pSB[pOwner] = 0;
	}
	return FMRES_IGNORED;
}

//Here is what I am tryin to make just owner and zombie to be able to destroy sandbags 
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type) 
{ 
	//Victim is not aa sandbag. 
	new sz_classname[32] 
	entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
	new iHealth = pev( victim, pev_health )-floatround(damage);
	if(iHealth<=0)
	{
		iHealth=1;
	}
	
	if( !equali(sz_classname,"amxx_pallets") ) 
	return HAM_IGNORED; 
	
	/*else if( iHealth < 400 ) // more than 200 glow a bit blue
	{
		set_rendering ( victim, kRenderFxGlowShell, 242, 38, 206, kRenderNormal, 16)
	}
	else if( iHealth < 600 ) // More than 400 glow green
	{
		set_rendering ( victim, kRenderFxGlowShell, 255, 203, 26, kRenderNormal, 16)
	}*/
	/*else if( iHealth < 600 ) // More than 400 glow green
	{
		set_rendering ( victim, kRenderFxGlowShell, 255, 203, 26, kRenderNormal, 16)
	}*/
		
	//Attacker is zombie 
	if( zp_get_user_zombie( attacker )) 
	return HAM_IGNORED; 
		
	//Block Damage 
	return HAM_SUPERCEDE; 
} 
public fw_PlayerKilled(victim, attacker, shouldgib, id)
{     
	new sz_classname[32], Float: health 
	entity_get_string( victim , EV_SZ_classname , sz_classname, charsmax(sz_classname))
	health = entity_get_float(victim, EV_FL_health)
	if(equal(sz_classname, "amxx_pallets") && is_valid_ent(victim) && zp_get_user_zombie(attacker) && health <= 0.0)
	{
		zp_set_user_ammo_packs(attacker, zp_get_user_ammo_packs(attacker) + 5)
		new player_name[34]
		get_user_name(attacker, player_name, charsmax(player_name))
		client_printcolor(0,"!y[!gZP!y] !g%s Has Won !g5 !yAmmoPacks By Destroying a !gSandbag",player_name)
		return HAM_IGNORED;
	} 
	if (g_pSB[victim] && is_valid_ent(g_pSB[victim]))
		remove_entity(g_pSB[victim]);	
	if (g_pBeam[victim] && is_valid_ent(g_pBeam[victim]))
		remove_entity(g_pBeam[victim])
	return HAM_IGNORED;
} 
public plugin_precache() 
{ 
	for(new i;i < sizeof g_models;i++) 
	engfunc(EngFunc_PrecacheModel,g_models[i]); 
}
	
public show_the_menu(id)
{
	new Menu = menu_create("\ySandbags \yMenu", "menu_command")
	menu_additem(Menu, "Buy/Place From Extra Items")
	
	menu_setprop( Menu, MPROP_EXIT, MEXIT_ALL );
	
	if(g_bolsas[id] > 0 && !zp_get_user_zombie(id))
	{
		menu_display(id, Menu, 0 );
		CreateFakeSandBag(id)
	}	
	else
	{		
		if(is_user_alive(id)&&!zp_get_user_zombie(id))
		{
			return;
		}
		else
		{
			
		}
	}
}
public zp_user_infected_post(id){
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id])
}
public free_sb(id)
{
	g_bolsas[id] = 10
}
public menu_command(id, menu, item)
{
	menu_destroy(menu);
		
	if (!g_pSB[id] || !is_valid_ent(g_pSB[id]))
	return PLUGIN_HANDLED;	
	
	switch(item)
	{
		case 0:  
		{ 
			if ( !zp_get_user_zombie(id) ) 
			{ 
				if(iSBCanBePlaced[id] == 2)
				{
					show_the_menu(id); 
					client_printcolor(id, "!y[!gZP!y] You Can't plant a !gSandbag !yat this location!")
					return PLUGIN_CONTINUE;
				}
				new money = g_bolsas[id] 
				if ( money < 1 ) 
				{ 
					return PLUGIN_CONTINUE 
				}
				g_bolsas[id]-= 1 
				place_palletwbags(id); 
				show_the_menu(id); 
				if(Sb_owner[id] > 0)
				{
					Sb_owner[id] -= 1
				}
			}

			else client_printcolor(id, "!tZombies Can't !yUse this")
			return PLUGIN_CONTINUE     
		} 
		case MENU_EXIT:
		{
			if (g_pSB[id] && is_valid_ent(g_pSB[id]))
				remove_entity(g_pSB[id]);
				
			if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
				remove_entity(g_pBeam[id]);			
		}
	}	
	return PLUGIN_HANDLED; 
}

public CreateFakeSandBag(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
		
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
		
	new iSB = create_entity("info_target")
	
	if (!iSB)
		return;
		
	static Float:vecAngles[3]
	GetOriginAimEndEyes(id, 128, ivecOrigin, vecAngles)
	engfunc(EngFunc_SetModel, iSB,g_models[random(sizeof g_models)]);
	engfunc(EngFunc_SetOrigin, iSB, ivecOrigin);
	
	set_pev(iSB, pev_classname, SB_CLASSNAME);
	set_pev(iSB, pev_owner, id);
	set_pev(iSB, pev_rendermode, kRenderTransAdd);
	set_pev(iSB, pev_renderamt, 200.0);
	set_pev(iSB, pev_body, 1);
	set_pev(iSB, pev_nextthink, get_gametime());
	set_pev(iSB,pev_movetype,MOVETYPE_PUSHSTEP); // Movestep <- for Preview

	new pBeam = Beam_Create("sprites/laserbeam.spr", 6.0);
	
	if (pBeam != FM_NULLENT)
	{	
		Beam_EntsInit(pBeam, iSB, id);
		Beam_SetColor(pBeam, Float:{150.0, 0.0, 0.0});
		Beam_SetScrollRate(pBeam, 255.0);
		Beam_SetBrightness(pBeam, 200.0);
	}
	else
	{
		pBeam = 0;
	}
	
	g_pBeam[id] = pBeam;
	g_pSB[id] = iSB;
}

public SB_Think(SandBag)
{
	if (pev_valid(SandBag) != 2)
		return;

	static pOwner;
	pOwner = pev(SandBag, pev_owner);
	
	if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
		return;
		
	static iBody, Float:vecColor[3], Float:vecAngles[3];

	GetOriginAimEndEyes(pOwner, 128, ivecOrigin, vecAngles);
	iBody = 2
	xs_vec_set(vecColor, 250.0, 0.0, 0.0);
	engfunc(EngFunc_SetOrigin, SandBag, ivecOrigin);	

	if (!IsHullVacant(ivecOrigin, HULL_HEAD, SandBag))
	{
		if(CheckSandBag() || CheckSandBagFake())
		{
		iBody = 1
		xs_vec_set(vecColor, 0.0, 250.0, 0.0);
		}
	}	
	
	if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
	{
		Beam_RelinkBeam(g_pBeam[pOwner]);
		Beam_SetColor(g_pBeam[pOwner], vecColor);
	}	
	
	iSBCanBePlaced[pOwner] = iBody	
	set_pev(SandBag, pev_angles, vecAngles);
	set_pev(SandBag, pev_body, iBody);
	set_pev(SandBag, pev_nextthink, get_gametime() + 0.01);
	
	return;
}
	
public place_palletwbags(id) 
{ 
	new Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_wall")); 
	
	set_pev(Ent,pev_classname,"amxx_pallets"); 
	
	engfunc(EngFunc_SetModel,Ent,g_models[random(sizeof g_models)]); 
	
	static Float:p_mins[3], Float:p_maxs[3], Float:vecOrigin[3], Float:vecAngles[3];
	p_mins = PALLET_MINS; 
	p_maxs = PALLET_MAXS; 
	engfunc(EngFunc_SetSize, Ent, p_mins, p_maxs); 
	set_pev(Ent, pev_mins, p_mins); 
	set_pev(Ent, pev_maxs, p_maxs ); 
	set_pev(Ent, pev_absmin, p_mins); 
	set_pev(Ent, pev_absmax, p_maxs ); 	
	set_pev(Ent, pev_body, 3);
	//vecOrigin[2] -= 8.0;
	GetOriginAimEndEyes(id, 128, vecOrigin, vecAngles);
	engfunc(EngFunc_SetOrigin, Ent, vecOrigin); 
	
	set_pev(Ent,pev_solid,SOLID_BBOX); // touch on edge, block 

	new iHealth = pev( Ent, pev_health );
	set_rendering ( Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 16)
	
	set_pev(Ent,pev_movetype,MOVETYPE_FLY); // no gravity, but still collides with stuff 
	
	new Float:p_cvar_health = float(iSandBagHealth[id])
	set_pev(Ent,pev_health,p_cvar_health); 
	set_pev(Ent,pev_takedamage,DAMAGE_YES); 

	static Float:rvec[3]; 
	pev(Ent,pev_v_angle,rvec); 
	
	rvec[0] = 0.0; 
	
	set_pev(Ent,pev_angles,rvec); 
	
	set_pev(Ent, pev_owner, id);

	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
		
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);	
		
	new player_name[34]
	get_user_name(id, player_name, charsmax(player_name))
	//ColorChat(id, RED,"^03%s ^03 has placed a sandbag!", player_name)
	client_printcolor(0, "!y[!gZP!y] %s has placed a !gsandbag", player_name)
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
====================================================*/ 
public event_newround() 
{ 
	iTeamLimit = 0	
	for ( new id; id <= get_maxplayers(); id++) 
	{ 		
		if( get_pcvar_num ( remove_nrnd ) == 1) 
		remove_allpalletswbags(); 
		g_bolsas[id] = 0  
		Sb_owner[id] = 0
		gAlreadyBought[id] = 0
		
		if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
			remove_entity(g_pBeam[id])
		if (g_pSB[id] && is_valid_ent(g_pSB[id]))
			remove_entity(g_pSB[id]);
	} 

}  
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
 
public zp_extra_item_selected(id, itemid)
{
   if (itemid == g_itemid_bolsas) 
   {  
    if(g_bolsas[id] > 1) 
    { 
    client_printcolor(id, "!y[!gZP!y] Max Sandbags reached !!!") 
    return
    }
	
    g_bolsas[id]+= 2 
    gAlreadyBought[id] = 1
    iTeamLimit++
    set_task(0.3,"show_the_menu",id) 
    client_printcolor(id, "!y[!gZP!y] You have !g%i !ysandbags, to use type !g'say / sb'", g_bolsas[id]) 
    Sb_owner[id] = 2
    iSandBagHealth[id] = 750
   
  }
}

public client_disconnect(id)
{	
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
}

public zp_fw_core_infect(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);	
}

public zp_fw_core_cure(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
}

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceHull, vecSrc, vecSrc, DONT_IGNORE_MONSTERS, iHull, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
}

GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction;

	pev(this, pev_origin, vecSrc);
	pev(this, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
	velocity_by_aim(this, iDistance, vecVelocity);
	xs_vec_add(vecSrc, vecVelocity, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, DONT_IGNORE_MONSTERS, this, 0);
	
	get_tr2(0, TR_flFraction, flFraction);
	
	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3];

		get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
		get_tr2(0, TR_vecEndPos, vecOut);

		xs_vec_mul_scalar(vecPlaneNormal, 1.0, vecPlaneNormal);
		xs_vec_add(vecOut, vecPlaneNormal, vecOut);
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}
	
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);
}

public CheckSandBag()
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,get_pcvar_float(cvar_units))) != 0 )
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
		new iHealth = pev( victim, pev_health );
		if( !equali(sz_classname,"amxx_pallets") ) 
		{
		//our dude has sandbags and wants to place them near to him
		if(is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
			return false; 
		}
	}
	return true
}

public CheckSandBagFake()
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,get_pcvar_float(cvar_units))) != 0 )
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
		new iHealth = pev( victim, pev_health );
		if( !equali(sz_classname,"FakeSandBag") ) 
		{
		//our dude has sandbags and wants to place them near to him
		if(is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
			return false; 
		}
	}
	return true
}
FClassnameIs(this, const szClassName[])
{
	if (pev_valid(this) != 2)
		return 0;

	new szpClassName[32];
	pev(this, pev_classname, szpClassName, charsmax(szpClassName));

	return equal(szClassName, szpClassName);
}
stock client_printcolor(const id,const input[], any:...)
{
	new msg[191], players[32], count = 1; vformat(msg,190,input,3);
	replace_all(msg,190,"!g","^4");    // green
	replace_all(msg,190,"!y","^1");    // normal
	replace_all(msg,190,"!t","^3");    // team
	    
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
