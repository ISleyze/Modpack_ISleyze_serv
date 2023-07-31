#version 120

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
