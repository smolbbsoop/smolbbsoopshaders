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

float3 PQToLinear(float3 encodedHDR)
{
    float3 ePrimePower = pow(encodedHDR, 1.0 / PQ_m2);
    float3 numerator = max(ePrimePower - PQ_c1, 0.0);
    float3 denominator = PQ_c2 - PQ_c3 * ePrimePower;
    float3 linearHDR = pow(numerator / denominator, 1.0 / PQ_m1);

    return linearHDR * 10000.0;
}

// thanks to TreyM for posting this in the ReShade Discord's code chat :3
float3 LinearToSRGB(float3 x)
{
    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
}

//============================================================================================
// Shader
//============================================================================================

void ConvertBuffer(float4 position : SV_Position, float2 texcoord : TEXCOORD, out float4 color : SV_Target)
{
    float4 hdrColor = tex2D(ReShade::BackBuffer, texcoord);
    float3 linearColor = PQToLinear(hdrColor.rgb);
    float3 srgbColor = LinearToSRGB(linearColor / 10000.0); // Normalize to [0, 1] for sRGB

    color = float4(srgbColor, hdrColor.a); // Preserve alpha
}

//============================================================================================
// Technique / Passes
//============================================================================================

technique HDR10ToSRGB < ui_label = "HDR10 PQ to sRGB"; ui_tooltip = "A simple shader to convert HDR10 PQ to sRGB. Useful for working with SDR only shaders when working in HDR10"; >
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader  = ConvertBuffer;
    }
}