/*================================================================================
	
	--------------------------------
	-*- [ZP] Rewards: Ammo Packs -*-
	--------------------------------
	
	This plugin is part of Zombie Plague Mod and is distributed under the
	terms of the GNU General Public License. Check ZP_ReadMe.txt for details.
	
================================================================================*/

#include <amxmodx>
#include <amxmisc>
#include <hamsandwich>
#include <cs_ham_bots_api>
#include <zombieplague>
#include <zp50_gamemodes>
#define LIBRARY_NEMESIS "zp50_class_nemesis"
#include <zp50_class_nemesis>
#define LIBRARY_ASSASSIN "zp50_class_assassin"
#include <zp50_class_assassin>
#define LIBRARY_SURVIVOR "zp50_class_survivor"
#include <zp50_class_survivor>
#define LIBRARY_SNIPER "zp50_class_sniper"
#include <zp50_class_sniper>
#include <zp50_ammopacks>
#include <dhudmessage>

#define MAXPLAYERS 32

new g_MaxPlayers

new const Float:g_flCoords[] = {-0.10, -0.15, -0.20}
new g_iPos[33]

new gPoints
new bool:isDoubleXP;


new PointPerKill[][] =
{
	"1", "1", "1", "1"
}
new PointsPerInfect[][] =
{
	"0", "5", "4", "3", "2", "1"
}

new Damage2Points[][] =
{
	"0", "500", "750", "1250", "1500", "2000", "2500", "3000"
}

new PointsRange[][] =
{
	"0", "2000", "10000", "14500", "35000", "40000", "50000", "9999999"
}
new iPointsPerKl[33], iPointsPerInf[33], iPoitsPerDm[33]


new Float:g_DamageDealtToZombies[MAXPLAYERS+1]
new Float:g_DamageDealtToHumans[MAXPLAYERS+1]


new cvar_ammop_winner, cvar_ammop_loser
new cvar_ammop_damage, cvar_ammop_human_damaged_hp
new cvar_ammop_zombie_killed, cvar_ammop_human_killed
new cvar_ammop_zombie_damaged_hp
new cvar_ammop_nemesis_ignore, cvar_ammop_survivor_ignore
new cvar_ammop_assassin_ignore, cvar_ammop_sniper_ignore


public plugin_init()
{
	register_plugin("[ZP] Rewards: Ammo Packs", ZP_VERSION_STRING, "ZP Dev Team")
	
	cvar_ammop_winner = register_cvar("zp_ammop_winner", "3")
	cvar_ammop_loser = register_cvar("zp_ammop_loser", "0")
	cvar_ammop_zombie_damaged_hp = register_cvar("zp_ammop_zombie_damaged_hp", "500")
	cvar_ammop_damage = register_cvar("zp_ammop_damage", "1")
	cvar_ammop_zombie_killed = register_cvar("zp_ammop_zombie_killed", "1")
	cvar_ammop_human_damaged_hp = register_cvar("zp_ammop_human_damaged_hp", "750")
	cvar_ammop_human_killed = register_cvar("zp_ammop_human_killed", "1")
	
	// Nemesis Class loaded?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library))
		cvar_ammop_nemesis_ignore = register_cvar("zp_ammop_nemesis_ignore", "0")

	// Assassin Class loaded?
	if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library))
		cvar_ammop_assassin_ignore = register_cvar("zp_ammop_assassin_ignore", "0")
	
	// Survivor Class loaded?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library))
		cvar_ammop_survivor_ignore = register_cvar("zp_ammop_survivor_ignore", "0")

	// Sniper Class loaded?
	if (LibraryExists(LIBRARY_SNIPER, LibType_Library))
		cvar_ammop_sniper_ignore = register_cvar("zp_ammop_sniper_ignore", "0")
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHamBots(Ham_TakeDamage, "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHamBots(Ham_Killed, "fw_PlayerKilled_Post", 1)
	
	g_MaxPlayers = get_maxplayers()
}


public plugin_natives()
{
	set_module_filter("module_filter")
	set_native_filter("native_filter")
}
public module_filter(const module[])
{
	if (equal(module, LIBRARY_NEMESIS) || equal(module, LIBRARY_ASSASSIN) || equal(module, LIBRARY_SURVIVOR) || equal(module, LIBRARY_SNIPER))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
public native_filter(const name[], index, trap)
{
	if (!trap)
		return PLUGIN_HANDLED;
		
	return PLUGIN_CONTINUE;
}



// Ham Take Damage Post Forward
public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Non-player damage or self damage
	if (victim == attacker || !is_user_alive(attacker))
		return;
	
	// Ignore ammo pack rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_ammop_nemesis_ignore))
		return;

	// Ignore ammo pack rewards for Assassin?
	if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(attacker) && get_pcvar_num(cvar_ammop_assassin_ignore))
		return;
	
	// Ignore ammo pack rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_ammop_survivor_ignore))
		return;

	// Ignore ammo pack rewards for Sniper?
	if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(attacker) && get_pcvar_num(cvar_ammop_sniper_ignore))
		return;
	
	if(zp_gamemodes_get_current() == zp_gamemodes_get_id("Zombie Tag Mode"))
		return;
		
	// Zombie attacking human...
	if (zp_core_is_zombie(attacker) && !zp_core_is_zombie(victim))
	{
		// Reward ammo packs to zombies for damaging humans?
		if (get_pcvar_num(cvar_ammop_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToHumans[attacker] += damage
                        
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToHumans[attacker] / get_pcvar_float(cvar_ammop_human_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + (get_pcvar_num(cvar_ammop_damage) * how_many_rewards))
				
				new iPos = ++g_iPos[attacker]
				if(iPos == sizeof(g_flCoords))
				{
					iPos = g_iPos[attacker] = 0
				}
				set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
				new idk = get_pcvar_num(cvar_ammop_human_damaged_hp) * how_many_rewards
				show_dhudmessage(attacker, "+%d point%s [DMG]", idk, idk > 1 ? "s" : "")
				g_DamageDealtToHumans[attacker] -= get_pcvar_float(cvar_ammop_human_damaged_hp) * how_many_rewards
			}
		}
	}
	// Human attacking zombie...
	else if (!zp_core_is_zombie(attacker) && zp_core_is_zombie(victim))
	{
		// Reward ammo packs to humans for damaging zombies?
		if (get_pcvar_num(cvar_ammop_damage) > 0)
		{
			// Store damage dealt
			g_DamageDealtToZombies[attacker] += damage
			
			// Give rewards according to damage dealt
			new how_many_rewards = floatround(g_DamageDealtToZombies[attacker] / get_pcvar_float(cvar_ammop_zombie_damaged_hp), floatround_floor)
			if (how_many_rewards > 0)
			{
				zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + (get_pcvar_num(cvar_ammop_damage) * how_many_rewards))
				new iPos = ++g_iPos[attacker]
				if(iPos == sizeof(g_flCoords))
				{
					iPos = g_iPos[attacker] = 0
				}
				set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
				new idk = get_pcvar_num(cvar_ammop_damage) * how_many_rewards
				show_dhudmessage(attacker, "+%d point%s [DMG]", idk, idk > 1 ? "s" : "")
				g_DamageDealtToZombies[attacker] -= get_pcvar_float(cvar_ammop_zombie_damaged_hp) * how_many_rewards
			}
		}
	}
}

// Ham Player Killed Post Forward
public fw_PlayerKilled_Post(victim, attacker, shouldgib)
{
	// Non-player kill or self kill
	if (victim == attacker || !is_user_connected(attacker))
		return;
	
	// Ignore ammo pack rewards for Nemesis?
	if (LibraryExists(LIBRARY_NEMESIS, LibType_Library) && zp_class_nemesis_get(attacker) && get_pcvar_num(cvar_ammop_nemesis_ignore))
		return;

	// Ignore ammo pack rewards for Assassin?
	if (LibraryExists(LIBRARY_ASSASSIN, LibType_Library) && zp_class_assassin_get(attacker) && get_pcvar_num(cvar_ammop_assassin_ignore))
		return;
	
	// Ignore ammo pack rewards for Survivor?
	if (LibraryExists(LIBRARY_SURVIVOR, LibType_Library) && zp_class_survivor_get(attacker) && get_pcvar_num(cvar_ammop_survivor_ignore))
		return;

	// Ignore ammo pack rewards for Sniper?
	if (LibraryExists(LIBRARY_SNIPER, LibType_Library) && zp_class_sniper_get(attacker) && get_pcvar_num(cvar_ammop_sniper_ignore))
		return;
	
	if(zp_gamemodes_get_current() == zp_gamemodes_get_id("Zombie Tag Mode"))
		return;
		
	// Reward ammo packs to attacker for the kill
	if (zp_core_is_zombie(victim))
	{
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + get_pcvar_num(cvar_ammop_zombie_killed))

		new iPos = ++g_iPos[attacker]
		if(iPos == sizeof(g_flCoords))
		{
			iPos = g_iPos[attacker] = 0
		}
		set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
                new idk = get_pcvar_num(cvar_ammop_zombie_killed)
		show_dhudmessage(attacker, "+%d point%s [KILL]", idk, idk > 1 ? "s" : "")
	}
	else
	{
		zp_ammopacks_set(attacker, zp_ammopacks_get(attacker) + get_pcvar_num(cvar_ammop_human_killed))


		new iPos = ++g_iPos[attacker]
		if(iPos == sizeof(g_flCoords))
		{
			iPos = g_iPos[attacker] = 0
		}
		set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
                new idk = get_pcvar_num(cvar_ammop_human_killed)
		show_dhudmessage(attacker, "+%d point%s [KILL]", idk, idk > 1 ? "s" : "")
	}
}



public CheckUserPoints(id)
{
	gPoints = zp_ammopacks_get(id)
	if(gPoints <= str_to_num(PointsRange[1]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[1])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[1])
		iPoitsPerDm[id] = str_to_num(Damage2Points[1])
	}
	else if(gPoints <= str_to_num(PointsRange[2]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[1])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[2])
		iPoitsPerDm[id] = str_to_num(Damage2Points[2])
	}
	else if(gPoints <= str_to_num(PointsRange[3]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[2])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[2])
		iPoitsPerDm[id] = str_to_num(Damage2Points[3])
	}
	else if(gPoints <= str_to_num(PointsRange[4]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[2])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[3])
		iPoitsPerDm[id] = str_to_num(Damage2Points[4])
	}
	else if(gPoints <= str_to_num(PointsRange[5]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[3])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[3])
		iPoitsPerDm[id] = str_to_num(Damage2Points[5])
	}
	else if(gPoints <= str_to_num(PointsRange[6]))
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[3])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[4])
		iPoitsPerDm[id] = str_to_num(Damage2Points[6])
	}
	else
	{
		iPointsPerKl[id] = str_to_num(PointPerKill[3])
		iPointsPerInf[id] = str_to_num(PointsPerInfect[5])
		iPoitsPerDm[id] = str_to_num(Damage2Points[7])
	}
}

public zp_fw_gamemodes_end()
{
	// Determine round winner and money rewards
	if (!zp_core_get_zombie_count())
	{
		// Human team wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			if (zp_core_is_zombie(id))
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
			else
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_winner))
		}
	}
	else if (!zp_core_get_human_count())
	{
		// Zombie team wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			if (zp_core_is_zombie(id))
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_winner))
			else
				zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
		}
	}
	else
	{
		// No one wins
		new id
		for (id = 1; id <= g_MaxPlayers; id++)
		{
			if (!is_user_connected(id))
				continue;
			
			zp_ammopacks_set(id, zp_ammopacks_get(id) + get_pcvar_num(cvar_ammop_loser))
		}
	}
}

public client_putinserver(id)
	CheckUserPoints(id)


public zp_fw_core_infect_post(victim, killer)
{
	if(!is_user_connected(killer))
		return;
	if(!is_user_connected(victim))
		return;
	if(zp_gamemodes_get_current() == zp_gamemodes_get_id("Zombie Tag Mode"))
		return;
		
	gPoints = zp_ammopacks_get(killer)
	if(killer != victim)
	{
		new iPos = ++g_iPos[killer]
		if(iPos == sizeof(g_flCoords))
		{
			iPos = g_iPos[killer] = 0
		}
		set_dhudmessage(0, 255, 0, -1.0, g_flCoords[iPos], 0, 0.0, 2.2, 2.0, 1.0)
                new idk = (iPointsPerInf[killer])
		if(!isDoubleXP)
		{			
			
			zp_ammopacks_set(killer, gPoints + iPointsPerInf[killer])
                        show_dhudmessage(killer, "+%d point%s [Infect]", idk, idk > 1 ? "s" : "")
		}
		else
		{
			
			zp_ammopacks_set(killer, gPoints + 2*iPointsPerInf[killer])
                        show_dhudmessage(killer, "+%d point%s [Infect]", idk, idk > 1 ? "s" : "")
		}
		CheckUserPoints(killer)
	}
}

public client_disconnect(id)
{
	// Clear damage after disconnecting
	g_DamageDealtToZombies[id] = 0.0
	g_DamageDealtToHumans[id] = 0.0
}
