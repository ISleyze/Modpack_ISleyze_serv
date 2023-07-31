#version 120

#include "lib/HDR.glsl"

varying vec2 texcoord;
varying vec4 color;

uniform sampler2D texture;

void main() {

  vec4 baseColor = texture2D(texture, texcoord) * color;

/* DRAWBUFFERS:0 */

  gl_FragData[0] = vec4(baseColor.rgb / MAX_COLOR_RANGE, baseColor.a);

}
