#version 120

/*
Read Mine and Chocapic13's terms of mofification/sharing before changing something below please!
ﯼᵵᴀᵶᵶᴬﺤ super Shaders (ﯼ✗∃), derived from Chocapic13 v4 Beta 4.8
Place two leading Slashes in front of the following '#define' lines in order to disable an option.
*/

//go to line 96 for changing sunlight/ambient color balance

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 sunVec;
varying vec3 moonVec;
varying vec3 upVec;

varying vec3 sunlight;
varying vec3 moonlight;
varying vec3 ambient_color;

varying float handItemLight;

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

////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
////////////////////sunlight color////////////////////
const ivec4 ToD[25] = ivec4[25](ivec4(0,200,134,48), //hour,r,g,b
								ivec4(1,200,134,48),
								ivec4(2,200,134,48),
								ivec4(3,200,134,48),
								ivec4(4,200,134,48),
								ivec4(5,200,134,48),
								ivec4(6,200,153,60),
								ivec4(7,200,166,72),
								ivec4(8,200,175,84),
								ivec4(9,200,183,96),
								ivec4(10,200,189,108),
								ivec4(11,200,195,120),
								ivec4(12,200,200,132),
								ivec4(13,200,195,120),
								ivec4(14,200,189,108),
								ivec4(15,200,183,96),
								ivec4(16,200,175,84),
								ivec4(17,200,166,72),
								ivec4(18,200,153,60),
								ivec4(19,200,134,48),
								ivec4(20,200,134,48),
								ivec4(21,200,134,48),
								ivec4(22,200,134,48),
								ivec4(23,200,134,48),
								ivec4(24,200,134,48));

								
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
const ivec4 ToD2[25] = ivec4[25](ivec4(0,8,20,30), //hour,r,g,b
								ivec4(1,8,20,30),
								ivec4(2,8,20,30),
								ivec4(3,8,20,30),
								ivec4(4,8,20,30),
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
								ivec4(20,8,20,30),
								ivec4(21,8,20,30),
								ivec4(22,8,20,30),
								ivec4(23,8,20,30),
								ivec4(24,8,20,30));

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;

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
vec3 skyColormoon = moonlight*L2*0.4 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun;

ambient_color = mix(sky_color,vec3(1/sqrt(3.0))*length(sky_color),0.0);

/*----------*/


	//moonlight = ivec3(5,8,20)/255.0;
ambient_color = mix(moonlight,ambient_color,sunVisibility);
}
