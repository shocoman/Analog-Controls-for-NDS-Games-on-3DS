#define ARM9

#include <stdio.h>

#include "sys/_stdint.h"
#include <nds.h>

#define RTCOM_DATA_OUTPUT 0x0C7FFDF0

void visualizeCPad(u16 cpadX, u16 cpadY) {
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
    glBegin(GL_QUAD);
    glColor3b(255, 255, 255);
    glVertex3v16(-2048, -2048, inttov16(-3));
    glVertex3v16(2048, -2048, inttov16(-3));
    glVertex3v16(2048, 2048, inttov16(-3));
    glVertex3v16(-2048, 2048, inttov16(-3));
    glEnd();

    glBegin(GL_TRIANGLE);
    glColor3b(255, 0, 0);
    glVertex3v16(0, 0, inttov16(-2));
    glVertex3v16(cpadX - 2048, cpadY - 2048, inttov16(-2));
    glVertex3v16(0, 0, inttov16(-2));

    glEnd();

    glPopMatrix(1);
    glPushMatrix();
    glTranslatef32(0, -80 * 4096, 4096);
    glScalef32(128 * 4096, 16 * 4096, 4096);

    glBegin(GL_QUAD);
    glColor3b(255, 0, 0);
    glVertex3v16(-2048, 2048, inttov16(-2));
    glVertex3v16(-2048, -2048, inttov16(-2));
    glVertex3v16(cpadX - 2048, -2048, inttov16(-2));
    glVertex3v16(cpadX - 2048, 2048, inttov16(-2));
    glEnd();

    glPopMatrix(1);
    glPushMatrix();
    glTranslatef32(100 * 4096, 0, 4096);
    glScalef32(16 * 4096, 128 * 4096, 4096);

    glBegin(GL_QUAD);
    glColor3b(255, 0, 0);
    glVertex3v16(-2048, cpadY - 2048, inttov16(-2));
    glVertex3v16(-2048, -2048, inttov16(-2));
    glVertex3v16(2048, -2048, inttov16(-2));
    glVertex3v16(2048, cpadY - 2048, inttov16(-2));
    glEnd();

    glPopMatrix(1);
    glFlush(0);
}

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

    while (true) {
        glViewport(0, 0, 255, 191);

        u32 cpad = *(vu32 *)RTCOM_DATA_OUTPUT;
        u16 cpadX = (s8)(cpad & 0xFF) << 4;
        u16 cpadY = (s8)((cpad >> 8) & 0xFF) << 4;
        cpadX += 0x800, cpadY += 0x800;
        visualizeCPad(cpadX, cpadY);
        iprintf("\x1b[%d;0H\t CPAD: %+05d, %+05d", 2, (cpadX - 0x800) >> 4, (cpadY - 0x800) >> 4);

        scanKeys();
        if (keysHeld() & KEY_B) {
            printf("\x1b[13;0HButton B is down    \n");
        } else {
            printf("\x1b[13;0HButton B is NOT down\n");
        }

        u32 nub = *(vu32 *)(RTCOM_DATA_OUTPUT + 4);
        u8 zlzr = nub & 0xFF;
        s8 nub_x = (nub >> 8) & 0xFF;
        s8 nub_y = (nub >> 16) & 0xFF;
        iprintf("\x1b[%d;0H\t ZL&ZR: %08X", 4, zlzr);
        iprintf("\x1b[%d;0H \x1b[2K \tRawNub: {X: %+04d; Y: %+04d} \n ", 5, nub_x, nub_y);

        // rotate Nub 45 degrees
        // new_x = x * cos - y * sin = x * sin - y * sin = sin*(x-y)
        // new_y = x * sin + y * cos = x * sin + y * sin = sin*(x+y)
        s32 sin_45 = 0xB50;
        s32 rot_nub_x = (sin_45 * (nub_x - nub_y) + 0x800) >> 12;
        s32 rot_nub_y = (sin_45 * (nub_x + nub_y) + 0x800) >> 12;
        iprintf("\x1b[%d;0H \x1b[2K \tRotatedNub: {%+04d; %+04d}\n", 6, rot_nub_x, rot_nub_y);

        vu16 *gyro = (vu16 *)(RTCOM_DATA_OUTPUT + 8);
        s16 gyro_x = *gyro;
        s16 gyro_y = *(gyro + 1);
        s16 gyro_z = *(gyro + 2);
        iprintf("\x1b[%d;0H\x1b[2K Gyro: %+07d; %+07d; %+07d\n", 8, gyro_x, gyro_y, gyro_z);
        iprintf("\x1b[%d;0H\x1b[2K RawGyro: %04x; %04x; %04x\n", 9, (u16)gyro_x, (u16)gyro_y,
                (u16)gyro_z);

        u8 *date_time = (u8 *)(RTCOM_DATA_OUTPUT - 8);
        u8 year = date_time[0], month = date_time[1], day = date_time[2];
        u8 dow = date_time[3];
        u8 hour = date_time[4], minute = date_time[5], second = date_time[6];
        iprintf("\x1b[%d;0H\x1b[2K Date: %02x; %02x; %02x; %02x\n", 11, year, month, day, dow);
        iprintf("\x1b[%d;0H\x1b[2K Time: %02x; %02x; %02x\n", 12, hour, minute, second);

        swiWaitForVBlank();
    }

    return 0;
}
