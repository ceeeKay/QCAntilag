
enum
{
	NET_ENTITY_GENERIC,
	NET_ENTITY_PLAYER,
};

enumflags
{
	NETFL_REMOTE = 0,
	NETFL_LOCAL,
	NETFL_INCOMPETENT, //NETFL_QSPASM,
	NETFL_TEAM
};

enumflags
{
	U_MODEL,
	U_FRAME,
	U_ANGLE,
	U_ORIGIN,
	U_SKIN,
	U_COLORMAP,
	U_EFFECTS,
	U_MOVEMENT,
	U_VIEWOFS,
	U_PREDTIMES,
};

typedef struct player_netdata
{
	vector angles;
	vector origin;
	float frame;
	float skin;
	float colormap;
	float modelindex;
	float effects;
	vector view_ofs;
	vector velocity;
	float movetype;
	float flags;
	float health;
	
	#if defined(SSQC)
	entity groundentity;
	#elif defined(CSQC)
	float groundentity;
	#endif
	
	float client_time;
	float lt_nextupdate;
	float lt_jumptime;
	float lt_jumpgrace;
	
	vector input_movevals;
	vector input_angs;
	
	#ifdef CSQC
	float update_time;
	float update_state;
	#endif
};

.player_netdata net_lastsent;
#ifdef CSQC
.player_netdata net_predicted;
.player_netdata net_old;
.player_netdata net_hold;


float last_inputframe;
float csqc_flags;
float getinputstate_ex(float num);
#endif

#ifdef SSQC
void PL_PrepareSendFlags()
{
	if (self.angles != self.net_lastsent.angles)
	{
		self.net_lastsent.angles = self.angles;
		self.SendFlags |= U_ANGLE;
	}
	
	if (self.origin != self.net_lastsent.origin || self.groundentity != self.net_lastsent.groundentity)
	{
		self.net_lastsent.origin = self.origin;
		self.net_lastsent.groundentity = self.groundentity;
		self.SendFlags |= U_ORIGIN;
	}
	
	if (self.frame != self.net_lastsent.frame)
	{
		self.net_lastsent.frame = self.frame;
		self.SendFlags |= U_FRAME;
	}
	
	if (self.skin != self.net_lastsent.skin)
	{
		self.net_lastsent.skin = self.skin;
		self.SendFlags |= U_SKIN;
	}
	
	if (self.colormap != self.net_lastsent.colormap)
	{
		self.net_lastsent.colormap = self.colormap;
		self.SendFlags |= U_COLORMAP;
	}
	
	if (self.modelindex != self.net_lastsent.modelindex)
	{
		self.net_lastsent.modelindex = self.modelindex;
		self.SendFlags |= U_MODEL;
	}
	
	if (self.effects != self.net_lastsent.effects)
	{
		self.net_lastsent.effects = self.effects;
		self.SendFlags |= U_EFFECTS;
	}
	
	if (self.view_ofs != self.net_lastsent.view_ofs)
	{
		self.net_lastsent.view_ofs = self.view_ofs;
		self.SendFlags |= U_VIEWOFS;
	}
	
	if (self.velocity != self.net_lastsent.velocity || self.movetype != self.net_lastsent.movetype || self.lt_input_angs != self.net_lastsent.input_angs || self.lt_input_movevals != self.net_lastsent.input_movevals || self.flags != self.net_lastsent.flags)
	{
		self.net_lastsent.movetype = self.movetype;
		self.net_lastsent.velocity = self.velocity;
		self.net_lastsent.input_angs = self.lt_input_angs;
		self.net_lastsent.input_movevals = self.lt_input_movevals;
		self.net_lastsent.flags = self.flags;
		self.SendFlags |= U_MOVEMENT;
	}
	
	self.SendFlags |= U_PREDTIMES;
}

float PL_SendEntity(entity to, float sendflags)
{
	float netflags = NETFL_REMOTE;
	if (to == self)
		netflags |= NETFL_LOCAL;
	if (to.csqc_enabled & CSQC_SHITTYENGINE)
		netflags |= NETFL_INCOMPETENT;
	
	WriteByte(MSG_ENTITY, NET_ENTITY_PLAYER);
	WriteByte(MSG_ENTITY, netflags);
	
	if (netflags & NETFL_LOCAL)
		WriteShort(MSG_ENTITY, sendflags);
	else
		WriteByte(MSG_ENTITY, sendflags);
	
	if (sendflags & U_MODEL)
		WriteByte(MSG_ENTITY, self.modelindex);
	
	if (sendflags & U_FRAME)
		WriteByte(MSG_ENTITY, self.frame);
	
	if (sendflags & U_COLORMAP)
		WriteByte(MSG_ENTITY, self.colormap);
	
	if (sendflags & U_SKIN)
		WriteByte(MSG_ENTITY, self.skin);
	
	if (sendflags & U_EFFECTS)
		WriteByte(MSG_ENTITY, self.effects);
	
	if (sendflags & U_ANGLE)
	{
		WriteAngle(MSG_ENTITY, self.angles_x);
		WriteAngle(MSG_ENTITY, self.angles_y);
		WriteAngle(MSG_ENTITY, self.angles_z);
	}
	
	
	if (netflags & NETFL_LOCAL)
	{
		if (sendflags & U_ORIGIN)
		{
			vector org = self.origin;
			if (self.groundentity)
				org -= self.groundentity.origin;
			
			if (netflags & NETFL_INCOMPETENT)
			{
				WriteLong(MSG_ENTITY, org_x * 1000);
				WriteLong(MSG_ENTITY, org_y * 1000);
				WriteLong(MSG_ENTITY, org_z * 1000);
			}
			else
			{
				WriteFloat(MSG_ENTITY, org_x);
				WriteFloat(MSG_ENTITY, org_y);
				WriteFloat(MSG_ENTITY, org_z);
			}
			
			WriteEntity(MSG_ENTITY, self.groundentity);
		}
		
		if (sendflags & U_MOVEMENT)
		{
			WriteByte(MSG_ENTITY, self.movetype | ((self.health > 0) * 128));
			
			
			WriteAngle(MSG_ENTITY, self.lt_input_angs_y);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_x);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_y);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_z);
			
			
			WriteShort(MSG_ENTITY, self.flags);
			
			if (netflags & NETFL_INCOMPETENT)
			{
				WriteLong(MSG_ENTITY, self.velocity_x * 1000);
				WriteLong(MSG_ENTITY, self.velocity_y * 1000);
				WriteLong(MSG_ENTITY, self.velocity_z * 1000);

			}
			else
			{
				WriteFloat(MSG_ENTITY, self.velocity_x);
				WriteFloat(MSG_ENTITY, self.velocity_y);
				WriteFloat(MSG_ENTITY, self.velocity_z);
			}
		}
		
		if (sendflags & U_VIEWOFS)
		{
			WriteByte(MSG_ENTITY, self.view_ofs_x + 127);
			WriteByte(MSG_ENTITY, self.view_ofs_y + 127);
			WriteByte(MSG_ENTITY, self.view_ofs_z + 127);
		}
		
		if (sendflags & U_PREDTIMES)
		{
			if (netflags & NETFL_INCOMPETENT)
			{
				WriteLong(MSG_ENTITY, self.client_time * 1000);
				WriteLong(MSG_ENTITY, self.lt_nextupdate * 1000);
				WriteLong(MSG_ENTITY, self.lt_jumptime * 1000);
				WriteLong(MSG_ENTITY, self.lt_jumpgrace * 1000);
			}
			else
			{
				WriteFloat(MSG_ENTITY, self.client_time);
				WriteFloat(MSG_ENTITY, self.lt_nextupdate);
				WriteFloat(MSG_ENTITY, self.lt_jumptime);
				WriteFloat(MSG_ENTITY, self.lt_jumpgrace);
			}
		}
	}
	else
	{
		if (sendflags & U_ORIGIN)
		{
			vector org = self.origin;
			if (self.groundentity)
				org -= self.groundentity.origin;
			
			WriteCoord(MSG_ENTITY, org_x);
			WriteCoord(MSG_ENTITY, org_y);
			WriteCoord(MSG_ENTITY, org_z);
			
			WriteEntity(MSG_ENTITY, self.groundentity);
		}
		
		if (sendflags & U_MOVEMENT)
		{
			WriteByte(MSG_ENTITY, self.movetype | ((self.health > 0) * 128));
			
			WriteAngle(MSG_ENTITY, self.lt_input_angs_y);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_x);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_y);
			WriteCoord(MSG_ENTITY, self.lt_input_movevals_z);
			
			WriteShort(MSG_ENTITY, self.flags);
			
			WriteCoord(MSG_ENTITY, self.velocity_x);
			WriteCoord(MSG_ENTITY, self.velocity_y);
			WriteCoord(MSG_ENTITY, self.velocity_z);
		}
	}
	
	return TRUE;
}
#endif


#ifdef CSQC
#define NET_STATE_FRESH 		1
#define NET_STATE_PREDICTED		2

entity view_subject;
float autocvar_v_viewheight;

vector  VEC_HULL_MIN = '-16 -16 -24';
vector  VEC_HULL_MAX = '16 16 32';

float	autocvar_cl_xerpClients;

.float	frame_starttime_old;
.float	frame_starttime_new;
.float	xerp_lastused;
.float	xerp_lazy_lastused;
.vector origin_errorcorrect;

void PL_CopyState(.player_netdata from, .player_netdata to)
{
	self.to.update_time = self.from.update_time;
	
	self.to.origin = self.from.origin;
	self.to.groundentity = self.from.groundentity;
	
	self.to.velocity = self.from.velocity;
	self.to.flags = self.from.flags;
	
	self.to.frame = self.from.frame;
	self.to.movetype = self.from.movetype;
	self.to.health = self.from.health;
	
	self.to.client_time = self.from.client_time;
	self.to.lt_nextupdate = self.from.lt_nextupdate;
	self.to.lt_jumptime = self.from.lt_jumptime;
	self.to.lt_jumpgrace = self.from.lt_jumpgrace;
	
	self.to.input_angs = self.from.input_angs;
	self.to.input_movevals = self.from.input_movevals;
}


void PL_RestoreState(.player_netdata state)
{
	self.origin = self.state.origin;
	
	if (self.state.groundentity)
	{
		vector g_org = getentity(self.state.groundentity, GE_ORIGIN);
		self.origin += g_org;
	}
	
	self.velocity = self.state.velocity;
	self.flags = self.state.flags;
	
	self.frame = self.state.frame;
	self.movetype = self.state.movetype;
	self.health = self.state.health;
	
	
	self.client_time = self.state.client_time;
	self.lt_nextupdate = self.state.lt_nextupdate;
	self.lt_jumptime = self.state.lt_jumptime;
	self.lt_jumpgrace = self.state.lt_jumpgrace;
	
	
	self.lt_input_angs = self.state.input_angs;
	self.lt_input_movevals = self.state.input_movevals;
}


void PL_LerpState(.player_netdata from, .player_netdata to, float frac)
{
	vector o1 = self.from.origin;
	if (self.from.groundentity)
		o1 += getentity(self.from.groundentity, GE_ORIGIN);
	
	
	vector o2 = self.to.origin;
	if (self.to.groundentity)
		o2 += getentity(self.to.groundentity, GE_ORIGIN);
	
	self.origin = o1 + (o2 - o1) * frac;
	
	
	vector a1 = self.from.angles;
	vector a2 = self.to.angles;
	self.angles = a1;
	self.angles_x -= angle_difference(a1_x, a2_x) * frac;
	self.angles_y -= angle_difference(a1_y, a2_y) * frac;
	self.angles_z -= angle_difference(a1_z, a2_z) * frac;
	self.net_predicted.angles = self.angles;
}

float clframetime;
void PL_Pred_ErrorCorrection()
{
	local float d = vlen(self.origin_errorcorrect);
	//tracebox(self.origin, self.mins + '0 0 8', self.maxs - '0 0 16', self.origin + self.origin_errorcorrect, MOVE_WORLDONLY, self);
	//d *= trace_fraction;
	
	local float mult = 1;
	local float spd = clframetime * 0.4;
	if (self != view_subject)
	{
		mult = 1.45;
		spd = clframetime * 0.5;
	}
	
	//if (d < 0.01 * mult)
	//	d = 0;
	//if (d < 400 * mult)
	//	d -= 5*spd;
	
	if (d < 0.5 * mult)
		d = 0;
	if (d < 4 * mult)
		d -= 120*spd;
	else if (d < 8 * mult)
		d -= 280*spd;
	else if (d < 18 * mult)
		d -= 400*spd;
	else if (d < 28 * mult)
		d -= 800*spd;
	else if (d < 42 * mult)
		d -= 1200*spd;
	else if (d < 64 * mult)
		d -= 2000*spd;
	else if (d < 112 * mult)
		d -= 2000*spd;
	else if (d < 128 * mult)
		d = 110;
	else
		d = 0;
	
	d = max(0, d);
	self.origin_errorcorrect = d * normalize(self.origin_errorcorrect);
}

float net_ping;
float net_pingquery;
float autocvar_cl_nopred;
vector pmove_vel;
vector stair_vieworigin;

float PL_Predraw()
{
	float time_interval = (self.net_lastsent.update_time - self.net_old.update_time) * 1.05;
	float frac = min((time - self.net_lastsent.update_time) / time_interval, 1.05);
	
	self.renderflags = 0;
	if (self.health <= 0)
	{
		self.solid = SOLID_NOT;
		PL_RestoreState(net_lastsent);
		if (self.net_lastsent.update_state == NET_STATE_FRESH)
		{
			self.net_lastsent.update_state = NET_STATE_PREDICTED;
			self.net_old.origin = self.net_predicted.origin;
		}
		
		PL_LerpState(net_old, net_lastsent, frac);
		
		if (view_subject == self)
		{
			self.renderflags = 2;
			setproperty(VF_ORIGIN, self.origin + self.view_ofs + [0, 0, bound(-8, autocvar_v_viewheight, 4)]);
		}
	}
	else if (view_subject == self)
	{
		setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
		self.solid = SOLID_SLIDEBOX;
		
		if (autocvar_cl_nopred)
		{
			//float time_interval = (self.net_old.update_time - self.net_hold.update_time) + 0.0125;
			if (self.net_lastsent.update_state == NET_STATE_FRESH)
			{
				self.net_lastsent.update_state = NET_STATE_PREDICTED;
				self.net_old.origin = self.net_predicted.origin;
			}
			
			PL_RestoreState(net_lastsent);
			PL_LerpState(net_old, net_lastsent, frac);
			
		}
		else
		{
			PM_UpdateVariables();
			PL_RestoreState(net_lastsent);
			
			float i;
			for(i = servercommandframe + 1; i <= clientcommandframe; i++)
			{
				if (!getinputstate_ex(i))
					continue;		//that input frame is too old.
				
				//input_angles_y += 180;
				
				PL_SimulateClientCommands();
			}
		}
		
		V_CalcBob();
		//makevectors(view_angles);
		
		if (self.flags & FL_ONGROUND)
		{
			float stairstep_speed = 180;
			
			stair_vieworigin[0] = self.origin[0];
			stair_vieworigin[1] = self.origin[1];
			stair_vieworigin[2] = bound(self.origin[2] - 16, stair_vieworigin[2], self.origin[2] + 16);
			
			if (stair_vieworigin[2] < self.origin[2])
			{
				stair_vieworigin[2] += stairstep_speed * clframetime;
				if (stair_vieworigin[2] > self.origin[2])
					stair_vieworigin[2] = self.origin[2];
			}
			else if (stair_vieworigin[2] > self.origin[2])
			{
				stair_vieworigin[2] -= stairstep_speed * clframetime;
				if (stair_vieworigin[2] < self.origin[2])
					stair_vieworigin[2] = self.origin[2];
			}
		}
		else
		{
			stair_vieworigin = self.origin;
		}
		
		
		vector view_origin = stair_vieworigin + self.view_ofs;
		
		if (autocvar_v_viewheight)
			view_origin_z += bound(-8, autocvar_v_viewheight, 4);
		else
			view_origin_z += v_bob;
		
		self.renderflags = 2;
		setproperty(VF_ORIGIN, view_origin);
		
		pmove_vel = self.velocity;
		V_ViewmodelPredraw();
	}
	else
	{
		setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
		self.solid = SOLID_SLIDEBOX;
		//PL_LerpState(net_old, net_lastsent, frac);
		
		if (self.net_lastsent.update_state == NET_STATE_FRESH)
		{
			self.net_lastsent.update_state = NET_STATE_PREDICTED;
			
			float xerp_time;
			vector temp_org;
			PL_RestoreState(net_old);
			input_movevalues = self.lt_input_movevals;
			input_angles = self.lt_input_angs;
			input_buttons = 0;
			xerp_time = (time - self.net_old.update_time) + self.xerp_lastused;
			PL_BasicXerp(xerp_time);
			self.origin += self.velocity * self.xerp_lazy_lastused;
			temp_org = self.origin;
			
			PL_RestoreState(net_lastsent);
			input_movevalues = self.lt_input_movevals;
			input_angles = self.lt_input_angs;
			input_buttons = 0;
			xerp_time = (time - self.net_lastsent.update_time) + self.xerp_lastused;
			PL_BasicXerp(xerp_time);
			self.origin += self.velocity * self.xerp_lazy_lastused;
			
			self.origin_errorcorrect = temp_org - (self.origin - self.origin_errorcorrect);
		}
		
		
		
		PL_RestoreState(net_lastsent);
		input_movevalues = self.lt_input_movevals;
		input_angles = self.lt_input_angs;
		input_buttons = 0;
		
		float xerp_time = 0;
		float xerp_lazy = 0;
		if (autocvar_cl_xerpClients)
		{
			float ping = net_ping / 1000;
			float xerp_extra = min(ping, 0.12);
			xerp_lazy = min(ping - xerp_extra, 0.06);
			
			self.xerp_lastused = xerp_extra;
			self.xerp_lazy_lastused = xerp_lazy;
			
			xerp_time = (time - self.net_lastsent.update_time) + self.xerp_lastused;
			PL_BasicXerp(xerp_time);
			
			if (xerp_lazy > 0)
				self.origin += self.velocity * xerp_lazy;
		}
		else
		{
			self.xerp_lastused = 0.013;
			self.xerp_lazy_lastused = 0;
			
			xerp_time = (time - self.net_lastsent.update_time) + self.xerp_lastused;
			PL_BasicXerp(xerp_time);
		}
		
		PL_Pred_ErrorCorrection();
		self.origin += self.origin_errorcorrect;
		
		setsize(self, VEC_HULL_MIN + '2 2 0', VEC_HULL_MAX - '2 2 2');
	}
	
	setorigin(self, self.origin);
	self.oldorigin = self.origin;
	self.net_predicted.angles = self.angles;
	self.net_predicted.origin = self.origin;
	self.net_predicted.groundentity = 0;
	
	
	//self.frame = self.net_old.frame;
	//self.frame2 = self.net_lastsent.frame;
	local float f_interval = min(0.12, self.frame_starttime_new - self.frame_starttime_old);
	self.lerpfrac = (time - self.frame_starttime_new) / f_interval;
	
	addentity(self);
	
	return 1;
}



void NetEntity_Player(float isnew)
{
	//PL_CopyState(net_old, net_hold);
	PL_CopyState(net_lastsent, net_old);
	self.net_old.angles = self.net_predicted.angles;
	//self.net_old.origin = self.net_predicted.origin;
	//self.net_old.groundentity = 0;
	self.net_lastsent.update_time = time;
	self.net_lastsent.update_state = NET_STATE_FRESH;
	
	float netflags = readbyte();
	float sendflags;
	
	if (netflags & NETFL_LOCAL)
	{
		view_subject = self;
		sendflags = readshort();
	}
	else
		sendflags = readbyte();
	
	
	if (sendflags & U_MODEL)
		self.modelindex = readbyte();
	
	if (sendflags & U_FRAME)
	{
		self.frame_starttime_old = self.frame_starttime_new;
		self.frame_starttime_new = time;
		self.frame = self.frame2;
		
		self.frame2 = readbyte();
		self.net_lastsent.frame = self.frame;
	}
	
	if (sendflags & U_COLORMAP)
		self.colormap = readbyte();
	
	if (sendflags & U_SKIN)
		self.skin = readbyte();
	
	if (sendflags & U_EFFECTS)
		self.effects = readbyte();
	
	if (sendflags & U_ANGLE)
	{
		self.angles_x = readangle();
		self.angles_y = readangle();
		self.angles_z = readangle();
		
		self.net_lastsent.angles = self.angles;
	}
	
	if (netflags & NETFL_LOCAL)
	{
		if (sendflags & U_ORIGIN)
		{
			if (netflags & NETFL_INCOMPETENT)
			{
				self.origin[0] = readlong() / 1000;
				self.origin[1] = readlong() / 1000;
				self.origin[2] = readlong() / 1000;
			}
			else
			{
				self.origin[0] = readfloat();
				self.origin[1] = readfloat();
				self.origin[2] = readfloat();
			}

			
			self.net_lastsent.origin = self.origin;
			self.net_lastsent.groundentity = readentitynum();
		}
		
		if (sendflags & U_MOVEMENT)
		{
			float data = readbyte();
			self.health = data & 128;
			self.net_lastsent.health = self.health;
			self.movetype = data & ~128;
			self.net_lastsent.movetype = self.movetype;
			
			
			self.lt_input_angs_y = readangle();
			self.lt_input_movevals_x = readcoord();
			self.lt_input_movevals_y = readcoord();
			self.lt_input_movevals_z = readcoord();
			self.net_lastsent.input_angs = self.lt_input_angs;
			self.net_lastsent.input_movevals = self.lt_input_movevals;
			
			
			self.flags = readshort();
			self.net_lastsent.flags = self.flags;
			
			if (netflags & NETFL_INCOMPETENT)
			{
				self.velocity_x = readlong() / 1000;
				self.velocity_y = readlong() / 1000;
				self.velocity_z = readlong() / 1000;
			}
			else
			{
				self.velocity_x = readfloat();
				self.velocity_y = readfloat();
				self.velocity_z = readfloat();
			}
			self.net_lastsent.velocity = self.velocity;
		}
		
		if (sendflags & U_VIEWOFS)
		{
			self.view_ofs_x = readbyte() - 127;
			self.view_ofs_y = readbyte() - 127;
			self.view_ofs_z = readbyte() - 127;
		}
		
		if (sendflags & U_PREDTIMES)
		{
			if (netflags & NETFL_INCOMPETENT)
			{
				self.client_time = readlong() / 1000;
				self.lt_nextupdate = readlong() / 1000;
				self.lt_jumptime = readlong() / 1000;
				self.lt_jumpgrace = readlong() / 1000;
			}
			else
			{			
				self.client_time = readfloat();
				self.lt_nextupdate = readfloat();
				self.lt_jumptime = readfloat();
				self.lt_jumpgrace = readfloat();
			}
			
			self.net_lastsent.client_time = self.client_time;
			self.net_lastsent.lt_nextupdate = self.lt_nextupdate;
			self.net_lastsent.lt_jumptime = self.lt_jumptime;
			self.net_lastsent.lt_jumpgrace = self.lt_jumpgrace;
		}
	}
	else
	{
		if (sendflags & U_ORIGIN)
		{
			self.origin[0] = readcoord();
			self.origin[1] = readcoord();
			self.origin[2] = readcoord();
			
			self.net_lastsent.origin = self.origin;
			self.net_lastsent.groundentity = readentitynum();
		}
		
		if (sendflags & U_MOVEMENT)
		{
			float data = readbyte();
			self.health = data & 128;
			self.net_lastsent.health = self.health;
			self.movetype = data & ~128;
			self.net_lastsent.movetype = self.movetype;
			
			self.lt_input_angs_y = readangle();
			self.lt_input_movevals_x = readcoord();
			self.lt_input_movevals_y = readcoord();
			self.lt_input_movevals_z = readcoord();
			self.net_lastsent.input_angs = self.lt_input_angs;
			self.net_lastsent.input_movevals = self.lt_input_movevals;
			
			self.flags = readshort();
			self.net_lastsent.flags = self.flags;
			
			self.velocity_x = readcoord();
			self.velocity_y = readcoord();
			self.velocity_z = readcoord();
			self.net_lastsent.velocity = self.velocity;
		}
	}
	
	if (isnew)
	{
		self.classname = "player";
		self.drawmask = MASK_ENGINE;
		self.predraw = PL_Predraw;
		self.gravity = 1;
		self.solid = SOLID_SLIDEBOX;
		setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
	}
}



void(float isnew) CSQC_Ent_Update
{
	float ent_index = readbyte();
	
	switch (ent_index)
	{
		case NET_ENTITY_GENERIC: /* */ break;
		case NET_ENTITY_PLAYER: NetEntity_Player(isnew); break;
	}
	
}



void SUB_Remove()
{
	remove(self);
}



#define beam_start velocity
#define beam_end oldorigin
float autocvar_cl_truelightning;
float autocvar_cl_lightningalpha;
float autocvar_cl_lightningscale;
float lightning_beam_predraw()
{
	vector end_beam = self.beam_end;
	
	if (self.owner)
	{
		self.beam_start = self.owner.origin;
		
		if (self.owner == view_subject)
		{
			if (autocvar_cl_truelightning)
			{
				vector angs1 = vectoangles(self.beam_end - self.beam_start);
				angs1[0] *= -1;
				
				if (autocvar_cl_truelightning == 3 && view_subject.entnum == player_localentnum)
				{
					getinputstate_ex(servercommandframe);
					angs1 = input_angles;
				}
				else if (autocvar_cl_truelightning == 2 && view_subject.entnum == player_localentnum)
				{
					getinputstate_ex(clientcommandframe - 2);
					angs1 = input_angles;
				}
				else if (autocvar_cl_truelightning >= 1)
				{
					getinputstate_ex(clientcommandframe);
					angs1 = input_angles;
				}
				else
				{
					angs1[0] += angle_difference(view_angles[0], angs1[0]) * autocvar_cl_truelightning;
					angs1[1] += angle_difference(view_angles[1], angs1[1]) * autocvar_cl_truelightning;
				}
				
				makevectors(angs1);
				traceline(self.owner.origin + '0 0 16', self.owner.origin + '0 0 16' + v_forward * 600, MOVE_NORMAL, self.owner);
				end_beam = trace_endpos;
			}
			
			makevectors(view_angles);
			self.beam_start[2] += 16;
			self.beam_start += v_up * -16;
		}
		else if (self.owner.classname == "player")
		{
			self.beam_start += '0 0 16';
		}
	}
	
	float separation = (30 / (self.scale ? 1/self.scale : 1));
	
	self.origin = self.beam_start;
	self.angles = vectoangles(self.beam_start - end_beam);
	float dist = vlen(self.beam_start - end_beam) / separation;
	vector dir = normalize(self.beam_start - end_beam);
	for(; dist > 0; dist--)
	{
		self.angles[2] = random() * 360;
		self.origin += dir * -separation;
		addentity(self);
	}
	
	
	if (self.think)
	{
		if (time > self.nextthink)
		{
			void() thonk = self.think;
			self.think = __NULL__;
			self.nextthink = 0;
			thonk();
		}
	}
	
	return 1;
}




float() CSQC_Parse_TempEntity =
{
	local float te_num = readbyte();
	
	if (te_num == TE_LIGHTNING2)
	{
		float entshort = readentitynum();
		vector start; start[0] = readcoord(); start[1] = readcoord(); start[2] = readcoord();
		vector end; end[0] = readcoord(); end[1] = readcoord(); end[2] = readcoord();
		entity ent = findfloat(world, entnum, entshort);
		
		if (ent)
		{
			for(entity list = find(world, classname, "beam"); list; list = find(list, classname, "beam"))
			{
				if (list.owner == ent)
					remove(list);
			}
			
			entity beam = spawn();
			beam.owner = ent;
			beam.classname = "beam";
			setmodel(beam, "progs/bolt2.mdl");
			
			beam.beam_start = start;
			beam.beam_end = end;
			
			beam.drawmask = MASK_ENGINE;
			beam.predraw = lightning_beam_predraw;
			if (autocvar_cl_lightningalpha)
				beam.alpha = autocvar_cl_lightningalpha;
			if (autocvar_cl_lightningscale)
				beam.scale = bound(0.1, autocvar_cl_lightningscale, 3);
			
			beam.think = SUB_Remove;
			beam.nextthink = time + 0.2;
			
			/*
			if (ent == view_subject)
				start = ent.net_predicted.origin;
			else
				start = ent.origin;
			*/
			
			return TRUE;
		}
		
		te_lightning2(ent, start, end);
		return TRUE;
	}
	
	
	return FALSE;
}


float getinputstate_ex(float num)
{
	if (csqc_flags & CSQC_SHITTYENGINE) // if our engine screws partial frames (qs, dp, whatever) then make some shit up!
	{
		if (num >= clientcommandframe)
		{
			float result = getinputstate(clientcommandframe-1);
			input_timelength = cltime - last_inputframe;
			return result;
		}
	}
	
	return getinputstate(num);
}


void() CSQC_Input_Frame
{
	last_inputframe = cltime;
}
#endif






















