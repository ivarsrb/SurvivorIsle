//
//  Shader.fsh
//  Island survival
//
//  Created by Ivars Rusbergs on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#define NUM_TEXTURES 2

precision lowp float;

//varyings
varying lowp vec4 v_color;
varying vec2 v_texCoord;

//uniforms
uniform sampler2D s_texture[NUM_TEXTURES];

uniform vec4 comm_color;

void main()
{
    vec4 texel0 = texture2D(s_texture[0], v_texCoord);
    vec4 texel1 = texture2D(s_texture[1], v_texCoord);
    gl_FragColor = v_color * comm_color * mix(texel1,texel0, v_color.a);
}