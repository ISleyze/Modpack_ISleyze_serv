float getTorchLightmap(vec3 normal, float lightmap, float skyLightmap, bool translucent) {

	float tRadius = 2.5;	// Higher means lower.
	float tBrightness = 0.09;

	float NdotL = translucent? 1.0 : clamp(dot(normal, normalize(gbufferModelView[1].xyz)), 0.0, 1.0) + clamp(dot(normal, normalize(-gbufferModelView[1].xyz)), 0.0, 1.0);

	float torchLightmap = max(exp(pow(lightmap + 0.5, tRadius)) - 1.3, 0.0) * tBrightness * (1.0 + NdotL * 0.5);
				torchLightmap *= mix(color.a, 1.0, torchLightmap);

	return torchLightmap;

}
