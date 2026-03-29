export type ItemRarity = "Common" | "Rare" | "Epic" | "Legendary";

export type Item = {
  id: string;
  rarity: ItemRarity;
  power: number;
  name: string;
  owner: string;
};

export type LootBoxOpenedEventJson = {
  item_id?: string;
  rarity?: number | string;
  power?: number | string;
  name?: unknown;
  owner?: string;
};
