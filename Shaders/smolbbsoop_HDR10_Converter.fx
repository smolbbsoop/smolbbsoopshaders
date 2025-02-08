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

#include ".\smolbbsoop\smolbbsoop_Global.fxh"

#if _SOOP_COLOUR_SPACE == 3

	#include "ReShade.fxh"

//============================================================================================
// Shader (Before)
//============================================================================================

	float4 ConvertBufferBefore(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float3 sRGBColour = tex2D(ReShade::BackBuffer, texcoord).rgb;
	    float3 LinearColour = sRGBToLinear(sRGBColour);
	
	    float3 Rec2020Colour = Rec709ToRec2020(LinearColour);

	    float3 TonemappedColour = InvReinhard(Rec2020Colour);
	    float3 HDRColour = LinearToPQ(TonemappedColour.rgb);
	
	    return float4(HDRColour, 1.0);
	}
	
//============================================================================================
// Shader (After)
//============================================================================================

	float4 ConvertBufferAfter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float3 HDRColour = tex2D(ReShade::BackBuffer, texcoord).rgb;
	    float3 LinearColour = PQToLinear(HDRColour.rgb);
	
	    float3 Rec709Colour = Rec2020ToRec709(LinearColour);
	
	    float3 TonemappedColour = Reinhard(Rec709Colour);
	    float3 sRGBColour = float3(LinearTosRGB(TonemappedColour.rgb));
	
	    return float4(sRGBColour, 1.0);
	}

//============================================================================================
// Technique / Passes
//============================================================================================
	
	technique HDR10ToSDR < ui_label = "HDR10 Converter (Before)"; ui_tooltip = "A simple shader to convert HDR10 PQ to sRGB. \nUseful for working with SDR only shaders when working in HDR10."; >
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ConvertBufferBefore;
	    }
	}
	
	technique SDRToHDR10 < ui_label = "HDR10 Converter (After)"; ui_tooltip = "A simple shader to convert sRGB to HDR10 PQ. \nUseful for working with SDR only shaders when working in HDR10."; >
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ConvertBufferAfter;
	    }
	}
#elif _SOOP_COLOUR_SPACE == 1
	uniform int ColourSpaceWarning <
		ui_type = "radio";
		ui_text = "The detected colour space (sRGB SDR) is not intended to be used with this shader."
			"\nPlease ensure you are playing in HDR10 PQ when using this shader. \nThis shader cannot convert SDR to HDR."
			"\n\nIf the HDR format has been detected incorrectly, please use the _SOOP_COLOUR_SPACE Global Preprocessor to override to the correct format."
			"\nFor this shader, override to SOOP_HDR10";
		ui_label = " ";
		> = 0;
			
	technique CompilationErrorsRGB <
		ui_label = "HDR10 Converter (Error)";
		ui_tooltip = "A simple shader to convert sRGB to HDR10 PQ. \nUseful for working with SDR only shaders when working in scRGB HDR \nThe detected colour space is not HDR!";
		>	
	{ }
#elif _SOOP_COLOUR_SPACE == 2
	uniform int ColourSpaceWarning <
		ui_type = "radio";
		ui_text = "The detected colour space (scRGB HDR) is not intended to be used with this shader."
			"\nPlease ensure you are playing in HDR10 PQ when using this shader. \nThis shader cannot convert SDR to HDR."
			"\n\nIf the HDR format has been detected incorrectly, please use the _SOOP_COLOUR_SPACE Global Preprocessor to override to the correct format."
			"\nFor this shader, override to SOOP_HDR10";
		ui_label = " ";
		> = 0;
			
	technique CompilationErrorscRGB <
		ui_label = "HDR10 Converter (Error)";
		ui_tooltip = "A simple shader to convert sRGB to HDR10 PQ. \nUseful for working with SDR only shaders when working in scRGB HDR \nThe detected colour space is not HDR10 PQ!";
		>	
	{ }
#endif