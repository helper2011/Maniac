#if defined maniac_included
#endinput
#endif
#define maniac_included


native void Maniac_ClientToggleSprint(int iClient, bool Toggle);
native float Maniac_GetClientSpeed(int iClient);
forward void Maniac_OnManiacWasFree();
forward bool Maniac_OnClientChangeSpeed(int iClient, int iType, float fSpeed);


public SharedPlugin __pl_maniac= 
{
	name = "maniac",
	file = "maniac.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_maniac_SetNTVOptional()
{
	MarkNativeAsOptional("Maniac_ClientToggleSprint");
	MarkNativeAsOptional("Maniac_GetClientSpeed");
	MarkNativeAsOptional("Maniac_OnManiacWasFree");
	MarkNativeAsOptional("Maniac_OnClientChangeSpeed");
}
#endif
