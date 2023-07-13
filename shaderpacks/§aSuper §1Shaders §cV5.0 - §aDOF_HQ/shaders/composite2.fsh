#version 120


/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//disabling is done by adding "//" to the beginning of a line.

//ADJUSTABLE VARIABLES//





//----------Details----------//
	#define Post_Bloom									
//----------End of Details----------//




const bool gaux2MipmapEnabled = true;

//ADJUSTABLE VARIABLES//

/*--------------------------------*/
varying vec4 texcoord;
uniform sampler2D gaux2;
uniform sampler2D gcolor;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
/*--------------------------------*/

const vec2 offsets[49] = vec2[49]  (vec2(-3,-3),vec2(-2,-3),vec2(-1,-3),vec2( 0,-3),vec2( 1,-3),vec2( 2,-3),vec2( 3,-3),
									vec2(-3,-2),vec2(-2,-2),vec2(-1,-2),vec2( 0,-2),vec2( 1,-2),vec2( 2,-2),vec2( 3,-2),
									vec2(-3,-1),vec2(-2,-1),vec2(-1,-1),vec2( 0,-1),vec2( 1,-1),vec2( 2,-1),vec2( 3,-1),
									vec2(-3, 0),vec2(-2, 0),vec2(-1, 0),vec2( 0, 0),vec2( 1, 0),vec2( 2, 0),vec2( 3, 0),
									vec2(-3, 1),vec2(-2, 1),vec2(-1, 1),vec2( 0, 1),vec2( 1, 1),vec2( 2, 1),vec2( 3, 1),
									vec2(-3, 2),vec2(-2, 2),vec2(-1, 2),vec2( 0, 2),vec2( 1, 2),vec2( 2, 2),vec2( 3, 2),
									vec2(-3, 3),vec2(-2, 3),vec2(-1, 3),vec2( 0, 3),vec2( 1, 3),vec2( 2, 3),vec2( 3, 3)
									);

const float weight[49] = float[49] (18,13,10, 9,10,13,18,
									13, 8, 5, 4, 5, 8,13,
									10, 5, 2, 1, 2, 5,10,
									 9, 4, 1, 0, 1, 4, 9,
									10, 5, 2, 1, 2, 5,10,
									13, 8, 5, 4, 5, 8,13,
									18,13,10, 9,10,13,18
									);

vec3 makeBloom(float lod,vec2 offset){
vec3 bloom = vec3(0);
float scale = pow(2,lod);
vec2 coord = (texcoord.xy-offset)*scale;

if (coord.x > -0.1 && coord.y > -0.1 && coord.x < 1.1 && coord.y < 1.1){
for (int i = 0; i < 49; i++) {
	float wg = exp(3-length(offsets[i]));
	vec2 bcoord = (texcoord.xy-offset+offsets[i]*pw*vec2(1.0,aspectRatio))*scale;
	if (wg > 0) bloom += pow(texture2D(gaux2,bcoord).rgb,vec3(2.2))*wg;
	}
}
bloom /= 26;
return bloom;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
vec3 blur = vec3(0);
	#ifdef Post_Bloom
	 blur += makeBloom(2,vec2(0,0));
	 blur += makeBloom(3,vec2(0.3,0));
	 blur += makeBloom(4,vec2(0,0.3));
	 blur += makeBloom(5,vec2(0.1,0.3));
	 blur += makeBloom(6,vec2(0.2,0.3));
	 blur += makeBloom(7,vec2(0.3,0.3));
	#endif
blur = clamp(pow(blur,vec3(1.0/2.2)),0.0,1.0);
/* DRAWBUFFERS:3 */
	gl_FragData[0] = vec4(blur,1.0);
}
