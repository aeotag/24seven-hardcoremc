#version 120


#define MAX_COLOR_RANGE 48.0
/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

const bool gdepthMipmapEnabled = true;

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES

	
		
	#define WATER_REFLECTIONS					//Adds reflections to the water surface			
		#define REFLECTION_STRENGTH 1.0
		
#define Rain_Fog								//Adds fog when its raining	

#define SPECULAR_MAPPING  						//Adds a "Shiny" look to blocks when raining
//#define Rain_Puddles							//To give the effect of Rain Puddles on the ground when raining, Taxing to FPS
	#define Rain_Puddles_Strength 70 	//[5 10 20 30 40 50 60 70 80 90 100 110 120]

//#define MOTIONBLUR				
	#define MOTIONBLUR_AMOUNT 0.066		
	
//#define UNDERWATER_FOG				//Adds a Blue fog when underwater

/*--------------------------------*/
#define Clouds_HQ					//very fps taxing
#define Clouds_HQ_fpsBoost			//This is to boost the fps of the HQ Clouds by sacrificing the Visual appearance of the clouds  
//#define Clouds_LQ					//Clouds From Robobo's shader, no fps hit but dont look as nice as HQ Clouds
	#define Steps_Quality 5		//[1 2 3 4 5 6 7 8] //This is for Clouds_LQ lower means less detail in the clouds, higher means more detail but could take some fps

 #define Stars					//Adds Stars at night
/*--------------------------------*/

#define VOLUMETRIC_LIGHT					//True Godrays, this is not Screen Space and is Based off Robobo's shader VL
	#define VL_MULT 					1.0				// Simple multiplier		
//---Volumetric light strength--//
#define SUNRISEnSET		6.0	//default is 10.0
#define NOON			2.0		//default is 2.0 for least amount of haze at the cost of effect
#define NIGHTs			0.55		//default is 100.7 for least amount of haze at the cost of effect, 5000.5 for best looking but lots of haze
#define IN_SIDE_RAYS	40.5		//strength of rays when indoors, daytime
#define IN_SIDE_RAYS_NIGHT 15.6		//strength of rays when indoors, night

//----ScreenSpace Godrays----//
#define GODRAYS									//These are 2D screenspace godrays		
	#ifdef VOLUMETRIC_LIGHT
		const float exposure = 2.2;			//godrays intensity 15.0 is default
	#else
		const float exposure = 10.0;
	#endif
	#ifdef VOLUMETRIC_LIGHT
		const float MOONexposure = 1.2;			//godrays intensity 15.0 is default
	#else
		const float MOONexposure = 10.2;			//godrays intensity 15.0 is default
	#endif
		const float density = 1.0;			
		const int NUM_SAMPLES = 7;			//increase this for better quality at the cost of performance /8 is default
		const float grnoise = 0.0;		//amount of noise /0.0 is default
		
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
#define SHADOW_MAP_BIAS 0.85
/* DRAWBUFFERS:2 */

const bool gcolorMipmapEnabled = true;
const bool compositeMipmapEnabled = true;
const bool gaux2MipmapEnabled = true;

//don't touch these lines if you don't know what you do!
const int maxf = 3;				//number of refinements
const float stp = 1.0;			//size of one step for raytracing algorithm
const float ref = 0.1;			//refinement multiplier
const float inc = 1.8;			//increasement factor at each step

//ground constants (lower quality)
const int Gmaxf = 3;				//number of refinements
const float Gstp = 1.2;			//size of one step for raytracing algorithm
const float Gref = 0.11;			//refinement multiplier
const float Ginc = 3.0;			//increasement factor at each step

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 moonlight2;
varying vec3 ambient_color;
varying vec3 vlAmbient;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D composite;
uniform sampler2D gaux4;
uniform sampler2D gaux3;
uniform sampler2D gaux2;
uniform sampler2D gaux1;
uniform sampler2D gdepthtex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D gnormal;
uniform sampler2D gdepth;
uniform sampler2D noisetex;
uniform sampler2DShadow shadow;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

varying float timeSunriseSunset;
varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeMidnight;
varying float timeSkyDark;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform vec3 previousCameraPosition;

uniform int isEyeInWater;
uniform int worldTime;
uniform float far;
uniform float near;
uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float frameTimeCounter;
uniform ivec2 eyeBrightnessSmooth;

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;
/*--------------------------------*/
vec2 wind[4] = vec2[4](vec2(abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5))+vec2(0.5),
					   vec2(-abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5)),
					   vec2(-abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5)),
					   vec2(abs(frameTimeCounter/1000.-0.5),-abs(frameTimeCounter/1000.-0.5)));
/*--------------------------------*/	

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float matflag = texture2D(gaux1,texcoord.xy).g;

vec3 fogclr = pow(mix(vec3(0.5,0.5,1.0),vec3(0.3,0.3,0.3),rainStrength)*ambient_color,vec3(2.2));
vec3 fogclrVL = pow(mix(vec3(0.5,0.5,1.0),vec3(0.3,0.3,0.3),rainStrength)*ambient_color,vec3(2.2));

vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0 - 1.0;

float time = float(worldTime);
float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-22800.0)/200.0,0.0,1.0);

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

float transition_fading = 1.0-(clamp((timefract-12000.0)/300.0,0.0,1.0)-clamp((timefract-13000.0)/300.0,0.0,1.0) + clamp((timefract-22800.0)/200.0,0.0,1.0)-clamp((timefract-23400.0)/200.0,0.0,1.0));

float sky_lightmap = texture2D(gaux1,texcoord.xy).r;
float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));

vec4 aux = texture2D(gaux1, texcoord.st);
vec4 aux2 = texture2D(gaux2, texcoord.st);

vec3 specular = texture2D(gaux3,texcoord.xy).rgb;
float specmap = float(aux.a > 0.7 && aux.a < 0.72) + (specular.r+specular.g*(iswet));
	
vec4 color = texture2DLod(composite,texcoord.xy,0);

//vec3 aux = texture2D(gaux1, texcoord.st).rgb;

float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

float luma(vec3 color) {
return dot(color.rgb,vec3(0.299, 0.587, 0.114));
}


float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

float hash( float n ) {
	return fract(sin(n)*43758.5453);
}

float subSurfaceScattering(vec3 vec,vec3 pos, float N) {
	return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;
}

float 	GetDepth(in vec2 coord) {
		return texture2D(gdepthtex, coord.st).x;
	}


vec4  	GetScreenSpacePosition(in vec2 coord, in float depth) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

	vec4  	GetScreenSpacePosition2(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

float subSurfaceScattering(vec3 pos, float N) {

return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;

}

float subSurfaceScattering2(vec3 vec,vec3 pos, float N) {
		return pow(max(dot(vec,normalize(pos))*0.5+0.5,0.0),N)*(N+1)/6.28;
	}

float 	ExpToLinearDepth(in float depth)
	{
		return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
	}

float 	LinearToExponentialDepth(in float linDepth)
{
	return (far * (linDepth - near)) / (linDepth * (far - near));
}
	
	float pixeldepth = texture2D(gdepthtex,texcoord.xy).x;

float getRainPuddles(vec3 fposition){
	vec3 pPos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);
	pPos = nvec3(gbufferProjectionInverse * nvec4(pPos * 2.0 - 1.0));
	vec4 pUw = gbufferModelViewInverse * vec4(pPos,1.0);
	vec3 worldPos = (pUw.xyz + cameraPosition.xyz);

	vec2 coord = (worldPos.xz/10000);

	float rainPuddles = texture2D(noisetex, fract(coord.xy*8)).x;
	rainPuddles += texture2D(noisetex, fract(coord.xy*4)).x;
	rainPuddles += texture2D(noisetex, fract(coord.xy*2)).x;
	rainPuddles += texture2D(noisetex, fract(coord.xy/2)).x;

	float strength = max(rainPuddles-2.15,0.0);
	float dL = 0.5;
	float L = (1.0 - (pow(dL,strength)));

	return L;
}

#ifdef LENS_EFFECTS

	float distratio(vec2 pos, vec2 pos2, float ratio) {
		float xvect = pos.x*ratio-pos2.x*ratio;
		float yvect = pos.y-pos2.y;
		return sqrt(xvect*xvect + yvect*yvect);
	}

	float gen_circular_lens(vec2 center, float size) {
		return 1.0-pow(min(distratio(texcoord.xy,center,aspectRatio),size)/size,10.0);
	}

	vec2 noisepattern(vec2 pos) {
		return vec2(abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f)),abs(fract(sin(dot(pos.yx ,vec2(18.9898f,28.633f))) * 4378.5453f)));
	} 

#endif

float noise( in vec2 x ) {
	vec2 p = floor(x);
	vec2 f = fract(x);
		 f = f*f*(3.0-2.0*f);
	float n = p.x + p.y*57.0;
	float res = mix(mix( hash(n+  0.0), hash(n+  1.0),f.x), mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y);
	return res;
}

float fbm( vec2 p ) {
	float f = 0.0;
		  f += 0.50000*noise( p ); p = p*2.5;
		  f += 0.25000*noise( p ); p = p*2.5;
		  f += 0.12500*noise( p ); p = p*2.5;
		  f += 0.06250*noise( p ); p = p*2.5;
		  f += 0.03125*noise( p );
	return f/0.984375;
}

vec3 skyLightIntegral (vec3 fposition) {
vec3 skycoaa = ivec3(28,180,255)/255.0;
vec3 sky_color = mix(moonlight*2.0,pow(skycoaa,vec3(2.2)),sunVisibility)*2.0;
	 sky_color = mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength);

vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

const float PI = 3.14159265359;

float Lz = 1.0;
float T = max(acos(dot(sVector,upVec)),0.0); 
float Y = max(acos(dot(sunVec,sVector)),0.0);
float M = max(acos(dot(moonVec,sVector)),0.0);

float blueDif = (1+2.0*cos(T));
float sunDif =  (1.0+2.0*max(cos(Y),0.0));

float hemisphereIntegral = PI + 2.0*(sin(T+PI/2.0)-sin(T-PI/2.0));
float sunIntegral = PI + 2.0*max(sin(Y+PI/2.0)*sin(Y+PI/2.0)*sin(Y+PI/2.0)-sin(Y-PI/2.0)*sin(Y-PI/2.0)*sin(Y-PI/2.0),0.0);
float moonIntegral = PI + 2.0*max(sin(M+PI/2.0)*sin(M+PI/2.0)*sin(M+PI/2.0)-sin(M-PI/2.0)*sin(M-PI/2.0)*sin(M-PI/2.0),0.0);

return hemisphereIntegral*sky_color*Lz + sunIntegral*sunlight*(1-rainStrength*0.9) * sunVisibility  + moonIntegral * moonlight * moonVisibility;
}

vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 skycoaa = ivec3(28,130,255)/255.0;
vec3 sky_color = pow(skycoaa,vec3(2.2));
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance


float Lz = 1.0;
float cosT = dot(sVector,upVector); //T=S-Y  
float absCosT = abs(cosT);
float cosS = dot(sunVec,upVector);
float S = acos(cosS);				//S=Y+T	-> cos(Y+T)=cos(S) -> cos(Y)*cos(T) - sin(Y)*sin(T) = cos(S)
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);				//Y=S-T

float a = -0.7;
float b = -0.15;
float c = 15.0;
float d = -1.0;
float e = 0.3;

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY); 
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.1*L*(1-rainStrength*0.8)))*L ; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;


//moon sky color
float McosS = dot(moonVec,upVector);
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY);
	  L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength)*L2*0.4 ; //affect color based on luminance (0% physically accurate)
	 skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun;
/*----------*/

return sky_color;
}

vec3 getFogColor(vec3 fposition) {

vec3 sky_color = pow(ambient_color,vec3(2.2))*2.0;
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
vec3 sVector = normalize(fposition);
vec3 upVector = normalize(upPosition);

sky_color = normalize(mix(sky_color,vec3(2.2)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance

float Lz = 1.0;
float cosT = dot(sVector,upVector); //T=S-Y  
float absCosT = abs(cosT);
float cosS = dot(sunVec,upVector);
float S = acos(cosS);				//S=Y+T	-> cos(Y+T)=cos(S) -> cos(Y)*cos(T) - sin(Y)*sin(T) = cos(S)
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);				//Y=S-T

float a = -0.7;
float b = -0.15;
float c = 15.0;
float d = -1.0;
float e = 0.3;

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY); 
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.05*L*(1-rainStrength*0.8)))*sqrt(L) ; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;


//moon sky color
float McosS = dot(moonVec,upVector);
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

float L2 =  (1+a*exp(b/absCosT))*(1+c*exp(d*MY)+e*McosY*McosY);
	  L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.25,0.25))*length(moonlight),rainStrength)*sqrt(L2) ; 
skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun;
//sky_color = vec3(Lc);
/*----------*/


return sky_color;

}

vec3 drawSun(vec3 fposition,vec3 color,int land) {
vec3 sVector = normalize(fposition);
float sun = max(pow(clamp(dot(sVector,normalize(sunPosition))+0.002,0.0,1.0),1000.0)-0.002,0.0)*land*(1-rainStrength*0.75)*sunVisibility;
vec3 sunlight = mix(sunlight,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength*0.8);

return mix(color,sunlight*MAX_COLOR_RANGE,sun);

}

vec3 calcWFog(vec3 fposition, vec3 color) {
	if (rainStrength > 0.9) {
    } else if(isEyeInWater > 0.9){
    

	float fog  = exp(-pow(length(fposition)/1,1.0-(1*rainStrength))*1.0);
		  
	float fogfactor =  clamp(fog,0.0,1.0);
	
	fogclr = getFogColor(fposition.xyz);
	

	return mix(((fogclr+color.rgb)/4*(1-rainStrength*0.95))/(1+2.0*(1-rainStrength*0.95)),color.rgb,fogfactor)*pow(1-rainStrength, 2.0f);
	}
}

vec3 calcFog(vec3 fposition, vec3 color) {
	
	float fog  = exp(-pow(length(fposition)/165,4.0-(2.5*rainStrength))*0.95);
		  fog -= mix(-1.0f, 0.0f, pow(eyeBrightnessSmooth.y / 240.0f, 2.0f));
		  
		  
	float fogfactor =  clamp(fog,0.0,1.0);
	
	fogclr = getFogColor(fposition.xyz);
	

	return mix((fogclr+color.rgb*2.0*(1-rainStrength*0.95))/(1+2.0*(1-rainStrength*0.95)),color.rgb,fogfactor);
	}
	
	
vec4 raytrace(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = stp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<40;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
			 spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = abs(fragpos.z-spos.z);
if(err < pow(length(vector)*1.85,1.15)){
	
                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=ref;
				
        
}
        vector *= inc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}

#ifdef Clouds_LQ

vec3 drawClouds(vec3 fposition,vec3 color, float mult) {
	if (isEyeInWater > .9) {
		} else {
			//vec4 noiseWeights = 1.0/vec4(1.0,3.5,12.25,42.87)/1.4472;
			const float r = 4.0;
			const vec4 noiseC = vec4(1.0,r,r*r,r*r*r);
			const vec4 noiseWeights = 1.0/vec4(1.0,r,r*r,r*r*r)/dot(1.0/vec4(1.0,r,r*r,r*r*r),vec4(1.0));
			/*--------------------------------*/
			vec3 sVector = normalize(fposition);
			float cosT = max(dot(normalize(sVector),upVec),0.0);
			vec3 tpos = vec3(gbufferModelViewInverse * vec4(sVector,0.0));
			vec3 wvec = normalize(tpos);
			vec3 wVector = normalize(tpos);

			vec3 cloudCol = pow(sunlight * 2.4,vec3(3.4))*(TimeSunrise+TimeSunset);
				cloudCol += (sunlight * 2.0)*(TimeNoon);
				cloudCol += (moonlight2 * 100.0)*(TimeMidnight);
				cloudCol +=	pow(sunlight * 1.5,vec3(3.0)) * (1-transition_fading);
			vec3 cloudCol2 = cloudCol;

			float totalcloud = 0.0;

			float height = (700.0)/(wVector.y);
			vec2 wind = vec2(1+frameTimeCounter, 8+frameTimeCounter)/20000;

			vec3 intersection;
			float density;
			float d1;

			int Steps = Steps_Quality;
			float weight;

			for (int i = 0; i < Steps; i++) {
				intersection = wVector * (height - i * 150.0 / Steps); 			//curved cloud plane

				vec2 coord1 = (intersection.xz+cameraPosition.xz)/200000+(wind);
				vec2 coord = (coord1/2.0);
			
					float noise = texture2D(noisetex,coord-wind*0.5).x;
						  noise += texture2D(noisetex,coord*3.5).x/3.5;
						  noise += texture2D(noisetex,coord*12.25).x/12.25;
						  noise /= 0.14;

				float cl = max(noise-0.6,0.0);
					  cl = max(cl-(abs(5-5.)/5.)*0.15,0.)*0.13 * (1.0 - rainx * 0.5);
				density = max(1-cl*1.5,0.)*max(1-cl*1.5,0.) / 11 / 3;
				density *= 2.0;

				totalcloud += density;
				totalcloud = clamp(totalcloud,0.0,1.0);
				weight += 1;

		}

		cloudCol = mix(cloudCol*pow(1-density, 2.0),vec3(cloudCol*0.125),pow(density, 2.0)) * 2.0;

		cloudCol += pow(sunlight * mix(3.0,2.5,TimeSunset + TimeSunrise),vec3(mix(3.0 - (1.0 * (1.0 - transition_fading)),1.0,TimeNoon)))* (50*(pow(1-density, 100.0))) * mix(1.0,0.25,1.0 - transition_fading) * 1.5 * (1-(TimeMidnight * transition_fading)) * (1-rainx);
		cloudCol += pow(sunlight * mix(3.0,2.5,TimeSunset + TimeSunrise),vec3(mix(3.0 - (1.0 * (1.0 - transition_fading)),1.0,TimeNoon))) * 25 * (1- TimeMidnight);
		cloudCol += moonlight * (50*(pow(1-density, 14.0))) * 70 * transition_fading * (1-rainx);

		cloudCol += pow(sunlight * mix(2.0,5.0,TimeSunset + TimeSunrise),vec3(mix(3.0,1.0,TimeNoon))) * (20*subSurfaceScattering2(sunVec,fposition,50.0)*(pow(1-density, 70.0))) * 2 * (1-(TimeMidnight * transition_fading));
		cloudCol += moonlight * (100*subSurfaceScattering2(moonVec,fposition,30.0)*(pow(1-density, 16.0))) * 50 * mix(1.0,0.25,1.0 - transition_fading);

		cloudCol = mix(cloudCol, sunlight, rainx);
		cloudCol *= (1- (0.5 * TimeMidnight));
		/*--------------------------------*/

			totalcloud /= weight;
			totalcloud = clamp(totalcloud,0.0,1.0);
			return mix(color.rgb,cloudCol * mult,totalcloud * 0.175 * pow(cosT,2.0));
		}
	}
#endif

#ifdef Clouds_HQ
vec3 drawCloud(vec3 fposition,vec3 color) {

vec3 sVector = normalize(fposition);
float cosT = max(dot(normalize(sVector),upVec),0.0);
float McosY = MdotU;
float cosY = SdotU;
float cloudScatteringExposure = 6.0;
	  cloudScatteringExposure += 6.0 * rainStrength;
vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);

vec4 totalcloud = vec4(.0);


vec3 intersection = wVector*((-cameraPosition.y+400.0+400*sqrt(cosT))/(wVector.y));
vec3 iSpos = (gbufferModelView*vec4(intersection,1.0)).rgb;
float cosT2 = pow(0.89,distance(vec2(0.0),intersection.xz)/140);
float rainy = mix(wetness, 1.0f, rainStrength);

float cloudCover	  		  = 1.0;
		float cloudCoverSunrise  = 0.45 * TimeSunrise * (1.0 - rainStrength * 0.7);
		float cloudCoverNoon     = 0.5 * TimeNoon * (1.0 - rainStrength * 0.7);
		float cloudCoverSunset   = 0.45 * TimeSunset * (1.0 - rainStrength * 0.7);
		float cloudCoverMidnight = 0.5 * TimeMidnight * (1.0 - rainStrength * 0.7);
		float cloudCoverRain     = 0.1 * rainStrength;
			  cloudCover *= cloudCoverSunrise + cloudCoverNoon + cloudCoverSunset + cloudCoverMidnight + cloudCoverRain;
#ifdef Clouds_HQ_fpsBoost
for (int i = 0;i<5;i++) {
#else
for (int i = 0;i<11;i++) {
#endif
	intersection = wVector*((-cameraPosition.y+300.0-i*3.*(1+cosT2*cosT2*3.5)+500*sqrt(cosT2))/(wVector.y)); 			//curved cloud plane
	vec3 wpos = tpos.xyz+cameraPosition;
	vec2 coord1 = (intersection.xz+cameraPosition.xz)/1000.0/140.+wind[0]*0.063;
	vec2 coord = fract(coord1/2.0);
	
	float noise = texture2D(noisetex,coord + frameTimeCounter / 40000.0).x;
		  noise += texture2D(noisetex,coord*3.5- wind[0] * 0.15 * 0.5).x/3.5;
		  noise += texture2D(noisetex,coord*12.25- wind[0] * 0.15 * 0.5).x/12.25;
		  noise += texture2D(noisetex,coord*42.87- wind[0] * 0.15 * 0.5).x/42.87;
		  noise += texture2D(noisetex,coord*66.57- wind[0] * 0.15 * 0.5).x/66.57;	
		  noise /= 1.4472;

	float cl = max(noise - cloudCover, 0.0);
 #ifdef Clouds_HQ_fpsBoost
	float density = max(1.0 - cl * 0.1, 0.) * max(1.0 - cl *0.1,0.)*(i/5.0)*(i/5.0);
	 #else
	float density = max(1.0 - cl * 1.5, 0.) * max(1.0 - cl *1.5,0.)*(i/11.)*(i/11.);
 #endif
	vec3 c =(ambient_color + mix(sunlight,length(sunlight)*vec3(3.25,3.32,3.4),rainStrength)*sunVisibility + mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength) * moonVisibility) * 0.12 *density + (24.*subSurfaceScattering(sunVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fragpos,0.1)*pow(density,2.))*mix(sunlight,length(sunlight)*vec3(2.25,2.32,2.4),rainStrength)*sunVisibility +  (24.*subSurfaceScattering(moonVec,fragpos,10.0)*pow(density,3.) + 10.*subSurfaceScattering2(moonVec,fragpos,0.1)*pow(density,2.))*mix(moonlight,length(moonlight)*vec3(0.25,0.32,0.4),rainStrength)*moonVisibility;
		 c += (cloudScatteringExposure*subSurfaceScattering(sunVec,fragpos,5.0)*pow(density,3.) + 10.*subSurfaceScattering2(sunVec,fragpos,0.1)*pow(density,2.)) * mix(sunlight, length(sunlight) * vec3(0.25,0.32,0.4), rainStrength);
		 c += (cloudScatteringExposure*subSurfaceScattering(moonVec,fragpos,5.0)*pow(density,3.) + 5.*subSurfaceScattering2(moonVec,fragpos,0.1)*pow(density,2.)) * sunlight * moonVisibility;
	
	cl = max(cl-(abs(i-8.0)/8.)*0.15,0.)*0.08;
	
	totalcloud += vec4(c.rgb*exp(-totalcloud.a),cl);
	totalcloud.a = min(totalcloud.a,1.0);
	
	if (totalcloud.a > 0.999) break;
	}
	return mix(color.rgb,totalcloud.rgb*(1 - rainStrength*0.87)*33.7,totalcloud.a*pow(cosT2,1.2));
}
#endif

#ifdef Stars
vec3 drawStar(vec3 fposition,vec3 color) {
vec3 sVector = normalize(fposition);
float cosT = dot(sVector,upVec);
float McosY = MdotU;
float cosY = SdotU;
//star generation

vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition,1.0));
vec3 wvec = normalize(tpos);
vec3 wVector = normalize(tpos);
vec3 intersection = wVector*(50.0/(wVector.y));

	vec2 wind = vec2(abs(frameTimeCounter/1000.-0.5),abs(frameTimeCounter/1000.-0.5));
	
	vec3 wpos = tpos.xyz+cameraPosition;
	intersection.xz = intersection.xz + 5.0*cosT*intersection.xz;		//curve the star pattern, because sky is not 100% plane in reality
	vec2 coord = (intersection.xz+wind*10)/512.0;
	vec2 coord1 = (intersection.xz+wind*10)/512.0;
	float noise = texture2D(noisetex,fract(coord.xy/2.0)).x;

	  float N = 8.0;
	vec3 star_color = vec3(1.0, 1.0, 1.0)*1.0*moonVisibility*(1-rainStrength) + moonlight*48.0*pow(max(McosY,0.0),N)*(N+1)/6.28  * (1-rainStrength)*moonVisibility ;	//coloring stars

	noise += texture2D(noisetex,fract(coord.xy)).x/2.0;
	noise += texture2D(noisetex,fract(coord1.xy)).x/2.0;

	float cl = max(noise-1.7,0.0);
	float ef = 0.01;
 
    float star2 = (1.0 - (pow((1-rainStrength*0.9)*ef,cl)))*max(cosT,0.0);
	  
	  
vec3 star = mix(color,star_color,star2);

return star;
}
#endif

vec4 raytraceGround(vec3 fragpos, vec3 normal) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
    vec3 rvector = normalize(reflect(normalize(fragpos), normalize(normal)));
    vec3 vector = Gstp * rvector;
    vec3 oldpos = fragpos;
    fragpos += vector;
	vec3 tvector = vector;
    int sr = 0;
    for(int i=0;i<30;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
		if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 spos = vec3(pos.st, texture2D(depthtex1, pos.st).r);
			 spos = nvec3(gbufferProjectionInverse * nvec4(spos * 2.0 - 1.0));
        float err = distance(fragpos.xyz,spos.xyz);
        if(err < length(vector)){

                sr++;
                if(sr >= maxf){
                    float border = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
                    color = texture2D(composite, pos.st);
					color.rgb = calcFog(spos,pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE);
					color.a = 1.0;
                    color.a *= border;
                    break;
                }
				tvector -=vector;
                vector *=Gref; 
}
        vector *= Ginc;
        oldpos = fragpos;
        tvector += vector;
		fragpos = start + tvector;
    }
    return color;
}


vec3 vlColor(vec3 fogcolor, float land) {
if (isEyeInWater > 0.9) {
    } else if(rainStrength > 0.9){
    } else {

	float VolumeSample = texture2DLod(gdepth, texcoord.st, 2.5f).a;
	
	float eyeBS = mix(1.0f, 0.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
	
	vec3 vlDay = vec3(sunlight) * NOON * TimeNoon;
	vec3 vlNight = vec3(sunlight)* NIGHTs * TimeMidnight;
	
	vec3 vlDay_SET = vec3(sunlight) * SUNRISEnSET * TimeSunset;
	vec3 vlDay_RISE = vec3(sunlight) * SUNRISEnSET * TimeSunrise;
	
	vec3 vlDayIN = vec3(sunlight)*IN_SIDE_RAYS;//*(1-land*0.75) * TimeNoon;;
		
	vec3 vlDayIN_NIGHT = vec3(moonlight2) * IN_SIDE_RAYS_NIGHT*(1-land*0.25) * TimeMidnight;
	
	float Atmosphere = 1-(pow(max(dot(normalize(fragpos),lightVector),0.0),1.5)*transition_fading);
		  Atmosphere *= 1-(pow(max(dot(normalize(fragpos),-lightVector),0.0),5.0)*transition_fading)*(1-TimeSunrise)*(1-TimeSunset)*(1-moonVisibility);
	
	vec3 atmosphere = ((fogcolor*sqrt(sunlight*sunlight))+sunlight*0.05)*(Atmosphere)*(1-moonVisibility);
	
	vec3 vlcolor = vec3 (vlDay) * atmosphere;
		 vlcolor += vec3 (vlDay_SET) * atmosphere;  
		 vlcolor += vec3 (vlDay_RISE) * atmosphere;
		 vlcolor += vec3 (vlNight);
		
	vec3 InVlcolor = vec3 (vlDayIN)*atmosphere;
		 InVlcolor *= eyeBS;
		 
	vec3 InVlcolorN = vec3 (vlDayIN_NIGHT);
		 InVlcolorN *= eyeBS;
	
		return ((vlcolor + InVlcolor + InVlcolorN) * vec3(VolumeSample)) * 0.25 * VL_MULT * pow(1-rainStrength, 2.0f);
	}
}

vec3 GetSSGodrays(){
if (isEyeInWater > 0.9) {
	
	} else {
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		 tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	float gr = 0.0;

	float truepos = pow(clamp(dot(-lightVector,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.25);
	if (truepos > 0.05) {
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
			 deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float illuminationDecay = 1.0;
		float illuminationDecayMOON = 1.0;
		
		vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));

		float gr = 0.0;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);
		illuminationDecayMOON = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);
		
		#ifdef VOLUMETRIC_LIGHT
			illuminationDecay *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
		#endif
		
		float fallof = 1.0;
				
		for(int i=0; i < NUM_SAMPLES ; i++) {
		fallof *= 0.85;
				textCoord -= deltaTextCoord;
				float sample = texture2DLod(gdepth, textCoord + noise*grnoise,3).r;
				gr += sample*fallof;
		}
		color.rgb += mix(sunlight,getFogColor(fragpos.xyz),rainStrength)*exposure*(gr/NUM_SAMPLES)*(1.0 - rainStrength*0.8)*illuminationDecay*truepos*transition_fading;
		color.rgb += (mix(sunlight,getFogColor(fragpos.xyz),rainStrength)*MOONexposure*(gr/NUM_SAMPLES)*(1.0 - rainStrength*0.8)*illuminationDecayMOON*truepos*transition_fading)*TimeMidnight;
	}
	else
	tpos = vec4(-sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	pos1 = tpos.xy/tpos.z;
	lightPos = pos1*0.5+0.5;
	truepos = pow(clamp(dot(-moonVec,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);
		if (truepos > 0.01 && moonVisibility > 0.01) {	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
			 deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float illuminationDecay = 1.0;
		vec2 noise = vec2(getnoise(textCoord),getnoise(-textCoord.yx+0.05));
		gr = 0.0;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		illuminationDecay = pow(max(1.0-sqrt(distx*distx+disty*disty),0.0),5.0);
		
		#ifdef VOLUMETRIC_LIGHT
			illuminationDecay *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
		#endif
		
			float fallof = 1.0;
		for(int i=0; i < NUM_SAMPLES ; i++) {
		fallof *= 0.85;
				textCoord -= deltaTextCoord;
				float sample = texture2DLod(gdepth, textCoord + noise*grnoise,3).r;
				gr += sample*fallof;
		}
		color.rgb += mix(moonlight,getFogColor(fragpos.xyz),rainStrength)*MOONexposure*(gr-0.0)*(1.0 - rainStrength*0.8)*illuminationDecay*truepos*moonVisibility;
	}
	}
return color.rgb;
	}
	
float Blinn_Phong(vec3 lvector, vec3 normal, float gloss, in vec3 fragpos, float glossyNess, in float skyLightMap)  {
	vec3 lightDir = vec3(lvector);

	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
		  cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);

	vec3 viewDirection = normalize(fragpos.xyz);

	vec3 halfAngle = normalize(lightDir - viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);

	float normalDotEye = dot(normal, normalize(fragpos.xyz));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
		  fresnel = fresnel*0.5 + 0.5 * (1.0-fresnel);

	float pi = 3.1415927;
	float n =  pow(glossyNess,gloss*14.0);
	return clamp((pow(blinnTerm, n )*((n+8.0)/(8*pi))) * pow(skyLightMap, 50.0), 0.0, 1.0);
}
	
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	color.rgb = pow(color.rgb,vec3(2.2))*MAX_COLOR_RANGE;
	int land = int(matflag < 0.03);
	int iswater = int(matflag > 0.04 && matflag < 0.07);
	int hand  = int(matflag > 0.75 && matflag < 0.85);
	
	fragpos = nvec3(gbufferProjectionInverse * nvec4(fragpos * 2.0 - 1.0));
	vec3 tfpos = fragpos.xyz;
	

	if (land > 0.9) fragpos = (gbufferModelView*(gbufferModelViewInverse*vec4(fragpos,1.0)+vec4(.0,max(cameraPosition.y-70.,.0),.0,.0))).rgb;
	vec3 uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(texcoord.xy,texture2D(depthtex1,texcoord.xy).x) * 2.0 - 1.0));		//underwater position	

	vec3 fogclr = getSkyColor(fragpos.xyz);
	vec3 fogclrVL = getSkyColor(fragpos.xyz);
		 fogclrVL *= mix(1.0f, 0.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));

	float cosT = dot(normalize(fragpos),upVec);
	float torchDistance = 15.0f;
	float torchHandlightDistance = 11.0f;
	float torch_lightmap = pow(aux.b,torchDistance);
	
	vec3 torchcolor = vec3(1.85,1.85,1.85);
	vec3 Torchlight_lightmap = (torch_lightmap+0.0*pow(max(torchHandlightDistance-length(fragpos.xyz),0.0)/torchHandlightDistance,5.0)*max(dot(-fragpos.xyz,normal),0.0)) *  torchcolor;
	uPos.z = mix(uPos.z,2000.0*(0.25+sunVisibility*0.75),land);
	
	vec3 color_torchlight = Torchlight_lightmap;
	
#ifdef MOTIONBLUR
if (isEyeInWater > 0.9) {
	
	} else {
	vec4 depth  = texture2D(depthtex2, texcoord.st);
	
	vec4 currentPosition = vec4(texcoord.x * 2.0f - 1.0f, texcoord.y * 2.0f - 1.0f, 2.0f * depth.x - 1.0f, 1.0f);
	
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
		 fragposition = gbufferModelViewInverse * fragposition;
		 fragposition /= fragposition.w;
		 fragposition.xyz += cameraPosition;
	
	
	vec4 previousPosition = fragposition;
		 previousPosition.xyz -= previousCameraPosition;
		 previousPosition = gbufferPreviousModelView * previousPosition;
		 previousPosition = gbufferPreviousProjection * previousPosition;
		 previousPosition /= previousPosition.w;
	
	vec2 velocity = (currentPosition - previousPosition).st * MOTIONBLUR_AMOUNT;

	int samples = 1;

	vec2 coord = texcoord.st + velocity;
		 coord = clamp(coord, 1.0 / vec2(viewWidth, viewHeight), 1.0 - 1.0 / vec2(viewWidth, viewHeight));
	for (int i = 0; i < 8; ++i, coord += velocity) {
		if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) {
			break;
		}
            color += texture2D(composite, coord),color.rgb, iswater;
			++samples;
	}

	color.rgb *= 25.0;
	
	//Colour Properties
		float Tonemap_Contrast 		= 1.3;
		float Tonemap_Saturation 	= 1.4; 
		float Tonemap_Decay			= 20.0;
		float Tonemap_Curve			= 65.0;
	
	vec3 colorN = normalize(color.rgb);
	
	vec3 clrfr = color.rgb/colorN.rgb;
	     clrfr = pow(clrfr.rgb, vec3(Tonemap_Contrast));
		 
	colorN.rgb = pow(colorN.rgb, vec3(Tonemap_Saturation));
	
	color.rgb = clrfr.rgb * colorN.rgb;

	color.rgb = (color.rgb * (1.0 + color.rgb/Tonemap_Decay))/(color.rgb + Tonemap_Curve)/samples;
}	
#endif	
	
	
	color.rgb = drawSun(fragpos,color.rgb,land);

	
		float fresnel_pow = 4.0+(1-specular.b)*1.0;
		float normalDotEye = dot(normal, normalize(fragpos));
		float fresnel = clamp(pow(1.0 + normalDotEye, fresnel_pow),0.0,1.0);
		float fresnel_SPEC = clamp(pow(1.0 + normalDotEye, 1.0),0.0,1.0);

		float fmult = 0.95;
		fresnel = fresnel*fmult + (1-fmult);
		vec4 reflection = vec4(0.0);
		vec3 lc = mix(vec3(0.0),sunlight,sunVisibility);

#ifdef WATER_REFLECTIONS		
if (iswater > 0.9) {
//compute skybox at reflected position
		
		vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
			 reflectedVector = fragpos + reflectedVector * (far-fragpos.z);
		
/*--------------------------------*/
#ifdef Clouds_HQ	
		#ifdef Clouds_LQ
		vec3 sky_color = calcFog(reflectedVector,drawClouds(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
	#else
		vec3 sky_color = calcFog(reflectedVector,drawCloud(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
		#endif
		
#else
	
		vec3 sky_color = calcFog(reflectedVector,(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
#endif
/*--------------------------------*/

		reflection = raytrace(fragpos, normal);
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*lc*(1.0-rainStrength)*48.0;			//fake sky reflection, avoid empty spaces
		reflection.a = min(reflection.a,1.0);
		if (iswater > 0.9)
		color.rgb = reflection.rgb*REFLECTION_STRENGTH *fresnel + (1-fresnel)*color.rgb;
}
#endif	
	
#ifdef Rain_Puddles
if (rainStrength > 0.9) {
	vec3 Refl;
	vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
			 reflectedVector = fragpos + reflectedVector * (far-fragpos.z);
		
#ifdef Clouds_HQ	
	#ifdef Clouds_LQ
		vec3 sky_color = calcFog(reflectedVector,drawClouds(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
	#else
		vec3 sky_color = calcFog(reflectedVector,drawCloud(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
	#endif
		
#else
	
		vec3 sky_color = calcFog(reflectedVector,(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
#endif
		
		npos = normalize(fragpos);
		reflectedVector = reflect(normalize(fragpos), normalize(normal));
			 reflectedVector = fragpos + reflectedVector * (far-length(fragpos));
		sky_color = calcFog(reflectedVector,(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
		
		if(fresnel_SPEC > 0.002) {
		reflection = raytraceGround(fragpos, normal);
		
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*lc*(1.0-rainStrength)*24.0;		
		reflection.rgb = mix(reflection.rgb,reflection.rgb*normalize(color.rgb),0.5);
		reflection.a = min(reflection.a,1.0);
		reflection.rgb = reflection.rgb/5.;
		color.rgb = fresnel_SPEC*reflection.rgb*clamp(pow(iswet, 10.0), 0.0, 1.0)*(1.0-specmap) * (getRainPuddles(fragpos) + 0.1 * getRainPuddles(fragpos)) + (1-fresnel_SPEC/5)*color.rgb;
		color.rgb += (fresnel_SPEC*Rain_Puddles_Strength*reflection.rgb*clamp(pow(iswet, 10.0), 0.0, 1.0)*(1.0-specmap) * (getRainPuddles(fragpos) + 0.1 * getRainPuddles(fragpos)) + ((1-fresnel_SPEC/5)*clamp(pow(iswet, 10.0), 0.0, 1.0)*(1.0-specmap))*color.rgb)* (TimeMidnight * transition_fading);
		}
	}
#endif	
	
#ifdef SPECULAR_MAPPING	
	if (land < 0.9 && hand < 0.1 && rainStrength > 0.9) {

		vec3 npos = normalize(fragpos);
		vec3 reflectedVector = reflect(normalize(fragpos), normalize(normal));
			 reflectedVector = fragpos + reflectedVector * (far-length(fragpos));
		vec3 sky_color = calcFog(reflectedVector,(reflectedVector,getSkyColor(reflectedVector)))*clamp(sky_lightmap*2.0-2/16.0,0.0,1.0);
		
		if(specmap*fresnel_SPEC > 0.002) 
		reflection = raytraceGround(fragpos, normal);
		
		reflection.rgb = mix(sky_color, reflection.rgb, reflection.a)+(color.a)*lc*(1.0-rainStrength);		
		reflection.rgb = mix(reflection.rgb,reflection.rgb*normalize(color.rgb),0.5);
		reflection.a = min(reflection.a,1.0);
		reflection.rgb = reflection.rgb/5.;
	#ifdef Rain_Puddles	
		if (specular.g > 0.0) {
		color.rgb = specmap*fresnel_SPEC*reflection.rgb + (1-fresnel_SPEC*specmap/2)*color.rgb;
		//color.rgb += (specmap*fresnel_SPEC*50*reflection.rgb + (1-fresnel_SPEC*specmap/2)*color.rgb)* (TimeMidnight * transition_fading);
		}
		#else
		color.rgb = specmap*fresnel_SPEC*reflection.rgb*clamp(pow(iswet, 10.0), 0.0, 1.0)*(1.0-specmap) + (1-fresnel_SPEC*specmap/2)*color.rgb;
		color.rgb += (specmap*fresnel_SPEC*20*reflection.rgb*clamp(pow(iswet, 10.0), 0.0, 1.0)*(1.0-specmap) + (1-fresnel_SPEC*specmap/2)*color.rgb)* (TimeMidnight * transition_fading);
	
	#endif
	}
#endif
	
#ifdef Clouds_HQ	
vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
	 fragposition /= fragposition.w;
 
 vec4 worldposition = vec4(0.0);
	  worldposition = gbufferModelViewInverse * fragposition;
 
 float horizon = (worldposition.y - texcoord.y);

	if (land > 0.1 && hand < 0.1 && horizon > 0.9) {
			if (cosT > 0.0) color.rgb = drawCloud(tfpos.xyz,color.rgb);
}
#endif

#ifdef Clouds_LQ	
	if (land > 0.9)	
		color.rgb = drawClouds(fragpos.xyz,color.rgb,10.0);
#endif

#ifdef Stars
	if (land > 0.9 && moonVisibility > 0.1) 
		color.rgb = drawStar(fragpos.xyz,color.rgb);
#endif
	
	vec3 colmult = mix(vec3(1.0),vec3(0.1,0.25,0.45),isEyeInWater);
	float depth_diff = clamp(pow(ld(texture2D(depthtex0, texcoord.st).r)*3.4,2.0),0.0,1.0);
	color.rgb = mix(color.rgb*colmult,vec3(0.05,0.1,0.15),depth_diff*isEyeInWater);
	
#ifdef Rain_Fog	
	color.rgb = calcFog(fragpos.xyz,color.rgb);
#endif
	
#ifdef UNDERWATER_FOG	
	color.rgb += calcWFog(fragpos.xyz,color.rgb);
#endif

#ifdef VOLUMETRIC_LIGHT	
	vec3 vlfogclr = mix(gl_Fog.color.rgb,vec3(0.2,0.2,0.2),rainStrength)*vlAmbient;
		 vlfogclr.rgb = vlfogclr.rgb*(0.75*(1-moonVisibility));
		 vlfogclr = mix(color.rgb,vlAmbient,0.6+ clamp((20000*moonVisibility), 0.0, 0.25))*(1.0-rainStrength)*(1.0-moonVisibility*0.9)*(1-TimeSunrise*-.25)*(1-TimeNoon*-.5);
		 vlfogclr.g -= vlfogclr.g*0.15;
		 vlfogclr.rb -= vlfogclr.rb*0.1*(TimeSunrise+TimeSunset);
		 vlfogclr *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
	
	color.rgb += vec3(vlColor(vec3(vlfogclr), land));
	color.rgb += vec3(vlColor(vec3(fogclrVL), land));
#endif
	
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows
	
/* DRAWBUFFERS:5 */
	
	//draw rain
	color += texture2D(gaux4,texcoord.xy).a*0.05;
	
	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		 tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
	float visiblesun = 0.0;
	float temp;
	float nb = 0;
	
//calculate sun occlusion (only on one pixel) 
	if (texcoord.x < pw && texcoord.x < ph) {
		for (int i = 0; i < 10;i++) {
			for (int j = 0; j < 10 ;j++) {
			temp = texture2D(gaux1,lightPos + vec2(pw*(i-5.0),ph*(j-5.0))*10.0).g;
			visiblesun +=  1.0-float(temp > 0.04) ;
			nb += 1.0;
		}
	}
	visiblesun /= nb;
}
#ifdef GODRAYS
	color.rgb = GetSSGodrays();
#endif
	color.rgb = clamp(pow(color.rgb/MAX_COLOR_RANGE,vec3(1.0/2.2)),0.0,1.0);
	

	gl_FragData[0] = vec4(color.rgb,visiblesun);
}