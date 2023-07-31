#version 120

#include "lib/HDR.glsl"

#define TEMPERATURE 1.0 // [0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

varying vec4 position;
varying float stars;

uniform sampler2D gaux4;

uniform int worldTime;

uniform float rainStrength;
uniform float screenBrightness;
uniform float nightVision;

#include "lib/timeArray.glsl"

mat2 rotate2d(float angle) {
  return mat2(cos(angle), -sin(angle), sin(angle), cos(angle));
}

vec2 projectSky(vec3 dir, float rotation) {

  const ivec2 resolution     = ivec2(8192, 3072);
  const vec2  tileSize       = resolution / vec2(4, 3);
  const vec2  tileSizeDivide = (0.5 * tileSize) - 1.5;

  dir.xz *= rotate2d(-rotation);
  dir.xyz = vec3(dir.z, -dir.y, -dir.x);

  vec2 coord = vec2(0.0);
  if (abs(dir.y) > abs(dir.x) && abs(dir.y) > abs(dir.z)) {
    dir /= abs(dir.y);
    coord.x = dir.x * tileSizeDivide.x + tileSize.x * 1.5;
    coord.y = -(dir.y < 0.0 ? 1 : -1) * dir.z * tileSizeDivide.y + tileSize.y * (dir.y < 0.0 ? 0.5 : 2.5);
  } else if (abs(dir.x) > abs(dir.y) && abs(dir.x) > abs(dir.z)) {
    dir /= abs(dir.x);
    coord.x = (dir.x < 0.0 ? -1 : 1) * dir.z * tileSizeDivide.x + tileSize.x * (dir.x < 0.0 ? 0.5 : 2.5);
    coord.y = dir.y * tileSizeDivide.y + tileSize.y * 1.5;
  } else {
    dir /= abs(dir.z);
    coord.x = (dir.z < 0.0 ? 1 : -1) * dir.x * tileSizeDivide.x + tileSize.x * (dir.z < 0.0 ? 1.5 : 3.5);
    coord.y = dir.y * tileSizeDivide.y + tileSize.y * 1.5;
  }

  return coord / resolution;

}

vec3 getSkyTextureFromSequence(vec3 pos) {

  float rotation = (clamp(worldTime > 21000.0? 0.0 : worldTime, 0.0, 12000.0) / 24000.0) * 5.0;

	// config = vec4(x offset, y offset, time, rotation offset)
  vec4 config[2] = vec4[2](vec4(0.0), vec4(0.0));

  vec3 first = vec3(0.0);
  vec3 second = vec3(0.0);
  vec3 rain = vec3(0.0);
  vec3 stars = vec3(0.0);

  if (time[0] > 0.01) {
    config[0] = vec4(0.0, 0.0, time[0], 0.0);
  } else if (time[2] > 0.01) {
    config[0] = vec4(0.5, 0.0, time[2], 0.0);
  } else if (time[4] > 0.01) {
    config[0] = vec4(0.75, 0.0, time[4], 0.55);
  }

  if (time[1] > 0.01) {
    config[1] = vec4(0.25, 0.0, time[1], 0.0);
  } else if (time[3] > 0.01) {
    config[1] = vec4(0.25, 0.0, time[3], 0.0);
  } else if (time[5] > 0.01) {
    config[1] = vec4(0.0, 0.5, time[5] * mix(0.2 * (1.0 + screenBrightness), 1.0, nightVision), 0.0);
  }

  if (rainStrength < 1.0) {
    first = texture2D(gaux4, projectSky(pos.xyz, rotation + config[0].w) * vec2(0.25, 0.5) + config[0].xy).rgb * config[0].z * (1.0 - rainStrength);
    second = texture2D(gaux4, projectSky(pos.xyz, rotation + config[1].w) * vec2(0.25, 0.5) + config[1].xy).rgb * config[1].z * (1.0 - rainStrength);
    if (time[5] > 0.0) stars = texture2D(gaux4, projectSky(pos.xyz, worldTime / 12000.0) * vec2(0.25, 0.5) + vec2(0.25, 0.5)).rgb * time[5] * (1.0 - rainStrength);
  }

  if (rainStrength > 0.0) {
    if (time[5] > 0.0) rain = texture2D(gaux4, projectSky(pos.xyz, worldTime / 12000.0) * vec2(0.25, 0.5) + vec2(0.0, 0.5)).rgb * time[5] * mix(0.1 * (1.0 + screenBrightness), 1.0, nightVision) * rainStrength;
    rain += texture2D(gaux4, projectSky(pos.xyz, worldTime / 3000.0) * vec2(0.25, 0.5) + vec2(0.5, 0.5)).rgb * rainStrength * mix(1.0, 0.04 + screenBrightness * 0.04, time[5] * (1.0 - nightVision));
  }

	return first + second + rain + (stars * 0.3 + max(stars - 0.1, 0.0));

}

void main() {

  vec3 skybox = getSkyTextureFromSequence(position.xyz);
       skybox = mix(skybox, skybox * vec3(0.0, 0.5, 1.0), (1.0 - TEMPERATURE) * 0.25);
       skybox = pow(skybox, vec3(1.3)) / MAX_COLOR_RANGE;

/* DRAWBUFFERS:061 */

  gl_FragData[0] = vec4(skybox, 1.0 - stars);
  gl_FragData[1] = vec4(skybox, 1.0 - stars);
  gl_FragData[2] = vec4(0.0, 0.0, 0.0, 1.0);

}
