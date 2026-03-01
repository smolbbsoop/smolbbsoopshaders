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

//============================================================================================
// sRGB Functions
//============================================================================================
	
#if _SOOP_COLOUR_SPACE == 1
	
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

//============================================================================================
// scRGB Functions
//============================================================================================

#elif _SOOP_COLOUR_SPACE == 2

//==============================================================
// Functions (Before)
//==============================================================

	float3 Reinhard(float3 x)
	{
	    return x / (1.0 + x);
	}
	
	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 LinearToSRGB(float3 x)
	{
	    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
	}
		
//==============================================================
// Functions (After)
//==============================================================

	float3 InvReinhard(float3 x)
	{
	    return x / (1.0 - x);
	}
	
	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 sRGBToLinear(float3 colour)
	{
	    return colour < 0.04045 ? colour / 12.92 : pow((colour + 0.055) / 1.055, 2.4);
	}
	
//============================================================================================
// HDR10 PQ Functions
//============================================================================================

#elif _SOOP_COLOUR_SPACE == 3

	#define PQ_m1 0.1593017578125
	#define PQ_m2 78.84375
	#define PQ_c1 0.8359375
	#define PQ_c2 18.8515625
	#define PQ_c3 18.6875
	
	uniform int PeakBrightness <
			ui_type = "drag";
			ui_label = "Peak Brightness";
			ui_category = "Global";
			ui_min = 100; ui_max = 10000;
			//hidden = true;
			ui_tooltip = "Input HDR Peak Brightness. Setting the correct value ensures the conversion is as accurate as possible";
		> = 1000;

//============================================================================================
// Color Spaces Conversion Matrices and Functions
// From https://github.com/clshortfuse/renodx/tree/main/src/shaders
//============================================================================================

static const float3x3 BT709_TO_XYZ_MAT = float3x3(
    0.4123907993f, 0.3575843394f, 0.1804807884f,
    0.2126390059f, 0.7151686788f, 0.0721923154f,
    0.0193308187f, 0.1191947798f, 0.9505321522f);

static const float3x3 XYZ_TO_BT709_MAT = float3x3(
    3.2409699419f, -1.5373831776f, -0.4986107603f,
    -0.9692436363f, 1.8759675015f, 0.0415550574f,
    0.0556300797f, -0.2039769589f, 1.0569715142f);

static const float3x3 BT2020_TO_XYZ_MAT = float3x3(
    0.6369580483f, 0.1446169036f, 0.1688809752f,
    0.2627002120f, 0.6779980715f, 0.0593017165f,
    0.0000000000f, 0.0280726930f, 1.0609850577f);

static const float3x3 XYZ_TO_BT2020_MAT = float3x3(
    1.7166511880f, -0.3556707838f, -0.2533662814f,
    -0.6666843518f, 1.6164812366f, 0.0157685458f,
    0.0176398574f, -0.0427706133f, 0.9421031212f);

//static const float3x3 BT709_TO_BT2020_MAT = mul(XYZ_TO_BT2020_MAT, BT709_TO_XYZ_MAT);
//static const float3x3 BT2020_TO_BT709_MAT = mul(XYZ_TO_BT709_MAT, BT2020_TO_XYZ_MAT);

	float3 Bt709FromBt2020(float3 bt2020){
		return mul(mul(XYZ_TO_BT709_MAT, BT2020_TO_XYZ_MAT), bt2020);
	}
	float3 Bt2020FromBt709(float3 bt709){
		return mul(mul(XYZ_TO_BT2020_MAT, BT709_TO_XYZ_MAT), bt709);
	}

//==============================================================
// Functions (After)
//==============================================================

	float3 PQToLinear(float3 x)
	{
	    float3 xpow = pow(max(x, 0.0), 1.0 / PQ_m2);
	    float3 num = max(xpow - PQ_c1, 0.0);
	    float3 den = max(PQ_c2 - PQ_c3 * xpow, 1e-10);
	    
	    float scalingFactor = 20375.99 * pow(PeakBrightness, -0.995);
	    
	    return pow(num / den, 1.0 / PQ_m1) * scalingFactor;
	}
	
	float3 Reinhard(float3 x)
	{
	    return x / (1.0 + x);
	}
	
	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 LinearTosRGB(float3 x)
	{
	    return x < 0.0031308 ? 12.92 * x : 1.055 * pow(x, 1.0 / 2.4) - 0.055;
	}

//==============================================================
// Functions (Before)
//==============================================================

	float3 LinearToPQ(float3 x)
	{
	    float S = 0.003789 * PeakBrightness;
	    float3 x_scaled = x * S;
	    float3 Y = clamp(x_scaled / 80.0, 0.0, 1.0);
	    
	    float3 Ym1 = pow(Y, PQ_m1);
	    float3 num = PQ_c1 + PQ_c2 * Ym1;
	    float3 den = 1.0 + PQ_c3 * Ym1;
	    
	    return pow(num / den, PQ_m2);
	}

	float3 InvReinhard(float3 x)
	{
	    return x / (1.0 - x);
	}

	// thanks to TreyM for posting this in the ReShade Discord's code chat :3
	float3 sRGBToLinear(float3 x)
	{
	    return x < 0.04045 ? x / 12.92 : pow((x + 0.055) / 1.055, 2.4);
	}
#endif
