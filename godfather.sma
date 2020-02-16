/**

**/

#define THE_GODFATHER	g_iLeader[TEAM_TERRORIST - 1]
#define GODFATHER_TEXT	g_rgszRoleNames[Role_Godfather]
#define GODFATHER_TASK	3654861	// just some random number.

#define GODFATHER_GRAND_SFX		"leadermode/sfx_event_sainthood_01.wav"
#define GODFATHER_REVOKE_SFX	"leadermode/sfx_bloodline_add_bloodline_01.wav"

new g_iGodchildrenCount = 0, g_rgiGodchildren[33];
new Float:g_flGodfatherSavedHP = 1000.0, Float:g_rgflGodchildrenSavedHP[33];
new cvar_godfatherRadius, cvar_godfatherDuration;

public Godfather_Initialize()
{
	cvar_godfatherRadius	= register_cvar("lm_godfather_radius",		"250.0");
	cvar_godfatherDuration	= register_cvar("lm_godfather_duration",	"20.0");
}

public Godfather_TerminateSkill()
{
	g_iGodchildrenCount = 0;
	remove_task(GODFATHER_TASK);
}

public Godfather_ExecuteSkill(pPlayer)
{
	// UNDONE: check skill usage status.
	
	g_iGodchildrenCount = 0;
	
	new iGodchild = -1, Float:vecOrigin[3];
	pev(pPlayer, pev_origin, vecOrigin);
	
	client_cmd(pPlayer, "spk %s", GODFATHER_GRAND_SFX);
	
	while ((iGodchild = engfunc(EngFunc_FindEntityInSphere, iGodchild, vecOrigin, get_pcvar_float(cvar_godfatherRadius))) > 0)
	{
		if (!is_user_connected(iGodchild))
			continue;
		
		if (get_pdata_int(iGodchild, m_iTeam) != TEAM_TERRORIST)	// UNDONE: godfather in CT...?
			continue;
		
		if (iGodchild == pPlayer)
			continue;
		
		g_iGodchildrenCount++;	// thus, the indexes are started from 1 and end with its exact number.
		g_rgiGodchildren[g_iGodchildrenCount] = iGodchild;
		
		client_cmd(iGodchild, "spk %s", GODFATHER_GRAND_SFX);
	}
	
	new Float:flGodfatherHealth, Float:flDividedHealth;
	pev(pPlayer, pev_health, flGodfatherHealth);
	
	flDividedHealth = flGodfatherHealth / (g_iGodchildrenCount + 1);	// the godfather should be included when partitioning occurs.
	
	g_flGodfatherSavedHP = flGodfatherHealth;
	set_pev(pPlayer, pev_health, flDividedHealth);
	
	new Float:flGodchildHealth;
	for (new i = 1; i <= g_iGodchildrenCount; i++)
	{
		pev(g_rgiGodchildren[i], pev_health, flGodchildHealth);
		g_rgflGodchildrenSavedHP[g_rgiGodchildren[i]] = flGodchildHealth;
		set_pev(g_rgiGodchildren[i], pev_health, flGodchildHealth + flDividedHealth);
	}
	
	set_task(get_pcvar_float(cvar_godfatherDuration), "Godfather_RevokeSkill", GODFATHER_TASK);
}

public Godfather_RevokeSkill(iTaskId)
{
	// the death of godchildren will NOT stop the HP payback. this is the rule. intended.
	for (new i = 1; i <= g_iGodchildrenCount; i++)
	{
		if (is_user_alive(g_rgiGodchildren[i]))
		{
			set_pev(g_rgiGodchildren[i], pev_health, g_rgflGodchildrenSavedHP[g_rgiGodchildren[i]]);
			client_cmd(g_rgiGodchildren[i], "spk %s", GODFATHER_REVOKE_SFX);
		}
	}
	
	// the only way to stop it is the death of the Godfather
	if (is_user_alive(THE_GODFATHER))
	{
		set_pev(THE_GODFATHER, pev_health, g_flGodfatherSavedHP);
		client_cmd(THE_GODFATHER, "spk %s", GODFATHER_REVOKE_SFX);
	}
	
	// g_iGodchildrenCount == 0 could be an indicator of the skill usage status ???
	// what if skill was fail due to nobody near Godfather?
	g_iGodchildrenCount = 0;
}