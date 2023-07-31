#version 120

varying vec4 color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;

void main() {

  color = gl_Color;

  vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

  gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
