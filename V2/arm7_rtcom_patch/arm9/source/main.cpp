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
        visualizeCPad(cpadX + 0x800, cpadY + 0x800);
        iprintf("\x1b[2;0H\t CPAD: %+05d, %+05d", cpadX >> 4, cpadY >> 4);

        scanKeys();
        if (keysHeld() & KEY_B) {
            printf("\x1b[13;0HButton B is down    \n");
        } else {
            printf("\x1b[13;0HButton B is NOT down\n");
        }

        u32 nub_data = *(vu32 *)(RTCOM_DATA_OUTPUT + 4);
        u8 zlzr = nub_data & 0xFF;
        s8 nub_x = (nub_data >> 8) & 0xFF;
        s8 nub_y = (nub_data >> 16) & 0xFF;
        iprintf("\x1b[4;0H\t ZL&ZR: %08X", zlzr);
        iprintf("\x1b[5;0H\t \x1b[2K Nub: {X: %+04d; Y: %+04d} \n ", nub_x, nub_y);

        swiWaitForVBlank();
    }

    return 0;
}
