#version 120

const bool 		shadowtex1Mipmap = true;
const bool 		shadowtex1Nearest = false;
#define MAX_COLOR_RANGE 45.0


/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//to increase shadow draw distance, edit shadowDistance and SHADOWHPL below. Both should be equal. Needs decimal point.
//disabling is done by adding "//" to the beginning of a line.

//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//////////////////////////////ADJUSTABLE VARIABLES
//#define OldColor_Tonemap			//Returns the Tonemap Colours Back to V4.1
//----------Shadows----------//
	const int shadowMapResolution = 2048;		// Shadow Resolution. 512 = Lowest Quality. 4096 = Highest Quality [512 1024 2048 3072 4096]
	const float shadowDistance = 140;		// shadowDistance. 60 = Lowest Quality. 200 = Highest Quality [60 80 110 100 120 140 160 180 200]
	
	#ifdef OldColor_Tonemap	
	#define SHADOW_DARKNESS 0.20				//shadow darkness levels, lower values mean darker shadows, see .vsh for colors /0.25 is default
	#else
	#define SHADOW_DARKNESS 0.11				//shadow darkness levels, lower values mean darker shadows, see .vsh for colors /0.25 is default
	#endif
	
	//#define HQ_SHADOW_FILTER					// set SUNLIGHTAMOUNT to 5.0 when using
	#define VARIABLE_PENUMBRA_SHADOWS		// This is similar to PCSS but not as accurate   
	
	//#define SOFT_SHADOWS						//smooth shadows 
//----------End of Shadows----------//

//----------Lighting----------//
	#define DYNAMIC_HANDLIGHT				//This enables torches and glowstones in players had to cast light

	#define SUNLIGHTAMOUNT 10				//[1 2 3 4 5 6 7 8 9 10 11 12 13] //change sunlight strength
	
	#define Light_Jitter					//This makes torch light flicker to simulate the inconsistent light that fire would produce 
	
	//Minecraft lightmap (used for sky)
	#define ATTENUATION 3.0
	#define MIN_LIGHT 0.0095
	
	#define Pseudo_hdr						//This is to simulate your eyes adapting to different light amounts
	#define NIGHT_EXPOSURE 0.85f
	
	#define NIGHT_LIGHT_Desaturation				//used to desaturate color at night but affects torch color, still needs work

//----------End of Lighting----------//

//----------Visual----------//
#define GODRAYS									//These are 2D screenspace godrays
		const float density = 0.55;			
		const int NUM_SAMPLES = 5;				//increase this for better quality at the cost of performance /5 is default
		const float grnoise = 1.0;			//amount of noise /0.012 is default
	
//#define SSAO								//Screen Space Ambient Occlusion, taxing on fps
		//SSAO constants
		const int nbdir = 5;					//the two numbers here affect the number of sample used. Increase for better quality at the cost of performance /6 and 6 is default
		const float sampledir = 8;	
		const float ssaorad = 0.7;				//radius of ssao shadows /1.0 is default
	
#define WATER_CAUSTIC							//Fake caustics, to simulate light rays reflected or refracted through water on the surface	
		#define CAUSTIC_STRENGHT 0.75
		#define CAUSTIC_SIZE 1.5
#define Water_TempFix							//This is to shadow map getting messed up while underwater


//***************************VOLUMETRIC LIGHT***************************//
	#define VOLUMETRIC_LIGHT					//True Godrays, this is not Screen Space and is Based off Robobo's shader VL
		#define VL_QUALITY 	2.0			  		// Quality of the Volumetric Light. 1.0 is default, 10.0 recommended for quality, 20.0 best quality you can get. But eats a lot of FPS.
		#define VOL_DISTANCE 50					// set the distance Vol Light will be calculated
//***************************BUILD IN FUNCTIONS***************************//		
		
	
	//#define CELSHADING						
		#define BORDER 1.0

	const float	sunPathRotation	= -40.0f;		//determines sun/moon inclination /-40.0 is default - 0.0 is normal rotation
//----------End of Visual----------//

//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
//////////////////////////////END OF ADJUSTABLE VARIABLES
const float 	eyeBrightnessHalflife 	= 10.f;
const bool 		gdepthMipmapEnabled 	= true;

const float 	wetnessHalflife 		= 70.0f;
const float 	drynessHalflife 		= 70.0f;

const float 	centerDepthHalflife 	= 4;

const int 		RGB8				= 1;
const int 		RGBA8 				= 2;
const int 		RGB16 				= 1;
const int 		RGBA16 				= 1;

const int 		gdepthFormat 			= RGBA16;
const int 		gcolorFormat 			= RGBA8;
const int 		gnormalFormat 			= RGB16;

const int 		compositeFormat 		= RGBA16;
const bool 		shadowHardwareFiltering0 = true;

const float 	shadowIntervalSize 		= 4.0f;
const int 		noiseTextureResolution  = 720;
#define SHADOW_MAP_BIAS 0.85

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying float SdotU;
varying float MdotU;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;
varying vec3 torchcolor;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 nsunlights;

varying float handItemLight;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeMidnight;
varying float timeSkyDark;

varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D gcolor;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D gnormal;
uniform sampler2D gaux3;
uniform sampler2DShadow shadow;
uniform sampler2D shadowtex1;
uniform sampler2D gaux1;
uniform sampler2D noisetex;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 cameraPosition;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;

// Remove the // for DOF_HQ
uniform float centerDepthSmooth;

uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;

float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);


vec3 convertScreenSpaceToWorldSpace(vec2 co, float depth) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, depth) * 2.0 - 1.0, 1.0);
		 fragposition /= fragposition.w;
  return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
    return screenSpace;
}

float luma(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}


vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}

vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}

float edepth(vec2 coord) {
	return texture2D(depthtex0,coord).z;
}

float PosDot(vec3 v1,vec3 v2) {
return max(dot(v1,v2),0.0);
}

float getnoise(vec2 pos) {
	return abs(fract(sin(dot(pos ,vec2(18.9898f,28.633f))) * 4378.5453f));
}

float subSurfaceScattering(vec3 pos, float N) {

return pow(max(dot(lightVector,normalize(pos)),0.0),N)*(N+1)/6.28;

}

float distx(float dist){
	float d = ((far * (dist - near)) / (dist * (far - near)));
	return d;
}

void 	DoNightLight(inout vec3 color) {			//Desaturates any color input at night, also adds a blueish tint

	float amount = 2.2f; 						//How much will the new desaturated and tinted image be mixed with the original image
	
	vec3 NightColor = vec3(0.25f, 0.25f, 0.25f);	
	float colorDesat = dot(color, vec3(0.5f)); 	//Desaturated color

	color = mix(color, vec3(colorDesat) * NightColor, TimeMidnight * amount);

}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;

vec3 fragpos = vec3(texcoord.st, texture2D(depthtex0, texcoord.st).r);

vec3 aux = texture2D(gaux1, texcoord.st).rgb;

vec3 normal = texture2D(gnormal, texcoord.st).rgb * 2.0f - 1.0f;

float pixeldepth = texture2D(depthtex0,texcoord.xy).x;
float pixeldepthW = texture2D(depthtex1,texcoord.xy).x;
float handlight = handItemLight;

#ifdef Light_Jitter
const float speed = 2.5;
float light_jitter = 1.0-sin(frameTimeCounter*1.4*speed+cos(frameTimeCounter*5.9*speed))*0.0071;
float light_jitter2 = 1.0-sin(frameTimeCounter*1.4*speed+cos(frameTimeCounter*1.9*speed))*0.00723;
float torch_lightmap = pow(aux.r,1.0 * light_jitter * light_jitter2);
#else
float torch_lightmap = pow(aux.r,1.0);
#endif

float sky_lightmap = pow(aux.r,ATTENUATION);

float iswet = wetness*pow(sky_lightmap,5.0)*sqrt(0.5+max(dot(normal,normalize(upPosition)),0.0));
	
vec3 specular = texture2D(gaux3,texcoord.xy).rgb;

									
const vec2 shadow_offsets[60] = vec2[60]  (  vec2(0.06120777f, -0.8370339f),
								vec2(0.09790099f, -0.5829314f),
								vec2(0.247741f, -0.7406831f),
								vec2(-0.09391049f, -0.9929391f),
								vec2(0.4241214f, -0.8359816f),
								vec2(-0.2032944f, -0.70053f),
								vec2(0.2894208f, -0.5542058f),
								vec2(0.2610383f, -0.957112f),
								vec2(0.4597653f, -0.4111754f),
								vec2(0.1003582f, -0.2941186f),
								vec2(0.3248212f, -0.2205462f),
								vec2(0.4968775f, -0.6096044f),
								vec2(0.770794f, -0.5416877f),
								vec2(0.6429226f, -0.261653f),
								vec2(0.6138752f, -0.7684944f),
								vec2(-0.06001971f, -0.4079638f),
								vec2(0.08106154f, -0.07295965f),
								vec2(-0.1657472f, -0.2334092f),
								vec2(-0.321569f, -0.4737087f),
								vec2(-0.3698382f, -0.2639024f),
								vec2(-0.2490126f, -0.02925519f),
								vec2(-0.4394466f, -0.06632736f),
								vec2(-0.6763983f, -0.1978866f),
								vec2(-0.5428631f, -0.3784158f),
								vec2(-0.3475675f, -0.9118061f),
								vec2(-0.1321516f, 0.2153706f),
								vec2(-0.3601919f, 0.2372792f),
								vec2(-0.604758f, 0.07382818f),
								vec2(-0.4872904f, 0.4500539f),
								vec2(-0.149702f, 0.5208581f),
								vec2(-0.6243932f, 0.2776862f),
								vec2(0.4688022f, 0.04856517f),
								vec2(0.2485694f, 0.07422727f),
								vec2(0.08987152f, 0.4031576f),
								vec2(-0.353086f, 0.7864715f),
								vec2(-0.6643087f, 0.5534591f),
								vec2(-0.8378839f, 0.335448f),
								vec2(-0.5260508f, -0.7477183f),
								vec2(0.4387909f, 0.3283032f),
								vec2(-0.9115909f, -0.3228836f),
								vec2(-0.7318214f, -0.5675083f),
								vec2(-0.9060445f, -0.09217478f),
								vec2(0.9074517f, -0.2449507f),
								vec2(0.7957709f, -0.05181496f),
								vec2(-0.1518791f, 0.8637156f),
								vec2(0.03656881f, 0.8387206f),
								vec2(0.02989202f, 0.6311651f),
								vec2(0.7933047f, 0.4345242f),
								vec2(0.3411767f, 0.5917205f),
								vec2(0.7432346f, 0.204537f),
								vec2(0.5403291f, 0.6852565f),
								vec2(0.6021095f, 0.4647908f),
								vec2(-0.5826641f, 0.7287358f),
								vec2(-0.9144157f, 0.1417691f),
								vec2(0.08989539f, 0.2006399f),
								vec2(0.2432684f, 0.8076362f),
								vec2(0.4476317f, 0.8603768f),
								vec2(0.9842657f, 0.03520538f),
								vec2(0.9567313f, 0.280978f),
								vec2(0.755792f, 0.6508092f));
									
	
const vec2 shadow_offsetss[60] = vec2[60]  (  vec2(0.06120777f, -0.8370339f),
								vec2(0.09790099f, -0.5829314f),
								vec2(0.247741f, -0.7406831f),
								vec2(-0.09391049f, -0.9929391f),
								vec2(0.4241214f, -0.8359816f),
								vec2(-0.2032944f, -0.70053f),
								vec2(0.2894208f, -0.5542058f),
								vec2(0.2610383f, -0.957112f),
								vec2(0.4597653f, -0.4111754f),
								vec2(0.1003582f, -0.2941186f),
								vec2(0.3248212f, -0.2205462f),
								vec2(0.4968775f, -0.6096044f),
								vec2(0.770794f, -0.5416877f),
								vec2(0.6429226f, -0.261653f),
								vec2(0.6138752f, -0.7684944f),
								vec2(-0.06001971f, -0.4079638f),
								vec2(0.08106154f, -0.07295965f),
								vec2(-0.1657472f, -0.2334092f),
								vec2(-0.321569f, -0.4737087f),
								vec2(-0.3698382f, -0.2639024f),
								vec2(-0.2490126f, -0.02925519f),
								vec2(-0.4394466f, -0.06632736f),
								vec2(-0.6763983f, -0.1978866f),
								vec2(-0.5428631f, -0.3784158f),
								vec2(-0.3475675f, -0.9118061f),
								vec2(-0.1321516f, 0.2153706f),
								vec2(-0.3601919f, 0.2372792f),
								vec2(-0.604758f, 0.07382818f),
								vec2(-0.4872904f, 0.4500539f),
								vec2(-0.149702f, 0.5208581f),
								vec2(-0.6243932f, 0.2776862f),
								vec2(0.4688022f, 0.04856517f),
								vec2(0.2485694f, 0.07422727f),
								vec2(0.08987152f, 0.4031576f),
								vec2(-0.353086f, 0.7864715f),
								vec2(-0.6643087f, 0.5534591f),
								vec2(-0.8378839f, 0.335448f),
								vec2(-0.5260508f, -0.7477183f),
								vec2(0.4387909f, 0.3283032f),
								vec2(-0.9115909f, -0.3228836f),
								vec2(-0.7318214f, -0.5675083f),
								vec2(-0.9060445f, -0.09217478f),
								vec2(0.9074517f, -0.2449507f),
								vec2(0.7957709f, -0.05181496f),
								vec2(-0.1518791f, 0.8637156f),
								vec2(0.03656881f, 0.8387206f),
								vec2(0.02989202f, 0.6311651f),
								vec2(0.7933047f, 0.4345242f),
								vec2(0.3411767f, 0.5917205f),
								vec2(0.7432346f, 0.204537f),
								vec2(0.5403291f, 0.6852565f),
								vec2(0.6021095f, 0.4647908f),
								vec2(-0.5826641f, 0.7287358f),
								vec2(-0.9144157f, 0.1417691f),
								vec2(0.08989539f, 0.2006399f),
								vec2(0.2432684f, 0.8076362f),
								vec2(0.4476317f, 0.8603768f),
								vec2(0.9842657f, 0.03520538f),
								vec2(0.9567313f, 0.280978f),
								vec2(0.755792f, 0.6508092f));
									
	

float Blinn_Phong(vec3 ppos, vec3 lvector, vec3 normal,float fpow, float gloss, float visibility)  {
	vec3 lightDir = vec3(lvector);
	
	vec3 surfaceNormal = normal;
	float cosAngIncidence = dot(surfaceNormal, lightDir);
		  cosAngIncidence = clamp(cosAngIncidence, 0.0, 1.0);
	
	vec3 viewDirection = normalize(-ppos);
	
	vec3 halfAngle = normalize(lightDir + viewDirection);
	float blinnTerm = dot(surfaceNormal, halfAngle);
	
	float normalDotEye = dot(normal, normalize(ppos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 5.0),0.0,1.0);
		  fresnel = fresnel*0.5 + 0.5 * (1.0-fresnel);
	
	float pi = 3.1415927;
	float n =  pow(2.5,gloss*10.0);
	return (pow(blinnTerm, n )*((n+8.0)/(8*pi)))*visibility;
}



#ifdef CELSHADING
vec3 celshade(vec3 clrr) {
	//edge detect
	float d = edepth(texcoord.xy);
	float dtresh = 1/(far-near)/5000.0;	
	vec4 dc = vec4(d,d,d,d);
	vec4 sa;
	vec4 sb;
	sa.x = edepth(texcoord.xy + vec2(-pw,-ph)*BORDER);
	sa.y = edepth(texcoord.xy + vec2(pw,-ph)*BORDER);
	sa.z = edepth(texcoord.xy + vec2(-pw,0.0)*BORDER);
	sa.w = edepth(texcoord.xy + vec2(0.0,ph)*BORDER);
	
	//opposite side samples
	sb.x = edepth(texcoord.xy + vec2(pw,ph)*BORDER);
	sb.y = edepth(texcoord.xy + vec2(-pw,ph)*BORDER);
	sb.z = edepth(texcoord.xy + vec2(pw,0.0)*BORDER);
	sb.w = edepth(texcoord.xy + vec2(0.0,-ph)*BORDER);
	
	vec4 dd = abs(2.0* dc - sa - sb) - dtresh;
	     dd = vec4(step(dd.x,0.0),step(dd.y,0.0),step(dd.z,0.0),step(dd.w,0.0));
	
	float e = clamp(dot(dd,vec4(0.25f,0.25f,0.25f,0.25f)),0.0,1.0);
	return clrr*e;
}
#endif


vec3 getSkyColor(vec3 fposition) {
//sky gradient
/*----------*/
vec3 skycoaa = vec3(0.25f, 0.4f, 1.3f) * 2.0f;
	 skycoaa = mix(skycoaa, vec3(1.0f, 0.9f, 0.5f), vec3(timeSkyDark));
	 skycoaa *= mix(vec3(1.0f), vec3(1.0f, 1.0f, 0.5f), vec3(timeSunrise + timeSunset));

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

//luminance
float mCosT = max(cosT,0.0);
float invRain07 = 1.0-rainStrength*0.6;
float L21 =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;	
const float d2 = -2.5;
float c2 = 4.0;
float Y2 = acos(cosY); 
	 
//gradient
float absCosT2 = 1.0-max(cosT*2.32+0.26,0.2);
vec3 grad1 = mix(sky1,sky2,absCosT2*absCosT2);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlights,sunscat*sunscat*(1.0-mCosT)*(1.0-rainStrength*0.5)*(clamp(-(cosS)*4.0+3.0,0.0,1.0)*0.65+0.35)*0.9+0.1);

//moon sky color
float McosS = dot(moonVec,upVector);
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY);
	  L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.2); //modulate intensity when raining
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength)*L2*0.4 ; //affect color based on luminance (0% physically accurate)
	 skyColormoon *= moonVisibility;


sky_color = skyColormoon+skyColorSun+grad3*pow(L21*(c2*exp(d2*Y2)+A),invRain07)*sunVisibility*vec3(0.85,0.88,1.0);
//sky_color = vec3(Lc);
/*----------*/

return sky_color;
}

float waterH(vec3 posxz) {

float wave = 0.0;

float factor = 1.0;
float amplitude = 0.2;
float speed = 4.0;
float size = 0.2;

float px = posxz.x/50.0 + 250.0;
float py = posxz.z/50.0  + 250.0;

float fpx = abs(fract(px*20.0)-0.5)*2.0;
float fpy = abs(fract(py*20.0)-0.5)*2.0;

float d = length(vec2(fpx,fpy));

	for (int i = 1; i < 8; i++) {
		wave -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
	factor /= 2;
	}

factor = 1.0;
px = -posxz.x/50.0 + 250.0;
py = -posxz.z/150.0 - 250.0;

fpx = abs(fract(px*20.0)-0.5)*2.0;
fpy = abs(fract(py*20.0)-0.5)*2.0;

d = length(vec2(fpx,fpy));
float wave2 = 0.0;
	
	for (int i = 1; i < 8; i++) {
		wave2 -= d*factor*cos( (1/factor)*px*py*size + 1.0*frameTimeCounter*speed);
	factor /= 2;
	}

return amplitude*wave2+amplitude*wave;
}

vec3 getWaterHeight(in vec3 posxz){

		posxz.x += sin(posxz.z+frameTimeCounter)*0.25;
		posxz.z += cos(posxz.x+frameTimeCounter*0.5)*0.25;
		
		float deltaPos = 0.3;
		float h0 = waterH(posxz);
		float h1 = waterH(posxz - vec3(deltaPos,0.0,0.0));
		float h2 = waterH(posxz - vec3(0.0,0.0,-deltaPos));
		float h3 = waterH(posxz - vec3(-deltaPos,0.0,0.0));
		float h4 = waterH(posxz - vec3(0.0,0.0,deltaPos));
		
	
		float dX = ((h1-h0)+(h0-h2))/deltaPos;
		float dY = ((h3-h0)+(h0-h4))/deltaPos;
	
		vec3 wave = normalize(vec3(dX,dY,1.0-pow(abs(dX+dY),2.0)));
		
		return wave;
}

float convertVec3ToFloat(in vec3 invec){

	float mixing;
		mixing += invec.x;
		mixing += invec.y;
		mixing += invec.z;
		mixing /= 3.0;

	return mixing;
}

#ifdef WATER_CAUSTIC

vec3 waterCaustic(vec3 color, float visibility, in float land) {
if (isEyeInWater > 0.09) {
	vec3 underwaterpos = vec3(texcoord.st, texture2D(depthtex1, texcoord.st).r);
		 underwaterpos = nvec3(gbufferProjectionInverse * nvec4(underwaterpos * 2.0 - 1.0));

	vec4 worldpositionuw = gbufferModelViewInverse * vec4(underwaterpos,1.0);
	vec3 wpos = (worldpositionuw.xyz + cameraPosition.xyz);

	vec3 coord = vec3(wpos);

	vec3 caustics = getWaterHeight(coord);

	float getcoustic = convertVec3ToFloat(caustics)/2.0;

	
	float wcaUW = (0.15 * 1.5);
	float caustic = 1-(pow(0.030,clamp(getcoustic,-3.0,10.0)*1.02));
		caustic = pow(caustic, 0.5);
		caustic = clamp(caustic,0.0,1.0);
		
	
	vec3 wc = clamp(mix(color * visibility * wcaUW,vec3(0),caustic * 1.55),0.0,1.0), isEyeInWater;

if (land > 0.9)
	return wc;
	//return -0.1+caustics;
	}
	else{
	vec3 underwaterpos = vec3(texcoord.st, texture2D(depthtex1, texcoord.st).r);
		 underwaterpos = nvec3(gbufferProjectionInverse * nvec4(underwaterpos * 2.0 - 1.0));

	vec4 worldpositionuw = gbufferModelViewInverse * vec4(underwaterpos,1.0);
	vec3 wpos = (worldpositionuw.xyz + cameraPosition.xyz);

	vec3 coord = vec3(wpos);

	vec3 caustics = getWaterHeight(coord);

	float getcoustic = convertVec3ToFloat(caustics)/2.0;

	float wca = (CAUSTIC_STRENGHT * 1.5);
	
	float caustic = 1-(pow(0.030,clamp(getcoustic,-3.0,10.0)*1.02));
		caustic = pow(caustic, 0.5);
		caustic = clamp(caustic,0.0,1.0);
		
	vec3 wc = clamp(mix(color * visibility * wca,vec3(0),caustic * 1.55),0.0,1.0);
		

if (land > 0.9)
	return wc;
	}
	}
#endif



float  	CalculateDitherPatternHRR(vec2 pos, const float sample) {

const int ditherPattern[64] = int[64](
  0, 32, 8, 40, 2, 34, 10, 42, /* 8x8 Bayer ordered dithering */
  48, 16, 56, 24, 50, 18, 58, 26, /* pattern. Each input pixel */
  12, 44, 4, 36, 14, 46, 6, 38, /* is scaled to the 0..63 range */
  60, 28, 52, 20, 62, 30, 54, 22, /* before looking in this table */
  3, 35, 11, 43, 1, 33, 9, 41, /* to determine the action. */
  51, 19, 59, 27, 49, 17, 57, 25,
  15, 47, 7, 39, 13, 45, 5, 37,
  63, 31, 55, 23, 61, 29, 53, 21); 

 vec2 count = vec2(0.0f);
      count.x = floor(mod(texcoord.s * viewWidth, 8.0f));
	  count.y = floor(mod(texcoord.t * viewHeight, 8.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 8];

	return float(dither) / 64.0f;
}

#ifdef VOLUMETRIC_LIGHT
float GetVolumetricRays() {

	///////////////////////Setting up functions///////////////////////
	if (isEyeInWater > 0.9) {
    } else if(rainStrength > 0.9){
		} else {
		float rays;

		float Quality = 4.0 / VL_QUALITY;
		float steps = Quality;

		float ditherPattern = CalculateDitherPatternHRR(texcoord.st, steps);
		ditherPattern *= steps;

		float maxDist = (45.0);
		float minDist = (0.01);
			  minDist += ditherPattern;
			
		float weight = (maxDist / steps);

		vec2 pushback = vec2(0.001, -0.001);	// Fixes light leakage from walls

		for (minDist; minDist < maxDist;) {

		///////////////////////MAKING VL NOT GO THROUGH WALLS///////////////////////

			if (getDepth(pixeldepth) < minDist){
				break;
			}

		///////////////////////Getting worldpositon///////////////////////

			vec4 fragpos = nvec4(convertScreenSpaceToWorldSpace(texcoord.st, distx(minDist)) * 1.0);
			vec4 worldposition = vec4(gbufferModelViewInverse * fragpos);

		///////////////////////Converting ScreenSpace to ShadowSpace///////////////////////

			worldposition = (shadowModelView * worldposition);
			worldposition = (shadowProjection * worldposition);

		///////////////////////Rescaling ShadowMaps///////////////////////

			float distb = sqrt(worldposition.r*worldposition.r + worldposition.g*worldposition.g);
			distb *= SHADOW_MAP_BIAS;
			float distortFactor = 1.0 - SHADOW_MAP_BIAS;
			distortFactor -= distb * - 1.0;

			vec3 pos = worldposition.rgb;
			pos.rg /= (sqrt(distortFactor / distortFactor) * (distortFactor));

		///////////////////////Projecting shadowmaps on a linear depth plane///////////////////////

			rays += (shadow2D(shadow, vec3(pos.rg, pos.b + pushback.r) * 0.5 + 0.5).z);

			minDist = minDist + steps;
	}

	///////////////////////Returning the program///////////////////////

		rays /= weight;
		rays *= 0.15;

		return (rays, clamp(rays * 2.5, 0.0, 0.1));
		//return rays;
	}
}

#else
float GetVolumetricRays(){

	return 0.0;
}
#endif

float GetScreenSpaceRays() {
float gr = 0.0;

	vec4 tpos = vec4(sunPosition,1.0)*gbufferProjection;
		 tpos = vec4(tpos.xyz/tpos.w,1.0);
	vec2 pos1 = tpos.xy/tpos.z;
	vec2 lightPos = pos1*0.5+0.5;
	
	float truepos = pow(clamp(dot(-sunVec,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);		//temporary fix that check if the sun/moon position is correct
	if (truepos > 0.01 && sunVisibility > 0.01) {	
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
			 deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		float fallof = 1.0;
		float noise = getnoise(textCoord);
		
		for(int i=0; i < NUM_SAMPLES ; i++) {			
			textCoord -= deltaTextCoord;
			
			fallof *= 0.8;
			float sample = step(texture2D(gaux1, textCoord+ deltaTextCoord*noise*grnoise).g,0.01);
			gr += sample*fallof;
		}
	}
	else {
	tpos = vec4(-sunPosition,1.0)*gbufferProjection;
	tpos = vec4(tpos.xyz/tpos.w,1.0);
	pos1 = tpos.xy/tpos.z;
	lightPos = pos1*0.5+0.5;
	truepos = pow(clamp(dot(-moonVec,tpos.xyz)/length(tpos.xyz),0.0,1.0),0.5);
	
		if (truepos > 0.01 && moonVisibility > 0.01) {
		vec2 deltaTextCoord = vec2( texcoord.st - lightPos.xy );
		vec2 textCoord = texcoord.st;
		deltaTextCoord *= 1.0 /  float(NUM_SAMPLES) * density;
		float avgdecay = 0.0;
		float distx = abs(texcoord.x*aspectRatio-lightPos.x*aspectRatio);
		float disty = abs(texcoord.y-lightPos.y);
		float fallof = 1.0;
		float noise = getnoise(textCoord);
		
		for(int i=0; i < NUM_SAMPLES ; i++) {			
			textCoord -= deltaTextCoord;
			
			fallof *= 0.8;
			float sample = step(texture2D(gaux1, textCoord+ deltaTextCoord*noise*grnoise).g,0.01);
			gr += sample*fallof;
		}
		gr /= NUM_SAMPLES;
	}
	}
 return gr;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
#ifndef DYNAMIC_HANDLIGHT
		handlight = 0.0;
#endif

	vec2 newtc = texcoord.xy;
	
	//unpack material flags
	float land = float(aux.g > 0.04);
	float iswater = float(aux.g > 0.04 && aux.g < 0.07);
	float translucent = float(aux.g > 0.3 && aux.g < 0.5);
	float tallgrass = float(aux.g > 0.42 && aux.g < 0.48);
	float hand = float(aux.g > 0.75 && aux.g < 0.85);
	float emissive = float(aux.g > 0.58 && aux.g < 0.62);
	float shading = 0.0f;
	float spec = 0.0;
	
	float roughness = mix(1.0-specular.b,0.005,iswater);
	if (specular.r+specular.g+specular.b < 1.0/255.0 && iswater < 0.09) roughness = 0.99;
	
	float fresnel_pow = pow(roughness,1.25+iswet*0.75)*5.0;
	if (iswater > 0.9) fresnel_pow=5.0;
	
	vec3 color = texture2D(gcolor, texcoord.st).rgb;
		 color = pow(color,vec3(2.2));
	
	float NdotL = dot(lightVector,normal);

	
	vec4 fragposition = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepthW - 1.0f, 1.0f);
		 fragposition /= fragposition.w;
	
	vec4 fragpositions = gbufferProjectionInverse * vec4(texcoord.s * 2.0f - 1.0f, texcoord.t * 2.0f - 1.0f, 2.0f * pixeldepth - 1.0f, 1.0f);
		 fragpositions /= fragpositions.w;

		vec4 worldposition = vec4(0.0);
		vec4 worldpositionraw = vec4(0.0);
			 worldposition = gbufferModelViewInverse * fragposition;	
		float xzDistanceSquared = worldposition.x * worldposition.x + worldposition.z * worldposition.z;
		float yDistanceSquared  = worldposition.y * worldposition.y;
			 worldpositionraw = worldposition;
		
	float time = float(worldTime);
	float transition_fading = 1.0-(clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-13500.0)/300.0,0.0,1.0) + clamp((time-22500.0)/300.0,0.0,1.0)-clamp((time-23400.0)/300.0,0.0,1.0));	//fading between sun/moon shadows
	float night = clamp((time-12000.0)/300.0,0.0,1.0)-clamp((time-23000.0)/200.0,0.0,1.0);
	float day = clamp((time-22000.0)/300.0,0.0,1.0)-clamp((time-13000.0)/200.0,0.0,1.0);
	
	vec3 uPos = vec3(.0);

//--Water Refract--//	
	if (iswater > 0.9) {
	
	vec3 posxz = worldposition.xyz+cameraPosition;
	
		vec3 refract = getWaterHeight(posxz);

		float refMult = 0.005-dot(normal,normalize(fragposition).xyz)*0.01;
	
		vec4 rA = texture2D(gcolor, newtc.st + refract.xy*refMult);
			 rA.rgb = pow(rA.rgb,vec3(2.2));
		vec4 rB = texture2D(gcolor, newtc.st);
			 rB.rgb = pow(rB.rgb,vec3(2.2));
	
		float mask = texture2D(gaux1, newtc.st + refract.xy*refMult).g;
			  mask =  float(mask > 0.04 && mask < 0.07);
		newtc = (newtc.st + refract.xy*refMult)*mask + texcoord.xy*(1-mask);
	
		color.rgb = pow(texture2D(gcolor,newtc.xy).rgb,vec3(2.2));
	}
	
	float uDepth = texture2D(depthtex1,newtc.xy).x;
	uPos  = nvec3(gbufferProjectionInverse * nvec4(vec3(newtc.xy,uDepth) * 2.0 - 1.0));	
	vec3 uVec = fragpositions.xyz-uPos;
	float UNdotUP = abs(dot(normalize(uVec),normal));
	float depth = length(uVec)*UNdotUP;
	
	
//--Shadow Calculation--//

	if (land > 0.9) {
		float dist = length(fragposition.xyz);
		float distof = clamp(1.0-dist/shadowDistance,0.0,1.0);
		float distof2 = clamp(1.0-pow(dist/(shadowDistance*0.75),2.0),0.0,1.0);
		//float shadow_fade = clamp(distof*12.0,0.0,1.0);
		float shadow_fade = sqrt(clamp(1.0 - xzDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0) * clamp(1.0 - yDistanceSquared / (shadowDistance*shadowDistance*1.0), 0.0, 1.0));

		/*--reprojecting into shadow space --*/

		worldposition = shadowModelView * worldposition;
		float comparedepth = -worldposition.z;
		worldposition = shadowProjection * worldposition;
		worldposition /= worldposition.w;
		float distb = sqrt(worldposition.x * worldposition.x + worldposition.y * worldposition.y);
		float distortFactor = (1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS;
		worldposition.xy *= 1.0f / distortFactor;
		worldposition = worldposition * 0.5f + 0.5f;
		/*---------------------------------*/
		
		float rescale = ((1.0f - SHADOW_MAP_BIAS) + distb * SHADOW_MAP_BIAS);
		float step = 3.0/shadowMapResolution*(1.0+rainStrength*5.0);
		//shadow_fade = 1.0-clamp((max(abs(worldposition.x-0.5),abs(worldposition.y-0.5))*2.0-0.9),0.0,0.1)*10.0;
		
		float NdotL = dot(normal, lightVector);
		float diffthresh = (pow(distortFactor*1.2,2.0)*(0.2/148.0)*(tan(acos(abs(NdotL)))) + (0.02/148.0))*(1.0+iswater*2.0);
			  diffthresh = mix(diffthresh,0.0005,translucent)*(1.+tallgrass*0.1*clamp(tan(acos(abs(NdotL))),0.0,2.));
		
		if (worldposition.s < 0.99 && worldposition.s > 0.01 && worldposition.t < 0.99 && worldposition.t > 0.01 ) {

			if ((NdotL < 0.0 && translucent < 0.1)) {
					shading = 0.0;
				}
			
			if (isEyeInWater > 0.09) {
					shading = 1.0;
				}
			
			else {
			#ifdef HQ_SHADOW_FILTER
				step = 2.0/shadowMapResolution*(1.0+rainStrength*5.0);
				float weights;
				float totalweight = 0.0;
				float sigma = 0.25;
				float A = 1.0/sqrt(2.0*3.14159265359*sigma);
				
				for(int i = 0; i < 25; i++){
					float dists = length(shadow_offsetss[i]);
					float weights = A*exp(-(dists*dists)/(2.0*sigma));
					shading += shadow2D(shadow,vec3(worldposition.st + shadow_offsetss[i]*step, worldposition.z-diffthresh*(2.0-weights))).x*weights;
					totalweight += 0.2;
				}
			
			shading /= totalweight;
			#endif
			
			step = 1.0/shadowMapResolution*(1.0+rainStrength*5.0);
			
			#ifdef SOFT_SHADOWS
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,step), worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(step,-step), worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,-step), worldposition.z-diffthresh)).x;
				shading += shadow2D(shadow,vec3(worldposition.st + vec2(-step,step), worldposition.z-diffthresh)).x;
				shading = shading/5.0;
			#endif
			
			#ifndef SOFT_SHADOWS
				#ifndef HQ_SHADOW_FILTER
				shading = shadow2D(shadow,vec3(worldposition.st, worldposition.z-diffthresh)).x;
				#endif
			#endif 
			
			#ifdef VARIABLE_PENUMBRA_SHADOWS

				float avgdepth = 0.0;
				vec2 scales = vec2(0.,100.);
				float mult = 10.0;
				
				//using texture filtering instead of multiple samples for more sample coherence over pixels, plus huge performance improvement
				float ssample = comparedepth - (0.05 + (texture2DLod(shadowtex1, worldposition.st,4).z) * (256.0 - 0.05));
				avgdepth = clamp(ssample, scales.x, scales.y)/(scales.y);
							
				avgdepth = (avgdepth)*mult;
							
				diffthresh *= avgdepth+1.0;			
				step =(0.07/shadowMapResolution*(1.0+2.0*tallgrass)+(avgdepth)/shadowMapResolution)/rescale*1.15*(1.0+rainStrength*5.0);
				float weight;
				
				for(int i = 0; i < 60; i++){
					float dist = length(shadow_offsets[i]);
					shading += shadow2D(shadow,vec3(worldposition.st + shadow_offsets[i]*step, worldposition.z-diffthresh*(1.0+dist))).x*exp(-dist*dist/0.3);
					weight += exp(-dist*dist/0.3);
				}

				
			shading /= weight;
			
		#endif	
			}
		}
		
		else shading = 1.0;
/*--------------------------------*/		
		
/*--------------------------------*/				
		float ao = 1.0;
		vec3 avgDir = vec3(.0);
		float tweight = 0.0;
		
	#ifdef SSAO
		if (land > 0.9 && iswater < 0.9 && hand < 0.9) {
			vec3 norm = texture2D(gnormal,texcoord.xy).rgb*2.0-1.0;
			vec3 projpos = convertScreenSpaceToWorldSpace(texcoord.xy,pixeldepth); 
			float progress = 0.0;
			ao = 0.0;
			float projrad = clamp(distance(convertCameraSpaceToScreenSpace(projpos + vec3(ssaorad,ssaorad,ssaorad)).xy,texcoord.xy),0.05,0.1);
			
			for (int i = 1; i < nbdir; i++) {
				for (int j = 1; j < sampledir; j++) {
					vec2 samplecoord = vec2(cos(progress),sin(progress))*(j/sampledir)*projrad + texcoord.xy;
					float sample = texture2D(depthtex0,samplecoord).x;
					vec3 sprojpos = convertScreenSpaceToWorldSpace(samplecoord,sample);
					float angle = min(1.0-sqrt(dot(norm,normalize(sprojpos-projpos))),1.0);
					float dist = pow(min(abs(length(sprojpos)-length(projpos)),ssaorad)/ssaorad,2.0);
					float temp = min(dist+angle,1.0);
					ao += temp;
					progress += (1.0-temp)/nbdir*3.14;
				}
				progress = i*(6.28/nbdir);
			}
			ao /= (nbdir-1)*(sampledir-1);
			ao = pow(ao,2.2);
		}
	#endif
		vec3 npos = normalize(fragposition.xyz);

		float diffuse = max(dot(lightVector,normal),0.0);
		
		diffuse = mix(diffuse,1.0,translucent*0.8);
		float sss = subSurfaceScattering(fragposition.xyz,30.0)*SUNLIGHTAMOUNT*2.0;
			  sss = (mix(0.0,sss,max(shadow_fade-0.1,0.0)*1.111)*0.5+0.5)*translucent;
		
		float handLight = (handlight*50.0)/pow(1.0+length(fragposition.xyz/2.0),2.0)*sqrt(dot(normalize(fragposition.xyz), -normal)*0.5+0.5);
		
	//Apply different lightmaps to image
	
		vec3 light_col =  mix(sunlight,moonlight,moonVisibility);
		
		vec3 Sunlight_lightmap = mix(light_col,vec3(0.5*(1-TimeMidnight*0.25)),rainStrength)*mix(max(sky_lightmap-rainStrength*0.95,0.0),shading*(1.0-rainStrength*0.99),1.0)*SUNLIGHTAMOUNT *diffuse*transition_fading* pow(1-rainStrength, 4.0f) ;

		vec3 Ucolor= normalize(vec3(0.1,0.4,0.6));

		//we'll suppose water plane have same height above pixel and at pixel water's surface
			//underwater position
		
		float sky_absorbance = mix(mix(1.0,exp(-depth/2.5),iswater),1.0,isEyeInWater);
		
		float visibility = sky_lightmap;
		float NdotUp = dot(normal,normalize(upPosition));
		float bouncefactor = sqrt(NdotUp*0.33+0.68);
		float cfBounce = PosDot(normalize(-sunPosition),normal)*0.5 + (1-bouncefactor)*0.5;
		float cfBounce2 = PosDot(normalize(sunPosition),normal)*0.2 + (1-bouncefactor)*0.2 + 0.6;
						
		vec3 aLightNormal = vec3(0.0);
		vec3 a_light =  ambient_color;
		
		vec3 emissive = vec3(2.0)*color.r*color.r*color.r*luma(color)*(emissive+handlight*hand)*(2.8-min(length(ambient_color)/sqrt(3.0),eyeBrightnessSmooth.y/240.0*1.7));

		vec3 bounceSunlight = cfBounce*sunlight*sunVisibility*sky_lightmap*SHADOW_DARKNESS*0.5 * (1-rainStrength*0.9);
		vec3 bounceMoonlight = cfBounce2*moonlight*moonVisibility*1.5* (1-rainStrength*0.9);
		
		////////New Dynamic Tone Mapping///////	
	
//Skylight Factor
if (isEyeInWater > 0.9) {
#ifdef Water_TempFix
	color.rgb *= 25.5;
#else
	color.rgb *= 2.5;
#endif
	
	//Colour Properties
		float Tonemap_Contrast 		= 1.0;
		float Tonemap_Saturation 	= 1.15; 
		float Tonemap_Decay			= 15.0;
		float Tonemap_Curve			= 85.0;
		
	color.rgb += 0.001;
	
	vec3 colorN = normalize(color.rgb);
	
	vec3 clrfr = color.rgb/colorN.rgb;
	     clrfr = pow(clrfr.rgb, vec3(Tonemap_Contrast));
		 
	colorN.rgb = pow(colorN.rgb, vec3(Tonemap_Saturation));
	
	color.rgb = clrfr.rgb * colorN.rgb;

	color.rgb = (color.rgb * (1.0 + color.rgb/Tonemap_Decay))/(color.rgb + Tonemap_Curve);
    } else {

	float Skylight_Exposure = eyeBrightnessSmooth.y / 16.0;
	
		  Skylight_Exposure = min(Skylight_Exposure, 16.0) / 16.0;
		  
#ifdef Pseudo_hdr
#ifdef OldColor_Tonemap	
	//Pseudo_hdr
	Skylight_Exposure = pow(Skylight_Exposure, 7.0);
	Skylight_Exposure *= mix(1.0f, NIGHT_EXPOSURE, night);
	color.rgb /= Skylight_Exposure+night/3 * 1.175 + 0.40;
#else
	Skylight_Exposure = pow(Skylight_Exposure, 10.0);
	Skylight_Exposure *= mix(1.0f, NIGHT_EXPOSURE, night);
	color.rgb /= Skylight_Exposure+night/3 * 1.175 + 0.30;
#endif	
	
	color.rgb *= 25.0;

#ifdef OldColor_Tonemap	
//Colour Properties
		float Tonemap_Contrast 		= 1.7;
		float Tonemap_Saturation 	= 1.37; 
		float Tonemap_Decay			= 800.0;
		float Tonemap_Curve			= 65.0;
	#else
	//Colour Properties
		float Tonemap_Contrast 		= 1.0;
		float Tonemap_Saturation 	= 0.80; 
		float Tonemap_Decay			= 15.0;
		float Tonemap_Curve			= 85.0;
#endif
		
	color.rgb += 0.001;
	
	vec3 colorN = normalize(color.rgb);
	
	vec3 clrfr = color.rgb/colorN.rgb;
	     clrfr = pow(clrfr.rgb, vec3(Tonemap_Contrast));
		 
	colorN.rgb = pow(colorN.rgb, vec3(Tonemap_Saturation));
	
	color.rgb = clrfr.rgb * colorN.rgb;

	color.rgb = (color.rgb * (1.0 + color.rgb/Tonemap_Decay))/(color.rgb + Tonemap_Curve);
}

#endif	
		
				
	////////New Torch System///////	
		
		float TorchBrightnessDay     = 0.00001f*day*torch_lightmap+SHADOW_DARKNESS+rainStrength*1.18;
		float TorchRangeDay          = 0.000001f*day*torch_lightmap+SHADOW_DARKNESS+rainStrength*3.18;
	
	#ifdef NIGHT_LIGHT_Desaturation
		float TorchBrightnessNight   = 3.3*night*torch_lightmap;
		float TorchRangeNight        = 3.8*night*torch_lightmap;
	#else
		float TorchBrightnessNight   = 5.9*night*torch_lightmap;
		float TorchRangeNight        = 2.8*night*torch_lightmap;
	#endif
		
	#ifdef NIGHT_LIGHT_Desaturation
		float TorchtBrightness_shadow = 0.35/torch_lightmap+day;
		float TorchRange_shadow      = 0.24/torch_lightmap+day;
	
		float TorchtBrightness_shadowNight = 0.00000000055/torch_lightmap+night;
		float TorchRange_shadowNight      = 0.000071/torch_lightmap+night;
	#else
		float TorchtBrightness_shadow = 0.35/torch_lightmap+day+night;
		float TorchRange_shadow      = 0.2/torch_lightmap+day+night;
	#endif
	
		float TorchHandlightDay      = 99.0000001*day*torch_lightmap;
		float TorchHandlightNight    = 5.00007*night*torch_lightmap;
		float TorchHandlight_shadow  = 0.009/torch_lightmap;

	
	
	#ifdef NIGHT_LIGHT_Desaturation
		float Torch_brightness = TorchBrightnessDay + TorchtBrightness_shadow + TorchtBrightness_shadowNight + TorchBrightnessNight;
		float Torch_range = TorchRangeDay + TorchRange_shadow + TorchRange_shadowNight + TorchRangeNight;
		float Torch_handlight = TorchHandlightDay + TorchHandlight_shadow + TorchHandlightNight;
	#else
		float Torch_brightness = TorchBrightnessDay + TorchtBrightness_shadow + TorchBrightnessNight;
		float Torch_range = TorchRangeDay + TorchRange_shadow + TorchRangeNight;
		float Torch_handlight = TorchHandlightDay + TorchHandlight_shadow + TorchHandlightNight;
	#endif
	
		float torch_lightmap = pow(aux.b,Torch_range)*Torch_brightness;
			
	#ifdef OldColor_Tonemap	
		vec3 sky_light = SHADOW_DARKNESS*a_light*ao * visibility;
	#else		
		vec3 sky_light = SHADOW_DARKNESS*a_light*ao * visibility;
		   	 sky_light *= mix(0.0f, 1.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
		vec3 sky_lights = (0.02*a_light*ao * visibility);
			 sky_lights *= mix(1.0f, 0.0f, pow(eyeBrightnessSmooth.y / 240.0f, 3.0f));
	#endif
		
		vec3 Torchlight_lightmap = (torch_lightmap + handLight / 2.5) *  torchcolor ;
		vec3 color_sunlight = Sunlight_lightmap;
		vec3 color_torchlight = Torchlight_lightmap;
		
	#ifdef NIGHT_LIGHT_Desaturation	
		if (land > 0.9){
		 color.r = color.r + ((color.g + color.b)/2.0)*(0.85)*TimeMidnight * 0.55;
		 color.g = color.g + ((color.r + color.b)/2.0)*(0.85)*TimeMidnight * 0.55;
		 color.b = color.b + ((color.r + color.g)/2.9)*(0.85)*TimeMidnight * 0.55;
		}
	#endif
	
// Ground get's darker when it's wet.
		if (iswet > 0.10 ) color *= 1.0 + (night / 11);
		if (iswet > 0.15 ) color *= 0.98 + (night / 11);
		if (iswet > 0.20 ) color *= 0.96 + (night / 11);
		if (iswet > 0.25 ) color *= 0.94 + (night / 11);
		if (iswet > 0.30 ) color *= 0.92 + (night / 11);
		if (iswet > 0.35 ) color *= 0.90 + (night / 11);
		if (iswet > 0.40 ) color *= 0.88 + (night / 11);
		
			
		
	//Add all light elements together
	vec3 nightlight = vec3(0.5);
	DoNightLight(nightlight);
	#ifdef OldColor_Tonemap
		color = ( bounceSunlight+ bounceMoonlight + nightlight * sky_lightmap*SHADOW_DARKNESS + sky_light+ MIN_LIGHT+ Sunlight_lightmap + color_torchlight  +  sss * light_col * shading *ao  *(1.0-rainStrength*0.9)*transition_fading + emissive)*color*sky_absorbance;
	#else
		color = ( bounceSunlight + bounceMoonlight + nightlight * sky_lightmap * SHADOW_DARKNESS + sky_lights + sky_light + MIN_LIGHT + Sunlight_lightmap + color_torchlight   +  sss * light_col * shading *ao  * (1.0-rainStrength*0.9) * transition_fading + emissive) * color * sky_absorbance;
	#endif
	

float rainx = clamp(rainStrength, 0.0f, 1.0f)/1.0f;

		if (iswater > 0.9) color = mix(Ucolor*length(ambient_color)*0.04*sky_lightmap,color,exp(-depth/16));

		float gfactor = mix(roughness+0.1,1.0,iswater);
		
		spec = Blinn_Phong(fragposition.xyz,lightVector,normal,fresnel_pow,gfactor,pow(sky_lightmap, 5.0)*diffuse) *land * (1.0-isEyeInWater)*transition_fading;
	}
	
	else if (isEyeInWater < 0.1 && (aux.g < 0.02) ){

	color = getSkyColor(fragposition.xyz)+pow(texture2D(gcolor,texcoord.xy).rgb,vec3(2.2))*(1-sunVisibility)*15.0*sqrt(max(dot(upVec,normalize(fragposition.xyz)),0.0)) ;

	}
	
			float sky_absorbanceWC = mix(mix(1.0,exp(-depth/2.5),iswater),1.0,isEyeInWater);
	
#ifdef WATER_CAUSTIC	
if (isEyeInWater > 0.09) {
		color += waterCaustic(color.rgb*7.5,1.0,land*(1.0-iswater))*isEyeInWater;
		//color += waterCaustic(color.rgb*2.5,1.0,land*(1.0-iswater))*isEyeInWater * TimeMidnight;
	}
	else {
		color += waterCaustic(color.rgb*2.5,1.0,land)*sky_absorbanceWC * pow(sky_lightmap,1.0)  * (1 - rainStrength * 0.75) * (iswater + isEyeInWater * 10) * (1 - iswater * isEyeInWater);
	}
#endif
	
	if(aux.g > 0.02 && aux.g < 0.04) color *= 5.0;

	
/* DRAWBUFFERS:31 */

	
#ifdef CELSHADING
	if (iswater < 0.9) color = celshade(color);
#endif

#ifdef GODRAYS
	float Rays2D = GetScreenSpaceRays();
	#else
	float Rays2D = 1.0;
#endif	

#ifdef VOLUMETRIC_LIGHT
	float volumetricRays = GetVolumetricRays();
#else
	float volumetricRays = 1.0;
#endif
		
	//color = ((sunlight * pow(sky_lightmap,(0.5))) * color);
	color = pow(color/MAX_COLOR_RANGE,vec3(1.0/2.2));

	gl_FragData[0] = vec4(color, spec);

	gl_FragData[1] = vec4(Rays2D,0.0,0.0,volumetricRays);
}
