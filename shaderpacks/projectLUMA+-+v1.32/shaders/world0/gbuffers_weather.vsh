#version 120

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 normal;
varying vec4 color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

uniform float frameTimeCounter;

void main() {

  color = gl_Color;
  texcoord = gl_MultiTexCoord0.st;
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
  normal = normalize(gl_NormalMatrix * gl_Normal);

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

  vec3 worldpos = position.xyz + cameraPosition;
  bool istopv = worldpos.y > cameraPosition.y + 5.0;
  if (!istopv) position.xz += 1.0;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
