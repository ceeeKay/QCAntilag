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



inside FireBullets:

// add this
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

// and this
	// Put all the player entities back to their actual (server) positions
	antilag_restore_players();



inside W_FireLightning:

// add this
	// Use the client's response time to temporarily move all other player entities back in time
	antilag_rewind_players(self.responsetime, self);

	org = self.origin + '0 0 16';

	traceline (org, org + v_forward*600, TRUE, self);

	WriteByte (MSG_BROADCAST, SVC_TEMPENTITY);
	WriteByte (MSG_BROADCAST, TE_LIGHTNING2);
	WriteEntity (MSG_BROADCAST, self);
	WriteCoord (MSG_BROADCAST, org_x);
	WriteCoord (MSG_BROADCAST, org_y);
	WriteCoord (MSG_BROADCAST, org_z);
	WriteCoord (MSG_BROADCAST, trace_endpos_x);
	WriteCoord (MSG_BROADCAST, trace_endpos_y);
	WriteCoord (MSG_BROADCAST, trace_endpos_z);

	LightningDamage (self.origin, trace_endpos + v_forward*4, self, 30);

// and this
	// Put all the player entities back to their actual (server) positions
	antilag_restore_players();



before W_FireRocket:

void ThinkMovetype_AntilagProjectile()
{
	self.think = ThinkMovetype_AntilagProjectile;
	self.nextthink = time + 0.01;

	// Use the client's response time to temporarily move all other player entities back in time
	antilag_rewind_players(self.responsetime, self.owner);

	// Trace a line from current position to the place where we'll be after the next frame
	traceline(self.origin, self.origin + (self.velocity * frametime), FALSE, self);

	// Actually move the missile
	setorigin(self, trace_endpos);

	// If we run into something
	if (trace_fraction < 1)
	{
		// Call T_MissileTouch()
		if (self.touch)
		{
			other = trace_ent;
			self.touch();
		}

		// Call the other entity's .touch function (if it has one)
		if (trace_ent && trace_ent.touch)
		{
			entity oself = self;
			other = self;
			self = trace_ent;
			self.touch();
			self = oself;
		}
	}

	// Put all the player entities back to their actual (server) positions
	antilag_restore_players();

	// Extrapolate the visual antilagged position to send to clients;
	// our physics position will be stored in hold_origin.
	local float extrapolation_time;
	// Start with where the game physics think we should be
	self.hold_origin = self.origin;
	// Cap extrapolation at our max rewind time
	extrapolation_time = self.responsetime > ANTILAG_MAX_RESPONSETIME ? ANTILAG_MAX_RESPONSETIME : self.responsetime;
	// Make sure to multiply by 0.001 to convert into seconds for desired velocity
	traceline(self.origin, self.origin + (self.velocity * extrapolation_time * 0.001), FALSE, self);
	// Move to the extrapolated position for good visuals
	setorigin(self, trace_endpos);
}



at the end of W_FireRocket:

// antilag

	// use custom a movement .think
	missile.movetype = MOVETYPE_NONE;
	missile.think = ThinkMovetype_AntilagProjectile;
	missile.nextthink = time + 0.01;

	// set .responsetime to owner's so position can be compensated for antilag
	missile.responsetime = self.responsetime;

	// store the physics version of the missile's location
	missile.hold_origin = missile.origin;



at the end of launch_spike:

// antilag

if (self.classname == "player") {
	// use custom a movement .think
	newmis.movetype = MOVETYPE_NONE;
	newmis.think = ThinkMovetype_AntilagProjectile;
	newmis.nextthink = time + 0.01;

	// set .responsetime to owner's so position can be compensated for antilag
	newmis.responsetime = self.responsetime;

	// store the physics versino of the missile's location
	newmis.hold_origin = newmis.origin;

	// Run ThinkMovetype_AntilagProjectile once manually for high ping players
	entity tmp = self;
	self = newmis;
	ThinkMovetype_AntilagProjectile();
	self = tmp;
}
