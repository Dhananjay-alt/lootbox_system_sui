export const PACKAGE_ID = import.meta.env.VITE_PACKAGE_ID as string | undefined;

// Support both forms requested by different revisions.
export const GAME_CONFIG_ID =
  (import.meta.env.VITE_GAMECONFIG_ID as string | undefined) ??
  (import.meta.env.VITE_GAME_CONFIG_ID as string | undefined);

export const RANDOM_ID =
  (import.meta.env.VITE_RANDOM_ID as string | undefined) ?? "0x8";

export const PAYMENT_AMOUNT = Number(import.meta.env.VITE_PAYMENT_AMOUNT ?? "100");

export const IS_CONFIGURED = Boolean(PACKAGE_ID && GAME_CONFIG_ID);
