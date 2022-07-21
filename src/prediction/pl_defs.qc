

.vector lt_input_movevals;
.vector	lt_input_angs;
.float	lt_nextupdate;
.float	lt_jumptime;
.float	lt_jumpgrace;
.float	client_time;

struct inputstate_t {
	float		sequence;
	float		servertime;
	float		timelength;
	vector		angles;
	vector		movevalues;
	float		buttons;
	float		impulse;
};

.float			netquake_client;
.inputstate_t 	i_state;

#ifdef SSQC
void Input_Save(entity cl)
{
	cl.i_state.sequence = input_sequence;
	cl.i_state.servertime = input_servertime;
	cl.i_state.timelength = input_timelength;
	cl.i_state.angles = input_angles;
	cl.i_state.movevalues = input_movevalues;
	cl.i_state.buttons = input_buttons;
	cl.i_state.impulse = input_impulse;
}


void Input_Restore(entity cl)
{
	input_sequence = cl.i_state.sequence;
	input_servertime = cl.i_state.servertime;
	input_timelength = cl.i_state.timelength;
	input_angles = cl.i_state.angles;
	input_movevalues = cl.i_state.movevalues;
	input_buttons = cl.i_state.buttons;
	input_impulse = cl.i_state.impulse;
}
#endif

#ifdef SSQC
void PL_PrepareSendFlags();
#endif





