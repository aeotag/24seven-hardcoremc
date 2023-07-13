#version 120

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

#extension GL_ARB_shader_texture_lod : enable

/* DRAWBUFFERS:0246 */

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
uniform int isEyeInWater;

	//#define OLD_WATER_COLOR			//Enable this to return the water Colour back to V4.1
	
#ifdef OLD_WATER_COLOR
	vec4 watercolor = vec4(0.1f, 0.3f, 0.5f, 170.0f/255.0f); 	//water color and opacity (r,g,b,opacity)
#endif	
	#define Color_Red 0.2			//[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2]
	#define Color_Green 0.7			//[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2]
	#define Color_Blue 1.1			//[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 0.95 1.0 1.1 1.2]
	
	#define Transparency 110		//[50 70 85 100 110 120 130 140 150 160 170 180 190 200 210 220 230 240 250]

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES

const int MAX_OCCLUSION_POINTS = 20;
const float MAX_OCCLUSION_DISTANCE = 32.0;
const float bump_distance = 64.0;				//Bump render distance: tiny = 32, short = 64, normal = 128, far = 256
const float pom_distance = 32.0;				//POM render distance: tiny = 32, short = 64, normal = 128, far = 256
const float fademult = 1.0;
const float PI = 3.1415927;

varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;
varying float viewdistance;

uniform vec3 cameraPosition;
uniform vec3 upPosition;

uniform sampler2D texture;
uniform sampler2D noisetex;
uniform int worldTime;
uniform float rainStrength;
uniform float frameTimeCounter;

	float timefract = worldTime;

	float TimeSunrise  = ((clamp(timefract, 23000.0f, 25000.0f) - 23000.0f) / 1000.0f) + (1.0f - (clamp(timefract, 0.0f, 2000.0f)/2000.0f));
	float TimeNoon     = ((clamp(timefract, 0.0f, 2000.0f)) / 2000.0f) - ((clamp(timefract, 9000.0f, 12000.0f) - 9000.0f) / 3000.0f);
	float TimeSunset   = ((clamp(timefract, 9000.0f, 12000.0f) - 9000.0f) / 3000.0f) - ((clamp(timefract, 12000.0f, 12750.0f) - 12000.0f) / 750.0f);
	float TimeMidnight = ((clamp(timefract, 12000.0f, 12750.0f) - 12000.0f) / 750.0f) - ((clamp(timefract, 23000.0f, 24000.0f) - 23000.0f) / 1000.0f);

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

float waterH(vec2 posxz) {

vec2 movement = vec2(abs(frameTimeCounter/2000.-0.5),-abs(frameTimeCounter/2000.-0.5));
vec2 movement2 = vec2(abs(frameTimeCounter/2000.-0.5),abs(frameTimeCounter/2000.-0.5));
vec2 movement3 = vec2(-abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5));
vec2 movement4 = vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5));

vec2 coord = (posxz/600)+(movement);
vec2 coord1 = (posxz/599.9)+(movement2);
vec2 coord2 = (posxz/599.8)+(movement3);
vec2 coord3 = (posxz/599.7)+(movement4);

float noise = texture2D(noisetex,fract(coord.xy/4.0)).x/2.0;
noise += texture2D(noisetex,fract(coord1.xy)).x/2.0;
noise += texture2D(noisetex,fract(coord2.xy*2.0)).x/4.0;
noise += texture2D(noisetex,fract(coord3.xy*4.0)).x/8.0;

return noise;
}

vec3 stokes(in float ka, in vec3 k, in vec3 g) {
    // ka = wave steepness, k = displacements, g = gradients / wave number
    float theta = k.x + k.z + k.t;
    float s = ka * (sin(theta) + ka * sin(2.0f * theta));
    return vec3(s * g.x, s * g.z, g.t);  // (-deta/dx, -deta/dz, scale)
}

vec3 waves1() {
    float scale = 8.0f / (viewdistance * viewdistance);
    vec3 gg = vec3(scale, 3600.0f, scale);
    vec3 gk = vec3(viewdistance * 6.0f, frameTimeCounter * -6.0f, 0.0f);
    vec3 gwave = stokes(10.0f, gk, gg);
    return normalize(gwave);
}

float smoothStep(in float edge0, in float edge1, in float x) {
    float t = clamp((x - edge0) / (edge1 - edge0), 0.0f, 1.0f);
    return t * t * (3.0f - 2.0f * t);
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
#ifdef OLD_WATER_COLOR
	vec4 tex = vec4((watercolor*length(texture2D(texture, texcoord.xy).rgb*color.rgb)*color).rgb,watercolor.a);
#else

	vec4 tex = texture2D(texture, texcoord.st);
	
	bool backfacing = false;
	if (viewVector.z > 0.0f) {
		backfacing = true;
	} else {
		backfacing = false;
	}
if (iswater > 0.5f && !backfacing) {
	vec4 albedo = texture2D(texture, texcoord.st).rgba;
		float lum = albedo.r + albedo.g + albedo.b;
			  lum /= 3.0f;

			  lum = pow(lum, 1.5f) * 1.5f;
			  lum += 0.0f;
	
	vec3 waterColor = color.rgb;

		waterColor = normalize(waterColor);

	
	tex = vec4(Color_Red, Color_Green, Color_Blue, Transparency/255.0f);
	tex.rgb *= 1.0f * waterColor.rgb;
		tex.rgb *= vec3(lum);
		
		} else if (iswater > 0.5f && backfacing) {
		tex = vec4(0.0, 0.0, 0.0f, 30.0f / 255.0f);
	}
#endif	
	vec3 posxz = wpos.xyz;

	float deltaPos = 0.1;
	float h0 = waterH(posxz.xz);
	float h1 = waterH(posxz.xz + vec2(deltaPos,0.0));
	float h2 = waterH(posxz.xz + vec2(-deltaPos,0.0));
	float h3 = waterH(posxz.xz + vec2(0.0,deltaPos));
	float h4 = waterH(posxz.xz + vec2(0.0,-deltaPos));

	float xDelta = (h1-h0)+(h0-h2);
	float yDelta = (h3-h0)+(h0-h4);

	vec3 newnormal = normalize(vec3(xDelta,yDelta,1.0-pow(abs(xDelta+yDelta),2.0)));

	vec4 frag2;
		frag2 = vec4((normal) * 0.5f + 0.5f, 1.0f);
	vec4 frag3;
		frag3 = vec4((normal) * 0.5f + 0.5f, 1.0f);

		
	if (iswater > 0.9) {
		vec3 bump = newnormal;
			bump = bump;


		float bumpmult = 0.3;
			  bumpmult += 0.51 * rainStrength;

		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);

		frag2 = vec4(normalize(bump * tbnMatrix) * 0.5 + 0.5, 1.0);
		frag3 = vec4(normalize(waves1() * tbnMatrix) * 0.5 + 0.5, 1.0);
	}
	gl_FragData[0] = tex;
	gl_FragData[1] = mix(frag2, frag3, smoothStep(3.0f, 1.0f, viewdistance));
	gl_FragData[2] = vec4(lmcoord.t, mix(1.0,0.05,iswater), lmcoord.s, 1.0);
}
