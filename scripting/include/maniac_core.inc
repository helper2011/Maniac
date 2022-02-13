#if defined maniac_core_included
#endinput
#endif
#define maniac_core_included

native void Maniac_PrintToChat(int iClient, const char[] message, any ...);
native void Maniac_PrintToChatAll(int iSkipClient = 0, const char[] message, any ...);
native void Maniac_OpenAdminMenu(int iClient);

forward bool Maniac_OnAdminOpenedSets(int iClient, const char[] mode);

public SharedPlugin __pl_maniac_core= 
{
	name = "maniac_core",
	file = "maniac_core.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_maniac_core_SetNTVOptional()
{
	MarkNativeAsOptional("Maniac_PrintToChat");
	MarkNativeAsOptional("Maniac_PrintToChatAll");
	MarkNativeAsOptional("Maniac_OpenAdminMenu");
	MarkNativeAsOptional("Maniac_OnAdminOpenedSets");
}
#endif
