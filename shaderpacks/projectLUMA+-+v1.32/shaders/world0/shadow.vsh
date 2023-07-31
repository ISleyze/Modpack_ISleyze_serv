#version 120

#define SHADOW_MAP_BIAS 0.8

#define WINDY_TERRAIN
  #define WIND_SPEED 1.0 // [0.1 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6]



varying vec2 texcoord;

uniform vec3 cameraPosition;

uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;

attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;

#ifdef WINDY_TERRAIN

  uniform float frameTimeCounter;
  uniform float rainStrength;

  vec3 calcMove(vec3 pos, float mcID, bool isWeldedToGround, float strength, float posRes) {

  	float speed = 3.0 * WIND_SPEED;

  	bool onGround = gl_MultiTexCoord0.t < mc_midTexCoord.t;

  	float movementX = sin(frameTimeCounter * speed + pos.z * posRes + cameraPosition.z * posRes);
  	float movementY = sin(frameTimeCounter * speed + pos.z * posRes + cameraPosition.z * posRes);
  	float movementZ = sin(frameTimeCounter * speed + pos.x * posRes + cameraPosition.x * posRes);

  	float random = max(sin(frameTimeCounter * 0.2) * cos(frameTimeCounter * 0.3), 0.0);

    float windfallX = (1.0 + sin(frameTimeCounter * speed * 2.0 + pos.z * posRes + cameraPosition.z * posRes)) * 5.0 * random;
    float windfallZ = sin(frameTimeCounter * speed * 2.0 + pos.x * posRes + cameraPosition.x * posRes) * 2.0 * random;

  	// Movement is based on the sky lightmap.
  	//strength *= lmcoord.t;
  	strength += strength * rainStrength;

    if (isWeldedToGround) {

  		if (mc_Entity.x == mcID && onGround) {

  			pos.x += (movementZ + windfallZ) * strength;
        pos.y += movementY * strength;
  			pos.z += movementX * strength;

  		}

  	} else {

  		if (mc_Entity.x == mcID) {

  			pos.x += (movementZ + windfallZ) * strength;
        pos.y += movementY * strength;
  			pos.z += movementX * strength;

  		}

  	}

  	return pos;

}

#endif

void main() {

  texcoord = gl_MultiTexCoord0.st;

  vec4 position = ftransform();
       position = shadowProjectionInverse * position;
       position = shadowModelViewInverse * position;

  #ifdef WINDY_TERRAIN

     position.xyz = calcMove(position.xyz, 10006.0, true, 0.01, 5.0);		// Saplings
     position.xyz = calcMove(position.xyz, 10018.0, false, 0.005, 10.0);		// Oak leaves
     position.xyz = calcMove(position.xyz, 10031.0, true, 0.05, 5.0);		// Grass
     position.xyz = calcMove(position.xyz, 10037.0, true, 0.01, 5.0);		// Yellow flower
     position.xyz = calcMove(position.xyz, 10038.0, true, 0.01, 5.0);		// Red flower and others
     position.xyz = calcMove(position.xyz, 10059.0, true, 0.02, 5.0);		// Wheat Crops
     position.xyz = calcMove(position.xyz, 10141.0, true, 0.01, 5.0);		// Carrots
     position.xyz = calcMove(position.xyz, 10142.0, true, 0.01, 5.0);		// Potatoes
     position.xyz = calcMove(position.xyz, 10161.0, false, 0.005, 10.0);	// Acacia leaves
     position.xyz = calcMove(position.xyz, 10175.0, true, 0.01, 5.0);		// Tall grass lower
     position.xyz = calcMove(position.xyz, 10176.0, false, 0.01, 5.0);		// Tall grass upper
     position.xyz = calcMove(position.xyz, 10207.0, true, 0.01, 5.0);		// Beetroot

  #endif


  position = shadowProjection * shadowModelView * position;

	float distortion = ((1.0 - SHADOW_MAP_BIAS) + length(position.xy * 1.165) * SHADOW_MAP_BIAS) * 0.97;

	position.xy /= distortion;
	position.z /= 2.5;

  gl_Position = position;

  gl_FrontColor = gl_Color;

}
