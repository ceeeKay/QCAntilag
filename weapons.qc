void (entity e, float rewindtime) antilag_rewind =
{
	vector rewindorigin;

	if (e.lastorigintime1 < rewindtime)
		rewindorigin = e.lastorigin1;
	else if (e.lastorigintime2 < rewindtime)
		rewindorigin = e.lastorigin2;
	else if (e.lastorigintime3 < rewindtime)
		rewindorigin = e.lastorigin3;
	else if (e.lastorigintime4 < rewindtime)
		rewindorigin = e.lastorigin4;
	else if (e.lastorigintime5 < rewindtime)
		rewindorigin = e.lastorigin5;
	else if (e.lastorigintime6 < rewindtime)
		rewindorigin = e.lastorigin6;
	else if (e.lastorigintime7 < rewindtime)
		rewindorigin = e.lastorigin7;
	else if (e.lastorigintime8 < rewindtime)
		rewindorigin = e.lastorigin8;
	else
		rewindorigin = e.lastorigin9;

  	setorigin(e, rewindorigin);
}

void (float pingtime, entity ignore) antilag_rewind_all =
{
	local entity player;

	float timestamp_we_want = (time - pingtime);
  
	player = find(world, classname, "player");

	while (player)
	{
		if ((player.deadflag == DEAD_NO) && (player.style & ELOHIM_CONNECTED) && !(player.style & ELOHIM_OBSERVER))
		{
			player.hold_origin = player.origin;
			if (player != ignore)
			{
				antilag_rewind(player, timestamp_we_want);
			}
		}
		player = find(player, classname, "player");
	}
}

void () antilag_restore_all =
{
	local entity player;
  
	player = find(world, classname, "player");

	while (player)
	{
		if ((player.deadflag == DEAD_NO) && (player.style & ELOHIM_CONNECTED) && !(player.style & ELOHIM_OBSERVER))
		{
			setorigin(player, player.hold_origin);
		}
		player = find(player, classname, "player");
	}
}




inside FireBullets:

//add this
	antilag_rewind_all(self.responsetime, self);

	ClearMultiDamage ();
	while (shotcount > 0)
	{
		direction = dir + crandom()*spread_x*v_right + crandom()*spread_y*v_up;

		traceline (src, src + direction*2048, FALSE, self);
		if (trace_fraction != 1.0)
			TraceAttack (4, direction);

		shotcount = shotcount - 1;
	}
	ApplyMultiDamage ();

//and this
	antilag_restore_all();
