inside PlayerPostThink:

// add this
	if (self.impulse == 37)
		client_responsetime_show();
	else if (self.impulse == 38)
		client_responsetime_set();
// and this
	UpdateLastOrigin();

	if (self.view_ofs == '0 0 0')
		return;		// intermission or finale
	if (self.deadflag)
		return;
...


add these functions:

void () client_ping_think =
{
    local entity client;

    client = find(world, classname, "player");
    while (client)
    {
		client.responsetime3 = client.responsetime2;
		client.responsetime2 = client.responsetime1;

		if (client.finaldest_y > self.finaldest_x)
			client.responsetime1 = (floor(client.finaldest_y - self.finaldest_x) - 16);
		else
			client.responsetime1 = ANTILAG_MAX_RESPONSETIME;

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

void () client_responsetime_get_all =
{
    local entity ping;

    WriteByte(MSG_BROADCAST, SVC_STUFFTEXT);
    WriteString(MSG_BROADCAST, "impulse 38\n");

    ping = spawn();
    ping.classname = "client_ping";
    ping.owner = world;
    ping.nextthink = time + 2;
    ping.think = client_ping_think;
    ping.finaldest_x = (time * 1000);
};

void () client_responsetime_set =
{
    self.finaldest_y = (time * 1000);
};

//debug function to see response times and frames
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
    sprint(self, "last frame1: ");
	sprint(self, vtos(self.lastorigin1));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime1));
	sprint(self, "\n");
    sprint(self, "last frame2: ");
	sprint(self, vtos(self.lastorigin2));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime2));
	sprint(self, "\n");
    sprint(self, "last frame3: ");
	sprint(self, vtos(self.lastorigin3));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime3));
	sprint(self, "\n");
    sprint(self, "last frame4: ");
	sprint(self, vtos(self.lastorigin4));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime4));
	sprint(self, "\n");
    sprint(self, "last frame5: ");
	sprint(self, vtos(self.lastorigin5));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime5));
	sprint(self, "\n");
    sprint(self, "last frame6: ");
	sprint(self, vtos(self.lastorigin6));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime6));
	sprint(self, "\n");
    sprint(self, "last frame7: ");
	sprint(self, vtos(self.lastorigin7));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime7));
	sprint(self, "\n");
    sprint(self, "last frame8: ");
	sprint(self, vtos(self.lastorigin8));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime8));
	sprint(self, "\n");
    sprint(self, "last frame9: ");
	sprint(self, vtos(self.lastorigin9));
	sprint(self, " ");
	sprint(self, ftos(self.lastorigintime9));
	sprint(self, "\n");
};

// rotate player positions
void () UpdateLastOrigin =
{
	self.lastorigin9 = self.lastorigin8;
	self.lastorigintime9 = self.lastorigintime8;
	self.lastorigin8 = self.lastorigin7;
	self.lastorigintime8 = self.lastorigintime7;
	self.lastorigin7 = self.lastorigin6;
	self.lastorigintime7 = self.lastorigintime6;
	self.lastorigin6 = self.lastorigin5;
	self.lastorigintime6 = self.lastorigintime5;
	self.lastorigin5 = self.lastorigin4;
	self.lastorigintime5 = self.lastorigintime4;
	self.lastorigin4 = self.lastorigin3;
	self.lastorigintime4 = self.lastorigintime3;
	self.lastorigin3 = self.lastorigin2;
	self.lastorigintime3 = self.lastorigintime2;
	self.lastorigin2 = self.lastorigin1;
	self.lastorigintime2 = self.lastorigintime1;
	self.lastorigin1 = self.origin;
	self.lastorigintime1 = (time * 1000);
};
