#version 120

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec3 normal;

uniform sampler2D texture;
uniform int fogMode;
uniform float rainStrength;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	vec4 tex = texture2D(texture, texcoord.st);
	
/* DRAWBUFFERS:04 */
	
	vec3 indlmap = texture2D(texture,texcoord.xy).rgb*color.rgb;
	
	gl_FragData[0] = vec4(indlmap,texture2D(texture,texcoord.xy).a*color.a);
	
	//x = specularity / y = land(0.0/1.0)/shadow early exit(0.2)/water(0.05) / z = torch lightmap
	
	gl_FragData[1] = vec4(lmcoord.t, 1.0, lmcoord.s, 1.0);
}