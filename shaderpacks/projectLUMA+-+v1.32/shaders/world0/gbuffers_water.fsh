#version 120
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

#include "lib/HDR.glsl"

#define SSR_METHOD 0 // [0 1] 0 = Flipped image, 1 = Raytracer
#define NORMAL_MAP_BUMPMULT 1.0 // [0.0 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]
#define TEMPERATURE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

#define colortex6 gaux3

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec4 color;
varying vec4 position2;
varying vec4 worldposition;
varying vec3 tangent;
varying vec4 normal;
varying vec3 binormal;

uniform sampler2D texture;
uniform sampler2D normals;
uniform sampler2D gaux1;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform sampler2D noisetex;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform vec3 upPosition;
uniform vec3 sunPosition;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

uniform ivec2 eyeBrightness;

uniform int isEyeInWater;
uniform int worldTime;

uniform float rainStrength;
uniform float near;
uniform float far;
uniform float sunAngle;
uniform float screenBrightness;
uniform float nightVision;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;

#include "lib/timeArray.glsl"

float luma(vec3 clr) {
	return dot(clr, vec3(0.3333));
}

float cdist(vec2 coord) {
	return max(abs(coord.s - 0.5), abs(coord.t - 0.5)) * 2.0;
}

float ditherGradNoise() {
  return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y));
}

bool material(float id) {

	if (normal.a > id - 0.01 && normal.a < id + 0.01) {
		return true;
	} else {
		return false;
	}

}

float encodeLightmap(vec2 a) {

  ivec2 bf = ivec2(a * 255.0);
  return float(bf.x | (bf.y << 8)) / 65535.0;

}

vec3 cameraSpaceToScreenSpace(vec3 fragpos) {

	vec4 pos  = gbufferProjection * vec4(fragpos, 1.0);
			 pos /= pos.w;

	return pos.xyz * 0.5 + 0.5;

}

vec3 cameraSpaceToWorldSpace(vec3 fragpos) {

	vec4 pos  = gbufferProjectionInverse * vec4(fragpos, 1.0);
			 pos /= pos.w;

	return pos.xyz;

}

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

mat2 rotate2d(float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec2 projectSky(vec3 dir, float rotation) {

  const ivec2 resolution     = ivec2(8192, 3072);
  const vec2  tileSize       = resolution / vec2(4, 3);
  const vec2  tileSizeDivide = (0.5 * tileSize) - 1.5;

  dir.xz *= rotate2d(-rotation);
  dir.xyz = vec3(dir.z, -dir.y, -dir.x);

  vec2 coord = vec2(0.0);
  if (abs(dir.y) > abs(dir.x) && abs(dir.y) > abs(dir.z)) {
    dir /= abs(dir.y);
    coord.x = dir.x * tileSizeDivide.x + tileSize.x * 1.5;
    coord.y = -(dir.y < 0.0 ? 1 : -1) * dir.z * tileSizeDivide.y + tileSize.y * (dir.y < 0.0 ? 0.5 : 2.5);
  } else if (abs(dir.x) > abs(dir.y) && abs(dir.x) > abs(dir.z)) {
    dir /= abs(dir.x);
    coord.x = (dir.x < 0.0 ? -1 : 1) * dir.z * tileSizeDivide.x + tileSize.x * (dir.x < 0.0 ? 0.5 : 2.5);
    coord.y = dir.y * tileSizeDivide.y + tileSize.y * 1.5;
  } else {
    dir /= abs(dir.z);
    coord.x = (dir.z < 0.0 ? 1 : -1) * dir.x * tileSizeDivide.x + tileSize.x * (dir.z < 0.0 ? 1.5 : 3.5);
    coord.y = dir.y * tileSizeDivide.y + tileSize.y * 1.5;
  }

  return coord / resolution;

}

vec3 getSkyTextureFromSequence(vec3 pos) {

	vec4 worldPos = gbufferModelViewInverse * vec4(pos.xyz, 1.0);

  float rotation = (clamp(worldTime > 21000.0? 0.0 : worldTime, 0.0, 12000.0) / 24000.0) * 5.0;

	// config = vec4(x offset, y offset, time, rotation offset)
  vec4 config[2] = vec4[2](vec4(0.0), vec4(0.0));

  vec3 first = vec3(0.0);
  vec3 second = vec3(0.0);
  vec3 rain = vec3(0.0);
  vec3 stars = vec3(0.0);

  if (time[0] > 0.01) {
    config[0] = vec4(0.0, 0.0, time[0], 0.0);
  } else if (time[2] > 0.01) {
    config[0] = vec4(0.5, 0.0, time[2], 0.0);
  } else if (time[4] > 0.01) {
    config[0] = vec4(0.75, 0.0, time[4], 0.55);
  }

  if (time[1] > 0.01) {
    config[1] = vec4(0.25, 0.0, time[1], 0.0);
  } else if (time[3] > 0.01) {
    config[1] = vec4(0.25, 0.0, time[3], 0.0);
  } else if (time[5] > 0.01) {
    config[1] = vec4(0.0, 0.5, time[5] * mix(0.2 * (1.0 + screenBrightness), 1.0, nightVision), 0.0);
  }

  if (rainStrength < 1.0) {
    first = texture2D(gaux4, projectSky(worldPos.xyz, rotation + config[0].w) * vec2(0.25, 0.5) + config[0].xy).rgb * config[0].z * (1.0 - rainStrength);
    second = texture2D(gaux4, projectSky(worldPos.xyz, rotation + config[1].w) * vec2(0.25, 0.5) + config[1].xy).rgb * config[1].z * (1.0 - rainStrength);
    if (time[5] > 0.0) stars = texture2D(gaux4, projectSky(worldPos.xyz, worldTime / 12000.0) * vec2(0.25, 0.5) + vec2(0.25, 0.5)).rgb * time[5] * (1.0 - rainStrength);
  }

  if (rainStrength > 0.0) {
    if (time[5] > 0.0) rain = texture2D(gaux4, projectSky(worldPos.xyz, worldTime / 12000.0) * vec2(0.25, 0.5) + vec2(0.0, 0.5)).rgb * time[5] * mix(0.1 * (1.0 + screenBrightness), 1.0, nightVision) * rainStrength;
    rain += texture2D(gaux4, projectSky(worldPos.xyz, worldTime / 3000.0) * vec2(0.25, 0.5) + vec2(0.5, 0.5)).rgb * rainStrength * mix(1.0, 0.04 + screenBrightness * 0.04, time[5] * (1.0 - nightVision));
  }

	return first + second + rain + (stars * 0.3 + max(stars - 0.1, 0.0));

}

float waterWaves(vec3 worldPos) {

  float wave = 0.0;

  worldPos.z += worldPos.y;
	worldPos.x += worldPos.y;

  worldPos.z *= 0.5;
  worldPos.x += sin(worldPos.x) * 0.3;

  wave  = texture2D(noisetex, worldPos.xz * 0.1 + vec2(frameTimeCounter * 0.03)).x * 0.1;
	wave += texture2D(noisetex, worldPos.xz * 0.02 - vec2(frameTimeCounter * 0.015)).x * 0.5;
	wave += texture2D(noisetex, worldPos.xz * 0.02 * rotate2d(0.5) + vec2(frameTimeCounter * 0.015)).x * 0.5;

  return wave * 0.4;

}

vec3 waterwavesToNormal(vec3 pos) {

  float deltaPos = 0.1;
	float h0 = waterWaves(pos.xyz);
	float h1 = waterWaves(pos.xyz + vec3(deltaPos, 0.0, 0.0));
	float h2 = waterWaves(pos.xyz + vec3(-deltaPos, 0.0, 0.0));
	float h3 = waterWaves(pos.xyz + vec3(0.0, 0.0, deltaPos));
	float h4 = waterWaves(pos.xyz + vec3(0.0, 0.0, -deltaPos));

	float xDelta = ((h1 - h0) + (h0 - h2)) / deltaPos;
	float yDelta = ((h3 - h0) + (h0 - h4)) / deltaPos;

	return normalize(vec3(xDelta, yDelta, 1.0 - xDelta * xDelta - yDelta * yDelta));

}

vec3 getNormals() {

	vec2 dcdx = dFdx(texcoord);
	vec2 dcdy = dFdy(texcoord);

	vec3 bump  = texture2DGradARB(normals, texcoord, dcdx, dcdy).rgb * 2.0 - 1.0;
			 bump *= vec3(NORMAL_MAP_BUMPMULT) + vec3(0.0, 0.0, 1.0 - NORMAL_MAP_BUMPMULT);

  if (material(0.1) || material(0.17)) {

		float NdotE = abs(dot(normal.xyz, normalize(position2.xyz)));

		bump  = waterwavesToNormal(worldposition.xyz);
		bump *= vec3(NdotE) + vec3(0.0, 0.0, 1.0 - NdotE);

	}

	mat3 tbnMatrix = mat3(tangent.x, binormal.x, normal.x,
						  					tangent.y, binormal.y, normal.y,
						  					tangent.z, binormal.z, normal.z);

	return normalize(bump * tbnMatrix);

}

#include "lib/fog.glsl"

vec4 raytrace(vec3 fragpos, vec3 normal) {

	#if (SSR_METHOD == 0)

    vec3 reflectedVector = reflect(normalize(fragpos), normal) * 30.0;
    vec3 pos = cameraSpaceToScreenSpace(fragpos + reflectedVector);

    float border = clamp((1.0 - (max(0.0, abs(pos.t - 0.5)) * 2.0)) * 50.0, 0.0, 1.0);

    return vec4(texture2DLod(gaux2, pos.xy, 0.0).rgb * MAX_COLOR_RANGE, border);

	#else

		float dither    = ditherGradNoise();

		const int samples       = 28;
		const int maxRefinement = 10;
		const float stepSize    = 1.2;
		const float stepRefine  = 0.28;
		const float stepIncrease = 1.8;

		vec3 col        = vec3(0.0);
		vec3 rayStart   = fragpos;
		vec3 rayDir     = reflect(normalize(fragpos), normal);
		vec3 rayStep    = (stepSize+dither-0.5)*rayDir;
		vec3 rayPos     = rayStart + rayStep;
		vec3 rayPrevPos = rayStart;
		vec3 rayRefine  = rayStep;

		int refine  = 0;
		vec3 pos    = vec3(0.0);
		float border = 0.0;

		for (int i = 0; i < samples; i++) {

			pos = cameraSpaceToScreenSpace(rayPos);

			if (pos.x<0.0 || pos.x>1.0 || pos.y<0.0 || pos.y>1.0 || pos.z<0.0 || pos.z>1.0) break;

			vec3 screenPos  = vec3(pos.xy, texture2D(depthtex1, pos.xy).x);
					 screenPos  = cameraSpaceToWorldSpace(screenPos * 2.0 - 1.0);

			float dist = distance(rayPos, screenPos);

			if (dist < pow(length(rayStep)*pow(length(rayRefine), 0.11), 1.1)*1.22) {

				refine++;
				if (refine >= maxRefinement)	break;

				rayRefine  -= rayStep;
				rayStep    *= stepRefine;

			}

			rayStep        *= stepIncrease;
			rayPrevPos      = rayPos;
			rayRefine      += rayStep;
			rayPos          = rayStart+rayRefine;

		}

		if (pos.z < 1.0-1e-5) {

			float depth = texture2D(depthtex0, pos.xy).x;

			float comp = 1.0 - near / far / far;
			bool land = depth < comp;

			if (land) {
				col = texture2D(gaux2, pos.xy).rgb * MAX_COLOR_RANGE;
				border = clamp((1.0 - cdist(pos.st)) * 50.0, 0.0, 1.0);
			}

		}

		return vec4(col, border);

	#endif

}

vec3 drawSun(vec3 fragpos, vec3 sunColor) {

	float sunVector = max(dot(normalize(fragpos), normalize(sunPosition)), 0.0);
	return smoothstep(0.997, 1.0, sunVector) * (1.0 - time[6]) * sunColor * 12.0;

}

vec3 waterShader(vec3 fragpos, vec3 normal, vec3 color, vec3 waterColor, vec3 sunColor, float shading) {

  vec3 reflectedVector = reflect(normalize(fragpos), normal) * 300.0;

	vec4 reflection = raytrace(fragpos, normal);

	float normalDotEye = dot(normal.rgb, normalize(fragpos));
	float fresnel = clamp(pow(1.0 + normalDotEye, 4.0) + 0.1, 0.0, 1.0);

	vec3 skyReflection = pow(getSkyTextureFromSequence(fragpos + reflectedVector), vec3(1.3));
			 skyReflection = mix(skyReflection, skyReflection * vec3(0.0, 0.5, 1.0), (1.0 - TEMPERATURE) * 0.25);
  if (isEyeInWater == 1) skyReflection = waterColor * vec3(0.6, 1.0, 0.8) * 0.2;

	reflection.rgb = mix(skyReflection * pow(lmcoord.t, 2.0), reflection.rgb, reflection.a);

	return mix(color, reflection.rgb, fresnel) + drawSun(reflectedVector, sunColor) * (1.0 - reflection.a) * shading;

}

#include "lib/common/getTorchLightmap.glsl"
#include "lib/common/lowlightEye.glsl"

#include "lib/underwaterDepth.glsl"
#include "lib/calcUnderwaterColor.glsl"

vec3 refraction(vec3 fragpos, vec3 color, vec3 waterColor) {

	float	waterRefractionStrength = 0.1;
	float rgbOffset = 0.01;

  vec3 pos = cameraSpaceToScreenSpace(fragpos);
	vec2 waterTexcoord = pos.xy;

	waterRefractionStrength /= 1.0 + length(fragpos) * 0.4;
	rgbOffset *= waterRefractionStrength;

	vec3 waterRefract = waterwavesToNormal(worldposition.xyz);

	waterTexcoord = pos.xy + waterRefract.xy * waterRefractionStrength;

	vec3 watercolor1   = vec3(0.0);
			 watercolor1.r = texture2D(gaux1, waterTexcoord.st + rgbOffset).r;
			 watercolor1.g = texture2D(gaux1, waterTexcoord.st).g;
			 watercolor1.b = texture2D(gaux1, waterTexcoord.st - rgbOffset).b;

  vec3 watercolor2   = vec3(0.0);
  		 watercolor2.r = texture2D(gaux2, waterTexcoord.st + rgbOffset).r;
  		 watercolor2.g = texture2D(gaux2, waterTexcoord.st).g;
  		 watercolor2.b = texture2D(gaux2, waterTexcoord.st - rgbOffset).b;

  float depth = underwaterDepth(fragpos, toNDC(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), texture2D(depthtex1, waterTexcoord).x)));

  vec3 watercolor = mix(calcUnderwaterColor(watercolor2 * MAX_COLOR_RANGE, waterColor * mix(lmcoord.x, 1.0, nightVision), depth), watercolor1 * MAX_COLOR_RANGE, min(lmcoord.t + 0.1, 1.0));

	if (material(0.1)) color = watercolor;

	return color;

}

void main() {

  vec4 baseColor = texture2D(texture, texcoord) * color;

  vec3 fragposition0 = toNDC(vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z));

  #include "lib/colors.glsl"



	float minLight = 0.03 + screenBrightness * 0.06;

	vec3 ambientLightmap = minLight + luma(ambientColor) * mix(lmcoord.y, 1.0, nightVision) + getTorchLightmap(normal.rgb, lmcoord.x, lmcoord.y, false) * torchColor;

	baseColor.rgb = lowlightEye(baseColor.rgb, ambientLightmap);
	baseColor.rgb *= ambientLightmap;

  if (material(0.1)) baseColor = vec4(refraction(fragposition0, baseColor.rgb, waterColor), 1.0);

	baseColor.rgb = renderFog(fragposition0.xyz, baseColor.rgb, ambientColor);
  if (material(0.1) || material(0.19)) baseColor.rgb = waterShader(fragposition0.xyz, getNormals(), baseColor.rgb, waterColor * ambientColor, mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.9, 0.8), sunFactor) * (1.0 - rainStrength), lmcoord.y > 0.9? 1.0 : 0.0);

/* DRAWBUFFERS:01 */

  gl_FragData[0] = vec4(baseColor.rgb / MAX_COLOR_RANGE, baseColor.a);
  gl_FragData[1] = vec4(encodeLightmap(lmcoord), 0.0, 0.0, normal.a);

}
