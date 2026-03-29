import { useState } from "react";
import "./App.css";

type Item = {
  id: number;
  rarity: "Common" | "Rare" | "Epic" | "Legendary";
  power: number;
};

function App() {
  const [hasLootBox, setHasLootBox] = useState<boolean>(false);
  const [currentItem, setCurrentItem] = useState<Item | null>(null);
  const [history, setHistory] = useState<Item[]>([]);
  const [loading, setLoading] = useState<boolean>(false);

  const rarities: Item["rarity"][] = [
    "Common",
    "Rare",
    "Epic",
    "Legendary",
  ];

  const buyLootBox = (): void => {
    setHasLootBox(true);
    alert("Loot Box Purchased!");
  };

  const openLootBox = (): void => {
    if (!hasLootBox) {
      alert("No loot box!");
      return;
    }

    setLoading(true);

    setTimeout(() => {
      const rarity =
        rarities[Math.floor(Math.random() * rarities.length)];

      const power = Math.floor(Math.random() * 50) + 1;

      const item: Item = {
        id: Date.now(),
        rarity,
        power,
      };

      setCurrentItem(item);
      setHistory((prev) => [item, ...prev]);
      setHasLootBox(false);
      setLoading(false);
    }, 1500);
  };

  return (
    <div className="container">
      <h1>🎁 Loot Box System</h1>

      <div className="buttons">
        <button onClick={buyLootBox}>Buy Loot Box</button>
        <button onClick={openLootBox} disabled={!hasLootBox}>
          Open Loot Box
        </button>
      </div>

      {loading && <p className="loading">Opening...</p>}

      {currentItem && !loading && (
        <div className={`result ${currentItem.rarity.toLowerCase()}`}>
          <h2>{currentItem.rarity}</h2>
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
            <p>{item.rarity}</p>
            <small>Power: {item.power}</small>
          </div>
        ))}
      </div>
    </div>
  );
}

export default App;