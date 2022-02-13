#include <sdkhooks>
#include <sdktools_entoutput>
#include <sdktools_functions>
#include <sdktools_entinput>
#include <sdktools_variant_t>
#include <maniac_core>

#pragma newdecls required

Handle	g_hGFwdOnClientChangeSpeed,
		g_hGFwdOnManiacWasFree,
		g_hTimer, 
		g_hTimerSprint[MAXPLAYERS + 1], 
		g_hTimerSprintCoolDown[MAXPLAYERS + 1];

ConVar	cvarHideTime, 
		cvarSpawnHealthT, 
		cvarDoubleJumpHeight,
		cvarEnableSprint, 
		cvarMaxSprint, 
		cvarSprintInc, 
		cvarSprintIncDelay, 
		cvarSprintMinUse, 
		cvarSprintStart, 
		cvarSprintCoolDown, 
		cvarSprintSpeed, 
		cvarSpawnSpeed, 
		cvarSpawnHealthCT,
		cvarGiveArmor,
		cvarGiveHe,
		cvarGiveFlash,
		cvarGiveSmoke,
		cvarDeagleMode,
		cvarHSOnlyMode,
		cvarDeagleAmmo,
		cvarDeaglePrimaryAmmo,
		cvarGiveAmmoForSomeKills,
		cvarSomeKillsForGiveAmmo,
		cvarHealthPerHumanT,
		cvarMaxJumps;

int		g_iHideTime, 
		g_iSpawnHealthT, 
		g_iSpawnHealthCT, 
		g_iSprintMax, 
		g_iSprintInc, 
		g_iSprintMinUse, 
		g_iSprintStart,
		g_iGiveAmmoForSomeKills,
		g_iSomeKillsForGiveAmmo,
		g_iHealthPerHumanT,
		g_iMaxJumps,
		
		m_flLaggedMovementValue,
		g_iClip1,
		g_iAmmoOffset,
		g_iPrimaryAmmoType,
		g_iArmor,
		m_iHealth,
		
		Armor,
		Hegrenades,
		Flashbangs,
		Smokegrenades,
		DeagleAmmo,
		DeaglePrimaryAmmo,
		
		MaxJumps[MAXPLAYERS + 1],
		Kills[MAXPLAYERS + 1],
		Sprint[MAXPLAYERS + 1], 
		Team[MAXPLAYERS + 1],
		Set[MAXPLAYERS + 1] = {-1, ...},
		SprintParticle[MAXPLAYERS + 1] = {-1, ...};

bool	SprintEnable,
		SprintToggle[MAXPLAYERS + 1],
		DeagleMode,
		HeadShotOnly,
		g_bLibrary;
		
float	g_fDoubleJumpHeight, 
		g_fSprintIncDelay, 
		g_fSprintCoolDown, 
		g_fSprintSpeed, 
		g_fSpawnSpeed,
		DoorPosition[3],
		Speed[MAXPLAYERS + 1];
char	DoorInfo[3][64];

public Plugin myinfo = 
{
    name = "Maniac",
    version = "1.0",
    author = "hEl"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
/*	MarkNativeAsOptional("Maniac_OnAdminOpenedSets");
	MarkNativeAsOptional("Maniac_PrintToChat");
	MarkNativeAsOptional("Maniac_PrintToChatAll");
	MarkNativeAsOptional("Maniac_OpenAdminMenu");*/
	
	CreateNative("Maniac_GetClientSpeed", Native_Maniac_GetClientSpeed);
	CreateNative("Maniac_ClientToggleSprint", Native_Maniac_ClientToggleSprint);
	RegPluginLibrary("maniac");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("maniac.phrases");
	
	cvarSpawnHealthT = CreateConVar("maniac_spawn_health_t", "500");
	g_iSpawnHealthT = cvarSpawnHealthT.IntValue;
	cvarSpawnHealthT.AddChangeHook(OnConVarChange);

	cvarSpawnHealthCT = CreateConVar("maniac_spawn_health_ct", "100");
	g_iSpawnHealthCT = cvarSpawnHealthCT.IntValue;
	cvarSpawnHealthCT.AddChangeHook(OnConVarChange);

	
	cvarHideTime = CreateConVar("maniac_hide_time", "30");
	g_iHideTime = cvarHideTime.IntValue;
	cvarHideTime.AddChangeHook(OnConVarChange);
	
	cvarDoubleJumpHeight = CreateConVar("maniac_dj_height", "275");
	g_fDoubleJumpHeight = cvarDoubleJumpHeight.FloatValue;
	cvarDoubleJumpHeight.AddChangeHook(OnConVarChange);
	
	cvarEnableSprint = CreateConVar("maniac_sprint", "1");
	SprintEnable = cvarEnableSprint.BoolValue;
	cvarEnableSprint.AddChangeHook(OnConVarChange);
	
	cvarMaxSprint = CreateConVar("maniac_max_sprint", "200");
	g_iSprintMax = cvarMaxSprint.IntValue;
	cvarMaxSprint.AddChangeHook(OnConVarChange);
	
	cvarSprintInc = CreateConVar("maniac_sprint_inc", "2");
	g_iSprintInc = cvarSprintInc.IntValue;
	cvarSprintInc.AddChangeHook(OnConVarChange);

	cvarSprintIncDelay = CreateConVar("maniac_sprint_inc_delay", "0.5");
	g_fSprintIncDelay = cvarSprintIncDelay.FloatValue;
	cvarSprintIncDelay.AddChangeHook(OnConVarChange);

	cvarSprintMinUse = CreateConVar("maniac_sprint_min_use", "0");
	g_iSprintMinUse = cvarSprintMinUse.IntValue;
	cvarSprintMinUse.AddChangeHook(OnConVarChange);
	
	cvarSprintStart = CreateConVar("maniac_sprint_start", "0");
	g_iSprintStart = cvarSprintStart.IntValue;
	cvarSprintStart.AddChangeHook(OnConVarChange);
	
	cvarSprintCoolDown = CreateConVar("maniac_sprint_cooldown", "2.0");
	g_fSprintCoolDown = cvarSprintCoolDown.FloatValue;
	cvarSprintCoolDown.AddChangeHook(OnConVarChange);

	cvarSpawnSpeed = CreateConVar("maniac_spawn_speed", "1.05");
	g_fSpawnSpeed = cvarSpawnSpeed.FloatValue;
	cvarSpawnSpeed.AddChangeHook(OnConVarChange);
	
	cvarSprintSpeed = CreateConVar("maniac_sprint_speed", "1.5");
	g_fSprintSpeed = cvarSprintSpeed.FloatValue;
	cvarSprintSpeed.AddChangeHook(OnConVarChange);	
	
	cvarGiveArmor = CreateConVar("maniac_give_armor", "100");
	Armor = cvarGiveArmor.IntValue;
	cvarGiveArmor.AddChangeHook(OnConVarChange);

	cvarGiveHe = CreateConVar("maniac_give_he", "1");
	Hegrenades = cvarGiveHe.IntValue;
	cvarGiveHe.AddChangeHook(OnConVarChange);		
	
	cvarGiveFlash = CreateConVar("maniac_give_flash", "2");
	Flashbangs = cvarGiveFlash.IntValue;
	cvarGiveFlash.AddChangeHook(OnConVarChange);	
	
	cvarGiveSmoke = CreateConVar("maniac_give_smoke", "1");
	Smokegrenades = cvarGiveSmoke.IntValue;
	cvarGiveSmoke.AddChangeHook(OnConVarChange);	
	
	cvarDeagleMode = CreateConVar("maniac_deagle_mode", "1");
	DeagleMode = cvarDeagleMode.BoolValue;
	cvarDeagleMode.AddChangeHook(OnConVarChange);	
	
	cvarHSOnlyMode = CreateConVar("maniac_headshot_only_mode", "1");
	HeadShotOnly = cvarHSOnlyMode.BoolValue;
	cvarHSOnlyMode.AddChangeHook(OnConVarChange);	
	
	cvarDeagleAmmo = CreateConVar("maniac_deagle_ammo", "1");
	DeagleAmmo = cvarDeagleAmmo.IntValue;
	cvarDeagleAmmo.AddChangeHook(OnConVarChange);	
	
	cvarDeaglePrimaryAmmo = CreateConVar("maniac_deagle_primary_ammo", "0");
	DeaglePrimaryAmmo = cvarDeaglePrimaryAmmo.IntValue;
	cvarDeaglePrimaryAmmo.AddChangeHook(OnConVarChange);	
	
	cvarGiveAmmoForSomeKills = CreateConVar("maniac_give_ammo_for_some_kills", "1");
	g_iGiveAmmoForSomeKills = cvarGiveAmmoForSomeKills.IntValue;
	cvarGiveAmmoForSomeKills.AddChangeHook(OnConVarChange);	
	
	cvarSomeKillsForGiveAmmo = CreateConVar("maniac_some_kills_for_give_ammo", "3");
	g_iSomeKillsForGiveAmmo = cvarSomeKillsForGiveAmmo.IntValue;
	cvarSomeKillsForGiveAmmo.AddChangeHook(OnConVarChange);	
	
	cvarHealthPerHumanT = CreateConVar("maniac_health_per_human_for_t", "500");
	g_iHealthPerHumanT = cvarHealthPerHumanT.IntValue;
	cvarHealthPerHumanT.AddChangeHook(OnConVarChange);	
	
	cvarMaxJumps = CreateConVar("maniac_max_jumps", "2");
	g_iMaxJumps = cvarMaxJumps.IntValue;
	cvarMaxJumps.AddChangeHook(OnConVarChange);

	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Pre);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);
	HookEvent("player_team", OnPlayerTeam);

	HookEvent("round_start", OnRoundStart);
	
	m_flLaggedMovementValue = FindSendPropInfo("CCSPlayer", "m_flLaggedMovementValue");
	g_iClip1 = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
	g_iAmmoOffset = FindSendPropInfo("CCSPlayer", "m_iAmmo");
	g_iPrimaryAmmoType = FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");
	g_iArmor = FindSendPropInfo("CCSPlayer", "m_ArmorValue");
	m_iHealth = FindSendPropInfo("CCSPlayer", "m_iHealth");
	
	g_hGFwdOnManiacWasFree = CreateGlobalForward("Maniac_OnManiacWasFree", ET_Ignore);
	g_hGFwdOnClientChangeSpeed = CreateGlobalForward("Maniac_OnClientChangeSpeed", ET_Hook, Param_Cell, Param_Cell, Param_FloatByRef);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPostAdminCheck(i);
			OnClientSpawned(i);
		}
	}
	
	g_bLibrary = LibraryExists("maniac_core");
	
	RegConsoleCmd("sm_jumps", Command_Jumps);
}

public Action Command_Jumps(int iClient, int iArgs)
{
	if(iArgs == 1)
	{
		char szBuffer[16];
		GetCmdArg(1, szBuffer, 16);
		int iJumps = StringToInt(szBuffer);
		MaxJumps[iClient] = (0 < iJumps <= g_iMaxJumps) ? iJumps:g_iMaxJumps;
	}
	
	return Plugin_Handled;
}

public void OnMapStart()
{
	char szBuffer[256];
	BuildPath(Path_SM, szBuffer, 256, "data/maniac/doors.cfg");
	KeyValues hKeyValues = new KeyValues("Doors");
	if(hKeyValues.ImportFromFile(szBuffer))
	{
		hKeyValues.Rewind();
		GetDoorInfo(hKeyValues);
		GetCurrentMap(szBuffer, 256);
		if(hKeyValues.JumpToKey(szBuffer))
		{
			GetDoorInfo(hKeyValues);
		}
	}
	
	delete hKeyValues;
}
	

void GetDoorInfo(KeyValues hKeyValues)
{
	hKeyValues.GetString("classname", DoorInfo[0], 64);
	hKeyValues.GetString("targetname", DoorInfo[1], 64);
	hKeyValues.GetString("input", DoorInfo[2], 64);
	hKeyValues.GetVector("position", DoorPosition, view_as<float>({0.0, 0.0, 0.0}));
}

public void OnConVarChange(ConVar convar, const char[] newValue, const char[] oldValue)
{
	if(convar == cvarHideTime)
	{
		g_iHideTime = cvarHideTime.IntValue;
	}
	else if(convar == cvarSpawnHealthT)
	{
		g_iSpawnHealthT = cvarSpawnHealthT.IntValue;
	}
	else if(convar == cvarSpawnHealthCT)
	{
		g_iSpawnHealthCT = cvarSpawnHealthCT.IntValue;
	}
	else if(convar == cvarDoubleJumpHeight)
	{
		g_fDoubleJumpHeight = cvarDoubleJumpHeight.FloatValue;
	}
	else if(convar == cvarEnableSprint)
	{
		SprintEnable = cvarEnableSprint.BoolValue;
	}
	else if(convar == cvarMaxSprint)
	{
		g_iSprintMax = cvarMaxSprint.IntValue;
	}
	else if(convar == cvarSprintInc)
	{
		g_iSprintInc = cvarSprintInc.IntValue;
	}
	else if(convar == cvarSprintIncDelay)
	{
		g_fSprintIncDelay = cvarSprintIncDelay.FloatValue;
	}
	else if(convar == cvarSprintMinUse)
	{
		g_iSprintMinUse = cvarSprintMinUse.IntValue;
	}
	else if(convar == cvarSprintStart)
	{
		g_iSprintStart = cvarSprintStart.IntValue;
	}
	else if(convar == cvarSprintCoolDown)
	{
		g_fSprintCoolDown = cvarSprintCoolDown.FloatValue;
	}
	else if(convar == cvarSprintSpeed)
	{
		g_fSprintSpeed = cvarSprintSpeed.FloatValue;
	}
	else if(convar == cvarSpawnSpeed)
	{
		g_fSpawnSpeed = cvarSpawnSpeed.FloatValue;
	}
	else if(convar == cvarGiveArmor)
	{
		Armor = cvarGiveArmor.IntValue;
	}
	else if(convar == cvarGiveHe)
	{
		Hegrenades = cvarGiveHe.IntValue;
	}
	else if(convar == cvarGiveFlash)
	{
		Flashbangs = cvarGiveFlash.IntValue;
	}
	else if(convar == cvarGiveSmoke)
	{
		Smokegrenades = cvarGiveSmoke.IntValue;
	}
	else if(convar == cvarDeagleMode)
	{
		DeagleMode = cvarDeagleMode.BoolValue;
	}
	else if(convar == cvarHSOnlyMode)
	{
		HeadShotOnly = cvarHSOnlyMode.BoolValue;
	}
	else if(convar == cvarDeagleAmmo)
	{
		DeagleAmmo = cvarDeagleAmmo.IntValue;
	}
	else if(convar == cvarDeaglePrimaryAmmo)
	{
		DeaglePrimaryAmmo = cvarDeaglePrimaryAmmo.IntValue;
	}
	else if(convar == cvarGiveAmmoForSomeKills)
	{
		g_iGiveAmmoForSomeKills = cvarGiveAmmoForSomeKills.IntValue;
	}
	else if(convar == cvarSomeKillsForGiveAmmo)
	{
		g_iSomeKillsForGiveAmmo = cvarSomeKillsForGiveAmmo.IntValue;
	}
	else if(convar == cvarHealthPerHumanT)
	{
		g_iHealthPerHumanT = cvarHealthPerHumanT.IntValue;
	}
	else if(convar == cvarMaxJumps)
	{
		g_iMaxJumps = cvarMaxJumps.IntValue;
	}
}

public void OnLibraryAdded(const char[] library)
{
	if(!g_bLibrary && strcmp(library, "maniac_core", false) == 0)
	{
		g_bLibrary = true;
	}
}

public void OnLibraryRemoved(const char[] library)
{
	if(g_bLibrary && strcmp(library, "maniac_core", false) == 0)
	{
		g_bLibrary = false;
	}
}

public bool Maniac_OnAdminOpenedSets(int iClient, const char[] mode)
{
	if(strcmp(mode, "maniac", false) == 0)
	{
		MAdmin_ManiacSets(iClient);
		return true;
	}
	return false;
}

void MAdmin_ManiacSets(int iClient, int iItem = 0)
{
	char szBuffer[256];
	Menu hMenu = new Menu(MAdmin_Sets_Menu);
	hMenu.SetTitle("Маньяк | Настройки Maniac");
	
	FormatEx(szBuffer, 256, "Хайд-Тайм: %i", g_iHideTime); 								hMenu.AddItem("", szBuffer, Set[iClient] == 0 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Начальное ХП для Т: %i", g_iSpawnHealthT);					hMenu.AddItem("", szBuffer, Set[iClient] == 1 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Начальное ХП для КТ: %i", g_iSpawnHealthCT);				hMenu.AddItem("", szBuffer, Set[iClient] == 2 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Стандартная скорость: %.2f", g_fSpawnSpeed);				hMenu.AddItem("", szBuffer, Set[iClient] == 3 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Высота второго прыжка: %.0f", g_fDoubleJumpHeight);		hMenu.AddItem("", szBuffer, Set[iClient] == 4 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Спринт: [%s]", SprintEnable ? "✔":"×");					hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Скорость спринта: %.2f", g_fSprintSpeed);					hMenu.AddItem("", szBuffer, Set[iClient] == 6 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Начальный спринт: %i", g_iSprintStart);					hMenu.AddItem("", szBuffer, Set[iClient] == 7 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Макс. спринт: %i", g_iSprintMax);							hMenu.AddItem("", szBuffer, Set[iClient] == 8 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Мин. спринт для use: %i", g_iSprintMinUse);				hMenu.AddItem("", szBuffer, Set[iClient] == 9 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Спринт++: %i", g_iSprintInc);								hMenu.AddItem("", szBuffer, Set[iClient] == 10 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Спринт++ интервал: %.1f", g_fSprintIncDelay);				hMenu.AddItem("", szBuffer, Set[iClient] == 11 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Спринт КД после use: %.1f", g_fSprintCoolDown);			hMenu.AddItem("", szBuffer, Set[iClient] == 12 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Выдача брони: %i", Armor);									hMenu.AddItem("", szBuffer, Set[iClient] == 13 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Выдача HEGrenades: %i", Hegrenades);						hMenu.AddItem("", szBuffer, Set[iClient] == 14 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Выдача Flashbang: %i", Flashbangs);						hMenu.AddItem("", szBuffer, Set[iClient] == 15 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Выдача Smokegrenade: %i", Smokegrenades);					hMenu.AddItem("", szBuffer, Set[iClient] == 16 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Дигл-режим: [%s]", DeagleMode ? "✔":"×");					hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Хедшот-Онли-режим: [%s]", HeadShotOnly ? "✔":"×");		hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Дигл-обойма: %i", DeagleAmmo);								hMenu.AddItem("", szBuffer, Set[iClient] == 19 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Дигл-магазин: %i", DeaglePrimaryAmmo);						hMenu.AddItem("", szBuffer, Set[iClient] == 20 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "%i kills = +X ammo", g_iSomeKillsForGiveAmmo);				hMenu.AddItem("", szBuffer, Set[iClient] == 21 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "X kills = +%i ammo", g_iGiveAmmoForSomeKills);				hMenu.AddItem("", szBuffer, Set[iClient] == 22 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "ХП для Т за 1 КТ: %i", g_iHealthPerHumanT);				hMenu.AddItem("", szBuffer, Set[iClient] == 23 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Макс кол-во прыжков: %i", g_iMaxJumps);					hMenu.AddItem("", szBuffer, Set[iClient] == 24 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);



	hMenu.ExitBackButton = true;
	hMenu.DisplayAt(iClient, iItem, 0);
}

public int MAdmin_Sets_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action != MenuAction_Select)
	{
		if(action == MenuAction_Cancel)
		{
			if(iItem == MenuCancel_ExitBack)
				Maniac_OpenAdminMenu(iClient);
			
			Set[iClient] = -1;
		}
		else if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}
	Set[iClient] = iItem;
	
	if(Set[iClient] == 5)
		cvarEnableSprint.SetBool(!SprintEnable);
	else if(Set[iClient] == 17)
		cvarDeagleMode.SetBool(!DeagleMode);
	else if(Set[iClient] == 18)
		cvarHSOnlyMode.SetBool(!HeadShotOnly);
	
	
	MAdmin_ManiacSets(iClient, hMenu.Selection);
	return -1;
}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(Set[iClient] != -1)
	{
		int iValue = StringToInt(sArgs);
		float fValue = StringToFloat(sArgs);
		
		switch(Set[iClient])
		{
			case 0:
			{
				if(0 <= iValue <= 75)
					cvarHideTime.SetInt(iValue);
			}
			case 1:
			{
				if(1 <= iValue <= 25000)
					cvarSpawnHealthT.SetInt(iValue);
			}
			case 2:
			{
				if(1 <= iValue <= 25000)
					cvarSpawnHealthCT.SetInt(iValue);
			}
			case 3:
			{
				if(0.5 <= fValue <= 2.5)
					cvarSpawnSpeed.SetFloat(fValue);
			}
			case 4:
			{
				if(150 <= iValue <= 1000)
					cvarDoubleJumpHeight.SetFloat(fValue);
			}
			case 6:
			{
				if(1.0 < iValue <= 5.0)
					cvarSprintSpeed.SetFloat(fValue);
			}
			case 7:
			{
				if(0 <= iValue <= g_iSprintMax)
					cvarSprintStart.SetInt(iValue);
			}
			case 8:
			{
				if(0 <= iValue <= 10000)
				{
					cvarMaxSprint.SetInt(iValue);
					
					if(g_iSprintStart > g_iSprintMax)
						cvarSprintStart.SetInt(g_iSprintMax);
					if(g_iSprintMinUse > g_iSprintMax)
						cvarSprintMinUse.SetInt(g_iSprintMax);
				}
					

			}
			case 9:
			{
				if(0 <= iValue <= g_iSprintMax)
					cvarSprintMinUse.SetInt(g_iSprintMax);
			}
			case 10:
			{
				if(0 <= iValue <= 10000)
					cvarSprintInc.SetInt(g_iSprintMax);
			}
			case 11:
			{
				if(0 < fValue <= 30.0)
					cvarSprintIncDelay.SetFloat(fValue);
			}
			case 12:
			{
				if(0 < fValue <= 30.0)
					cvarSprintCoolDown.SetFloat(fValue);
			}
			case 13:
			{
				if(0 <= iValue <= 100)
					cvarGiveArmor.SetInt(iValue);
			}
			case 14:
			{
				if(0 <= iValue <= 10)
				{
					cvarGiveHe.SetInt(iValue);
				}
			}
			case 15:
			{
				if(0 <= iValue <= 10)
				{
					cvarGiveFlash.SetInt(iValue);
				}
			}
			case 16:
			{
				if(0 <= iValue <= 10)
				{
					cvarGiveSmoke.SetInt(iValue);
				}
			}
			case 17:
			{
				if(0 <= iValue <= 7)
				{
					cvarDeagleAmmo.SetInt(iValue);
				}
			}
			case 20:
			{
				if(0 <= iValue <= 100)
				{
					cvarDeaglePrimaryAmmo.SetInt(iValue);
				}
			}
			case 21:
			{
				if(0 <= iValue <= 64)
				{
					cvarSomeKillsForGiveAmmo.SetInt(iValue);
				}
			}
			case 22:
			{
				if(0 <= iValue <= 50)
				{
					cvarGiveAmmoForSomeKills.SetInt(iValue);
				}
			}
			case 23:
			{
				if(0 <= iValue <= 3000)
				{
					cvarHealthPerHumanT.SetInt(iValue);
				}
			}
			case 24:
			{
				if(0 < iValue <= 15)
				{
					cvarMaxJumps.SetInt(iValue);
				}
			}
		}
		int iItem = Set[iClient] / 7;
		Set[iClient] = -1;
		MAdmin_ManiacSets(iClient, iItem * 7);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int iClient)
{
	MaxJumps[iClient] = g_iMaxJumps;
	Team[iClient] = GetClientTeam(iClient);
	SDKHook(iClient, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

public void OnClientDisconnect(int iClient)
{
	MaxJumps[iClient] = g_iMaxJumps;
	Set[iClient] = -1;
	ResetClientSettings(iClient);
}

void ResetClientSettings(int iClient)
{
	Kills[iClient] = 0;
	RemoveParticle(iClient);
	Sprint[iClient] = g_iSprintStart;
	SprintToggle[iClient] = false;
	delete g_hTimerSprint[iClient];
	delete g_hTimerSprintCoolDown[iClient];
}

void RemoveParticle(int iClient)
{
	if((SprintParticle[iClient] = EntRefToEntIndex(SprintParticle[iClient])) > 0 && IsValidEntity(SprintParticle[iClient]))
		RemoveEdict(SprintParticle[iClient]);
	
	SprintParticle[iClient] = -1;
}

public Action OnWeaponCanUse(int iClient, int iWeapon)
{
	char szBuffer[32];
	GetEdictClassname(iWeapon, szBuffer, 32);
	return (szBuffer[7] == 'k' || szBuffer[7] == 'c' || szBuffer[7] == 'h' || strncmp(szBuffer[7], "deagle", 6, false) == 0 || strncmp(szBuffer[7], "defus", 5, false) == 0 || strncmp(szBuffer[7], "flash", 5, false) == 0 || strncmp(szBuffer[7], "smoke", 5, false) == 0) ? Plugin_Continue:Plugin_Handled;
}

public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	delete g_hTimer;
	
	g_hTimer = CreateTimer(0.0, Timer_Hide, g_iHideTime);
	
	ManageObjectives();
}

void ManageObjectives()
{
	char sName[64];
	int iMax = GetMaxEntities();
	for (int i = MaxClients + 1; i <= iMax; i++)
	{
		if(!IsValidEntity(i) || !GetEdictClassname(i, sName, 64))
			continue;
		
		if (strcmp(sName, "func_buyzone", false) == 0 || strcmp(sName, "ambient_generic", false) == 0)
		{
			RemoveEdict(i);
		}
	}
}

public Action Timer_Hide(Handle hTimer, int iCountDown)
{
	g_hTimer = null;
	if(iCountDown > 0)
	{
		for (int i = 1; i <= MaxClients; i++)	
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i))
				PrintCenterText(i, "%i", iCountDown);
		}
		
		g_hTimer = CreateTimer(1.0, Timer_Hide, --iCountDown);
		
	}
	else 
	{
		RemoveDoor();
		RecalcHealth();
		PrintCenterTextAll("");
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				if(Team[i] == 2)
				{
					SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
					FadeScreen(i, 0);
					SetEntityMoveType(i, MOVETYPE_WALK);
				}
			}
		}
	}
}

void RecalcHealth()
{
	int iT, iCT;
	if(g_iHealthPerHumanT == 0 || (iT = GetClientsCount(2, 1)) == 0 || (iCT = GetClientsCount(3, 1) - 1) < 1)
	{
		return;
	}
	
	int iHealth = (g_iHealthPerHumanT * iCT) / iT;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			SetEntData(i, m_iHealth, g_iSpawnHealthT + iHealth);
		}
	}
}

void RemoveDoor()
{
	if(DoorInfo[0][0])
	{
		char szBuffer[64];
		int iEntity; float fPos[3];
		while((iEntity = FindEntityByClassname(iEntity, DoorInfo[0])) != -1)
		{
			GetEntPropVector(iEntity, Prop_Data, "m_vecOrigin", fPos);
			GetEntPropString(iEntity, Prop_Data, "m_iName", szBuffer, 64);
			
			if((!DoorInfo[1][0] || strcmp(DoorInfo[1], szBuffer, false) == 0) && ((!DoorPosition[0] && !DoorPosition[1] && !DoorPosition[2]) || (DoorPosition[0] == fPos[0] && DoorPosition[1] == fPos[1] && DoorPosition[2] == fPos[2])))
			{
				AcceptEntityInput(iEntity, !DoorInfo[2][0] ? "kill":DoorInfo[2]);
				GF_OnManiacWasFree();
			}
		}
	}
}

int GetClientsCount(int iTeam = -1, int iAlive = -1)
{
	int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (iTeam == -1 || iTeam == GetClientTeam(i)) && (iAlive == -1 || view_as<bool>(iAlive) == IsPlayerAlive(i)))
		{
			iCount++;
		}
	}
	
	return iCount;
}

void GF_OnManiacWasFree()
{
	Call_StartForward(g_hGFwdOnManiacWasFree);
	Call_Finish();
}

public Action OnPlayerHurt(Event hEvent, const char[] event, bool bDontBroadcast)
{
	if(!HeadShotOnly)
		return Plugin_Continue;
	
	char szBuffer[16];
	hEvent.GetString("weapon", szBuffer, 16);
	
	if(strcmp(szBuffer, "knife", false) == 0 || strcmp(szBuffer, "hegrenade", false) == 0 || hEvent.GetInt("hitgroup") == 1)
		return Plugin_Continue;
	
	int	iClient = GetClientOfUserId(hEvent.GetInt("userid")),
		iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	if (iClient != iAttacker && 0 < iAttacker <= MaxClients && iClient > 0)
	{
		SetEntData(iClient, m_iHealth, (hEvent.GetInt("health") + hEvent.GetInt("dmg_health")), 4, true);
		SetEntData(iClient, g_iArmor, (hEvent.GetInt("armor") + hEvent.GetInt("dmg_armor")), 4, true);
	}
	return Plugin_Continue;
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	OnClientSpawned(GetClientOfUserId(hEvent.GetInt("userid")));
}

void OnClientSpawned(int iClient)
{
	ResetClientSettings(iClient);
	
	if(!IsFakeClient(iClient))
	{
		g_hTimerSprintCoolDown[iClient] = CreateTimer(g_fSprintCoolDown, Timer_SprintCoolDown, iClient);
		g_hTimerSprint[iClient] = CreateTimer(g_fSprintIncDelay, Timer_SprintInc, iClient, TIMER_REPEAT);
	}
	if(IsPlayerAlive(iClient))
	{
		CreateTimer(0.1, Timer_OnClientSpawned, GetClientUserId(iClient));
	}
}

public void OnPlayerDeath(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid")), iAttacker = GetClientOfUserId(hEvent.GetInt("attacker"));

	ResetClientSettings(iClient);
	
	if(!(0 < iAttacker <= MaxClients) || iClient == iAttacker || IsFakeClient(iAttacker))
		return;
	
	if(++Kills[iAttacker] >= g_iSomeKillsForGiveAmmo)
	{
		Kills[iAttacker] = 0;
		int iDeagle = GetPlayerWeaponSlot(iAttacker, 1);
		if(iDeagle > 0)
		{
			SetEntData(iAttacker, g_iAmmoOffset + (GetEntData(iDeagle, g_iPrimaryAmmoType) * 4), g_iGiveAmmoForSomeKills);
		}
	}
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	Team[iClient] = hEvent.GetInt("team");
}



public Action Timer_OnClientSpawned(Handle hTimer, int iClient)
{
	if((iClient = GetClientOfUserId(iClient)) > 0 && IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		int iIndex;
		for(int i; i < 2; i++)
		{
			if((iIndex = GetPlayerWeaponSlot(iClient, i)) != -1)
			{
				RemovePlayerItem(iClient, iIndex);
				AcceptEntityInput(iIndex, "kill");
			}
		}
		Speed[iClient] = g_fSpawnSpeed;
		if(GF_OnClientChangeSpeed(iClient, 0, Speed[iClient]))
			SetEntDataFloat(iClient, m_flLaggedMovementValue, Speed[iClient]);
		
		SprintToggle[iClient] = SprintEnable;
		if(Team[iClient] == 2)
		{
			if(DeagleMode)
			{
				int iDeagle = GivePlayerItem(iClient, "weapon_deagle");
				SetEntData(iDeagle, g_iClip1, DeagleAmmo, 4, true);
				SetEntData(iClient, g_iAmmoOffset + (GetEntData(iDeagle, g_iPrimaryAmmoType) * 4), DeaglePrimaryAmmo);
			}
			if(g_hTimer)
			{
				SetEntProp(iClient, Prop_Data, "m_takedamage", 0, 1);
				FadeScreen(iClient, 255);
				SetEntityMoveType(iClient, MOVETYPE_NONE);
			}
			SetEntData(iClient, m_iHealth, g_iSpawnHealthT);
		}
		else if(Team[iClient] == 3)
		{
			SetEntData(iClient, m_iHealth, g_iSpawnHealthCT);
		}
		
		for(int i;i <= 10; i++)
		{
			if(i < Hegrenades)
				GivePlayerItem(iClient, "weapon_hegrenade");
			if(i < Flashbangs)
				GivePlayerItem(iClient, "weapon_flashbang");
			if(i < Smokegrenades)
				GivePlayerItem(iClient, "weapon_smokegrenade");
		}
		
		SetEntData(iClient, g_iArmor, Armor);
	}
}

bool GF_OnClientChangeSpeed(int iClient, int iType, float& fSpeed)
{
	bool bResult = true;
	Call_StartForward(g_hGFwdOnClientChangeSpeed);
	Call_PushCell(iClient);
	Call_PushCell(iType);
	Call_PushFloatRef(fSpeed);
	Call_Finish(bResult);
	
	return bResult;
}

public Action Timer_SprintCoolDown(Handle hTimer, int iClient)
{
	g_hTimerSprintCoolDown[iClient] = null;
}

public Action Timer_SprintInc(Handle hTimer, int iClient)
{
	if(IsClientInGame(iClient) && IsPlayerAlive(iClient))
	{
		if((Sprint[iClient] += g_iSprintInc) > g_iSprintMax)
			Sprint[iClient] = g_iSprintMax;
		
		DisplayClientSprint(iClient);
		return Plugin_Continue;
	}
	
	g_hTimerSprint[iClient] = null;
	return Plugin_Stop;
}


public void OnPlayerRunCmdPost(int iClient, int iButtons)
{
	static int iPrevButtons[MAXPLAYERS + 1], iPrevFlags[MAXPLAYERS + 1], Jumps[MAXPLAYERS + 1];
	
	int fCurFlags = GetEntityFlags(iClient);

	if (iPrevFlags[iClient] & FL_ONGROUND && !(fCurFlags & FL_ONGROUND)) 
	{
		Jumps[iClient]++;
	}
	else if(fCurFlags & FL_ONGROUND) 
	{
		Jumps[iClient] = 0;
	}
	else if(!(iPrevButtons[iClient] & IN_JUMP) && iButtons & IN_JUMP && Jumps[iClient] < MaxJumps[iClient])
	{						
		Jumps[iClient]++;						
		float fVelocity[3];
		GetEntPropVector(iClient, Prop_Data, "m_vecVelocity", fVelocity);
		fVelocity[2] = g_fDoubleJumpHeight;
		TeleportEntity(iClient, NULL_VECTOR, NULL_VECTOR, fVelocity);
	}
	
	iPrevFlags[iClient] = fCurFlags;		
	
	if(!SprintEnable || g_hTimerSprintCoolDown[iClient] || ((!SprintToggle[iClient] || Sprint[iClient] < g_iSprintMinUse) && !(iPrevButtons[iClient] & IN_USE)))
	{
		iPrevButtons[iClient]	= iButtons;
		return;
	}
	if(iButtons & IN_USE)
	{
		if(iPrevButtons[iClient] & IN_USE)
		{
			if(!SprintToggle[iClient])
				return;
			
			
			if(Sprint[iClient])
			{
				Sprint[iClient]--;

				if(!Sprint[iClient])
				{
					RemoveParticle(iClient);
					SetEntDataFloat(iClient, m_flLaggedMovementValue, Speed[iClient]);
				}
				DisplayClientSprint(iClient);
			}
		}
		else if(GF_OnClientChangeSpeed(iClient, 1, g_fSprintSpeed))
		{
			delete g_hTimerSprint[iClient];
			SetClientSprintParticle(iClient);
			SetEntDataFloat(iClient, m_flLaggedMovementValue, g_fSprintSpeed);
		}
	}
	else if(iPrevButtons[iClient] & IN_USE)
	{
		if(GF_OnClientChangeSpeed(iClient, 2, Speed[iClient]))
			SetEntDataFloat(iClient, m_flLaggedMovementValue, Speed[iClient]);
		
		delete g_hTimerSprint[iClient];
		RemoveParticle(iClient);
		g_hTimerSprintCoolDown[iClient] = CreateTimer(g_fSprintCoolDown, Timer_SprintCoolDown, iClient);
		g_hTimerSprint[iClient] = CreateTimer(g_fSprintIncDelay, Timer_SprintInc, iClient, TIMER_REPEAT);
		DisplayClientSprint(iClient);
	}
	
	iPrevButtons[iClient] = iButtons;
}

void SetClientSprintParticle(int iClient)
{
	int iEntity = CreateEntityByName("info_particle_system");
	
	if (iEntity > 0 && IsValidEdict(iEntity))
	{
		SprintParticle[iClient] = EntIndexToEntRef(iEntity);
		char szName[64]; float position[3];
		GetEntPropVector(iClient, Prop_Send, "m_vecOrigin", position);
		TeleportEntity(iEntity, position, NULL_VECTOR, NULL_VECTOR);
		GetEntPropString(iClient, Prop_Data, "m_iName", szName, 64);
		DispatchKeyValue(iEntity, "targetname", "tf2particle");
		DispatchKeyValue(iEntity, "parentname", szName);
		DispatchKeyValue(iEntity, "effect_name", "embers_small_01");
		DispatchSpawn(iEntity);
		SetVariantString("!activator");
		AcceptEntityInput(iEntity, "SetParent", iClient);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "start");
	}
}



stock void FadeScreen(int iClient, int iAmount)
{	
	Handle message = StartMessageOne("Fade", iClient);
	for(int i;i < 7; i++)
	{
		if(i < 3)	BfWriteShort(message, i < 2 ? 1536:iAmount == 0 ? 0x0010:0x0008);
		else		BfWriteByte(message, i < 6 ? 0:iAmount);
	}
	EndMessage();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (strncmp(classname, "weapon", 6, false) == 0 && (classname[7] != 'k' && classname[7] != 'c' && classname[7] != 'h' && strncmp(classname[7], "flash", 5, false) && strncmp(classname[7], "smoke", 5, false) && strncmp(classname[7], "deagle", 6, false) && strncmp(classname[7], "defus", 5, false)))
	{
		AcceptEntityInput(entity, "kill");
	}
}


void DisplayClientSprint(int iClient)
{
	char szBuffer[256];
	SetGlobalTransTarget(iClient);
	FormatEx(szBuffer, 256, "%t: %i ﹪ [%s]", "Current sprint", RoundToNearest(float(Sprint[iClient]) / float(g_iSprintMax) * 100.0), g_hTimerSprintCoolDown[iClient] || !SprintToggle[iClient] ? "×":"✔");
	Handle hBuffer = StartMessageOne("KeyHintText", iClient);
	BfWriteByte(hBuffer, 1);
	BfWriteString(hBuffer, szBuffer);
	EndMessage();
}

public int Native_Maniac_ClientToggleSprint(Handle hPlugin,	int numParams)
{
	SprintToggle[GetNativeCell(1)] = view_as<bool>(GetNativeCell(2));
}

public int Native_Maniac_GetClientSpeed(Handle hPlugin,	int numParams)
{
	return view_as<int>(Speed[GetNativeCell(1)]);
}