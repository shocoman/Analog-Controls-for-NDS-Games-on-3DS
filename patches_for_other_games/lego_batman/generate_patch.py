#!/bin/python
from pathlib import Path
import subprocess
import re
import struct
from collections import defaultdict, namedtuple


tmp_folder_name = "tmp_ndstools"
arm7_update_rtcom_function_name = "Update_RTCom"

asm_exe_path = "arm-none-eabi-as"
objcopy_exe_path = "arm-none-eabi-objcopy"
objdump_exe_path = "arm-none-eabi-objdump"
ld_exe_path = "arm-none-eabi-ld"
make_exe_path = "make"


RomInfo = namedtuple(
    'RomInfo',
    'arm7_ipc_send_msg, arm7_set_ipc_channel_handler, arm7_rtc_region_start, arm7_vblank_irq_end_address, arm7_rtc_init_function_call, arm9_controls_hook_insertion_point, arm9_code_position, arm9_div_function, description')
roms_info = {
    "YJBP-02C7401B": RomInfo(0x037FE3DC, 0x037FE368, 0x027F5CA0, 0x037F84D8, 0x037F8414, 0x0203C064, 0x02000AB0, 0x0210DC70, "Europe v1.0"),
    "YJBJ-F3B6CC7E": RomInfo(0x037FE3DC, 0x037FE368, 0x027F5CA0, 0x037F84D8, 0x037F8414, 0x0203C048, 0x02000AB0, 0x0210DBB8, "Japan v1.0"),
    "YJBE-BF1B2F19": RomInfo(0x037FE3DC, 0x037FE368, 0x027F5CA0, 0x037F84D8, 0x037F8414, 0x0203C04C, 0x02000AB0, 0x0210DCDC, "USA v1.0"),
}


def find_function_offset_in_asm_listing(asm_code, func_name):
    asm_func_regexp = r"([a-f0-9]{8}) .+" + func_name + "[^-+].+"
    regexp_func = re.search(asm_func_regexp, asm_code, re.IGNORECASE)
    if regexp_func:
        addr = int(regexp_func.group(1), 16)
    else:
        raise Exception(f"Can't find the function '{func_name}' in the output file")
    return addr


def assemble_arm7_rtcom_patch(rom_signature):
    rom_info = roms_info[rom_signature]
    arm7_patch_dir = 'arm7_rtcom_patch'

    # Assemble the TwlBg runtime patch binary
    twlbg_patch_folder = f"{arm7_patch_dir}/arm11_ucode/arm11_twlbg_patch"
    patch_asm_input_file = "arm11_twlbg_patch.s"

    subprocess.check_output([asm_exe_path, patch_asm_input_file, "-o", "arm11_twlbg_patch.out"], cwd=twlbg_patch_folder)
    subprocess.check_output([objcopy_exe_path, "-Obinary", "arm11_twlbg_patch.out", "TWLBG_PATCH.bin"],
                            cwd=twlbg_patch_folder)

    # generate a header file based on the runtime TwlBg patch's binary
    code_binary = open(f"{twlbg_patch_folder}/TWLBG_PATCH.bin", 'rb').read()
    with open(f"{twlbg_patch_folder}/twl_bg_patch_bytes.h", "w") as twl_bg_header_file:
        twl_bg_header = f"// The file was automatically generated by a python script from '{patch_asm_input_file}'\n"
        twl_bg_header += "#pragma once\n"
        twl_bg_header += "unsigned char twlbg_patch_code[] = {"
        for i, b in enumerate(code_binary):
            if i % 10 == 0:
                twl_bg_header += "\n"
            twl_bg_header += f"0x{b:02X}, "
        twl_bg_header = twl_bg_header.strip(", ")
        twl_bg_header += "};\n "
        twl_bg_header_file.write(twl_bg_header)

    # Build the whole Arm7 + Arm11 part
    subprocess.check_output([make_exe_path, 'clean', '--directory', arm7_patch_dir])

    arm7_defines_for_compiler = [("ARM7_IPC_SEND_MSG", rom_info.arm7_ipc_send_msg),
                                 ("ARM7_IPC_CHANNEL_HANDLER", rom_info.arm7_set_ipc_channel_handler)]
    defines = "EXTERNAL_DEFINES=" + " ".join([f"-D{name}=0x{value:08X}" for name, value in arm7_defines_for_compiler])
    try:
        subprocess.check_output([make_exe_path, defines, '--directory', arm7_patch_dir],
                                stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as e:
        print(e.output.decode('utf-8'))
        exit(-1)

    try:
        subprocess.check_output([ld_exe_path, 'rtcom.o', f'{arm7_patch_dir}.uc11.o', '--output', 'arm7_patch.o',
                                 '--section-start', f'.text={hex(rom_info.arm7_rtc_region_start)}'],
                                cwd=f'{arm7_patch_dir}/arm7/build/')
    except subprocess.CalledProcessError as e:
        print(e.output.decode('utf-8'))
        exit(-1)

    subprocess.check_output(
        [objcopy_exe_path, '-O', 'binary', '--only-section=.rodata', '--only-section=.text', 'arm7_patch.o',
         'arm7_patch.bin'],
        cwd=f'{arm7_patch_dir}/arm7/build/')
    arm7_patch_bytes = open(f'{arm7_patch_dir}/arm7/build/arm7_patch.bin', 'rb').read()

    rtcom_asm_code = subprocess.check_output([objdump_exe_path, '-d', 'rtcom.o'],
                                             cwd=f'{arm7_patch_dir}/arm7/build/', text=True)
    update_rtcom_func_offset = find_function_offset_in_asm_listing(rtcom_asm_code, arm7_update_rtcom_function_name)

    return update_rtcom_func_offset, arm7_patch_bytes


def assemble_arm9_patch(rom_signature, asm_filename):
    rom_info = roms_info[rom_signature]

    arm9_defines_for_assembler = [("DIV_FUNC", rom_info.arm9_div_function)]
    asm_defines = sum([["--defsym", f"{name}=0x{value:08X}"] for name, value in arm9_defines_for_assembler], [])

    patch_name = asm_filename.upper().split('/')[-1].split('.')[0]
    subprocess.check_output([asm_exe_path, asm_filename, '-o', f'{tmp_folder_name}/{patch_name}.out', *asm_defines])
    subprocess.check_output([objcopy_exe_path, '-Obinary',
                            f'{tmp_folder_name}/{patch_name}.out', f'{tmp_folder_name}/{patch_name}.bin'])

    asm_code = subprocess.check_output([objdump_exe_path, '-d', f'{tmp_folder_name}/{patch_name}.out'], text=True)

    return bytearray(open(f"{tmp_folder_name}/{patch_name}.bin", 'rb').read()), asm_code


def generate_action_replay_code(rom_signature):
    def ar_code__bulk_write(bin: bytearray, address: int):
        if len(bin) % 8 != 0:
            bin += b'\x00' * (8 - len(bin) % 8)
        ar_code = f"E{address:07X} {len(bin):08X}\n"
        for words in struct.iter_unpack("<II", bin):
            ar_code += f"{words[0]:08X} {words[1]:08X}\n"
        return ar_code

    def instr__arm_b(from_addr, target, link=False, exchange=False):
        offset = target - (from_addr + 8)
        if exchange:  # blx
            instr_type = 0xFA000000 if (offset & 0x2) == 0 else 0xFB000000
            return instr_type | ((offset >> 2) & 0xFFFFFF)
        else:
            instr_type = 0xEB000000 if link else 0xEA000000
            return instr_type | ((offset >> 2) & 0xFFFFFF)

    def instr__thumb_bl(src, target, exchange_instruction_set=False):
        base = (src + 4)
        bits_to_exchange = 0b11
        if exchange_instruction_set:
            target = (target & ~0x2) | (base & 0x2)
            bits_to_exchange = 0b01
        offset = target - base
        branch_instr_1 = 0xF000 | ((offset >> 12) & 0x7FF)
        branch_instr_2 = 0xE800 | ((offset >> 1) & 0x7FF) | (bits_to_exchange << 11)
        return branch_instr_1, branch_instr_2

    rom_info = roms_info[rom_signature]
    ar_code = ""

    ####################################################################################
    # Arm7 Patch
    arm7_code_start_address = rom_info.arm7_rtc_region_start
    vblank_handler_end = rom_info.arm7_vblank_irq_end_address
    update_rtcom_func_offset, arm7_patch_bytes = assemble_arm7_rtcom_patch(rom_signature)
    branch_to_rtcom_update_instruction = instr__arm_b(vblank_handler_end,
                                                      arm7_code_start_address + update_rtcom_func_offset)

    ar_code += f"""
        # wait until the arm7's code has been fully uploaded
        5{vblank_handler_end:07X} {0xe12fff1e:08X}  # if equal to "bx lr"

            0{rom_info.arm7_rtc_init_function_call:07X} 00000000                # prevent call to init the RTC on Arm7
            {ar_code__bulk_write(arm7_patch_bytes, arm7_code_start_address)}    # write the Arm7 + Arm11 code

            0{vblank_handler_end:07X} {branch_to_rtcom_update_instruction:08X}  # Hook the VBlank IRQ Handler
        D0000000 00000000
    """

    ####################################################################################
    # Arm9 patch
    arm9_start_address = rom_info.arm9_code_position
    code_binary, code_asm_text = assemble_arm9_patch(rom_signature, "arm9_controls_hook.s")

    # Player Movement
    player_move_hook_addr = rom_info.arm9_controls_hook_insertion_point
    player_move_orig_instr = 0xe7d01005
    player_move_branch_instr = instr__arm_b(player_move_hook_addr, arm9_start_address, True)

    ar_code += f"""
        # wait for some time, just to be sure (0x27FFC3C is a frame counter)
        427FFC3C 00000200
            # check if we can hook the "player movement"
            5{player_move_hook_addr:07X} {player_move_orig_instr:08X}
                {ar_code__bulk_write(code_binary, arm9_start_address)} # main patch
                0{player_move_hook_addr:07X} {player_move_branch_instr:08X}
        D2000000 00000000
    """

    formatted_cheatcode = ""
    for line in ar_code.splitlines():
        mb_nonempty_line = line.split('#')[0].strip()
        if len(mb_nonempty_line) > 0:
            formatted_cheatcode += mb_nonempty_line + '\n'

    return formatted_cheatcode


def generate_action_replay_codes_for_all_rom_versions():
    ac_folder_name = "action_replay_codes"
    Path(ac_folder_name).mkdir(exist_ok=True)

    cheat_codes = defaultdict(list)
    for rom_id, info in roms_info.items():
        filename = f"{rom_id} ({info.description})"

        code_text = generate_action_replay_code(rom_id)
        with open(f"{ac_folder_name}/{filename}.txt", "w") as f:
            f.write(code_text)

        cheat_codes[rom_id].append({'code': code_text, 'name': "CPad Patch"})

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

        header_attributes = ar_code_size_with_header // 4
        header_attributes |= 0x01000000  # enable the cheatcode by default
        ar_code_header = struct.pack("<I", header_attributes) + ar_code_header

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

    generate_action_replay_codes_for_all_rom_versions()

    if not tmp_folder_existed:
        import shutil
        shutil.rmtree(tmp_folder_name)


main()
