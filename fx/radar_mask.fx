//
// radar_mask.fx
//

texture uCustomRadarTexturePart;

float uScreenHeight = 0;
float uScreenWidth = 0;

//Set these parameters with lua.
float uUVRotation = 0;
float2 uUVPosition = float2(0.0,0.0);

#include "mta-helper.fx"

// Returns 1 if point is inside ellipse, 0 otherwise.
float InsideEllipse(float center_x, float center_y, float el_width, float el_height, float x, float y){
    return floor((pow((x - center_x),2) / pow(el_width,2)) + (pow((y - center_y),2) / pow(el_height,2)));
}

float2 rotate(float2 pos, float rotation){
	float c = cos(rotation);
	float s = sin(rotation);
	float2x2 m = float2x2(c,-s,s,c);
	return mul(m,pos);
}

float2 scale(float2 pos, float scale){
	float2x2 m = float2x2(scale,0,0,scale);
	return mul(m,pos);
}

//---------------------------------------------------------------------
// Sampler for the main texture
//---------------------------------------------------------------------
sampler Sampler0 = sampler_state
{
    Texture = (gTexture0);
	MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp; //Clamp so no tiling.
    AddressV = Clamp;
};

//---------------------------------------------------------------------
// Sampler for mask texture
//---------------------------------------------------------------------
sampler Sampler1 = sampler_state
{
    Texture = (uCustomRadarTexturePart);
	MinFilter = Linear;
    MagFilter = Linear;
    AddressU = Clamp;
    AddressV = Clamp;
};


//---------------------------------------------------------------------
//-- Structure of data sent to the vertex shader
//---------------------------------------------------------------------
struct VSInput
{
  float3 Position : POSITION0;
  float3 Normal : NORMAL0;
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
};

//---------------------------------------------------------------------
//-- Structure of data sent to the pixel shader ( from the vertex shader )
//---------------------------------------------------------------------
struct PSInput
{
  float4 Diffuse : COLOR0;
  float2 TexCoord : TEXCOORD0;
  float4 Position : POSITION1;
  float4 kaas : SV_POSITION;
};


PSInput VertexShaderFunction(VSInput VS)
{
    PSInput PS = (PSInput)0;
	
    PS.Position = MTACalcScreenPosition(VS.Position);

    PS.Diffuse = VS.Diffuse;
	
    return PS;
}

float4 PixelShaderFunction(PSInput PS) : COLOR0
{
	float2 ScreenPosition = PS.kaas.xy; //These coordinates are in range 0 to screen size.
	//Check if we are in the mask area.
    float inEllipse = InsideEllipse(0.5,0.5,0.89,0.89, PS.TexCoord.x - 0.5, PS.TexCoord.y - 0.5);
	
	//Normalize based on screen size.
    //ScreenPosition.x /= uScreenWidth;
    //ScreenPosition.y /= uScreenHeight;
	
	//ScreenPosition.x = MTAUnlerp(0.056, 0.216,ScreenPosition.x);
	//ScreenPosition.y = MTAUnlerp(0.679, 0.929,ScreenPosition.y);
	
	//Size of radar is 0.25 * uScreenHeight
	//if(ScreenPosition.x > (uScreenWidth * 0.056)){ //Top left corner or radar
	//if(ScreenPosition.y > (uScreenHeight * 0.679)){
	
	//Apply transforms.
	float2 centerOffRadarOnScreen = float2((0.056 + 0.075) * uScreenWidth, (0.679 + 0.075) * uScreenWidth);
	float2 offsetCenterRadarToDrawPixel = float2(ScreenPosition.x - 0.056 * uScreenWidth,ScreenPosition.y - 0.679 * uScreenHeight);
	float2 rotatedPixelToDraw = rotate(offsetCenterRadarToDrawPixel, uUVRotation);
	rotatedPixelToDraw += float2(1536/2,1536/2);
	rotatedPixelToDraw.x = MTAUnlerp(0.0, 1536, rotatedPixelToDraw.x);
	rotatedPixelToDraw.y = MTAUnlerp(0.0, 1536, rotatedPixelToDraw.y);
	
	
	//ScreenPosition +=  //Pos on screen
	//ScreenPosition = rotate(ScreenPosition,uUVRotation);
	//ScreenPosition -= float2(1536/2,1536/2); //Rotate around center of big texture //uUVPosition; //Rotate around point
    
	//Sample default texture at normal texture coordinates.
    float4 finalColor = tex2D(Sampler0, PS.TexCoord);
	
	//Sample based on screen position.
    float4 maskColor = tex2D(Sampler1, rotatedPixelToDraw);
    return maskColor;
	//return finalColor * (inEllipse ? 1:0) + maskColor * (inEllipse ? 0:1);
}

technique tec0
{
    pass P1
    {
        //VertexShader = compile vs_3_0 VertexShaderFunction();
		PixelShader  = compile ps_3_0 PixelShaderFunction();
    }
}

// Fallback
technique fallback
{
    pass P0
    {
        // Just draw normally
    }
}

/*
PS_OUTPUT ps_main(in PS_INPUT In)
{
    PS_OUTPUT Out;
    
    
    //In.v_position.x /= 1920;
    //In.v_position.y /= 1280;
    //In.v_position = rotate(In.v_position,rot);
    //In.v_position += uUVPosition;
    float2 ScreenPosition = In.v_position;
    
    float2 centerOffRadarOnScreen = float2((0.056 + 0.075), (0.679 + 0.1));
    float inEllipse = InsideEllipse(centerOffRadarOnScreen.x,centerOffRadarOnScreen.y,0.15,0.20, In.v_texcoord.x, In.v_texcoord.y);
    
    float2 offsetCenterRadarToDrawPixel = float2(ScreenPosition.x - (0.056 + 0.075) * uScreenWidth,ScreenPosition.y - (0.679 + 0.1) * uScreenHeight);
    float2 rotatedPixelToDraw = rotate(offsetCenterRadarToDrawPixel, uUVRotation);
    //rotatedPixelToDraw += float2(1536/2,1536/2);
    rotatedPixelToDraw -= float2(uUVPosition.x * 1536,uUVPosition.y * 1536);
    rotatedPixelToDraw.x = MTAUnlerp(0.0, 1536, rotatedPixelToDraw.x);
    rotatedPixelToDraw.y = MTAUnlerp(0.0, 1536, rotatedPixelToDraw.y);
    
    float4 finalColor = tex2D(texture0, In.v_texcoord);
    float4 maskColor = tex2D(texture1, rotatedPixelToDraw);
    
    Out.color = finalColor * (inEllipse ? 1:0) + maskColor * (inEllipse ? 0:1);
    return Out;
}
*/


