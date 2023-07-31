vec3 emissiveLight(vec3 clr, vec3 originalClr, bool emissive) {

	const float cover		= 0.3;

	//if (forHand) emissive = emissiveHandlight;
	if (emissive) clr *= 1.0 + MAX_COLOR_RANGE * 2.5 * max(luma(originalClr.rgb) - cover, 0.0) * 0.5;

	return clr;

}
