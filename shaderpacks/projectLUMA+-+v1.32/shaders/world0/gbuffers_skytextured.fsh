#version 120

#include "lib/HDR.glsl"

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;
uniform sampler2D gaux4;

uniform vec3 sunPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform float viewWidth;
uniform float viewHeight;
uniform float sunAngle;

vec3 toNDC(vec3 pos){
	vec4 iProjDiag = vec4(gbufferProjectionInverse[0].x, gbufferProjectionInverse[1].y, gbufferProjectionInverse[2].zw);
    vec3 p3 = pos * 2. - 1.;
    vec4 fragpos = iProjDiag * p3.xyzz + gbufferProjectionInverse[3];
    return fragpos.xyz / fragpos.w;
}

void main() {

  vec4 baseColor = texture2D(texture, texcoord) * color;

  vec3 fragposition = toNDC(vec3(gl_FragCoord.xy / vec2(viewWidth,viewHeight), gl_FragCoord.z));

	float sunFactor = clamp(1.0 - pow(abs(-0.25 + sunAngle) * 4.0, 2.0 / (abs(-0.25 + sunAngle) * 4.0)), 0.0, 1.0);

  float sunVector = max(dot(normalize(fragposition), normalize(sunPosition)), 0.0);
  float sun	= pow(sunVector, 100.0) * 0.5 + smoothstep(0.997, 1.0, sunVector) * 12.0;

  // Remove the default sun
  if (sunVector > 0.0) baseColor.rgb *= 0.0;
  // Draw the new sun on top
  baseColor.rgb += sun * mix(vec3(1.0, 0.5, 0.0), vec3(1.0, 0.9, 0.8), sunFactor);

		baseColor.rgb /= MAX_COLOR_RANGE;

/* DRAWBUFFERS:0 */

  gl_FragData[0] = baseColor;

}
