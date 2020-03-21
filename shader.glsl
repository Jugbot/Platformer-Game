

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    // The order of operations matters when doing matrix multiplication.
    // return vertex_position;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
vec4 effect( vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords ) {
  // texture_coords is garbage data
  vec4 texturecolor = Texel(tex, texture_coords);
  // return texturecolor * color;
  vec4 origin = TransformProjectionMatrix * vec4(0.0f, 0.0f, 0.0f, 1.0f);
  return vec4(mod(origin.x/screen_coords.x, 30.f)/30.f, mod(origin.y, 30.f)/30.f, 0.0f, 1.0f);
}
#endif