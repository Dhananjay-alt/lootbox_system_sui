# Loot Box dApp Frontend

React + TypeScript + Vite frontend for the Sui Move loot box system.

## What this app does

- Connects browser wallet (Sui-compatible)
- Executes purchase_loot_box on-chain
- Executes open_loot_box on-chain
- Loads LootBoxOpenedEvent history from chain
- Persists history across refresh (event source of truth)

## Environment setup

Create lootbox-ui/.env:

```env
VITE_PACKAGE_ID=0xYOUR_PACKAGE_ID
VITE_GAMECONFIG_ID=0xYOUR_SHARED_GAMECONFIG_ID
VITE_RANDOM_ID=0x8
VITE_PAYMENT_AMOUNT=100
```

Note:

- VITE_GAME_CONFIG_ID is also supported for compatibility.

## Run locally

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
```

## Main implementation files

- src/App.tsx
- src/main.tsx
- src/lib/env.ts
- src/lib/events.ts
- src/lib/types.ts

## Full project docs

See the root README for architecture, contract details, test flow, and command examples.
