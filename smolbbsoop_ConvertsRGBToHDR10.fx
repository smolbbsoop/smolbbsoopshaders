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
// Functions
//============================================================================================

static const float PQ_m1 = 0.1593017578125; // m1 = 2610 / 16384
static const float PQ_m2 = 78.84375;        // m2 = (2523 / 4096) * 128
static const float PQ_c1 = 0.8359375;       // c1 = 3424 / 4096
static const float PQ_c2 = 18.8515625;      // c2 = 2413 / 4096 * 32
static const float PQ_c3 = 18.6875;         // c3 = 2392 / 4096 * 32

// thanks to TreyM for posting this in the ReShade Discord's code chat :3
float3 SRGBToLinear(float3 color)
{
    return color < 0.04045 ? color / 12.92 : pow((color + 0.055) / 1.055, 2.4);
}

float3 LinearToPQ(float3 linearHDR)
{
    float3 normalizedHDR = saturate((linearHDR + 0.01) / 10000.0);
    float3 pqColor = pow((PQ_c1 + PQ_c2 * pow(normalizedHDR, PQ_m1)) / (1.0 + PQ_c3 * pow(normalizedHDR, PQ_m1)), PQ_m2);
    return pqColor;
}

//============================================================================================
// Shader
//============================================================================================

void ConvertBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    float4 srgbColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 linearColor = SRGBToLinear(srgbColor.rgb);
    float3 hdr10Color = LinearToPQ(linearColor * 10000.0);

    color = float4(hdr10Color, srgbColor.a);
}

//============================================================================================
// Technique / Passes
//============================================================================================

technique sRGBToHDR10 < ui_label = "sRGB to HDR10 PQ"; ui_tooltip = "A simple shader to convert scene sRGB to HDR10. Useful for working with SDR only shaders when working in HDR10. \n(NOTE, this shader does not convert games to HDR!)"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = ConvertBuffer;
    }
}