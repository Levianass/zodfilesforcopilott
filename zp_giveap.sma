/* Includes */
#include <amxmodx>
#include <amxmisc>
#include <zombieplague>
#include <colorchat>
/* Defines */
#define PLUGIN "SC_GiveAP"
#define AUTHOR "Arkshine & Bandai.UK"
#define VERSION "1.0.1"
#define prefix "ZoD*|"
public plugin_init()
{
/* Registers */

register_plugin(PLUGIN, VERSION, AUTHOR)
register_concmd("zp_giveap", "CmdGiveAP", ADMIN_RCON, "- zp_giveap <name> <amount> : Give User Specified Ammo Packs");
register_concmd("zp_takeap", "CmdTakeAP", ADMIN_RCON, "- zp_takeap <name> <amount> : Take Specified Ammo Packs From User");
register_concmd("zp_setap", "CmdSetAP", ADMIN_RCON, "- zp_setap <name> <amount> : Set Users Ammo Packs To Specified Amount");
}
/* Giving Ammo Packs */
public CmdGiveAP(id, level, cid)
{
if(!cmd_access(id, level, cid, 3))
{
return PLUGIN_HANDLED;
}

new s_Name[32], s_Amount[32];

read_argv(1, s_Name, charsmax(s_Name));
read_argv(2, s_Amount, charsmax(s_Amount));

new i_Target = cmd_target(id, s_Name, 2);

if(!i_Target)
{
client_print(id, print_console, "That Player Could Not Be Found, Sorry!");
return PLUGIN_HANDLED;
}

new Reciever[32]; get_user_name(i_Target, Reciever, 31);
zp_set_user_ammo_packs(i_Target, max(1, str_to_num(s_Amount) + zp_get_user_ammo_packs(i_Target)));
ColorChat(id, GREEN, "^4[^3%s^4] ^3%s Was given %s points by the Admin!", prefix, Reciever, s_Amount);
client_print(id, print_console, "[%s] You gave %s %s points", prefix, Reciever, s_Amount);
return PLUGIN_HANDLED;
}
/* Taking Ammo Packs */
public CmdTakeAP(id, level, cid)
{
if(!cmd_access(id, level, cid, 3))
{
return PLUGIN_HANDLED;
}

new s_Name[32], s_Amount[32];

read_argv(1, s_Name, charsmax(s_Name));
read_argv(2, s_Amount, charsmax(s_Amount));

new i_Target = cmd_target(id, s_Name, 2);

if(!i_Target)
{
client_print(id, print_console, "That Player Could Not Be Found, Sorry!");
return PLUGIN_HANDLED;
}

new Loser[32]; get_user_name(i_Target, Loser, 31);
new l_Amount = zp_get_user_ammo_packs(i_Target) - max(1, str_to_num(s_Amount))
zp_set_user_ammo_packs(i_Target, l_Amount);
ColorChat(0, GREEN, "^4[^3%s^4] ^3%s Has lost %s points for being bad!", prefix, Loser, s_Amount);
client_print(id, print_console, "[%s] You've taken %s points from %s!", prefix, Loser, s_Amount);

return PLUGIN_HANDLED;
}
/* Set Ammo Packs */
public CmdSetAP(id, level, cid)
{
if(!cmd_access(id, level, cid, 3))
{
return PLUGIN_HANDLED;
}

new s_Name[32], s_Amount[32];

read_argv(1, s_Name, charsmax(s_Name));
read_argv(2, s_Amount, charsmax(s_Amount));

new i_Target = cmd_target(id, s_Name, 2);

if(!i_Target)
{
client_print(id, print_console, "That Player Could Not Be Found, Sorry!");
return PLUGIN_HANDLED;
}

new Set[32]; get_user_name(i_Target, Set, 31);
zp_set_user_ammo_packs(i_Target, max(1, str_to_num(s_Amount)));
ColorChat(0, GREEN, "^4[^3%s^4] ^3%s Had their points Set to %s by the Admin!", prefix, Set, s_Amount);
client_print(id, print_console, "[%s] You set %s's points to %s!", prefix, Set, s_Amount);

return PLUGIN_HANDLED;
} 