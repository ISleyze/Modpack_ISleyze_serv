#version 120

varying vec2 texcoord;

uniform sampler2D colortex4;
uniform sampler2D depthtex1;
uniform float aspectRatio;


const bool colortex4MipmapEnabled = true;

vec3 bloomPass() {

	vec3 bloomSample = vec3(0.0);

	vec2 offsets[4] = vec2[4](vec2(1.0, 0.0), vec2(0.0, 1.0), vec2(-1.0, 0.0), vec2(0.0, -1.0));
	vec2 aspectcorrect = vec2(1.0, aspectRatio);

	float radius = 1.0;
	vec2 angle = vec2(0.0, radius);

	for (int i = 0; i < 4; i++) {
		bloomSample += texture2DLod(colortex4, texcoord * 2.0 + offsets[i] * aspectcorrect * 0.01, 5.0).rgb;
	}

	bloomSample *= 0.25;

	if (texcoord.x > 0.5 && texcoord.y > 0.5) {
		bloomSample = texture2DLod(colortex4, texcoord * 2.0 - vec2(1.0, 1.0), 2.0).rgb;
	}

	return bloomSample;

}


void main() {

/* DRAWBUFFERS:0 */

	gl_FragData[0] = vec4(bloomPass(), 0.0);


}
