#include <amxmodx> 
#include <amxmisc> 
#include <cstrike>
#include <fun> 
#include <hamsandwich> 
#include <engine> 
#include <fakemeta> 
#include <fakemeta_util> 
#include <zombieplague> 
#include <zp50_items>
#include <xs>

#define NAME              "[ZP] Extra Item : Thunder awp" 
#define VERSION                          "2.0" 
#define CREATOR                       "lucas_7_94 & teNsk" 


#define V_MODEL "models/v_awp_zop_thunder.mdl"
#define P_MODEL "models/p_awp_zop_thunder.mdl"
#define W_MODEL "models/w_awp_zop_thunder.mdl"

#define OLD_W_MODEL "models/w_awp.mdl"


// Put The Cost For The Plugin 
new const g_thunder_cost = 25 

/*==========Customization==========*/ 
new bool: g_HasThunderCarabine[33] 
//new bool:g_HasDMG[33]
new Thunder, g_thunder, g_maxplayers
new cvar_carbine_damage 
new cvar_say, cvar_sounds 
new cvar_round_started, cvar_logs, cvar_reset_round
/*===== End Customization ======*/ 

new g_msgWeaponList;

#define is_valid_player(%1) (1 <= %1 <= g_maxplayers) // Thanks You meTaLicross's gauss. =D 

#define WEAPON_BITSUM ((1<<CSW_AWP))


public plugin_init() 
{ 
    register_plugin(NAME, VERSION, CREATOR) 
	
    // Register the Plugin =D 
    g_thunder = zp_register_extra_item("Thunder AWP \r(Thunder Damage)", g_thunder_cost, ZP_TEAM_HUMAN); 
   
    g_msgWeaponList = get_user_msgid( "WeaponList" );
    g_maxplayers = get_maxplayers()
	
		
    register_forward(FM_SetModel, "fw_SetModel")
   
    RegisterHam(Ham_Item_AddToPlayer, "weapon_awp", "fw_AddToPlayer", 1);
    RegisterHam(Ham_Item_Deploy, "weapon_awp", "fw_Item_Deploy_Post", 1)
    RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage") 
    RegisterHam(Ham_Killed, "player", "fw_PlayerKilled") 
    RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post")

     
    // Cvars For Item 
    cvar_say = register_cvar("zp_thunder_says", "0") 
    cvar_sounds = register_cvar("zp_thunder_sounds", "1") 
    cvar_logs = register_cvar("zp_thunder_logs", "0") 
    cvar_round_started = register_cvar("zp_thunder_buy_started", "0") 
    cvar_carbine_damage = register_cvar("zp_thunder_damage", "3.9") 
    cvar_reset_round = register_cvar("zp_thunder_reset_round", "1")      
} 

public ClientCommand_SelectFlare( const client ) 
{ 
    engclient_cmd( client, "weapon_awp" ); 
}
public plugin_precache() 
{ 
   Thunder = precache_model("sprites/lgtning.spr"); 
   precache_sound( "ambience/thunder_clap.wav" ) 
   engfunc(EngFunc_PrecacheModel, V_MODEL)
   engfunc(EngFunc_PrecacheModel, P_MODEL)
   engfunc(EngFunc_PrecacheModel, W_MODEL)
   precache_generic("sprites/zop_thunder.spr")
   precache_generic("sprites/ch_zod_thunder_awp.spr")
   precache_generic("sprites/ch_zod_thunder_awp_v2.spr")
   precache_generic("sprites/ch_zod_thunder_awp_v2x.spr")
   precache_generic("sprites/weapon_thunder_awp.txt")
   
   register_clcmd( "weapon_thunder_awp", "ClientCommand_SelectFlare" );
} 


public zp_user_humanized_post(id) g_HasThunderCarabine[id] = false

public event_round_start()
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if(get_pcvar_num(cvar_reset_round))
			g_HasThunderCarabine[i] = false
	}
}



public zp_extra_item_selected(player, itemid) 
{ 
    if (itemid == g_thunder)
    
    { 
            if(get_pcvar_num(cvar_round_started) == 1) 
            { 
                if (!zp_has_round_started())
                { 
                    Color(player, "^x04ZoD *|^x01 You need to buy this item after the start of the round.") 
                    zp_set_user_ammo_packs(player, zp_get_user_ammo_packs(player) + g_thunder_cost) 
                     
                    return; 
                } 
            } 
            else 
            { 
                g_HasThunderCarabine[player] = true  
                fm_give_item(player, "weapon_awp") 
                cs_set_user_bpammo(player, CSW_AWP, 30)
                Color(player, "^x04ZoD*|^x01 You have purchased a Thunder Awp") 
            } 
    } 
} 

public fw_Item_Deploy_Post(pEntity)
{
   static pPlayer;
   pPlayer = get_pdata_cbase(pEntity, 41, 4);

   if(pev_valid(pPlayer) && g_HasThunderCarabine[pPlayer])
   {	
		
      set_pev(pPlayer, pev_viewmodel2, V_MODEL)
      set_pev(pPlayer, pev_weaponmodel2, P_MODEL)
	
   }
}


public fw_AddToPlayer(ent, id)
{
	if (!pev_valid(ent))
		return HAM_IGNORED;

	if (!is_user_connected(id))
		return HAM_IGNORED;

	if (pev(ent, pev_impulse) == 99989)
	{
		g_HasThunderCarabine[id] = true;
		set_pev(ent, pev_impulse, 0);
	}
	
	message_begin(MSG_ONE, g_msgWeaponList, _, id)
	write_string((g_HasThunderCarabine[id] ? "weapon_thunder_awp" : "weapon_awp"))
	write_byte(1)
	write_byte(30)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(2)
	write_byte(18)
	write_byte(0)
	message_end()
	
	return HAM_IGNORED;
} 

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_AWP)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_HasThunderCarabine[id])
		{
			set_pev(weapon, pev_impulse, 99989)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			g_HasThunderCarabine[id] = false;
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type, tracehandle)
{
	if(is_user_alive(attacker) && attacker != victim)
	{
		if(g_HasThunderCarabine[attacker] && (get_user_weapon(attacker) == CSW_AWP))
			SetHamParamFloat(4, damage * get_pcvar_num(cvar_carbine_damage))	
	}
}
public fw_TraceAttack_Post(this, idattacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
    if (GetHamReturnStatus() == HAM_SUPERCEDE)
        return

    if (!is_valid_player(idattacker))
        return

    if (!zp_get_user_zombie(this))
        return

    if (!g_HasThunderCarabine[idattacker])
        return

    if (get_user_weapon(idattacker) != CSW_AWP)
        return

    if (!(damagebits & DMG_BULLET))
        return

    if (get_tr2(tracehandle, TR_iHitgroup) != HIT_HEAD)
        return

    new vorigin[3],srco[3]; 
    get_user_origin(this, vorigin); 
    vorigin[2] -= 26 
    srco[0] = vorigin[0] + 200	 
    srco[1] = vorigin[1] + 200 
    srco[2] = vorigin[2] + 950 

    ThunderCarabine(srco, vorigin)
    ThunderCarabine(srco, vorigin)
    ThunderCarabine(srco, vorigin)

    if(get_pcvar_num(cvar_sounds) == 1) 
    {
        emit_sound(this ,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM); 
        emit_sound(idattacker ,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM); 
    }
}

public fw_PlayerKilled(victim, attacker, shouldgib) 
{ 
    if(!zp_get_user_zombie(victim)) 
        return; 

    if(!is_valid_player(attacker)) 
        return; 
          
    static killername[33], victimname[33] 
    get_user_name(attacker, killername, 31) 
    get_user_name(victim, victimname, 31) 
    g_HasThunderCarabine[victim] = false; 
     
    new clip, ammo, wpnid = get_user_weapon(attacker, clip, ammo) 
     
    if(g_HasThunderCarabine[attacker] && wpnid == CSW_AWP) 
    { 
        new vorigin[3],srco[3]; 
        get_user_origin(victim, vorigin); 
        vorigin[2] -= 26 
        srco[0] = vorigin[0] + 150 
        srco[1] = vorigin[1] + 150 
        srco[2] = vorigin[2] + 800 
         
        set_user_rendering(victim, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 16); 
         
        ThunderCarabine(srco,vorigin); 
        ThunderCarabine(srco,vorigin); 
        ThunderCarabine(srco,vorigin);         
         
        if(get_pcvar_num(cvar_say) == 1) 
        { 
            Color(attacker, "^x04[Thunder Carabine]^x01 You've Removed to ^x04%s", victimname) 
            Color(victim, "^x04[Thunder Carabine]^x01 You have been eliminated by %s", killername) 
        } 
         
        if(get_pcvar_num(cvar_sounds) == 1) 
        { 
            emit_sound(victim ,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM); 
            emit_sound(attacker ,CHAN_ITEM, "ambience/thunder_clap.wav", 1.0, ATTN_NORM, 0, PITCH_NORM); 
        } 
        if(get_pcvar_num(cvar_logs) == 1) 
        { 
            // Save Hummiliation 
            new namea[24],namev[24],authida[20],authidv[20],teama[8],teamv[8] 
             
            // Info On Attacker 
            get_user_name(attacker,namea,23)  
            get_user_team(attacker,teama,7)  
            get_user_authid(attacker,authida,19) 
            new attackerid = get_user_userid(attacker) 
             
            // Info On Victim 
            get_user_name(victim,namev,23)  
            get_user_team(victim,teamv,7)  
            get_user_authid(victim,authidv,19) 
            new victimid = get_user_userid(victim) 
             
            // Log This Kill 
            log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"Thunder Carabine^"", namea, attackerid, authida, teama, namev, victimid, authidv, teamv) 
        } 
         
        if(g_HasThunderCarabine[victim]) 
        { 
            Color(victim, "^x04[ZoD*|] Thunder Carabine Is OFF") 
            g_HasThunderCarabine[victim] = false 
        } 
    } 
} 

ThunderCarabine(vec1[3],vec2[3]) 
{ 
    message_begin(MSG_BROADCAST,SVC_TEMPENTITY);  
    write_byte(0);  
    write_coord(vec1[0]);  
    write_coord(vec1[1]);  
    write_coord(vec1[2]);  
    write_coord(vec2[0]);  
    write_coord(vec2[1]);  
    write_coord(vec2[2]);  
    write_short(Thunder);  
    write_byte(2); 
    write_byte(5); 
    write_byte(8); 
    write_byte(20); 
    write_byte(30); 
    write_byte(200);  
    write_byte(200); 
    write_byte(200); 
    write_byte(200); 
    write_byte(200); 
    message_end(); 
     
    message_begin( MSG_PVS, SVC_TEMPENTITY,vec2);  
    write_byte(9);  
    write_coord(vec2[0]);  
    write_coord(vec2[1]);  
    write_coord(vec2[2]);  
    message_end(); 
     
} 


stock Color(const id, const input[], any:...) 
{ 
    new count = 1, players[32] 
    static msg[191] 
    vformat(msg, 190, input, 3) 
     
    replace_all(msg, 190, "^x04", "^4") // Green Color 
    replace_all(msg, 190, "^x01", "^1") // Default Color 
    replace_all(msg, 190, "!team", "^3") // Team Color 
    replace_all(msg, 190, "!team2", "^0") // Team2 Color 
     
    if (id) players[0] = id; else get_players(players, count, "ch") 
    { 
        for (new i = 0; i < count; i++) 
        { 
            if (is_user_connected(players[i])) 
            { 
                message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, players[i]) 
                write_byte(players[i]); 
                write_string(msg); 
                message_end(); 
            } 
        } 
    } 
} 

stock drop_primary(id)
{
	new weapons[32], num;
	get_user_weapons(id, weapons, num);
	for (new i = 0; i < num; i++)
	{
		if (WEAPON_BITSUM & (1<<weapons[i]))
		{
			static wname[32];
			get_weaponname(weapons[i], wname, sizeof wname - 1);
			engclient_cmd(id, "drop", wname);
		}
	}
}