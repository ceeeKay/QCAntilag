





float(string cmdstr) CSQC_ConsoleCommand
{
	if (cmdstr == "+showscores")
		show_score = TRUE;
	else if (cmdstr == "-showscores")
		show_score = FALSE;
	
}

void(float apilevel, string enginename, float engineversion) CSQC_Init =
{
	V_ViewmodelCreate();
}

void(float vwidth, float vheight, float notmenu) CSQC_UpdateView
{
	if (cltime >= net_pingquery)
	{
		// fix QSS shite
		csqc_flags = getstatf(STAT_CSQCFLAGS);
		//
		
		net_ping = (net_ping + getstatf(STAT_PING)) / 2;
		net_pingquery = cltime + 0.25;
	}
	
	shealth = getstatf(STAT_HEALTH);
	
	score_display = FALSE;
	if (shealth <= 0 || show_score)
		score_display = TRUE;
	
	clearscene();
	addentities(((intermission || shealth <= 0)?0:MASK_CUSTOMVIEWMODEL)|MASK_ENGINE);
	setviewprop(VF_SIZE_X, vwidth);
	setviewprop(VF_SIZE_Y, vheight);
	setviewprop(VF_DRAWCROSSHAIR, 1);
	setviewprop(VF_DRAWENGINESBAR, 1);
	renderscene();
}







