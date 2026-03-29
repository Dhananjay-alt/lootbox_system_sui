import type { Item, ItemRarity, LootBoxOpenedEventJson } from "./types";

export function toNumber(value: number | string | undefined): number {
  if (typeof value === "number") return value;
  if (typeof value === "string") return Number(value);
  return 0;
}

export function rarityLabel(rarity: number): ItemRarity {
  if (rarity === 0) return "Common";
  if (rarity === 1) return "Rare";
  if (rarity === 2) return "Epic";
  return "Legendary";
}

function tryDecodeBase64(value: string): string {
  try {
    const decoded = atob(value);
    // Keep printable output only; fallback to original if it's binary-looking.
    const printable = /^[\x20-\x7E]+$/.test(decoded);
    return printable ? decoded : value;
  } catch {
    return value;
  }
}

export function decodeMoveName(value: unknown): string {
  if (typeof value === "string") return tryDecodeBase64(value);

  if (Array.isArray(value)) {
    const bytes = value.filter((v): v is number => typeof v === "number");
    return String.fromCharCode(...bytes);
  }

  return "Unknown Skin";
}

export function mapOpenedEventToItem(json: LootBoxOpenedEventJson): Item {
  const rarity = toNumber(json.rarity);

  return {
    id: json.item_id ?? `${Date.now()}`,
    rarity: rarityLabel(rarity),
    power: toNumber(json.power),
    name: decodeMoveName(json.name),
    owner: json.owner ?? "",
  };
}
