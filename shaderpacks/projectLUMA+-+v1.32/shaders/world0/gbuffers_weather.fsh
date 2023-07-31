#version 120

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 normal;
varying vec4 color;

uniform sampler2D texture;

uniform vec3 upPosition;

uniform int worldTime;
uniform float sunAngle;
uniform float rainStrength;
uniform float screenBrightness;
uniform float nightVision;
uniform float frameTimeCounter;

#include "lib/timeArray.glsl"

float luma(vec3 clr) {
	return dot(clr, vec3(0.3333));
}

#include "lib/common/getTorchLightmap.glsl"
#include "lib/common/lowlightEye.glsl"

void main() {

  vec4 baseColor = texture2D(texture, texcoord) * color;
  baseColor.rgb = vec3(luma(baseColor.rgb));

	#include "lib/colors.glsl"



	float minLight = 0.03 + screenBrightness * 0.06;

	vec3 ambientLightmap = minLight + luma(ambientColor) * mix(lmcoord.y, 1.0, nightVision) + getTorchLightmap(normal.rgb, lmcoord.x, lmcoord.y, false) * torchColor;

	baseColor.rgb = lowlightEye(baseColor.rgb, ambientLightmap);
	baseColor.rgb *= ambientLightmap;

/* DRAWBUFFERS:7 */

  gl_FragData[0] = baseColor;

}
