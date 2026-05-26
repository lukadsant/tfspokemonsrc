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

#ifndef GAMEPAD_H
#define GAMEPAD_H

class GamepadManager
{
public:
    void init();
    void terminate();
    void poll();

private:
    void releaseInjected();
    void setKeyState(int keyIndex, bool pressed);
    void openFirstController();

    enum KeyIndex {
        KeyIndexUp = 0,
        KeyIndexDown = 1,
        KeyIndexLeft = 2,
        KeyIndexRight = 3,
        KeyIndexCount = 4
    };

    bool m_injected[KeyIndexCount] = { false, false, false, false };

#if defined(FW_GAMEPAD_SDL2)
    struct SDL_GameController;
    SDL_GameController* m_controller = nullptr;
    bool m_initialized = false;
    int m_deadzone = 8000;
#endif
};

extern GamepadManager g_gamepad;

#endif
