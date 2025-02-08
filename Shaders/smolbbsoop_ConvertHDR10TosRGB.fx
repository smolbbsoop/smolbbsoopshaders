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

//============================================================================================
// Definitions
//============================================================================================

#define SOOP_SRGB 1
#define SOOP_SCRGB 2
#define SOOP_HDR10 3

#ifndef _SOOP_COLOUR_SPACE
    #if (BUFFER_COLOR_SPACE == 1)
        #define _SOOP_COLOUR_SPACE SOOP_SRGB
    #elif (BUFFER_COLOR_SPACE == 2)
        #define _SOOP_COLOUR_SPACE SOOP_SCRGB
    #elif (BUFFER_COLOR_SPACE == 3)
        #define _SOOP_COLOUR_SPACE SOOP_HDR10
    #else
        #define _SOOP_COLOUR_SPACE SOOP_SRGB
    #endif
#endif

#if _SOOP_COLOUR_SPACE == 3
	
	#include "ReShade.fxh"

//============================================================================================
// Functions
//============================================================================================

	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 sRGBToLinear(float3 x)
	{
	    return x < 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4);
	}
	
	float3 Rec709ToRec2020(float3 colour)
	{
	    return mul(float3x3
		(
	        1.6605, -0.5876, -0.0728,
	       -0.1246,  1.1329, -0.0083,
	       -0.0182, -0.1006,  1.1187
	    ), colour);
	}
	
	float3 InverseReinhard(float3 x)
	{
	    return x / (1.0 - x);
	}
	
	float LinearToPQ(float x)
	{
	    const float m1 = 0.1593017578125;
	    const float m2 = 78.84375;
	    const float c1 = 0.8359375;
	    const float c2 = 18.8515625;
	    const float c3 = 18.6875;
	
	    float Y = clamp(x / 80.0, 0.0, 1.0);
	    float num = c1 + c2 * pow(Y, m1);
	    float den = 1.0 + c3 * pow(Y, m1);
	    return pow(num / den, m2);
	}

//============================================================================================
// Shader
//============================================================================================

	float4 ConvertBuffer(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float3 sRGBColour = tex2D(ReShade::BackBuffer, texcoord).rgb;
	    float3 LinearColour = sRGBToLinear(sRGBColour);
	
	    float3 Rec2020Colour = Rec709ToRec2020(LinearColour);

	    float3 TonemappedColour = InverseReinhard(Rec2020Colour);
	    float3 HDRColour = float3(LinearToPQ(TonemappedColour.r), LinearToPQ(TonemappedColour.g), LinearToPQ(TonemappedColour.b));
	
	    return float4(HDRColour, 1.0);
	}
	
//============================================================================================
// Technique / Passes
//============================================================================================
	
	technique HDR10TosRGB < ui_label = "HDR10 PQ to sRGB"; ui_tooltip = "A simple shader to convert HDR10 PQ to sRGB. \nUseful for working with SDR only shaders when working in HDR10."; >
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ConvertBuffer;
	    }
	}
#else
	uniform int ColourSpaceWarning <
		ui_type = "radio";
		ui_text = "The detected colour space is not intended to be used with this shader."
			"\nPlease ensure you are playing in HDR10 PQ when using this shader. \nThis shader cannot convert SDR to HDR."
			"\n\nIf the HDR format has been detected incorrectly, please use the _SOOP_COLOUR_SPACE Global Preprocessor to override to the correct format."
			"\nFor this shader, override to SOOP_HDR10";
		ui_label = " ";
		> = 0;
			
	technique SRGBToHDR10 <
		ui_label = "sRGB to HDR10 PQ (Error)";
		ui_tooltip = "A simple shader to convert sRGB to HDR10 PQ. \nUseful for working with SDR only shaders when working in scRGB HDR \nThe detected colour space is not HDR!";
		>	
	{ }
#endif