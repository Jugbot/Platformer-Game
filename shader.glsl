uniform vec2 origin;
uniform vec2 meter;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // The order of operations matters when doing matrix multiplication.
    // return vertex_position;
    return vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect( vec4 color, Image tex, vec2 __texture_coords, vec2 screen_coords ) {
  // texture_coords is garbage data
  vec2 scale = meter - origin;
  vec2 texture_coords = (screen_coords - origin)/scale;//vec2(mod(screen_coords.x-origin.x, scale.x)/scale.x, mod(screen_coords.y-origin.y, scale.y)/scale.y;
  vec4 texturecolor = Texel(tex, texture_coords);
  // return texturecolor * color;
  // vec4 origin = TransformProjectionMatrix * vec4(0.0f, 0.0f, 0.0f, 1.0f);
  return color * texturecolor;
}
#endif