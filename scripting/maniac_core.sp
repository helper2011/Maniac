#include <cstrike>
#include <helco>
#include <sdktools_functions>

const int MEMORY = 100;
Handle	g_hTimer, 
		g_hGFwdOnAdminOpenedSets;
int 	Team[MAXPLAYERS + 1],
		Round[MAXPLAYERS + 1], 
		Time[MAXPLAYERS + 1], 
		Set[MAXPLAYERS + 1] = {-1, ...},
		Maniac[MAXPLAYERS + 1],
		Maniacs,
		Ratio,
		Tokens,
		Maps,
		RoundEndWinTeam,
		MapDelayForClear,
		maxRounds, 
		minRoundTime,
		Queue[MAXPLAYERS + 1],
		Queues,
		QueueSave[MAXPLAYERS + 1] = {-1, ...},
		Force[MAXPLAYERS + 1],
		Forces,
		BanTimeForDisconnect,
		g_iCollision,
		Rounds[MEMORY],
		QueueSaves[MEMORY];
char	Token[MEMORY][40];
ConVar	cvarRatio, 
		cvarmaxRounds, 
		cvarMinRoundTime, 
		cvarMapDelayForClear, 
		cvarAutoBalance, 
		cvarRoundEndImmortal, 
		cvarCollision, 
		cvarRoundEndWinTeam,
		cvarBanTimeForDisconnect;
bool	AntiSpam[MAXPLAYERS + 1][5],
		g_bDelayTimer, 
		AutoBalance, 
		RoundEnd, 
		RoundEndImmortal, 
		Collision;
		
public Plugin myinfo = 
{
    name = "Maniac Core",
    version = "1.0",
    author = "hEl"
};		
	

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max) 
{
	CreateNative("Maniac_OpenAdminMenu",	Native_Maniac_OpenAdminMenu);	
	CreateNative("Maniac_PrintToChat",		Native_Maniac_PrintToChat);	
	CreateNative("Maniac_PrintToChatAll",	Native_Maniac_PrintToChatAll);	

	RegPluginLibrary("maniac_core");

	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("maniac_core.phrases");
	(FindConVar("mp_restartgame")).AddChangeHook(OnRestartGame);
	
	Ratio					= ConVarManageInt((cvarRatio					= CreateConVar("maniac_ratio", "4")));
	maxRounds				= ConVarManageInt((cvarmaxRounds				= CreateConVar("maniac_maxrounds", "2")));
	minRoundTime			= ConVarManageInt((cvarMinRoundTime				= CreateConVar("maniac_min_roundtime", "45")));
	MapDelayForClear		= ConVarManageInt((cvarMapDelayForClear			= CreateConVar("maniac_map_delay_for_clear_tokens", "7")));
	RoundEndWinTeam			= ConVarManageInt((cvarRoundEndWinTeam			= CreateConVar("maniac_round_end_win_team", "3")));
	BanTimeForDisconnect	= ConVarManageInt((cvarBanTimeForDisconnect		= CreateConVar("maniac_ban_time_for_disconnect", "30")));
	
	AutoBalance				= ConVarManageBool((cvarAutoBalance				= CreateConVar("maniac_autobalance", "1")));
	RoundEndImmortal		= ConVarManageBool((cvarRoundEndImmortal		= CreateConVar("maniac_round_end_immortal", "1")));
	Collision				= ConVarManageBool((cvarCollision				= CreateConVar("maniac_collision", "0")));
	
	g_hGFwdOnAdminOpenedSets = CreateGlobalForward("Maniac_OnAdminOpenedSets", ET_Hook, Param_Cell, Param_String);
	
	HookEvent("player_disconnect", OnPlayerDisconnect);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_team", OnPlayerTeam_Pre, EventHookMode_Pre);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);

	AddCommandListener(Command_Jointeam, "jointeam");
	AddCommandListener(Command_Block, "kill");
	AddCommandListener(Command_Block, "explode");
	AddCommandListener(Command_Block, "spectate");
	AddCommandListener(Command_Block, "joinclass");
	
	g_iCollision = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	RegAdminCmd("sm_madmin", Command_MAdmin, ADMFLAG_ROOT);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			Team[i] = GetClientTeam(i);
			ManageTeam(i);
		}
	}
}

int ConVarManageInt(ConVar cvar)
{
	cvar.AddChangeHook(OnConvarChange);
	return cvar.IntValue;
}

bool ConVarManageBool(ConVar cvar)
{
	cvar.AddChangeHook(OnConvarChange);
	return cvar.BoolValue;
}



public Action CS_OnTerminateRound(float& delay, CSRoundEndReason& reason)
{
	int iValue = view_as<int>(reason);
	if(iValue == 12)
	{
		reason = view_as<CSRoundEndReason>(RoundEndWinTeam == 3 ? 7:8);
		
		if(RoundEndWinTeam == 3)
		{
			CreateTimer(0.5, Timer_SetScore);
		}

		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public Action Timer_SetScore(Handle hTimer)
{
	int iValue[2]; iValue[0] = GetTeamScore(RoundEndWinTeam), iValue[1] = GetTeamScore(RoundEndWinTeam == 3 ? 2:3);
	CS_SetTeamScore(RoundEndWinTeam, iValue[0] + 1); 
	SetTeamScore(RoundEndWinTeam, iValue[0] + 1);
	
	CS_SetTeamScore(RoundEndWinTeam == 3 ? 2:3, iValue[1] == 0 ? 0:iValue[1] - 1);  
	SetTeamScore(RoundEndWinTeam == 3 ? 2:3, iValue[1] == 0 ? 0:iValue[1] - 1);
}

public Action Command_MAdmin(int iClient, int iArgs)
{
	if(iClient > 0)
		MAdmin(iClient);
	
	return Plugin_Handled;
}

void MAdmin(int iClient)
{
	Menu hMenu = new Menu(MAdmin_Menu);
	hMenu.SetTitle("Маньяк | Админ-меню");
	hMenu.AddItem("", "Выбрать маньяка");
	hMenu.AddItem("", "Текущая очередь");
	hMenu.AddItem("", "Текущий баланс команд\n ");

	hMenu.AddItem("", "Настройки ядра");
	hMenu.AddItem("", "Настройки Maniac");
	hMenu.AddItem("", "Настройки Deathrun");
	hMenu.Display(iClient, 0);
}

public int MAdmin_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action != MenuAction_Select)
	{
		if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}
	
	if(iItem == 0)
	{
		MAdmin_Force(iClient);
	}
	else if(iItem == 1)
	{
		MAdmin_Queue(iClient);
	}
	else if(iItem == 2)
	{
		MAdmin_Balance(iClient);
	}
	else if(iItem == 3)
	{
		MAdmin_Sets(iClient);
	}
	else if(!OnAdminOpenedSets(iClient, iItem == 4 ? "maniac":"deathrun"))
	{
		PrintToChat2(iClient, "%t%t", "Tag", "This mode is disabled");
		MAdmin(iClient);
	}
	
	return -1;
}

void MAdmin_Queue(int iClient)
{
	char szBuffer[256];

	Menu hMenu = new Menu(MAdmin_Queue_Menu);
	hMenu.SetTitle("Маньяк | Текущая очередь: %i", Queues);
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			FormatEx(szBuffer, 256, "%N [%i]", i, FindValue(Queue, Queues, i) + 1);
			hMenu.AddItem("", szBuffer, ITEMDRAW_DISABLED);
		}
	}
	
	hMenu.ExitBackButton = true;
	hMenu.Display(iClient, 0);
}


public int MAdmin_Queue_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action != MenuAction_Select)
	{
		if(action == MenuAction_Cancel && iItem == MenuCancel_ExitBack)
			MAdmin(iClient);
		else if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}
	return -1;
}

void MAdmin_Force(int iClient, int iItem = 0)
{
	char szBuffer[512], szId[16];
	
	for(int i;i < Forces; i++)
	{
		if(i == 0)
			FormatEx(szBuffer, 256, "\nВыбраны: %N", Force[i]);
		else if(i == 1)
			Format(szBuffer, 256, "%s,\n%N", szBuffer, Force[i]);
	}
	
	Menu hMenu = new Menu(MAdmin_Force_Menu);
	hMenu.SetTitle("Маньяк | Выбор маньяка%s", szBuffer);
	hMenu.AddItem("", "Очистить список");

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Team[i] == 3 && FindValue(Force, Forces, i) == -1)
		{
			IntToString(GetClientUserId(i), szId, 16);
			FormatEx(szBuffer, 256, "%N", i);
			hMenu.AddItem(szId, szBuffer);
		}
	}
	
	hMenu.ExitBackButton = true;
	hMenu.DisplayAt(iClient, iItem, 0);
}


public int MAdmin_Force_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action != MenuAction_Select)
	{
		if(action == MenuAction_Cancel && iItem == MenuCancel_ExitBack)
			MAdmin(iClient);
		else if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}

	if(iItem == 0)
	{
		Forces = 0;
	}
	else
	{
		char szId[16];
		hMenu.GetItem(iItem, szId, 16);
		int iTarget = GetClientOfUserId(StringToInt(szId));
		
		if(iTarget > 0 && FindValue(Force, Forces, iTarget) == -1)
		{
			PushValue(Force, Forces, iTarget);
			MAdmin_Force(iClient);
		}
		else
			PrintToChat2(iClient, "%t%t", "Tag", "This client is unavailbale");
	}
	
	MAdmin_Force(iClient, hMenu.Selection);
	return -1;
}

void MAdmin_Balance(int iClient, int iItem = 0)
{
	Menu hMenu = new Menu(MAdmin_Balance_Menu);
	hMenu.SetTitle("Маньяк | Баланс");
	
	char szBuffer[256], szId[16]; int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && Team[i] > 1)
		{
			iCount++;
			IntToString(GetClientUserId(i), szId, 16);
			FormatEx(szBuffer, 256, "%N [%s]", i, Team[i] == 2 ? "Т":"КТ");
			hMenu.AddItem(szId, szBuffer);
		}
	}
	
	hMenu.ExitBackButton = true;
	
	if(iCount == 0)
	{
		delete hMenu;
		MAdmin(iClient);
	}
	else	hMenu.DisplayAt(iClient, iItem, 0);
}

public int MAdmin_Balance_Menu(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	if(action != MenuAction_Select)
	{
		if(action == MenuAction_Cancel && iItem == MenuCancel_ExitBack)
			MAdmin(iClient);
		if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}

	char szId[16];
	hMenu.GetItem(iItem, szId, 16);
	int iTarget = GetClientOfUserId(StringToInt(szId));
	
	if(iTarget > 0 && Team[iTarget] > 1)
	{
		ChangeClientTeam(iTarget, Team[iTarget] == 2 ? 3:2);
		
		if(!IsFakeClient(iTarget))
			PrintToChat2(iTarget, "%t%t", "Tag", "You moved to another team by admin", iClient, Team[iTarget] == 2 ? "T":"CT");
	}
	else
		PrintToChat2(iClient, "%t%t", "Tag", "This client is unavailbale");
	
	MAdmin_Balance(iClient, hMenu.Selection);
	return -1;
}

void MAdmin_Sets(int iClient, int iItem = 0)
{
	char szBuffer[256];
	Menu hMenu = new Menu(MAdmin_Sets_Menu);
	hMenu.SetTitle("Маньяк | Настройки ядра");
	
	FormatEx(szBuffer, 256, "1 Т = %i CT", Ratio); 												hMenu.AddItem("", szBuffer, Set[iClient] == 0 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Мин. время раунда для Т: %i", minRoundTime);						hMenu.AddItem("", szBuffer, Set[iClient] == 1 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Макс. кол-во раундов для Т: %i", maxRounds);						hMenu.AddItem("", szBuffer, Set[iClient] == 2 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Очистка токенов раз в %i карт", MapDelayForClear);					hMenu.AddItem("", szBuffer, Set[iClient] == 3 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);
	FormatEx(szBuffer, 256, "Бан за дисконнект из Т: %i мин.", BanTimeForDisconnect);			hMenu.AddItem("", szBuffer, Set[iClient] == 4 ? ITEMDRAW_DISABLED:ITEMDRAW_DEFAULT);

	FormatEx(szBuffer, 256, "Автобаланс: [%s]", AutoBalance ? "✔":"×");						hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Роунд Энд Вин: [%s]", RoundEndWinTeam == 3 ? "КТ":"Т");			hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Колизия: [%s]", Collision ? "✔":"×");								hMenu.AddItem("", szBuffer);
	FormatEx(szBuffer, 256, "Бессмертие в конце раунда: [%s]", RoundEndImmortal ? "✔":"×");	hMenu.AddItem("", szBuffer);
	
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
				MAdmin(iClient);
			
			Set[iClient] = -1;
		}
		else if(action == MenuAction_End)
			delete hMenu;
		
		return -1;
	}
	
	if(iItem < 5)
		Set[iClient] = iItem;
	else if(iItem == 5)
		cvarAutoBalance.SetBool(!AutoBalance);
	else if(iItem == 6)
		cvarRoundEndWinTeam.SetInt(RoundEndWinTeam == 3 ? 2:3);
	else if(iItem == 7)
		cvarCollision.SetBool(!Collision);
	else if(iItem == 8)
		cvarRoundEndImmortal.SetBool(!RoundEndImmortal);
	
	MAdmin_Sets(iClient, hMenu.Selection);
	return -1;
}

public Action OnClientSayCommand(int iClient, const char[] command, const char[] sArgs)
{
	if(Set[iClient] != -1)
	{
		int iValue = StringToInt(sArgs);
		
		switch(Set[iClient])
		{
			case 0:
			{
				if(0 < iValue <= 64)
					cvarRatio.SetInt(iValue);
			}
			case 1:
			{
				if(0 <= iValue <= 180)
					cvarMinRoundTime.SetInt(iValue);
			}
			case 2:
			{
				if(0 < iValue <= 5)
					cvarmaxRounds.SetInt(iValue);
			}
			case 3:
			{
				if(0 <= iValue <= 10)
					cvarMapDelayForClear.SetInt(iValue);
			}
			case 4:
			{
				if(0 <= iValue <= 150)
					cvarBanTimeForDisconnect.SetInt(iValue);
			}

		}
		Set[iClient] = -1;
		MAdmin_Sets(iClient);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

bool OnAdminOpenedSets(int iClient, const char[] mode)
{
	bool bResult;
	Call_StartForward(g_hGFwdOnAdminOpenedSets);
	Call_PushCell(iClient);
	Call_PushString(mode);
	Call_Finish(bResult);
	
	return bResult;
}


public void OnMapStart()
{
	AddHostageZone();
	
	if(MapDelayForClear > 0 && ++Maps >= MapDelayForClear)
	{
		Maps = 0;
		Tokens = 0;
	}
}

public void OnRestartGame(ConVar convar, const char[] newValue, const char[] oldValue)
{
	if(g_hTimer && StringToInt(newValue) > 0)
		delete g_hTimer;
}

public void OnConvarChange(ConVar convar, const char[] newValue, const char[] oldValue)
{
	if(convar == cvarRatio)
	{
		Ratio = cvarRatio.IntValue;
	}
	else if(convar == cvarmaxRounds)
	{
		maxRounds = cvarmaxRounds.IntValue;
	}
	else if(convar == cvarMinRoundTime)
	{
		minRoundTime = cvarMinRoundTime.IntValue;
	}
	else if(convar == cvarMapDelayForClear)
	{
		MapDelayForClear = cvarMapDelayForClear.IntValue;
	}
	else if(convar == cvarAutoBalance)
	{
		AutoBalance = cvarAutoBalance.BoolValue;
	}
	else if(convar == cvarRoundEndImmortal)
	{
		RoundEndImmortal = cvarRoundEndImmortal.BoolValue;
	}
	else if(convar == cvarCollision)
	{
		Collision = cvarCollision.BoolValue;
	}
	else if(convar == cvarRoundEndWinTeam)
	{
		RoundEndWinTeam = cvarRoundEndWinTeam.IntValue;
		
		if(RoundEndWinTeam != 2 && RoundEndWinTeam != 3)
			RoundEndWinTeam = StringToInt(oldValue);
	}
	else if(convar == cvarBanTimeForDisconnect)
	{
		BanTimeForDisconnect = cvarBanTimeForDisconnect.IntValue;
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!Collision && strcmp(classname, "hegrenade_projectile", false) == 0 || strcmp(classname, "flashbang_projectile", false) == 0 || strcmp(classname, "smokegrenade_projectile", false) == 0)
	{
		SetEntData(entity, g_iCollision, 2, 4, true);
	}
}


public Action Command_Jointeam(int iClient, const char[] command, int iArgs)
{
	if(iClient == 0 || iArgs == 0)
		return Plugin_Continue;
	
	char szBuffer[4];
	GetCmdArg(1, szBuffer, 4);
	int iTeam = StringToInt(szBuffer);

	if(iTeam == Team[iClient] || iTeam == 0)
		return Plugin_Handled;
	else if(!(0 < iTeam <= 3))
		return Plugin_Continue;
	
	if(iTeam == 1)
	{
		if(RoundEnd && Team[iClient] > 1)
		{
			if(IsNotSpam(iClient, 2))
			{
				PrintToChat2(iClient, "%t%t", "Tag", "You dont move to spec when round is end");
			}
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
	else if(Team[iClient] == 2)
	{
		if(AutoBalance && GetClientsCount(3) > 0)
		{
			if(IsNotSpam(iClient, 0))
			{
				PrintToChat2(iClient, "%t%t", "Tag", "You dont leave T command");
			}
			return Plugin_Handled;
		}
	}
	else if(iTeam == 2 && !CanGoForManiac(iClient))
	{
		if(IsNotSpam(iClient, 1))
		{
			PrintToChat2(iClient, "%t%t", "Tag", "You dont join to T command");
		}
		return Plugin_Handled;
	}
	
	ChangeClientTeam(iClient, iTeam);
	return Plugin_Handled;
}

bool IsNotSpam(int iClient, int iIndex)
{
	if(!AntiSpam[iClient][iIndex])
	{
		DataPack hPack;
		AntiSpam[iClient][iIndex] = view_as<bool>(CreateDataTimer(10.0, Timer_AntiSpam, hPack));
		hPack.WriteCell(iClient);
		hPack.WriteCell(iIndex);
		return true;
	}
	return false;
}

public Action Timer_AntiSpam(Handle hTimer, DataPack hPack)
{
	hPack.Reset();
	AntiSpam[hPack.ReadCell()][hPack.ReadCell()] = false;
	return Plugin_Stop;
}

public Action Command_Block(int iClient, const char[] command, int iArgs)
{
	if(Team[iClient] == 2 && (command[0] != 'j' || IsPlayerAlive(iClient)))
	{
		if(IsNotSpam(iClient, 3))
		{
			PrintToChat2(iClient, "%t%t", "Tag", "You dont self kill when for maniac");
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}



public void OnRoundStart(Event hEvent, const char[] event, bool bDontBroadcast)
{
	RoundEnd = false;
}

public void OnRoundEnd(Event hEvent, const char[] event, bool bDontBroadcast)
{
	RoundEnd = true;
	delete g_hTimer;
	if(RoundEndImmortal)
	{
		for(int i = 1; i <= MaxClients; i++)	if(IsClientInGame(i))
			SetEntProp(i, Prop_Data, "m_takedamage", 0, 1);
	}
	
	if(GetClientsCount(2) > 0)
		g_hTimer = CreateTimer(2.0, Timer_Balance, false);
}

public Action Timer_Balance(Handle hTimer, bool bClean)
{
	g_hTimer = null;

	char szBuffer[256];
	int iCT = GetClientsCount(3), iT = GetClientsCount(2), iTemp;
	if(AutoBalance && iCT > 0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && Team[i] == 2 && CheckManiacRound(i))
			{
				iCT++; iT--;
				CS_SwitchTeam(i, 3);
				FormatManiacString(szBuffer, 256, iTemp, i);
			}
		}
	}
	while(iT > 1 && iT * Ratio > iCT)
	{
		iCT++; iT--;
		ForcePlayerSuicide(Maniac[iT]);
		CS_SwitchTeam(Maniac[iT], 3);
		FormatManiacString(szBuffer, 256, iTemp, Maniac[iT]);
	}
	
	if(iTemp > 0)
	{
		PrintHintTextToAll("%t\n%t", "Tag 2", iTemp == 1 ? "Player was moved from maniacs":"Players was moved from maniacs", szBuffer);
	}
	
	if(!AutoBalance || iCT == 0)
	{
		return Plugin_Stop;
	}
	
	int iNeed;
	
	while((iT == 0 && iCT > 1) || (iT + 1) * Ratio <= iCT - 1)
	{
		iNeed++; iT++; iCT--;
	}
		
	
	if(iNeed == 0)
	{
		return Plugin_Stop;
	}
	
	iTemp = 0;
	
	while(iNeed && Forces)
	{
		iNeed--;
		FormatManiacString(szBuffer, 256, iTemp, Force[0]);
		CS_SwitchTeam(Force[0], 2);
	}
	
	if(iNeed == 0)
	{
		if(iTemp > 0)
		{
			PrintToChatAll2(_, "%t%t", "Tag", iTemp == 1 ? "Player was moved to maniacs":"Players was moved to maniacs", szBuffer);
		}
		return Plugin_Stop;
	}

	
	int[] Clients = new int[MaxClients + 1];
	int CorrectClients = GetCorrectClients(Clients);

	if(iNeed > CorrectClients)
	{
		int iNeedClean = iNeed - CorrectClients;
		for(int i; i < iNeedClean; i++)
			Round[Queue[i]] = 0;
	
		ShiftArray(Queue, (Queues -= iNeedClean), 0, iNeedClean);
		CorrectClients = GetCorrectClients(Clients);
	}
	
	int iIndex;
	while(iNeed)
	{
		iIndex = GetRandomInt(0, --CorrectClients);
		
		CS_SwitchTeam(Clients[iIndex], 2);
		
		FormatManiacString(szBuffer, 256, iTemp, Clients[iIndex]);
		
		ShiftArray(Clients, CorrectClients, iIndex);
		
		iNeed--;
	}

	
	if(iTemp > 0)
	{
		PrintToChatAll2(_, "%t%t", "Tag", iTemp == 1 ? "Player was moved to maniacs":"Players was moved to maniacs", szBuffer);
	}
	
	return Plugin_Stop;
}

int GetCorrectClients(int[] Clients)
{
	int CorrectClients;
		
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i) && Team[i] == 3 && Round[i] < maxRounds)
		{
			Clients[CorrectClients++] = i;
		}
		
	}
	
	return CorrectClients;
}

public void OnPlayerSpawn(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(!Collision)
		SetEntData(iClient, g_iCollision, 2, 4, true);
	
	Time[iClient] = Team[iClient] == 2 ? (GetTime2() + minRoundTime):0;
}

public void OnPlayerDisconnect(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	
	if(BanTimeForDisconnect > 0 && Team[iClient] == 2 && GetClientsCount(3) > 0)
	{
		char szBuffer[32];
		hEvent.GetString("reason", szBuffer, 32);
		
		if(strcmp(szBuffer, "Disconnect by user.", false) == 0)
			BanClient(iClient, BanTimeForDisconnect, BANFLAG_AUTHID, "Leave T Command");
	}
}

public Action OnPlayerTeam_Pre(Event hEvent, const char[] event, bool bDontBroadcast)
{
	return Plugin_Handled;
}

public void OnPlayerTeam(Event hEvent, const char[] event, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"))/*, iOldTeam = hEvent.GetInt("oldteam")*/;
	
	Team[iClient] = hEvent.GetInt("team");
	
	ManageTeam(iClient);
}

void ManageTeam(int iClient)
{
	int iIndex;
	
	if(Team[iClient] != 2 && (iIndex = FindValue(Maniac, Maniacs, iClient)) != -1)
		ShiftArray(Maniac, --Maniacs, iIndex);
	
	if(Team[iClient] != 3)
	{
		if((iIndex = FindValue(Queue, Queues, iClient)) != -1)
		{
			QueueSave[iClient] = iIndex;
			
			ShiftArray(Queue, --Queues, iIndex);
		}
		if((iIndex = FindValue(Force, Forces, iClient)) != -1)
			ShiftArray(Force, --Forces, iIndex);
	}
	
	switch(Team[iClient])
	{
		case 3:
		{
			ManageCTTeam(iClient);
		}
		case 2:
		{
			if(FindValue(Maniac, Maniacs, iClient) == -1)
				PushValue(Maniac, Maniacs, iClient);
		}
	}
}


void ManageCTTeam(int iClient)
{
	if(Round[iClient] >= maxRounds && FindValue(Queue, Queues, iClient) == -1)
	{
		int iPosition;
		if(QueueSave[iClient] != -1 && QueueSave[iClient] < Queues)
		{
			for(int i = Queues;i > QueueSave[iClient]; i--)
			{
				Queue[i] = Queue[i - 1];
			}
			Queues++;
			iPosition = QueueSave[iClient];
			Queue[QueueSave[iClient]] = iClient;
			QueueSave[iClient] = -1;
		}
		else
			iPosition = PushValue(Queue, Queues, iClient);
		
		if(!IsFakeClient(iClient) && IsNotSpam(iClient, 4))
			PrintToChat2(iClient, "%t%t", "Tag", "Show client position in queue list", iPosition + 1, Queues);
		
		
	}
}

int GetClientsCount(int iTeam = -1)
{
	int iCount;
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (iTeam == -1 || Team[i] == iTeam))
			iCount++;
	}
	
	return iCount;
}

bool CanGoForManiac(int iClient)
{
	int iT = GetClientsCount(2);
	
	if(iT == 0)
		return true;
	
	iT++;
	
	int iCT = GetClientsCount(3);
	
	if(Team[iClient] > 2)
	{
		iCT--;
	}
	
	return (maxRounds > Round[iClient] && iT * Ratio <= iCT);
}

public void OnClientPostAdminCheck(int iClient)
{
	Team[iClient] = GetClientTeam(iClient);
	
	if(!IsFakeClient(iClient))
	{
		char szAuth[40];
		GetClientAuthId(iClient, AuthId_Engine, szAuth, 40, true);
		int iIndex = FindInTokenList(szAuth);
		
		if(iIndex != -1)
		{
			QueueSave[iClient] = QueueSaves[iIndex];
			Round[iClient] = Rounds[iIndex];
			
			if(Team[iClient] == 3)
			{
				ManageCTTeam(iClient);
			}
			
			DeleteFromTokenList(iIndex);
		}
	}
}

public void OnClientDisconnect(int iClient)
{
	Set[iClient] = -1;
	if(!IsFakeClient(iClient))
	{
		if(Team[iClient] == 2)
			CheckManiacRound(iClient);
		
		if(Round[iClient] > 0 || QueueSave[iClient] != -1 || (QueueSave[iClient] = FindValue(Queue, Queues, iClient)) != -1)
		{
			PushClientInTokenList(iClient);
			QueueSave[iClient] = -1;
			Round[iClient] = 0;
		}
	}
	
	Time[iClient] = 0;
}

int GetTime2()
{
	static int iTime;
	if(!g_bDelayTimer)
	{
		g_bDelayTimer = view_as<bool>(CreateTimer(1.0, Timer_Delay));
		iTime = GetTime();
	}
	
	return iTime;
}

public Action Timer_Delay(Handle hTimer)
{
	g_bDelayTimer = false;
}

bool CheckManiacRound(int iClient)
{
	int iTime = GetTime2();
	if(iTime > Time[iClient] && Time[iClient] > 0)
	{
		if(++Round[iClient] >= maxRounds && FindValue(Queue, Queues, iClient) == -1)
		{
			PushValue(Queue, Queues, iClient);
		}
		
		Time[iClient] = 0;
	}
	
	return (AutoBalance && Round[iClient] >= maxRounds);
}


int PushClientInTokenList(int iClient)
{
	if(Tokens == MEMORY)
		DeleteFromTokenList(0);
	
	QueueSaves[Tokens] = QueueSave[iClient];
	Rounds[Tokens] = Round[iClient];
	GetClientAuthId(iClient, AuthId_Engine, Token[Tokens], 40, true);
	return Tokens++;
}

int FindInTokenList(const char[] auth)
{
	for(int i; i < Tokens; i++)
	{
		if(strcmp(Token[i], auth, false) == 0)
			return i;
	}
	
	return -1;
}

void DeleteFromTokenList(int iIndex)
{
	Tokens--;
	for(int i = iIndex; i < Tokens; i++)
	{
		Token[i] = Token[i + 1];
		Rounds[i] = Rounds[i + 1];
		QueueSaves[i] = QueueSaves[i + 1];
	}
}

int PushValue(int[] iArray, int& iSize, int iValue)
{
	iArray[iSize] = iValue;
	return iSize++;
}

int FindValue(int[] iArray, int iSize, int iValue)
{
	for(int i;i < iSize; i++)
		if(iArray[i] == iValue)
			return i;
		
	return -1;
}

void ShiftArray(int[] iArray, int iSize, int iIndex = 0, int iNumber = 1)
{
	for(int i = iIndex; i < iSize; i++)
		iArray[i] = iArray[i + iNumber];
}


stock void FormatManiacString(char[] szBuffer, int iSize, int& iManiacs, int iNick)
{
	if(iManiacs == 0)
	{
		FormatEx(szBuffer, iSize, "%N", iNick);
	}
	else
	{
		Format(szBuffer, iSize, "%s, %N", szBuffer, iNick);
	}
	iManiacs++;
}

void AddHostageZone()
{
	char sName[64];
	int iMax = GetMaxEntities();
	
	for (int i = MaxClients;i <= iMax; i++)	if(IsValidEntity(i) && GetEdictClassname(i, sName, 64) && strcmp(sName, "func_hostage_rescue", false) == 0)
		return;

	int iEnt = CreateEntityByName("func_hostage_rescue");
	if (iEnt > 0)
	{
		DispatchKeyValue(iEnt, "targetname", "maniac_roundend");
		DispatchKeyValueVector(iEnt, "orign", view_as<float>({-1000.0, -1000.0, -1000.0}));
		DispatchSpawn(iEnt);
	}
}


public int Native_Maniac_PrintToChat(Handle hPlugin,	int numParams)
{
	char szBuffer[256];
	int iClient = GetNativeCell(1);
	SetGlobalTransTarget(iClient);
	FormatNativeString(0, 2, 3, 256, _, szBuffer);
	PrintToChat2(iClient, "%t%s", "Tag", szBuffer);
}

public int Native_Maniac_PrintToChatAll(Handle hPlugin,	int numParams)
{
	char szBuffer[256];
	int iSkip = GetNativeCell(1);
	for(int i = 1;i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i) || iSkip == i)
			continue;
		
		SetGlobalTransTarget(i);
		FormatNativeString(0, 2, 3, 256, _, szBuffer);
		PrintToChat2(i, "%t%s", "Tag", szBuffer);
	}
}

public int Native_Maniac_OpenAdminMenu(Handle hPlugin,	int numParams)
{
	MAdmin(GetNativeCell(1));
}

Handle CreateMenu2(MenuHandler handler, bool bExitBackButton = true, const char[] format, any... ...)
{
	char szBuffer[256];
	Menu hMenu = new Menu(handler);
	VFormat(szBuffer, 256, format, 4);
	hMenu.SetTitle(szBuffer);
	hMenu.ExitBackButton = bExitBackButton;
	return hMenu;
	
}