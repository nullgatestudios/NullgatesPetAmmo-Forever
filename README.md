# Nullgate's Pet & Ammo - Forever

> **Status: planning.** No code yet. See [PLAN.md](PLAN.md).

**Nullgate's Pet & Ammo** is a hunter addon for **World of Warcraft: Forever**. One button feeds your pet the right food from your bags, and the addon keeps an eye on your pet's happiness and your ammo so neither runs out in the middle of a dungeon.

---

## How It Works

1. **Click Feed Pet** (or press its key binding).
2. **The addon picks the food**: something your pet's diet allows, high enough level for your pet to eat, and the least valuable choice first.
3. **Your pet eats it.** Food on your "never feed" list, such as food you eat yourself or food that buffs you, is never used.

The button glows when your pet would benefit from eating, shows how many meals you're carrying, and has a tooltip such as *"Tough Jerky (Meat), 14 left"*.

---

## Features

- **Feed Pet button** that chooses food by your pet's diet and level, with a key binding and a movable bar.
- **Happiness indicator** with a warning when your pet becomes unhappy.
- **Ammo counter** for the ammo you have equipped and the ammo in your bags.
- **Low ammo warnings**, with a louder one when you're nearly out, and a one-click re-equip when your equipped ammo runs out but you carry more of the right type.
- **Settings** in its own window or inside Nullgate's Addon Config.

The addon never buys anything. Use Nullgate's Restock to keep pet food and ammo stocked.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/npet` or `/petammo` | Open the settings. |
| `/npet lock` / `/npet unlock` | Lock or unlock the bar. |
| `/npet reset` | Reset the bar's position. |
| `/npet check` | Test what the addon needs in your game client and save the results. |

---

## Installation

Not released yet. Once it is:

1. Download the latest release from CurseForge or the GitHub releases page.
2. Extract the `NullgatesPetAmmo-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a hunter and type `/npet`.

---

## Part of the Nullgate Addon Suite

- **Nullgate's Addon Config**: one settings hub and profile manager for the whole suite.
- **Nullgate's Restock**, **Quest Tracker**, **Unit Toggles**, **Blacklist** and more.

---

## License

Source-available, all rights reserved. See [LICENSE.md](LICENSE.md).
