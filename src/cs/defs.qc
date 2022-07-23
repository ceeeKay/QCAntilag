


.float 	health;
.float 	deadflag;
.vector view_ofs;
.float 	waterlevel;
.float	watertype;
.entity	groundentity;
.float	teleport_time
.vector	movedir;


float	FL_FLY					= 1;
float	FL_SWIM					= 2;
float	FL_CLIENT				= 8;	// set for all client edicts
float	FL_INWATER				= 16;	// for enter / leave water splash
float	FL_MONSTER				= 32;
float	FL_GODMODE				= 64;	// player cheat
float	FL_NOTARGET				= 128;	// player cheat
float	FL_ITEM					= 256;	// extra wide size for bonus items
float	FL_ONGROUND				= 512;	// standing on something
float	FL_PARTIALGROUND		= 1024;	// not all corners are valid
float	FL_WATERJUMP			= 2048;	// player jumping out of water
float	FL_JUMPRELEASED			= 4096;	// for jump debouncing
float	FL_ISBOT				= 8192; // is the client a bot?
float 	FL_NO_PLAYERS    		= 16384;
float 	FL_NO_MONSTERS    		= 32768;
float 	FL_NO_BOTS	    		= 65536;

float	IT_INVISIBILITY			= 524288;
float	IT_INVULNERABILITY		= 1048576;
float	IT_SUIT					= 2097152;
float	IT_QUAD					= 4194304;

const float MASK_CUSTOMVIEWMODEL = 4;

float show_score;
float score_display;
float shealth;

