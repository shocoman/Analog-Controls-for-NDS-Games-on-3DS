### Super Mario 64 DS Circle Pad

Here lies an attempt to create a patch that would allow using the Circle Pad to control the main character in Super Mario 64 DS when played on a 3DS using TwilightMenu. On New 3DS/New 2DS systems, the patch also allows the player to rotate the camera left and right using the ZL and ZR buttons, as well as with the Nub stick (they just emulate pressing the "<-" and "->" buttons on the touchscreen).

The patch uses RTCom, a custom protocol that utilizes two free 1-byte legacy RTC registers, to pass data between Arm7 and Arm11 in order to allow the game to use the Circle Pad for control. It requires TWPatcher with RTCom enabled in order to work. At the time of writing, a detailed description of RTCom by Sono can be found in the comments of [the gbatemp thread](https://gbatemp.net/threads/patch-to-play-super-mario-64-ds-with-circle-pad-in-twilightmenu-with-twpatcher-and-rtcom.623267/).

### Action Replay code

The patch is in the form of an Action Replay code which performs the following tasks:

1.  Overwrites a huge chunk of Arm7 code that is usually responsible for working with RTC (but isn't used by the game) with Arm7 and Arm11 code that is stored in the Action Replay code. This code is used to read and pass the Circle Pad state to Arm9 where it can use it.
    
2.  NOPs a branch instruction to prevent Arm7 from calling the RTC initialization function, which is no longer exists nor needed.
    
3.  Copies Arm9 code into a "safe" place and inserts a branch instruction to jump there from the game's routine that usually updates the input. This allows Arm9 to read the Circle Pad state and conditionally skip the usual touchscreen and D-pad update functionality in a current frame, allowing the player still to use the Circle Pad without permanently disabling the touchscreen and D-pad controls.

### Known issues

-   There is a 10-15% slowdown in music due to the time that Arm7 spends waiting for Arm11 to respond.
-   There may be random amplitude spikes in the music when returning from the sleep mode. This is not related to RTCom and can also occur when opening the "nds-bootstrap" menu in some games. It seems to happen when Arm7 spends too much time inside a VBlank IRQ handler.

The second version doesn't have this problems as far as I know.

### Project structure

-   [action_replay_codes](./action_replay_codes) - Contains Action Replay codes for different versions of the game, with and without Nub, ZL, and ZR support. The folder also includes a prepopulated [usrcheat.dat](./action_replay_codes/usrcheat.dat) file that can be placed at `_nds/TWiLightMenu/extras/usrcheat.dat`.
-  [arm9_controls_hook.s](./arm9_controls_hook.s) - Arm9's part of the project. Reads the Circle Pad data (saved by Arm7) and processes it to calculate the displacement vector length, sine, cosine, and angle (to get the character's direction and speed), just like the game does normally with the touchscreen.
- [arm7](./arm7_rtcom_patch/arm7) -  Arm7 uploads the microcode that reads the CPad data to Arm11 and then periodically, on almost every VBlank IRQ, sends a command to execute it there, receives the CPad and Nub data and writes it to a safe place for Arm9. The safe place in this case is where RTC Date&Time registers are usually saved by Arm7's RTC routines (0x027ffde8).
-   [arm11_ucode](./arm7_rtcom_patch/arm11_ucode) - Arm11 "microcode" that executes the Circle Pad reading code sent from Arm7 and passes the data back to Arm7 when requested. Most of Arm7/Arm11 is borrowed from the exemplary [Rtc3DS](https://github.com/Gericom/Rtc3DS) project.
- [generate_patch.py](./generate_patch.py) - a script that is supposed to automatically build everything, link Arm7 and Arm11 together and generate the "action_replay_codes" folder. Requires devkitPro, ndstools and whatnot.

### V2
[The second version](./V2) uses a bit different approach. Instead of constantly communicating with Arm11 back and forth, we can just patch TwlBg at runtime once at the start and tell it to pass us fresh CPad data via [free legacy RTC regs](http://problemkaputt.de/gbatek-3ds-gpio-registers.htm) on every frame. In our case, all of the RTC regs are free, because SM64DS doesn't use or read time&date. The TwlBg has some available space for new code - at the point of the first contact some functions are no longer needed and can be safely overwritten.
This version also allows remapping the ZL and ZR buttons to other keys (mostly A, B, X, Y, L, R). So, instead of strictly rotating the camera, they may do something else. The buttons can be remapped similarly through additional AR codes. I have a simple webpage to generate them [here](https://shocoman.github.io/sm64ds_remap_codegen/).
