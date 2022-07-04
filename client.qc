//PlayerPostThink after dying, before dead check  (or elohim_impulse for crmod)


if (self.impulse == 37)
    client_responsetime_show();
else if (self.impulse == 38) // used for sping (was 103)
	client_responsetime_update();
	
	
//Also call this in PlayerPostThink after dying, before dead check
	
SetPositions();


//then add these functions

void () client_responsetime_update =
{
    if (self.finaldest_x == 0)
    {
        //don't let clients interfere with response time
        return;
    }

    self.responsetime3 = self.responsetime2;
    self.responsetime2 = self.responsetime1;
    self.responsetime1 = (time - self.finaldest_x);
    self.finaldest_x = 0;

    if (self.responsetime2 > 0)
    {
        if (self.responsetime3 > 0)
        {
            self.responsetime = ((self.responsetime1 + self.responsetime2 + self.responsetime3) / 3);
        }
        else
        {
            self.responsetime = ((self.responsetime1 + self.responsetime2) / 2);
        }
    }
    else
    {
        self.responsetime = self.responsetime1;
    }
};

void () client_responsetime_get =
{
    self.finaldest_x = time;
    stuffcmd(self, "impulse 38;\n");
};

void () client_responsetime_show =
{
    sprint3(self, "response time3: ", ftos(self.responsetime3), "\n");
    sprint3(self, "response time2: ", ftos(self.responsetime2), "\n");
    sprint3(self, "response time1: ", ftos(self.responsetime1), "\n");
    sprint3(self, "response time:  ", ftos(self.responsetime), "\n");
    sprint3(self, "current origin: ", vtos(self.origin), "\n");
    sprint5(self, "last frame1: ", vtos(self.lastorigin1), " ", ftos(self.lastorigintime1), "\n");
    sprint5(self, "last frame2: ", vtos(self.lastorigin2), " ", ftos(self.lastorigintime2), "\n");
    sprint5(self, "last frame3: ", vtos(self.lastorigin3), " ", ftos(self.lastorigintime3), "\n");
    sprint5(self, "last frame4: ", vtos(self.lastorigin4), " ", ftos(self.lastorigintime4), "\n");
    sprint5(self, "last frame5: ", vtos(self.lastorigin5), " ", ftos(self.lastorigintime5), "\n");
    sprint5(self, "last frame6: ", vtos(self.lastorigin6), " ", ftos(self.lastorigintime6), "\n");
    sprint5(self, "last frame7: ", vtos(self.lastorigin7), " ", ftos(self.lastorigintime7), "\n");
    sprint5(self, "last frame8: ", vtos(self.lastorigin8), " ", ftos(self.lastorigintime8), "\n");
    sprint5(self, "last frame9: ", vtos(self.lastorigin9), " ", ftos(self.lastorigintime9), "\n");
};

void () SetPositions =
{
	if (time > self.responsetimecheck)
	{
		self.responsetimecheck = (time + 10);
		client_responsetime_get();
	}

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
	self.lastorigintime1 = time;
};
