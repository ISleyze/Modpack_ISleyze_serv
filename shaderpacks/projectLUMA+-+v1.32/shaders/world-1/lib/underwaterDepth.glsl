float underwaterDepth(vec3 fragpos, vec3 uPos) {

  vec3 uVec = fragpos.xyz - uPos;
  float UNdotUP = abs(dot(normalize(uVec), normal.rgb));

  return 1.0 - clamp(length(uVec) * UNdotUP * 0.1, 0.0, 1.0);

}
