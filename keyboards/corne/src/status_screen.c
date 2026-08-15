#include <zephyr/kernel.h>

#include <zmk/battery.h>
#include <zmk/display.h>
#include <zmk/display/status_screen.h>
#include <zmk/event_manager.h>
#include <zmk/events/battery_state_changed.h>
#include <zmk/usb.h>
#include <zmk/events/usb_conn_state_changed.h>

#include "art.h"

#define ART_BOTTOM_INSET 16

#define BATTERY_CELLS 5

static lv_obj_t *battery_cells[BATTERY_CELLS];

struct battery_state {
    uint8_t level;
    bool charging;
};

static int32_t glyph_advance(void) {
    return ((const lv_image_dsc_t *)art_glyphs[0])->header.h;
}

static void battery_render(struct battery_state state) {
    uint8_t cells[BATTERY_CELLS];
    size_t count = 0;

    if (state.charging) {
        cells[count++] = ART_GLYPH_CHARGE;
    }

    uint8_t level = state.level > 100 ? 100 : state.level;
    if (level >= 100) {
        cells[count++] = 1;
        cells[count++] = 0;
        cells[count++] = 0;
    } else {
        if (level >= 10) {
            cells[count++] = level / 10;
        }
        cells[count++] = level % 10;
    }
    cells[count++] = ART_GLYPH_PERCENT;

    int32_t advance = glyph_advance();
    int32_t first = -((int32_t)count - 1) * advance / 2;

    for (size_t i = 0; i < BATTERY_CELLS; i++) {
        if (i >= count) {
            lv_obj_add_flag(battery_cells[i], LV_OBJ_FLAG_HIDDEN);
            continue;
        }
        lv_image_set_src(battery_cells[i], art_glyphs[cells[i]]);
        lv_obj_remove_flag(battery_cells[i], LV_OBJ_FLAG_HIDDEN);
        lv_obj_align(battery_cells[i], LV_ALIGN_RIGHT_MID, 0, first + (int32_t)i * advance);
    }
}

static struct battery_state battery_get_state(const zmk_event_t *eh) {
    const struct zmk_battery_state_changed *ev = as_zmk_battery_state_changed(eh);

    return (struct battery_state){
        .level = (ev != NULL) ? ev->state_of_charge : zmk_battery_state_of_charge(),
#if IS_ENABLED(CONFIG_USB_DEVICE_STACK)
        .charging = zmk_usb_is_powered(),
#else
        .charging = false,
#endif
    };
}

ZMK_DISPLAY_WIDGET_LISTENER(nix_battery, struct battery_state, battery_render, battery_get_state)
ZMK_SUBSCRIPTION(nix_battery, zmk_battery_state_changed);
#if IS_ENABLED(CONFIG_USB_DEVICE_STACK)
ZMK_SUBSCRIPTION(nix_battery, zmk_usb_conn_state_changed);
#endif

static lv_obj_t *create_art(lv_obj_t *screen) {
#if IS_ENABLED(CONFIG_ZMK_SPLIT_ROLE_CENTRAL)
    lv_obj_t *art = lv_image_create(screen);
    lv_image_set_src(art, &art_nix_logo);
#else
    lv_obj_t *art = lv_animimg_create(screen);
    lv_animimg_set_src(art, art_lambda_frames, art_lambda_frames_count);
    lv_animimg_set_duration(art, CONFIG_ZMK_NIX_SCREEN_LAMBDA_PERIOD_MS);
    lv_animimg_set_repeat_count(art, LV_ANIM_REPEAT_INFINITE);
    lv_animimg_start(art);
#endif
    return art;
}

lv_obj_t *zmk_display_status_screen() {
    lv_obj_t *screen = lv_obj_create(NULL);
    lv_obj_remove_flag(screen, LV_OBJ_FLAG_SCROLLABLE);

    lv_obj_align(create_art(screen), LV_ALIGN_LEFT_MID, ART_BOTTOM_INSET, 0);

    for (size_t i = 0; i < BATTERY_CELLS; i++) {
        battery_cells[i] = lv_image_create(screen);
        lv_obj_add_flag(battery_cells[i], LV_OBJ_FLAG_HIDDEN);
    }
    nix_battery_init();

    return screen;
}
