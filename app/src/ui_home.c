/* Tezos Ledger application - Home screen display

   Copyright 2023 Nomadic Labs <contact@nomadic-labs.com>

   With code excerpts from:
    - Legacy Tezos app, Copyright 2019 Obsidian Systems
    - Ledger Blue sample apps, Copyright 2016 Ledger

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License. */

#include "globals.h"

static enum {
  SCREEN_CLEAR_SIGN,
  SCREEN_QUIT,
  SCREEN_BLIND_SIGN,
  SCREEN_SETTINGS,
} screen;

static void redisplay();

static unsigned int cb(unsigned int button_mask, __attribute__((unused)) unsigned int button_mask_counter) {
  if (button_mask == (BUTTON_EVT_RELEASED | BUTTON_LEFT) && screen > SCREEN_CLEAR_SIGN) {
    screen--;
    redisplay ();
  }
  if (button_mask == (BUTTON_EVT_RELEASED | BUTTON_RIGHT) && screen < SCREEN_QUIT) {
    screen++;
    redisplay ();
  }
  if (button_mask == (BUTTON_EVT_RELEASED | BUTTON_LEFT | BUTTON_RIGHT) && screen == 1) {
    exit_app();
  }
  return 0;
}

static void redisplay() {
  bagl_element_t init[4 + TZ_SCREEN_LINES_11PX] = {
    // { {type, userid, x, y, width, height, stroke, radius, fill, fgcolor, bgcolor, font_id, icon_id}, text/icon
#ifdef TARGET_NANOS
    {{ BAGL_RECTANGLE, 0x00, 0, 0, 128, BAGL_HEIGHT, 0, 0, BAGL_FILL, 0x000000, 0xFFFFFF, 0, 0 }, NULL },
    {{ BAGL_ICON, 0x00, 3, 1, 4, 7, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
    {{ BAGL_ICON, 0x00, 122, 1, 4, 7, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
    {{ BAGL_LABELINE, 0x02, 7, 8, 114, 11, 0, 0, 0, 0xFFFFFF, 0x000000, BOLD, 0 }, global.ux.lines[0] },
    {{ BAGL_LABELINE, 0x02, 0, 19, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[1] },
    {{ BAGL_LABELINE, 0x02, 0, 30, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[2] },
    {{ BAGL_ICON, 0x00, 56, 14, 16, 16, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
#define LINE_1 1
#define LINE_2 2
#else
    {{ BAGL_RECTANGLE, 0x00, 0, 0, 128, BAGL_HEIGHT, 0, 0, BAGL_FILL, 0x000000, 0xFFFFFF, 0, 0 }, NULL },
    {{ BAGL_ICON, 0x00, 3, 1, 4, 7, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
    {{ BAGL_ICON, 0x00, 122, 1, 4, 7, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
    {{ BAGL_LABELINE, 0x02, 7, 8, 114, 11, 0, 0, 0, 0xFFFFFF, 0x000000, BOLD, 0 }, global.ux.lines[0] },
    {{ BAGL_LABELINE, 0x02, 0, 21, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[1] },
    {{ BAGL_LABELINE, 0x02, 0, 34, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[2] },
    {{ BAGL_LABELINE, 0x02, 0, 47, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[3] },
    {{ BAGL_LABELINE, 0x02, 0, 60, 128, 11, 0, 0, 0, 0xFFFFFF, 0x000000, REGULAR, 0 }, global.ux.lines[4] },
    {{ BAGL_ICON, 0x00, 56, 24, 16, 16, 0, 0, 0, 0xFFFFFF, 0x000000, 0, BAGL_GLYPH_NOGLYPH }, (const char*) &C_icon_rien },
#define LINE_1 2
#define LINE_2 3
#endif
  };
  for (int i = 0; i < TZ_SCREEN_LINES_11PX;i++)
    global.ux.lines[i][0]=0;
  switch (screen) {
  case SCREEN_CLEAR_SIGN:
    init[2].text = (const char*) &C_icon_right;
    strncpy(global.ux.lines[0], "Tezos Wallet", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    strncpy(global.ux.lines[LINE_1], "ready for", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    strncpy(global.ux.lines[LINE_2], "safe signing", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    break;
  case SCREEN_BLIND_SIGN:
    init[2].text = (const char*) &C_icon_right;
    strncpy(global.ux.lines[0], "Tezos Wallet", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    strncpy(global.ux.lines[LINE_1], "ready for", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    strncpy(global.ux.lines[LINE_2], "BLIND signing", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    break;
  case SCREEN_QUIT:
    init[1].text = (const char*) &C_icon_left;
    strncpy(global.ux.lines[0], "Quit?", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    init[sizeof(init)/sizeof(bagl_element_t)-1].text = (const char*) &C_icon_dashboard_x;
    break;
  case SCREEN_SETTINGS:
    init[1].text = (const char*) &C_icon_left;
    strncpy(global.ux.lines[0], "Settings", TZ_SCREEN_WITDH_FULL_REGULAR_11PX);
    init[sizeof(init)/sizeof(bagl_element_t)-1].text = (const char*) &C_icon_settings;
    break;
  }
  DISPLAY(init, cb);
}

void ui_initial_screen(void) {
  screen = SCREEN_CLEAR_SIGN;
  redisplay();
}