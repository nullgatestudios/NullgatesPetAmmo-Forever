# Changelog

All notable changes to Nullgate's Pet & Ammo - Forever.

## [1.0.0-beta.1] - 2026-11-20

First test version, looking for hunters to try it.

### New

- **Feed Pet button**: one click feeds your pet the least valuable food in your bags that its diet allows and that is high enough level for it to eat. The button shows how many meals you carry and glows when your pet would like a meal.
- **Pet food data** for 380 foods, read from the Forever client data.
- **Never feed list** (`/npet never <item>`) and an option to skip conjured food.
- **Happiness**: a colored dot on the Feed Pet button, and a warning when your pet becomes unhappy (or, if you choose, as soon as it isn't happy).
- **Ammo button**: shows how much ammo you carry, warns when it runs low (200), nearly out (50) or out, and equips a spare stack of the right type with one click when your ammo slot is empty.
- **Key binding** for Feed Pet under Key Bindings > AddOns.
- **Settings** in its own window or inside Nullgate's Addon Config.
- **`/npet check`**: tests what the addon needs in your client, explains why any food would be refused, and reports what happens when you feed your pet. Results are saved for bug reports.
- Available in English, Deutsch, Español, Français, Italiano, Português (Brasil), Русский, 한국어, 简体中文 and 繁體中文.

### Good to know

- Buttons can't change during combat. If your bags change mid-fight, the Feed Pet button shows a small red mark and updates as soon as combat ends.
- The addon never buys, sells or deletes anything.
