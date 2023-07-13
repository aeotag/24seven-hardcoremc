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
varying vec3 moonlight2;
varying vec3 ambient_color;
varying vec3 vlAmbient;

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
const ivec4 ToD[25] = ivec4[25](ivec4(0,4,8,16), //hour,r,g,b
							ivec4(1,4,8,16),
							ivec4(2,4,8,16),
							ivec4(3,4,8,16),
							ivec4(4,4,8,16),
							ivec4(5,4,8,16),
								ivec4(6,200,153,60),
								ivec4(7,200,166,72),
								ivec4(8,170,155,120),
								ivec4(9,170,155,120),
								ivec4(10,170,155,120),
								ivec4(11,170,155,120),
								ivec4(12,170,155,120),
								ivec4(13,170,155,120),
								ivec4(14,170,155,120),
								ivec4(15,170,155,120),
								ivec4(16,170,155,120),
								ivec4(17,200,166,72),
								ivec4(18,200,153,60),
								ivec4(19,4,8,16),
								ivec4(20,4,8,16),
							ivec4(21,4,8,16),
							ivec4(22,4,8,16),
							ivec4(23,4,8,16),
							ivec4(24,4,8,16));

								
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
////////////////////ambient color////////////////////
const ivec4 ToD2[25] = ivec4[25](ivec4(0,10,20,45), //hour,r,g,b
							ivec4(1,10,20,45),
							ivec4(2,10,20,45),
							ivec4(3,10,20,45),
							ivec4(4,10,20,45),
								ivec4(5,10,20,45),
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
								ivec4(19,10,20,45),
								ivec4(20,3,12,38),
							ivec4(21,3,12,38),
							ivec4(22,3,12,38),
							ivec4(23,3,12,38),
							ivec4(24,3,12,38));
							
////////////////////VLambient color////////////////////
////////////////////VLambient color////////////////////
////////////////////VLambient color////////////////////
const ivec4 ToD3[25] = ivec4[25](ivec4(0,15,38,60), //hour,r,g,b
							ivec4(1,15,38,60),
							ivec4(2,15,38,60),
							ivec4(3,15,38,60),
							ivec4(4,15,38,60),
								ivec4(5,5,38,60),
								ivec4(6,100,110,180),
								ivec4(7,100,110,180),
								ivec4(8,60,160,255),
								ivec4(9,60,160,255),
								ivec4(10,60,160,255),
								ivec4(11,60,160,255),
								ivec4(12,60,160,255),
								ivec4(13,60,160,255),
								ivec4(14,60,160,255),
								ivec4(15,60,160,255),
								ivec4(16,60,160,255),
								ivec4(17,100,110,180),
								ivec4(18,100,110,180),
								ivec4(19,5,38,60),
								ivec4(20,15,38,60),
							ivec4(21,15,38,60),
							ivec4(22,15,38,60),
							ivec4(23,15,38,60),
							ivec4(24,15,38,60));

//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////
//////////////////////////////VOID MAIN//////////////////////////////

void main() {
	
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
	moonlight = ivec3(4,6,16)/2555555555.0;
	moonlight2 = ivec3(4,6,10)/255.0;
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
	
	ivec4 tempb = ToD3[int(floor(hour))];
	ivec4 tempb2 = ToD3[int(floor(hour)) + 1];

	vlAmbient = mix(vec3(tempb.yzw),vec3(tempb2.yzw),(hour-float(tempa.x))/float(tempb2.x-tempb.x))/255.0f;


//sky gradient
/*----------*/
vec3 skycoaa = ivec3(28,170,255)/255.0;
vec3 sky_color = pow(skycoaa,vec3(2.2));
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
vec3 skyColormoon = mix(moonlight,normalize(vec3(0.25,0.3,0.4))*length(moonlight),rainStrength)*L2*0.4 ; //affect color based on luminance (0% physically accurate)
skyColormoon *= moonVisibility;

sky_color = skyColormoon+skyColorSun;

ambient_color = mix(sky_color,vec3(1/sqrt(3.0))*length(sky_color),0.25);

/*----------*/



ambient_color = mix(moonlight,ambient_color,sunVisibility);
}
