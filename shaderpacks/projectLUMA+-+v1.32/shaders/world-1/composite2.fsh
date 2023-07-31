#version 120

#include "lib/HDR.glsl"

//#define MOTIONBLUR
	#define MOTIONBLUR_AMOUNT 1.0 // [0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6 1.8 2.0]

varying vec2 texcoord;

uniform sampler2D colortex4;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;

uniform vec3 sunPosition;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferPreviousModelView;
uniform mat4 gbufferProjection;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;

uniform float near;
uniform float far;

float ditherGradNoise() {
	return fract(52.9829189*fract(0.06711056*gl_FragCoord.x + 0.00583715*gl_FragCoord.y));
}

vec3 doMotionblur(vec3 color) {

	const int	motionblurSamples	= 8;

	#ifdef MOTIONBLUR

		vec4 currentPosition = vec4(texcoord.x * 2.0 - 1.0, texcoord.y * 2.0 - 1.0, 2.0 * texture2D(depthtex2, texcoord.st).x - 1.0, 1.0);

		vec4 fragposition = gbufferProjectionInverse * currentPosition;
		fragposition = gbufferModelViewInverse * fragposition;
		fragposition /= fragposition.w;
		fragposition.xyz += cameraPosition;

		vec4 previousPosition = fragposition;
		previousPosition.xyz -= previousCameraPosition;
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		previousPosition /= previousPosition.w;

		vec2 velocity = (currentPosition - previousPosition).st * MOTIONBLUR_AMOUNT * 0.02;
		velocity = clamp(sqrt(dot(velocity, velocity)), 0.0, MOTIONBLUR_AMOUNT * 0.02) * normalize(velocity);

		int samples = 1;

		vec2 coord = texcoord.st + velocity;

		for (int i = 0; i < motionblurSamples; ++i, coord += velocity) {

			if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) break;

			color += texture2D(colortex4, coord).rgb * MAX_COLOR_RANGE;
			++samples;

		}

		color = color / samples;

	#endif

	return color;

}

void main() {

	vec4 tpos = vec4(sunPosition, 1.0) * gbufferProjection;
			 tpos = vec4(tpos.xyz / tpos.w, 1.0);
	vec2 pos = tpos.xy / tpos.z;
	vec2 lightPos = pos * 0.5 + 0.5;

	float comp = 1.0 - near / far / far;

	vec3 color = texture2D(colortex4, texcoord).rgb * MAX_COLOR_RANGE;

/* DRAWBUFFERS:4 */

	gl_FragData[0] = vec4(doMotionblur(color) / MAX_COLOR_RANGE, float(texture2D(depthtex1, lightPos).x > comp));


}
