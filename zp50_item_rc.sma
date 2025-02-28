#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>
#include <hamsandwich>
#include <xs>
#include <cs_maxspeed_api>
#include <beams>
#include <colorchat>
#include <zp50_items>
#include <zp50_gamemodes>
#include <zp50_item_zombie_madness>
#include <zp50_class_zombie>
#include <zp50_grenade_frost>
#include <bulletdamage>


const MAXPLAYERS = 32;

#define SetPlayerBit(%1,%2)		(%1 |= (1<<(%2&31)))
#define ClearPlayerBit(%1,%2)	(%1 &= ~(1 <<(%2&31)))
#define CheckPlayerBit(%1,%2)	(%1 & (1<<(%2&31)))



new const RC_CLASSNAME[] = "rcbomb";
new const RC_MODEL[] = "models/zod_mdls/savage.mdl";
new const CAM_CLASSNAME[] = "rccam";
new const CAM_MODEL[] = "models/rpgrocket.mdl";
new const RC_SOUND[] = "zod_sounds/monster_engine.wav";

new g_pCar[MAXPLAYERS+1], g_pBeam[MAXPLAYERS+1], bool:g_bIsJumping[MAXPLAYERS+1], Float:g_flMaxSpeed[MAXPLAYERS+1], Float:g_vecAngles[MAXPLAYERS+1][3], Float:g_vecOrigin[MAXPLAYERS+1][3], g_pTriggerCam;
new g_iMaxPlayers;
new g_fViewEntCar;
new g_iItemId, explosion, rc_radius, g_iVIPItemId
new iPlayerLimit[33], iLimit[33], iVIPLimit[33]
public plugin_init()
{
	register_plugin("[ZoP*|] Item: RC", "2.0", "Several");

	g_pTriggerCam = create_entity("trigger_camera");
	engfunc(EngFunc_SetModel, g_pTriggerCam, CAM_MODEL);
	set_pev(g_pTriggerCam, pev_classname, CAM_CLASSNAME);
	set_pev(g_pTriggerCam, pev_movetype, MOVETYPE_NOCLIP);
	set_pev(g_pTriggerCam, pev_solid, SOLID_NOT);
	set_pev(g_pTriggerCam, pev_renderamt, 0.0);
	set_pev(g_pTriggerCam, pev_rendermode, kRenderTransTexture);

	g_iMaxPlayers = get_maxplayers();

	g_iItemId = zp_items_register("Remote controlled bomb", 30);
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");

	RegisterHam(Ham_TakeDamage, "info_target", "CBaseEntity_TakeDamage");
	register_think(RC_CLASSNAME, "RC_Think");

	RegisterHam(Ham_Killed, "player", "CBasePlayer_Killed");
	rc_radius = register_cvar("zp_rc_distance", "350")
	register_forward(FM_UpdateClientData, "CBasePlayer_UpdateData_Post", 1);
	register_forward(FM_OnFreeEntPrivateData, "OnFreeEntPrivateData");

	register_clcmd("say /rc", "CmdRC");
	register_clcmd("say_team /rc", "CmdRC");
	
	//register_touch("trigger_teleport", "player", "tport");
}

public plugin_precache()
{
	precache_model(RC_MODEL);
	precache_model(CAM_MODEL);
	precache_sound(RC_SOUND);
	precache_sound("buttons/blip1.wav");
	explosion = precache_model("sprites/zerogxplode.spr")
}

public plugin_natives()
{
	register_native("free_rc", "giveRC", 1)
}
public client_disconnected(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_core_infect(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_core_cure(this)
{
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public zp_fw_items_select_pre(this, iItemId)
{
	if (iItemId != g_iItemId)
		return ZP_ITEM_AVAILABLE;

	static Text[32]
	format(Text, charsmax(Text), "[%d/1]", iLimit[this])
	zp_items_menu_text_add(Text)
	
	if (!IsAllowedMode())
		return ZP_ITEM_DONT_SHOW;
		
	if (zp_core_is_zombie(this))
		return ZP_ITEM_DONT_SHOW;
		
	if(iLimit[this] >= 1)
		return ZP_ITEM_NOT_AVAILABLE;
	
	if(iVIPLimit[this] >= 1)
		return ZP_ITEM_NOT_AVAILABLE;
	
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		return ZP_ITEM_NOT_AVAILABLE;

	return ZP_ITEM_AVAILABLE;
}
public zpv_fw_items_select_pre(this, iItemId)
{
	if (iItemId != g_iItemId)
		return ZP_ITEM_AVAILABLE;
	if(iVIPLimit[this] >= 1)
		return ZP_ITEM_NOT_AVAILABLE;
	
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
		return ZP_ITEM_NOT_AVAILABLE;

	return ZP_ITEM_AVAILABLE;
}
public zpv_fw_items_select_post(this, iItemId)
{
	if (iItemId != g_iVIPItemId)
		return;

	RC_Spawn(this);
	ShowMenu_RC(this);
	iVIPLimit[this] = 1
}
public giveRC(id)
{
	RC_Spawn(id);
	ShowMenu_RC(id);
}
public zp_fw_items_select_post(this, iItemId)
{
	if (iItemId != g_iItemId)
		return;

	RC_Spawn(this);
	ShowMenu_RC(this);
	iPlayerLimit[this] = 1
	iLimit[this]++
}
bool:IsAllowedMode()
{
	new Mode[5]
	Mode[0] = zp_gamemodes_get_current()
	Mode[1] = zp_gamemodes_get_id("Multiple Infection Mode")
	Mode[2] = zp_gamemodes_get_id("Infection Mode")
	Mode[3] = zp_gamemodes_get_id("Armageddon Mode")
        Mode[4] = zp_gamemodes_get_id("Swarm Mode")

	for(new num = 1; num <= charsmax(Mode); num++)
	{
		if(Mode[0] == Mode[num])
			return true
	}
	return false;	
}
public CmdRC(this)
{
	if (!is_user_alive(this) || zp_core_is_zombie(this))
	{
		ColorChat(this, GREEN, "[ZoP*|]^03 Zombies can't use RC")
		return PLUGIN_HANDLED;
	}
	if(!IsAllowedMode())
	{
		ColorChat(this, GREEN, "[ZoP*|]^03 RC Unavailable")
		return PLUGIN_HANDLED;		
	}
	if (g_pCar[this] && is_valid_ent(g_pCar[this]))
	{
		if (pev(g_pCar[this], pev_movetype) == MOVETYPE_PUSHSTEP)
		{
			ColorChat(this, GREEN, "[ZoP*|]^03 You have an active ^04 RC ^03 already")
			return PLUGIN_HANDLED;
		}

		ShowMenu_RC(this);
		return PLUGIN_HANDLED;
	}

	if (!zp_items_force_buy(this, g_iItemId))
	{
		ColorChat(this, GREEN, "[ZoP*|]^03 Item Unavailable")
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;
}

ShowMenu_RC(this)
{
	if(!IsAllowedMode())
	{
		ColorChat(this, GREEN, "[ZoP*|]^03 RC Unavailable")
		return;		
	}
	
	new iMenu, szBuffer[512], iLen;

	iMenu = menu_create("\yZoP*| RC MonsterTruck:", "HandleMenu_RC");

	formatex(szBuffer, charsmax(szBuffer), "Place The RC!");
	menu_additem(iMenu, szBuffer);

	iLen = formatex(szBuffer, charsmax(szBuffer), "^n-Press \rW \wto move forward \rS \wtomove backward, \rA\w -> Left, \rD \w-> Right^n");
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Jump with \r[+attack2]\w^n");
	iLen += formatex(szBuffer[iLen], charsmax(szBuffer) - iLen, "Detonate with \r[+attack]^n");
	menu_addtext(iMenu, szBuffer, 0);

	menu_setprop(iMenu, MPROP_EXIT, MEXIT_NEVER);
	menu_setprop(iMenu, MPROP_PERPAGE, 0);
	menu_display(this, iMenu);
}

public HandleMenu_RC(this, iMenu, iItem)
{
	menu_destroy(iMenu);

	if (!g_pCar[this] || !is_valid_ent(g_pCar[this]))
		return PLUGIN_HANDLED;

	if (iItem == 0)
	{
		if (pev(g_pCar[this], pev_body) == 0)
		{
			if (g_pBeam[this] && is_valid_ent(g_pBeam[this]))
				remove_entity(g_pBeam[this]);
	
			pev(this, pev_origin, g_vecOrigin[this]);
			pev(g_pCar[this], pev_angles, g_vecAngles[this]);

			set_pev(g_pCar[this], pev_solid, SOLID_BBOX);
			set_pev(g_pCar[this], pev_movetype, MOVETYPE_PUSHSTEP);
			set_pev(g_pCar[this], pev_takedamage, DAMAGE_YES);
			set_pev(g_pCar[this], pev_body, random_num(2, 12));
			set_pev(g_pCar[this], pev_rendermode, kRenderNormal);
			set_pev(g_pCar[this], pev_renderamt, 255.0);
                        set_rendering(g_pCar[this], kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 5 )

			drop_to_floor(g_pCar[this]);

			g_flMaxSpeed[this] = get_user_maxspeed(this);
			g_pBeam[this] = 0;

			cs_set_player_maxspeed(this, 1.0);
			attach_view(this, g_pTriggerCam);
			SetPlayerBit(g_fViewEntCar, this);
		}
		else
		{
			ShowMenu_RC(this);
			ColorChat(this, GREEN, "[ZoP*|]^03 You Can't Place ^04The RC ^03 Here")
		}
	}

	return PLUGIN_HANDLED;
}


RC_Spawn(this)
{
	new pCar = create_entity("info_target");

	if (!pCar)
		return;

	new Float:vecOrigin[3], Float:vecAngles[3];

	pev(this, pev_origin, vecOrigin);
	//pev(this, pev_angles, vecAngles);

	new Float:vecVelocity[3];
	velocity_by_aim(this, 128, vecVelocity);
	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);

	vecOrigin[2] += 25.0;

	xs_vec_copy(vecOrigin, g_vecOrigin[this]);
	xs_vec_copy(vecAngles, g_vecAngles[this]);

	engfunc(EngFunc_SetModel, pCar, RC_MODEL);
	engfunc(EngFunc_SetSize, pCar, Float:{ -14.0, -14.0, 0.0 }, Float:{ 14.0, 14.0, 18.5 });
	engfunc(EngFunc_SetOrigin, pCar, vecOrigin);

	set_pev(pCar, pev_classname, RC_CLASSNAME);
	set_pev(pCar, pev_owner, this);
	set_pev(pCar, pev_angles, vecAngles);
	set_pev(pCar, pev_health, 400.0);
	set_pev(pCar, pev_body, 1);
	set_pev(pCar, pev_rendermode, kRenderTransAdd);
	set_pev(pCar, pev_renderamt, 200.0);
	set_pev(pCar, pev_controller_0, 125);
	set_pev(pCar, pev_controller_1, 125);
	set_pev(pCar, pev_controller_2, 125);
	set_pev(pCar, pev_nextthink, get_gametime());

	new pBeam = Beam_Create("sprites/laserbeam.spr", 6.0);

	if (pBeam != FM_NULLENT)
	{	
		Beam_EntsInit(pBeam, pCar, this);
		Beam_SetColor(pBeam, Float:{150.0, 0.0, 0.0});
		Beam_SetScrollRate(pBeam, 255.0);
		Beam_SetBrightness(pBeam, 200.0);
	}
	else
	{
		pBeam = 0;
	}

	g_pBeam[this] = pBeam;
	g_pCar[this] = pCar;
}

public Event_NewRound(this)
{
	new pEdict;
	while ((pEdict = find_ent_by_class(pEdict, RC_CLASSNAME)) > 0)
		remove_entity(pEdict);
	new iPlayer
	for (iPlayer = 1; iPlayer <= 32; iPlayer++)	
	{
		if(is_user_connected(iPlayer))
			iLimit[iPlayer] = 0
	}
	
}

public CBaseEntity_TakeDamage(this, pInflictor, pAttacker)
{
	if (!FClassnameIs(this, RC_CLASSNAME))
		return HAM_IGNORED;

	if(pev( this , pev_waterlevel ))
		return HAM_IGNORED;
		
	if (zp_core_is_zombie(pAttacker))
		return HAM_IGNORED;
		
	return HAM_SUPERCEDE;
}


public RC_Think(this)
{
	if (pev_valid(this) != 2)
		return;

	static pOwner;
	pOwner = pev(this, pev_owner);

	if (!(1 <= pOwner <= g_iMaxPlayers) || !is_user_alive(pOwner))
		return;

	if (pev(this, pev_movetype) != MOVETYPE_PUSHSTEP)
	{
		static iBody, Float:vecColor[3], Float:vecOrigin[3], Float:vecAngles[3];

		GetOriginAimEndEyes(pOwner, 128, vecOrigin, vecAngles);
		iBody = 0;
		xs_vec_set(vecColor, 0.0, 150.0, 0.0);

		engfunc(EngFunc_SetOrigin, this, vecOrigin);

		vecOrigin[2] += 70.0;

		if (/*!IsOnGround(this) || */!IsHullVacant(vecOrigin, HULL_HEAD, this))
		{
			iBody = 1;
			xs_vec_set(vecColor, 150.0, 0.0, 0.0);
		}

		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
		{
			Beam_RelinkBeam(g_pBeam[pOwner]);
			Beam_SetColor(g_pBeam[pOwner], vecColor);
		}

		set_pev(this, pev_angles, vecAngles);
		set_pev(this, pev_body, iBody);
		set_pev(this, pev_nextthink, get_gametime() + 0.01);

		return;
	}

	static bitsButton;
	bitsButton = pev(pOwner, pev_button);
	
	if (bitsButton & IN_ATTACK2)
	{
		client_cmd(pOwner, "spk buttons/blip1.wav");

		if (!CheckPlayerBit(g_fViewEntCar, pOwner))
		{
			attach_view(pOwner, g_pTriggerCam);
			SetPlayerBit(g_fViewEntCar, pOwner);
		}
		else
		{
			attach_view(pOwner, pOwner);
			ClearPlayerBit(g_fViewEntCar, pOwner);
		}

		set_pev(this, pev_nextthink, get_gametime() + 0.2);
		return;
	}
	
	if (!CheckPlayerBit(g_fViewEntCar, pOwner))
		bitsButton = 0;

	if (bitsButton & IN_ATTACK)
	{
		new Float:vecOrigin[3];
		pev(this, pev_origin, vecOrigin);

		remove_entity(this);
		ExplosionCreate(pOwner, vecOrigin);

		return;
	}

	static Float:flSpeed, bool:bOnGround, Float:vecAngles[3], Float:vecSrc[3], Float:flGameTime;

	pev(this, pev_angles, vecAngles);
	pev(this, pev_origin, vecSrc);
	flGameTime = get_gametime();
	bOnGround = IsOnGround(this);

	if (!flSpeed)
	{
		static Float:vecVelocity[3];
		pev(this, pev_velocity, vecVelocity);
		flSpeed = vector_length(vecVelocity);
	}

	static Float:d;
	d = vecAngles[1] - g_vecAngles[pOwner][1];

	if (d > 180.0)
		d -= 360.0;
	else if (d < -180.0)
		d += 360.0;

	g_vecAngles[pOwner][1] += d * 0.15;

	ValidateAngles(g_vecAngles[pOwner][1]);
	

				
	
				
	new szClassName[32];
	pev(this, pev_classname, szClassName, charsmax(szClassName));

	if (equal(szClassName, "func_ladder"))
	{
                static Float:vecGoal[3], Float:vecVelocity[3], Float:vecForward[3];

	        if (pev(g_pCar[this], pev_movetype) != MOVETYPE_FLY)
		return;
	        if (bitsButton & IN_FORWARD)
	        {
		flSpeed = floatmin(flSpeed + 28.0, 350.0);

		xs_vec_mul_scalar(vecForward, 0.05, vecVelocity);
		xs_vec_add(vecSrc, vecVelocity, vecGoal);
		engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

		pev(this, pev_velocity, vecVelocity);
		xs_vec_mul_scalar(vecForward, flSpeed, vecVelocity);
		set_pev(this, pev_velocity, vecVelocity);
	}
	}
	
	
	


	if(bOnGround)
	{
	if(!pev( this , pev_waterlevel ))
	{
	g_bIsJumping[pOwner] = false;

	SetGroundAngles(this);

	static Float:vecGoal[3], Float:vecVelocity[3], Float:vecForward[3];

		//bitsButton = pev(pOwner, pev_button);
	pev(this, pev_angles, vecAngles);

	engfunc(EngFunc_MakeVectors, vecAngles);
	global_get(glb_v_forward, vecForward);

	vecForward[2] *= -1.0;

	if (bitsButton & IN_FORWARD)
	{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, 0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
	}
	else if (bitsButton & IN_BACK)
	{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, -0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, -1.0 * flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
	}

	if (bitsButton & (IN_MOVELEFT|IN_LEFT))
	{
			vecAngles[1] += 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
	}
	else if (bitsButton & (IN_MOVERIGHT|IN_RIGHT))
	{
			vecAngles[1] -= 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
	}

	if (bitsButton & IN_JUMP)
	{
			pev(this, pev_velocity, vecVelocity);
			vecVelocity[2] = 300.0;
			set_pev(this, pev_velocity, vecVelocity);

			g_bIsJumping[pOwner] = true;
	}
	
	}
	}

	else if (g_bIsJumping[pOwner])
	{
		static Float:vecVelocity[3], Float:vecForward[3];

		bitsButton = pev(pOwner, pev_button);
		pev(this, pev_angles, vecAngles);
		pev(this, pev_velocity, vecVelocity);

		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecForward);

		if (bitsButton & IN_FORWARD)
		{
			vecVelocity[0] = vecForward[0] * 270.0;
			vecVelocity[1] = vecForward[1] * 270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
		else if (bitsButton & IN_BACK)
		{
			vecVelocity[0] = vecForward[0] * -270.0;
			vecVelocity[1] = vecForward[1] * -270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
	}
	
	
	
	if(pev( this , pev_waterlevel ))
	{
	g_bIsJumping[pOwner] = false;

	SetGroundAngles(this);

	static Float:vecGoal[3], Float:vecVelocity[3], Float:vecForward[3];

		//bitsButton = pev(pOwner, pev_button);
	pev(this, pev_angles, vecAngles);

	engfunc(EngFunc_MakeVectors, vecAngles);
	global_get(glb_v_forward, vecForward);

	vecForward[2] *= -1.0;

	if (bitsButton & IN_FORWARD)
	{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, 0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
	}
	else if (bitsButton & IN_BACK)
	{
			flSpeed = floatmin(flSpeed + 28.0, 350.0);

			xs_vec_mul_scalar(vecForward, -0.05, vecVelocity);
			xs_vec_add(vecSrc, vecVelocity, vecGoal);
			engfunc(EngFunc_MoveToOrigin, this, vecGoal, vector_distance(vecSrc, vecGoal), 1);

			pev(this, pev_velocity, vecVelocity);
			xs_vec_mul_scalar(vecForward, -1.0 * flSpeed, vecVelocity);
			set_pev(this, pev_velocity, vecVelocity);
	}

	if (bitsButton & (IN_MOVELEFT|IN_LEFT))
	{
			vecAngles[1] += 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
	}
	else if (bitsButton & (IN_MOVERIGHT|IN_RIGHT))
	{
			vecAngles[1] -= 4.0;
			ValidateAngles(vecAngles[1]);
			set_pev(this, pev_angles, vecAngles);
	}

	if (bitsButton & IN_JUMP)
	{
			pev(this, pev_velocity, vecVelocity);
			vecVelocity[2] = 300.0;
			set_pev(this, pev_velocity, vecVelocity);

			g_bIsJumping[pOwner] = true;
	}
	
	if (bitsButton & IN_DUCK)
	{
		pev(this, pev_velocity, vecVelocity);
		vecVelocity[2] -= 100.0;
		set_pev(this, pev_velocity, vecVelocity);
	}
	}

	if (g_bIsJumping[pOwner] && pev( this , pev_waterlevel ))
	{
		static Float:vecVelocity[3], Float:vecForward[3];

		bitsButton = pev(pOwner, pev_button);
		pev(this, pev_angles, vecAngles);
		pev(this, pev_velocity, vecVelocity);

		engfunc(EngFunc_MakeVectors, vecAngles);
		global_get(glb_v_forward, vecForward);

		if (bitsButton & IN_FORWARD)
		{
			vecVelocity[0] = vecForward[0] * 270.0;
			vecVelocity[1] = vecForward[1] * 270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
		else if (bitsButton & IN_BACK)
		{
			vecVelocity[0] = vecForward[0] * -270.0;
			vecVelocity[1] = vecForward[1] * -270.0;

			set_pev(this, pev_velocity, vecVelocity);
		}
	}
	

	

	if (!get_speed(this) || !bOnGround)

	{
		if( !pev( this , pev_waterlevel ))
		{
		flSpeed = 0.0;
		
		static Float:flFrameRate;
		pev(this, pev_framerate, flFrameRate);

		if (flFrameRate != 0.0)
		{
			set_pev(this, pev_framerate, 0.0);
			set_pev(this, pev_animtime, 0.0);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
		}
		}
	}
	else
	{
		if( !pev( this , pev_waterlevel ))
		{
		static Float:flSoundTime;
		pev(this, pev_ltime, flSoundTime);

		if (flGameTime - flSoundTime > 1.0)
		{
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, 0, PITCH_NORM);
			SetAnim(this, 0, 1.0);
			set_pev(this, pev_ltime, flGameTime);
		}
		}
	}
	
	if (!get_speed(this))
	{
		if(pev( this , pev_waterlevel ))
		{
		flSpeed = 0.0;
		
		static Float:flFrameRate;
		pev(this, pev_framerate, flFrameRate);

		if (flFrameRate != 0.0)
		{
			set_pev(this, pev_framerate, 0.0);
			set_pev(this, pev_animtime, 0.0);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
		}
		}
	}
	else
	{
		if(pev( this , pev_waterlevel ))
		{
		static Float:flSoundTime;
		pev(this, pev_ltime, flSoundTime);

		if (flGameTime - flSoundTime > 1.0)
		{
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
			emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, 0, PITCH_NORM);
			SetAnim(this, 0, 1.0);
			set_pev(this, pev_ltime, flGameTime);
		}
		}
	}

	set_pev(this, pev_nextthink, flGameTime + 0.02);
}

SetGroundAngles(this)
{
	static tr, Float:vecSrc[3], Float:vecEnd[3], Float:flFraction;

	pev(this, pev_origin, vecSrc);
	vecSrc[2] += 10.0;
	xs_vec_sub(vecSrc, Float:{0.0, 0.0, 20.0}, vecEnd);

	tr = create_tr2();

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, tr);
	get_tr2(tr, TR_flFraction, flFraction);

	if (flFraction < 1.0)
	{
		static Float:vecPlaneNormal[3], Float:vecForward[3], Float:vecRight[3], Float:vecAngles[3];

		pev(this, pev_angles, vecAngles);
		angle_vector(vecAngles, ANGLEVECTOR_FORWARD, vecForward);

		get_tr2(tr, TR_vecPlaneNormal, vecPlaneNormal);

		xs_vec_cross(vecForward, vecPlaneNormal, vecRight);
		xs_vec_cross(vecPlaneNormal, vecRight, vecForward);

		static Float:flPitch, Float:vecAngles2[3];

		flPitch = vecAngles[1];
	
		vector_to_angle(vecForward, vecAngles);
		vector_to_angle(vecRight, vecAngles2);

		vecAngles[1] = flPitch;
		vecAngles[2] = -1.0 * vecAngles2[0];

		set_pev(this, pev_angles, vecAngles);
	}

	free_tr2(tr);
	return 1;
}

ValidateAngles(&Float:angles)
{
	if (angles > 360.0)
		angles -= 360.0;
	if (angles < 0.0)
		angles += 360.0;
}

public CBasePlayer_Killed(this)
{
	if (g_pCar[this] && pev_valid(g_pCar[this]))
		remove_entity(g_pCar[this]);
}

public CBasePlayer_UpdateData_Post(this)
{
	if (!is_user_alive(this))
		return;

	if (!g_pCar[this] || pev_valid(g_pCar[this]) != 2 || pev_valid(g_pTriggerCam) != 2)
		return;

	if (pev(g_pCar[this], pev_movetype) != MOVETYPE_PUSHSTEP)
		return;

	static Float:vecSrc[3], Float:vecEnd[3], Float:vecAngles[3], Float:vec[3];

	pev(g_pCar[this], pev_origin, vecSrc);

	g_vecOrigin[this][0] += (vecSrc[0] - g_vecOrigin[this][0]) * 0.14;
	g_vecOrigin[this][1] += (vecSrc[1] - g_vecOrigin[this][1]) * 0.14;
	g_vecOrigin[this][2] += (vecSrc[2] - g_vecOrigin[this][2]) * 0.14;

	xs_vec_copy(g_vecOrigin[this], vecSrc);
	xs_vec_copy(g_vecAngles[this], vecAngles)

	engfunc(EngFunc_MakeVectors, vecAngles);
	global_get(glb_v_forward, vec);

	vecEnd[0] = vecSrc[0] + ((vec[0] * 100.0) * -1);
	vecEnd[1] = vecSrc[1] + ((vec[1] * 100.0) * -1);
	vecEnd[2] = vecSrc[2] + ((vec[2] * 100.0) * -1) + 45.0;

	static Float:flFraction;
	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, g_pCar[this], 0);
	get_tr2(0, TR_flFraction, flFraction);

	if (flFraction < 1.0)
		get_tr2(0, TR_vecEndPos, vecEnd);

	engfunc(EngFunc_SetOrigin, g_pTriggerCam, vecEnd);


	set_pev(g_pTriggerCam, pev_angles, vecAngles);
}

public OnFreeEntPrivateData(this)
{
	if (!FClassnameIs(this, RC_CLASSNAME))
		return FMRES_IGNORED;

	new pOwner = pev(this, pev_owner);

	if ((1 <= pOwner <= g_iMaxPlayers))
	{
		if (is_user_connected(pOwner))
		{
			cs_set_player_maxspeed_auto(pOwner, g_flMaxSpeed[pOwner]);
			attach_view(pOwner, pOwner);
		}

		if (g_pBeam[pOwner] && is_valid_ent(g_pBeam[pOwner]))
			remove_entity(g_pBeam[pOwner]);

		g_pCar[pOwner] = 0;
		g_pBeam[pOwner] = 0;
		ClearPlayerBit(g_fViewEntCar, pOwner);
	}

	emit_sound(this, CHAN_ITEM, RC_SOUND, 0.35, ATTN_NORM, SND_STOP, PITCH_NORM);
	set_pev(this, pev_framerate, 0.0);

	return FMRES_IGNORED;
}

FClassnameIs(this, const szClassName[])
{
	if (pev_valid(this) != 2)
		return 0;

	new szpClassName[32];
	pev(this, pev_classname, szpClassName, charsmax(szpClassName));

	return equal(szClassName, szpClassName);
}

ExplosionCreate(this, Float:vecOrigin[3])
{
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecOrigin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecOrigin[0])
	engfunc(EngFunc_WriteCoord, vecOrigin[1])
	engfunc(EngFunc_WriteCoord, vecOrigin[2] + 32)
	write_short(explosion)
	write_byte(60)
	write_byte(30)
	write_byte(10)
	message_end()
	/*
	new AuthID[32]
	new isEmma,isNala;	
	get_user_authid(this ,AuthID,31)
	if(equali(AuthID,"STEAM_0:0:555283776"))
	{
		isEmma=true;
	}
	else
	if(equali(AuthID,"STEAM_0:0:2055819299"))
	{
		isNala=true
	}
	*/
	
	new Float:PlayerPos[3], Float:distance, Float:damage
	
	for (new i = 1; i < 33; i++) 
	{
		if(!is_user_connected(i))
			continue;
		if(!is_user_alive(i)) 
			continue;		
		
		pev(i, pev_origin, PlayerPos)
		
		distance = get_distance_f(PlayerPos, vecOrigin)
		if (distance <= get_pcvar_num(rc_radius))
		{
			new FinalDamage
			damage = float(2500) - distance
			new attacker = this		
			if(zp_item_zombie_madness_get(i))
				FinalDamage = floatround(damage / 3)
			else
				FinalDamage = floatround(damage)
				
			if (zp_core_is_zombie(i))
			{				
				if(zp_grenade_frost_get(i))
				zp_grenade_frost_set(i, false)
                                const DMG_GRENADE = 1<<24
				ExecuteHam(Ham_TakeDamage, i, 0, attacker, float(FinalDamage), DMG_GRENADE)		
				bd_show_damage(attacker, FinalDamage, 0, 1)
				bd_show_damage(i, FinalDamage, 1, 0)
				if(is_user_alive(i))
				{
					new Float:Power = (damage - distance) / 3.0
					new Float:zKnockback = 1.0
					KnockbackPlayer(i, vecOrigin, zKnockback, distance, Power, 2)
				}
			}

		}
	}
/*
	new pExplosion = create_entity("env_explosion");

	if (!pExplosion)
		return;

	engfunc(EngFunc_SetOrigin, pExplosion, vecOrigin);
	set_pev(pExplosion, pev_classname, RCEXP_CLASSNAME);
	set_pev(pExplosion, pev_owner, pOwner);
	set_pev(pExplosion, pev_dmg, flMultiplier);

	if (!bDoDamage)
		set_pev(pExplosion, pev_spawnflags, pev(pExplosion, pev_spawnflags) | SF_ENVEXPLOSION_NODAMAGE);

	new szMagnitude[22];
	formatex(szMagnitude, charsmax(szMagnitude), "%3d", iMagnitude);

	DispatchKeyValue(pExplosion, "iMagnitude", szMagnitude);
	DispatchSpawn(pExplosion);
	force_use(pExplosion, pExplosion);
*/
}


stock KnockbackPlayer(ent, Float:VicOrigin[3], Float:speed, Float:distance, Float:Minus, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	
	new Float:fl_Time = distance / speed
	if (type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time)// * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time)// * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time	
	}
	else if (type == 2)
	{
		if(distance > 100.0)
		{
			fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0])) * Minus
			fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1])) * Minus
			fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) * Minus
		}
		else
		{
			fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0])) * Minus * 2.0
			fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1])) * Minus * 2.0
			fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) * Minus * 2.0
		}	
	}
	
	set_pev(ent, pev_velocity, fl_Velocity)
}
SetAnim(this, iAnim, Float:flFrameRate)
{
	set_pev(this, pev_sequence, iAnim);
	set_pev(this, pev_frame, 0.0);
	set_pev(this, pev_animtime, get_gametime());
	set_pev(this, pev_framerate, flFrameRate);
}

bool:IsOnGround(this)
{
	static Float:vecSrc[3], Float:vecEnd[3];
	pev(this, pev_origin, vecSrc);
	xs_vec_sub(vecSrc, Float:{ 0.0, 0.0, 10.0 }, vecEnd);

	engfunc(EngFunc_TraceLine, vecSrc, vecEnd, IGNORE_MONSTERS, this, 0);

	static Float:flFraction;
	get_tr2(0, TR_flFraction, flFraction);

	if (!(pev(this, pev_flags) & FL_ONGROUND) && flFraction == 1.0)
		return false;

	return true;
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

		xs_vec_mul_scalar(vecPlaneNormal, 8.0, vecPlaneNormal);
		xs_vec_add(vecOut, vecPlaneNormal, vecOut);
	}
	else
	{
		xs_vec_copy(vecEnd, vecOut);
	}

	vecVelocity[2] = 0.0;
	vector_to_angle(vecVelocity, vecAngles);
}

/*
public tport(teleporter)

{
    teleporter = engfunc(EngFunc_FindEntityByString, teleporter, "classname","trigger_teleport")

    if(is_valid_ent(teleporter) && !is_user_alive(teleporter))
        entity_set_int(teleporter, EV_INT_solid, SOLID_NOT);
}

*/ 