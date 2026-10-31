#include <flutter/runtime_effect.glsl>

uniform vec2 u_size;
uniform vec2 u_lens_center;
uniform vec2 u_lens_half_size;
uniform float u_corner_radius;
uniform float u_refraction;
uniform sampler2D u_texture_input;

out vec4 frag_color;

void main() {
  vec2 uv = FlutterFragCoord().xy / u_size;
  vec2 localPosition = (uv - u_lens_center) * u_size;
  vec2 boxPosition = abs(localPosition) -
      (u_lens_half_size - vec2(u_corner_radius));
  float signedDistance = length(max(boxPosition, vec2(0.0))) +
      min(max(boxPosition.x, boxPosition.y), 0.0) - u_corner_radius;
  float rim = smoothstep(-7.0, -5.0, signedDistance) *
      (1.0 - smoothstep(-1.5, 0.0, signedDistance));
  vec2 outsidePosition = max(boxPosition, vec2(0.0));
  vec2 edgeNormal = sign(localPosition) * outsidePosition;
  if (dot(edgeNormal, edgeNormal) < 0.0001) {
    edgeNormal = boxPosition.x > boxPosition.y
        ? vec2(sign(localPosition.x), 0.0)
        : vec2(0.0, sign(localPosition.y));
  }
  vec2 edgeDirection = normalize(edgeNormal);
  vec2 uvOffset = edgeDirection * u_refraction * rim / u_size;
  vec4 originalColor = texture(u_texture_input, uv);
  vec2 refractedUv = clamp(
    uv + uvOffset,
    vec2(0.001),
    vec2(0.999)
  );
  vec4 refractedColor = texture(u_texture_input, refractedUv);
  frag_color = mix(refractedColor, originalColor, originalColor.a);
}
