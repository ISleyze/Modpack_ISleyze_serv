vec3 underwaterFog(vec3 fragpos, vec3 color, vec3 waterColor, vec3 lavaColor) {

  if (isEyeInWater == 1) {
    return mix(color, waterColor, 1.0 - exp(-pow(length(fragpos) * 0.03, 1.0)));
  } else if (isEyeInWater == 2) {
    return mix(color, lavaColor, 1.0 - exp(-pow(length(fragpos), 1.0)));
  } else {
    return color;
  }

}
