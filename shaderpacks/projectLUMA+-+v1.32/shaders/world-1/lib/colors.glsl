#define TEMPERATURE 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define TORCHLIGHT_TEMPERATURE 1.0 // [0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

float sunFactor = 0.0;

vec3 ambientColor = vec3(1.0, 0.4, 0.1) * 0.5;
     ambientColor = mix(ambientColor, vec3(0.0, 0.5, 1.0), (1.0 - TEMPERATURE) * 0.25);

vec3 torchColor = pow(vec3(1.0, 0.6, 0.4), vec3(TORCHLIGHT_TEMPERATURE));

vec3 waterColor = vec3(0.0, 0.7, 1.0);

vec3 lavaColor = vec3(1.0, 0.4, 0.0);
