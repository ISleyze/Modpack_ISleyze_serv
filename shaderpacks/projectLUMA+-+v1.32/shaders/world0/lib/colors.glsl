#define TEMPERATURE 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define TORCHLIGHT_TEMPERATURE 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

float sunFactor = clamp(1.0 - pow(abs(-0.25 + sunAngle) * 4.0, 2.0 / (abs(-0.25 + sunAngle) * 4.0)), 0.0, 1.0);

vec3 ambientColor = mix(vec3(0.75, 0.84, 1.0) * 0.6, vec3(0.6, 0.75, 1.0), sunFactor) * (1.0 - time[5]);
     ambientColor += vec3(0.6, 0.73, 1.0) * 0.2 * time[5];
     ambientColor *= 1.0 - rainStrength;

     ambientColor += vec3(0.9, 0.95, 1.0) * 0.9 * rainStrength * (1.0 - time[5]);
     ambientColor += vec3(0.6, 0.73, 1.0) * 0.3 * rainStrength * time[5];
     ambientColor = mix(ambientColor, normalize(ambientColor), nightVision * time[5]);
     ambientColor = mix(ambientColor, vec3(0.0, 0.5, 1.0), (1.0 - TEMPERATURE) * 0.25);

vec3 sunColor = mix(vec3(1.0, 0.5, 0.3) * 0.6, vec3(1.0, 0.9, 0.8), sunFactor) * (1.0 - time[6]);
     sunColor += vec3(0.6, 0.6, 1.0) * 0.1 * time[5];
     sunColor *= 1.0 - rainStrength;

vec3 torchColor = pow(vec3(1.0, 0.6, 0.4), vec3(TORCHLIGHT_TEMPERATURE));

vec3 waterColor = vec3(0.0, 0.7, 1.0);

vec3 lavaColor = vec3(1.0, 0.4, 0.0);
