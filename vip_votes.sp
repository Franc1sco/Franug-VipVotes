#include <sourcemod>
#include <sdktools>
#include <basecomm>

/*  SM Franug Vip Votes
 *
 *  Copyright (C) 2020 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

public Plugin myinfo = 
{
	name = "SM Franug Vip Votes",
	author = "Franc1sco franug",
	description = "",
	version = "0.2",
	url = "http://steamcommunity.com/id/franug"
};

int _admin, _target;

const int nothing = 0;
const int gag = 1;
const int mute = 2;
const int ban = 3;

int _type = nothing;

public void OnPluginStart()
{
	RegAdminCmd("sm_votegag", Command_VoteGag, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_votemute", Command_VoteMute, ADMFLAG_RESERVATION);
	RegAdminCmd("sm_voteban", Command_VoteBan, ADMFLAG_RESERVATION);
}

public void OnClientDisconnect(int client)
{
	if (client < 1)return;
	
	if(client == _admin)
	{
		ServerCommand("sm_cancelvote");
		PrintToChatAll("Vote cancelled because the admin disconnected");
		
		_target = 0;
		_admin = 0;
		_type = nothing;
	}
	else if(client == _target)
	{
		ServerCommand("sm_cancelvote");
		PrintToChatAll("Player voted disconnected so he will be punished");
		
		if(_type == gag)
			ServerCommand("sm_gag %i 30 Vote gag by %N", GetClientUserId(client), _admin);
		else if(_type == mute)
			ServerCommand("sm_mute %i 30 Vote mute by %N", GetClientUserId(client), _admin);
		else if(_type == ban)
			ServerCommand("sm_ban %i 30 Vote ban by %N", GetClientUserId(client), _admin);
			
			
		_target = 0;
		_admin = 0;
		_type = nothing;
	}
}

public Action:Command_VoteGag(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] usa: sm_votegag <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		ReplyToCommand(client, "Target not found");
		return Plugin_Handled; // Target not found...
	}
	if(BaseComm_IsClientGagged(client))
	{
		ReplyToCommand(client, "%N already have a gag", target);
		return Plugin_Handled;
	}
	ShowActivity2(client, "[VipVotes]", "Started a gag vote against %N", target);
	DoVoteMenuGag(target, client);
	
	return Plugin_Handled;
}

public Action:Command_VoteMute(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] usa: sm_votemute <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		ReplyToCommand(client, "Target not found");
		return Plugin_Handled; // Target not found...
	}
	if(BaseComm_IsClientMuted(client))
	{
		ReplyToCommand(client, "%N already have a mute", target);
		return Plugin_Handled;
	}
	ShowActivity2(client, "[VipVotes]", "Started a mute vote against %N", target);
	DoVoteMenuMute(target, client);
	
	return Plugin_Handled;
}

public Action:Command_VoteBan(client, args)
{
	if(args < 1) // Not enough parameters
	{
		ReplyToCommand(client, "[SM] usa: sm_voteban <#userid|name>");
		return Plugin_Handled;
	}
	decl String:arg[30];
	GetCmdArg(1, arg, sizeof(arg));
	
	new target;
	if((target = FindTarget(client, arg, true, true)) == -1)
	{
		ReplyToCommand(client, "Target not found");
		return Plugin_Handled; // Target not found...
	}
	ShowActivity2(client, "[VipVotes]", "Started a ban vote against %N", target);
	DoVoteMenuBan(target, client);
	
	return Plugin_Handled;
}


public int Handle_VoteMenuGag(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        /* This is called after VoteEnd */
        delete menu;
    }
    else if (action == MenuAction_VoteEnd)
    {
    	if (_target == 0 || _admin == 0)return;
    	
        /* 0=yes, 1=no */
        if (param1 == 0)
        {
            char steam[64];
            menu.GetItem(param1, steam, sizeof(steam));
            
            int isteam = StringToInt(steam);
            int client = GetClientOfUserId(isteam);
            
            if (!client || !IsClientInGame(client))return;
            
            ServerCommand("sm_gag #%s 30 Vote gag by %N", steam, _admin);
            
        }
        
        
        _target = 0;
        _admin = 0;
        _type = nothing;
    }
}
 
void DoVoteMenuGag(int client, int admin)
{
    if (IsVoteInProgress())
    {
    	ReplyToCommand(admin, "A vote already in process, try more later");
        return;
    }
    
    _target = client;
    _admin = admin;
    _type = gag;
 
    Menu menu = new Menu(Handle_VoteMenuGag);
    menu.SetTitle("Gag to %N?", client);
    char steam[64];
    
    Format(steam, 64, "%i", GetClientUserId(client));
    
    menu.AddItem(steam, "Yes");
    menu.AddItem("no", "No");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);
}


public int Handle_VoteMenuBan(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        /* This is called after VoteEnd */
        delete menu;
    }
    else if (action == MenuAction_VoteEnd)
    {
    	if (_target == 0 || _admin == 0)return;
    	
        /* 0=yes, 1=no */
        if (param1 == 0)
        {
            char steam[64];
            menu.GetItem(param1, steam, sizeof(steam));
            
            int isteam = StringToInt(steam);
            int client = GetClientOfUserId(isteam);
            
            if (!client || !IsClientInGame(client))return;
            
            ServerCommand("sm_ban #%s 30 Vote ban by %N", steam, _admin);
            
        }
        
        
        _target = 0;
        _admin = 0;
        _type = nothing;
    }
}
 
void DoVoteMenuBan(int client, int admin)
{
    if (IsVoteInProgress())
    {
    	ReplyToCommand(admin, "A vote already in process, try more later");
        return;
    }
    
    _target = client;
    _admin = admin;
    _type = ban;
 
    Menu menu = new Menu(Handle_VoteMenuBan);
    menu.SetTitle("Ban to %N?", client);
    char steam[64];
    
    Format(steam, 64, "%i", GetClientUserId(client));
    
    menu.AddItem(steam, "Yes");
    menu.AddItem("no", "No");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);
}

public int Handle_VoteMenuMute(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_End)
    {
        /* This is called after VoteEnd */
        delete menu;
    }
    else if (action == MenuAction_VoteEnd)
    {
    	if (_target == 0 || _admin == 0)return;
    	
        /* 0=yes, 1=no */
        if (param1 == 0)
        {
            char steam[64];
            menu.GetItem(param1, steam, sizeof(steam));
            
            int isteam = StringToInt(steam);
            int client = GetClientOfUserId(isteam);
            
            if (!client || !IsClientInGame(client))return;
            
            ServerCommand("sm_mute #%s 30 Vote mute by %N", steam, _admin);
            
        }
        
        
        _target = 0;
        _admin = 0;
        _type = nothing;
    }
}
 
void DoVoteMenuMute(int client, int admin)
{
    if (IsVoteInProgress())
    {
    	ReplyToCommand(admin, "A vote already in process, try more later");
        return;
    }
    
    _target = client;
    _admin = admin;
    _type = mute;
 
    Menu menu = new Menu(Handle_VoteMenuMute);
    menu.SetTitle("Mute to %N?", client);
    char steam[64];
    
    Format(steam, 64, "%i", GetClientUserId(client));
    
    menu.AddItem(steam, "Yes");
    menu.AddItem("no", "No");
    menu.ExitButton = false;
    menu.DisplayVoteToAll(20);
}