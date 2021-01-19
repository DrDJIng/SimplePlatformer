extends Polygon2D

shader_type canvas_item;

void fragment()
{
	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, 1.0);
}
