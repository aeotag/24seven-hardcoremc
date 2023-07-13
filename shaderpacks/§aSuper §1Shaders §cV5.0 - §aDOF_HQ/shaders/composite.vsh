#version 120


/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//go to line 46 for changing sunlight color and ambient color line 89 for moon light color
/*--------------------------------*/
#define NIGHT_LIGHT_Desaturation				//used to desaturate color at night but affects torch color, still needs work

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec4 lightS;


varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;
varying vec3 torchcolor;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 nsunlights;

varying float handItemLight;
varying float eyeAdapt;

varying float SdotU;
varying float MdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform vec3 skyColor;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform int worldTime;
uniform int heldItemId;
uniform int heldBlockLightValue;
uniform float rainStrength;
uniform float wetness;
uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;


float timefract = worldTime;
float TimeSunrise  = ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0) + (1.0 - (clamp(timefract, 0.0, 4000.0)/4000.0));
float TimeNoon     = ((clamp(timefract, 0.0, 4000.0)) / 4000.0) - ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0);
float TimeSunset   = ((clamp(timefract, 8000.0, 12000.0) - 8000.0) / 4000.0) - ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0);
float TimeMidnight = ((clamp(timefract, 12000.0, 12750.0) - 12000.0) / 750.0) - ((clamp(timefract, 23000.0, 24000.0) - 23000.0) / 1000.0);

/*--------------------------------*/
//#define OldColor_Tonemap
#ifdef OldColor_Tonemap
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
const ivec4 ToD[25] = ivec4[25](ivec4(0,4,8,16), //hour,r,g,b
							ivec4(1,4,8,16),
							ivec4(2,4,8,16),
							ivec4(3,4,8,16),
							ivec4(4,4,8,16),
							ivec4(5,4,8,16),
								ivec4(6,90,61,25),
								ivec4(7,175,119,65),
								ivec4(8,215,190,127),
								ivec4(9,230,215,160),
								ivec4(10,230,235,190),
								ivec4(11,230,235,190),
								ivec4(12,230,235,190),
								ivec4(13,230,235,190),
								ivec4(14,230,235,190),
								ivec4(15,230,235,190),
								ivec4(16,220,215,160),
								ivec4(17,215,190,127),
								ivec4(18,235,169,100),
								ivec4(19,235,153,60),
								ivec4(20,4,8,16),
							ivec4(21,4,8,16),
							ivec4(22,4,8,16),
							ivec4(23,4,8,16),
							ivec4(24,4,8,16));


								
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
const ivec4 ToD2[25] = ivec4[25](ivec4(0,3,14,19), //hour,r,g,b
								ivec4(1,3,14,19),
								ivec4(2,3,14,19),
								ivec4(3,3,14,19),
								ivec4(4,3,14,19),
								ivec4(5,30,75,150),
								ivec4(6,60,160,255),
								ivec4(7,60,160,255),
								ivec4(8,60,160,255),
								ivec4(9,60,160,255),
								ivec4(10,60,160,255),
								ivec4(11,60,160,255),
								ivec4(12,60,160,255),
								ivec4(13,60,160,255),
								ivec4(14,60,160,255),
								ivec4(15,60,160,255),
								ivec4(16,60,160,255),
								ivec4(17,60,160,255),
								ivec4(18,60,160,255),
								ivec4(19,30,75,150),
								ivec4(20,3,14,19),
								ivec4(21,3,14,19),
								ivec4(22,3,14,19),
								ivec4(23,3,14,19),
								ivec4(24,3,14,19));

	vec3 sky_Grad_color = ivec3(60,170,255)/255.0;							
								
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
	moonlight = ivec3(4,5,8)/435.0;
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	
	else {
		lightVector = normalize(-sunPosition);
	}
	sunVec = normalize(sunPosition);
	moonVec = normalize(-sunPosition);
	upVec = normalize(upPosition);
	
	SdotU = dot(sunVec,upVec);
	MdotU = dot(moonVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	moonVisibility = pow(clamp(MdotU+0.1,0.0,0.1)/0.1,2.0);
	
	handItemLight = 0.0;
	if (heldItemId == 50) {
		// torch
		handItemLight = 0.5;
	}
	
	else if (heldItemId == 76 || heldItemId == 94) {
		// active redstone torch / redstone repeater
		handItemLight = 0.1;
	}
	
	else if (heldItemId == 89) {
		// lightstone
		handItemLight = 0.6;
	}
	
	else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {
		// lava / lava / fire
		handItemLight = 0.5;
	}
	
	else if (heldItemId == 91) {
		// jack-o-lantern
		handItemLight = 0.6;
	}
	
	
	else if (heldItemId == 327) {
		handItemLight = 0.2;
	}
	
	float hour = worldTime/1000.0+6.0;
	if (hour > 24.0) hour = hour - 24.0;
	
	ivec4 temp = ToD[int(floor(hour))];
	ivec4 temp2 = ToD[int(floor(hour)) + 1];
	
	sunlight = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;
	
	ivec4 tempa = ToD2[int(floor(hour))];
	ivec4 tempa2 = ToD2[int(floor(hour)) + 1];
	
	ambient_color = mix(vec3(tempa.yzw),vec3(tempa2.yzw),(hour-float(tempa.x))/float(tempa2.x-tempa.x))/255.0f;


//sky gradient
/*----------*/
vec3 sky_color = pow(ambient_color,vec3(2.2))*2.0;
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2)));
vec3 sVector = upVec;
vec3 upVector = normalize(upPosition);

sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(ambient_color),rainStrength)); //normalize colors in order to don't change luminance


float Lz = 1.0;
float cosT = dot(sVector,upVector); //T=S-Y  
float absCosT = abs(cosT);
float cosS = dot(sunVec,upVector);
float S = acos(cosS);				//S=Y+T	-> cos(Y+T)=cos(S) -> cos(Y)*cos(T) - sin(Y)*sin(T) = cos(S)
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);				//Y=S-T
//float L =   ((0.91+10*exp(-3*Y)+0.45*cosY*cosY)*(1.0-exp(-0.32/(absCosT+0.01))))/((0.91+10*exp(-3*S)+0.45*cosS*cosS)*(1.0-exp(-0.32)));		//CIE clear sky

float a = -0.7;
float b = -0.15;
float c = 15.0;
float d = -1.0;
float e = 0.3;

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY); 
//vec3 Lc = 1 + c*exp(d*Y)*sky_color + e*cosY*cosY*sky_color + a*exp(b/(absCosT+0.01))*sky_color + a*exp(b/(absCosT+0.01))*c*exp(d*Y) *nsunlight+ a*exp(b/(absCosT+0.01))*e*cosY*cosY*nsunlight;
//= 1 + f(Y) + g(Y) + h(T) + i(T,Y) + j(T,Y)
//S is constant on the frame
//float T = 2.0*S-Y;
//float cosT2 = abs(cos(S+Y)); 
//L = 1 + c*exp(d*Y) + e*cosY*cosY + a*exp(b/(cosT2+0.01)) + a*exp(b/(cosT2+0.01))*c*exp(d*Y) + a*exp(b/(cosT2+0.01))*e*cosY*cosY;
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.8); //modulate intensity when raining
//vec3 skyColorSun = mix(sky_color,,1-exp(-0.3*L*(1-rainStrength*0.8))); 
vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.1*L*(1-rainStrength*0.8)))*L ; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;


//moon sky color
float McosS = dot(moonVec,upVector);
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY);
L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.8); //modulate intensity when raining
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.5,0.03,0.04))*length(moonlight),rainStrength)*L2*0.4 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun;

ambient_color = mix(sky_color,vec3(1/sqrt(3.0))*length(sky_color),0.25);

/*----------*/



ambient_color = mix(moonlight,ambient_color*2,sunVisibility);

float torchWhiteBalance = 0.067f;
			 torchcolor = vec3(0.7,0.23,0.03);
			 torchcolor = mix(torchcolor, vec3(1.0f), vec3(torchWhiteBalance));
			 torchcolor = pow(torchcolor, vec3(0.99f));
}

#else

////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
const ivec4 ToD[25] = ivec4[25](ivec4(0,200,134,48), //hour,r,g,b
								ivec4(1,200,134,48),
								ivec4(2,200,134,48),
								ivec4(3,200,134,48),
								ivec4(4,200,134,48),
								ivec4(5,200,134,48),
								ivec4(6,200,134,90),
								ivec4(7,200,180,110),
								ivec4(8,200,186,132),
								ivec4(9,200,195,143),
								ivec4(10,200,199,154),
								ivec4(11,200,200,165),
								ivec4(12,200,200,171),
								ivec4(13,200,200,165),
								ivec4(14,200,199,154),
								ivec4(15,200,195,143),
								ivec4(16,200,186,132),
								ivec4(17,200,180,110),
								ivec4(18,200,153,90),
								ivec4(19,200,134,48),
								ivec4(20,200,134,48),
								ivec4(21,200,134,48),
								ivec4(22,200,134,48),
								ivec4(23,200,134,48),
								ivec4(24,200,134,48));
								
vec3 sky_color = ivec3(60,170,255)/255.0;								
/*--------------------------------*/							

vec3 getSkyColor(vec3 fposition) {

/*--------------------------------*/
	float SdotU = dot(sunVec,upVec);
	float MdotU = dot(moonVec,upVec);
	float sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	float moonVisibility = pow(clamp(MdotU+0.1,0.0,0.1)/0.1,2.0);
/*--------------------------------*/	
vec3 sky_color = vec3(0.1, 0.35, 1.);
vec3 nsunlight = normalize(pow(sunlight,vec3(2.2))*vec3(1.,0.9,0.8));
vec3 sVector = normalize(fposition);

sky_color = normalize(mix(sky_color,vec3(0.25,0.3,0.4)*length(sunlight)*0.3,rainStrength)); //normalize colors in order to don't change luminance
/*--------------------------------*/
float Lz = 1.0;
float cosT = dot(sVector,upVec); 
float absCosT = max(cosT,0.0);
float cosS = dot(sunVec,upVec);
float S = acos(cosS);				
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);	
/*--------------------------------*/	
float a = -1.;
float b = -0.24;
float c = 6.0;
float d = -0.8;
float e = 0.45;

/*--------------------------------*/

//sun sky color
float L =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*Y)+e*cosY*cosY); 
L = pow(L,1.0-rainStrength*0.8)*(1.0-rainStrength*0.8); //modulate intensity when raining

vec3 skyColorSun = mix(sky_color, nsunlight,1-exp(-0.005*pow(L,4.)*(1-rainStrength*0.8)))*L*0.5; //affect color based on luminance (0% physically accurate)
skyColorSun *= sunVisibility;
/*--------------------------------*/

//moon sky color
float McosS = MdotU;
float MS = acos(McosS);
float McosY = dot(moonVec,sVector);
float MY = acos(McosY);

/*--------------------------------*/

float L2 =  (1+a*exp(b/(absCosT+0.01)))*(1+c*exp(d*MY)+e*McosY*McosY)+0.2;
L2 = pow(L2,1.0-rainStrength*0.8)*(1.0-rainStrength*0.35); //modulate intensity when raining

vec3 skyColormoon = mix(pow(normalize(moonlight),vec3(2.2))*length(moonlight),normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength)*L2*0.8 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;
sky_color = skyColormoon*2.0+skyColorSun;
/*--------------------------------*/
return sky_color;
}

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {

	
	moonlight =  vec3(0.2f, 0.5f, 1.0)/68;
	/*--------------------------------*/
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
	/*--------------------------------*/
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	else {
		lightVector = normalize(-sunPosition);
	}
	/*--------------------------------*/
	sunVec = normalize(sunPosition);
	moonVec = normalize(-sunPosition);
	upVec = normalize(upPosition);
	
	SdotU = dot(sunVec,upVec);
	MdotU = dot(moonVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	moonVisibility = pow(clamp(MdotU+0.1,0.0,0.1)/0.1,2.0);
	/*--------------------------------*/
	
	float hour = mod(worldTime/1000.0+6.0,24);
	
	ivec4 temp = ToD[int(mod(floor(hour),24))];
	ivec4 temp2 = ToD[int(mod(floor(hour) + 1,24))];
	
	sunlight = mix(vec3(temp.yzw),vec3(temp2.yzw),(hour-float(temp.x))/float(temp2.x-temp.x))/255.0f;

	sunlight.b *= 0.95;
	/*--------------------------------*/
	
	//sample the skybox at different places to get an accurate average color from the sky
	vec3 wUp = (gbufferModelView * vec4(vec3(0.0,1.0,0.0),0.0)).rgb;
	vec3 wS1 = (gbufferModelView * vec4(normalize(vec3(3.5,1.0,3.5)),0.0)).rgb;
	vec3 wS2 = (gbufferModelView * vec4(normalize(vec3(-3.5,1.0,3.5)),0.0)).rgb;
	vec3 wS3 = (gbufferModelView * vec4(normalize(vec3(3.5,1.0,-3.5)),0.0)).rgb;
	vec3 wS4 = (gbufferModelView * vec4(normalize(vec3(-3.5,1.0,-3.5)),0.0)).rgb;

	ambient_color = (getSkyColor(wUp) + getSkyColor(wS1) + getSkyColor(wS2) + getSkyColor(wS3) + getSkyColor(wS4))*2.;
	ambient_color = pow(normalize(ambient_color),vec3(1./2.2))*length(ambient_color);		
	/*--------------------------------*/
	eyeAdapt = (2.0-min(length((getSkyColor(wUp) + getSkyColor(wS1) + getSkyColor(wS2) + getSkyColor(wS3) + getSkyColor(wS4))*2.)/sqrt(3.)*2.,eyeBrightnessSmooth.y/255.0*1.6+0.3))*(1-rainStrength*0.5);
	/*--------------------------------*/

	handItemLight = 0.0;
	if (heldItemId == 50) {
		// torch
		handItemLight = 0.5;
	}
	
	else if (heldItemId == 76 || heldItemId == 94) {
		// active redstone torch / redstone repeater
		handItemLight = 0.1;
	}
	
	else if (heldItemId == 89) {
		// lightstone
		handItemLight = 0.6;
	}
	
	else if (heldItemId == 10 || heldItemId == 11 || heldItemId == 51) {
		// lava / lava / fire
		handItemLight = 0.5;
	}
	
	else if (heldItemId == 91) {
		// jack-o-lantern
		handItemLight = 0.6;
	}
	
	
	else if (heldItemId == 327) {
		handItemLight = 0.2;
	}
	
	float cosS = SdotU;
float mcosS = max(cosS,0.0);

float skyMult = max(SdotU*0.1+0.1,0.0)/0.2*(1.0-rainStrength*0.6)*0.7;
	nsunlights = normalize(pow(mix(sunlight,5.*sunlight*sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.35),rainStrength),vec3(2.2)))*0.6*skyMult;
	
	vec3 sky_color = vec3(0.15, 0.14, 0.15);
		 sky_color = normalize(mix(sky_color,2.*sunlight*sunVisibility*(1.0-rainStrength*0.95)+vec3(0.3,0.3,0.3)*length(sunlight),rainStrength)); //normalize colors in order to don't change luminance
	
	sky1 = sky_color*0.6*skyMult;
	sky2 = mix(sky_color,mix(nsunlights,sky_color,rainStrength*0.9),1.0-max(mcosS-0.2,0.0)*0.5)*0.6*skyMult;

	
	/*--------------------------------*/
	#ifdef NIGHT_LIGHT_Desaturation
		float torchWhiteBalance = 0.0067f;
	#else
		float torchWhiteBalance = 0.067f;
	#endif
			 torchcolor = vec3(0.7,0.23,0.03);
		#ifdef NIGHT_LIGHT_Desaturation
			 torchcolor += vec3(1.7,0.0023,0.0003) / 50.5 * TimeMidnight;
		#endif
			 torchcolor = mix(torchcolor, vec3(1.0f), vec3(torchWhiteBalance));
			 torchcolor = pow(torchcolor, vec3(0.99f));
}

#endif