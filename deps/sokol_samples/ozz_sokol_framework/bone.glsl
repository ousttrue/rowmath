@vs vs
uniform vs_params {
  mat4 joint;
  mat4 u_mvp;
};

in vec3 a_position;
in vec3 a_normal;
in vec4 a_color;
out vec3 v_world_normal;
out vec4 v_vertex_color;

mat4 GetWorldMatrix() {
  // Rebuilds bone properties.
  // Bone length is set to zero to disable leaf rendering.
  float is_bone = joint[3].w;
  vec3 bone_dir = vec3(joint[0].w, joint[1].w, joint[2].w) * is_bone;
  float bone_len = length(bone_dir);

  // Setup rendering world matrix.
  float dot1 = dot(joint[2].xyz, bone_dir);
  float dot2 = dot(joint[0].xyz, bone_dir);
  vec3 binormal = abs(dot1) < abs(dot2) ? joint[2].xyz : joint[0].xyz;

  mat4 world_matrix;
  world_matrix[0] = vec4(bone_dir, 0.);
  world_matrix[1] = vec4(bone_len * normalize(cross(binormal, bone_dir)), 0.);
  world_matrix[2] =
      vec4(bone_len * normalize(cross(bone_dir, world_matrix[1].xyz)), 0.);
  world_matrix[3] = vec4(joint[3].xyz, 1.);
  return world_matrix;
}

void main() {
  mat4 world_matrix = GetWorldMatrix();
  vec4 vertex = vec4(a_position.xyz, 1.);
  gl_Position = u_mvp * world_matrix * vertex;
  mat3 cross_matrix = mat3(cross(world_matrix[1].xyz, world_matrix[2].xyz),
                           cross(world_matrix[2].xyz, world_matrix[0].xyz),
                           cross(world_matrix[0].xyz, world_matrix[1].xyz));
  float invdet = 1.0 / dot(cross_matrix[2], world_matrix[2].xyz);
  mat3 normal_matrix = cross_matrix * invdet;
  v_world_normal = normal_matrix * a_normal;
  v_vertex_color = a_color;
}
@end

@fs fs 
in vec3 v_world_normal;
in vec4 v_vertex_color;
out vec4 o_color;

vec4 GetAmbient(vec3 _world_normal) {
  vec3 normal = normalize(_world_normal);
  vec3 alpha = (normal + 1.) * .5;
  vec2 bt = mix(vec2(.3, .7), vec2(.4, .8), alpha.xz);
  vec3 ambient = mix(vec3(bt.x, .3, bt.x), vec3(bt.y, .8, bt.y), alpha.y);
  return vec4(ambient, 1.);
}

void main() {
  vec4 ambient = GetAmbient(v_world_normal);
  o_color = ambient * v_vertex_color;
}
@end

@program bone vs fs
