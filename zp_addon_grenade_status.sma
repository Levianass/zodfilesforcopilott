/*********************************************************
*                         Made by                      
*
*  RRRRR   AAA   PPPPP   AAA   RRRRR   AAA      1 33333
*  R   R  A   A  P   P  A   A  R   R  A   A    11     3
*  RRRRR  A   A  PPPPP  A   A  RRRRR  A   A   1 1     3
*  RR     AaaaA  P      AaaaA  RR     AaaaA     1  3333
*  R R    A   A  P      A   A  R R    A   A     1     3
*  R  R   A   A  P      A   A  R  R   A   A     1 33333
*
**********************************************************
*                   AMX MOD X script.                    *
* You can modify the code, but DO NOT modify the author! *
**********************************************************
*
*  Special Tanks to:
*  =================
*  DaRk_StyLe - Idea for set grenade status colors by cvars
*********************************************************/

#include <amxmodx>
#include <zombieplague>

#define VERSION "1.2"

new cvar_status, cvar_fire_icon, cvar_fire_color, cvar_frost_icon, cvar_frost_color, cvar_flare_icon, cvar_flare_color,
cvar_infect_icon, cvar_infect_color

new g_StatusIcon
new g_GrenadeIcon[33][32]

public plugin_init()  {
	register_plugin("[ZP] Addon: Grenade Status", VERSION, "rapara13")
	register_cvar("zp_grenade_status", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	// Nade Status Cvar
	cvar_status = register_cvar("zp_nadestatus_icon","1") // [0=Hide | 1=Show | 2=Flash (Don't work with red color)]
	
	// Fire Grenade Cvars
	cvar_fire_icon = register_cvar("zp_firenade_icon","1") // [0=Disable | 1=Enable]
	cvar_fire_color = register_cvar("zp_firenade_color","255 0 0") // Color of Fire Nade in RGB
	
	// Frost Grenade Cvars
	cvar_frost_icon = register_cvar("zp_frostnade_icon","1") // [0=Disable | 1=Enable]
	cvar_frost_color = register_cvar("zp_frostnade_color","100 149 237") // Color of Frost Nade in RGB
	
	// Flare Grenade Cvars
	cvar_flare_icon = register_cvar("zp_flarenade_icon","1") // [0=Disable | 1=Enable]
	cvar_flare_color = register_cvar("zp_flarenade_color","255 255 255") // Color of Flare Nade in RGB
	
	// Infect Grenade Cvars
	cvar_infect_icon = register_cvar("zp_infectnade_icon","1") // [0=Disable | 1=Enable]
	cvar_infect_color = register_cvar("zp_infectnade_color","0 255 0") // Color of Infect Nade in RGB
	
	register_event("CurWeapon", "GrenadeIcon", "be", "1=1")
	register_event("DeathMsg", "DeathEvent", "a")
	
	g_StatusIcon = get_user_msgid("StatusIcon")
}

public GrenadeIcon(id) {
	RemoveGrenadeIcon(id)
		
	if(is_user_bot(id))
		return
		
	static NadeType, GrenadeSprite[16], Color[17], Red[5], Green[5], Blue[5]
	NadeType = get_user_weapon(id)
	
	switch(NadeType) {
		case CSW_HEGRENADE: // Fire Nade / Infect Nade
		{
			if(!zp_get_user_zombie(id)) {
				if(!get_pcvar_num(cvar_fire_icon))
					return
				
				GrenadeSprite = "dmg_heat"
				get_pcvar_string(cvar_fire_color, Color, charsmax(Color))
				
			} else {
				if(!get_pcvar_num(cvar_infect_icon))
					return
					
				GrenadeSprite = "dmg_bio"
				get_pcvar_string(cvar_infect_color, Color, charsmax(Color))
			}
		}
		case CSW_FLASHBANG: // Frost Nade
		{
			if(!get_pcvar_num(cvar_frost_icon))
					return
			
			GrenadeSprite = "dmg_cold"
			get_pcvar_string(cvar_frost_color, Color, charsmax(Color))
		}
		case CSW_SMOKEGRENADE: // Flare Nade
		{
			if(!get_pcvar_num(cvar_flare_icon))
					return
			
			GrenadeSprite = "dmg_shock"
			get_pcvar_string(cvar_flare_color, Color, charsmax(Color))
		}
		default: 
		return
	}
	parse(Color,Red,charsmax(Red),Green,charsmax(Green),Blue,charsmax(Blue))
	g_GrenadeIcon[id] = GrenadeSprite
	
	// Show Grenade Icons
	message_begin(MSG_ONE,g_StatusIcon,{0,0,0},id)
	write_byte(get_pcvar_num(cvar_status)) // Status [0=Hide, 1=Show, 2=Flash]
	write_string(g_GrenadeIcon[id]) // Sprite Name
	write_byte(str_to_num(Red)) // Red
	write_byte(str_to_num(Green)) // Green
	write_byte(str_to_num(Blue)) // Blue
	message_end()
	
	return
}

public RemoveGrenadeIcon(id) {
	// Remove Grenade Icons
	message_begin(MSG_ONE,g_StatusIcon,{0,0,0},id)
	write_byte(0) // Status [0=Hide, 1=Show, 2=Flash]
	write_string(g_GrenadeIcon[id]) // Sprite Name
	message_end()
}

public DeathEvent() {
	new id = read_data(2)
	
	if(is_user_bot(id))
	RemoveGrenadeIcon(id)
}
