**Nullgate's Pet & Ammo** is a hunter addon for **World of Warcraft: Forever**. One button feeds your pet the right food from your bags, and the addon watches your pet's happiness and your ammo so neither runs out halfway through a dungeon.

No more digging through your bags for something your pet will actually eat, or finding out you're out of arrows when the pull has already started.

> **Beta:** this is an early test version and we're looking for hunters to try it. If something doesn't work, run `/npet check`, then send us the results with a short description.

---

## Features

- **Feed Pet button**: picks food your pet's diet allows and that is high enough level for your pet to eat, cheapest choice first. The button shows how many meals you're carrying, and its tooltip says what it will feed.
- **Never feed list**: food you want to keep for yourself, or food that gives you a buff, is never touched (`/npet never <item>`). Conjured food can be skipped too.
- **Happiness indicator**: see at a glance whether your pet is happy, content or unhappy, with a warning when it becomes unhappy. The Feed Pet button glows when a meal would help.
- **Ammo counter**: the ammo you have equipped and the matching ammo in your bags.
- **Low ammo warnings**: a reminder when you drop below a number you choose, a louder one when you're nearly out, and a one-click re-equip when your equipped ammo runs out but you carry more of the right type.
- **Key binding** for Feed Pet, under Key Bindings > AddOns.
- **Simple settings**: lock and move the bar, scale, warning levels and sounds, conjured food and the language.

---

## How It Works

1. **Click Feed Pet**, or press its key binding.
2. **The addon picks the food**: allowed by your pet's diet, high enough level to give happiness, and the least valuable option you carry.
3. **Your pet eats it.**

The game doesn't allow buttons to change during combat. If your bags change mid-fight, the button shows a small red mark and updates as soon as combat ends.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/npet` or `/petammo` | Open the settings. |
| `/npet never <item link>` | Never feed this food (type it again to allow it). |
| `/npet lock` / `/npet unlock` | Lock or unlock the bar. |
| `/npet reset` | Reset the bar's position. |
| `/npet check` | Test what the addon needs in your game client and save the results (for bug reports). |

---

## Supported Languages

All 10 languages the game client runs in:

- English
- Deutsch (German)
- Español (Spanish)
- Français (French)
- Italiano (Italian)
- Português do Brasil (Brazilian Portuguese)
- Русский (Russian)
- 한국어 (Korean)
- 简体中文 (Simplified Chinese)
- 繁體中文 (Traditional Chinese)

The addon uses your game's language automatically. You can switch at any time in the settings; it applies after a `/reload`. The translations were made with machine assistance, so some wording may not be quite right. Corrections are welcome: send a message here on CurseForge or [report on our website](https://nullgatestudios.com/report?addon=pet-ammo).

## Installation

1. Download the latest file.
2. Extract the `NullgatesPetAmmo-Forever` folder into the `Interface\AddOns` folder of your World of Warcraft: Forever installation.
3. Log in on a hunter. The bar appears near the bottom of the screen; type `/npet` for the settings.

---

## Good to Know

- The addon only runs for hunters.
- It never buys, sells or deletes anything.
