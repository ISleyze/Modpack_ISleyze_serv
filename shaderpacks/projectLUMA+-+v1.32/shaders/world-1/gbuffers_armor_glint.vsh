#version 120

varying vec2 texcoord;
varying vec4 color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

void main() {

  texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;

  color = gl_Color;

  vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

  gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
