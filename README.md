# smolbbsoopshaders
A collection of ReShade shaders, mostly made for personal use but maybe somebody can get some use out of them!

## Radial Blur
This was the main shader I've wanted for a while. It's a fairly simple symmetrical radial blur, similar to the one found in Davinci Resolve (where I got the idea).
It's not exactly well optimised but what can you expect for first shaders.

![RadialBlurExample](https://github.com/user-attachments/assets/f10a45df-071e-4070-841e-1f72b7e18ddd)

## sRGB to Scene Linear (and the inverse)
These 2 shaders are super niche. The intention is to convert either an SDR game to scene linear and use shaders within that (not that many support that), or the opposite, converting an scRGB HDR game to an approximation of sRGB for use with SDR only shaders. It does the job :)

![Scene Linear Example](https://github.com/user-attachments/assets/18541437-29a7-4027-905b-76692fb8fff7)

## HDR10 PQ to sRGB (and the inverse)
In a similar vein to the prior shader pair, these shaders aim to convert an HDR10 game's output to sRGB for use with SDR only shaders. The implementation isn't perfect, with the darks usually getting a bit of banding after, but nobody else seems to be making it.

![HDR10toSDR example](https://github.com/user-attachments/assets/3f62c936-a298-4c2b-ac06-a83e4ef6c24d)
