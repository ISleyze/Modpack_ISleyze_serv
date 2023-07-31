#version 120
#extension GL_EXT_gpu_shader4 : enable

#include "lib/HDR.glsl"

varying vec2 texcoord;
varying vec3 normal;
varying vec4 color;
varying vec2 lmcoord;

uniform sampler2D texture;

float encodeLightmap(vec2 a) {

  ivec2 bf = ivec2(a * 255.0);
  return float(bf.x | (bf.y << 8)) / 65535.0;

}

vec2 encodeNormal(vec3 normal) {

  return normal.xy * inversesqrt(normal.z * 8.0 + 8.0) + 0.5;

}

void main() {

  vec4 baseColor = texture2D(texture, texcoord) * color;

/* DRAWBUFFERS:012 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

  gl_FragData[0] = vec4(baseColor.rgb * 4.0 / MAX_COLOR_RANGE, baseColor.a);
  gl_FragData[1] = vec4(encodeLightmap(lmcoord), encodeNormal(normal.rgb), 1.0);
  gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);

}
