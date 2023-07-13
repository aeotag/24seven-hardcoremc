#version 120
#define MAX_COLOR_RANGE 48.0
const bool gdepthMipmapEnabled = true;

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

#define desaturation 0.0		// Color_desaturation. 0.0 = full color. 1.0 = Black & White [0.0 0.25 0.50 0.75 1.0]

//#define OldColor_Tonemap			//Returns the Tonemap Colours Back to V4.1		

//#define CHOCS_LENS_FLARE			//Lens Flare from Chocapics shaders

#define LENS_FLARE							
		#define LENS_POWER 1.0					//lens effect intensity	
	
#define KUDA_LENS						//sun star lens

	#define Post_Bloom					//Adds Bloom to everything					

#define CALCULATE_EXPOSURE	


//#define DISTANT_BLUR					//Blurs objects in the distance // Cant use HQ_DOF or DOF_LQ at the same time 

#define HQ_DOF							//High Quality DOF that uses centerDepthSmooth to have smooth focus transition //Cant use DISTANT_BLUR or DOF_LQ at the same time 
					
//#define DOF_LQ						//This is a Low Quality Depth Of Field version that doesnt use centerDepthSmooth to smooth focus transition //Cant use DISTANT_BLUR or HQ_DOF at the same time 
	//lens properties
const float focal = 0.024;
float aperture = 0.0019;	
const float sizemult = 100.0;		
			
			#define RAIN_LENS			//Adds colour Blue to rain drops on screen

	#define RAIN_DROPS					//Rain Drops on the players lens
	
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES



varying vec4 texcoord;

varying vec3 lightVector;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying float sunVisibility;

uniform sampler2D depthtex0;
uniform sampler2D depthtex2;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux4;
uniform sampler2D gnormal;
uniform sampler2D composite;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 sunPosition;
uniform vec3 moonPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;

uniform int isEyeInWater;
uniform int worldTime;

uniform float aspectRatio;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;

uniform float centerDepthSmooth;


uniform vec3 upPosition;
vec3 sunPos = sunPosition;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float timefract = worldTime;

//Raining
float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
float wetx  = clamp(wetness, 0.0f, 1.0f);

//Calculate Time of Day
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

float matflag = texture2D(gaux1,texcoord.xy).g;
float sky_lightmap = texture2D(gaux1,texcoord.xy).r;
int land = int(matflag < 0.03);
vec3 aux = texture2D(gaux1, texcoord.xy).rgb;
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;
float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));

vec3 calcExposure(vec3 color) {
         float maxx = 1;
         float minx = 0.5;

         float exposure = max(pow(aux.r + aux.g*iswet * 1, -0.4), 0.0)*maxx + minx;

         color.rgb /= vec3(exposure);

         return color.rgb;
}

// Standard depth function.
float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

#ifdef DOF_LQ

//hexagon pattern
const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
									vec2(  0.0000,  0.2500 ),
									vec2( -0.2165,  0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2(  0.2165, -0.1250 ),
									vec2(  0.4330,  0.2500 ),
									vec2(  0.0000,  0.5000 ),
									vec2( -0.4330,  0.2500 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.0000, -0.5000 ),
									vec2(  0.4330, -0.2500 ),
									vec2(  0.6495,  0.3750 ),
									vec2(  0.0000,  0.7500 ),
									vec2( -0.6495,  0.3750 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.0000, -0.7500 ),
									vec2(  0.6495, -0.3750 ),
									vec2(  0.8660,  0.5000 ),
									vec2(  0.0000,  1.0000 ),
									vec2( -0.8660,  0.5000 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.0000, -1.0000 ),
									vec2(  0.8660, -0.5000 ),
									vec2(  0.2163,  0.3754 ),
									vec2( -0.2170,  0.3750 ),
									vec2( -0.4333, -0.0004 ),
									vec2( -0.2163, -0.3754 ),
									vec2(  0.2170, -0.3750 ),
									vec2(  0.4333,  0.0004 ),
									vec2(  0.4328,  0.5004 ),
									vec2( -0.2170,  0.6250 ),
									vec2( -0.6498,  0.1246 ),
									vec2( -0.4328, -0.5004 ),
									vec2(  0.2170, -0.6250 ),
									vec2(  0.6498, -0.1246 ),
									vec2(  0.6493,  0.6254 ),
									vec2( -0.2170,  0.8750 ),
									vec2( -0.8663,  0.2496 ),
									vec2( -0.6493, -0.6254 ),
									vec2(  0.2170, -0.8750 ),
									vec2(  0.8663, -0.2496 ),
									vec2(  0.2160,  0.6259 ),
									vec2( -0.4340,  0.5000 ),
									vec2( -0.6500, -0.1259 ),
									vec2( -0.2160, -0.6259 ),
									vec2(  0.4340, -0.5000 ),
									vec2(  0.6500,  0.1259 ),
									vec2(  0.4325,  0.7509 ),
									vec2( -0.4340,  0.7500 ),
									vec2( -0.8665, -0.0009 ),
									vec2( -0.4325, -0.7509 ),
									vec2(  0.4340, -0.7500 ),
									vec2(  0.8665,  0.0009 ),
									vec2(  0.2158,  0.8763 ),
									vec2( -0.6510,  0.6250 ),
									vec2( -0.8668, -0.2513 ),
									vec2( -0.2158, -0.8763 ),
									vec2(  0.6510, -0.6250 ),
									vec2(  0.8668,  0.2513 ));

#endif

#ifdef HQ_DOF
	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));
											
	#endif

const vec2 offsets[60] = vec2[60]  (  vec2( 0.0000, 0.2500 ),
									vec2( -0.2165, 0.1250 ),
									vec2( -0.2165, -0.1250 ),
									vec2( -0.0000, -0.2500 ),
									vec2( 0.2165, -0.1250 ),
									vec2( 0.2165, 0.1250 ),
									vec2( 0.0000, 0.5000 ),
									vec2( -0.2500, 0.4330 ),
									vec2( -0.4330, 0.2500 ),
									vec2( -0.5000, 0.0000 ),
									vec2( -0.4330, -0.2500 ),
									vec2( -0.2500, -0.4330 ),
									vec2( -0.0000, -0.5000 ),
									vec2( 0.2500, -0.4330 ),
									vec2( 0.4330, -0.2500 ),
									vec2( 0.5000, -0.0000 ),
									vec2( 0.4330, 0.2500 ),
									vec2( 0.2500, 0.4330 ),
									vec2( 0.0000, 0.7500 ),
									vec2( -0.2565, 0.7048 ),
									vec2( -0.4821, 0.5745 ),
									vec2( -0.6495, 0.3750 ),
									vec2( -0.7386, 0.1302 ),
									vec2( -0.7386, -0.1302 ),
									vec2( -0.6495, -0.3750 ),
									vec2( -0.4821, -0.5745 ),
									vec2( -0.2565, -0.7048 ),
									vec2( -0.0000, -0.7500 ),
									vec2( 0.2565, -0.7048 ),
									vec2( 0.4821, -0.5745 ),
									vec2( 0.6495, -0.3750 ),
									vec2( 0.7386, -0.1302 ),
									vec2( 0.7386, 0.1302 ),
									vec2( 0.6495, 0.3750 ),
									vec2( 0.4821, 0.5745 ),
									vec2( 0.2565, 0.7048 ),
									vec2( 0.0000, 1.0000 ),
									vec2( -0.2588, 0.9659 ),
									vec2( -0.5000, 0.8660 ),
									vec2( -0.7071, 0.7071 ),
									vec2( -0.8660, 0.5000 ),
									vec2( -0.9659, 0.2588 ),
									vec2( -1.0000, 0.0000 ),
									vec2( -0.9659, -0.2588 ),
									vec2( -0.8660, -0.5000 ),
									vec2( -0.7071, -0.7071 ),
									vec2( -0.5000, -0.8660 ),
									vec2( -0.2588, -0.9659 ),
									vec2( -0.0000, -1.0000 ),
									vec2( 0.2588, -0.9659 ),
									vec2( 0.5000, -0.8660 ),
									vec2( 0.7071, -0.7071 ),
									vec2( 0.8660, -0.5000 ),
									vec2( 0.9659, -0.2588 ),
									vec2( 1.0000, -0.0000 ),
									vec2( 0.9659, 0.2588 ),
									vec2( 0.8660, 0.5000 ),
									vec2( 0.7071, 0.7071 ),
									vec2( 0.5000, 0.8660 ),
									vec2( 0.2588, 0.9659 ));

float A = 0.355;
float B = 0.37;
float C = 0.1;
float D = 0.2;
float E = 0.02;
float F = 0.3;
float W = MAX_COLOR_RANGE;

vec3 Uncharted2Tonemap(vec3 x) {
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

float distratio(vec2 pos, vec2 pos2) {
	float xvect = pos.x*aspectRatio-pos2.x*aspectRatio;
	float yvect = pos.y-pos2.y;
	return sqrt(xvect*xvect + yvect*yvect);
}
	
float distratio_2(vec2 pos, vec2 pos2, float ratio) {
		float xvect = pos.x*ratio-pos2.x*ratio;
		float yvect = pos.y-pos2.y;
		return sqrt(xvect*xvect + yvect*yvect);
	}	
	
//circle position pattern (vec2 coordinate, size)
	const vec3 pattern[16] = vec3[16](	vec3(0.1,0.1,0.02),
										vec3(-0.12,0.07,0.02),
										vec3(-0.11,-0.13,0.02),
										vec3(0.1,-0.1,0.02),
									
										vec3(0.07,0.15,0.02),
										vec3(-0.08,0.17,0.02),
										vec3(-0.14,-0.07,0.02),
										vec3(0.15,-0.19,0.02),
									
										vec3(0.012,0.15,0.02),
										vec3(-0.08,0.17,0.02),
										vec3(-0.14,-0.07,0.02),
										vec3(0.02,-0.17,0.021),
									
										vec3(0.10,0.05,0.02),
										vec3(-0.13,0.09,0.02),
										vec3(-0.05,-0.1,0.02),
										vec3(0.1,0.01,0.02)
									);	
	
float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy)/size;
	return exp(-dist*dist);
}

float yDistAxis (in float degrees) {
	
		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z;
			 lightPos = (lightPos + 1.0f)/2.0f;
			 
		return abs((lightPos.y-lightPos.x*(degrees))-(texcoord.y-texcoord.x*(degrees)));
		
	}
	
float smoothCircleDist (in float lensDist) {

		vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
			 tpos = vec4(tpos.xyz/tpos.w,1.0);
		vec2 lightPos = tpos.xy/tpos.z*lensDist;
			 lightPos = (lightPos + 1.0f)/2.0f;
			 
		return distratio_2(lightPos.xy, texcoord.xy, aspectRatio);
		
	}
	
vec2 noisepattern(vec2 pos) {
	return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
}
float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}
float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}



	float dynamicTonemapping(float dTDayValue, float dTNightValue) {
	
		float dTDay = dTDayValue * (TimeSunrise + TimeNoon + TimeSunset);
		float dTNight = dTNightValue * TimeMidnight;
			
		float dTBrightness = dTDay + dTNight;
			  
		return (pow(eyeBrightnessSmooth.y / 255.0, 6.0f) * 1.0 + dTBrightness);
	
	}



//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

		const float pi = 3.14159265359;
		vec3 fogclr = mix(gl_Fog.color.rgb,vec3(0.25,0.25,0.25),rainStrength)*vec3(0.7,0.7,1.0);
		float rainlens = 0.0;
		const float lifetime = 4.0;		//water drop lifetime in seconds
		float ftime = frameTimeCounter*2.0/lifetime;  
		vec2 drop = vec2(0.0,fract(frameTimeCounter/10.0));   

	
#ifdef RAIN_DROPS
		float gen = 1.0-fract((ftime+0.5)*0.5);
		vec2 pos = (noisepattern(vec2(-0.94386347*floor(ftime*0.5+0.25),floor(ftime*0.5+0.25))))*0.8+0.1 - drop;
		rainlens += gen_circular_lens(fract(pos),0.09)*gen*rainStrength;

		gen = 1.0-fract((ftime+0.5)*0.5);
		pos = (noisepattern(vec2(0.9347*floor(ftime*0.5+0.5),-0.2533282*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.09)*gen*rainStrength;

		gen = 1.0-fract((ftime+0.5)*0.5);
		pos = (noisepattern(vec2(0.785282*floor(ftime*0.5+0.75),-0.285282*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.09)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.347*floor(ftime*0.5),0.6847*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.09)*gen*rainStrength;
		
		gen = 1.0-fract((ftime+0.5)*0.5);
		pos = (noisepattern(vec2(0.8514*floor(ftime*0.5+0.5),-0.456874*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.090)*gen*rainStrength;

		gen = 1.0-fract((ftime+0.5)*0.5);
		pos = (noisepattern(vec2(0.845156*floor(ftime*0.5+0.75),-0.2457854*floor(ftime*0.5+0.75))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.093)*gen*rainStrength;

		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.368*floor(ftime*0.5),0.8654*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.09)*gen*rainStrength*5;
		
		gen =  1.0-fract(ftime*0.5);
		pos = (noisepattern(vec2(-0.458*floor(ftime*0.5),0.7546*floor(ftime*0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.095)*gen*rainStrength*5;
		
		gen = 1.0-fract((ftime+0.5)*0.5);
		pos = (noisepattern(vec2(0.7532*floor(ftime*0.5+0.5),-0.54275*floor(ftime*0.5+0.5))))*0.8+0.1- drop;
		rainlens += gen_circular_lens(fract(pos),0.099)*gen*rainStrength*5;
	
		rainlens *= clamp((eyeBrightness.y-220)/15.0,0.0,1.0);
	
#endif
	vec2 fake_refract = vec2(sin(frameTimeCounter*2.0 + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter*2.0 + texcoord.y*100.0 + texcoord.x*50.0))* isEyeInWater;
	vec2 Fake_Refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;

	vec2 newTC = texcoord.st + fake_refract * 0.01 * (rainlens);
	vec2 New_tc = texcoord.st + Fake_Refract * 0.01 * (rainlens);

	vec3 color = pow(texture2D(gaux2, newTC + fake_refract * 0.0035).rgb,vec3(2.2))*MAX_COLOR_RANGE/2;
		 color += pow(texture2D(gaux2, New_tc).rgb,vec3(2.2))*MAX_COLOR_RANGE/2;
	
	float fog = 1-(exp(-pow(ld(texture2D(depthtex0, newTC.st).r)/256.0*far,4.0-(2.7*rainStrength))*4.0));
		fog = mix(fog,1-exp(-ld(texture2D(depthtex0, newTC.st).r)*far/256.),isEyeInWater);

#ifdef DISTANT_BLUR
if (rainStrength > 0.35) {
	
	} else {
	float z_DB = ld(texture2D(depthtex0, newTC.st).r)*far;
	float focus_DB = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc_DB = min(abs(aperture * (focal * (z_DB - focus_DB)) / (z_DB * (focus_DB - focal)))*sizemult,pw*15.0);
		  pcoc_DB = min(fog*pw*10.0,pw*10.0);
	
	vec4 sample = vec4(0.0);
	vec3 bcolor_DB = color/MAX_COLOR_RANGE;
	float nb_DB = 0.0;
	vec2 bcoord_DB = vec2(0.0);
	
		for ( int i = 0; i < 60; i++) {
			bcolor_DB += pow(texture2D(gaux2, newTC.xy + offsets[i]*pcoc_DB*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		}
		
	color.rgb = bcolor_DB/61.0*MAX_COLOR_RANGE;
}	
#endif

#ifdef DOF_LQ

	//Calculate pixel Circle of Confusion that will be used for bokeh depth of field
	float z = ld(texture2D(depthtex2, texcoord.st).r)*far;
	float focus = ld(texture2D(depthtex2, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*10.0);		
	
	
	vec3 bcolor = color/MAX_COLOR_RANGE;
	float nb = 0.0;
	vec2 bcoord = vec2(0.0);

	for ( int i = 0; i < 60; i++) {
		bcolor += pow(texture2D(gaux2, texcoord.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
		
	}
	
	color.rgb = bcolor/61.0*MAX_COLOR_RANGE;

#endif

#ifdef HQ_DOF
	float depth = texture2D(depthtex2, texcoord.st).x;

    float depth_fading = centerDepthSmooth;
    float focus = (depth - depth_fading) / 15;	
	
	vec3 bcolor = color/MAX_COLOR_RANGE;
	
	for ( int i = 0; i < 60; i++) {
			bcolor += pow(texture2D(gaux2, newTC.xy + hex_offsets[i]*focus*vec2(1.0,aspectRatio)).rgb,vec3(2.2));
			
		}
		color.rgb = bcolor/61.0*MAX_COLOR_RANGE;
#endif	
	
#ifdef Post_Bloom

vec3 blur = vec3(0);
vec3 blurNight = vec3(0);
vec2 bloomcoord = texcoord.xy;

	blur += pow(texture2D(composite,bloomcoord/pow(2.0,2.0) + vec2(0.0,0.0)).rgb,vec3(2.2))*pow(6.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,3.0) + vec2(0.3,0.0)).rgb,vec3(2.2))*pow(5.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,4.0) + vec2(0.0,0.3)).rgb,vec3(2.2))*pow(4.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,5.0) + vec2(0.1,0.3)).rgb,vec3(2.2))*pow(3.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,6.0) + vec2(0.2,0.3)).rgb,vec3(2.2))*pow(2.0,0.25);
	blur += pow(texture2D(composite,bloomcoord/pow(2.0,7.0) + vec2(0.3,0.3)).rgb,vec3(2.2))*pow(1.0,0.25);
	//blur = pow(texture2D(composite,bloomcoord/2).rgb,vec3(2.2));

	vec3 blur1 = pow(texture2D(composite,bloomcoord/pow(2.0,2.0) + vec2(0.0,0.0)).rgb,vec3(2.2))*pow(7.0,1.0);
	vec3 blur2 = pow(texture2D(composite,bloomcoord/pow(2.0,3.0) + vec2(0.3,0.0)).rgb,vec3(2.2))*pow(6.0,1.0);
	vec3 blur3 = pow(texture2D(composite,bloomcoord/pow(2.0,4.0) + vec2(0.0,0.3)).rgb,vec3(2.2))*pow(5.0,1.0);
	vec3 blur4 = pow(texture2D(composite,bloomcoord/pow(2.0,5.0) + vec2(0.1,0.3)).rgb,vec3(2.2))*pow(4.0,1.0);
	vec3 blur5 = pow(texture2D(composite,bloomcoord/pow(2.0,6.0) + vec2(0.2,0.3)).rgb,vec3(2.2))*pow(3.0,1.0);
	vec3 blur6 = pow(texture2D(composite,bloomcoord/pow(2.0,7.0) + vec2(0.3,0.3)).rgb,vec3(2.2))*pow(2.0,1.0);
	blurNight = blur1 + blur2 + blur3 + blur4 + blur5 + blur6;
	
color.xyz = mix(color,blur * 0.3 * MAX_COLOR_RANGE, 0.008);
color.xyz += blur*0.01*(1+35*pow(rainStrength,3.))*rainStrength;
color.rgb += mix(color,blurNight*MAX_COLOR_RANGE,0.003)*TimeMidnight;
//color = blur*MAX_COLOR_RANGE*0.006;
//color = vec3(pow(length(blur),0.5));
#endif 


	vec4 rain = pow(texture2D(gaux4,newTC.xy),vec4(vec3(2.2),1.));
	color.rgb = ((rain.rgb*rain.a + color) - (rain.rgb * rain.a * color));
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 lightPos = tpos.xy/tpos.z;
		lightPos = (lightPos + 1.0f)/2.0f;
		
		vec3 lightVector;
		
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(moonPosition);
	}
	

	float xdist = abs(lightPos.x-newTC.x);
	float ydist = abs(lightPos.y-newTC.y);
	
	float xydist = distance(lightPos.xy,newTC.xy);
	float xydistratio = distratio(lightPos.xy,newTC.xy);
	
	float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/300.0,0.0,1.0) + clamp((time-22800.0)/200.0,0.0,1.0)-clamp((time-23400.0)/200.0,0.0,1.0));
	float sunvisibility = min(texture2D(gaux2,vec2(0.0)).a,1.0) * (1.0-rainStrength*0.9) * transition_fading;
	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);
	
	float centerdist = clamp(1.0 - pow(cdist(lightPos), 0.2), 0.0, 1.0);
	float sizemult = 1.0 + centerdist;

	float circles_lens = 0.0;
	vec3 light_color = mix(moonlight,sunlight,sunVisibility);

#ifdef RAIN_LENS	
	//rain drops on screen
		color += fogclr*rainlens*vec3(0.25,0.3,0.4)*length(ambient_color);
#endif
	
#ifdef LENS_FLARE

if (isEyeInWater > 0.9) {
	
	} else {

vec3 sP = sunPosition;

	float fading = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

			vec2 lPos = sP.xy / -sP.z;
			lPos.x *= 1.0f/aspectRatio;
			lPos.xy *= 1.40f;						
			lPos = (lPos + 1.0f)/2.0f;
			if (fading > 0.01 && TimeMidnight < 1.0) {

			
			float sunmask = 0.0f;
			float sunstep = -4.5f;
			float masksize = 0.004f;
					

sunmask = texture2D(gaux2,vec2(0.0)).a;
					sunmask *= LENS_POWER * (1.0f - TimeMidnight)*fading;
					sunmask *= 1.0 - rainx;
			if (sunmask > 0.02) {
			//Detect if sun is on edge of screen
				float edgemaskx = clamp(distance(lPos.x, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
				float edgemasky = clamp(distance(lPos.y, 0.5f)*8.0f - 3.0f, 0.0f, 1.0f);
			
						
						
			////Darken colors if the sun is visible
				float centermask = 1.0 - clamp(distance(lPos.xy, vec2(0.5f, 0.5f))*2.0, 0.0, 1.0);
						centermask = pow(centermask, 1.0f);
						centermask *= sunmask;
			
				color *= (1.0 - centermask * (1.0f - TimeMidnight));
			
			
			//Adjust global flare settings
				const float flaremultR = 0.8f;
				const float flaremultG = 1.0f;
				const float flaremultB = 1.5f;
			
				float flarescale = 1.0f;
				const float flarescaleconst = 1.0f;
			
			
			//Flare gets bigger at center of screen
			
				flarescale *= (1.0 - centermask);
			
			
			//Center white flare
			vec2 flare1scale = vec2(1.7f*flarescale, 1.7f*flarescale);
			float flare1pow = 12.0f;
			vec2 flare1pos = vec2(lPos.x*aspectRatio*flare1scale.x, lPos.y*flare1scale.y);
			
			
			float flare1 = distance(flare1pos, vec2(texcoord.s*aspectRatio*flare1scale.x, texcoord.t*flare1scale.y));
				  flare1 = 0.5 - flare1;
				  flare1 = clamp(flare1, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare1 *= sunmask;
				  flare1 = pow(flare1, 1.8f);
				  
				  flare1 *= flare1pow;
				  
				  	color.r += flare1*0.7f*flaremultR;
					color.g += flare1*0.4f*flaremultG;
					color.b += flare1*0.2f*flaremultB;	
				  			
							
							
			//Center white flare
			  vec2 flare1Bscale = vec2(0.5f*flarescale, 0.5f*flarescale);
			  float flare1Bpow = 6.0f;
			vec2 flare1Bpos = vec2(lPos.x*aspectRatio*flare1Bscale.x, lPos.y*flare1Bscale.y);
			
			
			float flare1B = distance(flare1Bpos, vec2(texcoord.s*aspectRatio*flare1Bscale.x, texcoord.t*flare1Bscale.y));
				  flare1B = 0.5 - flare1B;
				  flare1B = clamp(flare1B, 0.0, 10.0) * clamp(-sP.z, 0.0, 1.0);
				  flare1B *= sunmask;
				  flare1B = pow(flare1B, 1.8f);
				  
				  flare1B *= flare1Bpow;
				  
				  	color.r += flare1B*0.7f*flaremultR;
					color.g += flare1B*0.2f*flaremultG;
					color.b += flare1B*0.0f*flaremultB;	
				
 ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
               
            
               
               
            //Center orange strip 1
           vec2 flare_strip1_scale = vec2(0.5f*flarescale, 40.0f*flarescale);
           float flare_strip1_pow = 0.2f;
           float flare_strip1_fill = 7.0f;
           float flare_strip1_offset = 0.0f;
         vec2 flare_strip1_pos = vec2(lPos.x*aspectRatio*flare_strip1_scale.x, lPos.y*flare_strip1_scale.y);
         
         
         float flare_strip1_ = distance(flare_strip1_pos, vec2(texcoord.s*aspectRatio*flare_strip1_scale.x, texcoord.t*flare_strip1_scale.y));
              flare_strip1_ = 0.5 - flare_strip1_;
              flare_strip1_ = clamp(flare_strip1_*flare_strip1_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_strip1_ *= sunmask;
              flare_strip1_ = pow(flare_strip1_, 1.4f);
              
              flare_strip1_ *= flare_strip1_pow;

              
                 color.r += flare_strip1_*0.5f*flaremultR;
               color.g += flare_strip1_*0.3f*flaremultG;
               color.b += flare_strip1_*0.0f*flaremultB;   
               
               
               
            //Center orange strip 3
           vec2 flare_strip3_scale = vec2(0.4f*flarescale, 35.0f*flarescale);
           float flare_strip3_pow = 0.2f;
           float flare_strip3_fill = 7.0f;
           float flare_strip3_offset = 0.0f;
         vec2 flare_strip3_pos = vec2(lPos.x*aspectRatio*flare_strip3_scale.x, lPos.y*flare_strip3_scale.y);
         
         
         float flare_strip3_ = distance(flare_strip3_pos, vec2(texcoord.s*aspectRatio*flare_strip3_scale.x, texcoord.t*flare_strip3_scale.y));
              flare_strip3_ = 0.5 - flare_strip3_;
              flare_strip3_ = clamp(flare_strip3_*flare_strip3_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_strip3_ *= sunmask;
              flare_strip3_ = pow(flare_strip3_, 1.4f);
              
              flare_strip3_ *= flare_strip3_pow;

              
                 color.r += flare_strip3_*0.5f*flaremultR;
               color.g += flare_strip3_*0.3f*flaremultG;
               color.b += flare_strip3_*0.0f*flaremultB;
				
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


         vec3 tempColor = vec3(0.0);

         
//-------------------red--------------------------------------------------------------------------------------

           vec2 flare_red_scale = vec2(5.2f*flarescale, 5.2f*flarescale);
           flare_red_scale.x *= (centermask);
           flare_red_scale.y *= (centermask);
           
           float flare_red_pow = 4.5f;
           float flare_red_fill = 15.0f;
           float flare_red_offset = -1.0f;
         vec2 flare_red_pos = vec2(  ((1.0 - lPos.x)*(flare_red_offset + 1.0) - (flare_red_offset*0.5))  *aspectRatio*flare_red_scale.x,  ((1.0 - lPos.y)*(flare_red_offset + 1.0) - (flare_red_offset*0.5))  *flare_red_scale.y);
         
         
         float flare_red_ = distance(flare_red_pos, vec2(texcoord.s*aspectRatio*flare_red_scale.x, texcoord.t*flare_red_scale.y));
              flare_red_ = 0.5 - flare_red_;
              flare_red_ = clamp(flare_red_*flare_red_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_red_ = sin(flare_red_*1.57075);
              
              flare_red_ = pow(flare_red_, 1.1f);
              
              flare_red_ *= flare_red_pow;         
              
              
              //subtract
              vec2 flare_redD_scale = vec2(3.0*flarescale, 3.0*flarescale);
              flare_redD_scale *= 0.99;
              flare_redD_scale.x *= (centermask);
               flare_redD_scale.y *= (centermask);
              
              float flare_redD_pow = 8.0f;
              float flare_redD_fill = 1.4f;
              float flare_redD_offset = -1.2f;
            vec2 flare_redD_pos = vec2(  ((1.0 - lPos.x)*(flare_redD_offset + 1.0) - (flare_redD_offset*0.5))  *aspectRatio*flare_redD_scale.x,  ((1.0 - lPos.y)*(flare_redD_offset + 1.0) - (flare_redD_offset*0.5))  *flare_redD_scale.y);
         
         
            float flare_redD_ = distance(flare_redD_pos, vec2(texcoord.s*aspectRatio*flare_redD_scale.x, texcoord.t*flare_redD_scale.y));
               flare_redD_ = 0.5 - flare_redD_;
               flare_redD_ = clamp(flare_redD_*flare_redD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_redD_ = sin(flare_redD_*1.57075);
               flare_redD_ = pow(flare_redD_, 0.9f);
              
               flare_redD_ *= flare_redD_pow;
              
            flare_red_ = clamp(flare_red_ - flare_redD_, 0.0, 10.0);
            flare_red_ *= sunmask;
              
                 tempColor.r += flare_red_*1.0f*flaremultR;
               tempColor.g += flare_red_*0.0f*flaremultG;
               tempColor.b += flare_red_*0.0f*flaremultB;
               
//--------------------------------------------------------------------------------------
   
//-------------------Orange--------------------------------------------------------------------------------------

           vec2 flare_orange_scale = vec2(5.0f*flarescale, 5.0f*flarescale);
           flare_orange_scale.x *= (centermask);
           flare_orange_scale.y *= (centermask);
           
           float flare_orange_pow = 4.5f;
           float flare_orange_fill = 15.0f;
           float flare_orange_offset = -1.0f;
         vec2 flare_orange_pos = vec2(  ((1.0 - lPos.x)*(flare_orange_offset + 1.0) - (flare_orange_offset*0.5))  *aspectRatio*flare_orange_scale.x,  ((1.0 - lPos.y)*(flare_orange_offset + 1.0) - (flare_orange_offset*0.5))  *flare_orange_scale.y);
         
         
         float flare_orange_ = distance(flare_orange_pos, vec2(texcoord.s*aspectRatio*flare_orange_scale.x, texcoord.t*flare_orange_scale.y));
              flare_orange_ = 0.5 - flare_orange_;
              flare_orange_ = clamp(flare_orange_*flare_orange_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_orange_ = sin(flare_orange_*1.57075);
              
              flare_orange_ = pow(flare_orange_, 1.1f);
              
              flare_orange_ *= flare_orange_pow;         
              
              
              //subtract
              vec2 flare_orangeD_scale = vec2(2.884f*flarescale, 2.884f*flarescale);
              flare_orangeD_scale *= 0.99;
              flare_orangeD_scale.x *= (centermask);
               flare_orangeD_scale.y *= (centermask);
              
              float flare_orangeD_pow = 8.0f;
              float flare_orangeD_fill = 1.4f;
              float flare_orangeD_offset = -1.2f;
            vec2 flare_orangeD_pos = vec2(  ((1.0 - lPos.x)*(flare_orangeD_offset + 1.0) - (flare_orangeD_offset*0.5))  *aspectRatio*flare_orangeD_scale.x,  ((1.0 - lPos.y)*(flare_orangeD_offset + 1.0) - (flare_orangeD_offset*0.5))  *flare_orangeD_scale.y);
         
         
            float flare_orangeD_ = distance(flare_orangeD_pos, vec2(texcoord.s*aspectRatio*flare_orangeD_scale.x, texcoord.t*flare_orangeD_scale.y));
               flare_orangeD_ = 0.5 - flare_orangeD_;
               flare_orangeD_ = clamp(flare_orangeD_*flare_orangeD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_orangeD_ = sin(flare_orangeD_*1.57075);
               flare_orangeD_ = pow(flare_orangeD_, 0.9f);
              
               flare_orangeD_ *= flare_orangeD_pow;
              
            flare_orange_ = clamp(flare_orange_ - flare_orangeD_, 0.0, 10.0);
            flare_orange_ *= sunmask;
              
                 tempColor.r += flare_orange_*1.0f*flaremultR;
               tempColor.g += flare_orange_*0.0f*flaremultG;
               tempColor.b += flare_orange_*0.0f*flaremultB;   
               
//--------------------------------------------------------------------------------------
   
//-------------------Green--------------------------------------------------------------------------------------

           vec2 flare_green_scale = vec2(4.8f*flarescale, 4.8f*flarescale);
           flare_green_scale.x *= (centermask);
           flare_green_scale.y *= (centermask);
           
           float flare_green_pow = 4.5f;
           float flare_green_fill = 15.0f;
           float flare_green_offset = -1.0f;
         vec2 flare_green_pos = vec2(  ((1.0 - lPos.x)*(flare_green_offset + 1.0) - (flare_green_offset*0.5))  *aspectRatio*flare_green_scale.x,  ((1.0 - lPos.y)*(flare_green_offset + 1.0) - (flare_green_offset*0.5))  *flare_green_scale.y);
         
         
         float flare_green_ = distance(flare_green_pos, vec2(texcoord.s*aspectRatio*flare_green_scale.x, texcoord.t*flare_green_scale.y));
              flare_green_ = 0.5 - flare_green_;
              flare_green_ = clamp(flare_green_*flare_green_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_green_ = sin(flare_green_*1.57075);
              
              flare_green_ = pow(flare_green_, 1.1f);
              
              flare_green_ *= flare_green_pow;         
              
              
              //subtract
              vec2 flare_greenD_scale = vec2(2.769f*flarescale, 2.769f*flarescale);
              flare_greenD_scale *= 0.99;
              flare_greenD_scale.x *= (centermask);
               flare_greenD_scale.y *= (centermask);
              
              float flare_greenD_pow = 8.0f;
              float flare_greenD_fill = 1.4f;
              float flare_greenD_offset = -1.2f;
            vec2 flare_greenD_pos = vec2(  ((1.0 - lPos.x)*(flare_greenD_offset + 1.0) - (flare_greenD_offset*0.5))  *aspectRatio*flare_greenD_scale.x,  ((1.0 - lPos.y)*(flare_greenD_offset + 1.0) - (flare_greenD_offset*0.5))  *flare_greenD_scale.y);
         
         
            float flare_greenD_ = distance(flare_greenD_pos, vec2(texcoord.s*aspectRatio*flare_greenD_scale.x, texcoord.t*flare_greenD_scale.y));
               flare_greenD_ = 0.5 - flare_greenD_;
               flare_greenD_ = clamp(flare_greenD_*flare_greenD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_greenD_ = sin(flare_greenD_*1.57075);
               flare_greenD_ = pow(flare_greenD_, 0.9f);
              
               flare_greenD_ *= flare_greenD_pow;
              
            flare_green_ = clamp(flare_green_ - flare_greenD_, 0.0, 10.0);
            flare_green_ *= sunmask;
              
                 tempColor.r += flare_green_*0.25f*flaremultR;
               tempColor.g += flare_green_*1.0f*flaremultG;
               tempColor.b += flare_green_*0.0f*flaremultB;   
               
//--------------------------------------------------------------------------------------

//-------------------Blue--------------------------------------------------------------------------------------

           vec2 flare_blue_scale = vec2(4.6f*flarescale, 4.6f*flarescale);
           flare_blue_scale.x *= (centermask);
           flare_blue_scale.y *= (centermask);
           
           float flare_blue_pow = 4.5f;
           float flare_blue_fill = 15.0f;
           float flare_blue_offset = -1.0f;
         vec2 flare_blue_pos = vec2(  ((1.0 - lPos.x)*(flare_blue_offset + 1.0) - (flare_blue_offset*0.5))  *aspectRatio*flare_blue_scale.x,  ((1.0 - lPos.y)*(flare_blue_offset + 1.0) - (flare_blue_offset*0.5))  *flare_blue_scale.y);
         
         
         float flare_blue_ = distance(flare_blue_pos, vec2(texcoord.s*aspectRatio*flare_blue_scale.x, texcoord.t*flare_blue_scale.y));
              flare_blue_ = 0.5 - flare_blue_;
              flare_blue_ = clamp(flare_blue_*flare_blue_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
              flare_blue_ = sin(flare_blue_*1.57075);
              
              flare_blue_ = pow(flare_blue_, 1.1f);
              
              flare_blue_ *= flare_blue_pow;         
              
              
              //subtract
              vec2 flare_blueD_scale = vec2(2.596f*flarescale, 2.596f*flarescale);
              flare_blueD_scale *= 0.99;
              flare_blueD_scale.x *= (centermask);
               flare_blueD_scale.y *= (centermask);
              
              float flare_blueD_pow = 8.0f;
              float flare_blueD_fill = 1.4f;
              float flare_blueD_offset = -1.2f;
            vec2 flare_blueD_pos = vec2(  ((1.0 - lPos.x)*(flare_blueD_offset + 1.0) - (flare_blueD_offset*0.5))  *aspectRatio*flare_blueD_scale.x,  ((1.0 - lPos.y)*(flare_blueD_offset + 1.0) - (flare_blueD_offset*0.5))  *flare_blueD_scale.y);
         
         
            float flare_blueD_ = distance(flare_blueD_pos, vec2(texcoord.s*aspectRatio*flare_blueD_scale.x, texcoord.t*flare_blueD_scale.y));
               flare_blueD_ = 0.5 - flare_blueD_;
               flare_blueD_ = clamp(flare_blueD_*flare_blueD_fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
               flare_blueD_ = sin(flare_blueD_*1.57075);
               flare_blueD_ = pow(flare_blueD_, 0.9f);
              
               flare_blueD_ *= flare_blueD_pow;
              
            flare_blue_ = clamp(flare_blue_ - flare_blueD_, 0.0, 10.0);
            flare_blue_ *= sunmask;
              
                 tempColor.r += flare_blue_*0.0f*flaremultR;
               tempColor.g += flare_blue_*0.0f*flaremultG;
               tempColor.b += flare_blue_*0.75f*flaremultB;   
               
//--------------------------------------------------------------------------------------

      color += (tempColor);
			
			//far small flare
			  vec2 flare4scale = vec2(4.5f*flarescale, 4.5f*flarescale);
			  float flare4pow = 0.3f;
			  float flare4fill = 3.0f;
			  float flare4offset = -0.1f;
			vec2 flare4pos = vec2(  ((1.0 - lPos.x)*(flare4offset + 1.0) - (flare4offset*0.5))  *aspectRatio*flare4scale.x,  ((1.0 - lPos.y)*(flare4offset + 1.0) - (flare4offset*0.5))  *flare4scale.y);
			
			
			float flare4 = distance(flare4pos, vec2(texcoord.s*aspectRatio*flare4scale.x, texcoord.t*flare4scale.y));
				  flare4 = 0.5 - flare4;
				  flare4 = clamp(flare4*flare4fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4 = sin(flare4*1.57075);
				  flare4 *= sunmask;
				  flare4 = pow(flare4, 1.1f);
				  
				  flare4 *= flare4pow;
				  
				  	color.r += flare4*0.6f*flaremultR;
					color.g += flare4*0.0f*flaremultG;
					color.b += flare4*0.8f*flaremultB;							
					
					
					
			//far small flare2
			  vec2 flare4Bscale = vec2(7.5f*flarescale, 7.5f*flarescale);
			  float flare4Bpow = 0.4f;
			  float flare4Bfill = 2.0f;
			  float flare4Boffset = 0.0f;
			vec2 flare4Bpos = vec2(  ((1.0 - lPos.x)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *aspectRatio*flare4Bscale.x,  ((1.0 - lPos.y)*(flare4Boffset + 1.0) - (flare4Boffset*0.5))  *flare4Bscale.y);
			
			
			float flare4B = distance(flare4Bpos, vec2(texcoord.s*aspectRatio*flare4Bscale.x, texcoord.t*flare4Bscale.y));
				  flare4B = 0.5 - flare4B;
				  flare4B = clamp(flare4B*flare4Bfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4B = sin(flare4B*1.57075);
				  flare4B *= sunmask;
				  flare4B = pow(flare4B, 1.1f);
				  
				  flare4B *= flare4Bpow;
				  
				  	color.r += flare4B*0.4f*flaremultR;
					color.g += flare4B*0.0f*flaremultG;
					color.b += flare4B*0.3f*flaremultB;						
					
					
					
			//far small flare3
			  vec2 flare4Cscale = vec2(37.5f*flarescale, 37.5f*flarescale);
			  float flare4Cpow = 2.0f;
			  float flare4Cfill = 2.0f;
			  float flare4Coffset = -0.3f;
			vec2 flare4Cpos = vec2(  ((1.0 - lPos.x)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *aspectRatio*flare4Cscale.x,  ((1.0 - lPos.y)*(flare4Coffset + 1.0) - (flare4Coffset*0.5))  *flare4Cscale.y);
			
			
			float flare4C = distance(flare4Cpos, vec2(texcoord.s*aspectRatio*flare4Cscale.x, texcoord.t*flare4Cscale.y));
				  flare4C = 0.5 - flare4C;
				  flare4C = clamp(flare4C*flare4Cfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4C = sin(flare4C*1.57075);
				  flare4C *= sunmask;
				  flare4C = pow(flare4C, 1.1f);
				  
				  flare4C *= flare4Cpow;
				  
				  	color.r += flare4C*0.2f*flaremultR;
					color.g += flare4C*0.6f*flaremultG;
					color.b += flare4C*0.4f*flaremultB;						
					
					
					
			//far small flare4
			  vec2 flare4Dscale = vec2(67.5f*flarescale, 67.5f*flarescale);
			  float flare4Dpow = 1.0f;
			  float flare4Dfill = 2.0f;
			  float flare4Doffset = -0.35f;
			vec2 flare4Dpos = vec2(  ((1.0 - lPos.x)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *aspectRatio*flare4Dscale.x,  ((1.0 - lPos.y)*(flare4Doffset + 1.0) - (flare4Doffset*0.5))  *flare4Dscale.y);
			
			
			float flare4D = distance(flare4Dpos, vec2(texcoord.s*aspectRatio*flare4Dscale.x, texcoord.t*flare4Dscale.y));
				  flare4D = 0.5 - flare4D;
				  flare4D = clamp(flare4D*flare4Dfill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4D = sin(flare4D*1.57075);
				  flare4D *= sunmask;
				  flare4D = pow(flare4D, 1.1f);
				  
				  flare4D *= flare4Dpow;
				  
				  	color.r += flare4D*0.2f*flaremultR;
					color.g += flare4D*0.2f*flaremultG;
					color.b += flare4D*0.4f*flaremultB;						
					
					
								
			//far small flare5
			  vec2 flare4Escale = vec2(60.5f*flarescale, 60.5f*flarescale);
			  float flare4Epow = 1.0f;
			  float flare4Efill = 3.0f;
			  float flare4Eoffset = -0.3393f;
			vec2 flare4Epos = vec2(  ((1.0 - lPos.x)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *aspectRatio*flare4Escale.x,  ((1.0 - lPos.y)*(flare4Eoffset + 1.0) - (flare4Eoffset*0.5))  *flare4Escale.y);
			
			
			float flare4E = distance(flare4Epos, vec2(texcoord.s*aspectRatio*flare4Escale.x, texcoord.t*flare4Escale.y));
				  flare4E = 0.5 - flare4E;
				  flare4E = clamp(flare4E*flare4Efill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4E = sin(flare4E*1.57075);
				  flare4E *= sunmask;
				  flare4E = pow(flare4E, 1.1f);
				  
				  flare4E *= flare4Epow;
				  
				  	color.r += flare4E*0.2f*flaremultR;
					color.g += flare4E*0.2f*flaremultG;
					color.b += flare4E*0.3f*flaremultB;					
					
								
								
			//far small flare5
			  vec2 flare4Fscale = vec2(20.5f*flarescale, 20.5f*flarescale);
			  float flare4Fpow = 3.0f;
			  float flare4Ffill = 3.0f;
			  float flare4Foffset = -0.4713f;
			vec2 flare4Fpos = vec2(  ((1.0 - lPos.x)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *aspectRatio*flare4Fscale.x,  ((1.0 - lPos.y)*(flare4Foffset + 1.0) - (flare4Foffset*0.5))  *flare4Fscale.y);
			
			
			float flare4F = distance(flare4Fpos, vec2(texcoord.s*aspectRatio*flare4Fscale.x, texcoord.t*flare4Fscale.y));
				  flare4F = 0.5 - flare4F;
				  flare4F = clamp(flare4F*flare4Ffill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare4F = sin(flare4F*1.57075);
				  flare4F *= sunmask;
				  flare4F = pow(flare4F, 1.1f);
				  
				  flare4F *= flare4Fpow;
				  
				  	color.r += flare4F*0.3f*flaremultR;
					color.g += flare4F*0.1f*flaremultG;
					color.b += flare4F*0.1f*flaremultB;						
					

			  vec2 flare5scale = vec2(3.2f*flarescale , 3.2f*flarescale );
			  float flare5pow = 13.4f;
			  float flare5fill = 1.0f;
			  float flare5offset = -2.0f;
			vec2 flare5pos = vec2(  ((1.0 - lPos.x)*(flare5offset + 1.0) - (flare5offset*0.5))  *aspectRatio*flare5scale.x,  ((1.0 - lPos.y)*(flare5offset + 1.0) - (flare5offset*0.5))  *flare5scale.y);
			
			
			float flare5 = distance(flare5pos, vec2(texcoord.s*aspectRatio*flare5scale.x, texcoord.t*flare5scale.y));
				  flare5 = 0.5 - flare5;
				  flare5 = clamp(flare5*flare5fill, 0.0, 1.0) * clamp(-sP.z, 0.0, 1.0);
				  flare5 *= sunmask;
				  flare5 = pow(flare5, 1.9f);
				  
				  flare5 *= flare5pow;
				  
				  	color.r += flare5*0.4f*flaremultR;
					color.g += flare5*0.4f*flaremultG;
					color.b += flare5*0.3f*flaremultB;						
					

			}
}
}
#endif

#ifdef KUDA_LENS

    //float distof = min(min(1.0-lightPos.x,lightPos.x),min(1.0-lightPos.y,lightPos.y));
	float fading_2 = clamp(1.0-step(distof,0.1)+pow(distof*10.0,5.0),0.0,1.0);

    //float time = float(worldTime);
	//float transition_fading = 1.0-(clamp((time-12000.0)/500.0,0.0,1.0)-clamp((time-13000.0)/500.0,0.0,1.0) + clamp((time-22500.0)/100.0,0.0,1.0)-clamp((time-23300.0)/200.0,0.0,1.0));

    float sunvisibility_2 = min(texture2D(gaux2, vec2(0.0)).a, 1.0) * fading_2 * transition_fading;
	float sunvisibility2 = min(texture2D(gaux2, vec2(0.0)).a, 1.0) * transition_fading;
	float centerVisibility = 1.0 - clamp(distance(lightPos.xy, vec2(0.5, 0.5)) * 2.0, 0.0, 1.0);
		  centerVisibility *= sunvisibility_2;
	
	float lensBrightness = 0.5;
	
	// Fix, that the particles are visible on the moon position at daytime
	float truepos_2 = 0.0f;
	
	if ((worldTime < 13000 || worldTime > 23000) && sunPos.z < 0) truepos_2 = 1.0 * (TimeSunrise + TimeNoon + TimeSunset); 
	if ((worldTime < 23000 || worldTime > 13000) && -sunPos.z < 0) truepos_2 = 1.0 * TimeMidnight; 


	

	
	if ((worldTime < 13000 || worldTime > 23000) && sunPos.z < 0 && isEyeInWater < 0.9) {
	
		float dist = distance(texcoord.st, vec2(0.5, 0.5));

		// Sunrays
		if (sunvisibility_2 > 0.08) {
		
			float visibility = max(pow(max(1.0 - smoothCircleDist(1.0)/1.0,0.1),5.0)-0.1,0.0);
			float sun = max(pow(max(1.0 - smoothCircleDist(1.0)/0.5,0.1),5.0)-0.1,0.0);
		
			vec3 lenscolorSunrise = vec3(5.52, 4.6, 3.7) * TimeSunrise;
			vec3 lenscolorNoon = vec3(5.52, 5.0, 5.5) * TimeNoon;
			vec3 lenscolorSunset = vec3(5.52, 4.6, 3.7) * TimeSunset;
			
			vec3 lenscolor = lenscolorSunrise + lenscolorNoon + lenscolorSunset;
			
			float lens_strength = clamp(0.8 * lensBrightness - sun, 0.0, 1.0);
			lenscolor *= lens_strength;
			
			float sunray1 = max(pow(max(1.0 - yDistAxis(1.5)/0.7,0.1),10.0)-0.6,0.0)*1.3;
			float sunray2 = max(pow(max(1.0 - yDistAxis(-1.3)/0.7,0.1),10.0)-0.6,0.0)*1.3;
			float sunray3 = max(pow(max(1.0 - yDistAxis(5.0)/1.5,0.1),10.0)-0.6,0.0)*1.3;
			float sunray4 = max(pow(max(1.0 - yDistAxis(-4.8)/1.5,0.1),10.0)-0.6,0.0)*1.3;
			
			float sunrays = min(sunray1 + sunray2 + sunray3 + sunray4, 1.0);
			
			color += lenscolor * sunrays * visibility * sunvisibility_2 * (1.0-rainStrength*1.0);
		}
	
			
			// Screen getting darker when looking at the sun.
			color.rgb *= (1.0 - centerVisibility * 1.0 * truepos * (TimeSunrise + TimeNoon + TimeSunset) * (1.0 - rainStrength));
			
		
	
	}
#endif

#ifdef CHOCS_LENS_FLARE
	//post processing
		if (sunvisibility > 0.05) {

			vec3 lensColor = exp(-ydist*ydist/0.0015)*exp(-xdist*xdist/0.05)*sunvisibility * vec3(0.1,0.3,1.0);

			vec2 LC = vec2(0.5)-lightPos;
			
			
			
			vec2 pos1 = lightPos + LC * 0.7;
			lensColor += vec3(1.0,0.3,.1)*gen_circular_lens(vec2(pos1),0.03)*0.58;
			
			pos1 = lightPos + LC * 0.9;
			lensColor += vec3(0.8,0.6,.1)*gen_circular_lens(vec2(pos1),0.06)*0.375;
			
			pos1 = lightPos + LC * 1.3;
			lensColor += vec3(0.1,1.0,.3)*gen_circular_lens(vec2(pos1),0.12)*0.28;
			
			pos1 = lightPos + LC * 2.1;
			lensColor += vec3(0.1,0.6,.8)*gen_circular_lens(vec2(pos1),0.24)*0.21;

			lensColor = lensColor*7.0*sunvisibility*truepos*light_color/MAX_COLOR_RANGE;
			
			color = ((lensColor + color/MAX_COLOR_RANGE) - (lensColor * color/MAX_COLOR_RANGE))*MAX_COLOR_RANGE;
			//color = Uncharted2Tonemap(lensColor)/Uncharted2Tonemap(vec3(W));
	}
#endif
	
	
#ifdef CALCULATE_EXPOSURE
	if (isEyeInWater > 0.9 && land < 0.1) color.rgb = calcExposure(color);
#endif
	
	//Tonemapping
	float avglight = texture2D(gaux2,vec2(1.0)).a;
	
	vec3 curr = Uncharted2Tonemap(color);

#ifdef OldColor_Tonemap
	vec3 whiteScale = 1.0f/Uncharted2Tonemap(vec3(W));
#else
	vec3 whiteScale = 1.40f/Uncharted2Tonemap(vec3(W))*TimeNoon;
		 whiteScale += 1.40f/Uncharted2Tonemap(vec3(W))*TimeSunrise;
		 whiteScale += 1.00f/Uncharted2Tonemap(vec3(W))*TimeSunset;
		 whiteScale += 1.00f/Uncharted2Tonemap(vec3(W))*TimeMidnight;
#endif	
	color = curr*whiteScale;
	
	 float saturation = 1.04;   
	
	color.r = pow(color.r, 1.1);
	color.g = pow(color.g, 1.1);
	color.b = pow(color.b, 1.1);
       
        float avg = (color.r + color.g + color.b);
       
        color = (((color - avg )*saturation)+avg) ;
		color /= saturation;
	
	color = clamp(pow(color,vec3(1.0/2.2)),0.0,1.0);

	color = mix(color, vec3(dot(color, vec3(1.0 / 3.0))), vec3(desaturation));


	gl_FragColor = vec4(color,1.0);
}
