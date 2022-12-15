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

        u32 cpad = *(vu32 *)0x0CFFFE70;
        u16 cpadX = (int8)(cpad & 0xFF) << 4;
        u16 cpadY = (int8)((cpad >> 8) & 0xFF) << 4;
        cpadX += 0x800;
        cpadY += 0x800;

        u32 nub = *(vu32 *)0x0CFFFE74;
        u8 zlzr = nub & 0xFF;
        int8_t nub_x = (nub >> 8) & 0xFF;
        int8_t nub_y = (nub >> 16) & 0xFF;

        // u16 cpadX = cpad & 0xFFF;
        // u16 cpadY = (cpad >> 12) & 0xFFF;

        // vs16* gyro = (vs16*)0x0CFFFE78;
        // u16 cpadX = (~gyro[0] & 0xFFF) ^ 0x800;
        // u16 cpadY = (gyro[1] & 0xFFF) ^ 0x800;

        // vu16* gyrodat = (vu16*)0x0CFFFE78;
        // u16 cpadX = ((gyrodat[2] >> 4) & 0xFFF) ^ 0x800;
        // u16 cpadY = ((gyrodat[0] >> 4) & 0xFFF) ^ 0x800;

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
        swiWaitForVBlank();
        scanKeys();
        if (keysDown() & KEY_B) {
            printf("\x1b[13;0HButton B is down\n");
        } else {
            printf("\x1b[13;0HButton B is NOT down\n");
        }

        // printf("=[%02X]=\n\e[1A\n", *(vu8*)0x0CFFFDFF);
        iprintf("\x1b[%d;0H \x1b[2K \tCPAD: %04X, %04X", 2, cpadX, cpadY);
        iprintf("\x1b[%d;0H \x1b[2K \tZL&ZR: %08X", 4, zlzr);
        iprintf("\x1b[%d;0H \x1b[2K \tNub: {X: %+04d; Y: %+04d}\n", 5, nub_x, nub_y);
        // printf("CPAD: %04X, %04X\n\e[1A\n", cpadX - 0x800, cpadY - 0x800);
    }

    return 0;
}
