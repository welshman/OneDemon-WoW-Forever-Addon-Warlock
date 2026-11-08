# OneDemon

**One button for all your Warlock demons.**

OneDemon replaces the clutter of separate pet summon buttons with a single, clean button, similar to how Retail handles it. Left-click to summon your current demon. Right-click to open a flyout and pick a different one.

Built for **World of Warcraft: Forever**.

---

## Features

- **One-button summoning:** left-click (or use your keybind) to summon your selected demon
- **Right-click flyout:** shows every demon you currently know, and closes after you pick one
- **Remembers your choice:** your last-picked demon is saved between sessions and characters
- **Auto-detects known demons:** only shows the pets you have actually learned
- **Cooldown swipe:** shows the cooldown on the button
- **Keybinding support:** bind it under Key Bindings → AddOns → OneDemon
- **Works in combat:** the flyout is secure, so it can be opened and used during a fight
- **Options panel:** found under Options → AddOns → OneDemon

## Options

- Button scale
- Flyout direction (up, down, left, right)
- Lock position
- Show or hide tooltips
- Show or hide cooldown swipe
- Reset position

## How to use

- **Left-click:** summon the current demon
- **Right-click:** open or close the demon list
- **Shift + drag:** move the button
- **/onedemon:** open the options panel
- **/onedemon reset:** reset the button's position

## Installation

1. Download and extract the zip.
2. Put the `OneDemon` folder in your `Interface/AddOns` directory.
3. Restart the game, or type `/reload` if it is already running.

The addon only loads on Warlock characters.

## Notes

- Settings changes can't be applied during combat because the buttons are secure frames. If you try, the addon will tell you.
- Forever uses the modern addon API, so this addon is not intended for Classic Era clients.
- If a demon is missing from the flyout, it either isn't learned yet or uses a spell ID the addon doesn't know about. Please report it.

## Known issues

- Felguard may not appear until its spell ID is confirmed for Forever.

## Feedback

Found a bug or a missing demon? Leave a comment or open an issue with the exact message from `/oddebug` and any Lua error text.

---

## Changelog

**1.0**
- Initial release
- One-button demon summoning with right-click flyout
- Options panel and keybinding support
