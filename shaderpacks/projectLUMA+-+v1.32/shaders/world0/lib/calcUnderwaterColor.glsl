vec3 calcUnderwaterColor(vec3 color, vec3 waterColor, float depth) {

  vec3 underwaterColor = color * mix(vec3(1.0), mix(waterColor, vec3(0.0, 1.0, 1.0), pow(max(depth, 0.0), 1.5)), 1.2 - pow(depth, 2.0));
  underwaterColor = mix(underwaterColor, waterColor * 0.08, 1.0 - depth);

  return underwaterColor;

}
