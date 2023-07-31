#version 120

#include "lib/HDR.glsl"

//#define DEPTH_OF_FIELD
//#define DIRTY_LENS

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

void main() {

  vec3 color = texture2D(colortex0, texcoord).rgb;

	vec4 fragposition0  = gbufferProjectionInverse * (vec4(texcoord.st, texture2D(depthtex0, texcoord).x, 1.0) * 2.0 - 1.0);
	     fragposition0 /= fragposition0.w;

	float comp = 1.0 - near / far / far;

/* DRAWBUFFERS:42 */

	gl_FragData[0] = vec4(color, 1.0);

	#ifdef DIRTY_LENS
		bool emissive = texture2D(colortex1, texcoord).a > 0.29 && texture2D(colortex1, texcoord).a < 0.31;
		gl_FragData[1] = vec4(color * float(emissive), texture2D(colortex1, texcoord).a);
	#endif

}
