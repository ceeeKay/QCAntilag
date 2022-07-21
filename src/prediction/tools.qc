float DEG2RAD = 0.0174532925199432957692369076848861271344287188854172545609719144;
float RAD2DEG = 57.2957795130823208767981548141051703324054724665643215491602438612;
float PI      = 3.1415926535897932384626433832795028841971693993751058209749445923;

#define CSQC_ENABLED			1
#define CSQC_SHITTYENGINE		2 

#define CrossProduct(v1,v2,cross) \
        ((cross)[0]=(v1)[1]*(v2)[2]-(v1)[2]*(v2)[1], \
         (cross)[1]=(v1)[2]*(v2)[0]-(v1)[0]*(v2)[2], \
         (cross)[2]=(v1)[0]*(v2)[1]-(v1)[1]*(v2)[0])

#if defined(SSQC) || defined(CSQC)
typedef struct trace_t {
	float		allsolid;   // if true, plane is not valid
	float		startsolid; // if true, the initial point was in a solid area
	float		fraction;   // time completed, 1.0 = didn't hit anything
	vector		startpos;
	vector		endpos;     // final position
	vector		plane_normal;      // surface normal at impact
	float		plane_dist;
	float		contents;   // contents on other side of surface hit
	entity		ent;
	float		inopen;
	float		inwater;
	float		endcontents;
	float		surfaceflags;
	float		surface_id;
	float		bone_id;
};


float (float x, float y) angle_difference =
{
	local float a;
	a = x - y;
	a = (a + 180) % 360 - 180;
	if (a > 180) a -= 360;
	if (a < -180) a += 360;
	
	return a;
}


#endif