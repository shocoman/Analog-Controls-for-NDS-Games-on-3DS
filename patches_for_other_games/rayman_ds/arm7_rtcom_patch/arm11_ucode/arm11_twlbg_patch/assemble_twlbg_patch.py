import subprocess
import os


patch_asm_input_file = "arm11_twlbg_patch.s"
as_exe = "arm-none-eabi-as"
objcopy_exe = "arm-none-eabi-objcopy"

current_dir = os.path.dirname(os.path.realpath(__file__))

subprocess.check_output([as_exe, patch_asm_input_file, "-o", "arm11_twlbg_patch.out"], cwd=current_dir)
subprocess.check_output([objcopy_exe, "-Obinary", "arm11_twlbg_patch.out", "TWLBG_PATCH.NO_NUB.bin"], cwd=current_dir)
subprocess.check_output([as_exe, patch_asm_input_file, "-o", "arm11_twlbg_patch.out",
                        "--defsym", "INCLUDE_NEW_3DS_STUFF=1"], cwd=current_dir)
subprocess.check_output([objcopy_exe, "-Obinary", "arm11_twlbg_patch.out", "TWLBG_PATCH.WITH_NUB.bin"], cwd=current_dir)

# os.remove(current_dir + "/arm11_twlbg_patch.out")
