//
//  Shader.vsh
//  Island survival
//
//  Created by Ivars Rusbergs on 12/22/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//
// Mix texture color depending on alpha

//attributes
attribute vec4 position;
attribute vec4 color;
attribute vec2 texCoord;

//uniforms
uniform mat4 modelViewProjectionMatrix;

//varyings
varying lowp vec4 v_color;
varying vec2 v_texCoord;

void main()
{
	gl_Position = modelViewProjectionMatrix * position;
    v_color = color;
	v_texCoord = texCoord;
}