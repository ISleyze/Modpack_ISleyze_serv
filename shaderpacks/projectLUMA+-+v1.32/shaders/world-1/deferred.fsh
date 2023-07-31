#version 120
#extension GL_EXT_gpu_shader4 : enable

#include "lib/HDR.glsl"

//#define AMBIENT_OCCLUSION
//#define PBR
//#define RAIN_PUDDLES
#define SSR_METHOD 0 // [0 1] 0 = Flipped image, 1 = Raytracer

varying vec2 texcoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;

uniform float near;
uniform float far;


float ditherGradNoise() {
  return fract(52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y));
}

vec3 decodeNormal(vec2 enc) {

  vec2 fenc = enc*4-2;
  float f = dot(fenc,fenc);
  float g = sqrt(1-f/4.0);
  vec3 n;
  n.xy = fenc*g;
  n.z = 1-f/2;
  return n;

}

#if defined PBR || defined RAIN_PUDDLES

	float cdist(vec2 coord) {
		return max(abs(coord.s - 0.5), abs(coord.t - 0.5)) * 2.0;
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

	vec4 raytrace(vec3 fragpos, vec3 normal) {

		#if (SSR_METHOD == 0)

			vec3 reflectedVector = reflect(normalize(fragpos), normal) * 30.0;
			vec3 pos = cameraSpaceToScreenSpace(fragpos + reflectedVector);

			float border = clamp(1.0 - pow(cdist(pos.st), 10.0), 0.0, 1.0);

			return vec4(texture2D(colortex0, pos.xy).rgb * MAX_COLOR_RANGE, border);

		#else

			const int samples       = 28;
			const int maxRefinement = 10;
			const float stepSize    = 1.2;
			const float stepRefine  = 0.28;
			const float stepIncrease = 1.8;

			vec3 col        = vec3(0.0);
			vec3 rayStart   = fragpos;
			vec3 rayDir     = reflect(normalize(fragpos), normal);
			vec3 rayStep    = (stepSize+ditherGradNoise()-0.5)*rayDir;
			vec3 rayPos     = rayStart + rayStep;
			vec3 rayPrevPos = rayStart;
			vec3 rayRefine  = rayStep;

			int refine  = 0;
			vec3 pos    = vec3(0.0);
			float edge  = 0.0;

			for (int i = 0; i < samples; i++) {

				pos = cameraSpaceToScreenSpace(rayPos);

				if (pos.x<0.0 || pos.x>1.0 || pos.y<0.0 || pos.y>1.0 || pos.z<0.0 || pos.z>1.0) break;

				vec3 screenPos  = vec3(pos.xy, texture2D(depthtex0, pos.xy).x);
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
					col = texture2D(colortex0, pos.xy).rgb * MAX_COLOR_RANGE;
					edge = clamp(1.0 - cdist(pos.st), 0.0, 1.0);
				}

			}

			return vec4(col, clamp(edge * 2.0, 0.0, 1.0));

		#endif

	}

#endif

#ifdef AMBIENT_OCCLUSION

	uniform float viewWidth;
	uniform float viewHeight;

	vec3 toScreenSpace(vec2 p) {
		vec4 fragposition = gbufferProjectionInverse * vec4(vec3(p, texture2D(depthtex0, p).x) * 2.0 - 1.0, 1.0);
		return fragposition.xyz /= fragposition.w;
	}

	int bitfieldReverse(int a) {
		a = ((a & 0x55555555) << 1 ) | ((a & 0xAAAAAAAA) >> 1);
		a = ((a & 0x33333333) << 2 ) | ((a & 0xCCCCCCCC) >> 2);
		a = ((a & 0x0F0F0F0F) << 4 ) | ((a & 0xF0F0F0F0) >> 4);
		a = ((a & 0x00FF00FF) << 8 ) | ((a & 0xFF00FF00) >> 8);
		a = ((a & 0x0000FFFF) << 16) | ((a & 0xFFFF0000) >> 16);
		return a;
	}

	#define hammersley(i, N) vec2( float(i) / float(N), float( bitfieldReverse(i) ) * 2.3283064365386963e-10 )
	#define tau 6.2831853071795864769252867665590
	#define circlemap(p) (vec2(cos((p).y*tau), sin((p).y*tau)) * p.x)

	float jaao(vec2 p, bool sky) {

		// By Jodie.

		const float radius = 1.0;
		const int steps = 16;

		float ao = 1.0;

		vec3 p3 = toScreenSpace(p);
		vec3 normal = normalize(cross(dFdx(p3), dFdy(p3)));
		vec2 clipRadius = radius * vec2(viewHeight / viewWidth, 1.0) / length(p3);

		vec3 v = normalize(-p3);

		float nvisibility = 0.0;
		float vvisibility = 0.0;

		for (int i = 0; i < steps; i++) {

			vec2 circlePoint = circlemap(hammersley(i * 15 + 1, 16 * steps)) * clipRadius;

			circlePoint *= ditherGradNoise() + 0.1;

			vec3 o  = toScreenSpace(circlePoint    +p) - p3;
			vec3 o2 = toScreenSpace(circlePoint*.25+p) - p3;
			float l  = length(o );
			float l2 = length(o2);
			o /=l ;
			o2/=l2;

			nvisibility += clamp(1.-max(
				dot(o , normal) - clamp((l -radius)/radius,0.,1.),
				dot(o2, normal) - clamp((l2-radius)/radius,0.,1.)
			), 0., 1.);

			vvisibility += clamp(1.-max(
				dot(o , v) - clamp((l -radius)/radius,0.,1.),
				dot(o2, v) - clamp((l2-radius)/radius,0.,1.)
			), 0., 1.);

		}

		ao = min(vvisibility * 2.0, nvisibility) / float(steps);

		if (sky) ao = 1.0;

		return ao;

	}

#endif


void main() {

  vec3 color = texture2D(colortex0, texcoord).rgb * MAX_COLOR_RANGE;
	vec3 normal = decodeNormal(texture2D(colortex1, texcoord).yz);

	float depth = texture2D(depthtex0, texcoord).x;

  vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord.st, depth, 1.0) * 2.0 - 1.0);
	     fragposition0 /= fragposition0.w;

	float comp = 1.0 - near / far / far;
	bool sky = depth > comp;

	#ifdef AMBIENT_OCCLUSION
		const float AOStrength = 0.6;
		color *= (1.0 - AOStrength) + jaao(texcoord, sky) * AOStrength;
	#endif


/* DRAWBUFFERS:05 */

  gl_FragData[0] = vec4(color / MAX_COLOR_RANGE, 1.0);
	#if defined PBR || defined RAIN_PUDDLES
		gl_FragData[1] = raytrace(fragposition0.xyz, normal);
	#endif

}
