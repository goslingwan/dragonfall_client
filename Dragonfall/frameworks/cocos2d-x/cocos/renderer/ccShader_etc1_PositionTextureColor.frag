// CC_Texture1是etc的alpha数据也可以用ETC1压缩 by dannyhe
const char* ccShader_etc1_PositionTextureColor_frag = STRINGIFY(
\n
varying vec4 v_fragmentColor;
varying vec2 v_texCoord;

void main()
{
    vec4 color = texture2D(CC_Texture0, v_texCoord);
    color.a = texture2D(CC_Texture1, v_texCoord).r;
    gl_FragColor = color * v_fragmentColor; //支持Cocos opacity
}
);