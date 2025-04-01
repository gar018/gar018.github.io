@group(0) @binding(0) var inTexture: texture_2d<f32>;
@group(0) @binding(1) var outTexture: texture_storage_2d<rgba8unorm, write>;

@compute
@workgroup_size(8, 8)
fn computeMain(@builtin(global_invocation_id) global_id: vec3u) {
  let uv = vec2i(global_id.xy);
  let color = textureLoad(inTexture, uv, 0);
  // Apply 8 bits quantization
  let avg = (0.299 * color.r + 0.587 * color.g + 0.114 * color.b);
  let out = vec4f(avg, avg, avg, color.a);
  textureStore(outTexture, uv, out);
}