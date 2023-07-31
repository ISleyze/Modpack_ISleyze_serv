#version 120

#define WINDY_TERRAIN
  #define WIND_SPEED 1.0 // [0.1 0.2 0.4 0.6 0.8 1.0 1.2 1.4 1.6]
//#define AUTO_BUMP
//#define POM

varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 tangent;
varying vec4 normal;
varying vec3 binormal;
varying vec4 viewVector;
varying vec4 worldposition;

varying vec4 color;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform vec3 cameraPosition;

attribute vec4 at_tangent;
attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;

#if defined POM || defined AUTO_BUMP
  varying vec4 vtexcoordam;
  varying vec4 vtexcoord;
#endif

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
  	strength *= lmcoord.t;
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

  texcoord        = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;

  color           = gl_Color;

  lmcoord.x       = (gl_TextureMatrix[1] * gl_MultiTexCoord1).x;
  lmcoord.y       = smoothstep(0.03, 1.0, (gl_TextureMatrix[1] * gl_MultiTexCoord1).y);
  normal          = vec4(normalize(gl_NormalMatrix * gl_Normal), 0.02);
  tangent			    = normalize(gl_NormalMatrix * at_tangent.xyz );
  binormal		    = normalize(gl_NormalMatrix * -cross(gl_Normal, at_tangent.xyz));

  #if defined POM || defined AUTO_BUMP

    vec2 midcoord 				= (gl_TextureMatrix[0] *  mc_midTexCoord).st;
    vec2 texcoordminusmid	= texcoord - midcoord;

    vtexcoordam.pq  = abs(texcoordminusmid) * 2;
    vtexcoordam.st  = min(texcoord, midcoord - texcoordminusmid);
    vtexcoord.xy   	= sign(texcoordminusmid) * 0.5 + 0.5;

  #endif

  viewVector = gl_ModelViewMatrix * gl_Vertex;

	vec4 position = gbufferModelViewInverse * viewVector;

  worldposition = position + vec4(cameraPosition.xyz, 0.0);

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

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

  if (mc_Entity.x == 10006.0 ||	// Saplings
			mc_Entity.x == 10018.0 ||	// Oak leaves
			mc_Entity.x == 10030.0 ||	// Cobweb
			mc_Entity.x == 10031.0 ||	// Grass
			mc_Entity.x == 10037.0 ||	// Yellow flower
			mc_Entity.x == 10038.0 ||	// Red flower and others
			mc_Entity.x == 10059.0 ||	// Wheat Crops
			mc_Entity.x == 10083.0 ||	// Sugar Canes
			mc_Entity.x == 10106.0 ||	// Vines
			mc_Entity.x == 10141.0 ||	// Carrots
			mc_Entity.x == 10142.0 ||	// Potatoes
			mc_Entity.x == 10161.0 ||	// Acacia leaves
			mc_Entity.x == 10175.0 || // Lower grass
      mc_Entity.x == 10176.0 || // Upper grass
			mc_Entity.x == 10207.0 // Beetroot
			) normal.a = 0.2;

  if (mc_Entity.x == 10089.0 ||	// Glowstone
			mc_Entity.x == 10050.0 ||	// Torch
			mc_Entity.x == 10051.0 ||	// Fire
			mc_Entity.x == 10091.0 ||	// Jack o'Lantern
			mc_Entity.x == 10124.0 ||	// Redstone Lamp
			mc_Entity.x == 10138.0 ||	// Beacon
			mc_Entity.x == 10169.0 ||	// Sea Latern
			mc_Entity.x == 10010.0 ||	// Lava
			mc_Entity.x == 10198.0 // End rod
			) {
        normal.a = 0.3;
        lmcoord.y = 1.0;
      }

}
