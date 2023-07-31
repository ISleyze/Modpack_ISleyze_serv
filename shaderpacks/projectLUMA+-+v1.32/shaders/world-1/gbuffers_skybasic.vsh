#version 120

varying vec2 texcoord;
varying vec4 color;
varying vec4 position;
varying float stars;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

void main() {

  texcoord = gl_MultiTexCoord0.st;

  stars = float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0);

  position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
