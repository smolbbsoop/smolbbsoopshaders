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

#define SDR 0
#define HDR10 1
#define LINEAR 2

#ifndef _COLOUR_SPACE_OVERRIDE
    #if (BUFFER_COLOR_SPACE == 1)
        #define _COLOUR_SPACE_OVERRIDE SDR
    #elif (BUFFER_COLOR_SPACE == 2)
        #define _COLOUR_SPACE_OVERRIDE LINEAR
    #elif (BUFFER_COLOR_SPACE == 3)
        #define _COLOUR_SPACE_OVERRIDE HDR10
    #else
        #define _COLOUR_SPACE_OVERRIDE SDR // Default to sRGB for unknown BUFFER_COLOR_SPACE
    #endif
#endif

#if BUFFER_COLOR_SPACE == 2 || _COLOUR_SPACE_OVERRIDE == LINEAR

	#include "Reshade.fxh"
	
	//============================================================================================
	// Functions
	//============================================================================================
	
	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 SRGBToLinear(float3 color)
	{
	    return color < 0.04045 ? color / 12.92 : pow((color + 0.055) / 1.055, 2.4);
	}
	
	//============================================================================================
	// Shader
	//============================================================================================
	
	void ConvertBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
	{
	    float4 scRGBColor = tex2D(ReShade::BackBuffer, texcoord);
	    float3 linearHDRColor = SRGBToLinear(scRGBColor.rgb);
	
	    color = float4(linearHDRColor, scRGBColor.a);
	}
	
	//============================================================================================
	// Technique / Passes
	//============================================================================================
	
	technique SRGBToLinear < 
		ui_label = "sRGB to Linear"; 
		ui_tooltip = "A simple shader to convert sRGB to scene linear. \nUseful for working with SDR only shaders when working in scRGB HDR"; 
		>
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
			"\nPlease ensure you are playing in scRGB HDR when using this shader. \nThis shader cannot convert SDR to HDR.";
		ui_label = " ";
		> = 0;
			
	technique SRGBToLinear <
		ui_label = "sRGB to Linear (Error)";
	    ui_tooltip = "A simple shader to convert sRGB to scene linear. \nUseful for working with SDR only shaders when working in scRGB HDR \nThe detected colour space is not HDR!";
		>	
	{ }
#endif