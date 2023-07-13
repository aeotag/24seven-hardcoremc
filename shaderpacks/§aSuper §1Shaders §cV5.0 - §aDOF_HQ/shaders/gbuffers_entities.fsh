#version 120

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

const int GL_EXP = 2048;
const int GL_LINEAR = 9729;

varying vec4 color;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 normal;
uniform int entityHurt;

uniform sampler2D texture;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform int fogMode;
uniform int worldTime;
uniform float wetness;

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {	
	
	vec2 adjustedTexCoord = texcoord.st;
	vec3 lightVector;
	vec4 albedo = texture2D(texture,adjustedTexCoord)*color * vec4(1 + entityHurt * 0.1, 1.0, 1.0, 1.0);
	vec4 frag2 = vec4(normal*0.5+0.5, 1.0f);

	float dirtest = 0.4;
	
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	
	dirtest = 1.0-0.8*step(dot(frag2.xyz*2.0-1.0,lightVector),-0.02);
	
/* DRAWBUFFERS:024 */
	gl_FragData[0] = albedo;
	gl_FragData[1] = frag2;	
	gl_FragData[2] = vec4(lmcoord.t, dirtest, lmcoord.s, 1.0);
}