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

void (float pingtime, entity ignore) antilag_rewind_players =
{
	local entity player;

	float timestamp_we_want = ((time * 1000) - pingtime);
  
	player = find(world, classname, "player");

	while (player)
	{
		if ((player.deadflag == DEAD_NO) && (player.style & ELOHIM_CONNECTED) && !(player.style & ELOHIM_OBSERVER))
		{
			// Store the player's .origin off to a temporary .hold_origin
			// Should this be inside the player != ignore check?
			player.hold_origin = player.origin;
			// Don't rewind self
			if (player != ignore)
			{
				// Rewind the player entity back to timestamp_we_want
				antilag_rewind(player, timestamp_we_want);
			}
		}
		player = find(player, classname, "player");
	}
}

void () antilag_restore_players =
{
	local entity player;
  
	player = find(world, classname, "player");

	while (player)
	{
		if ((player.deadflag == DEAD_NO) && (player.style & ELOHIM_CONNECTED) && !(player.style & ELOHIM_OBSERVER))
		{
			// Put everybody back where the server thinks they belong
			setorigin(player, player.hold_origin);
		}
		player = find(player, classname, "player");
	}
}




inside FireBullets and W_FireLightning:

//add this
	// Use the client's response time to temporarily move all other player entities back in time
	antilag_rewind_players(self.responsetime, self);

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
	// Put all the player entities back to their actual (server) positions
	antilag_restore_players();
