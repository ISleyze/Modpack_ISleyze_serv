#version 120

varying vec2 texcoord;
varying vec3 normal;
varying vec4 color;
varying vec2 lmcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

void main() {

  color = gl_Color;
  texcoord = gl_MultiTexCoord0.st;
  normal = normalize(gl_NormalMatrix * gl_Normal);
  lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
