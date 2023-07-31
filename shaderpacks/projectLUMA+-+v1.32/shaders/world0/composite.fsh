#version 120

#include "lib/HDR.glsl"

//#define DEPTH_OF_FIELD
//#define DIRTY_LENS
#define LIGHT_SCATTERING 1 // [0 1 2]

varying vec2 texcoord;

uniform sampler2D colortex0;  // color
uniform sampler2D depthtex0;

uniform mat4 gbufferProjectionInverse;

uniform float near;
uniform float far;

/* OptiFine constants
const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA8;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16;
const int colortex5Format = RGBA16;
const int colortex6Format = R11F_G11F_B10F;
const bool colortex0Clear = false;
const bool colortex1Clear = true;
const bool colortex2Clear = true;
const bool colortex3Clear = false;
const bool colortex4Clear = true;
const bool colortex5Clear = false;
const bool colortex6Clear = false;
const bool colortex7Clear = true;
*/

const float sunPathRotation = -30.0f;
const int	noiseTextureResolution = 1;
#ifdef DEPTH_OF_FIELD
	const float centerDepthHalflife = 2.0f;	// [0.0f 0.2f 0.4f 0.6f 0.8f 1.0f 1.2f 1.4f 1.6f 1.8f 2.0f] Transition for focus.
#endif

#ifdef DIRTY_LENS
	uniform sampler2D colortex1;
#endif

#if (LIGHT_SCATTERING == 1)

	uniform sampler2D depthtex1;
	uniform mat4 gbufferProjection;
	uniform vec3 sunPosition;

	float prerenderGodrays(vec3 fragpos, float comp) {

		const int	godraysSamples = 6;

		float grSample = 0.0;

		vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
				 tpos = vec4(tpos.xyz / tpos.w, 1.0);
		vec2 pos = tpos.xy / tpos.z;
		vec2 lightPos = pos * 0.5 + 0.5;

		vec2 grCoord = texcoord.st;
		vec2 deltaTextCoord	 = texcoord.st - lightPos.xy;
				 deltaTextCoord	/= float(godraysSamples);  // 1 / 12 = 0.083

		float distx = abs(texcoord.x - lightPos.x);
		float disty = abs(texcoord.y - lightPos.y);

		for (int i = 0; i < godraysSamples; i++) {

			grCoord	-= deltaTextCoord * 0.7;

			if (grCoord.y < 1.0 && grCoord.x > 0.0 && grCoord.x < 1.0 && texture2D(depthtex1, grCoord).x > comp) {
				grSample += 1.0;
			}

		}

		grSample /= float(godraysSamples);

		return grSample;

	}

#endif

void main() {

  vec3 color = texture2D(colortex0, texcoord).rgb;

	vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord.st, texture2D(depthtex0, texcoord).x, 1.0) * 2.0 - 1.0);
	     fragposition0 /= fragposition0.w;

	float comp = 1.0 - near / far / far;

/* DRAWBUFFERS:42 */

	#if (LIGHT_SCATTERING == 1)
  	gl_FragData[0] = vec4(color, prerenderGodrays(fragposition0.xyz, comp));
	#else
		gl_FragData[0] = vec4(color, 1.0);
	#endif

	#ifdef DIRTY_LENS
		bool emissive = texture2D(colortex1, texcoord).a > 0.29 && texture2D(colortex1, texcoord).a < 0.31;
		gl_FragData[1] = vec4(color * float(emissive), texture2D(colortex1, texcoord).a);
	#endif

}
