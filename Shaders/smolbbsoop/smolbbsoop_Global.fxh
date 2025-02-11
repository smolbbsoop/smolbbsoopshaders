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

//==============================================================
// Functions (After)
//==============================================================

	float3 PQToLinear(float3 x)
	{
	    float3 num = max(pow(x, 1.0 / PQ_m2) - PQ_c1, 0.0);
	    float3 den = PQ_c2 - PQ_c3 * pow(x, 1.0 / PQ_m2);
	    
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
	    
	    float3 num = PQ_c1 + PQ_c2 * pow(Y, PQ_m1);
	    float3 den = 1.0 + PQ_c3 * pow(Y, PQ_m1);
	    
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