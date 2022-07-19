void antilag_restore_projectiles(string class)
{
	local entity projectile;

	projectile = find(world, classname, class);

	while (projectile)
	{
		if (projectile.think != ThinkMovetype_AntilagProjectile) {
			projectile = find(projectile, classname, class);
			continue;
		}

	    setorigin(projectile, projectile.hold_origin);

		projectile = find(projectile, classname, class);
	}
}

in StartFrame:

// after this
	teamplay = cvar("teamplay");
	skill = cvar("skill");
	framecount = framecount + 1;

// add this
	if (time > responsetimecheck)
	{
		responsetimecheck = (time + 10);
		client_responsetime_get_all();
	}

// and this
	// Put projectiles back where they actually are before we do game things
	antilag_restore_projectiles("missile");
	antilag_restore_projectiles("spike");
