# smolbbsoopshaders
A collection of ReShade shaders, mostly made for personal use but maybe somebody can get some use out of them!

## Radial Blur
This was the main shader I've wanted for a while. It's a fairly simple symmetrical radial blur, similar to the one found in Davinci Resolve (where I got the idea).
It's not exactly well optimised but what can you expect for first shaders.

## sRGB to Scene Linear (and the inverse)
These 2 shaders are super niche. The intention is to convert either an SDR game to scene linear and use shaders within that (not that many support that), or the opposite, converting an scRGB HDR game to an approximation of sRGB for use with SDR only shaders. It does the job :)
