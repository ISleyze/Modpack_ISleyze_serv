#version 120

#include "lib/HDR.glsl"

//#define DISTANCE_BLUR
//#define RAINDROP_REFRACTION
#define HEATWAVE

varying vec2 texcoord;

uniform sampler2D colortex1;
uniform sampler2D colortex7;
uniform sampler2D colortex4;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

uniform vec3 sunPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform int worldTime;
uniform int isEyeInWater;

uniform ivec2 eyeBrightness;

uniform float near;
uniform float far;
uniform float sunAngle;
uniform float rainStrength;
uniform float nightVision;
uniform float blindness;

#include "lib/timeArray.glsl"

#ifdef HEATWAVE
	uniform float frameTimeCounter;
#endif

vec3 blindnessFog(vec3 fragpos, vec3 color) {

  float fogFactor = 1.0 - exp(-pow(length(fragpos) * 0.4, 1.0));

  return color * (1.0 - blindness * fogFactor);

}

#include "lib/common/underwaterFog.glsl"

#ifdef DISTANCE_BLUR

	vec3 distanceBlur(vec2 coord, vec3 fragpos) {

		const bool colortex4MipmapEnabled = true;

		float depth = 1.0 - exp(-pow(length(fragpos.xyz) * 0.005, 2.0));

	  return texture2DLod(colortex4, coord, depth).rgb * MAX_COLOR_RANGE;

	}

#endif


void main() {

  // x = 0; y = 1
	vec2 depth = vec2(texture2D(depthtex0, texcoord).x, texture2D(depthtex1, texcoord).x);

  float mat = texture2D(colortex1, texcoord).a;


  vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord.st, depth.x, 1.0) * 2.0 - 1.0);
	     fragposition0 /= fragposition0.w;

	vec4 fragposition1  = gbufferProjectionInverse * (vec4(texcoord.st, depth.y, 1.0) * 2.0 - 1.0);
	     fragposition1 /= fragposition1.w;

  float comp = 1.0 - near / far / far;

  bool sky = depth.y > comp;
  bool land = depth.y < comp;

	bool hand = depth.x < 0.56;

  bool water = mat > 0.09 && mat < 0.11;
	bool gbuffers_water = mat > 0.09 && mat < 0.2;

	vec4 raindrops = texture2D(colortex7, texcoord);
	vec2 refraction = vec2(0.0);

	#ifdef RAINDROP_REFRACTION
		refraction = vec2(0.0, 0.015 * raindrops.a);
	#endif

	#ifdef HEATWAVE

		float	refractionMultiplier = 0.0005;
		float	refractionSpeed	= 5.0;
		float refractionSize = 2.0;
		float refractionStart = 75.0;

		float fogFactor = (1.0 - exp(-pow(length(fragposition1.xyz) / refractionStart, 2.0)));

		refraction += vec2(sin(frameTimeCounter * refractionSpeed + texcoord.x * 50.0 * refractionSize + texcoord.y * 25.0 * refractionSize)) * refractionMultiplier * fogFactor;

	#endif

  vec3 color = texture2D(colortex4, texcoord + refraction).rgb * MAX_COLOR_RANGE;

  #ifdef DISTANCE_BLUR
   	color = distanceBlur(texcoord + refraction, fragposition1.xyz);
  #endif


	vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
			 tpos = vec4(tpos.xyz / tpos.w, 1.0);
	vec2 pos = tpos.xy / tpos.z;
	vec2 lightPos = pos * 0.5 + 0.5;

  #include "lib/colors.glsl"

	// Render fog on top of gbuffers_water
	if (gbuffers_water) color = underwaterFog(fragposition0.xyz, color, ambientColor, lavaColor);

	if (!hand) color += raindrops.rgb * 0.2;

	color = blindnessFog(fragposition1.xyz, color);

/* DRAWBUFFERS:4 */

  gl_FragData[0] = vec4(color / MAX_COLOR_RANGE, float(texture2D(depthtex1, lightPos).x > comp));

}
