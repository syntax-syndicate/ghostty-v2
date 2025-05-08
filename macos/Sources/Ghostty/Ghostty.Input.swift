import Cocoa
import SwiftUI
import GhosttyKit

extension Ghostty {
    // MARK: Keyboard Shortcuts

    /// Return the key equivalent for the given trigger.
    ///
    /// Returns nil if the trigger doesn't have an equivalent KeyboardShortcut. This is possible
    /// because Ghostty input triggers are a superset of what can be represented by a macOS
    /// KeyboardShortcut. For example, macOS doesn't have any way to represent function keys
    /// (F1, F2, ...) with a KeyboardShortcut. This doesn't represent a practical issue because input
    /// handling for Ghostty is handled at a lower level (usually). This function should generally only
    /// be used for things like NSMenu that only support keyboard shortcuts anyways.
    static func keyboardShortcut(for trigger: ghostty_input_trigger_s) -> KeyboardShortcut? {
        let key: KeyEquivalent
        switch (trigger.tag) {
        case GHOSTTY_TRIGGER_PHYSICAL:
            // Only functional keys can be converted to a KeyboardShortcut. Other physical
            // mappings cannot because KeyboardShortcut in Swift is inherently layout-dependent.
            if let equiv = Self.keyToEquivalent[trigger.key.physical] {
                key = equiv
            } else {
                return nil
            }

        case GHOSTTY_TRIGGER_UNICODE:
            guard let scalar = UnicodeScalar(trigger.key.unicode) else { return nil }
            key = KeyEquivalent(Character(scalar))

        default:
            return nil
        }

        return KeyboardShortcut(
            key,
            modifiers: EventModifiers(nsFlags: Ghostty.eventModifierFlags(mods: trigger.mods)))
    }

    // MARK: Mods

    /// Returns the event modifier flags set for the Ghostty mods enum.
    static func eventModifierFlags(mods: ghostty_input_mods_e) -> NSEvent.ModifierFlags {
        var flags = NSEvent.ModifierFlags(rawValue: 0);
        if (mods.rawValue & GHOSTTY_MODS_SHIFT.rawValue != 0) { flags.insert(.shift) }
        if (mods.rawValue & GHOSTTY_MODS_CTRL.rawValue != 0) { flags.insert(.control) }
        if (mods.rawValue & GHOSTTY_MODS_ALT.rawValue != 0) { flags.insert(.option) }
        if (mods.rawValue & GHOSTTY_MODS_SUPER.rawValue != 0) { flags.insert(.command) }
        return flags
    }

    /// Translate event modifier flags to a ghostty mods enum.
    static func ghosttyMods(_ flags: NSEvent.ModifierFlags) -> ghostty_input_mods_e {
        var mods: UInt32 = GHOSTTY_MODS_NONE.rawValue

        if (flags.contains(.shift)) { mods |= GHOSTTY_MODS_SHIFT.rawValue }
        if (flags.contains(.control)) { mods |= GHOSTTY_MODS_CTRL.rawValue }
        if (flags.contains(.option)) { mods |= GHOSTTY_MODS_ALT.rawValue }
        if (flags.contains(.command)) { mods |= GHOSTTY_MODS_SUPER.rawValue }
        if (flags.contains(.capsLock)) { mods |= GHOSTTY_MODS_CAPS.rawValue }

        // Handle sided input. We can't tell that both are pressed in the
        // Ghostty structure but thats okay -- we don't use that information.
        let rawFlags = flags.rawValue
        if (rawFlags & UInt(NX_DEVICERSHIFTKEYMASK) != 0) { mods |= GHOSTTY_MODS_SHIFT_RIGHT.rawValue }
        if (rawFlags & UInt(NX_DEVICERCTLKEYMASK) != 0) { mods |= GHOSTTY_MODS_CTRL_RIGHT.rawValue }
        if (rawFlags & UInt(NX_DEVICERALTKEYMASK) != 0) { mods |= GHOSTTY_MODS_ALT_RIGHT.rawValue }
        if (rawFlags & UInt(NX_DEVICERCMDKEYMASK) != 0) { mods |= GHOSTTY_MODS_SUPER_RIGHT.rawValue }

        return ghostty_input_mods_e(mods)
    }

    /// A map from the Ghostty key enum to the keyEquivalent string for shortcuts. Note that
    /// not all ghostty key enum values are represented here because not all of them can be
    /// mapped to a KeyEquivalent.
    static let keyToEquivalent: [ghostty_input_key_e : KeyEquivalent] = [
        // Function keys
        GHOSTTY_KEY_ARROW_UP: .upArrow,
        GHOSTTY_KEY_ARROW_DOWN: .downArrow,
        GHOSTTY_KEY_ARROW_LEFT: .leftArrow,
        GHOSTTY_KEY_ARROW_RIGHT: .rightArrow,
        GHOSTTY_KEY_HOME: .home,
        GHOSTTY_KEY_END: .end,
        GHOSTTY_KEY_DELETE: .delete,
        GHOSTTY_KEY_PAGE_UP: .pageUp,
        GHOSTTY_KEY_PAGE_DOWN: .pageDown,
        GHOSTTY_KEY_ESCAPE: .escape,
        GHOSTTY_KEY_ENTER: .return,
        GHOSTTY_KEY_TAB: .tab,
        GHOSTTY_KEY_BACKSPACE: .delete,
        GHOSTTY_KEY_SPACE: .space,
    ]

    // Mapping of event keyCode to ghostty input key values. This is cribbed from
    // glfw mostly since we started as a glfw-based app way back in the day!
    static let keycodeToKey: [UInt16 : ghostty_input_key_e] = [
        0x1D: GHOSTTY_KEY_DIGIT_0,
        0x12: GHOSTTY_KEY_DIGIT_1,
        0x13: GHOSTTY_KEY_DIGIT_2,
        0x14: GHOSTTY_KEY_DIGIT_3,
        0x15: GHOSTTY_KEY_DIGIT_4,
        0x17: GHOSTTY_KEY_DIGIT_5,
        0x16: GHOSTTY_KEY_DIGIT_6,
        0x1A: GHOSTTY_KEY_DIGIT_7,
        0x1C: GHOSTTY_KEY_DIGIT_8,
        0x19: GHOSTTY_KEY_DIGIT_9,
        0x00: GHOSTTY_KEY_A,
        0x0B: GHOSTTY_KEY_B,
        0x08: GHOSTTY_KEY_C,
        0x02: GHOSTTY_KEY_D,
        0x0E: GHOSTTY_KEY_E,
        0x03: GHOSTTY_KEY_F,
        0x05: GHOSTTY_KEY_G,
        0x04: GHOSTTY_KEY_H,
        0x22: GHOSTTY_KEY_I,
        0x26: GHOSTTY_KEY_J,
        0x28: GHOSTTY_KEY_K,
        0x25: GHOSTTY_KEY_L,
        0x2E: GHOSTTY_KEY_M,
        0x2D: GHOSTTY_KEY_N,
        0x1F: GHOSTTY_KEY_O,
        0x23: GHOSTTY_KEY_P,
        0x0C: GHOSTTY_KEY_Q,
        0x0F: GHOSTTY_KEY_R,
        0x01: GHOSTTY_KEY_S,
        0x11: GHOSTTY_KEY_T,
        0x20: GHOSTTY_KEY_U,
        0x09: GHOSTTY_KEY_V,
        0x0D: GHOSTTY_KEY_W,
        0x07: GHOSTTY_KEY_X,
        0x10: GHOSTTY_KEY_Y,
        0x06: GHOSTTY_KEY_Z,

        0x27: GHOSTTY_KEY_QUOTE,
        0x2A: GHOSTTY_KEY_BACKSLASH,
        0x2B: GHOSTTY_KEY_COMMA,
        0x18: GHOSTTY_KEY_EQUAL,
        0x32: GHOSTTY_KEY_BACKQUOTE,
        0x21: GHOSTTY_KEY_BRACKET_LEFT,
        0x1B: GHOSTTY_KEY_MINUS,
        0x2F: GHOSTTY_KEY_PERIOD,
        0x1E: GHOSTTY_KEY_BRACKET_RIGHT,
        0x29: GHOSTTY_KEY_SEMICOLON,
        0x2C: GHOSTTY_KEY_SLASH,

        0x33: GHOSTTY_KEY_BACKSPACE,
        0x39: GHOSTTY_KEY_CAPS_LOCK,
        0x75: GHOSTTY_KEY_DELETE,
        0x7D: GHOSTTY_KEY_ARROW_DOWN,
        0x77: GHOSTTY_KEY_END,
        0x24: GHOSTTY_KEY_ENTER,
        0x35: GHOSTTY_KEY_ESCAPE,
        0x7A: GHOSTTY_KEY_F1,
        0x78: GHOSTTY_KEY_F2,
        0x63: GHOSTTY_KEY_F3,
        0x76: GHOSTTY_KEY_F4,
        0x60: GHOSTTY_KEY_F5,
        0x61: GHOSTTY_KEY_F6,
        0x62: GHOSTTY_KEY_F7,
        0x64: GHOSTTY_KEY_F8,
        0x65: GHOSTTY_KEY_F9,
        0x6D: GHOSTTY_KEY_F10,
        0x67: GHOSTTY_KEY_F11,
        0x6F: GHOSTTY_KEY_F12,
        0x69: GHOSTTY_KEY_PRINT_SCREEN,
        0x6B: GHOSTTY_KEY_F14,
        0x71: GHOSTTY_KEY_F15,
        0x6A: GHOSTTY_KEY_F16,
        0x40: GHOSTTY_KEY_F17,
        0x4F: GHOSTTY_KEY_F18,
        0x50: GHOSTTY_KEY_F19,
        0x5A: GHOSTTY_KEY_F20,
        0x73: GHOSTTY_KEY_HOME,
        0x72: GHOSTTY_KEY_INSERT,
        0x7B: GHOSTTY_KEY_ARROW_LEFT,
        0x3A: GHOSTTY_KEY_ALT_LEFT,
        0x3B: GHOSTTY_KEY_CONTROL_LEFT,
        0x38: GHOSTTY_KEY_SHIFT_LEFT,
        0x37: GHOSTTY_KEY_META_LEFT,
        0x47: GHOSTTY_KEY_NUM_LOCK,
        0x79: GHOSTTY_KEY_PAGE_DOWN,
        0x74: GHOSTTY_KEY_PAGE_UP,
        0x7C: GHOSTTY_KEY_ARROW_RIGHT,
        0x3D: GHOSTTY_KEY_ALT_RIGHT,
        0x3E: GHOSTTY_KEY_CONTROL_RIGHT,
        0x3C: GHOSTTY_KEY_SHIFT_RIGHT,
        0x36: GHOSTTY_KEY_META_RIGHT,
        0x31: GHOSTTY_KEY_SPACE,
        0x30: GHOSTTY_KEY_TAB,
        0x7E: GHOSTTY_KEY_ARROW_UP,

        0x52: GHOSTTY_KEY_NUMPAD_0,
        0x53: GHOSTTY_KEY_NUMPAD_1,
        0x54: GHOSTTY_KEY_NUMPAD_2,
        0x55: GHOSTTY_KEY_NUMPAD_3,
        0x56: GHOSTTY_KEY_NUMPAD_4,
        0x57: GHOSTTY_KEY_NUMPAD_5,
        0x58: GHOSTTY_KEY_NUMPAD_6,
        0x59: GHOSTTY_KEY_NUMPAD_7,
        0x5B: GHOSTTY_KEY_NUMPAD_8,
        0x5C: GHOSTTY_KEY_NUMPAD_9,
        0x45: GHOSTTY_KEY_NUMPAD_ADD,
        0x41: GHOSTTY_KEY_NUMPAD_DECIMAL,
        0x4B: GHOSTTY_KEY_NUMPAD_DIVIDE,
        0x4C: GHOSTTY_KEY_NUMPAD_ENTER,
        0x51: GHOSTTY_KEY_NUMPAD_EQUAL,
        0x43: GHOSTTY_KEY_NUMPAD_MULTIPLY,
        0x4E: GHOSTTY_KEY_NUMPAD_SUBTRACT,
    ];
}
