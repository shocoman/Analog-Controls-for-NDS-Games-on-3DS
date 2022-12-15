#!/bin/python
from pathlib import Path
import zlib
import sys
import subprocess
import re
import struct
from collections import defaultdict


ARM9_ROM_ADDRESS = 0x02004000
ARM9_CONTROLS_INIT_HOOK_ADDR = 0x020049EC
ARM9_CONTROLS_BASE_PATCH_ADDR = 0x02004b00  # or 0x0234B500?

# rom_path = "Super Mario 64 DS (USA).nds"
rom_path = sys.argv[1] if len(sys.argv) > 1 else ""

tmp_folder_name = "tmp_ndstools"
arm7_update_rtcom_function_name = "Update_RTCom"

ndstool_exe_path = "ndstool"
asm_exe_path = "arm-none-eabi-as"
objcopy_exe_path = "arm-none-eabi-objcopy"
objdump_exe_path = "arm-none-eabi-objdump"
ld_exe_path = "arm-none-eabi-ld"
make_exe_path = "make"

ndstool_params = [
    "-9", f"{tmp_folder_name}/arm9.bin",
    "-7", f"{tmp_folder_name}/arm7.bin",
    "-y9", f"{tmp_folder_name}/y9.bin",
    "-y7", f"{tmp_folder_name}/y7.bin",
    "-d", f"{tmp_folder_name}/data",
    "-y", f"{tmp_folder_name}/overlay",
    "-h", f"{tmp_folder_name}/header.bin",
    "-t", f"{tmp_folder_name}/banner.bin",
]

arm9_rom_function_offsets = {
    # Address to insert branch for controls hook; ipc_sendmsg func; sqrt func; getangle func; controls struct address
    "ASMP-D3D9F14A": [0x202C408, 0x0205b988, 0x0203d744, 0x0203b4dc, 0x0209f498],
    "ASMJ-D2BBD1E6": [0x202B5E4, 0x0205a6d4, 0x0203c4d0, 0x0203a26c, 0x0209803c],
    "ASMJ-D2F380B2": [0x202B5AC, 0x02059f10, 0x0203bd0c, 0x02039aa8, 0x02096f7c],
    "ASMK-3C73EADE": [0x202B3E8, 0x02059298, 0x0203bdd4, 0x0203a158, 0x0209e548],
    "ASME-AEA63749": [0x202B324, 0x020599fc, 0x0203b898, 0x02039684, 0x02097594],
    "ASME-F486F859": [0x202B5E8, 0x0205a6d8, 0x0203c4d4, 0x0203a270, 0x02098ad8]
}

arm7_rom_offsets = {
    # rtc init call instr; rtc init call addr; rtc code block start addr; vblank handler end addr
    "ASMP-D3D9F14A": [0xEB002857, 0x37f837c, 0x03801d44, 0x037f85f4],
    "ASMJ-D2BBD1E6": [0xEB002857, 0x37f837c, 0x03801d44, 0x037f85f4],
    "ASMJ-D2F380B2": [0xEB002857, 0x37f837c, 0x03801d44, 0x037f85f4],
    "ASMK-3C73EADE": [0xEB002857, 0x37f837c, 0x03801d44, 0x037f85f4],
    "ASME-AEA63749": [0xEB002867, 0x37f837c, 0x03801d84, 0x037f85f4],
    "ASME-F486F859": [0xEB002857, 0x37f837c, 0x03801d44, 0x037f85f4]
}

rom_descriptions = {
    "ASMP-D3D9F14A": "Europe v1.0",
    "ASMJ-D2BBD1E6": "Japan v1.1",
    "ASMJ-D2F380B2": "Japan v1.0",
    "ASMK-3C73EADE": "Korea v1.0",
    "ASME-AEA63749": "USA v1.0",
    "ASME-F486F859": "USA v1.1"
}


def find_function_offset_in_asm_listing(asm_code, func_name):
    asm_func_regexp = r"([a-f0-9]{8}) .+" + func_name + ".+"
    regexp_func = re.search(asm_func_regexp, asm_code, re.IGNORECASE)
    addr = -1
    if regexp_func:
        addr = int(regexp_func.group(1), 16)
    return addr


def assemble_arm9_controls_hook_patch(asm_symbols_params):
    patch_asm_filename = "arm9_controls_hook.s"
    assembled_patch_filename = f"{tmp_folder_name}/ARM9_CONTROLS_HOOK_PATCH.bin"

    subprocess.check_output([asm_exe_path, patch_asm_filename, '-o',
                             f'{tmp_folder_name}/arm9_controls_hook.o', *asm_symbols_params])
    subprocess.check_output([objcopy_exe_path, '-Obinary',
                            f'{tmp_folder_name}/arm9_controls_hook.o', assembled_patch_filename])
    with open(assembled_patch_filename, "rb") as patch_file:
        return patch_file.read()


def assemble_arm7_rtcom_patch(rtc_code_block_start_addr, include_nub):
    arm7_patch_dir = 'arm7_rtcom_patch'

    subprocess.check_output([make_exe_path, 'clean', '--directory', arm7_patch_dir])

    include_nub_param = 'EXTERNAL_FLAGS=' + ('-DINCLUDE_NEW_3DS_STUFF' if include_nub else '')
    subprocess.check_output(
        [make_exe_path, include_nub_param, '--directory', arm7_patch_dir],
        stderr=subprocess.DEVNULL)

    subprocess.check_output(
        [ld_exe_path, 'rtcom.o', f'{arm7_patch_dir}.uc11.o', '--output', 'arm7_patch.o', '--section-start',
         f'.text={hex(rtc_code_block_start_addr)}'],
        stderr=subprocess.DEVNULL, cwd=f'{arm7_patch_dir}/arm7/build/')

    subprocess.check_output(
        [objcopy_exe_path, '-O', 'binary', '--only-section=.rodata', '--only-section=.text', 'arm7_patch.o',
         'arm7_patch.bin'],
        cwd=f'{arm7_patch_dir}/arm7/build/')
    arm7_patch_bytes = open(f'{arm7_patch_dir}/arm7/build/arm7_patch.bin', 'rb').read()

    rtcom_asm_code = subprocess.check_output([objdump_exe_path, '-d', 'rtcom.o'],
                                             cwd=f'{arm7_patch_dir}/arm7/build/', text=True)
    update_rtcom_func_offset = find_function_offset_in_asm_listing(rtcom_asm_code, arm7_update_rtcom_function_name)

    return update_rtcom_func_offset, arm7_patch_bytes


def get_asm_symbols_params(instr_to_replace, ipc_sendmsg_func, sqrt_func, getangle_func, controls_struct):
    return [
        "--defsym", "INPUT_UPDATE_INJECT_ADDRESS=" + hex(instr_to_replace),
        "--defsym", "IPC_SEND_MESSAGE_FUNC_ADDRESS=" + hex(ipc_sendmsg_func),
        "--defsym", "SQRT_FUNC_ADDRESS=" + hex(sqrt_func),
        "--defsym", "GET_ANGLE_FUNC_ADDRESS=" + hex(getangle_func),
        "--defsym", "CONTROLS_STRUCT_ADDRESS=" + hex(controls_struct),
        "--defsym", "INIT_HOOK_ADDR=" + hex(ARM9_CONTROLS_INIT_HOOK_ADDR),
        "--defsym", "BASE_PATCH_ADDR=" + hex(ARM9_CONTROLS_BASE_PATCH_ADDR),
    ]


def load_rom_id():
    ROM_GAME_CODE_OFFSET = 0x0C
    with open(rom_path, 'rb') as asm9_file_read:
        header = asm9_file_read.read(0x200)

    gamecode = struct.unpack_from('4s', header, ROM_GAME_CODE_OFFSET)[0].decode()
    header_crc32_jamcrc = ~zlib.crc32(header) & 0xFFFFFFFF
    return f"{gamecode}-{header_crc32_jamcrc:08X}"


def patch_arm9(rom_id):
    with open(f"{tmp_folder_name}/arm9.bin", "rb") as asm9_file_read:
        arm9_code = bytearray(asm9_file_read.read())

    # insert the initial activating hook
    branch_instr = 0xEA000000 | ((ARM9_CONTROLS_BASE_PATCH_ADDR - ARM9_CONTROLS_INIT_HOOK_ADDR - 8) >> 2)
    addr = ARM9_CONTROLS_INIT_HOOK_ADDR - ARM9_ROM_ADDRESS
    struct.pack_into("<I", arm9_code, addr, branch_instr)

    current_rom_offsets = arm9_rom_function_offsets[rom_id]
    patch_code = assemble_arm9_controls_hook_patch(get_asm_symbols_params(*current_rom_offsets))

    relative_base_addr = ARM9_CONTROLS_BASE_PATCH_ADDR - ARM9_ROM_ADDRESS
    arm9_code[relative_base_addr:relative_base_addr+len(patch_code)] = patch_code

    print(f"A9: Patch size: 0x{len(patch_code):08X}")

    with open(f"{tmp_folder_name}/arm9.bin", "wb") as asm9_file_write:
        asm9_file_write.write(arm9_code)


def patch_arm7(rom_id, include_nub):
    _, rtc_init_call_addr, rtc_code_block_addr, vblank_handler_exit_addr = arm7_rom_offsets[rom_id]

    update_rtcom_func_offset, arm7_patch_bytes = assemble_arm7_rtcom_patch(rtc_code_block_addr, include_nub)
    branch_to_rtcom_update_instruction = 0xEA000000 + (
        ((rtc_code_block_addr + update_rtcom_func_offset - vblank_handler_exit_addr - 8) >> 2) & 0xFFFFFF)

    rel_offset = 0x37F7E98
    arm7_rtc_init_call_addr = rtc_init_call_addr - rel_offset
    arm7_rtc_code_block_addr = rtc_code_block_addr - rel_offset
    arm7_vblank_irq_handler_end_addr = vblank_handler_exit_addr - rel_offset

    print(f"A7: 'Branch to Update_RTCom'-instruction: 0x{branch_to_rtcom_update_instruction:08X}")
    print(
        f"A7: Patch Update RTCom func offset: 0x{update_rtcom_func_offset:08X} (0x{update_rtcom_func_offset+rel_offset:08X})")
    print(f"A7: Patch size: 0x{len(arm7_patch_bytes):08X}")
    print(f"A7: Init RTC Call addr: 0x{arm7_rtc_init_call_addr:08X} (0x{rtc_init_call_addr:08X})")
    print(f"A7: RTC Code Block start addr: 0x{arm7_rtc_code_block_addr:08X} (0x{rtc_code_block_addr:08X})")
    print(
        f"A7: VBlank Handler end address: 0x{arm7_vblank_irq_handler_end_addr:08X} (0x{vblank_handler_exit_addr:08X})")

    with open(f"{tmp_folder_name}/arm7.bin", "rb") as asm7_file_read:
        arm7_code = bytearray(asm7_file_read.read())

    struct.pack_into('<I', arm7_code, arm7_rtc_init_call_addr, 0)
    struct.pack_into('<I', arm7_code, arm7_vblank_irq_handler_end_addr, branch_to_rtcom_update_instruction)
    arm7_code[arm7_rtc_code_block_addr:arm7_rtc_code_block_addr+len(arm7_patch_bytes)] = arm7_patch_bytes

    with open(f"{tmp_folder_name}/arm7.bin", "wb") as asm7_file_write:
        asm7_file_write.write(arm7_code)


def patch_rom(rom_path, include_nub):
    rom_id = load_rom_id()
    print(f"A9: Current Gamecode + 'Header CRC32/JAMCRC' = '{rom_id}'")

    subprocess.check_output([ndstool_exe_path, "-x", rom_path, *ndstool_params])
    patch_arm9(rom_id)
    patch_arm7(rom_id, include_nub)
    subprocess.check_output([ndstool_exe_path, "-c", "new_" + Path(rom_path).name, *ndstool_params])


def generate_action_replay_code(rom_id, include_nub):
    rtc_init_call_instr, rtc_init_call_addr, rtc_code_block_addr, vblank_handler_end_addr = arm7_rom_offsets[rom_id]

    update_rtcom_func_offset, arm7_patch_bytes = assemble_arm7_rtcom_patch(rtc_code_block_addr, include_nub)
    branch_to_rtcom_update_instruction = 0xEA000000 + (
        ((rtc_code_block_addr + update_rtcom_func_offset - vblank_handler_end_addr - 8) >> 2) & 0xFFFFFF)

    #############
    # Arm7 Patch
    action_replay_code = f"5{rtc_init_call_addr:07X} {rtc_init_call_instr:08X}\n"  # if equal to this instruction
    action_replay_code += f"0{rtc_init_call_addr:07X} 00000000\n"

    # Copy the main code block
    current_address = rtc_code_block_addr
    for words in struct.iter_unpack("<I", arm7_patch_bytes):
        action_replay_code += f"0{current_address:07X} {words[0]:08X}\n"
        current_address += 4

    # Hook the VBlank IRQ Handler
    action_replay_code += f"0{vblank_handler_end_addr:07X} {branch_to_rtcom_update_instruction:08X}\n"
    action_replay_code += f"D2000000 00000000\n"

    #############
    # Arm9 Patch
    current_rom_offsets = arm9_rom_function_offsets[rom_id]
    arm9_patch_code = assemble_arm9_controls_hook_patch(get_asm_symbols_params(*current_rom_offsets))

    patched_instr_offset = arm9_rom_function_offsets[rom_id][0]
    action_replay_code += f"5{patched_instr_offset:07X} E7D01108\n"  # if equal to this instruction

    last_instr = 0
    current_address = ARM9_CONTROLS_BASE_PATCH_ADDR
    for words in struct.iter_unpack("<I", arm9_patch_code):
        action_replay_code += f"0{current_address:07X} {words[0]:08X}\n"
        current_address += 4
        last_instr = words[0]

    # insert the instruction to branch into the patch code from the controls routine
    action_replay_code += f"0{patched_instr_offset:07X} {last_instr:08X}\n"
    action_replay_code += f"D2000000 00000000\n"

    return action_replay_code


def generate_action_replay_codes_for_all_rom_versions():
    ac_folder_name = "action_replay_codes"
    Path(ac_folder_name).mkdir(exist_ok=True)

    cheat_codes = defaultdict(list)
    for include_nub in [False, True]:
        for rom_id, _ in arm9_rom_function_offsets.items():
            filename = f"{rom_id} ({rom_descriptions[rom_id]})"

            code_text = generate_action_replay_code(rom_id, include_nub)
            nub_postfix = " [with Nub stick, ZL and ZR]" if include_nub else ""
            with open(f"{ac_folder_name}/{filename+nub_postfix}.txt", "w") as f:
                f.write(code_text)

            cheat_codes[rom_id].append({'code': code_text, 'name': "CPAD" + nub_postfix})

    usrcheat_dat_file = generate_usrcheat_dat_file_with_ar_codes(cheat_codes)
    with open(f'{ac_folder_name}/usrcheat.dat', 'wb') as f:
        f.write(usrcheat_dat_file)


def generate_usrcheat_dat_file_with_ar_codes(patches: dict):
    def make_ar_file_header():
        main_header = bytearray(b'\0' * 0x100)
        main_header[0:0xC] = b'R4 CheatCode'
        main_header[0xD] = 1
        db_name = b"SM64DS with CPad AR Codes"
        struct.pack_into(f'{len(db_name)}s', main_header, 0x10, db_name)
        struct.pack_into('<I', main_header, 0x4C, 0x594153d5)
        main_header[0x50] = 1
        return main_header

    def make_ar_game_header(game_name, n_code):
        game_name = game_name.encode()
        game_header = game_name + b'\0' * (4 - len(game_name) % 4)
        game_attribute_header = bytearray(0x24)
        game_attribute_header[0] = n_code
        game_attribute_header[8] = 1
        game_header += game_attribute_header
        return game_header

    def get_ar_code_values_from_text(codes):
        ar_code_values = []
        for line in codes.splitlines():
            columns = line.split()
            if len(columns) != 2:
                continue
            ar_code_values.append(int(columns[0], 16))
            ar_code_values.append(int(columns[1], 16))
        return ar_code_values

    def make_ar_code_record(code_name, code_description, ar_code_values):
        # Code Header
        ar_code_name = code_name.encode()
        ar_code_description = code_description.encode()
        ar_code_header = ar_code_name + b'\0'
        ar_code_header += ar_code_description
        ar_code_header += b'\0' * (4 - len(ar_code_header) % 4)

        # AR Code Record
        ar_code = struct.pack(f"<{len(ar_code_values)}I", *ar_code_values)
        ar_code_size = len(ar_code)
        ar_code_header += struct.pack("<I", ar_code_size // 4)
        ar_code_size_with_header = ar_code_size + len(ar_code_header)
        ar_code_header = struct.pack("<I", ar_code_size_with_header // 4) + ar_code_header

        ar_code_record = ar_code_header + ar_code
        return ar_code_record

    n_games = len(patches)

    # Game Position Table
    game_pos_table = bytearray(0x10 * n_games)

    game_codes = defaultdict(list)
    for i, (rom_id, roms_info) in enumerate(patches.items()):
        gamecode, crc32_str = rom_id.split('-')
        struct.pack_into('<4sI', game_pos_table, 0x10 * i, gamecode.encode(), int(crc32_str, 16))

        for rom_code in roms_info:
            ar_code_record = make_ar_code_record(rom_code['name'], "",
                                                 get_ar_code_values_from_text(rom_code['code']))
            game_codes[rom_id].append(ar_code_record)

    # Make it Whole
    usrcheat_dat_file = bytearray()
    usrcheat_dat_file += make_ar_file_header()
    usrcheat_dat_file += game_pos_table + bytes(0x10)

    for i, (rom_id, rom_codes) in enumerate(game_codes.items()):
        struct.pack_into('<I', usrcheat_dat_file, 0x100 + i * 0x10 + 8, len(usrcheat_dat_file))
        usrcheat_dat_file += make_ar_game_header(rom_id, n_code=len(rom_codes))
        for rom_code in rom_codes:
            usrcheat_dat_file += rom_code

    return usrcheat_dat_file


def main():
    tmp_folder_path = Path(tmp_folder_name)
    tmp_folder_existed = tmp_folder_path.exists()
    if not tmp_folder_existed:
        tmp_folder_path.mkdir()

    if rom_path:
        include_nub = True
        patch_rom(rom_path, include_nub)
    else:
        generate_action_replay_codes_for_all_rom_versions()

    if not tmp_folder_existed:
        import shutil
        shutil.rmtree(tmp_folder_name)


main()
