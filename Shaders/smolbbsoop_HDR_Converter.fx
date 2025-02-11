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

//============================================================================================
// scRGB Converter
//============================================================================================

#if _SOOP_COLOUR_SPACE == 2

	#include "Reshade.fxh"
	
//==================================================
// Shader (Before)
//==================================================
	
	void ConvertBufferBefore(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 colour : SV_Target)
	{
	    float4 LinearColour = tex2D(ReShade::BackBuffer, texcoord);
	    float3 TonemappedColour = Reinhard(LinearColour.rgb);
	    float3 sRGBColour = LinearToSRGB(TonemappedColour.rgb);
	
	    colour = float4(sRGBColour, LinearColour.a);
	}
	
//==================================================
// Shader (After)
//==================================================
	
	void ConvertBufferAfter(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 colour : SV_Target)
	{
	    float4 sRGBColour = tex2D(ReShade::BackBuffer, texcoord);
	    float3 LinearColour = sRGBToLinear(sRGBColour.rgb);
	    float3 InvTonemappedColour = InvReinhard(LinearColour.rgb);
	
	    colour = float4(InvTonemappedColour, sRGBColour.a);
	}

//============================================================================================
// Technique / Passes
//============================================================================================

	technique LinearTosRGB < 
		ui_label = "scRGB Converter (Before)"; 
		ui_tooltip = "A simple shader to convert scRGB HDR to sRGB SDR. \nUseful for working with SDR only shaders when working in scRGB HDR"; 
		>
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ConvertBufferBefore;
	    }
	}
	technique sRGBToLinear < 
		ui_label = "scRGB Converter (After)"; 
		ui_tooltip = "A simple shader to convert sRGB SDR to scRGB HDR. \nUseful for working with SDR only shaders when working in scRGB HDR"; 
		>
	{
	    pass
	    {
	        VertexShader = PostProcessVS;
	        PixelShader  = ConvertBufferAfter;
	    }
	}

//============================================================================================
// HDR10 PQ Converter
//============================================================================================

#elif _SOOP_COLOUR_SPACE == 3

	#include "ReShade.fxh"

//==================================================
// Shader (Before)
//==================================================

	float4 ConvertBufferBefore(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float3 HDRColour = tex2D(ReShade::BackBuffer, texcoord).rgb;
	    float3 LinearColour = PQToLinear(HDRColour.rgb);
		float3 sRGBColour = LinearTosRGB(LinearColour);
		
	    float3 TonemappedColour = Reinhard(sRGBColour);
	
	    return float4(TonemappedColour, 1.0);
	}

//==================================================
// Shader (After)
//==================================================

	float4 ConvertBufferAfter(float4 pos : SV_Position, float2 texcoord : TEXCOORD) : SV_Target
	{
	    float3 sRGBColour = tex2D(ReShade::BackBuffer, texcoord).rgb;
		float3 TonemappedColour = InvReinhard(sRGBColour);
	    float3 LinearColour = sRGBToLinear(TonemappedColour);
	    
	    float3 HDRColour = LinearToPQ(LinearColour);
	
	    return float4(HDRColour, 1.0);
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
			"\nPlease ensure you are playing in HDR (Either HDR10 PQ or scRGB) when using this shader. \nThis shader cannot convert SDR to HDR."
			"\n\nIf the HDR format has been detected incorrectly, please use the _SOOP_COLOUR_SPACE Global Preprocessor to override to the correct format."
			"\nAvailable Colour Spaces:"
			"\nSOOP_HDR10"
			"\nSOOP_SCRGB";
		ui_label = " ";
		> = 0;
			
	technique CompilationErrorsRGB <
		ui_label = "HDR Converter (Error)";
		ui_tooltip = "A simple shader to convert HDR to SDR. \nUseful for working with SDR only shaders when playing in HDR \nThe detected colour space is not HDR!";
		>	
	{ }
#endif