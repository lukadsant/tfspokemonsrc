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

#include "gamepad.h"

#include <framework/const.h>
#include <framework/platform/platformwindow.h>
#include <framework/core/logger.h>

#if defined(FW_GAMEPAD_SDL2)
#include <SDL.h>
#endif

GamepadManager g_gamepad;

void GamepadManager::init()
{
#if defined(FW_GAMEPAD_SDL2)
    if(SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) != 0) {
        g_logger.warning(stdext::format("SDL2 gamepad init failed: %s", SDL_GetError()));
        m_initialized = false;
        return;
    }

    m_initialized = true;
    openFirstController();
#endif
}

void GamepadManager::terminate()
{
#if defined(FW_GAMEPAD_SDL2)
    releaseInjected();
    if(m_controller) {
        SDL_GameControllerClose(m_controller);
        m_controller = nullptr;
    }
    if(m_initialized) {
        SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
        m_initialized = false;
    }
#endif
}

void GamepadManager::poll()
{
#if defined(FW_GAMEPAD_SDL2)
    if(!m_initialized)
        return;

    if(m_controller && !SDL_GameControllerGetAttached(m_controller)) {
        releaseInjected();
        SDL_GameControllerClose(m_controller);
        m_controller = nullptr;
    }

    if(!m_controller) {
        openFirstController();
        if(!m_controller)
            return;
    }

    SDL_GameControllerUpdate();

    int axisX = SDL_GameControllerGetAxis(m_controller, SDL_CONTROLLER_AXIS_LEFTX);
    int axisY = SDL_GameControllerGetAxis(m_controller, SDL_CONTROLLER_AXIS_LEFTY);

    bool dpadUp = SDL_GameControllerGetButton(m_controller, SDL_CONTROLLER_BUTTON_DPAD_UP) != 0;
    bool dpadDown = SDL_GameControllerGetButton(m_controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN) != 0;
    bool dpadLeft = SDL_GameControllerGetButton(m_controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT) != 0;
    bool dpadRight = SDL_GameControllerGetButton(m_controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT) != 0;

    bool up = dpadUp || axisY < -m_deadzone;
    bool down = dpadDown || axisY > m_deadzone;
    bool left = dpadLeft || axisX < -m_deadzone;
    bool right = dpadRight || axisX > m_deadzone;

    setKeyState(KeyIndexUp, up);
    setKeyState(KeyIndexDown, down);
    setKeyState(KeyIndexLeft, left);
    setKeyState(KeyIndexRight, right);
#endif
}

void GamepadManager::releaseInjected()
{
    setKeyState(KeyIndexUp, false);
    setKeyState(KeyIndexDown, false);
    setKeyState(KeyIndexLeft, false);
    setKeyState(KeyIndexRight, false);
}

void GamepadManager::setKeyState(int keyIndex, bool pressed)
{
    Fw::Key key = Fw::KeyUnknown;
    switch(keyIndex) {
    case KeyIndexUp:
        key = Fw::KeyUp;
        break;
    case KeyIndexDown:
        key = Fw::KeyDown;
        break;
    case KeyIndexLeft:
        key = Fw::KeyLeft;
        break;
    case KeyIndexRight:
        key = Fw::KeyRight;
        break;
    default:
        return;
    }

    bool injected = m_injected[keyIndex];
    if(pressed) {
        if(!injected && !g_window.isKeyPressed(key)) {
            g_window.injectKeyDown(key);
            m_injected[keyIndex] = true;
        }
        return;
    }

    if(injected) {
        g_window.injectKeyUp(key);
        m_injected[keyIndex] = false;
    }
}

void GamepadManager::openFirstController()
{
#if defined(FW_GAMEPAD_SDL2)
    int count = SDL_NumJoysticks();
    for(int i = 0; i < count; ++i) {
        if(!SDL_IsGameController(i))
            continue;
        SDL_GameController* controller = SDL_GameControllerOpen(i);
        if(controller) {
            m_controller = controller;
            const char* name = SDL_GameControllerName(controller);
            if(name)
                g_logger.info(stdext::format("SDL2 gamepad connected: %s", name));
            return;
        }
    }
#endif
}
