/* ===================================================================================
Copyright © Violet Cleathero - 2024

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE,ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
=================================================================================== */

#include "ReShade.fxh"

//============================================================================================
// UI
//============================================================================================

// Blur Parameters ====================

uniform float2 UI_BlurCenter <
    ui_type = "slider";
    ui_label = "Center of Image";
    ui_category = "Blur Adjustments";
    ui_min = 0.0;
    ui_max = 1.0;
    > = float2(0.5, 0.5);

uniform float UI_BlurStrength <
    ui_type = "slider";
    ui_label = "Intensity";
    ui_category = "Blur Adjustments";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.75;

uniform float UI_Falloff <
    ui_type = "slider";
    ui_label = "Falloff Distance";
    ui_category = "Blur Adjustments";
    ui_min = 0.0;
    ui_max = 1.0;
    > = 0.6;

// Testing Parameters ====================

uniform int UI_ColourSpace <
	ui_type = "combo";
    ui_label = "Input Colour Space";
    ui_items = "sRGB / Gamma 2.2\0scRGB HDR / Linear\0HDR10 PQ\0";
    ui_tooltip = "Select the colour space being used for input (In most cases this will be sRGB).";
    ui_category = "Experimental";
> = 0;
    
//============================================================================================
// Textures / Samplers / Defines
//============================================================================================
    
sampler BackBuffer { Texture = ReShade::BackBufferTex; MagFilter = POINT; MinFilter = POINT; MipFilter = POINT; AddressU = CLAMP; AddressV = CLAMP; AddressW = CLAMP; };

#define RES float2(BUFFER_WIDTH, BUFFER_HEIGHT)

// HDR10 PQ constants
#define PQ_m1 0.1593017578125
#define PQ_m2 78.84375
#define PQ_c1 0.8359375
#define PQ_c2 18.8515625
#define PQ_c3 18.6875

//============================================================================================
// Functions
//============================================================================================

// thanks to TreyM for posting this in the ReShade Discord's code chat :3
float3 sRGBToLinear(float3 x)
{
    return x < 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4); 
}

// thanks to TreyM for posting this in the ReShade Discord's code chat :3
float3 LinearTosRGB(float3 x)
{
    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055; 
}

float3 HDR10ToLinear(float3 encodedHDR)
{
    float3 ePrimePower = pow(encodedHDR, 1.0 / PQ_m2);
    float3 numerator = max(ePrimePower - PQ_c1, 0.0);
    float3 denominator = PQ_c2 - PQ_c3 * ePrimePower;
    float3 linearHDR = pow(numerator / denominator, 1.0 / PQ_m1);

    return linearHDR * 600.0;
}

float3 LinearToHDR10(float3 linearHDR)
{
    float3 normalizedHDR = saturate(linearHDR / 600.0);

    float3 hdr10Color = pow(
        (PQ_c1 + PQ_c2 * pow(normalizedHDR, PQ_m1)) /
        (1.0 + PQ_c3 * pow(normalizedHDR, PQ_m1)),
        PQ_m2
    );

    return hdr10Color;
}

float2 Rotate(float2 uv, float2 pivot, float angle)
{
    float s = sin(angle);
    float c = cos(angle);

    uv -= pivot;
    float2 rotatedUV = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
    return rotatedUV + pivot;
}

//============================================================================================
// Main Function
//============================================================================================

float4 RadialBlur(float2 texCoords, float2 center, float strength, int quality, float falloff, float taperStrength)
{
	float4 Colour = float4(0.0, 0.0, 0.0, 1.0);

	// there was probably a better way to make it AR agnostic, but this does the trick mostly :)
    float aspectRatio = RES.x / RES.y;
	float2 adjustedCoords = float2(texCoords.x, texCoords.y / aspectRatio);
    float2 adjustedCenter = float2(center.x, center.y / aspectRatio);
	
    float distance = length(adjustedCoords - adjustedCenter);
    float falloffFactor = pow(distance, falloff);

    float taperBase = 1.0 - taperStrength;
    float taperCompensation = lerp(2.0, 1.0, taperStrength);

    for (int i = 0; i < quality; i++)
    {
        float angle = (0.1 + float(i) * 0.5) * strength * falloffFactor;
        float taperWeight = taperBase + taperStrength * (1.0 - abs(float(i) / quality));

        // positive rotation +
        float2 rotatedCoords = Rotate(adjustedCoords, adjustedCenter, angle);
        rotatedCoords.y *= aspectRatio;
        
        float3 sampleColor;
        
        if (UI_ColourSpace == 0)
        {
        	sampleColor = sRGBToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
        }
        else if (UI_ColourSpace == 1)
        {
        	sampleColor = tex2D(ReShade::BackBuffer, rotatedCoords).rgb;
        }
        else if (UI_ColourSpace == 2)
        {
        	sampleColor = HDR10ToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
        }
        
        Colour.rgb += sampleColor * taperWeight;

        // negative rotation -
        rotatedCoords = Rotate(adjustedCoords, adjustedCenter, -angle);
        rotatedCoords.y *= aspectRatio;
        
        if (UI_ColourSpace == 0)
        {
        	sampleColor = sRGBToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
        }
        else if (UI_ColourSpace == 1)
        {
        	sampleColor = tex2D(ReShade::BackBuffer, rotatedCoords).rgb;
        }
        else if (UI_ColourSpace == 2)
        {
        	sampleColor = HDR10ToLinear(tex2D(ReShade::BackBuffer, rotatedCoords).rgb);
        }
        
        Colour.rgb += sampleColor * taperWeight;
    }

    // normalise and convert back
    Colour.rgb /= (quality * taperCompensation);
    //Colour.rgb = LinearTosRGB(Colour.rgb);
    
    if (UI_ColourSpace == 0)
    {
    	Colour.rgb = LinearTosRGB(Colour.rgb);
    }
    else if (UI_ColourSpace == 1)
    {
    	Colour.rgb = Colour.rgb;
    }
    else if (UI_ColourSpace == 2)
    {
    	Colour.rgb = LinearToHDR10(Colour.rgb);
    }

    return Colour;
}

//============================================================================================
// Shader
//============================================================================================

float4 ApplyBlur(float4 pos : SV_Position, float2 texCoords : TexCoord) : SV_Target
{
	// this might waste a few 0.00001ms but it makes it neater for me :3
	// it was initially controllable but my god the blur looks horrendous without the taper
	float TaperStrength = 1.0;
	
	// adjusted controls (keeps all sliders 0-1 with adapted controls to ensure useable results :3)
	float adjustedBlurStrength = lerp(0.0, 0.02, UI_BlurStrength);
    float adjustedFalloff = lerp(1.0, 5.0, UI_Falloff);
    
    // i cant figure out how to separate quality from blur strength so this will do as a mediocre compromise
    // also has the benefit that the shader can be more performant with reasonable blurs i guess \o/
    float dynamicQuality = lerp(5, 100, UI_BlurStrength) * (1.0 / max(adjustedFalloff, 0.001));
    dynamicQuality = clamp(dynamicQuality, 5.0, 300);
    
    return RadialBlur(texCoords, UI_BlurCenter, adjustedBlurStrength, dynamicQuality, adjustedFalloff, TaperStrength);
}

//============================================================================================
// Technique / Passes
//============================================================================================

technique RadialBlur < ui_label = "Symmetrical Radial Blur"; ui_tooltip = "An unoptimised and lazily made radial blur shader that warps the edges of the frame in a radial pattern"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = ApplyBlur;
    }
}