

float autocvar_cl_bobup;
float autocvar_cl_bobcycle;
float autocvar_cl_bob;
entity view_subject;
entity v_viewmodel;
float v_bob;
float v_bobtime;

/*
===============
V_CalcBob

From WinQuake GPL Codebase
===============
*/
void V_CalcBob()
{
	entity cl = view_subject;
	if (!cl || !(cl.flags & FL_ONGROUND))
		return;
	
	v_bobtime += frametime;
	
	if (autocvar_cl_bobcycle == 0)
		return;
	
	float	cycle;
	cycle = cltime - (int)(v_bobtime / autocvar_cl_bobcycle) * autocvar_cl_bobcycle;
	cycle /= autocvar_cl_bobcycle;
	if (cycle < autocvar_cl_bobup)
		cycle = PI * cycle / autocvar_cl_bobup;
	else
		cycle = PI + PI*(cycle - autocvar_cl_bobup)/(1.0 - autocvar_cl_bobup);

// bob is proportional to velocity in the xy plane
// (don't count Z, or jumping messes it up)

	v_bob = sqrt(cl.velocity[0]*cl.velocity[0] + cl.velocity[1]*cl.velocity[1]) * autocvar_cl_bob;
	
	v_bob = v_bob * 0.3 + v_bob * 0.7 * sin(cycle);
	if (v_bob > 4)
		v_bob = 4;
	else if (v_bob < -7)
		v_bob = -7;
}




void V_ViewmodelPredraw()
{
	v_viewmodel.origin = 0;
	v_viewmodel.origin_x += v_bob * 0.4;
	
	float oldframe = v_viewmodel.frame;
	float oldmodel = v_viewmodel.modelindex;
	
	v_viewmodel.modelindex = getstati(STAT_WEAPONMODELI);
	v_viewmodel.frame = getstati(STAT_WEAPONFRAME);
	
	if (oldframe != v_viewmodel.frame)
	{
		v_viewmodel.frame2 = oldframe;
		v_viewmodel.lerpfrac = 1;
	}
	
	if (oldmodel != v_viewmodel.modelindex)
	{
		v_viewmodel.lerpfrac = 0;
	}
	
	v_viewmodel.lerpfrac = max(0, v_viewmodel.lerpfrac - frametime * 10);
	
	if (getstati(STAT_ITEMS) & IT_INVISIBILITY)
		v_viewmodel.modelindex = 0;
}


void V_ViewmodelCreate()
{
	v_viewmodel = spawn();
	v_viewmodel.drawmask = MASK_CUSTOMVIEWMODEL;
	v_viewmodel.renderflags = 1;
}











