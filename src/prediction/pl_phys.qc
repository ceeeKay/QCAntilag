
#define PHYS_MINIMUMRATE 	1/72
#define PHYS_XERPRATE 		1/60

float	pm_tickrate;
float	pm_accelerate;
float	pm_friction;
float	pm_edgefriction;
float	pm_stopspeed;
float	pm_maxspeed;
float	pm_nostep;
float	pm_gravity;
.float	ping;

enum gstat:float {
STAT_PM_TICKRATE = 40,
STAT_PM_ACCEL,
STAT_PM_FRICTION,
STAT_PM_EDGEFRICTION,
STAT_PM_STOPSPEED,
STAT_PM_MAXSPEED,
STAT_PM_NOSTEP,
STAT_PM_GRAVITY,
STAT_PING,
STAT_CSQCFLAGS
};



void PM_UpdateVariables()
{
	#ifdef SSQC
	pm_tickrate = bound(0.013, cvar("sv_playertic"), 0.1);
	pm_accelerate = cvar("sv_accelerate");
	pm_friction = cvar("sv_friction");
	pm_edgefriction = max(1, cvar("sv_edgefriction"));
	pm_stopspeed = cvar("sv_stopspeed");
	pm_maxspeed = cvar("sv_maxspeed");
	pm_nostep = cvar("sv_nostep");
	pm_gravity = cvar("sv_gravity");
	#endif
	#ifdef CSQC
	pm_tickrate = getstatf(STAT_PM_TICKRATE);
	pm_accelerate = getstatf(STAT_PM_ACCEL);
	pm_friction = getstatf(STAT_PM_FRICTION);
	pm_edgefriction = getstatf(STAT_PM_EDGEFRICTION);
	pm_stopspeed = getstatf(STAT_PM_STOPSPEED);
	pm_maxspeed = getstatf(STAT_PM_MAXSPEED);
	pm_nostep = getstatf(STAT_PM_NOSTEP);
	pm_gravity = getstatf(STAT_PM_GRAVITY);
	#endif
}

#ifdef SSQC
void PM_InitVariables()
{
	
	globalstat(STAT_PM_TICKRATE, 	EV_FLOAT, "pm_tickrate");
	globalstat(STAT_PM_ACCEL, 		EV_FLOAT, "pm_accelerate");
	globalstat(STAT_PM_FRICTION, 	EV_FLOAT, "pm_friction");
	globalstat(STAT_PM_EDGEFRICTION,EV_FLOAT, "pm_edgefriction");
	globalstat(STAT_PM_STOPSPEED, 	EV_FLOAT, "pm_stopspeed");
	globalstat(STAT_PM_MAXSPEED, 	EV_FLOAT, "pm_maxspeed");
	globalstat(STAT_PM_NOSTEP, 		EV_FLOAT, "pm_nostep");
	globalstat(STAT_PM_GRAVITY, 	EV_FLOAT, "pm_gravity");
	clientstat(STAT_PING,			EV_FLOAT, ping);
	clientstat(STAT_CSQCFLAGS,		EV_FLOAT, csqc_enabled);
}
#endif


void PHYS_Impact(entity e1, entity e2)
{
	entity		old_self, old_other;
	
	old_self = self;
	old_other = other;
	
	if (e1.touch && e1.solid != SOLID_NOT)
	{
		self = e1;
		other = e2;
		e1.touch();
	}
	
	if (e2.touch && e2.solid != SOLID_NOT)
	{
		self = e2;
		other = e1;
		e2.touch();
	}

	self = old_self;
	other = old_other;
}


void PHYS_PushEntity(entity ent, vector push)
{
	vector	end;
	end = ent.origin + push;

	if (ent.movetype == MOVETYPE_FLYMISSILE)
		tracebox(ent.origin, ent.mins, ent.maxs, end, MOVE_MISSILE, ent);
	else if (ent.solid == SOLID_TRIGGER || ent.solid == SOLID_NOT)
		tracebox(ent.origin, ent.mins, ent.maxs, end, MOVE_NOMONSTERS, ent);
	else
		tracebox(ent.origin, ent.mins, ent.maxs, end, MOVE_NORMAL, ent);	
	
	setorigin(ent, trace_endpos);

	if (trace_ent)
		PHYS_Impact (ent, trace_ent);
}		

/*
==================
PHYS_UserFriction
==================
*/
void PHYS_UserFriction (void)
{
	float	speed, newspeed, control, fric;
	vector	start, stop;
	
	speed = sqrt(self.velocity_x * self.velocity_x + self.velocity_y * self.velocity_y);
	if (!speed)
		return;

// if the leading edge is over a dropoff, increase friction
	start_x = stop_x = self.origin_x + self.velocity_x/speed*16;
	start_y = stop_y = self.origin_y + self.velocity_y/speed*16;
	start_z = self.origin_z + self.mins_z;
	stop_z = start_z - 34;

	traceline(start, stop, TRUE, self);

	if (trace_fraction >= 1.0)
		fric = pm_friction * pm_edgefriction;
	else
		fric = pm_friction;

// apply friction	
	control = speed < pm_stopspeed ? pm_stopspeed : speed;
	newspeed = speed - input_timelength * control * fric;
	
	if (newspeed < 0)
		newspeed = 0;
	newspeed /= speed;

	self.velocity_x = self.velocity_x * newspeed;
	self.velocity_y = self.velocity_y * newspeed;
	self.velocity_z = self.velocity_z * newspeed;
}

/*
==============
PHYS_Accelerate
==============
*/
void PHYS_Accelerate (vector wishdir, float wishspeed)
{
	float			i;
	float		addspeed, accelspeed, currentspeed;
	
	currentspeed = dotproduct(self.velocity, wishdir);
	addspeed = wishspeed - currentspeed;
	
	if (addspeed <= 0)
		return;
	accelspeed = pm_accelerate * input_timelength * wishspeed;
	if (accelspeed > addspeed)
		accelspeed = addspeed;
	
	//for (i=0; i<3; i++)
	//	self.velocity[i] += accelspeed * wishdir[i];	
	self.velocity += accelspeed * wishdir;
}

void PHYS_AirAccelerate (vector wishveloc)
{
	float			i;
	float		addspeed, wishspd, wishspeed, accelspeed, currentspeed;
	
	wishspeed = vlen(wishveloc);
	wishspd = vlen(wishveloc);
	wishveloc = normalize(wishveloc);
	if (wishspd > 30)
		wishspd = 30;
	currentspeed = dotproduct(self.velocity, wishveloc);
	addspeed = wishspd - currentspeed;
	if (addspeed <= 0)
		return;
	accelspeed = pm_accelerate * input_timelength * wishspeed;
	if (accelspeed > addspeed)
		accelspeed = addspeed;
	
	//for (i=0 ; i<3 ; i++)
	//	self.velocity[i] += accelspeed * wishveloc[i];	

	self.velocity += accelspeed * wishveloc;
}


void DropPunchAngle (void)
{
	float	len;
	
	len = vlen(self.punchangle);
	
	len -= 10 * input_timelength;
	if (len < 0)
		len = 0;
	
	self.punchangle = normalize(self.punchangle) * len;
}

/*
===================
PHYS_WaterMove
===================
*/
void PHYS_WaterMove (void)
{
	float	i;
	vector	wishvel;
	float	speed, newspeed, wishspeed, addspeed, accelspeed;

//
// user intentions
//
	makevectors(self.lt_input_angs);
	//AngleVectors (sv_player->v.v_angle, forward, right, up);

	//for (i=0; i<3; i++)
	//	wishvel[i] = v_forward[i] * self.lt_input_movevals[0] + v_right[i] * self.lt_input_movevals[1];
	wishvel = v_forward * self.lt_input_movevals_x + v_right * self.lt_input_movevals_y;

	if (!self.lt_input_movevals_x && !self.lt_input_movevals_y && !self.lt_input_movevals_z)
		wishvel_z -= 60;		// drift towards bottom
	else
		wishvel_z += self.lt_input_movevals[2];

	wishspeed = vlen(wishvel);
	if (wishspeed > pm_maxspeed)
	{
		wishvel *= pm_maxspeed/wishspeed;
		wishspeed = pm_maxspeed;
	}
	wishspeed *= 0.7;

//
// water friction
//
	speed = vlen(self.velocity);
	if (speed)
	{
		newspeed = speed - input_timelength * speed * pm_friction;
		if (newspeed < 0)
			newspeed = 0;	
		self.velocity *= newspeed/speed;
	}
	else
		newspeed = 0;
	
//
// water acceleration
//
	if (!wishspeed)
		return;

	addspeed = wishspeed - newspeed;
	if (addspeed <= 0)
		return;

	wishvel = normalize(wishvel);
	accelspeed = pm_accelerate * wishspeed * input_timelength;
	if (accelspeed > addspeed)
		accelspeed = addspeed;
	
	self.velocity += accelspeed * wishvel;
}

void PHYS_WaterJump (void)
{
	if (time > self.teleport_time
	|| !self.waterlevel)
	{
		self.flags = self.flags & ~FL_WATERJUMP;
		self.teleport_time = 0;
	}
	self.velocity[0] = self.movedir[0];
	self.velocity[1] = self.movedir[1];
}


/*
===================
PHYS_AirMove
===================
*/
void PHYS_AirMove (void)
{
	float		i;
	vector		wishvel, wishdir;
	float		wishspeed, onground;
	float		fmove, smove;

	makevectors([0, self.lt_input_angs_y, 0]);

	fmove = self.lt_input_movevals_x;
	smove = self.lt_input_movevals_y;
	
// hack to not let you back into teleporter
	if (time < self.teleport_time && fmove < 0)
		fmove = 0;
	
	/*
	for (i=0; i<3; i++)
		wishvel[i] = v_forward[i] * fmove + v_right[i] * smove;
	//*/
	
	wishvel = (v_forward * fmove) + (v_right * smove);
	

	if ( self.movetype != MOVETYPE_WALK)
		wishvel_z = self.lt_input_movevals_z;
	else
		wishvel_z = 0;
	
	wishdir = normalize(wishvel);
	wishspeed = vlen(wishvel);
	if (wishspeed > pm_maxspeed)
	{
		wishvel *= pm_maxspeed/wishspeed;
		wishspeed = pm_maxspeed;
	}
	
	
	
	if ( self.movetype == MOVETYPE_NOCLIP)
	{	// noclip
		self.velocity = wishvel;
	}
	else if ( self.flags & FL_ONGROUND )
	{
		PHYS_UserFriction ();
		PHYS_Accelerate (wishdir, wishspeed);
	}
	else
	{	// not on ground, so little effect on velocity
		PHYS_AirAccelerate (wishvel);
	}		
}

/*
===================
PHYS_ClientThink
the move fields specify an intended velocity in pix/sec
the angle fields specify an exact angular motion in degrees
===================
*/
void PHYS_ClientThink (void)
{
	vector		v_angle;

	if (self.movetype == MOVETYPE_NONE)
		return;
	
//
// if dead, behave differently
//
	if (self.health <= 0)
		return;

	/*
//
// angles
// show 1/3 the pitch angle and all the roll angle
	cmd = host_client->cmd;
	angles = sv_player->v.angles;
	
	VectorAdd (sv_player->v.v_angle, sv_player->v.punchangle, v_angle);
	angles[ROLL] = V_CalcRoll (sv_player->v.angles, sv_player->v.velocity)*4;
	if (!self.fixangle)
	{
		angles[PITCH] = -v_angle[PITCH]/3;
		angles[YAW] = v_angle[YAW];
	}
	*/

	if (self.flags & FL_WATERJUMP)
	{
		PHYS_WaterJump ();
		return;
	}
//
// walk
//
	if ((self.waterlevel >= 2) && (self.movetype != MOVETYPE_NOCLIP))
	{
		PHYS_WaterMove ();
		return;
	}

	PHYS_AirMove ();	
}








/*
==================
ClipVelocity

Slide off of the impacting object
returns the blocked flags (1 = floor, 2 = step / wall)
==================
*/
#define	STOP_EPSILON	0.1

vector clip_out;
float ClipVelocity (vector in, vector normal, vector out, float overbounce)
{
	float	backoff;
	float	change;
	float	i, blocked;
	
	blocked = 0;
	if (normal[2] > 0)
		blocked |= 1;		// floor
	if (!normal[2])
		blocked |= 2;		// step
	
	backoff = dotproduct(in, normal) * overbounce;
	
	/*
	for (i=0 ; i<3 ; i++)
	{
		change = normal[i]*backoff;
		out[i] = in[i] - change;
		if (out[i] > -STOP_EPSILON && out[i] < STOP_EPSILON)
			out[i] = 0;
	}
	*/
	
	
	/// we have to do this yucky hack, because without extended instructions
	/// treating vectors like arrays causes crashes >.>
	change = normal_x * backoff;
	out_x = in_x - change;
	if (out_x > -STOP_EPSILON && out_x < STOP_EPSILON)
		out_x = 0;
	
	
	change = normal_y * backoff;
	out_y = in_y - change;
	if (out_y > -STOP_EPSILON && out_y < STOP_EPSILON)
		out_y = 0;
	
	
	change = normal_z * backoff;
	out_z = in_z - change;
	if (out_z > -STOP_EPSILON && out_z < STOP_EPSILON)
		out_z = 0;
	///
	
	
	clip_out = out;
	return blocked;
}


float PHYS_TestEntityPosition(entity ent)
{
	tracebox(ent.origin, ent.mins, ent.maxs, ent.origin, FALSE, self);
	
	if (trace_startsolid)
		return TRUE;
	
	return FALSE;
}

/*
=============
PHYS_CheckStuck

This is a big hack to try and fix the rare case of getting stuck in the world
clipping hull.
=============
*/
void PHYS_CheckStuck (entity ent)
{
	float		i, j;
	float		z;
	vector	org;

	if (!PHYS_TestEntityPosition(ent))
	{
		ent.oldorigin = ent.origin;
		return;
	}

	org = ent.origin;
	ent.origin = ent.oldorigin;
	if (!PHYS_TestEntityPosition(ent))
	{
		setorigin(ent, ent.origin);
		return;
	}
	
	for (z=0 ; z< 18 ; z++)
		for (i=-1 ; i <= 1 ; i++)
			for (j=-1 ; j <= 1 ; j++)
			{
				ent.origin[0] = org[0] + i;
				ent.origin[1] = org[1] + j;
				ent.origin[2] = org[2] + z;
				if (!PHYS_TestEntityPosition(ent))
				{
					#ifdef SSQC
					dprint("Unstuck.\n");
					#endif
					setorigin(ent, ent.origin);
					return;
				}
			}
			
	ent.origin = org;
	#ifdef SSQC
	dprint("player is stuck.\n");
	#endif
}



/*
============
PHYS_FlyMove

The basic solid body movement clip that slides along multiple planes
Returns the clipflags if the velocity was modified (hit something solid)
1 = floor
2 = wall / step
4 = dead stop
If steptrace is not NULL, the trace of any vertical wall hit will be stored
============
*/
#define	MAX_CLIP_PLANES	5
float PHYS_FlyMove (entity ent, float delta)
{
	float		bumpcount, numbumps;
	vector		dir;
	float		d;
	float		numplanes;
	vector		planes[MAX_CLIP_PLANES];
	vector		primal_velocity, original_velocity, new_velocity;
	float		i, j;
	vector		end;
	float		time_left;
	float		blocked;
	
	numbumps = 4;
	
	blocked = 0;
	original_velocity = ent.velocity;
	primal_velocity = ent.velocity;
	numplanes = 0;
	
	time_left = delta;

	for (bumpcount=0 ; bumpcount<numbumps ; bumpcount++)
	{
		if (!ent.velocity[0] && !ent.velocity[1] && !ent.velocity[2])
			break;

		///*
		for (i = 0; i < 3; i++)
		{
			//end[i] = ent.origin[i] + time_left * ent.velocity[i];
		}
		//*/
		
		//end_x = ent.origin_x + time_left * ent.velocity_x;
		//end_y = ent.origin_y + time_left * ent.velocity_y;
		//end_z = ent.origin_z + time_left * ent.velocity_z;
		end = ent.origin + time_left * ent.velocity;
		
		tracebox(ent.origin, ent.mins, ent.maxs, end, FALSE, ent);

		if (trace_allsolid)
		{	// entity is trapped in another solid
			ent.velocity = 0;
			return 3;
		}

		if (trace_fraction > 0)
		{	// actually covered some distance
			ent.origin = trace_endpos;
			original_velocity = ent.velocity;
			numplanes = 0;
		}

		if (trace_fraction == 1)
			 break;		// moved the entire distance

		//if (!trace_ent)
		//	Sys_Error ("PHYS_FlyMove: !trace.ent");

		if (trace_plane_normal_z > 0.7)
		{
			blocked |= 1;		// floor
			if (trace_ent.solid == SOLID_BSP)
			{
				//ent.flags =	ent.flags | FL_ONGROUND;
				//ent.groundentity = trace_ent;
			}
		}
		
		if (trace_plane_normal_z == 0)
		{
			blocked |= 2;		// step
			//if (steptrace)
			//	*steptrace = trace;	// save for player extrafriction
		}

//
// run the impact function
//
		PHYS_Impact (ent, trace_ent);
		if !(ent)
			break;		// removed by the impact function

		
		time_left -= time_left * trace_fraction;
		
	// cliped to another plane
		if (numplanes >= MAX_CLIP_PLANES)
		{	// this shouldn't really happen
			ent.velocity = 0;
			return 3;
		}
		
		planes[numplanes] = trace_plane_normal;
		numplanes++;
		
//
// modify original_velocity so it parallels all of the clip planes
//		
		///*
		for (i=0; i<numplanes; i++)
		{
			ClipVelocity (original_velocity, planes[i], new_velocity, 1.01);
			new_velocity = clip_out;
			for (j=0 ; j<numplanes ; j++)
				if (j != i)
				{
					if (dotproduct(new_velocity, planes[j]) < 0)
						break;	// not ok
				}
			if (j == numplanes)
				break;
		}
		//*/
		
		if (i != numplanes)
		{	// go along this plane
			ent.velocity = new_velocity;
		}
		else
		{	// go along the crease
			if (numplanes != 2)
			{
//				Con_Printf ("clip velocity, numplanes == %i\n",numplanes);
				ent.velocity = 0;
				return 7;
			}
			CrossProduct(planes[0], planes[1], dir);
			d = dotproduct(dir, ent.velocity);
			ent.velocity = dir * d;
		}

//
// if original velocity is against the original velocity, stop dead
// to avoid tiny occilations in sloping corners
//
		if (dotproduct(ent.velocity, primal_velocity) <= 0 && FALSE)
		{
			ent.velocity = 0;
			return blocked;
		}
	}
	
	return blocked;
}



/*
=============
PHYS_CheckWater
=============
*/
float PHYS_CheckWater (entity ent)
{
	vector	point;
	int		cont;

	point_x = ent.origin_x;
	point_y = ent.origin_y;
	point_z = ent.origin_z + ent.mins_z + 1;	
	
	ent.waterlevel = 0;
	ent.watertype = CONTENT_EMPTY;
	cont = pointcontents(point);
	if (cont <= CONTENT_WATER)
	{
		ent.watertype = cont;
		ent.waterlevel = 1;
		point_z = ent.origin_z + (ent.mins_z + ent.maxs_z)*0.5;
		cont = pointcontents(point);
		if (cont <= CONTENT_WATER)
		{
			ent.waterlevel = 2;
			point_z= ent.origin_z + ent.view_ofs_z;
			cont = pointcontents(point);
			if (cont <= CONTENT_WATER)
				ent.waterlevel = 3;
		}
	}
	
	return ent.waterlevel > 1;
}

/*
============
PHYS_WallFriction

============
*/
void PHYS_WallFriction (entity ent)
{
	float		d, i;
	vector		into, side;
	
	makevectors([0, self.lt_input_angs_y, 0]);
	d = dotproduct(trace_plane_normal, v_forward);
	
	d += 0.5;
	if (d >= 0)
		return;
		
// cut the tangential velocity
	i = dotproduct(trace_plane_normal, ent.velocity);
	into = trace_plane_normal * i;
	side = ent.velocity - into;
	
	ent.velocity_x = side_x * (1 + d);
	ent.velocity_y = side_y * (1 + d);
}

/*
=====================
PHYS_TryUnstick

Player has come to a dead stop, possibly due to the problem with limited
float precision at some angle joins in the BSP hull.

Try fixing by pushing one pixel in each direction.

This is a hack, but in the interest of good gameplay...
======================
*/
float PHYS_TryUnstick (entity ent, vector oldvel)
{
	float	i;
	vector	oldorg;
	vector	dir;
	float	clip;
	
	oldorg = ent.origin;
	dir = 0;

	for (i = 0; i < 8; i++)
	{
// try pushing a little in an axial direction
		switch (i)
		{
			case 0:	dir[0] = 2; dir[1] = 0; break;
			case 1:	dir[0] = 0; dir[1] = 2; break;
			case 2:	dir[0] = -2; dir[1] = 0; break;
			case 3:	dir[0] = 0; dir[1] = -2; break;
			case 4:	dir[0] = 2; dir[1] = 2; break;
			case 5:	dir[0] = -2; dir[1] = 2; break;
			case 6:	dir[0] = 2; dir[1] = -2; break;
			case 7:	dir[0] = -2; dir[1] = -2; break;
		}
		
		PHYS_PushEntity (ent, dir);

// retry the original move
		ent.velocity_x = oldvel_x;
		ent.velocity_y = oldvel_y;
		ent.velocity_z = 0;
		clip = PHYS_FlyMove (ent, 0.1);//, &steptrace);

		if ( fabs(oldorg_y - ent.origin_y) > 4
		|| fabs(oldorg_x - ent.origin_x) > 4 )
		{
//Con_DPrintf ("unstuck!\n");
			return clip;
		}
			
// go back to the original pos and try again
		ent.origin = oldorg;
	}
	
	ent.velocity = 0;
	return 7;		// still not moving
}

/*
=====================
PHYS_WalkMove

Only used by players
======================
*/
#define	STEPSIZE	18
void PHYS_WalkMove (entity ent)
{
	vector		upmove, downmove;
	vector		oldorg, oldvel;
	vector		nosteporg, nostepvel;
	float		clip;
	float		oldonground;
	
//
// do a regular slide move unless it looks like you ran into a step
//
	oldonground = ent.flags & FL_ONGROUND;
	ent.flags = ent.flags & ~FL_ONGROUND;
	ent.groundentity = world;
	
	if (self.client_time >= self.lt_jumpgrace)
	{
		tracebox(ent.origin, ent.mins, ent.maxs, ent.origin + '0 0 -0.5', FALSE, ent);
		if (trace_plane_normal_z > 0.7)
		{
			if (trace_ent.solid == SOLID_BSP)
			{
				ent.groundentity = trace_ent;
				ent.flags |= FL_ONGROUND;
			}
		}
	}
	
	oldorg = ent.origin;
	oldvel = ent.velocity;
	
	clip = PHYS_FlyMove(ent, input_timelength);//, &steptrace);
	
	if ( !(clip & 2) )
		return;		// move didn't block on a step

	if (!oldonground && ent.waterlevel == 0)
		return;		// don't stair up while jumping
	
	if (ent.movetype != MOVETYPE_WALK)
		return;		// gibbed by a trigger
	
	if (pm_nostep)
		return;
	
	if (ent.flags & FL_WATERJUMP)
		return;
	
	nosteporg = ent.origin;
	nostepvel = ent.velocity;

//
// try moving up and forward to go up a step
//
	ent.origin = oldorg;
	upmove = 0;
	downmove = 0;
	
	upmove_z = STEPSIZE;
	downmove_z = -STEPSIZE + oldvel[2] * input_timelength;

// move up
	PHYS_PushEntity(ent, upmove);	// FIXME: don't link?

// move forward
	ent.velocity_x = oldvel_x;
	ent.velocity_y = oldvel_y;
	ent.velocity_z = 0;
	clip = PHYS_FlyMove(ent, input_timelength);//, &steptrace);
	
	vector h_tpn = trace_plane_normal;
	float h_tf = trace_fraction;

// check for stuckness, possibly due to the limited precision of floats
// in the clipping hulls
	if (clip)
	{
		if ( fabs(oldorg_y - ent.origin_y) < 0.03125
		&& fabs(oldorg_x - ent.origin_x) < 0.03125 )
		{	// stepping up didn't make any progress
			clip = PHYS_TryUnstick(ent, oldvel);
		}
	}
	
	trace_plane_normal = h_tpn;
	trace_fraction = h_tf;
	
// extra friction based on view angle
	if ( clip & 2 )
		PHYS_WallFriction(ent);//, &steptrace);

// move down
	//downtrace = PHYS_PushEntity (ent, downmove);	// FIXME: don't link?
	PHYS_PushEntity(ent, downmove);

	if (trace_plane_normal_z > 0.7)
	{
		if (ent.solid == SOLID_BSP)
		{
			//ent.flags =	ent.flags | FL_ONGROUND;
			//ent.groundentity = trace_ent;
		}
	}
	else
	{
// if the push down didn't end up on good ground, use the move without
// the step up.  This happens near wall / slope combinations, and can
// cause the player to hop up higher on a slope too steep to climb	
		ent.origin = nosteporg;
		ent.velocity = nostepvel;
	}
}

void PHYS_AddGravity(entity ent, float delta)
{
	ent.velocity_z -= ent.gravity * pm_gravity * delta;
}


void(entity ent) PHYS_Physics_Client
{
	switch (ent.movetype)
	{
	case MOVETYPE_NONE:
		//if (!PHYS_RunThink (ent))
		//	return;
		break;

	case MOVETYPE_WALK:
		//if (!PHYS_RunThink (ent))
		//	return;
		if (!PHYS_CheckWater(ent) && !(ent.flags & FL_WATERJUMP))
			PHYS_AddGravity (ent, input_timelength * 0.5);
		#ifdef SSQC
		PHYS_CheckStuck (ent);
		#endif
		PHYS_WalkMove (ent);
		if (!PHYS_CheckWater(ent) && !(ent.flags & FL_WATERJUMP) && (ent.velocity[2] != 0))
			PHYS_AddGravity (ent, input_timelength * 0.5);
		break;
		
	case MOVETYPE_TOSS:
	case MOVETYPE_BOUNCE:
		//PHYS_Physics_Toss (ent);
		#ifdef SSQC
		runstandardplayerphysics(ent);
		#endif
		break;

	case MOVETYPE_FLY:
		//if (!PHYS_RunThink (ent))
		//	return;
		PHYS_FlyMove (ent, input_timelength);
		break;
		
	case MOVETYPE_NOCLIP:
		//if (!PHYS_RunThink (ent))
		//	return;
		ent.origin = ent.velocity * input_timelength;
		break;
		
	//default:
	//	Sys_Error ("PHYS_Physics_client: bad movetype %i", ent.movetype);
	}
	
	touchtriggers(ent);
}


void() PL_SimulateNetquakeTickrate
{
	if (self.client_time >= self.lt_nextupdate)
	{
		self.lt_input_angs = input_angles;
		self.lt_input_movevals = input_movevalues;
		self.lt_nextupdate = self.client_time + pm_tickrate;
	}
}


void() PL_Jump
{
	if !(self.flags & FL_ONGROUND)
	{
		self.lt_jumptime = self.client_time + pm_tickrate;
	}
	
	if (input_buttons & 2)
	{
		if (self.flags & FL_WATERJUMP)
			return;
		
		if (self.waterlevel >= 2)
		{
			if (self.watertype == CONTENT_WATER)
				self.velocity_z = 100;
			else if (self.watertype == CONTENT_SLIME)
				self.velocity_z = 80;
			else
				self.velocity_z = 50;

			#ifdef SSQC
			// play swiming sound
			if (self.swim_flag < time)
			{
				self.swim_flag = time + 1;
				if (random() < 0.5)
					sound (self, CHAN_BODY, "misc/water1.wav", 1, ATTN_NORM);
				else
					sound (self, CHAN_BODY, "misc/water2.wav", 1, ATTN_NORM);
			}
			#endif
			return;
		}

		if (!(self.flags & FL_ONGROUND))
			return;
		
		if (self.client_time < self.lt_jumptime)
			return;

		if (!(self.flags & FL_JUMPRELEASED))
			return;		// don't pogo stick

		//self.flags = self.flags - (self.flags & FL_JUMPRELEASED);
		//self.flags = self.flags - FL_ONGROUND;	// don't stairwalk
		//CRMOD - this is more efficient
		self.lt_jumpgrace = self.client_time + 0.02;
		self.flags = self.flags - (self.flags & (FL_JUMPRELEASED | FL_ONGROUND));//
		#ifdef SSQC
		self.finaldest_x = time;  // CRMOD - player is alive
		#endif
		
		input_buttons -= input_buttons & 2;
		
		#ifdef SSQC
		// player jumping sound
		sound (self, CHAN_BODY, "player/plyrjmp8.wav", 1, ATTN_NORM);
		#endif
		
		self.velocity_z = self.velocity_z + 270;
	}
	else
		self.flags = self.flags | FL_JUMPRELEASED;
}


void() PL_SimulateClientCommands
{
	float tleft = input_timelength;
	while (tleft > 0)
	{
		input_timelength = min(tleft, PHYS_MINIMUMRATE);
		//if (input_timelength < 0.01)
		//	break;
		
		if !(self.deadflag)
			PL_Jump();
		
		self.client_time += input_timelength;
		
		PL_SimulateNetquakeTickrate();
		PHYS_ClientThink();
		PHYS_Physics_Client(self);
		
		
		tleft -= input_timelength;
	}
}


void(float tleft) PL_BasicXerp
{
	//PHYS_CheckStuck(self);
	
	while (tleft > 0)
	{
		input_timelength = min(tleft, PHYS_XERPRATE);
		
		PL_Jump();
		//PL_SimulateNetquakeTickrate();
		PHYS_ClientThink();
		PHYS_Physics_Client(self);
		
		tleft -= input_timelength;
	}
}


#ifdef SSQC
void PM_ClientConnect()
{
	self.netquake_client = TRUE;
	if (infokeyf(self, INFOKEY_P_CSQCACTIVE)) // CSQC means we're always doing prediction
	{
		self.csqc_enabled |= CSQC_ENABLED;
		self.netquake_client = FALSE;
	}
	else if (strstrofs(infokey(self, "protocol"), "quakeworld") != -1 || infokey(self, "protocol") == "qex666") // clients will force their own brand of prediction, hopefully they're close enough
	{
		self.netquake_client = FALSE;
	}
	
	string client_engine = infokey(self, "*ver");
	if (strstrofs(client_engine, "FTE", 0) == -1)
		self.csqc_enabled |= CSQC_SHITTYENGINE;
	
	
	sprint(self, "This server is using predictable NQ physics!\n");
	if (self.netquake_client)
	{
		sprint(self, "You are connected with a NQ client, you will not have prediction.\n");
	}
	else if (self.csqc_enabled & CSQC_ENABLED)
	{
		sprint(self, "You are connected with a CSQC compatible client, you should have a smooth experience.\n");
	}
	else
	{
		sprint(self, "You are connected with a proprietary-prediction client, your experience may not be smooth when physics differences occur.\n");
	}
}


void PM_ClientDisconnect()
{
	
}



void() PM_PlayerPreThink;
void() PM_PlayerPostThink;

void PM_RunClient()
{
	DropPunchAngle();
	
	self.v_angle = input_angles;
	makevectors(input_angles);
	PM_PlayerPreThink();
	
	PL_SimulateClientCommands();
	PL_PrepareSendFlags();
	
	self.v_angle = input_angles;
	makevectors(input_angles);
	PM_PlayerPostThink();
}


void PM_StartFrame()
{
	// update prediction globals
	PM_UpdateVariables();
	
	// run classic NQ clients, so they're a bit smoother
	for(entity client = findflags(world, flags, FL_CLIENT); client; client = findflags(client, flags, FL_CLIENT))
	{
		self = client;
		if !(self.netquake_client)
			continue;
		
		Input_Restore(client);
		client.i_state.buttons = 0;
		client.i_state.impulse = 0;
		input_timelength = frametime;
		
		PM_RunClient();
	}
}


void() SV_RunClientCommand
{
	if (self.netquake_client)
	{
		input_buttons |= self.i_state->buttons;
		if (!input_impulse)
			input_impulse = self.i_state->impulse;
		
		Input_Save(self);
		return;
	}
	
	PM_RunClient();
}
#endif





