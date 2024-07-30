#define ARM9

#include <stdio.h>

#include "sys/_stdint.h"
#include <nds.h>

#define RTCOM_DATA_OUTPUT 0x0C7FFDF0


void visualizeAccel(u16 gyroX, u16 gyroY, u16 gyroZ) {
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-128, 128, -96, 96, 0.1, 100);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();

    // not a real gl function and will likely change
    glPolyFmt(POLY_ALPHA(31) | POLY_CULL_NONE);

    glPushMatrix();
    glScalef32(128 * 4096, 128 * 4096, 4096);

    *(vu32 *)0x040004A8 = 0;
    // draw the obj
    // glBegin(GL_QUAD);
    //     glColor3b(255, 255, 255);
    //     glVertex3v16(-2048, -2048, inttov16(-3));
    //     glVertex3v16(2048, -2048, inttov16(-3));
    //     glVertex3v16(2048, 2048, inttov16(-3));
    //     glVertex3v16(-2048, 2048, inttov16(-3));
    // glEnd();

    // glBegin(GL_TRIANGLE);
    //     glColor3b(255, 0, 0);
    //     glVertex3v16(0, 0, inttov16(-2));
    //     glVertex3v16(gyroX - 2048, gyroY - 2048, inttov16(-2));
    //     glVertex3v16(0, 0, inttov16(-2));
    // glEnd();
    glPopMatrix(1);


    glPushMatrix();
    glTranslatef32(80 * 4096, 64 << 12, 4096);
    glScalef32(16 * 4096, 128 * 4096, 4096);
    glBegin(GL_QUAD);
        glColor3b(255, 0, 0);
        glVertex3v16(-2048, gyroX - 2048, inttov16(-2));
        glVertex3v16(-2048, -2048, inttov16(-2));
        glVertex3v16(2048, -2048, inttov16(-2));
        glVertex3v16(2048, gyroX - 2048, inttov16(-2));
    glEnd();
    glPopMatrix(1);

    glPushMatrix();
    glTranslatef32(100 * 4096, 64 << 12, 4096);
    glScalef32(16 * 4096, 128 * 4096, 4096);
    glBegin(GL_QUAD);
        glColor3b(0, 255, 0);
        glVertex3v16(-2048, gyroY - 2048, inttov16(-2));
        glVertex3v16(-2048, -2048, inttov16(-2));
        glVertex3v16(2048, -2048, inttov16(-2));
        glVertex3v16(2048, gyroY - 2048, inttov16(-2));
    glEnd();
    glPopMatrix(1);

    glPushMatrix();
    glTranslatef32(120 * 4096, 64 << 12, 4096);
    glScalef32(16 * 4096, 128 * 4096, 4096);
    glBegin(GL_QUAD);
        glColor3b(0, 0, 255);
        glVertex3v16(-2048, gyroZ - 2048, inttov16(-2));
        glVertex3v16(-2048, -2048, inttov16(-2));
        glVertex3v16(2048, -2048, inttov16(-2));
        glVertex3v16(2048, gyroZ - 2048, inttov16(-2));
    glEnd();
    glPopMatrix(1);

    glFlush(0);
}

u8 reverseBits(u8 b) {
    b = (b & 0xF0) >> 4 | (b & 0x0F) << 4;
    b = (b & 0xCC) >> 2 | (b & 0x33) << 2;
    b = (b & 0xAA) >> 1 | (b & 0x55) << 1;
    return b;
}

#define CLAMP(value, low, high) (((value)<(low))?(low):(((value)>(high))?(high):(value)))

int main() {
    consoleDemoInit(); // setup the sub screen for printing

    // set mode 0, enable BG0 and set it to 3D
    videoSetMode(MODE_0_3D);

    // initialize gl
    glInit();

    // setup the rear plane
    glClearColor(0, 0, 0, 31); // BG must be opaque for AA to work
    glClearPolyID(63);         // BG must have a unique polygon ID for AA to work
    glClearDepth(0x7FFF);


    s16 gyroCalibr[3] = {0};

    bool i2c_table_inited = false;

    int accel_offset = 0;
    constexpr int accel_offset_max = 8;
    s32 accel_xs[accel_offset_max], accel_ys[accel_offset_max], accel_zs[accel_offset_max];
    for (int i = 0; i < accel_offset_max; i++)
        accel_xs[i] = accel_ys[i] = accel_zs[i] = 0;

    while (true) {
        glViewport(0, 0, 255, 191);

        u32 cpad = *(vu32 *)RTCOM_DATA_OUTPUT;
        u16 cpadX = (s8)(cpad & 0xFF) << 4;
        u16 cpadY = (s8)((cpad >> 8) & 0xFF) << 4;
        cpadX += 0x800, cpadY += 0x800;
        // visualizeCPad(cpadX, cpadY);
        // iprintf("\x1b[%d;0H\t CPAD: %+05d, %+05d", 2, (cpadX - 0x800) >> 4, (cpadY - 0x800) >> 4);

        scanKeys();
        // if (keysHeld() & KEY_B) {
        //     printf("\x1b[18;0HButton B is down    \n");
        // } else {
        //     printf("\x1b[18;0HButton B is NOT down\n");
        // }



        s16 *accel = (s16 *)(RTCOM_DATA_OUTPUT + 10);
        s16 accel_x = *accel;
        s16 accel_y = *(accel + 1);
        s16 accel_z = *(accel + 2);
        iprintf("\x1b[%d;0H\x1b[2K Press DPad Up to Recalibrate", 1);
        iprintf("\x1b[%d;0H\x1b[2KAccel: %+07d; %+07d; %+07d\n", 4, accel_x - gyroCalibr[0], accel_y - gyroCalibr[1], accel_z - gyroCalibr[2]);

        // s8 small_accel_x = CLAMP((accel_x + 128) >> 8, -128, 127);
        // s8 small_accel_y = CLAMP((accel_y + 128) >> 8, -128, 127);
        // s8 small_accel_z = CLAMP((accel_z + 128) >> 8, -128, 127);
        {
            accel_xs[accel_offset] = CLAMP((accel_x + 128) >> 8, -128, 127);
            accel_ys[accel_offset] = CLAMP((accel_y + 128) >> 8, -128, 127);
            accel_zs[accel_offset] = CLAMP((accel_z + 128) >> 8, -128, 127);
            accel_offset = (accel_offset + 1) % accel_offset_max;

            s32 accel_sums[3] = { 0, 0, 0 };
            for (int i = 0; i < accel_offset_max; i++)
                accel_sums[0] += accel_xs[i], accel_sums[1] += accel_ys[i], accel_sums[2] += accel_zs[i];

            accel_sums[0] = (accel_sums[0] + accel_offset_max/2) / accel_offset_max;
            accel_sums[1] = (accel_sums[1] + accel_offset_max/2) / accel_offset_max;
            accel_sums[2] = (accel_sums[2] + accel_offset_max/2) / accel_offset_max;

            iprintf("\x1b[%d;0H\x1b[2KAcc: %+07d; %+07d; %+07d\n", 6, accel_sums[0], accel_sums[1], accel_sums[2]);
        }

        // s8 small_accel_x = CLAMP((accel_x + 128) >> 8, -128, 127) & 0xFC;
        // s8 small_accel_y = CLAMP((accel_y + 128) >> 8, -128, 127) & 0xFC;
        // s8 small_accel_z = CLAMP((accel_z + 128) >> 8, -128, 127) & 0xFC;
        s8 small_accel_x = CLAMP((accel_x + 128) >> 8, -128, 127);
        s8 small_accel_y = CLAMP((accel_y + 128) >> 8, -128, 127);
        s8 small_accel_z = CLAMP((accel_z + 128) >> 8, -128, 127);
        iprintf("\x1b[%d;0H\x1b[2KAcc: %+07d; %+07d; %+07d\n", 7, small_accel_x, small_accel_y, small_accel_z);

        if (keysHeld() & KEY_UP) {
            gyroCalibr[0] = accel_x;
            gyroCalibr[1] = accel_y;
            gyroCalibr[2] = accel_z;
        }

        visualizeAccel((accel_x - gyroCalibr[0]) / 8, (accel_y - gyroCalibr[1]) / 8, (accel_z - gyroCalibr[2]) / 8);

        auto* rtcom_addr = (vu8*)0x0CFFFE70;

        if (!i2c_table_inited) {
            i2c_table_inited = true;
            for (int i = 0; i < 30; i++) {
                ((vu8*)rtcom_addr + 0x10)[i] = 0;
            }
        }

        // print i2c device table
        iprintf("\x1b[%d;0H\x1b[2K I2C Device Table:\n", 16);
        for (int i = 0; i < 5; i++) {
            vu8* i2c_table = rtcom_addr + 0x10;
            u8 bus1 = *(i2c_table + 0 + 6*i);
            u8 addr1 = *(i2c_table + 1 + 6*i);
            u8 bus2 = *(i2c_table + 2 + 6*i);
            u8 addr2 = *(i2c_table + 3 + 6*i);
            u8 bus3 = *(i2c_table + 4 + 6*i);
            u8 addr3 = *(i2c_table + 5 + 6*i);
            iprintf("\x1b[%d;0H\x1b[2K  %02d) %02X:%02X %02X:%02X %02X:%02X\n", 17 + i, i*3, bus1, addr1, bus2, addr2, bus3, addr3);
        }

        swiWaitForVBlank();
    }

    return 0;
}
