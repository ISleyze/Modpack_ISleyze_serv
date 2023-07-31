#version 120
#extension GL_ARB_shader_texture_lod : enable

#include "lib/HDR.glsl"

#define TONEMAPPING		// Disable it, when you want to keep the originals colors.
	#define SATURATION 1.0		// [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define EXPOSURE 1.0		// [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define BRIGHTNESS 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
	#define CONTRAST 1.0		// [0.1 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5]
	#define WHITESCALE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
//#define CHROMATIC_ABERRATION
//#define VIGNETTE
#define LENS_FLARE
//#define BLOOM
//#define DEPTH_OF_FIELD
//#define FILM_GRAIN
//#define CINEMATIC_MODE

varying vec2 texcoord;

uniform sampler2D colortex4;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;

float ditherGradNoise() {
  return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y));
}

#ifdef TONEMAPPING

	float A = 0.2 * EXPOSURE;
	float B = 0.40;
	float C = 0.10 * BRIGHTNESS;
	float D = 0.60;
	float E = 0.022 * CONTRAST;
	float F = 0.30;
	float W = 9.8 * WHITESCALE;

	vec3 Uncharted2Tonemap(vec3 x) {
		return (( x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
	}

	float Uncharted2Tonemap(float x) {
		return (( x * (A * x + C * B) + D * E) / (x * (A * x + B) + D * F)) - E / F;
	}

	vec3 tonemapping(vec3 color) {

		// Saturation
		color = mix(color, vec3(dot(color, vec3(0.3333))), -SATURATION * 1.1 + 1.0);

		color = pow(color, vec3(2.2));

		color = Uncharted2Tonemap(color * 8.0);

		float whiteScale = 1.0 / Uncharted2Tonemap(W);
		color = color * whiteScale;

		color = pow(color, vec3(0.4545));

		return color;

	}

#endif

// TODO: Sharpness Effekt

#ifdef FILM_GRAIN

	uniform float frameTimeCounter;

	float rand(vec2 coord) {
	  return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 43758.5453);
	}

	vec3 filmgrain(vec3 color) {

		const float noiseAmount = 0.03;

		vec2 coord = texcoord + frameTimeCounter * 0.01;

		vec3 noise = vec3(0.0);
				 noise.r = rand(coord + 0.1);
				 noise.g = rand(coord);
				 noise.b = rand(coord - 0.1);

		return color * (1.0 - noiseAmount + noise * noiseAmount) + noise * noiseAmount;

	}

#endif

#ifdef VIGNETTE

	vec3 vignette(vec3 color) {

		float vignetteStrength	= 1.0;
		float vignetteSharpness	= 3.0;

		float dist = 1.0 - pow(distance(texcoord.st, vec2(0.5)), vignetteSharpness) * vignetteStrength;

		return color * dist;

	}

#endif

#ifdef CHROMATIC_ABERRATION

	vec3 doChromaticAberration(vec2 coord) {

		const float offsetMultiplier	= 0.004;

		float dist = pow(distance(coord.st, vec2(0.5)), 2.5);

		vec3 color = vec3(0.0);

		color.r = texture2D(colortex4, coord.st + vec2(offsetMultiplier * dist, 0.0)).r;
		color.g = texture2D(colortex4, coord.st).g;
		color.b = texture2D(colortex4, coord.st - vec2(offsetMultiplier * dist, 0.0)).b;

		return color * MAX_COLOR_RANGE;

	}

#endif

#ifdef LENS_FLARE

	uniform mat4 gbufferProjection;
	uniform vec3 sunPosition;
	uniform ivec2 eyeBrightness;
	uniform int isEyeInWater;
	uniform int worldTime;

	#include "lib/timeArray.glsl"

	float drawCircle(float radius, float edge, float lensDist) {

		vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
				 tpos = vec4(tpos.xyz / tpos.w, 1.0);
		vec2 pos = tpos.xy / tpos.z * lensDist;
		vec2 lightPos = pos * 0.5 + 0.5;

		vec2 coord = (texcoord - lightPos) / radius;

		float circle = 1.0 - clamp(pow(coord.x * aspectRatio, 2.0) + pow(coord.y, 2.0), 0.0, 1.0);

		return smoothstep(0.0, 1.0 - edge, circle);

	}

	mat2 rotate2d(float angle){
	  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
	}

	float drawHorizontal(float size, float angle, float edge, float lensDist) {

		vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
				 tpos = vec4(tpos.xyz / tpos.w, 1.0);
		vec2 pos = tpos.xy / tpos.z * lensDist;
		vec2 lightPos = pos * 0.5 + 0.5;

		vec2 coord = (texcoord - lightPos) * rotate2d(angle);

		return 1.0 - clamp(abs(0.0 - coord.y * 2.0 / size), 0.0, 1.0);

	}

	vec3 lensFlare(vec3 color) {

		float lensPower = 0.2;

		vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
				 tpos = vec4(tpos.xyz / tpos.w, 1.0);
		vec2 pos = tpos.xy / tpos.z;
		vec2 lightPos = pos * 0.5 + 0.5;

		float distof = min(clamp(1.2 - lightPos.x, 0.0, lightPos.x), clamp(1.2 - lightPos.y, 0.0, lightPos.y));
		float sunVisibility = texture2D(colortex4, vec2(0.0)).a * distof;

		lensPower *= (1.0 - time[5]) * (1.0 - time[6]) * (1.0 - rainStrength) * float(sunPosition.z < 0.0);
		if (isEyeInWater == 1) lensPower *= eyeBrightness.y / 240.0;

		vec3 flare1 = max(drawCircle(0.3, 0.8, -0.5) - drawCircle(0.3, 0.8, -0.45), 0.0) * vec3(1.0, 0.5, 0.0);
		vec3 flare2 = max(drawCircle(0.3, 0.8, -0.55) - drawCircle(0.3, 0.8, -0.5), 0.0) * vec3(0.5, 1.0, 0.5);
		vec3 flare3 = max(drawCircle(0.3, 0.8, -0.6) - drawCircle(0.3, 0.8, -0.55), 0.0) * vec3(0.2, 0.5, 1.0);

		vec3 flare10 = drawCircle(0.02, 0.3, 0.2) * drawCircle(0.02, 0.3, 0.22) * vec3(1.0, 1.0, 0.0) * 0.5;
		vec3 flare9 = drawCircle(0.04, 0.5, 0.1) * drawCircle(0.04, 0.5, 0.15) * vec3(0.3, 1.0, 0.0) * 0.5;

		vec3 flare8 = drawCircle(0.01, 0.0, -0.1) * drawCircle(0.01, 0.0, -0.11) * vec3(0.0, 1.0, 0.0);

		vec3 flare4 = drawCircle(0.007, 0.0, -0.2) * drawCircle(0.007, 0.0, -0.21) * vec3(1.0, 0.5, 0.0);

		vec3 flare11 = drawCircle(0.07, 0.7, -0.15) * drawCircle(0.07, 0.7, -0.25) * vec3(0.0, 0.6, 1.0) * 0.5;

		vec3 flare5 = max(drawCircle(0.1, 0.7, -0.3) - drawCircle(0.13, 0.3, -0.25), 0.0) * vec3(1.0, 0.5, 0.0);
		vec3 flare6 = drawCircle(0.01, 0.2, -0.4) * drawCircle(0.01, 0.2, -0.41) * vec3(0.0, 1.0, 1.0);
		vec3 flare7 = max(drawCircle(0.07, 0.7, -0.5) - drawCircle(0.1, 0.2, -0.45), 0.0) * vec3(0.2, 0.5, 1.0);

		return color + (flare1 + flare2 + flare3 + flare4 + flare5 + flare6 + flare7 + flare8 + flare9 + flare10 + flare11) * sunVisibility * lensPower;

	}

#endif

#ifdef CINEMATIC_MODE

	vec3 blackBars(vec3 clr) {

		if (texcoord.t > 0.9 || texcoord.t < 0.1) clr.rgb = vec3(0.0);

		return clr;

	}

#endif

#ifdef DEPTH_OF_FIELD

	uniform sampler2D depthtex1;
	uniform float centerDepthSmooth;

	vec3 renderDOF(vec3 color, float depth) {

		const bool colortex4MipmapEnabled = true;
		const float blurFactor = 1.0;
		const float maxBlurFactor = 0.05;

		float focus	= depth - centerDepthSmooth;
		float factor = clamp(focus * blurFactor, -maxBlurFactor, maxBlurFactor);

		bool hand = depth < 0.56;
		if (hand) factor = 0.0;

		vec2 aspectcorrect = vec2(1.0, aspectRatio);

		vec2 offsets[4] = vec2[4](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0));

		vec3 blurSamples = vec3(0.0);

		for (int i = 0; i < 4; i++) {

			#ifdef CHROMATIC_ABERRATION

				float dist = pow(distance(texcoord.st, vec2(0.5)), 2.5);

				blurSamples.r += texture2DLod(colortex4, texcoord + (offsets[i] + vec2(5.0 * dist, 0.0)) * factor * 0.05 * aspectcorrect, abs(factor) * 60.0).r;
				blurSamples.g += texture2DLod(colortex4, texcoord + offsets[i] * factor * 0.05 * aspectcorrect, abs(factor) * 60.0).g;
				blurSamples.b += texture2DLod(colortex4, texcoord + (offsets[i] - vec2(5.0 * dist, 0.0)) * factor * 0.05 * aspectcorrect, abs(factor) * 60.0).b;

			#else

				blurSamples += texture2DLod(colortex4, texcoord + offsets[i] * factor * 0.05 * aspectcorrect, abs(factor) * 60.0).rgb;

			#endif

		}

		return blurSamples * 0.25 * MAX_COLOR_RANGE;

	}

#endif

#ifdef BLOOM

	uniform sampler2D colortex0;

	vec3 bloom(vec3 color) {

		vec3 bloomSample = vec3(0.0);

		vec2 offsets[4] = vec2[4](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0));
		vec2 offsets2[4] = vec2[4](vec2(-1.0, 1.0), vec2(-1.0, -1.0), vec2(1.0, -1.0), vec2(1.0, 1.0));
		vec2 aspectcorrect = vec2(1.0, aspectRatio);

		const bool colortex0MipmapEnabled = true;

		float pw = 1.0 / viewWidth;
		float ph = 1.0 / viewHeight;

		for (int i = 0; i < 4; i++) {

			bloomSample += texture2DLod(colortex0, texcoord * 0.5 + offsets2[i] * aspectcorrect * 0.01, 2.0).rgb;
			bloomSample += texture2DLod(colortex0, texcoord * 0.5 + offsets[i] * aspectcorrect * 0.01, 2.0).rgb;
			bloomSample += texture2DLod(colortex0, texcoord * 0.5 + vec2(0.5, 0.5) + offsets[i] * aspectcorrect * 0.001, 1.5).rgb * 2.0;

		}

		// TODO: Mehr Bloom unterwasser
		return color + pow(bloomSample, vec3(3.0)) * 0.07;

	}

#endif

void main() {

  vec3 color = texture2D(colortex4, texcoord).rgb * MAX_COLOR_RANGE;

	#ifdef CHROMATIC_ABERRATION
		color = doChromaticAberration(texcoord);
	#endif

	#ifdef DEPTH_OF_FIELD
		color = renderDOF(color, texture2D(depthtex1, texcoord).x);
	#endif

	#ifdef FILM_GRAIN
		color = filmgrain(color);
	#endif

	#ifdef LENS_FLARE
		color = lensFlare(color);
	#endif

	#ifdef BLOOM

		color = pow(color, vec3(2.2));
		color = bloom(color);
		color = pow(color, vec3(0.4545));

	#endif

	#ifdef TONEMAPPING
		color = tonemapping(color);
	#endif

	#ifdef VIGNETTE
		color = vignette(color);
	#endif

	#ifdef CINEMATIC_MODE
		color = blackBars(color);
	#endif

	color += ditherGradNoise() / 255.0;

  gl_FragColor = vec4(color, 1.0);

}
