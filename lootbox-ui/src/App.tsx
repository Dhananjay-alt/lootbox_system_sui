import {
  ConnectButton,
  useCurrentAccount,
  useSignAndExecuteTransaction,
  useSuiClient,
  useSuiClientContext,
} from "@mysten/dapp-kit";
import { Transaction } from "@mysten/sui/transactions";
import { useCallback, useEffect, useMemo, useState } from "react";
import {
  GAME_CONFIG_ID,
  IS_CONFIGURED,
  PACKAGE_ID,
  PAYMENT_AMOUNT,
  RANDOM_ID,
} from "./lib/env";
import { mapOpenedEventToItem } from "./lib/events";
import type { Item, LootBoxOpenedEventJson } from "./lib/types";
import "./App.css";

function App() {
  const account = useCurrentAccount();
  const client = useSuiClient();
  const { network } = useSuiClientContext();
  const { mutateAsync: signAndExecuteTransaction } = useSignAndExecuteTransaction();

  const [hasLootBox, setHasLootBox] = useState<boolean>(false);
  const [lootBoxId, setLootBoxId] = useState<string | null>(null);
  const [currentItem, setCurrentItem] = useState<Item | null>(null);
  const [history, setHistory] = useState<Item[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string>("");
  const [txStatus, setTxStatus] = useState<string>("");

  const isConfigured = IS_CONFIGURED;

  const eventType = useMemo(
    () => (PACKAGE_ID ? `${PACKAGE_ID}::loot_box::LootBoxOpenedEvent` : ""),
    [],
  );

  const refreshOwnedLootBoxes = useCallback(async () => {
    if (!account || !PACKAGE_ID) {
      setHasLootBox(false);
      setLootBoxId(null);
      return;
    }

    const result = await client.getOwnedObjects({
      owner: account.address,
      filter: {
        StructType: `${PACKAGE_ID}::loot_box::LootBox`,
      },
      options: {
        showType: true,
      },
    });

    const firstLootBoxId =
      result.data.find((entry) => entry.data?.objectId)?.data?.objectId ?? null;

    setLootBoxId(firstLootBoxId);
    setHasLootBox(firstLootBoxId !== null);
  }, [account, client]);

  const refreshHistory = useCallback(async () => {
    if (!eventType) {
      setHistory([]);
      return;
    }

    // Read on-chain events so history persists across refreshes.
    const events = await client.queryEvents({
      query: { MoveEventType: eventType },
      order: "descending",
      limit: 25,
    });

    const parsed = events.data
      .map((event) => event.parsedJson as LootBoxOpenedEventJson | null)
      .filter((json): json is LootBoxOpenedEventJson => json !== null)
      .filter((json) => (account ? json.owner === account.address : true))
      .map(mapOpenedEventToItem);

    setHistory(parsed);
    setCurrentItem(parsed[0] ?? null);
  }, [account, client, eventType]);

  useEffect(() => {
    void refreshOwnedLootBoxes();
    void refreshHistory();
  }, [refreshOwnedLootBoxes, refreshHistory]);

  const buyLootBox = async (): Promise<void> => {
    if (!account) {
      setError("Connect wallet first.");
      return;
    }
    if (!isConfigured || !PACKAGE_ID || !GAME_CONFIG_ID) {
      setError("Set VITE_PACKAGE_ID and VITE_GAMECONFIG_ID in your env.");
      return;
    }

    setError("");
    setTxStatus("");
    setLoading(true);

    try {
      const tx = new Transaction();
      // Split the gas coin to produce a Coin<SUI> input matching the loot box price.
      const payment = tx.splitCoins(tx.gas, [tx.pure.u64(PAYMENT_AMOUNT)]);

      tx.moveCall({
        target: `${PACKAGE_ID}::loot_box::purchase_loot_box`,
        arguments: [tx.object(GAME_CONFIG_ID), payment],
      });

      const result = await signAndExecuteTransaction({
        transaction: tx,
        chain: `sui:${network}`,
      });

      setTxStatus(`Purchase success: ${result.digest}`);

      await refreshOwnedLootBoxes();
      await refreshHistory();
    } catch (e) {
      const message = e instanceof Error ? e.message : "Purchase failed";
      setError(message);
      setTxStatus("Purchase failed");
    } finally {
      setLoading(false);
    }
  };

  const openLootBox = async (): Promise<void> => {
    if (!account) {
      setError("Connect wallet first.");
      return;
    }
    if (!lootBoxId) {
      setError("No loot box found in your wallet.");
      return;
    }
    if (!isConfigured || !PACKAGE_ID || !GAME_CONFIG_ID) {
      setError("Set VITE_PACKAGE_ID and VITE_GAMECONFIG_ID in your env.");
      return;
    }

    setError("");
    setTxStatus("");
    setLoading(true);

    try {
      const tx = new Transaction();
      // open_loot_box expects: owned LootBox, shared GameConfig, and shared Random object.
      tx.moveCall({
        target: `${PACKAGE_ID}::loot_box::open_loot_box`,
        arguments: [
          tx.object(lootBoxId),
          tx.object(GAME_CONFIG_ID),
          tx.object(RANDOM_ID),
        ],
      });

      const result = await signAndExecuteTransaction({
        transaction: tx,
        chain: `sui:${network}`,
      });

      setTxStatus(`Open success: ${result.digest}`);

      await refreshOwnedLootBoxes();
      await refreshHistory();
    } catch (e) {
      const message = e instanceof Error ? e.message : "Open failed";
      setError(message);
      setTxStatus("Open failed");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="container">
      <h1>🎁 Loot Box System</h1>
      <ConnectButton />
      {account && <p className="loading">Wallet: {account.address}</p>}

      {!isConfigured && (
        <p className="loading">Set VITE_PACKAGE_ID and VITE_GAMECONFIG_ID to enable on-chain calls.</p>
      )}

      {error && <p className="loading">{error}</p>}
      {txStatus && <p className="loading">{txStatus}</p>}

      <div className="buttons">
        <button onClick={() => void buyLootBox()} disabled={loading || !account}>
          Buy Loot Box
        </button>
        <button onClick={() => void openLootBox()} disabled={!hasLootBox || loading || !account}>
          Open Loot Box
        </button>
      </div>

      {loading && <p className="loading">Opening...</p>}

      {currentItem && !loading && (
        <div className={`result ${currentItem.rarity.toLowerCase()}`}>
          <h2>{currentItem.rarity}</h2>
          <p>{currentItem.name}</p>
          <p>Power: {currentItem.power}</p>
        </div>
      )}

      <h3>📜 History</h3>

      <div className="history">
        {history.map((item) => (
          <div
            key={item.id}
            className={`card ${item.rarity.toLowerCase()}`}
          >
            <p>{item.name}</p>
            <p>{item.rarity}</p>
            <small>Power: {item.power}</small>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;