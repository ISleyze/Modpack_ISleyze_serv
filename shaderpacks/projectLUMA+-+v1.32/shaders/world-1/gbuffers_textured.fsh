#version 120
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

#include "lib/HDR.glsl"

#define NORMAL_MAP_BUMPMULT 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
//#define AUTO_BUMP
	#define TEXTURE_RESOLUTION 16 // [16 32 64 128 256 512]
//#define TORCH_NORMALS
//#define AMBIENT_OCCLUSION
//#define POM
	#define POM_DEPTH	7.0 // [1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0]
//#define PBR
	#define PBR_FORMAT 0 // [0 1 2 3 4]

#define AMBIENT_LIGHT 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define OVERRIDE_FOLIAGE_COLOR

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 tangent;
varying vec4 normal;
varying vec3 binormal;
varying vec4 viewVector;
varying vec4 worldposition;
varying vec4 color;

uniform sampler2DShadow shadowtex0;
uniform sampler2D texture;
uniform sampler2D normals;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform vec3 shadowLightPosition;

uniform ivec2 eyeBrightness;

uniform int isEyeInWater;
uniform int worldTime;

uniform float rainStrength;
uniform float sunAngle;
uniform float screenBrightness;
uniform float nightVision;
uniform float viewWidth;
uniform float viewHeight;

#if defined POM || defined AUTO_BUMP
  varying vec4 vtexcoordam;
  varying vec4 vtexcoord;
#endif


const int shadowMapResolution = 2048;	// [1024 1536 2048 3172 4096 8192]
const float shadowDistance = 128.0;	// [64.0 72.0 80.0 88.0 96.0 104.0 112.0 120.0 128.0 136.0 144.0 152.0 160.0 168.0 176.0 184.0 192.0 200.0 208.0 216.0 224.0 232.0 240.0 248.0 256.0]
const bool shadowHardwareFiltering = true;

vec2 dcdx = dFdx(texcoord);
vec2 dcdy = dFdy(texcoord);

float luma(vec3 clr) {
	return dot(clr, vec3(0.3333));
}

float encodeLightmap(vec2 a) {

  ivec2 bf = ivec2(a * 255.0);
  return float(bf.x | (bf.y << 8)) / 65535.0;

}

vec2 encodeNormal(vec3 normal) {

  return normal.xy * inversesqrt(normal.z * 8.0 + 8.0) + 0.5;

}

bool material(float id) {

	if (normal.a > id - 0.01 && normal.a < id + 0.01) {
		return true;
	} else {
		return false;
	}

}

mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
											tangent.y, binormal.y, normal.y,
											tangent.z, binormal.z, normal.z);

#include "lib/common/getTorchLightmap.glsl"
#include "lib/common/emissiveLight.glsl"

#ifdef TORCH_NORMALS

	float torchLambertian(vec3 viewNormal, float lightmap) {

		vec3 Q1 = dFdx(viewVector.xyz);
		vec3 Q2 = dFdy(viewVector.xyz);
		float st1 = dFdx(lightmap);
		float st2 = dFdy(lightmap);

		st1 /= luma(fwidth(viewVector.xyz));
		st2 /= luma(fwidth(viewVector.xyz));
		vec3 T = Q1 * st2 - Q2 * st1;
		T = normalize(T + normal.xyz * 0.0002);
		T = -cross(T, normal.xyz);

		T = normalize(T + normal.xyz * 0.01);
		T = normalize(T + normal.xyz * 0.85 * lightmap);


		float torchLambert  = pow(clamp(dot(T, viewNormal.xyz) * 1.0 + 0.0, 0.0, 1.0), 1.0);
					torchLambert += pow(clamp(dot(T, viewNormal.xyz) * 0.4 + 0.6, 0.0, 1.0), 1.0) * 0.5;

		if (dot(T, normal.xyz) > 0.99) torchLambert = pow(torchLambert, 2.0) * 0.45;

		return torchLambert;

	}

#endif

float bouncedLight(vec3 normal, float lightmap) {

	float bouncedLightStrength = 0.25;

	float shadowLength = 1.0 - abs(-0.25 + sunAngle) * 4.0;

	float bounce0 = max(dot(normal, -normalize(shadowLightPosition)), 0.0);
  float bounce1 = max(dot(normal, normalize(shadowLightPosition)), 0.0);
  float ground = max(dot(normal, normalize(upPosition)), 0.0);
	float light = mix(bounce0 * 0.5, bounce1 * (1.0 - ground) * shadowLength * 3.0, 1.0 - lightmap) * smoothstep(0.5, 1.0, color.a);

	return light * lightmap * bouncedLightStrength + bounce1 * bouncedLightStrength * 0.5 * smoothstep(0.8, 1.0, lightmap);

}

#include "lib/common/lowlightEye.glsl"

float subsurfaceScattering(vec3 fragpos, bool translucent) {

  const float strength = 0.5;

  float sunVector = max(dot(normalize(fragpos), normalize(sunPosition)), 0.0);
	float light	= pow(sunVector, 2.0) * float(translucent);

  return light * strength;

}

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

#ifdef PBR

	uniform sampler2D specular;

	vec3 PBRData(float NdotUp, bool translucent) {

		vec4 spec = texture2D(specular, texcoord);

		float roughness = 0.0;
		float metallic = 0.0;
		float specularity = luma(spec.rgb);

		#if (PBR_FORMAT == 0)

			// Common
			roughness = 1.0 - spec.r;
			metallic = spec.g;

		#elif (PBR_FORMAT == 2)

			// Pulchra + Continuum Addon
			roughness = 1.0 - spec.b;
			specularity *= 0.5;
			if (spec.r > 0.45) metallic = spec.r;


		#elif (PBR_FORMAT == 3)

			// Chroma Hills
			roughness = 1.0 - spec.r;
			metallic = spec.b;

		#elif (PBR_FORMAT == 4)

			// Stratum
			roughness = 1.0 - spec.b;
			metallic = spec.b;

		#endif

		#ifdef RAIN_PUDDLES

			specularity = mix(specularity + 0.25 * rainStrength * NdotUp * wetnessMap, 1.0, puddleMap * NdotUp * rainStrength);
			// TODO: Eine schönere Methode als das?
			if (translucent) specularity = 0.0;
			roughness = mix(roughness, 0.0, puddleMap * NdotUp * rainStrength);

		#endif

		return vec3(roughness, metallic, specularity);

	}

#endif

vec3 getNormals(vec2 coord) {

	vec3 bump  = texture2DGradARB(normals, coord, dcdx, dcdy).rgb * 2.0 - 1.0;

	#ifdef AUTO_BUMP

		float offset = 1.0 / TEXTURE_RESOLUTION;

		float M = abs(luma(texture2D(texture, fract(vtexcoord.st + vec2(0.0, 0.0)) * vtexcoordam.pq + vtexcoordam.xy).rgb));
		float L = abs(luma(texture2D(texture, fract(vtexcoord.st + vec2(offset, 0.0)) * vtexcoordam.pq + vtexcoordam.xy).rgb));
		float R = abs(luma(texture2D(texture, fract(vtexcoord.st + vec2(-offset, 0.0)) * vtexcoordam.pq + vtexcoordam.xy).rgb));
		float U = abs(luma(texture2D(texture, fract(vtexcoord.st + vec2(0.0, offset)) * vtexcoordam.pq + vtexcoordam.xy).rgb));
		float D = abs(luma(texture2D(texture, fract(vtexcoord.st + vec2(0.0, -offset)) * vtexcoordam.pq + vtexcoordam.xy).rgb));
		float X = (R - M) + (M - L);
		float Y = (D - M) + (M - U);

		bump = vec3(X, Y, 0.3);

	#endif

	bump *= vec3(NORMAL_MAP_BUMPMULT) + vec3(0.0, 0.0, 1.0 - NORMAL_MAP_BUMPMULT);

	return normalize(bump * tbnMatrix);

}

#ifdef POM

	float readAlpha(in vec2 coord) {
		return texture2DGradARB(normals, fract(coord) * vtexcoordam.pq + vtexcoordam.st, dcdx, dcdy).a;
	}

	vec2 parallaxMapping(vec2 coord, vec3 fragpos) {

		const float pomQuality = 256.0;
		const float maxOcclusionDistance = 32.0;
		const float mixOcclusionDistance = 28.0;
		const int   maxOcclusionPoints = 256;

		vec2 newCoord = coord;

		vec3 vwVector = normalize(tbnMatrix * viewVector.xyz);

		vec3 intervalMult = vec3(1.0, 1.0, 10.0 - POM_DEPTH) / pomQuality;

		float dist = length(fragpos.xyz);

		if (dist < maxOcclusionDistance) {

			if (vwVector.z < 0.0 && readAlpha(vtexcoord.xy) < 0.99 && readAlpha(vtexcoord.xy) > 0.01) {
				vec3 interval = vwVector.xyz * intervalMult;
				vec3 coord = vec3(vtexcoord.xy, 1.0);

				for (int loopCount = 0; (loopCount < maxOcclusionPoints) && (readAlpha(coord.st) < coord.p); ++loopCount) {
					coord = coord + interval;
				}

				float mincoord = 1.0 / 4096.0;

				// Don't wrap around top of tall grass/flower
				if (coord.t < mincoord) {
					if (readAlpha(vec2(coord.s, mincoord)) == 0.0) {
						coord.t = mincoord;
						discard;
					}
				}

				newCoord = mix(fract(coord.st) * vtexcoordam.pq + vtexcoordam.xy, newCoord, max(dist - mixOcclusionDistance, 0.0) / (maxOcclusionDistance - mixOcclusionDistance));

			}

		}

		return newCoord;

	}

#endif


void main() {

	bool hand = gl_FragCoord.z < 0.56;
	bool translucent = material(0.2);
	bool emissive = material(0.3);

	vec3 fragposition = toNDC(vec3(gl_FragCoord.xy / vec2(viewWidth,viewHeight), hand? gl_FragCoord.z + 0.38 : gl_FragCoord.z));

	vec2 newTexcoord = texcoord;
  #ifdef POM
    newTexcoord = parallaxMapping(texcoord, fragposition);
  #endif

	vec4 albedo = texture2D(texture, newTexcoord);
	#ifdef OVERRIDE_FOLIAGE_COLOR
		albedo *= mix(color, color * vec4(1.8, 1.4, 1.0, 1.0), 1.0 - luma(color.rgb));
	#else
		albedo *= color;
	#endif

	vec4 baseColor = albedo;
	vec3 newNormal = hand? normal.rgb : getNormals(newTexcoord);

	float NdotUp = clamp(dot(newNormal, normalize(-gbufferModelView[1].xyz)), 0.0, 1.0);

	#include "lib/colors.glsl"



	const float ambientStrength = 0.4;


	float minLight = 0.1 + screenBrightness * 0.06;


	float smoothLighting = 0.3 + color.a * 0.7;
	vec3 torchlight = getTorchLightmap(normal.xyz, lmcoord.x, lmcoord.y, translucent) * torchColor;
	#ifdef TORCH_NORMALS
			 torchlight *= torchLambertian(newNormal, lmcoord.x);
	#endif

	#ifdef AMBIENT_OCCLUSION
		smoothLighting = 0.7 + color.a * 0.3;
	#endif

	vec3 ambientLightmap = (minLight + ambientColor * ambientStrength * AMBIENT_LIGHT) * smoothLighting + NdotUp * torchColor * 0.1;
			 ambientLightmap += torchlight;
			 ambientLightmap = emissiveLight(ambientLightmap, baseColor.rgb * torchColor, emissive);

	baseColor.rgb = lowlightEye(baseColor.rgb, ambientLightmap);
	baseColor.rgb *= ambientLightmap;


/* DRAWBUFFERS:0124 */

  gl_FragData[0] = vec4(baseColor.rgb / MAX_COLOR_RANGE, baseColor.a);
  gl_FragData[1] = vec4(encodeLightmap(lmcoord), encodeNormal(newNormal), normal.a);
	gl_FragData[3] = vec4(albedo.rgb, 0.0);

	#ifdef PBR
		gl_FragData[2] = vec4(hand? vec3(0.0) : PBRData(NdotUp, translucent), 1.0);
	#endif

}
