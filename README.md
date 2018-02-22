# Journey Sand
A Unity project to remake the scene in Journey.

********

A demo image for the scene in the project :

![Screenshot](Images/Title2.jpg)

The reference scene from Journey :

![Screenshot](Images/ReferenceImg.jpg)

(Image Source: GDC Vault 2012 - https://www.gdcvault.com/play/1017742/Sand-Rendering-in)

## Diffuse

A modified Oren Nayar model is implemented :

![Screenshot](Images/Diffuse.jpg)

## Height map(Normal map)

The terrain is separated into X-direction and Z-direction.

![Screenshot](Images/NormalXZ.jpg)

Normal map in X and Z direction is applied to different orientations.

![Screenshot](Images/NormalXZSmooth.jpg)

TBN convert the normal to correct direction

![Screenshot](Images/NormalDetail.jpg)

The overall effect :

![Screenshot](Images/Normal.jpg)

## Specular

Well, simply, it is Bilnn-Phong model. I also tried the PBR but there is just a very vague improvement.

![Screenshot](Images/Specular.jpg)

## Glitter

Not 100% sure what the noise function is uesd. Here is a fake effect to simulate the one in Journey.

![Screenshot](Images/Glitter.jpg)

![Screenshot](Images/GlitterEffect.jpg)

******

## Post Effect

The result without any screen-base effect:

![Screenshot](Images/Post1.jpg)

Add Bloom: (Post Processing Stack)

![Screenshot](Images/Post2.jpg)

Add Tone map and LUT :(Post Processing Stack)

![Screenshot](Images/Post3.jpg)

Add Sharpen and saturation : (Beautify https://assetstore.unity.com/packages/vfx/shaders/fullscreen-camera-effects/beautify-61730)

![Screenshot](Images/Post4.jpg)

******

## License

[![License: CC BY-SA 4.0](https://img.shields.io/badge/License-CC%20BY--SA%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by-sa/4.0/)
