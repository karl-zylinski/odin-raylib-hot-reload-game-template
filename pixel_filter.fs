// This is a bilinear-based AA for pixelart that reduces pixel shimmering for scaled and translated pixelart.
// In order to use it:
// - Load this shader as a fragment shader: pixel_filter_shader = rl.LoadShader(nil, "pixel_filter.fs")
// - Use rl.BeginShaderMode(pixel_filter_shader) to enable it at start of your program's drawing code. End the drawing code with gl.EndShaderMode()
// - Set all textures to bilinear filtering (including fonts)
// - Set rl.BeginBlendMode(.ALPHA_PREMULTIPLY) around all your drawing code
// - Premultiply alpha in all textures. If your pixelart only uses full or zero transparency then you don't need to do this
// - Premultiply alpha in any fonts.
//
// You can use the included load_premultiplied_alpha_ttf_from_memory in raylib_helpers.odin to load a font with premultiplied alpha
// and bilinear filtering enabled. Feed it the font bytes (i.e. load the font bytes with os.read_entire_file("some_font.ttf"))
// 
// Read more here: https://gist.github.com/d7samurai/9f17966ba6130a75d1bfb0f1894ed377

// The shader code is by Ben Golus

#version 330

in vec2 fragTexCoord;
in vec4 fragColor;
uniform sampler2D texture0;
out vec4 finalColor;

vec2 uv_aa_smoothstep(vec2 uv, vec2 res, float width) {
    vec2 pixels = uv * res;
    
    vec2 pixels_floor = floor(pixels + 0.5);
    vec2 pixels_fract = fract(pixels + 0.5);
    vec2 pixels_aa = fwidth(pixels) * width * 0.5;
    pixels_fract = smoothstep( vec2(0.5) - pixels_aa, vec2(0.5) + pixels_aa, pixels_fract );
    
    return (pixels_floor + pixels_fract - 0.5) / res;
}

void main()
{
    finalColor = fragColor * texture(texture0, uv_aa_smoothstep(fragTexCoord, ivec2(textureSize(texture0, 0)), 1.5));
}