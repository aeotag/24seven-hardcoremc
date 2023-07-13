#version 120

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define WAVING_WATER

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



varying vec4 color;
varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 position;
varying vec4 bloommask;
varying vec3 binormal;
varying vec3 normal;
varying vec3 tangent;
varying vec3 viewVector;
varying vec3 wpos;
varying float iswater;
varying float viewdistance;

attribute vec4 mc_Entity;

uniform vec3 cameraPosition;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform int isEyeInWater;
uniform float frameTimeCounter;
uniform float rainStrength;
float timefract = worldTime;

const float PI = 3.1415927;

//Raining
float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////
//////////////////////////////main//////////////////////////////

void main() {
	
	
	position = gl_ModelViewMatrix * gl_Vertex;
	iswater = 0.0f;
	float displacement = 0.0;
	
	/* un-rotate */
	vec4 viewpos = gbufferModelViewInverse * position;

	vec3 worldpos = viewpos.xyz + cameraPosition;
	wpos = worldpos;
	
	vec4 viewVertex = gbufferModelView * viewpos; //Re-rotate
    viewdistance = gl_FogFragCoord = length(viewVertex);
	
	
	if (mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
		iswater = 1.0;
		float speed = 1.0;
		
		
        float magnitude = (sin((worldTime * PI / ((28.0) * speed))) * 0.05 + 0.15) * 0.4;
        float d0 = sin(worldTime * PI / (122.0 * speed)) * 3.0 - 1.5;
        float d1 = sin(worldTime * PI / (142.0 * speed)) * 3.0 - 1.5;
        float d2 = sin(worldTime * PI / (162.0 * speed)) * 3.0 - 1.5;
        float d3 = sin(worldTime * PI / (112.0 * speed)) * 3.0 - 1.5;
		displacement = sin((worldTime * PI / (15.0 * speed)) + (position.z + d2) + (position.x + d3)) * magnitude;
        position.y += displacement;
		
					for(int i = 1; i < 3; ++i){
		
			float octave = i * 1.0;
			float speed = (octave) * 3.0;
			
			float magnitude = (sin((position.y * octave + position.x * octave + worldTime * octave * PI / ((28.0) * speed))) * 0.15 + 0.15) * 0.2;
			float d0 = sin(position.y * octave * 3.0 + position.x * octave * 0.3 + worldTime * PI / (112.0 * speed)) * 3.0 - 1.5;
			float d1 = sin(position.y * octave * 0.7 - position.x * octave * 10.0 + worldTime * PI / (142.0 * speed)) * 3.0 - 1.5;
			float d2 = sin(worldTime * PI / (132.0 * speed)) * 3.0 - 1.5;
			float d3 = sin(worldTime * PI / (122.0 * speed)) * 3.0 - 1.5;
			displacement += sin((worldTime * PI / (11.0 * speed)) + (position.z * octave + d2) + (position.x * octave + d3)) * (magnitude/2.0);
			displacement -= sin((worldTime * PI / (11.0 * speed)) + (position.z * octave * 0.5 + d1) + (position.x * octave * 2.0 + d0)) * (magnitude/2.0);
			position.y += displacement;
		}
	}
	

#ifdef WAVING_WATER
	if(mc_Entity.x == 8.0 || mc_Entity.x == 9.0) {
	
		iswater = 1.0;
		float fy = fract(worldpos.y + 0.001);
		
	    if (fy > 0.02) {

			float wave = 0.025 *  sin(2 * PI * (frameTimeCounter*0.5 + worldpos.x /  11.0 + worldpos.z / 5.0))
		               + 0.0 +rainx*+0.05 +0.05 * sin(2 * PI * (frameTimeCounter*0.45 + worldpos.x / 11.0 + worldpos.z /  5.0));	
			displacement = clamp(wave, -fy, 1.0-fy);
			viewpos.y += displacement;
		}
		
	}
#endif

	/* re-rotate */
	viewpos = gbufferModelView * viewpos;

	/* projectify */
	gl_Position = gl_ProjectionMatrix * viewpos;
	
	color = gl_Color;
	
	texcoord = gl_TextureMatrix[0] * gl_MultiTexCoord0;

	lmcoord = gl_TextureMatrix[1] * gl_MultiTexCoord1;
	
	gl_FogFragCoord = gl_Position.z;
	
	tangent = vec3(1.0);
	binormal = vec3(1.0);
	normal = normalize(gl_NormalMatrix * normalize(gl_Normal));

	if (gl_Normal.x > 0.5) {
		//  2.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0, -1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.x < -0.5) {
		// -1.0,  0.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.y > 0.5) {
		//  0.0,  1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.y < -0.5) {
		//  0.0, -1.0,  0.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0,  0.0,  1.0));
	}
	
	else if (gl_Normal.z > 0.5) {
		//  0.0,  0.0,  1.0
		tangent  = normalize(gl_NormalMatrix * vec3( 1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	else if (gl_Normal.z < -0.5) {
		//  0.0,  0.0, -1.0
		tangent  = normalize(gl_NormalMatrix * vec3(-1.0,  0.0,  0.0));
		binormal = normalize(gl_NormalMatrix * vec3( 0.0, -1.0,  0.0));
	}
	
	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
							tangent.y, binormal.y, normal.y,
							tangent.z, binormal.z, normal.z);
	
		vec3 newnormal = vec3(sin(displacement*PI),1.0-cos(displacement*PI),displacement);
	
			vec3 bump = newnormal;
			bump = bump;
		
		float bumpmult = 0.05;
		
		bump = bump * vec3(bumpmult, bumpmult, bumpmult) + vec3(0.0f, 0.0f, 1.0f - bumpmult);
		
		normal = bump * tbnMatrix;
		
	viewVector = (gl_ModelViewMatrix * gl_Vertex).xyz;
	viewVector = normalize(tbnMatrix * viewVector);
	
	
}