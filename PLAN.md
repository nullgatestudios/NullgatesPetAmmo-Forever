# Nullgate's Pet & Ammo - Forever: Plan

Status: phases 0 to 4 built as 1.0.0-beta.1 on 2026-11-20; the in-game checks wait for testers (`/npet check`). Planned on 2026-11-20.

Forever data notes: 380 pet foods over 7 diets (plus Raw Meat, eaten by meat pets); conjured food is flagged. The 30-level feeding rule is the Classic one and `/npet check` reports refusals to confirm it.

- **Folder:** `NullgatesPetAmmo-Forever`
- **Saved variables:** `NullgatesPetAmmoDB` (per character)
- **Commands:** `/npet` and `/petammo`

## Decisions made

- Hunter only: the addon stays off for other classes.
- The addon never buys anything. Buying belongs to Nullgate's Restock.
- Food data is generated from Forever client data (wago.tools), never typed by hand.
- Ships as 1.0.0-beta.1 for testers, like Food & Water.

## The constraint that shapes the design

Feeding is a cast on a chosen item, so the click has to land on a **secure button** whose macro (`/cast Feed Pet` then `/use <bag> <slot>`) was set in advance. The macro can only change **out of combat**, so the addon picks the food whenever your bags or pet change and queues any change made in combat until it ends.

---

## Phase 0: Repo and checks

- Repo, README, plan, license, logo, CurseForge workflow, `/zips` packaging, tests.
- `/npet check` in-game self test. Confirm in the Forever client:
  - `GetPetFoodTypes()` returns the diet names (Meat, Fish, Bread, Cheese, Fruit, Fungus).
  - `GetPetHappiness()` returns happiness 1 to 3.
  - The Feed Pet macro on a secure button feeds the item in that bag slot.
  - The level rule for food a pet refuses as too low.

## Phase 1: Food data and picker

- Generator script: food item IDs with diet type and item level from client data.
- Picker: diet allowed, level high enough for the pet, lowest value first.
- "Never feed" list; option to skip conjured food.
- Unit tests for the picker.

## Phase 2: Feed Pet button and happiness

- Secure Feed Pet button with key binding, count and tooltip; movable, lockable bar.
- Glow when feeding helps and the pet isn't already eating (Feed Pet Effect aura).
- Happiness indicator; warning on dropping to Unhappy (option: below Happy).

## Phase 3: Ammo

- Equipped ammo (`GetInventoryItemCount("player", 0)`) and bag ammo of the matching type.
- Warnings: low (default 200), critical, empty.
- Re-equip button when equipped ammo runs out but a matching stack is in your bags.

## Phase 4: Settings, languages, beta

- Settings window and Nullgate's Addon Config page.
- The 10 client languages.
- DESCRIPTION.md, CHANGELOG.md, 1.0.0-beta.1.
