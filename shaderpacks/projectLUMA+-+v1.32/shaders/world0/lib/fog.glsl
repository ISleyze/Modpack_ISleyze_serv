vec3 renderFog(vec3 fragpos, vec3 color, vec3 ambientColor) {

  const bool colortex6MipmapEnabled = true;

  vec4 worldPos = gbufferModelViewInverse * vec4(fragpos, 1.0);

  float height = pow(max(1.0 - ((worldPos.y + cameraPosition.y) * 2.0 - 240), 0.0), 2.0) * 0.00004;

  float fogDensity = 0.002;
        fogDensity += fogDensity * rainStrength;
        fogDensity += height * fogDensity;

	float fogFactor = exp(-pow(length(fragpos.xyz) * fogDensity, 1.5) * 0.3);

	vec3 fogcolor = mix(ambientColor * (1.0 - rainStrength * time[5]), texture2D(colortex6, texcoord, 6.0).rgb * MAX_COLOR_RANGE, 1.0 - fogFactor * 0.5);

  color = pow(color, vec3(2.2));
  color = mix(color, pow(fogcolor, vec3(2.2)), 1.0 - fogFactor);
  color = pow(color, vec3(0.4545));

  return color;

}
