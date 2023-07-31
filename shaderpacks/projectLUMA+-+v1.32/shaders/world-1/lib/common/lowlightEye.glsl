vec3 lowlightEye(vec3 color, vec3 ambientLightmap) {

	return mix(color, vec3(luma(color)), pow(max(1.0 - luma(ambientLightmap), 0.0), 4.0));

}
