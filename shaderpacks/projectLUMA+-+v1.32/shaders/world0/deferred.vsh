#version 120

varying vec2 texcoord;

attribute vec4 at_tangent;

void main() {

  texcoord = gl_MultiTexCoord0.st;
  gl_Position = ftransform();

}
