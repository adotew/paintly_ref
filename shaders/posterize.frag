#include <flutter/runtime_effect.glsl>

uniform float uLevels;
uniform float uWidth;
uniform float uHeight;
uniform sampler2D uTexture;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / vec2(uWidth, uHeight);
  vec4 color = texture(uTexture, uv);
  if (uLevels < 1.0) {
    fragColor = color;
    return;
  }

  float levels = uLevels;
  color.r = floor(color.r * levels) / (levels - 1.0);
  color.g = floor(color.g * levels) / (levels - 1.0);
  color.b = floor(color.b * levels) / (levels - 1.0);
  fragColor = color;
}
