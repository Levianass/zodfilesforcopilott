/*
	Shidla [SGC] | 2013 год
	ICQ: 312-298-513

	2.8.2 [Final Version] | 21.05.2013
*/

#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <zombieplague>
#include <zp50_gamemodes>
#include <engine>
#include <zp50_items>
#include <zp50_gamemodes>
#include <colorchat>
#include <zp50_ammopacks>
#include <zp50_colorchat>
#include <bulletdamage>
#include <beams>
#include <zp50_grenade_frost>
#include <dhudmessage>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or greater library required!
#endif

#define PLUGIN "[ZP] LaserMine"
#define VERSION "3.0"
#define AUTHOR "SandStriker / Shidla / QuZ / DJ_WEST"

#define RemoveEntity(%1)	engfunc(EngFunc_RemoveEntity,%1)
#define TASK_PLANT			15100
#define TASK_RESET			15500
#define TASK_RELEASE		15900

#define LASERMINE_TEAM		pev_iuser1 //EV_INT_iuser1
#define LASERMINE_OWNER		pev_iuser2 //EV_INT_iuser3
#define LASERMINE_STEP		pev_iuser3
#define LASERMINE_HITING	pev_iuser4
#define LASERMINE_COUNT		pev_fuser1

#define LASERMINE_POWERUP	pev_fuser2
#define LASERMINE_BEAMTHINK	pev_fuser3

#define LASERMINE_BEAMENDPOINT	pev_vuser1
#define MAX_MINES			10
#define MODE_LASERMINE		0
#define OFFSET_TEAM			114
#define OFFSET_MONEY		115
#define OFFSET_DEATH		444

#define cs_get_user_team(%1)	CsTeams:get_offset_value(%1,OFFSET_TEAM)
#define cs_get_user_deaths(%1)	get_offset_value(%1,OFFSET_DEATH)
#define is_valid_player(%1)	(1 <= %1 <= 32)

// Constants
const m_pOwner = EV_INT_iuser1;
const m_pBeam = EV_INT_iuser2;
const m_rgpDmgTime = EV_INT_iuser3;
const m_flPowerUp = EV_FL_starttime;
const m_vecEnd = EV_VEC_endpos;
const m_flSparks = EV_FL_ltime;


enum CsTeams {
CS_TEAM_UNASSIGNED = 0,
CS_TEAM_T = 1,
CS_TEAM_CT = 2,
CS_TEAM_SPECTATOR = 3
};

enum tripmine_e {
	TRIPMINE_IDLE1 = 0,
	TRIPMINE_IDLE2,
	TRIPMINE_ARM1,
	TRIPMINE_ARM2,
	TRIPMINE_FIDGET,
	TRIPMINE_HOLSTER,
	TRIPMINE_DRAW,
	TRIPMINE_WORLD,
	TRIPMINE_GROUND,
};

enum
{
	POWERUP_THINK,
	BEAMBREAK_THINK,
	EXPLOSE_THINK
};

enum
{
	POWERUP_SOUND,
	ACTIVATE_SOUND,
	STOP_SOUND
};

new const
	ENT_MODELS[]	= "models/zod_lasermine.mdl",
	ENT_SOUND1[]	= "weapons/mine_deploy.wav",
	ENT_SOUND2[]	= "weapons/mine_charge.wav",
	ENT_SOUND3[]	= "weapons/mine_activate.wav",
	ENT_SOUND4[]	= "debris/beamstart9.wav",
	ENT_SOUND5[]	= "items/gunpickup2.wav",
	ENT_SOUND6[]	= "debris/bustglass1.wav",
	ENT_SOUND7[]	= "debris/bustglass2.wav",
	ENT_SPRITE1[]	= "sprites/laserbeam.spr",
	ENT_SPRITE2[]	= "sprites/zerogxplodex.spr";

new const
	ENT_CLASS_NAME[]	=	"lasermine",
	ENT_CLASS_NAME3[]	=	"func_breakable",
	gSnarkClassName[]	=	"wpn_snark",	// Для совместимости с плагином "Snark"
	barnacle_class[]	=	"barnacle",		// Для совместимости с плагином "Barnacle"
	weapon_box[]		=	"weaponbox";

const MAXPLAYERS = 32;

new g_EntMine, beam, boom
new g_LENABLE, g_LFMONEY, g_LAMMO, g_LCOST, g_LMODE, g_LRADIUS
new g_LRDMG,g_LFF,g_LCBT, g_LDELAY, g_LVISIBLE, g_LSTAMMO, g_LACCESS, g_LGLOW, g_LDMGMODE, g_LCLMODE
new g_LCBRIGHT, g_LDSEC, g_LCMDMODE, g_LBUYMODE, g_LME;
new g_msgDamage;
new g_dcount[33],g_nowtime,g_MaxPL, LaserEnt, cvar_units
new bool:g_settinglaser[33]
new Float:plspeed[33], plsetting[33], g_havemine[33], g_deployed[33];
//new CVAR_LMCost
new g_GameModeInfectionID, g_iMaxPlayers, g_GameModeMultiID, g_GameModeSwarmID
new g_MaxLMS[33], Planted[33], Sb_owner[33]
new Float:iLaserMineHealth[33]
new iRandomDamage[33], Float:iFloatNumber[33]
new damage[2]
new const Float:g_flCoords[] = {-0.10, -0.15, -0.20}
new g_iPos[33]
native zp_item_zombie_madness_get(id)
new g_pSB[33], g_pBeam[33], iSBCanBePlaced[33]
new Float:ivecOrigin[3]
new const SB_CLASSNAME[] = "FakeLasermine"
new Float:g_fLastDmg[33]
new g_iDmgMultiplier
new SBText[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	// Вызываем функцию Laser_TakeDamage при получении урона объектом ENT_CLASS_NAME3 (func_breakable)
	RegisterHam(Ham_TakeDamage, ENT_CLASS_NAME3, "Laser_TakeDamage", 0)
	RegisterHam(Ham_TakeDamage, ENT_CLASS_NAME3, "Laser_TakeDamage", 1)
        RegisterHam(Ham_TakeDamage, "player", "CBasePlayer_TakeDamage_Pre");
	//RegisterHam(Ham_Killed, ENT_CLASS_NAME3, "fw_PlayerKilled", 1)
	// Add your code here...
	//register_clcmd("+setlaser","CreateLaserMine_Progress_b");
	//register_clcmd("-setlaser","StopCreateLaserMine");
	register_clcmd("+dellaser","ReturnLaserMine_Progress");
	register_clcmd("-dellaser","StopReturnLaserMine");
	//register_clcmd("say /lm", "say_lasermine");
	register_clcmd("say /lm", "Lasermenu_LgK")
	//register_clcmd("buy_lasermine","BuyLasermineChat");

        register_clcmd("say /lmbuy","BuyLasermine");

	g_LENABLE	= register_cvar("zp_ltm","1")
	g_LACCESS	= register_cvar("zp_ltm_acs","0") //0 all, 1 admin
	g_LMODE		= register_cvar("zp_ltm_mode","0") //0 lasermine, 1 tripmine
	g_LAMMO		= register_cvar("zp_ltm_ammo","1111111")
	g_LCOST		= register_cvar("zp_ltm_cost","20")
	g_LFMONEY	= register_cvar("zp_ltm_fragmoney","1")
	g_LRADIUS	= register_cvar("zp_ltm_radius","25.0")
	g_LRDMG		= register_cvar("zp_ltm_rdmg","1000") //radius damage
	g_LFF		= register_cvar("zp_ltm_ff","0")
	g_LCBT		= register_cvar("zp_ltm_cbt","ALL")
	g_LDELAY	= register_cvar("zp_ltm_delay","0.1")
	g_LVISIBLE	= register_cvar("zp_ltm_line","1")
	g_LGLOW		= register_cvar("zp_ltm_glow","0")
	g_LCBRIGHT	= register_cvar("zp_ltm_bright","255")//laser line brightness.
	g_LCLMODE	= register_cvar("zp_ltm_color","0") //0 is team color,1 is green
	g_LDMGMODE	= register_cvar("zp_ltm_ldmgmode","0") //0 - frame dmg, 1 - once dmg, 2 - 1 second dmg
	g_LDSEC		= register_cvar("zp_ltm_ldmgseconds","1") //mode 2 only, damage / seconds. default 1 (sec)
	g_LSTAMMO	= register_cvar("zp_ltm_startammo","0")
	g_LBUYMODE	= register_cvar("zp_ltm_buymode","1");
	g_LCMDMODE	= register_cvar("zp_ltm_cmdmode","1");		//0 is +USE key, 1 is bind, 2 is each.
	damage[0] = register_cvar("zp_ltm_damage1","50")
	damage[1] = register_cvar("zp_ltm_damage2","0")
	cvar_units = register_cvar("zp_lasermine_units", "42")
	
	register_event("DeathMsg", "DeathEvent", "a");
	register_event("CurWeapon", "standing", "be", "1=1");
	register_event("ResetHUD", "delaycount", "a");
	register_event("ResetHUD", "newround", "b");
	register_logevent("endround", 2, "0=World triggered", "1=Round_End");	// Регистрируем конец раунда
	register_event("Damage","CutDeploy_onDamage","b");
	g_msgDamage		= get_user_msgid("Damage");
	register_event("HLTV","event_newround", "a","1=0", "2=0"); // it's called every on new round 
	// Forward.
	register_forward(FM_Think, "ltm_Think");
	register_forward(FM_PlayerPostThink, "ltm_PostThink");
	register_forward(FM_PlayerPreThink, "ltm_PreThink");

	// Регистируем файл языков
	register_dictionary("LaserMines.txt")
	register_cvar("ZoD *| Lasermine", "3.0", FCVAR_SERVER|FCVAR_SPONLY)

	// Регистрируем ExtraItem
	g_LME = zp_register_extra_item("Lasermine", 15, ZP_TEAM_HUMAN)
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");
	g_iMaxPlayers = get_maxplayers();
	register_think(SB_CLASSNAME, "SB_Think");
//	register_clcmd("iTest","free_lm")

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

public plugin_precache() 
{
	precache_sound(ENT_SOUND1);
	precache_sound(ENT_SOUND2);
	precache_sound(ENT_SOUND3);
	precache_sound(ENT_SOUND4);
	precache_sound(ENT_SOUND5);
	precache_sound(ENT_SOUND6);
	precache_sound(ENT_SOUND7);
	precache_model(ENT_MODELS);
	beam = precache_model(ENT_SPRITE1);
	boom = precache_model(ENT_SPRITE2);
	return PLUGIN_CONTINUE;
}

public plugin_modules() 
{
	require_module("fakemeta");
	require_module("cstrike");
}

public free_lm(id)
{
	g_havemine[id] = 5
	g_MaxLMS[id] = 5
	Sb_owner[id] = 5
	iLaserMineHealth[id] = 450.0
}
public plugin_cfg()
{
	LaserEnt = create_custom_entity("LaserMine_Hurt")
	g_EntMine = engfunc(EngFunc_AllocString,ENT_CLASS_NAME3);
	arrayset(g_havemine,0,sizeof(g_havemine));
	arrayset(g_deployed,0,sizeof(g_deployed));
	g_MaxPL = get_maxplayers();
	g_GameModeInfectionID = zp_gamemodes_get_id("Infection Mode")
	g_GameModeMultiID = zp_gamemodes_get_id("Multiple Infection Mode")
        g_GameModeSwarmID = zp_gamemodes_get_id("Swarm Mode")
	new file[64]; get_localinfo("amxx_configsdir",file,63);
	format(file, 63, "%s/zp_ltm_cvars_ap.cfg", file);
	if(file_exists(file)) server_cmd("exec %s", file), server_exec();
}

public CBasePlayer_TakeDamage_Pre(this, pInflictor, pAttacker, Float:flDamage)
{
    if (!FClassnameIs(pInflictor, "lasermine"))
        return HAM_IGNORED;

    if (!zp_get_user_zombie(this))
        return HAM_SUPERCEDE;

    SetHamParamInteger(5, DMG_GENERIC);
    SetHamParamEntity(3, entity_get_int(pInflictor, EV_INT_iuser1));
    SetHamParamFloat(4, floatmax(flDamage * 6.0, 600.0));

    return HAM_HANDLED;
}

public Laser_TakeDamage(victim, inflictor, attacker, Float:f_Damage, bit_Damage)
{
	//Victim is not lasermine.
	
	new sz_classname[32] 
	entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
	new iHealth = pev( victim, pev_health );	
	new id
	id = pev(victim, LASERMINE_OWNER)
	
	if( !equali(sz_classname,"lasermine") ) 
	return HAM_IGNORED; 
	
	if(!zp_core_is_zombie(attacker))
	return HAM_SUPERCEDE;
	
	if( iHealth < 200 ) // more than 200 glow a bit blue
	{
	set_rendering ( victim, kRenderFxGlowShell, 242, 38, 206, kRenderNormal, 16)
	}
	else if( iHealth < 300 ) // More than 400 glow green
	{
	set_rendering ( victim, kRenderFxGlowShell, 255, 203, 26, kRenderNormal, 16)
	}
	if( iHealth <= 400 ) // less than 200 glow red
	{
	set_rendering ( victim, kRenderFxGlowShell, 255-255*iHealth/600, 255*iHealth/600, 0, kRenderNormal, 16)
	}
	if( iHealth <= 500 ) // less than 200 glow red
	{
	set_rendering ( victim, kRenderFxGlowShell, 255-255*iHealth/600, 255*iHealth/600, 0, kRenderNormal, 16)
	}
	else
	if( iHealth <= 600 ) // More than 400 glow green
	{
	set_rendering ( victim, kRenderFxGlowShell, 0, 255-(255*iHealth-400)/200,255*(iHealth-400)/200, kRenderNormal, 16)
	}
	iLaserMineHealth[id] = float(iHealth)
	if(equal(sz_classname, "lasermine") && is_valid_ent(victim) && zp_core_is_zombie(attacker) && iHealth <= 0.0)
	{
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + 5)
		new player_name[34]
		get_user_name(attacker, player_name, charsmax(player_name))
		zp_colored_print(0, "^03%s ^01earned^03 5 points ^01by destroying lasermine!", player_name)
		new iPos = ++g_iPos[attacker]
		if(iPos == sizeof(g_flCoords))
		{
		iPos = g_iPos[attacker] = 0
		}
		set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
		show_dhudmessage(attacker, "+5 points [Lasermine]")
		return HAM_IGNORED;
	} 	

	//Attacker is zombie 
	if( zp_core_is_zombie( attacker ) && !zp_grenade_frost_get(attacker) )  
	return HAM_IGNORED; 
		
	//Block Damage 
	return HAM_SUPERCEDE; 

}
public cHealth(id) ColorChat(id,GREEN,"ZoD *| Mines]^03 Your Current Lasermine health: ^04%d ^03Points", floatround(iLaserMineHealth[id]) )
public Lasermenu_LgK( id )
{

        //if(zp_gamemodes_get_current() != zp_gamemodes_get_id("Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Multi Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Swarm Mode")) return PLUGIN_HANDLED;

	new Menu = menu_create("[Lasermine Menu]","lgk_lm_handler")
        format(SBText, charsmax(SBText), "Place a Lasermine \r[%d/1]", g_MaxLMS[id]);
	menu_additem(Menu, SBText, "", 0)
	menu_additem(Menu,"Takeback a Lasermine","",0)

	menu_setprop(Menu, MPROP_EXITNAME, "Exit^n^n\yLegendGamerZ-")
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL );
	if(!zp_core_is_zombie(id))
	{
	menu_display(id, Menu, 0 );
	if(Planted[id] == 0)
		CreateFakeSandBag(id)    

	}
	return PLUGIN_CONTINUE
}
public lgk_lm_handler( id, menu, item )
{
	menu_destroy(menu);

	
	switch( item )
	{
		case 0:
		{
			if(iSBCanBePlaced[id] == 5)
			{
				Lasermenu_LgK(id); 
				ColorChat(id, GREEN, "ZoD *|^03 Lasermine can't be placed here!")
				return PLUGIN_CONTINUE;
			}
			
			if(zp_gamemodes_get_current() == g_GameModeMultiID || zp_gamemodes_get_current() == g_GameModeInfectionID || zp_gamemodes_get_current() == g_GameModeSwarmID)
			{
				if(g_havemine[id] >= 1 )
				{
					if(Planted[id] > 0)
					{
					ColorChat(id,GREEN,"ZoD* | Mines ^03You've Already placed a lasermine")
					return PLUGIN_HANDLED;     
					}
					Spawn(id)
                                        Lasermenu_LgK(id)
				}
				else 
					ColorChat(id, GREEN,"ZoD *| Mines^03 You Don't have any laser mines to plant")
			}
			else
			ColorChat(id, GREEN,"ZoD *| Mines^03 Lasermines can be placed only in infection modes.")	
			if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		        remove_entity(g_pSB[id]);		
		}
		case 1:
		{
			
			//client_cmd(id,"+dellaser")
			ReturnMine(id)
                        Lasermenu_LgK(id)
		}
		case 2:
		{
			Destroy(id)
			cHealth(id)
                        Lasermenu_LgK(id)
		}
		case MENU_EXIT:
			Destroy(id)
		
	}
        return 0;
}

public Destroy(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
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
	GetOriginAimEndEyes(id, 150, ivecOrigin, vecAngles)
	engfunc(EngFunc_SetModel, iSB, ENT_MODELS)
	engfunc(EngFunc_SetOrigin, iSB, ivecOrigin);
	
	set_pev(iSB, pev_classname, SB_CLASSNAME);
	set_pev(iSB, pev_owner, id);
	set_pev(iSB, pev_rendermode, kRenderTransAdd);
	set_pev(iSB, pev_renderamt, 200.0);
	set_pev(iSB, pev_body, 1);
	set_pev(iSB, pev_nextthink, get_gametime());
	set_pev(iSB,pev_movetype,MOVETYPE_PUSHSTEP); // Movestep <- for Preview
	set_pev(iSB,pev_frame,0);
	set_pev(iSB,pev_body,5);
	set_pev(iSB,pev_sequence,TRIPMINE_WORLD);
	set_pev(iSB,pev_framerate,0);
	set_pev(iSB,pev_angles,vecAngles);
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

	GetOriginAimEndEyes(pOwner, 150, ivecOrigin, vecAngles);
	iBody = 5
	xs_vec_set(vecColor, 250.0, 0.0, 0.0);
	engfunc(EngFunc_SetOrigin, SandBag, ivecOrigin);	
	set_pev(SandBag,pev_angles,vecAngles);	

	if (!IsHullVacant(ivecOrigin, HULL_HEAD, SandBag))
	{
		if(CheckSandBag() || CheckSandBagFake())
		{
		iBody = 3
		xs_vec_set(vecColor, 0.0, 155.0, 0.0);
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

public delaycount(id)
{
	g_dcount[id] = floatround(get_gametime());
}

bool:CheckTime(id)
{
	g_nowtime = floatround(get_gametime()) - g_dcount[id];
	if(g_nowtime >= get_pcvar_num(g_LDELAY))
		return true;
	return false;
}

public CreateLaserMine_Progress_b(id)
{
	if(get_pcvar_num(g_LCMDMODE) != 0)
	{
	if(zp_gamemodes_get_current() == g_GameModeMultiID || zp_gamemodes_get_current() == g_GameModeInfectionID)
	{
	if(g_havemine[id] >= 1 )
	{
		if(Planted[id] < 1)
		{
		CreateLaserMine_Progress(id);
		}
		else ColorChat(id, GREEN,"ZoD *|Mines ^03You already placed your Lasermine!")	
	}
	else 
		ColorChat(id, GREEN,"ZoD *| Mines ^03You Don't have any laser mines to plant")
	}
	else
		ColorChat(id, GREEN,"ZoD *| Mines ^03Lasermines are infection-mode items only. you can't place it in any other mode.")
	}
	return PLUGIN_HANDLED;
}

public CreateLaserMine_Progress(id)
{
	g_settinglaser[id] = true;
	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(1);
	write_byte(0);
	message_end();

	set_task(1.2, "Spawn", (TASK_PLANT + id));

	return PLUGIN_HANDLED;
}
public zp_fw_gamemodes_end()
{
	new id
	for (id = 1; id <= get_maxplayers(); id++)
	{
		g_havemine[id] = 0
		Planted[id] = 0
	}
}
public ReturnLaserMine_Progress(id)
{

	if(!ReturnCheck(id))
		return PLUGIN_HANDLED;
	g_settinglaser[id] = true;

	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(1);
	write_byte(0);
	message_end();

	set_task(1.2, "ReturnMine", (TASK_RELEASE + id));

	return PLUGIN_HANDLED;
}

public StopCreateLaserMine(id)
{

	DeleteTask(id);
	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(0);
	write_byte(0);
	message_end();

	return PLUGIN_HANDLED;
}

public StopReturnLaserMine(id)
{

	DeleteTask(id);
	message_begin(MSG_ONE, 108, {0,0,0}, id);
	write_byte(0);
	write_byte(0);
	message_end();

	return PLUGIN_HANDLED;
}

public ReturnMine(id)
{
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 100.0) return;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return;
	if(pev(tgt,LASERMINE_OWNER) != id) return;
	RemoveEntity(tgt);

	g_havemine[id] ++;
	g_deployed[id] --;
	g_havemine[id] ++;
	Planted[id] = 0;
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	//client_cmd(id, "-dellaser")
	return;
}

public Spawn(id)
{
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
		
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
	new gName[32]
	get_user_name(id,gName,charsmax(gName))
	// motor
	new i_Ent = engfunc(EngFunc_CreateNamedEntity,g_EntMine);
	if(!i_Ent)
	{
		client_print(id, print_chat,"[Laesrmine Debug] Can't Create Entity");
		return PLUGIN_HANDLED_MAIN;
	}
	set_pev(i_Ent,pev_classname,ENT_CLASS_NAME);

	engfunc(EngFunc_SetModel,i_Ent,ENT_MODELS);

	set_pev(i_Ent,pev_solid,SOLID_NOT);
	set_pev(i_Ent,pev_movetype,MOVETYPE_FLY);

	set_pev(i_Ent,pev_frame,0);
	set_pev(i_Ent,pev_body,3);
	set_pev(i_Ent,pev_sequence,TRIPMINE_WORLD);
	set_pev(i_Ent,pev_framerate,0);
	set_pev(i_Ent,pev_takedamage,DAMAGE_YES);
	set_pev(i_Ent,pev_dmg,100.0);
	set_pev(i_Ent,pev_health,iLaserMineHealth[id]); 
	set_pev(i_Ent,pev_movetype,MOVETYPE_FLY)
	//set_user_health(i_Ent,get_pcvar_num(g_LHEALTH));
	new Float:vOrigin[3];
	new	Float:vNewOrigin[3],Float:vNormal[3],Float:vTraceDirection[3],
		Float:vTraceEnd[3],Float:vEntAngles[3]; 
	pev(id, pev_origin, vOrigin);
	velocity_by_aim(id, 150, vTraceDirection);
	xs_vec_add(vTraceDirection, vOrigin, vTraceEnd);
	engfunc(EngFunc_TraceLine, vOrigin, vTraceEnd, DONT_IGNORE_MONSTERS, id, 0);
	new Float:fFraction;
	get_tr2(0, TR_flFraction, fFraction);
	//set_pev(i_Ent, pev_owner, id);
	engfunc(EngFunc_SetSize, i_Ent, Float:{ -4.0, -4.0, -4.0 }, Float:{ 4.0, 4.0, 4.0 });
	// -- We hit something!
	if(fFraction < 1.0)
	{
		// -- Save results to be used later.
		get_tr2(0, TR_vecEndPos, vTraceEnd);
		get_tr2(0, TR_vecPlaneNormal, vNormal);
	}


	xs_vec_mul_scalar(vNormal, 8.0, vNormal);
	xs_vec_add(vTraceEnd, vNormal, vNewOrigin);
	GetOriginAimEndEyes(id, 150, vNewOrigin, vEntAngles);
	engfunc(EngFunc_SetOrigin, i_Ent, vNewOrigin);

	// -- Rotate tripmine.
	vector_to_angle(vNormal,vEntAngles);
	set_pev(i_Ent,pev_angles,vEntAngles);

	// -- Calculate laser end origin.
	new Float:vBeamEnd[3], Float:vTracedBeamEnd[3];
		 
	xs_vec_mul_scalar(vNormal, 8192.0, vNormal);
	xs_vec_add(vNewOrigin, vNormal, vBeamEnd);

	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, IGNORE_MONSTERS, i_Ent, 0);

	get_tr2(0, TR_vecPlaneNormal, vNormal);
	get_tr2(0, TR_vecEndPos, vTracedBeamEnd);

        static hTr

	hTr = create_tr2();

	engfunc(EngFunc_TraceLine, vNewOrigin, vBeamEnd, DONT_IGNORE_MONSTERS, i_Ent, hTr);


	// -- Save results to be used later.
	set_pev(i_Ent, LASERMINE_OWNER, id);
	set_pev(i_Ent,LASERMINE_BEAMENDPOINT,vTracedBeamEnd);
	set_pev(i_Ent,LASERMINE_TEAM,int:cs_get_user_team(id));
	new Float:fCurrTime = get_gametime();

	set_pev(i_Ent,LASERMINE_POWERUP, fCurrTime + 2.5);
	set_pev(i_Ent,LASERMINE_STEP,POWERUP_THINK);
	set_pev(i_Ent,pev_nextthink, fCurrTime + 0.2);

	PlaySound(i_Ent,POWERUP_SOUND);
	g_deployed[id]++;
	g_havemine[id]--;
	Planted[id]++;
	Sb_owner[id]--;
	DeleteTask(id);
	new iLaserHealth = floatround(iLaserMineHealth[id])
	if( iLaserHealth <= 150 ) // from 1 to 100 HP it will glow red
	{
	set_rendering ( i_Ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 22)
	}
	else if( iLaserHealth <= 300 ) // from 400 to infinity HP it will glow green
	{
	set_rendering ( i_Ent, kRenderFxGlowShell, 255, 200, 0, kRenderNormal, 22)
	}
	else if( iLaserHealth <= 450 ) // from 400 to infinity HP it will glow green
	{
	set_rendering ( i_Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 22)
	}
	else if( iLaserHealth <= 600 ) // from 400 to infinity HP it will glow green
	{
	set_rendering ( i_Ent, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 22)
	}	
	ColorChat(0,GREEN,"ZoD *| Mines ^01 %s ^03Has Placed a Lasermine", gName)
        Lasermenu_LgK(id)
	return 1;
}

stock TeamDeployedCount(id)
{
	static i;
	static CsTeams:t;t = cs_get_user_team(id);
	static cnt;cnt=0;

	for(i = 1;i <= g_MaxPL;i++)
	{
		if(is_user_connected(i))
			if(t == cs_get_user_team(i))
				cnt += g_deployed[i];
	}

	return cnt;
}

bool:CheckCanTeam(id)
{
	new arg[5],CsTeam:num;
	get_pcvar_string(g_LCBT,arg,3);
	if(equali(arg,"Z"))
	{
		num = CsTeam:CS_TEAM_T;
	}
	else if(equali(arg,"H"))
	{
		num = CsTeam:CS_TEAM_CT;
	}
	else if(equali(arg,"ALL") || equali(arg,"HZ") || equali(arg,"ZH"))
	{
		num = CsTeam:CS_TEAM_UNASSIGNED;
	}
	else
	{
		num = CsTeam:CS_TEAM_UNASSIGNED;
	}
	if(num != CsTeam:CS_TEAM_UNASSIGNED && num != CsTeam:cs_get_user_team(id))
		return false;
	return true;
}

bool:CanCheck(id,mode)	// Проверки: когда можно ставить мины
{
	if(!get_pcvar_num(g_LENABLE))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NOTACTIVE")

		return false;
	}
	if(get_pcvar_num(g_LACCESS) != 0)
		if(!(get_user_flags(id) & ADMIN_IMMUNITY))
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_NOACCESS")
			return false;
		}
	if(!pev_user_alive(id)) return false;
	if(!CheckCanTeam(id))
	{
		client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_CBT")
		return false;
	}
	if(mode == 0)
	{
		if(g_havemine[id] <= 0)
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_DONTHAVEMINE")
			return false;
		}
	}
	if(mode == 1)
	{
		if(get_pcvar_num(g_LBUYMODE) == 0)
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_CANTBUY")
			return false;
		}
		if(g_havemine[id] >= get_pcvar_num(g_LAMMO))
		{
			client_print(id, print_chat, "%L %L", id, "CHATTAG",id, "STR_HAVEMAX")
			return false;
		}
		if(zp_get_user_ammo_packs(id) < get_pcvar_num(g_LCOST))
		{
			client_print(id, print_chat, "%L %L%d %L", id, "CHATTAG",id, "STR_NOMONEY",get_pcvar_num(g_LCOST),id, "STR_NEEDED")
			return false;
		}
	}
	if(!CheckTime(id))
	{
		client_print(id, print_chat, "%L %L %d %L", id, "CHATTAG",id, "STR_DELAY",get_pcvar_num(g_LDELAY)-g_nowtime,id, "STR_SECONDS")
		return false;
	}

	return true;
}

bool:ReturnCheck(id)
{
	if(!CanCheck(id,-1)) return false;
	if(g_havemine[id] + 1 > get_pcvar_num(g_LAMMO)) return false;
	new tgt,body,Float:vo[3],Float:to[3];
	get_user_aiming(id,tgt,body);
	if(!pev_valid(tgt)) return false;
	pev(id,pev_origin,vo);
	pev(tgt,pev_origin,to);
	if(get_distance_f(vo,to) > 70.0) return false;
	new EntityName[32];
	pev(tgt, pev_classname, EntityName, 31);
	if(!equal(EntityName, ENT_CLASS_NAME)) return false;
	if(pev(tgt,LASERMINE_OWNER) != id) return false;
	return true;
}

public ltm_Think(i_Ent)
{

	if(!pev_valid(i_Ent))
		return FMRES_IGNORED;
	new EntityName[32];
	pev(i_Ent, pev_classname, EntityName, 31);
	if(!get_pcvar_num(g_LENABLE)) return FMRES_IGNORED;
	// -- Entity is not a tripmine, ignoring the next...
	if(!equal(EntityName, ENT_CLASS_NAME))
		return FMRES_IGNORED;

	static Float:fCurrTime;
	fCurrTime = get_gametime();

	switch(pev(i_Ent, LASERMINE_STEP))
	{
		case POWERUP_THINK :
		{
			new Float:fPowerupTime;
			pev(i_Ent, LASERMINE_POWERUP, fPowerupTime);

			if(fCurrTime > fPowerupTime)
			{
				set_pev(i_Ent, pev_solid, SOLID_BBOX);
				set_pev(i_Ent, LASERMINE_STEP, BEAMBREAK_THINK);

				PlaySound(i_Ent, ACTIVATE_SOUND);
			}
			if(get_pcvar_num(g_LGLOW)!=0)
			{
				if(get_pcvar_num(g_LCLMODE)==0)
				{
					switch (pev(i_Ent,LASERMINE_TEAM))
					{
						// цвет лазера Зомби
						case CS_TEAM_T: set_rendering(i_Ent,kRenderFxGlowShell,0,255,0,kRenderNormal,5);
						// цвет лазера Человека
						case CS_TEAM_CT:set_rendering(i_Ent,kRenderFxGlowShell,0,255,0,kRenderNormal,5);
					}
				}else
				{
					// цвет лазера, если стоит "одинаковый для всех" цвет
					set_rendering(i_Ent,kRenderFxGlowShell,0,255,0,kRenderNormal,5);
				}
			}
			set_pev(i_Ent, pev_nextthink, fCurrTime + 0.1);
		}
		case BEAMBREAK_THINK :
		{
			static Float:vEnd[3],Float:vOrigin[3];
			pev(i_Ent, pev_origin, vOrigin);
			pev(i_Ent, LASERMINE_BEAMENDPOINT, vEnd);

			static iHit, Float:fFraction, Trace_Result;
			engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, 0);
			
			engfunc(EngFunc_TraceLine, vOrigin, vEnd, DONT_IGNORE_MONSTERS, i_Ent, Trace_Result);
			get_tr2(Trace_Result, TR_flFraction, fFraction);
			iHit = get_tr2(Trace_Result, TR_pHit);

			// -- Something has passed the laser.
			if(fFraction < 1.0)
			{
				// -- Ignoring others tripmines entity.
				if(pev_valid(iHit))
				{
					pev(iHit, pev_classname, EntityName, 31);
					// Игнорим всякую хрень
					if(!equal(EntityName, ENT_CLASS_NAME) && !equal(EntityName, gSnarkClassName) && !equal(EntityName, barnacle_class) && !equal(EntityName, weapon_box))
					{
						set_pev(i_Ent, pev_enemy, iHit);

						if(get_pcvar_num(g_LMODE) == MODE_LASERMINE)
							CreateLaserDamage(i_Ent,iHit);
						else
							if(get_pcvar_num(g_LFF) || CsTeams:pev(i_Ent,LASERMINE_TEAM) != cs_get_user_team(iHit))
								set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);

						if (!pev_valid(i_Ent))	// если не верный объект - ничего не делаем. Спасибо DJ_WEST
							return FMRES_IGNORED;

						set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
					}
				}
			}
			if(get_pcvar_num(g_LDMGMODE)!=0)
				if(pev(i_Ent,LASERMINE_HITING) != iHit)
					set_pev(i_Ent,LASERMINE_HITING,iHit);
 
			// -- Tripmine is still there.
			if(pev_valid(i_Ent))
			{
				static Float:fHealth;
				pev(i_Ent, pev_health, fHealth);

				if(fHealth <= 0.0 || (pev(i_Ent,pev_flags) & FL_KILLME))
				{
				set_pev(i_Ent, LASERMINE_STEP, EXPLOSE_THINK);
				set_pev(i_Ent, pev_nextthink, fCurrTime + random_float(0.1, 0.3));
				}
										 
				static Float:fBeamthink;
				pev(i_Ent, LASERMINE_BEAMTHINK, fBeamthink);
						 
				if(fBeamthink < fCurrTime && get_pcvar_num(g_LVISIBLE))
				{
					DrawLaser(i_Ent, vOrigin, vEnd);
					set_pev(i_Ent, LASERMINE_BEAMTHINK, fCurrTime + 0.1);
				}
				set_pev(i_Ent, pev_nextthink, fCurrTime + 0.01);
			}
		}
		case EXPLOSE_THINK :
		{
			// -- Stopping entity to think
			set_pev(i_Ent, pev_nextthink, 0.0);
			PlaySound(i_Ent, STOP_SOUND);
			g_deployed[pev(i_Ent,LASERMINE_OWNER)]--;
			CreateExplosion(i_Ent);
			CreateDamage(i_Ent,get_pcvar_float(g_LRDMG),get_pcvar_float(g_LRADIUS))
			RemoveEntity(i_Ent);
		}
    }
	return FMRES_IGNORED;
}

PlaySound(i_Ent, i_SoundType)
{
	switch (i_SoundType)
	{
		case POWERUP_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND1, VOL_NORM, ATTN_NORM, 0, PITCH_NORM);
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, 0, PITCH_NORM);
		}
		case ACTIVATE_SOUND :
		{
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, 1, 75);
		}
		case STOP_SOUND :
		{
			emit_sound(i_Ent, CHAN_BODY , ENT_SOUND2, 0.2, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(i_Ent, CHAN_VOICE, ENT_SOUND3, 0.5, ATTN_NORM, SND_STOP, 75);
		}
	}
}

DrawLaser(i_Ent, const Float:v_Origin[3], const Float:v_EndOrigin[3])
{
	new tcolor[3];
	new teamid = pev(i_Ent, LASERMINE_TEAM);
	if(get_pcvar_num(g_LCLMODE) == 0)
	{
		switch(teamid){
			case 1:{
				// Цвет луча для Зомби
				tcolor[0] = 255;
				tcolor[1] = 0;
				tcolor[2] = 0;
			}
			case 2:{
				// Цвет луча для Человека
				tcolor[0] = 255;
				tcolor[1] = 0;
				tcolor[2] = 0;
			}
		}
	}else
	{
        tcolor[0] = 255;
        tcolor[1] = 0;
        tcolor[2] = 0;
	}
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord,v_Origin[0]);
	engfunc(EngFunc_WriteCoord,v_Origin[1]);
	engfunc(EngFunc_WriteCoord,v_Origin[2]);
	engfunc(EngFunc_WriteCoord,v_EndOrigin[0]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[1]); //Random
	engfunc(EngFunc_WriteCoord,v_EndOrigin[2]); //Random
	write_short(beam);
	write_byte(0);
	write_byte(0);
	write_byte(1);	//Life
	write_byte(5);	//Width
	write_byte(0);	//wave
	write_byte(255); // r
	write_byte(0); // g
	write_byte(0); // b
	write_byte(get_pcvar_num(g_LCBRIGHT));
	write_byte(255);
	message_end();
}

CreateDamage(iCurrent,Float:DmgMAX,Float:Radius)
{
	// Get given parameters
	new Float:vecSrc[3];
	pev(iCurrent, pev_origin, vecSrc);

	new AtkID =pev(iCurrent,LASERMINE_OWNER);
	new TeamID=pev(iCurrent,LASERMINE_TEAM);

	new ent = -1;
	new Float:tmpdmg = DmgMAX;

	new Float:kickback = 0.0;
	// Needed for doing some nice calculations :P
	new Float:Tabsmin[3], Float:Tabsmax[3];
	new Float:vecSpot[3];
	new Float:Aabsmin[3], Float:Aabsmax[3];
	new Float:vecSee[3];
	new trRes;
	new Float:flFraction;
	new Float:vecEndPos[3];
	new Float:distance;
	new Float:origin[3], Float:vecPush[3];
	new Float:invlen;
	new Float:velocity[3];
	new pHitHP,pHitTeam;
	// Calculate falloff
	new Float:falloff;
	if(Radius > 0.0)
	{
		falloff = DmgMAX / Radius;
	} else {
		falloff = 1.0;
	}
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, Radius)) != 0)
	{
		if(!pev_valid(ent)) continue;
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
		{
			// Entity is not a player or monster, ignore it
			continue;
		}
		if(!pev_user_alive(ent)) continue;
		// Reset data
		kickback = 1.0;
		tmpdmg = DmgMAX;
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(ent, pev_absmin, Tabsmin);
		pev(ent, pev_absmax, Tabsmax);
		xs_vec_add(Tabsmin,Tabsmax,Tabsmin);
		xs_vec_mul_scalar(Tabsmin,0.5,vecSpot);
		pev(iCurrent, pev_absmin, Aabsmin);
		pev(iCurrent, pev_absmax, Aabsmax);
		xs_vec_add(Aabsmin,Aabsmax,Aabsmin);
		xs_vec_mul_scalar(Aabsmin,0.5,vecSee);
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, iCurrent, trRes);
		get_tr2(trRes, TR_flFraction, flFraction);
		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if(flFraction >= 0.9 || get_tr2(trRes, TR_pHit) == ent)
		{
			// Work out the distance between impact and entity
			get_tr2(trRes, TR_vecEndPos, vecEndPos);
			distance = get_distance_f(vecSrc, vecEndPos) * falloff;
			tmpdmg -= distance;
			if(tmpdmg < 0.0)
				tmpdmg = 0.0;
			// Kickback Effect
			if(kickback != 0.0)
			{
				xs_vec_sub(vecSpot,vecSee,origin);
				invlen = 1.0/get_distance_f(vecSpot, vecSee);

				xs_vec_mul_scalar(origin,invlen,vecPush);
				pev(ent, pev_velocity, velocity)
				xs_vec_mul_scalar(vecPush,tmpdmg,vecPush);
				xs_vec_mul_scalar(vecPush,kickback,vecPush);
				xs_vec_add(velocity,vecPush,velocity);
				if(tmpdmg < 60.0)
				{
					xs_vec_mul_scalar(velocity,12.0,velocity);
				} else {
					xs_vec_mul_scalar(velocity,4.0,velocity);
				}
				if(velocity[0] != 0.0 || velocity[1] != 0.0 || velocity[2] != 0.0)
				{
					// There's some movement todo :)
					set_pev(ent, pev_velocity, velocity)
				}
			}

			pHitHP = pev_user_health(ent) - floatround(tmpdmg)
			pHitTeam = int:cs_get_user_team(ent)
			if(pHitHP <= 0)
			{
				if(pHitTeam != TeamID)
				{
					zp_set_user_ammo_packs(AtkID,zp_get_user_ammo_packs(AtkID) + get_pcvar_num(g_LFMONEY))
					//set_score(AtkID,ent,1,pHitHP)
				}else
				{
					if(get_pcvar_num(g_LFF))
					{
						zp_set_user_ammo_packs(AtkID,zp_get_user_ammo_packs(AtkID) - get_pcvar_num(g_LFMONEY))
						//set_score(AtkID,ent,-1,pHitHP)
					}
				}
			}else
			{
				if(pHitTeam != TeamID || get_pcvar_num(g_LFF))
				{
					//set_pev(Player,pev_health,pHitHP)
					set_user_health(ent, pHitHP)
					engfunc(EngFunc_MessageBegin,MSG_ONE_UNRELIABLE,g_msgDamage,{0.0,0.0,0.0},ent);
					write_byte(floatround(tmpdmg))
					write_byte(floatround(tmpdmg))
					write_long(DMG_BULLET)
					engfunc(EngFunc_WriteCoord,vecSrc[0])
					engfunc(EngFunc_WriteCoord,vecSrc[1])
					engfunc(EngFunc_WriteCoord,vecSrc[2])
					message_end()
				}
			}
		}
	}
	return
}


bool:pev_user_alive(ent)
{
	new deadflag = pev(ent,pev_deadflag);
	if(deadflag != DEAD_NO)
		return false;
	return true;
}

CreateExplosion(iCurrent)
{
	new Float:vOrigin[3];
	pev(iCurrent,pev_origin,vOrigin);

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(99); //99 = KillBeam
	write_short(iCurrent);
	message_end();

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, vOrigin, 0);
	write_byte(TE_EXPLOSION);
	engfunc(EngFunc_WriteCoord,vOrigin[0]);
	engfunc(EngFunc_WriteCoord,vOrigin[1]);
	engfunc(EngFunc_WriteCoord,vOrigin[2]);
	write_short(boom);
	write_byte(30);
	write_byte(15);
	write_byte(0);
	message_end();
}
CreateLaserDamage(iCurrent,isHit)
{
	if(isHit < 0) return PLUGIN_CONTINUE
	switch(get_pcvar_num(g_LDMGMODE))
	{
		case 1:
		{
			if(pev(iCurrent,LASERMINE_HITING) == isHit)
				return PLUGIN_CONTINUE
		}
		case 2:
		{
			if(pev(iCurrent,LASERMINE_HITING) == isHit)
			{
				static Float:cnt
				static now,htime;now = floatround(get_gametime())

				pev(iCurrent,LASERMINE_COUNT,cnt)
				htime = floatround(cnt)
				if(now - htime < get_pcvar_num(g_LDSEC))
				{
					return PLUGIN_CONTINUE;
				}else{
					set_pev(iCurrent,LASERMINE_COUNT,get_gametime())
				}
			}else
			{
				set_pev(iCurrent,LASERMINE_COUNT,get_gametime())
			}
		}
	}

	new Float:vOrigin[3],Float:vEnd[3]
	pev(iCurrent,pev_origin,vOrigin)
	pev(iCurrent,pev_vuser1,vEnd)

	new id
	id = pev(iCurrent,LASERMINE_OWNER)//, szNetName[32]
	iRandomDamage[id] = random_num(get_pcvar_num(damage[0]),get_pcvar_num(damage[1]))
	iFloatNumber[id] = float(iRandomDamage[id])
	if(is_user_connected(id))
	{
		if(is_user_connected(isHit))
		{
			static Float:gametime; gametime = get_gametime()
			if(gametime - g_fLastDmg[id] < 1.0)
				return PLUGIN_CONTINUE
			g_fLastDmg[id] = gametime
			if(zp_core_is_zombie(isHit) && !zp_item_zombie_madness_get(isHit))
			{
				ExecuteHamB(Ham_TakeDamage, isHit, LaserEnt, id, iFloatNumber[id], DMG_GENERIC | DMG_ALWAYSGIB);
				emit_sound(isHit, CHAN_WEAPON, ENT_SOUND4, 1.0, ATTN_NORM, 0, PITCH_NORM)
				bd_show_damage(id,iRandomDamage[id],0,1)
				bd_show_damage(isHit,iRandomDamage[id],0,1)
			}
		}
	}
	return PLUGIN_CONTINUE
}

create_custom_entity(const weaponDescription[])
{
    new iEnt = create_entity("info_target")
    if( iEnt > 0 )
    {
        set_pev(iEnt, pev_classname, weaponDescription)
    }
    return iEnt
} 

stock pev_user_health(id)
{
	new Float:health
	pev(id,pev_health,health)
	return floatround(health)
}

stock set_user_health(id,health)
{
	health > 0 ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}

stock get_user_godmode(index) {
	new Float:val
	pev(index, pev_takedamage, val)

	return (val == DAMAGE_NO)
}

stock set_user_frags(index, frags)
{
	set_pev(index, pev_frags, float(frags))

	return 1
}

stock pev_user_frags(index)
{
	new Float:frags;
	pev(index,pev_frags,frags);
	return floatround(frags);
}



public BuyLasermine(id)
{
        if(zp_gamemodes_get_current() != zp_gamemodes_get_id("Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Multi Infection Mode") && zp_gamemodes_get_current() != zp_gamemodes_get_id("Swarm Mode")) return PLUGIN_CONTINUE

	if(!CanCheck(id,1)) return PLUGIN_CONTINUE
	if(g_MaxLMS[id] >= 1)
	{
		ColorChat(id, GREEN,"ZoD *| Mines ^03 You can't use lasermine more than once per round")
		return PLUGIN_HANDLED
	}
	g_havemine[id]++;
	g_MaxLMS[id] += 1
	Sb_owner[id]++
	ColorChat(id, GREEN,"ZoD *| Mines ^03 You just bought a ^04LaserMine. ^03Type ^04/lm ^03to open this menu again.")
        Lasermenu_LgK(id)
	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}
public BuyLasermineChat(id)
{
	if(!CanCheck(id,1)) return PLUGIN_CONTINUE
	if(g_MaxLMS[id] >= 1)
	{
		ColorChat(id, GREEN,"ZoD *| Mines ^03 You can't use lasermine more than once per round")
		return PLUGIN_HANDLED
	}
	zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id) - get_pcvar_num(g_LCOST))
	g_havemine[id]++;
	g_MaxLMS[id] += 1
	ColorChat(id, GREEN,"ZoD *| Mines ^03 You bought a lasermine!")

	emit_sound(id, CHAN_ITEM, ENT_SOUND5, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	return PLUGIN_HANDLED
}
public zp_fw_items_select_pre(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_LME)
	return ZP_ITEM_AVAILABLE;
	
	// Antidote only available to zombies
	if (zp_core_is_zombie(id))
	return ZP_ITEM_DONT_SHOW;
	
	//Antidote only available during infection modes
	new current_mode = zp_gamemodes_get_current()
	if (current_mode != g_GameModeInfectionID && current_mode != g_GameModeMultiID && current_mode != g_GameModeSwarmID)
	return ZP_ITEM_DONT_SHOW;
	// Display remaining item count for this round
	static text[32]
	formatex(text, charsmax(text), "[%d/1]", g_MaxLMS[id])
	zp_items_menu_text_add(text)
	
	// Reached antidote limit for this round
	if (g_MaxLMS[id] >= 1)
	return ZP_ITEM_NOT_AVAILABLE;
	
	return ZP_ITEM_AVAILABLE;
}
public zp_fw_items_select_post(id, itemid, ignorecost)
{
	// This is not our item
	if (itemid != g_LME)
	return;
	BuyLasermine(id)
	
	iLaserMineHealth[id] = 450.0
	
	iLaserMineHealth[id] = 450.0
	Lasermenu_LgK(id)
}


public showInfo(id)
{
	client_print(id, print_chat, "%L", id, "STR_REF")
}

public say_lasermine(id){
	new said[32]
	read_argv(1,said,31);
	if(!get_pcvar_num(g_LENABLE))
	{
		return PLUGIN_CONTINUE
	}
	if(equali(said, "lasermine") || equali(said, "/lasermine")){
		const SIZE = 1024
		new msg[SIZE+1],len = 0;
		len += formatex(msg[len], SIZE - len, "<html><body>")
		len += formatex(msg[len], SIZE - len, "<p><b>LaserMine</b></p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p>You can be setting the mine on the wall.</p><br/>")
		len += formatex(msg[len], SIZE - len, "<p>That laser will give what touched it damage.</p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p><b>LaserMine Commands</b></p><br/><br/>")
		len += formatex(msg[len], SIZE - len, "<p><b>Say /buy lasermine</b> or <b>Say /lm</b> //buying lasermine<br/>")
		len += formatex(msg[len], SIZE - len, "<b>buy_lasermine</b> //bind ^"F2^" buy_lasermine : using F2 buying lasermine<br/>")
		len += formatex(msg[len], SIZE - len, "<b>+setlaser</b> //bind mouse3 +setlaser : using mouse3 set lasermine on wall<br/>")
		len += formatex(msg[len], SIZE - len, "</body></html>")
		show_motd(id, msg, "Lasermine Entity help")
		return PLUGIN_CONTINUE
	}
	else if(containi(said, "laser") != -1) {
		showInfo(id)
		return PLUGIN_CONTINUE
	}
	return PLUGIN_CONTINUE
}

public standing(id) 
{
	if(!g_settinglaser[id])
		return PLUGIN_CONTINUE

	set_pev(id, pev_maxspeed, 1.0)

	return PLUGIN_CONTINUE
}

public ltm_PostThink(id) 
{
	if(!g_settinglaser[id] && plsetting[id]){
		resetspeed(id)
	}
	else if(g_settinglaser[id] && !plsetting[id]) {
		pev(id, pev_maxspeed,plspeed[id])
		set_pev(id, pev_maxspeed, 1.0)
	}
	plsetting[id] = g_settinglaser[id]
	return FMRES_IGNORED
}

public ltm_PreThink(id)
{
	if(!pev_user_alive(id) || g_settinglaser[id] == true || is_user_bot(id) || get_pcvar_num(g_LCMDMODE) == 1)
		return FMRES_IGNORED;

	if(pev(id, pev_button) & IN_USE && !(pev(id, pev_oldbuttons) & IN_USE))
		CreateLaserMine_Progress(id)
	return FMRES_IGNORED;
}

resetspeed(id)
{
	set_pev(id, pev_maxspeed, plspeed[id])
}

public client_putinserver(id){
	g_deployed[id] = 0;
	g_havemine[id] = 0;
	DeleteTask(id);
        set_task( 1.0, "Task_CheckAiming", id + 3389, _, _, "b" ); 
	return PLUGIN_CONTINUE
}

public client_disconnect(id){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
	DeleteTask(id);
	RemoveAllTripmines(id);
	if (g_pSB[id] && is_valid_ent(g_pSB[id]))
		remove_entity(g_pSB[id]);
	
	if (g_pBeam[id] && is_valid_ent(g_pBeam[id]))
		remove_entity(g_pBeam[id]);
	return PLUGIN_CONTINUE
}


public newround(id){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE
	pev(id, pev_maxspeed,plspeed[id])
	DeleteTask(id);
	RemoveAllTripmines(id);
	//client_print(id, print_chat, "[ZP][LM][DeBug] All Mines removied!");
	delaycount(id);
	SetStartAmmo(id);
	return PLUGIN_CONTINUE
}

public endround(id)
{
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE

	// Удаление мин после конца раунда
	DeleteTask(id);
	RemoveAllTripmines(id);
	g_MaxLMS[id] = 0
	Planted[id] = 0
	g_havemine[id] = 0
	return PLUGIN_CONTINUE
}
public zp_fw_gamemodes_start()
{
	new id
	for (id = 1; id <= get_maxplayers(); id++)
	{
		g_MaxLMS[id] = 0
		Planted[id] = 0
		g_havemine[id] = 0
	}
}
public DeathEvent(){
	if(!get_pcvar_num(g_LENABLE))
		return PLUGIN_CONTINUE

	new id = read_data(2)
	if(is_user_connected(id)) DeleteTask(id);
	return PLUGIN_CONTINUE
}

public RemoveAllTripmines(i_Owner)
{
	new iEnt = g_MaxPL + 1;
	new clsname[32];
	while((iEnt = engfunc(EngFunc_FindEntityByString, iEnt, "classname", ENT_CLASS_NAME)))
	{
		if(i_Owner)
		{
			if(pev(iEnt, LASERMINE_OWNER) != i_Owner)
				continue;
			clsname[0] = '^0'
			pev(iEnt, pev_classname, clsname, sizeof(clsname)-1);
			if(equali(clsname, ENT_CLASS_NAME))
			{
				PlaySound(iEnt, STOP_SOUND);
				RemoveEntity(iEnt);
			}
		}
		else
			set_pev(iEnt, pev_flags, FL_KILLME);
	}
	g_deployed[i_Owner]=0;
}

SetStartAmmo(id)
{
	new stammo = get_pcvar_num(g_LSTAMMO);
	if(stammo <= 0) return PLUGIN_CONTINUE;
	g_havemine[id] = (g_havemine[id] <= stammo) ? stammo : g_havemine[id];
	return PLUGIN_CONTINUE;
}

public CutDeploy_onDamage(id)
{
	if(get_user_health(id) < 1)
		DeleteTask(id);
}

DeleteTask(id)
{
	if(task_exists((TASK_PLANT + id)))
	{
		remove_task((TASK_PLANT + id))
	}
	if(task_exists((TASK_RELEASE + id)))
	{
		remove_task((TASK_RELEASE + id))
	}
	g_settinglaser[id] = false
	return PLUGIN_CONTINUE;
}

get_offset_value(id, type)
{
	new key = -1;
	switch(type)
	{
		case OFFSET_TEAM: key = OFFSET_TEAM;
		case OFFSET_MONEY:
		key = OFFSET_MONEY;
		case OFFSET_DEATH: key = OFFSET_DEATH;
	}
	if(key != -1)
	{
		if(is_amd64_server()) key += 25;
		return get_pdata_int(id, key);
	}
	return -1;
}
public event_newround() 
{ 
	for ( new id; id <= get_maxplayers(); id++) 
	{ 
		g_MaxLMS[id] = 0
	} 
	
} 

bool:IsHullVacant(const Float:vecSrc[3], iHull, pEntToSkip = 0)
{
	engfunc(EngFunc_TraceHull, vecSrc, vecSrc, IGNORE_MONSTERS, iHull, pEntToSkip, 0);
	return bool:(!get_tr2(0, TR_AllSolid) && !get_tr2(0, TR_StartSolid) && get_tr2(0, TR_InOpen));
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

GetOriginAimEndEyes(this, iDistance, Float:vecOut[3], Float:vecAngles[3])
{
	static Float:vecSrc[3], Float:vecEnd[3], Float:vecViewOfs[3], Float:vecVelocity[3];
	static Float:flFraction, Float:vecPlaneNormal[3];

	pev(this, pev_origin, vecSrc);
	pev(this, pev_view_ofs, vecViewOfs);

	xs_vec_add(vecSrc, vecViewOfs, vecSrc);
	velocity_by_aim(this, iDistance, vecVelocity);
	xs_vec_add(vecSrc, vecVelocity, vecEnd);

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

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, 0);
	
	get_tr2(0, TR_flFraction, flFraction);
	
	get_tr2(0, TR_PlaneNormal, vecPlaneNormal);
	get_tr2(0, TR_vecEndPos, vecOut);
		
	xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
	xs_vec_add(vecOut, vecPlaneNormal, vecOut);

	//vecVelocity[2] = 0.0;
	vector_to_angle(vecPlaneNormal, vecAngles);
}

public CheckSandBag()
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,get_pcvar_float(cvar_units))) != 0 )
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
		if( !equali(sz_classname,"lasermine") ) 
		{
		//our dude has sandbags and wants to place them near to him
		if(is_user_connected(victim) && is_user_alive(victim) && Sb_owner[victim] == 0)
			return false; 
		}
	}
	return true;
}

public CheckSandBagFake()
{
	static victim
	victim = -1
	while ( ( victim = find_ent_in_sphere(victim,ivecOrigin,get_pcvar_float(cvar_units))) != 0 )
	{
		new sz_classname[32] 
		entity_get_string( victim , EV_SZ_classname , sz_classname, 31 )
		if( !equali(sz_classname,"FakeLasermine") ) 
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

public Task_CheckAiming( iTaskIndex )
{
    static iClient;
    iClient = iTaskIndex - 3389;

    if( is_user_alive( iClient ) )
    {
        static iEntity, iDummy, cClassname[ 32 ];
        get_user_aiming( iClient, iEntity, iDummy, 9999 );

        if( pev_valid( iEntity ) )
        {
            pev( iEntity, pev_classname, cClassname, 31 );

            if( equal( cClassname, "lasermine" ) )
            {
                new name[ 32 ];
                new aim = pev( iEntity, LASERMINE_OWNER );
                get_user_name( aim, name, charsmax( name ) - 1 )
                set_hudmessage( 0, 255, 0, -1.0, 0.60, 0, 6.0, 1.1, 0.0, 0.0, -1 )
                show_hudmessage( iClient, "Owner: %s^nLaser HP :%d", name, pev( iEntity, pev_health ) );
            }
        }
    }
}