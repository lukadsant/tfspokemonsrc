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

#include "joystickmanager.h"
#include <framework/core/application.h>
#include <framework/core/graphicalapplication.h>
#include <framework/platform/platformwindow.h>
#include <framework/luaengine/luainterface.h>

#ifdef WITH_JOYSTICK
#include <SDL2/SDL.h>

static std::vector<SDL_GameController*> s_controllers;
#endif

JoystickManager g_joysticks;

JoystickManager::JoystickManager()
{
    m_initialized = false;
    m_lastDirX = 0;
    m_lastDirY = 0;
    m_holdingX = false;
    m_holdingY = false;
    m_heldDirX = -1;
    m_heldDirY = -1;
    m_mouseActive = false;
    m_virtualMouseX = 0;
    m_virtualMouseY = 0;
    m_buttonA = false;
    m_buttonR3 = false;
    m_buttonX = false;
    m_buttonY = false;
    m_buttonB = false;
    m_buttonLB = false;
    m_buttonLT = false;
    m_buttonRT = false;
    m_buttonSelect = false;
    m_dpadUp = false;
    m_dpadDown = false;
    m_dpadLeft = false;
    m_dpadRight = false;
}

void JoystickManager::init()
{
#ifdef WITH_JOYSTICK
    if (SDL_InitSubSystem(SDL_INIT_GAMECONTROLLER) < 0) {
        g_logger.error(stdext::format("Unable to initialize SDL GameController: %s", SDL_GetError()));
        return;
    }

    m_initialized = true;

    // Open all connected controllers
    for (int i = 0; i < SDL_NumJoysticks(); ++i) {
        if (SDL_IsGameController(i)) {
            SDL_GameController* controller = SDL_GameControllerOpen(i);
            if (controller) {
                s_controllers.push_back(controller);
                g_logger.info(stdext::format("Connected joystick: %s", SDL_GameControllerName(controller)));
            }
        }
    }

    if (s_controllers.empty()) {
        g_logger.info("No joysticks/gamepads detected.");
    }
#endif
}

void JoystickManager::terminate()
{
#ifdef WITH_JOYSTICK
    for (auto controller : s_controllers) {
        SDL_GameControllerClose(controller);
    }
    s_controllers.clear();

    if (m_initialized) {
        SDL_QuitSubSystem(SDL_INIT_GAMECONTROLLER);
        m_initialized = false;
    }
#endif
}

void JoystickManager::poll()
{
#ifdef WITH_JOYSTICK
    if (!m_initialized) return;

    SDL_PumpEvents();

    for (auto controller : s_controllers) {
        if (!SDL_GameControllerGetAttached(controller)) continue;

        // === LEFT STICK: Movement (analog only) ===
        int axisX = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTX);
        int axisY = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_LEFTY);

        int currentDirX = 0;
        int currentDirY = 0;

        if (axisX < -JOYSTICK_DEADZONE) currentDirX = -1;
        else if (axisX > JOYSTICK_DEADZONE) currentDirX = 1;

        if (axisY < -JOYSTICK_DEADZONE) currentDirY = -1;
        else if (axisY > JOYSTICK_DEADZONE) currentDirY = 1;

        // === D-PAD: Pokemon bar control (separate from movement) ===
        bool dpadUp = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_UP);
        bool dpadDown = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_DOWN);
        bool dpadLeft = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_LEFT);
        bool dpadRight = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_DPAD_RIGHT);
        bool currentLB = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER);

        // Fire D-pad events on press (not repeat)
        // direction: 0=up, 1=right, 2=down, 3=left
        if (dpadLeft && !m_dpadLeft) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickDpad", 3, currentLB);
            g_app.setOnInputEvent(false);
        }
        if (dpadRight && !m_dpadRight) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickDpad", 1, currentLB);
            g_app.setOnInputEvent(false);
        }
        if (dpadUp && !m_dpadUp) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickDpad", 0, currentLB);
            g_app.setOnInputEvent(false);
        }
        if (dpadDown && !m_dpadDown) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickDpad", 2, currentLB);
            g_app.setOnInputEvent(false);
        }
        m_dpadUp = dpadUp;
        m_dpadDown = dpadDown;
        m_dpadLeft = dpadLeft;
        m_dpadRight = dpadRight;

        // X axis walking
        if (currentDirX != 0) {
            int dir = (currentDirX < 0) ? 3 : 1;
            if (!m_holdingX || dir != m_heldDirX) {
                g_app.setOnInputEvent(true);
                g_lua.callGlobalField("g_joysticks", "onJoystickDir", dir);
                g_app.setOnInputEvent(false);
                m_walkTimerX.restart();
                m_holdingX = true;
                m_heldDirX = dir;
            } else if (m_holdingX && m_walkTimerX.ticksElapsed() >= WALK_REPEAT_INTERVAL) {
                g_app.setOnInputEvent(true);
                g_lua.callGlobalField("g_joysticks", "onJoystickDir", dir);
                g_app.setOnInputEvent(false);
                m_walkTimerX.restart();
            }
        } else {
            m_holdingX = false;
            m_heldDirX = -1;
        }

        // Y axis walking
        if (currentDirY != 0) {
            int dir = (currentDirY < 0) ? 0 : 2;
            if (!m_holdingY || dir != m_heldDirY) {
                g_app.setOnInputEvent(true);
                g_lua.callGlobalField("g_joysticks", "onJoystickDir", dir);
                g_app.setOnInputEvent(false);
                m_walkTimerY.restart();
                m_holdingY = true;
                m_heldDirY = dir;
            } else if (m_holdingY && m_walkTimerY.ticksElapsed() >= WALK_REPEAT_INTERVAL) {
                g_app.setOnInputEvent(true);
                g_lua.callGlobalField("g_joysticks", "onJoystickDir", dir);
                g_app.setOnInputEvent(false);
                m_walkTimerY.restart();
            }
        } else {
            m_holdingY = false;
            m_heldDirY = -1;
        }

        m_lastDirX = currentDirX;
        m_lastDirY = currentDirY;

        // === RIGHT STICK: Mouse cursor control ===
        int rAxisX = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTX);
        int rAxisY = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_RIGHTY);

        bool rightStickActive = (rAxisX > JOYSTICK_DEADZONE || rAxisX < -JOYSTICK_DEADZONE ||
                                 rAxisY > JOYSTICK_DEADZONE || rAxisY < -JOYSTICK_DEADZONE);

        if (rightStickActive) {
            // On first activation, sync virtual position with current mouse position
            if (!m_mouseActive) {
                Point mousePos = g_window.getMousePosition();
                m_virtualMouseX = mousePos.x;
                m_virtualMouseY = mousePos.y;
                m_mouseActive = true;
            }

            // Map stick value to cursor speed
            float speedX = 0, speedY = 0;

            if (rAxisX > JOYSTICK_DEADZONE)
                speedX = (float)(rAxisX - JOYSTICK_DEADZONE) / (32767 - JOYSTICK_DEADZONE) * MOUSE_MAX_SPEED;
            else if (rAxisX < -JOYSTICK_DEADZONE)
                speedX = (float)(rAxisX + JOYSTICK_DEADZONE) / (32767 - JOYSTICK_DEADZONE) * MOUSE_MAX_SPEED;

            if (rAxisY > JOYSTICK_DEADZONE)
                speedY = (float)(rAxisY - JOYSTICK_DEADZONE) / (32767 - JOYSTICK_DEADZONE) * MOUSE_MAX_SPEED;
            else if (rAxisY < -JOYSTICK_DEADZONE)
                speedY = (float)(rAxisY + JOYSTICK_DEADZONE) / (32767 - JOYSTICK_DEADZONE) * MOUSE_MAX_SPEED;

            m_virtualMouseX += (int)speedX;
            m_virtualMouseY += (int)speedY;

            // Clamp to window bounds
            Size windowSize = g_window.getSize();
            if (m_virtualMouseX < 0) m_virtualMouseX = 0;
            if (m_virtualMouseY < 0) m_virtualMouseY = 0;
            if (m_virtualMouseX >= windowSize.width()) m_virtualMouseX = windowSize.width() - 1;
            if (m_virtualMouseY >= windowSize.height()) m_virtualMouseY = windowSize.height() - 1;

            g_window.warpMouse(Point(m_virtualMouseX, m_virtualMouseY));

            // Notify Lua to draw custom cursor
            g_lua.callGlobalField("g_joysticks", "onJoystickMouse", m_virtualMouseX, m_virtualMouseY, true);
        } else {
            if (m_mouseActive) {
                // Notify Lua to hide custom cursor
                g_lua.callGlobalField("g_joysticks", "onJoystickMouse", 0, 0, false);
            }
            m_mouseActive = false;
        }

        // === BUTTONS: Mouse click simulation ===
        Point clickPos = m_mouseActive ? Point(m_virtualMouseX, m_virtualMouseY) : g_window.getMousePosition();

        // A button (Xbox) / X button (PS) = Left mouse click
        bool currentA = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_A);
        if (currentA && !m_buttonA) {
            // Press
            g_app.setOnInputEvent(true);
            g_window.simulateMouseButton(clickPos, 1, true);  // 1 = MouseLeftButton
            g_app.setOnInputEvent(false);
        } else if (!currentA && m_buttonA) {
            // Release
            g_app.setOnInputEvent(true);
            g_window.simulateMouseButton(clickPos, 1, false);
            g_app.setOnInputEvent(false);
        }
        m_buttonA = currentA;

        // R3 (right stick press) = Right mouse click
        bool currentR3 = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_RIGHTSTICK);
        if (currentR3 && !m_buttonR3) {
            // Press
            g_app.setOnInputEvent(true);
            g_window.simulateMouseButton(clickPos, 2, true);  // 2 = MouseRightButton
            g_app.setOnInputEvent(false);
        } else if (!currentR3 && m_buttonR3) {
            // Release
            g_app.setOnInputEvent(true);
            g_window.simulateMouseButton(clickPos, 2, false);
            g_app.setOnInputEvent(false);
        }
        m_buttonR3 = currentR3;

        // === SPELL BUTTONS: X, Y, B with LB modifier ===
        currentLB = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_LEFTSHOULDER);

        // X button (Xbox) / □ (PS) = m1 or m4 with LB
        bool currentX = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_X);
        if (currentX && !m_buttonX) {
            int moveId = currentLB ? 4 : 1;
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickButton", moveId);
            g_app.setOnInputEvent(false);
        }
        m_buttonX = currentX;

        // Y button (Xbox) / △ (PS) = m2 or m5 with LB
        bool currentY = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_Y);
        if (currentY && !m_buttonY) {
            int moveId = currentLB ? 5 : 2;
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickButton", moveId);
            g_app.setOnInputEvent(false);
        }
        m_buttonY = currentY;

        // B button (Xbox) / ○ (PS) = m3 or m6 with LB
        bool currentB = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_B);
        if (currentB && !m_buttonB) {
            int moveId = currentLB ? 6 : 3;
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickButton", moveId);
            g_app.setOnInputEvent(false);
        }
        m_buttonB = currentB;

        m_buttonLB = currentLB;

        // === LT/L2 TRIGGER: Target cycling ===
        // Triggers are analog axes (0 to 32767), treat as button with threshold
        int ltAxis = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_TRIGGERLEFT);
        bool currentLT = (ltAxis > 16000);  // ~50% threshold
        if (currentLT && !m_buttonLT) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickTargetCycle");
            g_app.setOnInputEvent(false);
        }
        m_buttonLT = currentLT;

        // === RT/R2 TRIGGER: Pokeball capture ===
        int rtAxis = SDL_GameControllerGetAxis(controller, SDL_CONTROLLER_AXIS_TRIGGERRIGHT);
        bool currentRT = (rtAxis > 16000);  // ~50% threshold
        if (currentRT && !m_buttonRT) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickCapture");
            g_app.setOnInputEvent(false);
        }
        m_buttonRT = currentRT;

        // === BACK/SELECT BUTTON: Toggle Bar Mode ===
        bool currentSelect = SDL_GameControllerGetButton(controller, SDL_CONTROLLER_BUTTON_BACK);
        if (currentSelect && !m_buttonSelect) {
            g_app.setOnInputEvent(true);
            g_lua.callGlobalField("g_joysticks", "onJoystickSelect");
            g_app.setOnInputEvent(false);
        }
        m_buttonSelect = currentSelect;

        // Only process first controller
        break;
    }
#endif
}
