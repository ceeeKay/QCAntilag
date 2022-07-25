// QCAntilag: global defines/constants
#define ANTILAG_STATES				0x10
#define ANTILAG_MASK				0x0F
#define	ANTILAG_MAX_RESPONSETIME	150
#define ANTILAG_FL_SPAWNTEST		0x01

// QCAntilag: entity properties
.float 	antilag_flags;
.vector	lastorigin[ANTILAG_STATES];
.float 	lastorigintime[ANTILAG_STATES];
.float 	antilag_updatetime;
.vector hold_origin;
.vector	spawn_angles;
.float 	spawn_time;
.float 	responsetime;
.float 	responsetime1;
.float 	responsetime2;
.float 	responsetime3;
.float 	spamtime;

// QCAntilag: this stuff is only valid in FTE or another QW compatible engine
.void() customphysics;
string(entity e, string key) infokey = #0:infokey;
float(entity e, string key) infokeyf = #0:infokeyf;

const float MSG_MULTICAST = 4;	/* The byte(s) will be written into the multicast buffer for more selective sending. Messages sent this way will never be split across packets, and using this for csqc-only messages will not break protocol translation. */
const float MULTICAST_ALL = 0;	/* The multicast message is unreliably sent to all players. MULTICAST_ constants are valid arguments for the multicast builtin, which ignores the specified origin when given this constant. */
const float MULTICAST_PHS = 1;	/* The multicast message is unreliably sent to only players that can potentially hear the specified origin. Its quite loose. */
const float MULTICAST_PVS = 2;	/* The multicast message is unreliably sent to only players that can potentially see the specified origin. */
const float MULTICAST_ONE = 6;	/* The multicast message is unreliably sent to the player (AND ALL TRACKING SPECTATORS) specified in the msg_entity global. The specified origin is ignored. */
const float MULTICAST_ONE_NOSPECS = 9;	/* The multicast message is unreliably sent to the player specified in the msg_entity global. The specified origin is ignored. */
const float MULTICAST_ALL_R = 3;	/* The multicast message is reliably sent to all players. The specified origin is ignored. */
const float MULTICAST_PHS_R = 4;	/* The multicast message is reliably sent to only players that can potentially hear the specified origin. Players might still not receive it if they are out of range. */
const float MULTICAST_PVS_R = 5;	/* The multicast message is reliably sent to only players that can potentially see the specified origin. Players might still not receive it if they cannot see the event. */
const float MULTICAST_ONE_R = 7;	/* The multicast message is reliably sent to the player (AND ALL TRACKING SPECTATORS) specified in the msg_entity global. The specified origin is ignored */
const float MULTICAST_ONE_R_NOSPECS = 10;	/* The multicast message is reliably sent to the player specified in the msg_entity global. The specified origin is ignored */
float(vector where, float set) multicast = #0:multicast;
//

// QCAntilag: globals
float is_running_fte;
float responsetimecheck;

// QCAntilag: clear player positions
void () ClearLastOrigin =
{
	float i;
	for(i = 0; i < ANTILAG_STATES; i++)
	{
		self.lastorigin[i] = 0;
		self.lastorigintime[i] = 0;
	}
};

// QCAntilag: compare angles to see if they're within margin of error
float(vector ang1, vector ang2) CompareNetAngles =
{
	// putting this in a loop inexplicably causes a crash... no idea
	// the math here is just replicating WriteAngle behavior
	ang1[0] = floor(ang1[0]*(256/360) - 0.5) & 255;
	ang2[0] = floor(ang2[0]*(256/360) - 0.5) & 255;
	ang1[1] = floor(ang1[1]*(256/360) - 0.5) & 255;
	ang2[1] = floor(ang2[1]*(256/360) - 0.5) & 255;
	ang1[2] = floor(ang1[2]*(256/360) - 0.5) & 255;
	ang2[2] = floor(ang2[2]*(256/360) - 0.5) & 255;
	
	return (ang1 == ang2);
};

// QCAntilag: check angles for spawn
void() CheckSpawnTest =
{
	if (self.antilag_flags & ANTILAG_FL_SPAWNTEST && self.spawn_time)
	{
		if (CompareNetAngles(self.v_angle, self.spawn_angles))
		{
			self.responsetime1 = (time - self.spawn_time) * 1000;
			self.spawn_time = 0;
		}
		else if (time - self.spawn_time > 0.5) // timeout, something went wrong. not exactly unexpected with this hack
		{
			self.spawn_time = 0;
		}
	}
}

// QCAntilag: Think function for client ping impulse
void () client_ping_think =
{
	local entity client;

	client = find(world, classname, "player");
	while (client)
	{
		client.responsetime3 = client.responsetime2;
		client.responsetime2 = client.responsetime1;

		if (client.finaldest_y > self.finaldest_x) // if we got a packet back
		{
			self.antilag_flags &= ~ANTILAG_FL_SPAWNTEST;
			client.responsetime1 = (floor(client.finaldest_y - self.finaldest_x) - 16);
			
			// cap to acceptable values
			client.responsetime1 = client.responsetime1 < 0 ? 0 : client.responsetime1;
			client.responsetime1 = client.responsetime1 > ANTILAG_MAX_RESPONSETIME ? ANTILAG_MAX_RESPONSETIME : client.responsetime1;
		}
		else // packet dropped, lets make something up
		{
			if (self.finaldest_z > client.finaldest_y) // client hasn't responded in a long time, probably cl_filterstuffcmd 1
			{
				client.antilag_flags |= ANTILAG_FL_SPAWNTEST;
				client.responsetime1 = client.responsetime;
			}
			else
				client.responsetime1 = client.responsetime;
		}

		if (client.responsetime2 > 0)
		{
			if (client.responsetime3 > 0)
			{
				client.responsetime = ((client.responsetime1 + client.responsetime2 + client.responsetime3) / 3);
			}
			else
			{
				client.responsetime = ((client.responsetime1 + client.responsetime2) / 2);
			}
		}
		else
		{
			client.responsetime = client.responsetime1;
		}
        client = find(client, classname, "player");
    }

    remove(self);
};

// QCAntilag: Request ping (response) time for all clients
void () client_responsetime_get_all =
{
	if (is_running_fte) // if we're on FTE, we can use the QW way
	{
		for(entity pl = find(world, classname, "player"); pl; pl = find(pl, classname, "player"))
		{
			pl.responsetime = infokeyf(pl, "ping") - 8; // account for QW input frame timey-ness
			
			// cap to acceptable values
			pl.responsetime = pl.responsetime < 0 ? 0 : pl.responsetime;
			pl.responsetime = pl.responsetime > ANTILAG_MAX_RESPONSETIME ? ANTILAG_MAX_RESPONSETIME : pl.responsetime;
		}
		
		responsetimecheck = (time + 3); // we're using engine stuff, so we can speed this polling up a bit
		return;
	}

	local entity ping;

	WriteByte(MSG_BROADCAST, SVC_STUFFTEXT);
	WriteString(MSG_BROADCAST, "impulse 38\n");

	ping = spawn();
	ping.classname = "client_ping";
	ping.owner = world;
	ping.nextthink = time + 2;
	ping.think = client_ping_think;
	ping.finaldest_x = (time * 1000);
	ping.finaldest_z = ((time - 20) * 1000);

	responsetimecheck = (time + 10);
};

// QCAntilag: Store the ping (response) time for a ping entity
void () client_responsetime_set =
{
	self.finaldest_y = (time * 1000);
};

// QCAntilag: Debug function to see response times and frames
void () client_responsetime_show =
{
	//don't let players spam this
	if (time < self.spamtime)
		return;

	self.spamtime = (time + 5);

	sprint(self, "response time3: ");
	sprint(self, ftos(self.responsetime3));
	sprint(self, "\n");
	sprint(self, "response time2: ");
	sprint(self, ftos(self.responsetime2));
	sprint(self, "\n");
	sprint(self, "response time1: ");
	sprint(self, ftos(self.responsetime1));
	sprint(self, "\n");
	sprint(self, "response time:  ");
	sprint(self, ftos(self.responsetime));
	sprint(self, "\n");
	sprint(self, "current origin: ");
	sprint(self, vtos(self.origin));
	sprint(self, "\n");

	float i;
	for(i = 0; i < ANTILAG_STATES; i++)
	{
		sprint(self, "last frame");
		sprint(self, ftos(i));
		sprint(self, ": ");
		sprint(self, vtos(self.lastorigin[i]));
		sprint(self, " ");
		sprint(self, ftos(self.lastorigintime[i]));
		sprint(self, "\n");
	}
};

// QCAntilag: Rotate player positions
void () UpdateLastOrigin =
{
	// push array towards the end, this could be replaced with a circular buffer
	float i;
	for(i = ANTILAG_STATES-1; i > 0; i--)
	{
		self.lastorigin[i] = self.lastorigin[i-1];
		self.lastorigintime[i] = self.lastorigintime[i-1];
	}

	self.lastorigin[0] = self.origin;
	self.lastorigintime[0] = (time * 1000);
};

// QCAntilag: Rewind an entity "e" to "rewindtime" to check for lag-compensated hits
void (entity e, float rewindtime) antilag_rewind =
{
	vector rewindorigin;

	float i;
	for(i = 0; i < ANTILAG_STATES; i++)
	{
		// if we encounter a cleared value
		if (lastorigintime[i] == 0)
		{
			// if this is the first array entry, the entire thing is cleared
			if (i == 0) {
				// return without messing with origin
				return;
			}
			// use the previous one
			else if (i > 0) {
				rewindorigin = e.lastorigin[i - 1];
				break;
			}
		}
		// if we've gone over our target rewind time, use this origin
		else if (rewindtime > e.lastorigintime[i])
		{
			rewindorigin = e.lastorigin[i];
			break;
		}
	}

	setorigin(e, rewindorigin);
}

// QCAntilag: Rewind all players to "pingtime" except for player "ignore"
void (float pingtime, entity ignore) antilag_rewind_players =
{
	local entity player;

	float timestamp_we_want = ((time * 1000) - pingtime);

	player = find(world, classname, "player");

	while (player)
	{
		if (player.deadflag == DEAD_NO)
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

// QCAntilag: Restore all players' .origin back to where the server thinks they are
void () antilag_restore_players =
{
	local entity player;

	player = find(world, classname, "player");

	while (player)
	{
		if (player.deadflag == DEAD_NO)
		{
			// Put everybody back where the server thinks they belong
			setorigin(player, player.hold_origin);
		}
		player = find(player, classname, "player");
	}
}

// QCAntilag: Extrapolate the visual antilagged position of projectiles to send to clients
void Extrapolate_AntilagProjectile(entity missile)
{
	// Original physics position should have been stored in missile.hold_origin already

	// Make sure to multiply by 0.001 to convert into seconds for desired velocity
	traceline(missile.origin, missile.origin + (missile.velocity * missile.responsetime * 0.001), FALSE, missile);
	// Move to the extrapolated position for good visuals
	setorigin(missile, trace_endpos);
}

// QCAntilag: .think function for antilag projectiles (i.e. rockets, nails/spikes)
void ThinkMovetype_AntilagProjectile()
{
	self.think = ThinkMovetype_AntilagProjectile;
	self.nextthink = time + 0.01;

	setorigin(self, self.hold_origin);

	// If our SSQC is running at hyper fast framerate for some reason (FTE)
	local float delta = frametime;
	if (is_running_fte)
	{
		if (cvar("sv_gameplayfix_multiplethinks") || delta < 0.01)
			delta = 0.01;
	}

	// Use the client's response time to temporarily move all other player entities back in time
	antilag_rewind_players(self.responsetime, self.owner);

	// Trace a line from current position to the place where we'll be after the next frame
	traceline(self.origin, self.origin + (self.velocity * delta), FALSE, self);

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

	// Track our true position
	self.hold_origin = self.origin;

	// Run extrapolation
	Extrapolate_AntilagProjectile(self);
}
