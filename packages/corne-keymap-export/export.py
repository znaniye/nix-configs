import re
import sys
import time

import zmk_studio_api as zmk

KEYMAP = "keyboards/corne/config/corne.keymap"
UNLOCK_TIMEOUT = 120

MODS = {
    "LC": 0x01, "LS": 0x02, "LA": 0x04, "LG": 0x08,
    "RC": 0x10, "RS": 0x20, "RA": 0x40, "RG": 0x80,
}

DEPRECATED = {
    "ATSN": "AT_SIGN", "CMMA": "COMMA", "COLN": "COLON", "COPY": "K_COPY",
    "CRRT": "CARET", "CUT": "K_CUT", "EQL": "EQUAL", "GRAV": "GRAVE",
    "KPLS": "KP_PLUS", "LABT": "LESS_THAN", "M_EJCT": "C_EJECT",
    "M_MUTE": "C_MUTE", "M_NEXT": "C_NEXT", "M_PLAY": "C_PLAY_PAUSE",
    "M_PREV": "C_PREVIOUS", "M_STOP": "C_STOP", "NUM_0": "N0", "NUM_1": "N1",
    "NUM_2": "N2", "NUM_3": "N3", "NUM_4": "N4", "NUM_5": "N5", "NUM_6": "N6",
    "NUM_7": "N7", "NUM_8": "N8", "NUM_9": "N9", "PAUS": "PAUSE_BREAK",
    "PSTE": "K_PASTE", "SPC": "SPACE", "TILD": "TILDE", "UARW": "UP_ARROW",
    "UNDO": "K_UNDO",
}

BT_CMDS = {0: "BT_CLR", 1: "BT_NXT", 2: "BT_PRV", 3: "BT_SEL", 4: "BT_CLR_ALL", 5: "BT_DISC"}
BT_WITH_ARG = {3, 5}
OUT_VALS = {0: "OUT_TOG", 1: "OUT_USB", 2: "OUT_BLE", 3: "OUT_NONE"}

USAGE_TO_NAME = {}
NAME_TO_USAGE = {}
for _k in zmk.Keycode:
    USAGE_TO_NAME.setdefault(int(_k), DEPRECATED.get(_k.name, _k.name))
    NAME_TO_USAGE.setdefault(_k.name, int(_k))
    if _k.name in DEPRECATED:
        NAME_TO_USAGE.setdefault(DEPRECATED[_k.name], int(_k))

PREFERRED = {}


class Unsupported(Exception):
    pass


def varint(buf, i):
    v = s = 0
    while True:
        b = buf[i]
        i += 1
        v |= (b & 0x7F) << s
        if not b & 0x80:
            return v, i
        s += 7


def fields(buf):
    i = 0
    while i < len(buf):
        key, i = varint(buf, i)
        num, wt = key >> 3, key & 7
        if wt == 0:
            val, i = varint(buf, i)
        elif wt == 2:
            ln, i = varint(buf, i)
            val, i = buf[i:i + ln], i + ln
        elif wt == 5:
            val, i = buf[i:i + 4], i + 4
        elif wt == 1:
            val, i = buf[i:i + 8], i + 8
        else:
            raise ValueError(f"unsupported wire type {wt}")
        yield num, val


def zigzag(n):
    return (n >> 1) ^ -(n & 1)


def parse_keymap(buf):
    layers = []
    for num, val in fields(buf):
        if num != 1:
            continue
        layer = {"id": 0, "name": "", "bindings": []}
        for n2, v2 in fields(val):
            if n2 == 1:
                layer["id"] = v2
            elif n2 == 2:
                layer["name"] = v2.decode()
            elif n2 == 3:
                triple = [0, 0, 0]
                for n3, v3 in fields(v2):
                    if n3 == 1:
                        triple[0] = zigzag(v3)
                    elif n3 == 2:
                        triple[1] = v3
                    elif n3 == 3:
                        triple[2] = v3
                layer["bindings"].append(tuple(triple))
        layers.append(layer)
    return layers


def parse_details(buf):
    ident, name = 0, ""
    for num, val in fields(buf):
        if num == 1:
            ident = val
        elif num == 2:
            name = val.decode()
    return ident, name


def keycode(param):
    if param in PREFERRED:
        return PREFERRED[param]
    if param in USAGE_TO_NAME:
        return USAGE_TO_NAME[param]
    base, mods = param & 0xFFFFFF, param >> 24
    name = PREFERRED.get(base) or USAGE_TO_NAME.get(base)
    if name is None:
        raise Unsupported(f"unknown HID usage 0x{param:08X}")
    for label, bit in MODS.items():
        if mods & bit:
            name = f"{label}({name})"
    return name


def bluetooth(a, b):
    if a not in BT_CMDS:
        raise Unsupported(f"unknown bluetooth command {a}")
    return f"&bt {BT_CMDS[a]} {b}" if a in BT_WITH_ARG else f"&bt {BT_CMDS[a]}"


def output(a, b):
    if a not in OUT_VALS:
        raise Unsupported(f"unknown output value {a}")
    return f"&out {OUT_VALS[a]}"


BEHAVIORS = {
    "key press": lambda a, b: f"&kp {keycode(a)}",
    "key toggle": lambda a, b: f"&kt {keycode(a)}",
    "sticky key": lambda a, b: f"&sk {keycode(a)}",
    "layer-tap": lambda a, b: f"&lt {a} {keycode(b)}",
    "mod-tap": lambda a, b: f"&mt {keycode(a)} {keycode(b)}",
    "momentary layer": lambda a, b: f"&mo {a}",
    "sticky layer": lambda a, b: f"&sl {a}",
    "toggle layer": lambda a, b: f"&tog {a}",
    "to layer": lambda a, b: f"&to {a}",
    "bluetooth": bluetooth,
    "output selection": output,
    "mouse key press": lambda a, b: f"&mkp {a}",
    "caps word": lambda a, b: "&caps_word",
    "key repeat": lambda a, b: "&key_repeat",
    "reset": lambda a, b: "&sys_reset",
    "bootloader": lambda a, b: "&bootloader",
    "z_so_off": lambda a, b: "&soft_off",
    "studio unlock": lambda a, b: "&studio_unlock",
    "grave/escape": lambda a, b: "&gresc",
    "transparent": lambda a, b: "&trans",
    "none": lambda a, b: "&none",
}


def encode(text):
    m = re.fullmatch(r'(\w+)\((.*)\)', text)
    if m and m.group(1) in MODS:
        inner = encode(m.group(2))
        return None if inner is None else (MODS[m.group(1)] << 24) | inner
    if text in NAME_TO_USAGE:
        return NAME_TO_USAGE[text]
    try:
        parts = re.findall(r'(\w+): (-?\d+)', repr(zmk.KeyPress(text)))
    except Exception:
        return None
    page, ident, mods = (int(v) for _, v in parts[:3])
    return (mods << 24) | (page << 16) | ident


BINDINGS_RE = re.compile(r'bindings\s*=\s*<(?P<body>.*?)>\s*;', re.S)
NODE_RE = re.compile(r'(\w[\w-]*)\s*\{', re.S)
TOKEN_RE = re.compile(r'&[A-Za-z_]\w*(?:[ \t]+[A-Za-z0-9_()]+)*')


def find_layers(text):
    out = []
    for m in BINDINGS_RE.finditer(text):
        names = NODE_RE.findall(text, 0, m.start())
        start = m.start("body")
        tokens = [(t.group(0), start + t.start(), start + t.end())
                  for t in TOKEN_RE.finditer(m.group("body"))]
        out.append({"name": names[-1] if names else "?", "tokens": tokens})
    return out


def learn_names(file_layers):
    for layer in file_layers:
        for token, _, _ in layer["tokens"]:
            for arg in token.split()[1:]:
                if not re.match(r'[A-Za-z_]', arg):
                    continue
                code = encode(arg)
                if code is not None:
                    PREFERRED.setdefault(code, arg)


def unlock(client):
    if "UNLOCKED" in client.get_lock_state():
        return
    print("locked; press the &studio_unlock key on the keyboard")
    deadline = time.time() + UNLOCK_TIMEOUT
    while "UNLOCKED" not in client.get_lock_state():
        if time.time() > deadline:
            sys.exit("timed out waiting for unlock")
        time.sleep(1)
    print("unlocked")


def main():
    try:
        with open(KEYMAP) as fh:
            text = fh.read()
    except FileNotFoundError:
        sys.exit(f"{KEYMAP} not found; run this from the repository root")

    file_layers = find_layers(text)
    if not file_layers:
        sys.exit(f"no bindings found in {KEYMAP}")
    learn_names(file_layers)

    devices = zmk.StudioClient.list_ble_devices()
    if not devices:
        sys.exit("no BLE keyboard found; connect it first")
    device_id, name = devices[0]
    print(f"connecting to {name or device_id}")
    client = zmk.StudioClient.open_ble(device_id)

    unlock(client)

    if client.check_unsaved_changes():
        sys.exit("keyboard has unsaved changes; save them in ZMK Studio first")

    device_layers = parse_keymap(bytes(client.get_keymap_bytes()))
    if len(device_layers) != len(file_layers):
        sys.exit(f"{len(file_layers)} layers in the file, {len(device_layers)} on the "
                 "keyboard; resolve that by hand first")
    for f, d in zip(file_layers, device_layers):
        if len(f["tokens"]) != len(d["bindings"]):
            sys.exit(f"layer {f['name']}: {len(f['tokens'])} bindings in the file, "
                     f"{len(d['bindings'])} on the keyboard")

    roles = {}
    for bid in sorted({t[0] for d in device_layers for t in d["bindings"]}):
        _, display = parse_details(bytes(client.get_behavior_details_bytes(bid)))
        role = display.strip().lower()
        if role not in BEHAVIORS:
            sys.exit(f"behavior {bid} ({display!r}) is not supported by this script")
        roles[bid] = role

    edits = []
    for f, d in zip(file_layers, device_layers):
        for (token, start, end), (bid, p1, p2) in zip(f["tokens"], d["bindings"]):
            try:
                new = BEHAVIORS[roles[bid]](p1, p2)
            except Unsupported as exc:
                sys.exit(f"layer {f['name']}: {exc}")
            if new != " ".join(token.split()):
                edits.append((start, end, new))

    for start, end, new in sorted(edits, reverse=True):
        text = text[:start] + new + text[end:]

    with open(KEYMAP, "w") as fh:
        fh.write(text)
    print(f"{KEYMAP} updated, {len(edits)} bindings changed; review with git diff")
    return 0


if __name__ == "__main__":
    sys.exit(main())
