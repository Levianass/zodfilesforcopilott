#include <amxmodx>
#include <fakemeta>
#include <zombieplague>
#include <hamsandwich>
#include <engine>
#include <xs>


#define PLUGIN_NAME	"Human Level Skills"
#define PLUGIN_VERSION	"2.0"
#define PLUGIN_AUTHOR	"China.xiaowenzi"

#define fm_get_user_oldbutton(%1) pev(%1, pev_oldbuttons)
#define fm_get_user_button(%1) pev(%1, pev_button)
#define fm_get_entity_flags(%1) pev(%1, pev_flags)


//Humans increase blood volume per level of life
#define SKILLHEALTH 10.0

//Human armor increased armor per level
#define SKILLARMOR 10.0

//Humans reduce the gravity of each level of gravity reduction
#define SKILLGRAVITY 100

//Human increase speed increases at each level
#define SKILLSPEED 1.0

//Humans increase transparency and increase transparency at each level
#define SKILLRENDER 40

//The power multiplier that humans increase in firepower at each level
#define SKILLATTACK 0.01

//The rate at which the player gains experience without saving
#define NOSAVEEXEGAIN 1.5

//The rate at which the player gains experience when saving
#define SAVEEXEGAIN 1.0

//Purchase experience player gains experience
#define BUYEXEGAIN 10000

//Ammunition bag used for purchasing experience
#define BUYEXEPACKS 200

//Ammunition bag used for purchase level (Formula: Rating *n)
#define BUYLEVELPACKS 100

//The display type of the level information (1 is HUD, 2 is the center of the screen, 3 is the lower left corner, and 4 is the upper right corner image)
#define SHOWTYPE 3

//The mode of experience acquisition (1 is calculated by the number of damages of the attack, 2 is obtained by killing the enemy)
#define EXEGAIN 1

//If the experience acquisition mode is 2, then what is the bottom value of the number of experiences that can be obtained when killing an enemy?
#define EXEGAIN2EXE 10000.0

//Experience HUD information display channel (1 to 4, if there is a conflict, please modify the channel)
#define HUDCHANNEL 3

//Experience required to reset skill points
#define RESETPOINTEXE 2000

//Open the menu command, delete this column to turn off this feature
#define THE_BUTTON "F1"

//Grenade replenishment time
#define SKILLHEGRENADE 30.0


new const file[]={"\addons\amxmodx\configs\Zp_SimpleLevel.ini"}
new g_LevelPoint[33],g_LevelExe[33],g_Level[33],g_LevelTotalExe[33]
new bool:g_levelSave[33]=false,bool:g_PD[33],bool:g_guishow[33],bool:g_taskid[33]
new g_fwBotForwardRegister,g_MaxLevel=0
new g_jump[33]

//How many skills in total
#define SKILLNUM 8
new g_LevelNum[33][SKILLNUM]

//Highest level of skill
new g_LevelSkillMAX[SKILLNUM]=
{
	10,	//"HP"
	10,	//"Armor"
	5,	//"Gravity"
	5,	//"Speed"
	5,	//"Stealth"
	3,	//"Weapon damage"
	1,	//"Grenade supply"
	1             //"Jump"
}


//Skill points required for upgrade
new g_LevelSkillPonit[SKILLNUM]=
{
	1,	//"HP"
	1,	//"Armor"
	2,	//"Gravity"
	2,	//"Speed"
	3,	//"Stealth"
	5,	//"Weapon damage"
	5,	//"Grenade supply"
	5             //"Jump"
}

new szLevelName[SKILLNUM][]=
{
	"HP",
	"Armor",
	"Gravity",
	"Speed",
	"Stealth",
	"Weapon damage",
	"Grenade supply", 
	"Jump"
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_clcmd("levelmenu","PlayerMenu")
	register_clcmd("levelmenu","PlayerMenu",ADMIN_ALL, "display level menu" )
	register_event("ResetHUD","set_hunman","b")
	register_clcmd("resetlevel","resetlevel")
	register_clcmd("eg_leveltest","leveltest")
	for(new i=0;i<SKILLNUM;i++)
		g_MaxLevel+=g_LevelSkillMAX[i]*g_LevelSkillPonit[i]
	g_MaxLevel+=1
	
	RegisterHam(Ham_TakeDamage, "player", "HAM_TakeDamage")
	g_fwBotForwardRegister = register_forward(FM_PlayerPostThink, "fw_BotForwardRegister_Post", 1)
}

public plugin_end()
{
	for(new id=1;id<=get_maxplayers();id++)
	{
		if(is_user_connected(id))
		{
			remove_task(id)
			g_LevelExe[id]=0
			g_LevelTotalExe[id]=500
			g_Level[id]=1
			g_LevelPoint[id]=0
			for(new i=0;i<SKILLNUM;i++)
				g_LevelNum[id][i]=0
		}
	}
}


public zp_user_humanized_post(id)
{
	set_hunman(id)
}

public leveltest(id)
{
	g_LevelExe[id]+=10000000
	zp_set_user_ammo_packs(id, zp_get_user_ammo_packs(id) + 100)
}

public resetlevel(id)
{
	g_LevelExe[id]=0
	g_LevelTotalExe[id]=500
	g_Level[id]=1
	g_LevelPoint[id]=0
	g_PD[id]=true
	g_levelSave[id]=false
	g_taskid[id]=false
	save_score(id)
	client_color(id,"Level settings have been reset")
}

public set_hunman(id)
{
	if(!zp_get_user_zombie(id))
	{
		new Float:fStandFor
		pev(id,pev_health,fStandFor)
		set_pev(id,pev_health,fStandFor+SKILLHEALTH*g_LevelNum[id][0])
		set_pev(id,pev_gravity,1.0-(float(SKILLGRAVITY)/1000)*g_LevelNum[id][2])
		set_pev(id,pev_armorvalue,SKILLARMOR*g_LevelNum[id][1])
		set_pev(id,pev_maxspeed,250.0+SKILLSPEED*float(g_LevelNum[id][3]))
		fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 255-SKILLRENDER*g_LevelNum[id][4])
		set_task(3.0,"set_gravity",id)
	}
	if(SHOWTYPE==4&&!g_guishow[id])
	{
		g_guishow[id]=true
	}
	if(g_PD[id])
	{
			g_PD[id]=false
			g_levelSave[id]=false
			client_color(id," ")
	}
}
public set_gravity(id)
{
	if(!zp_get_user_zombie(id))
	{
		if(is_user_alive(id))
		{
			set_pev(id,pev_gravity,1.0-(float(SKILLGRAVITY)/1000)*g_LevelNum[id][2])
		}	
	}
}

public client_damage(attacker,victim,damage,weapon,hitplace,ta)
{
	if(EXEGAIN==1&&g_Level[attacker]<g_MaxLevel&&zp_get_user_zombie(victim)&&!zp_get_user_zombie(attacker))
	{
		add_level_exe(attacker,floatround(damage*5*(g_levelSave[attacker]?SAVEEXEGAIN:NOSAVEEXEGAIN)))
	}
}
public client_death(killer,victim,wpnindex,hitplace,TK)
{
	if(EXEGAIN==2&&g_Level[killer]<g_MaxLevel&&zp_get_user_zombie(victim)&&!zp_get_user_zombie(killer))
	{
		add_level_exe(killer,floatround(EXEGAIN2EXE*5*(g_levelSave[killer]?SAVEEXEGAIN:NOSAVEEXEGAIN)))
	}
}


public client_connect(id)
{
#if defined(THE_BUTTON)
	client_cmd(id,"bind %s ^"levelmenu^"",THE_BUTTON)	
#endif
}

public client_putinserver(id)
{
	g_Level[id]=1
	g_LevelTotalExe[id]=500
	show_levelhud(id)
	g_LevelExe[id]=read_score(id)
	g_levelSave[id]=false
	set_task(1.0,"show_levelhud",id,_,_,"b")
}

public client_disconnect(id)
{
	remove_task(id)
	g_LevelExe[id]=0
	g_LevelTotalExe[id]=500
	g_Level[id]=1
	g_LevelPoint[id]=0
	g_taskid[id]=false
	for(new i=0;i<SKILLNUM;i++)
		g_LevelNum[id][i]=0
}
public client_PreThink(id)
{
	if(is_user_connected(id))
	{
		if(g_LevelExe[id]>=g_LevelTotalExe[id]&&g_Level[id]<g_MaxLevel)
		{
			g_LevelExe[id]-=g_LevelTotalExe[id]
			g_Level[id]+=1
			g_LevelTotalExe[id]=floatround(500*g_Level[id]*1.5)
			g_LevelPoint[id]+=1
			if(is_user_alive(id)&&!zp_get_user_zombie(id))
				PlayerMenu(id)
		}
		if(g_LevelExe[id]<0)
		{
			g_LevelExe[id]+=floatround(500*(g_Level[id]-1)*((g_Level[id]-1)==1?1.0:1.5))
			g_Level[id]-=1
			if(g_LevelPoint[id]>0)
				g_LevelPoint[id]-=1
			g_LevelTotalExe[id]=floatround(500*g_Level[id]*(g_Level[id]==1?1.0:1.5))
		}
		if(g_LevelExe[id]>g_LevelTotalExe[id]&&g_Level[id]==g_MaxLevel)	
			g_LevelExe[id]=floatround(500*g_MaxLevel*1.5)
		if(is_user_alive(id))
		{
			if(g_jump[id]<g_LevelNum[id][7]&&(fm_get_user_button(id)&IN_JUMP)&&!(fm_get_user_oldbutton(id)&IN_JUMP))
			{
				fm_jump(id)
				g_jump[id]+=1
			}
			if(g_jump[id]!=0&&fm_get_entity_flags(id)&FL_ONGROUND) 
				g_jump[id]=0
			if(!zp_get_user_zombie(id))
				set_pev(id,pev_maxspeed,250.0+SKILLSPEED*float(g_LevelNum[id][3]))
			new day=SHOWTYPE
			if(day==4)
			{
				if(g_guishow[id]&&!zp_get_user_zombie(id))
				{
					new szMsg[128]
					format(szMsg,127,"Level:%d/%d^nExe:%d/%d ^nPoint:%d",g_Level[id],g_MaxLevel,g_LevelExe[id],g_LevelTotalExe[id],g_LevelPoint[id])
					message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("TutorText"), _, id)
					write_byte(id)
					write_string(szMsg)
					message_end()
				}
				else if(g_guishow[id])
				{
					g_guishow[id]=false
					remove_guishow(id)
				}
			}
			
		}
		else if(g_guishow[id])
		{
			g_guishow[id]=false
			remove_guishow(id)
		}
	}
}

public remove_guishow(id)
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("TutorClose"), _, id)
	write_byte(id)
	message_end()
}

public zp_user_humanized_pre(id, survivor)
{
	g_guishow[id]=true
}

public PlayerMenu(id)
{
	static opcion[256]
	formatex(opcion, charsmax(opcion),"\yHuman Level Skills\y(Skill points:\r %d \ypoint)",g_LevelPoint[id])	
	new iMenu=menu_create(opcion,"Show")	//执行菜单命令的
	new szTempid[18]
	for(new i=0;i<SKILLNUM;i++)
	{
		if(g_LevelNum[id][i]<g_LevelSkillMAX[i])
			formatex(opcion, charsmax(opcion),"\r%s \y(need %d point ,\yNow %d level,\yTotal %d level)", szLevelName[i],g_LevelSkillPonit[i],g_LevelNum[id][i],g_LevelSkillMAX[i])
		else formatex(opcion, charsmax(opcion),"\w%s \rgrade:Max", szLevelName[i])
		menu_additem(iMenu, opcion, szTempid,0)
	}
	formatex(opcion, charsmax(opcion),"\ybuy %d experience(\r%dAmmunition bag\y)",BUYEXEGAIN,BUYEXEPACKS)
	menu_additem(iMenu, opcion, szTempid,0)
	formatex(opcion, charsmax(opcion),"\yPurchase level(\r%dammo\y)",BUYLEVELPACKS*g_Level[id])
	menu_additem(iMenu, opcion, szTempid,0)
	formatex(opcion, charsmax(opcion),"\yReset skill point\w(\r%dexperience\w)^n(Enter resetlevel to reset all level settings)",RESETPOINTEXE)
	menu_additem(iMenu, opcion, szTempid,0)
	menu_setprop(iMenu, MPROP_EXIT, MEXIT_ALL)
	formatex(opcion, charsmax(opcion),"\wreturn")	//返回菜单的名字
	menu_setprop(iMenu, MPROP_BACKNAME, opcion)
	formatex(opcion, charsmax(opcion),"\wNext page")	//下一页菜单的名字
	menu_setprop(iMenu, MPROP_NEXTNAME, opcion)
	formatex(opcion, charsmax(opcion),"\wdrop out")	//退出菜单的名字
	menu_setprop(iMenu, MPROP_EXITNAME, opcion)
	menu_setprop(iMenu, MPROP_NUMBER_COLOR, "\r")	//菜单前面颜色的数字
	menu_display(id, iMenu, 0)
	return PLUGIN_HANDLED
}

public Show(id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new command[6], name[64], access, callback
	menu_item_getinfo(menu, item, access, command, sizeof command - 1, name, sizeof name - 1, callback)
	switch(item)
	{
		case 0..(SKILLNUM-1):{
			if(is_user_alive(id))
			{
				if(!zp_get_user_zombie(id))
				{
					if(g_LevelNum[id][item]<g_LevelSkillMAX[item])
					{
						if(g_LevelPoint[id]>=g_LevelSkillPonit[item])
						{
							g_LevelNum[id][item]+=1
							new Float:fStandFor
							switch(item+1)
							{
								case 1:
								{
									pev(id,pev_health,fStandFor)
									set_pev(id,pev_health,fStandFor+SKILLHEALTH)
									
								}
								case 2:
								{
									pev(id,pev_armorvalue,fStandFor)
									set_pev(id,pev_armorvalue,fStandFor+SKILLARMOR)
								}
								case 3:
								{
									set_pev(id,pev_gravity,1.0-(float(SKILLGRAVITY)/1000)*g_LevelNum[id][2])
								}
								case 4:
								{
									pev(id,pev_maxspeed,fStandFor)
									set_pev(id,pev_maxspeed,fStandFor+SKILLSPEED)
								}
								case 5:
								{
									fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, 255-SKILLRENDER*g_LevelNum[id][4])
								}
								case 7:
								{
									set_task(SKILLHEGRENADE,"give_grenade",id,_,_,"b")
								}
							}
							g_LevelPoint[id]-=g_LevelSkillPonit[item]
							if(g_LevelNum[id][item]<g_LevelSkillMAX[item])
								client_color(id,"/g%s/ySuccessfully upgraded skills,Spend /g skill points /r%d/y , now level is /g%d/y",szLevelName[item],g_LevelSkillPonit[item],g_LevelNum[id][item])
							else if(g_LevelNum[id][item]==g_LevelSkillMAX[item])
								client_color(id,"/g%s/y skills successfully upgraded, cost /g skill points /r%d/y, now /g skill level /y has been upgraded to /g full level",szLevelName[item],g_LevelSkillPonit[item],g_LevelNum[id][item])
							if(g_LevelPoint[id]>0)
								PlayerMenu(id)
						}
						else client_color(id,"/yYour skill points are not enough to upgrade /g%s/y",szLevelName[item])
					}
					else {
					client_color(id,"/y skill level is full, can't continue to upgrade /g%s/y",szLevelName[item])
					PlayerMenu(id)
					}
				}
				else client_color(id,"/yYour current team is /r zombie/y team, can't upgrade /g%s/y",szLevelName[item])
			}
			else client_color(id,"/yYou are currently /g dead /y, can't upgrade /g%s/y",szLevelName[item])
		}		
		case SKILLNUM:{
			if(is_user_alive(id))
			{
				if(g_Level[id]!=g_MaxLevel)
				{
					if(!zp_get_user_zombie(id))
					{
						if(zp_get_user_ammo_packs(id)>=BUYEXEPACKS)
						{
							add_level_exe(id,BUYEXEGAIN)
							zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id)-BUYEXEPACKS)
							client_color(id,"购买经验成功")
						}
						else{
							client_color(id,"Your ammo bag is not enough to buy experience")
						}
					}
					else{
						client_color(id,"/y only /g human / y can buy experience")
					}
				}
				else
				{
					client_color(id,"/y Your level is full, you can't buy it anymore...")
				}
				
			}
			else
			{
				client_color(id,"/y only /g alive /y can buy experience")
			}
		}
		case (SKILLNUM+1):{
			if(is_user_alive(id))
			{
				if(g_Level[id]<g_MaxLevel)
				{
					if(!zp_get_user_zombie(id))
					{
						if(zp_get_user_ammo_packs(id)>=BUYLEVELPACKS*g_Level[id])
						{
							g_LevelExe[id]=0
							g_Level[id]+=1
							g_LevelTotalExe[id]=floatround(500*g_Level[id]*1.5)
							g_LevelPoint[id]+=1
							if(is_user_alive(id)&&!zp_get_user_zombie(id))
								PlayerMenu(id)
							zp_set_user_ammo_packs(id,zp_get_user_ammo_packs(id)-BUYLEVELPACKS*g_Level[id])
							client_color(id,"Successful purchase level")
						}
						else{
							client_color(id,"Your ammo bag is not enough to buy a grade")
						}
					}
					else{
						client_color(id,"/y only /g human / y can buy grade")
					}
				}
				else
				{
					client_color(id,"/y Your level is full, you can't buy it anymore...")
				}
			}
			else
			{
				client_color(id,"/y only /g alive /y can buy level")
			}
		}
		case (SKILLNUM+2):{
			if(!zp_get_user_zombie(id))
			{
				new g_total=g_LevelExe[id]
				if(g_Level[id]>1)
				{
					for(new i=2;i<=g_Level[id]-1;i++)
					{
						g_total+=floatround(500*i*1.5)
					}
					g_total+=500
					if(g_total>=RESETPOINTEXE)
					{
						g_LevelExe[id]-=RESETPOINTEXE
						for(new i=0;i<=SKILLNUM-1;i++)
						{
							g_LevelPoint[id]+=g_LevelNum[id][i]*g_LevelSkillPonit[i]
							g_LevelNum[id][i]=0

						}
						if(is_user_alive(id))
						{
							set_pev(id,pev_gravity,1.0)
							if(pev(id,pev_health)>100)
								set_pev(id,pev_health,100.0)
							if(pev(id,pev_armorvalue)>0)
								set_pev(id,pev_armorvalue,0.0)
						}
						client_color(id,"Skill point has been cleared")
					}
				}
				else{
					client_color(id,"Skill point has been cleared")
				}
			}
			else{
				client_color(id,"/y only /g human / y can clear the skill point")
			}
		}	
	
	}
	
	menu_destroy(menu)
	return PLUGIN_HANDLED
}

public add_level_exe(index,addexe)
{
	g_LevelExe[index]+=addexe
}

public show_levelhud(id)
{
	if(is_user_alive(id)&&!zp_get_user_zombie(id)&&SHOWTYPE==1)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.05, 0, 6.0, 1.1,_,_,HUDCHANNEL)		
		show_hudmessage(id, "grade:%d/%d^n experience:%d/%d^n Skill points:%d point",g_Level[id],g_MaxLevel,g_LevelExe[id],g_LevelTotalExe[id],g_LevelPoint[id])
	}
	else if(is_user_alive(id)&&!zp_get_user_zombie(id)&&SHOWTYPE==2)
	{
		client_print(id,print_center, "grade:%d/%d^n experience:%d/%d^n Skill points:%d point",g_Level[id],g_MaxLevel,g_LevelExe[id],g_LevelTotalExe[id],g_LevelPoint[id])
	}
	else if(is_user_alive(id)&&!zp_get_user_zombie(id)&&SHOWTYPE==3)
	{
		new szMsg[128]
		format(szMsg,127,"grade:%d/%d^n experience:%d/%d^n Skill points:%d point",g_Level[id],g_MaxLevel,g_LevelExe[id],g_LevelTotalExe[id],g_LevelPoint[id])
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), _, id)
		write_byte(0)
		write_string(szMsg)
		message_end()
	}
	else if(!is_user_alive(id))
	{
		new pid=pev(id,pev_iuser2)
		if( !pid ) return
		if(!zp_get_user_zombie(pid))
		{
			new name[64]
			get_user_name(pid,name,63)
			new Explosion[1024]
			for(new i=0;i<SKILLNUM;i++)
			{
				new szSkillnum[16]
				if(g_LevelNum[pid][i]!=g_LevelSkillMAX[i]) format(szSkillnum,charsmax(szSkillnum),"%d level",g_LevelNum[pid][i])
				else format(szSkillnum,charsmax(szSkillnum),"MAX")
				
				if(i==0) format(Explosion,charsmax(Explosion),"Player:%s  grade:%d^n^n%s: %s^n",name,g_Level[pid],szLevelName[i],szSkillnum)
				else format(Explosion,charsmax(Explosion),"%s%s: %s^n",Explosion,szLevelName[i],szSkillnum)
			}
			set_hudmessage(0, 255, 0, 0.73, 0.12, 1, 6.0,  1.1,_,_,HUDCHANNEL)
			show_hudmessage(id, "%s",Explosion)
		}
	}		
}

public save_score(id)
{
	if(g_Level[id]>1)
	{
		for(new i=2;i<=g_Level[id]-1;i++)
		{
			g_LevelExe[id]+=floatround(500*i*1.5)
		}
		g_LevelExe[id]+=500
	}
	if(is_user_bot(id)) return PLUGIN_HANDLED
	new line = 0, textline[1024], len
	new line_name[64] 
	new value[33]
	new ident[33]
	get_user_name(id, ident, charsmax(ident))
	while ((line = read_file(file, line, textline, 1023, len)))
	{
		if (len == 0 || equal(textline, ";", 1))
			continue

		parse (textline, line_name, 63)
		strtok(textline,line_name,charsmax(line_name),value,charsmax(value),'`')

		if(equal(line_name, ident)){
				len = format(textline, 1023, "%s", ident)
				len += format(textline[len], 1023 - len, "`%d",g_LevelExe[id])
				write_file(file, textline, line -1)
				return PLUGIN_HANDLED
		}
	}
	len = format(textline, 255, "%s", ident)
	len += format(textline[len], 255 - len, "`%d",g_LevelExe[id])
	write_file(file, textline)
	return PLUGIN_HANDLED
}

public read_score(id)
{
	new line = 0, textline[1024], len
	new line_name[64] 
	new value[33]
	new ident[33]
	get_user_name(id, ident, charsmax(ident))

	if(!file_exists(file))
	{
		write_file(file, "")
	}

	while((line = read_file(file, line, textline, 1023, len)))
	{
		if (len == 0 || equal(textline, ";", 1))
			continue

		parse (textline, line_name, 63)
		strtok(textline,line_name,charsmax(line_name),value,charsmax(value),'`')
		if(equal(line_name, ident)){
			return str_to_num(value)
		}
	}
	return 0
}




stock client_color(id, const input[], any:...)
{
	static iPlayersNum[32], iCount; iCount = 1
	static szMsg[191]
	
	vformat(szMsg, charsmax(szMsg), input, 3)
	
	replace_all(szMsg, 190, "/g", "^4") // 绿色
	replace_all(szMsg, 190, "/y", "^1") // 橙色
	replace_all(szMsg, 190, "/r", "^3") // 队伍色
	replace_all(szMsg, 190, "/w", "^0") // 黄色
	
	if(id) iPlayersNum[0] = id
	else get_players(iPlayersNum, iCount, "ch")
	
	for (new i = 0; i < iCount; i++)
	{
		if (is_user_connected(iPlayersNum[i]))
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, iPlayersNum[i])
			write_byte(iPlayersNum[i])
			write_string(szMsg)
			message_end()
		}
	}
}

stock fm_set_user_money(iPlayer, money)
{
	set_pdata_int(iPlayer, 115, money, 5)
	message_begin(MSG_ONE, get_user_msgid("Money"), {0,0,0}, iPlayer)
	write_long(money)
	write_byte(1)
	message_end()
}

stock fm_get_user_money(iPlayer)
{
	return get_pdata_int(iPlayer,115)
}


public fw_BotForwardRegister_Post(iPlayer)
{
	if(!is_user_bot(iPlayer))
		return
	
	unregister_forward(FM_PlayerPostThink, g_fwBotForwardRegister, 1)
	RegisterHamFromEntity(Ham_TakeDamage, iPlayer, "HAM_TakeDamage")
}

public HAM_TakeDamage(victim, inflictor, attacker, Float:damage, damagetype)
{
	if (!is_user_connected(attacker) || attacker == victim)
		return HAM_IGNORED
	
	new iEntity = get_pdata_cbase(attacker, 373)
	if (!inflictor || !pev_valid(iEntity))
		return HAM_IGNORED
	
	SetHamParamFloat(4, damage * (g_LevelNum[attacker][5]?(1.0+SKILLATTACK*g_LevelNum[attacker][5]):1.0))
	return HAM_IGNORED
}

stock Screen_Fade(id, Float:time, fade_type = 0x0000, red, green, blue, alpha)
{
	// 添加影响
	message_begin(MSG_ONE_UNRELIABLE,get_user_msgid("ScreenFade"), _, id)
	write_short((1<<12)*1) 
	write_short(floatround((1<<12)*time)) 		// 保持时间
	write_short(fade_type) 			// 伪造类型 [FADE_IN(0x0000)/FADE_OUT(0x0001)/FADE_OUT(0x0002)/FADE_STAYOUT(0x0004)]
	write_byte(red) 	// 红色
	write_byte(green) 	// 绿色
	write_byte(blue)	// 蓝色
	write_byte(alpha) 	// 亮度
	message_end()
}

stock MakeDeath(attack, victim)
{
	if(!(0<attack<33) || !(0<victim<33)) return

	
	set_pdata_int(victim, 444, get_pdata_int(victim, 444, 5) + 1, 5)

        set_msg_block(get_user_msgid("DeathMsg"), BLOCK_ONCE)
        set_msg_block(get_user_msgid("ScoreInfo"), BLOCK_ONCE)
	
	message_begin(MSG_ALL, get_user_msgid("DeathMsg"))
	write_byte(attack)
	write_byte(victim)
	write_byte(0)
	write_string("Skill")
	message_end()
	
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(victim)
	write_short(pev(victim, pev_frags))
	write_short(get_user_deaths(victim))
	write_short(0)
	write_short(get_pdata_int(victim, 114, 5))
	message_end()
	
	message_begin(MSG_ALL, get_user_msgid("ScoreInfo"))
	write_byte(attack)
	write_short((get_pdata_int(attack, 114, 5) != get_pdata_int(victim, 114, 5))?(pev(attack, pev_frags)+1):(pev(attack, pev_frags)-1))
	write_short(get_user_deaths(attack))
	write_short(0)
	write_short(get_user_team(attack))
	message_end()
}
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) {
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}

stock Float:fm_entity_range(ent1, ent2) {
	new Float:origin1[3], Float:origin2[3];
	pev(ent1, pev_origin, origin1);
	pev(ent2, pev_origin, origin2);

	return get_distance_f(origin1, origin2);
}
stock fm_give_item(iPlayer, const wEntity[])
{
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, 	wEntity))
	new Float:origin[3]
	pev(iPlayer, pev_origin, origin)
	set_pev(iEntity, pev_origin, origin)
	set_pev(iEntity, pev_spawnflags, pev(iEntity, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, iEntity)
	new save = pev(iEntity, pev_solid)
	dllfunc(DLLFunc_Touch, iEntity, iPlayer)
	if(pev(iEntity, pev_solid) != save)
		return iEntity
	engfunc(EngFunc_RemoveEntity, iEntity)
	return -1
}

stock fm_set_user_health(index, health)
{
	health > 0 ? set_pev(index, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, index)
	return 1
}
stock fm_vel2d_over_aiming(index,Float:Rdegree,Float:sthenth,Float:xyz[3],Float:z_value=0.0)
{
	new Float:fporigin[3],Float:faorigin[3]
	pev(index,pev_origin,fporigin)
	new Float:start[3], Float:view_ofs[3]
	pev(index, pev_origin, start)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)

	new Float:dest[3]
	pev(index, pev_v_angle, dest)
	engfunc(EngFunc_MakeVectors, dest)
	global_get(glb_v_forward, dest)
	xs_vec_mul_scalar(dest, 9999.0, dest)
	xs_vec_add(start, dest, dest)

	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0)
	get_tr2(0, TR_vecEndPos,faorigin)
	new Float:Angles[3]
	pev(index,pev_angles,Angles)
	Angles[1]=(Angles[1]>0)?Angles[1]:(180.0+(180.0-floatabs(Angles[1])))
	new Float:fvalue=3.1415926535898/180.0*(Rdegree+Angles[1])
	xyz[0]=(floatcos(fvalue))*sthenth
	xyz[1]=(floatsin(fvalue))*sthenth
	if(z_value==-1.0)
		z_value=(faorigin[2]-fporigin[2])/xs_sqrt(floatpower(faorigin[2]-fporigin[2],2.0))*sthenth
	xyz[2]=z_value

}

public give_grenade(id)
{
    if(!zp_get_user_zombie(id)&&is_user_alive(id)&&g_LevelNum[id][6])
    {
		new grtype = random_num(1, 3)
		switch(grtype)
		{
			case 1:fm_give_item(id,"weapon_hegrenade")
			case 2:fm_give_item(id,"weapon_flashbang")
			case 3:fm_give_item(id, "weapon_smokegrenade")
		}
    }
}

stock fm_jump(id)
{
	new Float:velocity[3] 
	pev(id,pev_velocity,velocity)
	velocity[2] = random_float(265.0,285.0)
	set_pev(id,pev_velocity,velocity)
}
