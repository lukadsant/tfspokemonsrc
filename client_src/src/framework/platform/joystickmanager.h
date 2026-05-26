/*
 * Copyright (c) 2010-2017 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#ifndef JOYSTICKMANAGER_H
#define JOYSTICKMANAGER_H

#include <framework/global.h>
#include <framework/core/timer.h>

//@bindsingleton g_joysticks
class JoystickManager
{
    enum {
        JOYSTICK_DEADZONE = 10000,
        WALK_REPEAT_INTERVAL = 150,  // ms between repeated walk events while holding
        MOUSE_MAX_SPEED = 12         // max pixels per frame for right stick cursor
    };

public:
    JoystickManager();

    void init();
    void terminate();
    void poll();

    bool isInitialized() { return m_initialized; }

private:
    bool m_initialized;
    
    int m_lastDirX;
    int m_lastDirY;
    
    // Timers for continuous walking while held
    Timer m_walkTimerX;
    Timer m_walkTimerY;
    bool m_holdingX;
    bool m_holdingY;
    int m_heldDirX;   // last fired direction for X axis
    int m_heldDirY;   // last fired direction for Y axis

    // Virtual mouse position for right stick control
    bool m_mouseActive;    // right stick is currently controlling the cursor
    int m_virtualMouseX;
    int m_virtualMouseY;

    // Button states for mouse click simulation
    bool m_buttonA;        // A (Xbox) / X (PS) = Left click
    bool m_buttonR3;       // R3 (right stick press) = Right click

    // Button states for spell/attack mapping
    bool m_buttonX;        // X (Xbox) / □ (PS)
    bool m_buttonY;        // Y (Xbox) / △ (PS)
    bool m_buttonB;        // B (Xbox) / ○ (PS)
    bool m_buttonLB;       // LB (Xbox) / L1 (PS)
    bool m_buttonLT;       // LT (Xbox) / L2 (PS) - target cycling
    bool m_buttonRT;       // RT (Xbox) / R2 (PS) - pokeball capture
    bool m_buttonSelect;   // Back/Select button - toggle pokeball bar mode

    // D-pad states for Pokemon bar
    bool m_dpadUp;
    bool m_dpadDown;
    bool m_dpadLeft;
    bool m_dpadRight;
};

extern JoystickManager g_joysticks;

#endif
