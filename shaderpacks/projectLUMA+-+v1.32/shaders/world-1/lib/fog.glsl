vec3 renderFog(vec3 fragpos, vec3 color, vec3 ambientColor) {

  float fogDensity = 0.002;
        fogDensity += fogDensity * rainStrength;

	float fogFactor = exp(-pow(length(fragpos.xyz) * fogDensity, 1.5) * 0.3);

  color = pow(color, vec3(2.2));
  color = mix(color, pow(ambientColor, vec3(2.2)), 1.0 - fogFactor);
  color = pow(color, vec3(0.4545));

  return color;

}
