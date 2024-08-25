//------------------------------------------------------------------------------
//  shaders for instancing-sapp sample
//------------------------------------------------------------------------------
// @ctype mat4 hmm_mat4

@vs vs
uniform vs_params {
    // mat4 mvp;
    mat4 VP;
};

// in vec3 pos;
// in vec4 color0;
// in vec3 inst_pos;
in vec4 vPosFace;
in vec4 vUvBarycentric;
in vec4 iRow0;
in vec4 iRow1;
in vec4 iRow2;
in vec4 iRow3;
in vec4 iPositive_xyz_flag;
in vec4 iNegative_xyz_flag;

// out vec4 color;
out vec4 oUvBarycentric;
flat out uvec3 o_Palette_Flag_Flag;

mat4 transform(vec4 r0, vec4 r1, vec4 r2, vec4 r3)
{
  return mat4(
    r0.x, r0.y, r0.z, r0.w,
    r1.x, r1.y, r1.z, r1.w,
    r2.x, r2.y, r2.z, r2.w,
    r3.x, r3.y, r3.z, r3.w
  );
}

void main()
{
    gl_Position = VP * transform(iRow0, iRow1, iRow2, iRow3) * vec4(vPosFace.xyz, 1);
    oUvBarycentric = vUvBarycentric;
    if(vPosFace.w==0.0)
    {
      o_Palette_Flag_Flag = uvec3(iPositive_xyz_flag.x, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else if(vPosFace.w==1.0)
    {
      o_Palette_Flag_Flag = uvec3(iPositive_xyz_flag.y, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else if(vPosFace.w==2.0)
    {
      o_Palette_Flag_Flag = uvec3(iPositive_xyz_flag.z, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else if(vPosFace.w==3.0)
    {
      o_Palette_Flag_Flag = uvec3(iNegative_xyz_flag.x, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else if(vPosFace.w==4.0)
    {
      o_Palette_Flag_Flag = uvec3(iNegative_xyz_flag.y, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else if(vPosFace.w==5.0)
    {
      o_Palette_Flag_Flag = uvec3(iNegative_xyz_flag.z, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
    else{
      o_Palette_Flag_Flag = uvec3(0, 
        iPositive_xyz_flag.w,
        iNegative_xyz_flag.w);
    }
}
// void main() {
//     vec4 pos = vec4(pos + inst_pos, 1.0);
//     gl_Position = mvp * pos;
//     color = color0;
// }
@end

@fs fs
uniform fs_params {
  vec4 colors[32];
  vec4 textures[32];
};

// in vec4 color;
in vec4 oUvBarycentric;
flat in uvec3 o_Palette_Flag_Flag;
// out vec4 frag_color;
out vec4 FragColor;

// uniform sampler sampler0;
// uniform texture2D tex0;
// uniform sampler sampler1;
// uniform texture2D tex1;
// uniform sampler sampler2;
// uniform texture2D tex2;


// https://github.com/rreusser/glsl-solid-wireframe
float grid (vec2 vBC, float width) {
  vec3 bary = vec3(vBC.x, vBC.y, 1.0 - vBC.x - vBC.y);
  vec3 d = fwidth(bary);
  vec3 a3 = smoothstep(d * (width - 0.5), d * (width + 0.5), bary);
  return min(a3.x, a3.y);
}

void main()
{
    vec4 border = vec4(vec3(grid(oUvBarycentric.zw, 1.0)), 1);
    uint index = o_Palette_Flag_Flag.x;
    vec4 color = colors[index];
    vec4 texel = vec4(1, 1, 1, 1);
    // if(textures[index].x==0.0)
    // {
    //   texel = texture(sampler2D(tex0, sampler0), oUvBarycentric.xy);
    // }
    // else if(textures[index].x==1.0)
    // {
    //   texel = texture(sampler2D(tex1, sampler1), oUvBarycentric.xy);
    // }
    // else if(textures[index].x==2.0)
    // {
    //   texel = texture(sampler2D(tex2, sampler2), oUvBarycentric.xy);
    // }
    // else{
    //   texel = vec4(1, 1, 1, 1);
    // }
    FragColor = texel * color * border;
}
// void main() {
//     frag_color = color;
// }
@end

@program instancing vs fs
