#version 120

varying vec2 texcoord;

uniform sampler2D texture;

uniform int blockEntityId;

void main() {

  if (blockEntityId == 10138) discard;

  gl_FragData[0] = texture2D(texture, texcoord);

}
