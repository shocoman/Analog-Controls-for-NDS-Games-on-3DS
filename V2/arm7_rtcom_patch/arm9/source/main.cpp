#include "sys/_stdint.h"
#include <nds.h>
#include <stdio.h>

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

        u32 cpad = *(vu32 *)0x0C7FFDE8;
        u16 cpadX = (int8)(cpad & 0xFF) << 4;
        u16 cpadY = (int8)((cpad >> 8) & 0xFF) << 4;
        cpadX += 0x800;
        cpadY += 0x800;

        u32 nub = *(vu32 *)0x0C7FFDEC;
        u8 zlzr = nub & 0xFF;
        int8_t nub_x = (nub >> 8) & 0xFF;
        int8_t nub_y = (nub >> 16) & 0xFF;

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

        scanKeys();
        if (keysHeld() & KEY_B) {
            printf("\x1b[13;0HButton B is down    \n");
        } else {
            printf("\x1b[13;0HButton B is NOT down\n");
        }

        iprintf("\x1b[%d;0H\t CPAD: %+05d, %+05d", 2, (cpadX - 0x800) >> 4, (cpadY - 0x800) >> 4);
        iprintf("\x1b[%d;0H\t ZL&ZR: %08X", 4, zlzr);
        iprintf("\x1b[%d;0H \x1b[2K \tNub: {X: %+04d; Y: %+04d}\n", 5, nub_x, nub_y);

        int8 rotated_x = (nub_x + nub_y);
        int8 rotated_y = (nub_y - nub_x);
        iprintf("\x1b[%d;0H \x1b[2K \tNub: {X: %+04d; Y: %+04d}\n", 7, rotated_x, rotated_y); // rotate 135 degrees

        swiWaitForVBlank();
    }

    return 0;
}
