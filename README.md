### Super Mario 64 DS Circle Pad

Here lies an attempt to create a patch that would allow the Circle Pad to be used to control the main character in Super Mario 64 DS when played on a 3DS using TwilightMenu. On New 3DS/New 2DS systems, the patch also makes it possible to rotate the camera left and right using the ZL and ZR buttons, as well as with the nub stick (they just emulate pressing the "<-" and "->" buttons on the touchscreen).

The patch uses RTCom, a custom protocol that utilizes two free 1-byte legacy RTC registers, to pass data between Arm7 and Arm11 in order to allow the game to use the Circle Pad for controls. It requires TWPatcher with RTCom enabled in order to work. At the time of writing, a detailed description of RTCom by Sono can be found in the comments of [the gbatemp thread](https://gbatemp.net/threads/circle-pad-patches-for-super-mario-64-ds-and-other-games-in-twilightmenu-with-twpatcher-and-rtcom.623267/post-10026852).

It is possible to remap the ZL and ZR buttons to other keys (mostly A, B, X, Y, L, R). So, instead of strictly rotating the camera, they may do something else. The buttons can be remapped similarly through additional AR cheatcodes. I have a simple webpage to generate them [here](https://shocoman.github.io/sm64ds_remap_codegen/).

### Action Replay code

The patch comes in the form of an Action Replay cheatcode that performs the following tasks:

1.  Overwrites a huge chunk of Arm7 code that is usually responsible for working with RTC (but isn't used by the game, and even if it would, it's still possible to replace it with a stub. I used this approach in other games) with Arm7 and Arm11 code that is stored in the Action Replay cheatcode. This code is used to read and pass the Circle Pad state to Arm9 where it can use it.
    
2.  Erases a branch instruction to prevent Arm7 from calling the RTC initialization function, which is no longer exists nor needed.
    
3.  Copies Arm9 code into a "safe" place and inserts a branch instruction to jump there from the game's controls routine that usually updates the input. This allows Arm9 to read the Circle Pad state and conditionally skip the usual touchscreen and D-pad update functionality in the current frame, allowing players to still use the Circle Pad without permanently disabling the touchscreen and D-pad controls.


### Project structure

-   [action_replay_codes](./action_replay_codes) - Contains Action Replay codes for different versions of the game, with and without Nub, ZL, and ZR support. The folder also includes a prepopulated [usrcheat.dat](./action_replay_codes/usrcheat.dat) file that should be placed at `_nds/TWiLightMenu/extras/usrcheat.dat`.
-  [arm9_controls_hook.s](./arm9_controls_hook.s) - Arm9's part of the project. Reads the Circle Pad data (saved by Arm7) and processes it to calculate the displacement vector length, sine, cosine, and angle (to get the character's direction and speed), just like the game does normally with the touchscreen controls.
- [arm7](./arm7_rtcom_patch/arm7) -  Arm7 uploads "microcode" to Arm11. This microcode patches the TwlBg at runtime (the assembly code for this TwlBg patch is [here](./arm7_rtcom_patch/arm11_ucode/arm11_twlbg_patch/arm11_twlbg_patch.s)). After that, the TwlBg will start sending fresh CPad data via [free legacy RTC registers](http://problemkaputt.de/gbatek-3ds-gpio-registers.htm) in each frame. In our case, all RTC registers are free because SM64DS doesn't use or read time and date. The TwlBg has some available space (probably a lot of it) for new code - at the point of the first contact with Arm7 some functions are no longer needed and can be safely overwritten.
-   [arm11_ucode](./arm7_rtcom_patch/arm11_ucode) - Arm11 "microcode" that finds all required memory locations (like position of the CPad data), initializes the nub stick, and patches the TwlBg. Most of Arm7/Arm11 is borrowed from the exemplary [Rtc3DS](https://github.com/Gericom/Rtc3DS) project.
- [generate_patch.py](./generate_patch.py) - a script that is supposed to automatically build everything (including the TwlBg patch), link the Arm7 and Arm11 binaries together and generate the "action_replay_codes" folder in the end. Requires devkitPro, ndstools and whatnot. It also can (when given a filename) patch a rom directly without having to use an AR cheatcode, but this would change the checksum of the rom and break all other cheatcodes.
