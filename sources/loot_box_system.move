module loot_box::loot_box {

    use sui::object::{UID};
    use sui::tx_context::{TxContext};
    use sui::tx_context;
    use sui::object;
    use sui::transfer;
    use sui::coin;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::random;
    use sui::event;
    use sui::package;

    const E_INVALID_PUBLISHER: u64 = 2;

    /// One-time witness used to claim a single Publisher capability.
    public struct LOOT_BOX has drop {}

    /// -------------------------------
    /// STRUCTS
    /// -------------------------------

    public struct AdminCap has key {
        id: UID,
    }

    public struct GameConfig has key {
        id: UID,
        treasury: u64,
        treasury_owner: address,
        initialized: bool,
        price: u64,
        common_weight: u8,
        rare_weight: u8,
        epic_weight: u8,
        legendary_weight: u8,
    }

    public struct LootBox has key {
        id: UID,
    }

    public struct GameItem has key, store {
        id: UID,
        rarity: u8,
        power: u8,
        name: vector<u8>,
    }

    public struct LootBoxOpenedEvent has copy, drop {
        item_id: address,
        rarity: u8,
        power: u8,
        name: vector<u8>,
        owner: address,
    }

    public struct LootBoxPurchasedEvent has copy, drop {
        buyer: address,
        price: u64,
    }

    fun rarity_from_roll(rand: u8, common_weight: u8, rare_weight: u8, epic_weight: u8): u8 {
        if (rand < common_weight) {
            0
        } else if (rand < common_weight + rare_weight) {
            1
        } else if (rand < common_weight + rare_weight + epic_weight) {
            2
        } else {
            3
        }
    }

    fun pick_cs2_item_name(rarity: u8, gen: &mut random::RandomGenerator): vector<u8> {
        if (rarity == 0) {
            let i = random::generate_u8_in_range(gen, 0, 4);
            if (i == 0) {
                b"P250 Sand Dune"
            } else if (i == 1) {
                b"Glock-18 Candy Apple"
            } else if (i == 2) {
                b"MP9 Sand Dashed"
            } else if (i == 3) {
                b"UMP-45 Urban DDPAT"
            } else {
                b"Nova Predator"
            }
        } else if (rarity == 1) {
            let i = random::generate_u8_in_range(gen, 0, 4);
            if (i == 0) {
                b"AK-47 Redline"
            } else if (i == 1) {
                b"M4A4 Desolate Space"
            } else if (i == 2) {
                b"AWP Fever Dream"
            } else if (i == 3) {
                b"USP-S Cortex"
            } else {
                b"FAMAS Mecha Industries"
            }
        } else if (rarity == 2) {
            let i = random::generate_u8_in_range(gen, 0, 4);
            if (i == 0) {
                b"M4A1-S Printstream"
            } else if (i == 1) {
                b"AK-47 Asiimov"
            } else if (i == 2) {
                b"AWP Wildfire"
            } else if (i == 3) {
                b"USP-S Kill Confirmed"
            } else {
                b"Desert Eagle Printstream"
            }
        } else {
            let i = random::generate_u8_in_range(gen, 0, 4);
            if (i == 0) {
                b"AWP Dragon Lore"
            } else if (i == 1) {
                b"M4A4 Howl"
            } else if (i == 2) {
                b"AK-47 Fire Serpent"
            } else if (i == 3) {
                b"Karambit Doppler"
            } else {
                b"Sport Gloves Vice"
            }
        }
    }

    #[test_only]
    public fun rarity_from_roll_for_test(rand: u8, common_weight: u8, rare_weight: u8, epic_weight: u8): u8 {
        rarity_from_roll(rand, common_weight, rare_weight, epic_weight)
    }

    fun init(witness: LOOT_BOX, ctx: &mut TxContext) {
        package::claim_and_keep<LOOT_BOX>(witness, ctx);
    }

    /// -------------------------------
    /// INIT GAME
    /// -------------------------------

    public entry fun init_game(publisher: package::Publisher, ctx: &mut TxContext) {
        assert!(package::from_module<LOOT_BOX>(&publisher), E_INVALID_PUBLISHER);

        let admin = AdminCap {
            id: object::new(ctx),
        };

        let config = GameConfig {
            id: object::new(ctx),
            treasury: 0,
            treasury_owner: tx_context::sender(ctx),
            initialized: true,
            price: 100,
            common_weight: 60,
            rare_weight: 25,
            epic_weight: 12,
            legendary_weight: 3,
        };

        package::burn_publisher(publisher);
        transfer::transfer(admin, tx_context::sender(ctx));
        transfer::share_object(config);
    }

    /// -------------------------------
    /// PURCHASE LOOT BOX
    /// -------------------------------

    public entry fun purchase_loot_box(
        config: &mut GameConfig,
        mut payment: Coin<SUI>,
        ctx: &mut TxContext
    ) {
        assert!(config.initialized, 0);
        let value = coin::value(&payment);
        assert!(value >= config.price, 0);

        event::emit(LootBoxPurchasedEvent {
            buyer: tx_context::sender(ctx),
            price: config.price,
        });

        let charged = coin::split(&mut payment, config.price, ctx);
        transfer::public_transfer(charged, config.treasury_owner);

        if (coin::value(&payment) > 0) {
            transfer::public_transfer(payment, tx_context::sender(ctx));
        } else {
            coin::destroy_zero(payment);
        };

        config.treasury = config.treasury + config.price;

        let lootbox = LootBox {
            id: object::new(ctx),
        };

        transfer::transfer(lootbox, tx_context::sender(ctx));
    }

    public entry fun update_rarity_weights(
        _admin: &AdminCap,
        config: &mut GameConfig,
        common: u8,
        rare: u8,
        epic: u8,
        legendary: u8
    ) {
        assert!(
            (common as u64) + (rare as u64) + (epic as u64) + (legendary as u64) == 100,
            1
        );

        config.common_weight = common;
        config.rare_weight = rare;
        config.epic_weight = epic;
        config.legendary_weight = legendary;
    }

    /// -------------------------------
    /// OPEN LOOT BOX (CORE)
    /// -------------------------------

    public entry fun open_loot_box(
        lootbox: LootBox,
        config: &GameConfig,
        r: &random::Random,
        ctx: &mut TxContext
    ) {
        assert!(config.initialized, 0);
        // Create randomness generator from shared Random object
        let mut gen = random::new_generator(r, ctx);
        let rand = random::generate_u8_in_range(&mut gen, 0, 99);

        // Determine rarity
        let rarity = rarity_from_roll(
            rand,
            config.common_weight,
            config.rare_weight,
            config.epic_weight,
        );

        // Assign power based on rarity
        let power = if (rarity == 0) {
            random::generate_u8_in_range(&mut gen, 1, 10)
        } else if (rarity == 1) {
            random::generate_u8_in_range(&mut gen, 11, 25)
        } else if (rarity == 2) {
            random::generate_u8_in_range(&mut gen, 26, 40)
        } else {
            random::generate_u8_in_range(&mut gen, 41, 50)
        };

        let name = pick_cs2_item_name(rarity, &mut gen);

        let item = GameItem {
            id: object::new(ctx),
            rarity,
            power,
            name: copy name,
        };

        let item_id = object::id(&item);
        event::emit(LootBoxOpenedEvent {
            item_id: object::id_to_address(&item_id),
            rarity: rarity,
            power: power,
            name,
            owner: tx_context::sender(ctx),
        });

        // Burn loot box
        let LootBox { id } = lootbox;
        object::delete(id);

        // Send NFT to user
        transfer::transfer(item, tx_context::sender(ctx));
    }

    /// -------------------------------
    /// VIEW FUNCTION
    /// -------------------------------

    public fun get_item_stats(item: &GameItem): (u8, u8) {
        (item.rarity, item.power)
    }

    public fun get_item_name(item: &GameItem): vector<u8> {
        copy item.name
    }

    #[test_only]
    public fun publisher_for_testing(ctx: &mut TxContext): package::Publisher {
        package::claim<LOOT_BOX>(LOOT_BOX {}, ctx)
    }

    #[test_only]
    public fun config_for_testing(price: u64, treasury_owner: address, ctx: &mut TxContext): GameConfig {
        GameConfig {
            id: object::new(ctx),
            treasury: 0,
            treasury_owner,
            initialized: true,
            price,
            common_weight: 60,
            rare_weight: 25,
            epic_weight: 12,
            legendary_weight: 3,
        }
    }

    #[test_only]
    public fun treasury_for_testing(config: &GameConfig): u64 {
        config.treasury
    }

    #[test_only]
    public fun destroy_config_for_testing(config: GameConfig) {
        let GameConfig {
            id,
            treasury: _,
            treasury_owner: _,
            initialized: _,
            price: _,
            common_weight: _,
            rare_weight: _,
            epic_weight: _,
            legendary_weight: _,
        } = config;
        object::delete(id);
    }

    #[test_only]
    public fun purchase_loot_box_mock(config: &mut GameConfig, payment: Coin<SUI>, ctx: &mut TxContext): LootBox {
        let value = coin::value(&payment);
        assert!(value >= config.price, 0);
        coin::destroy_zero(payment);

        config.treasury = config.treasury + config.price;

        LootBox {
            id: object::new(ctx),
        }
    }

    #[test_only]
    public fun open_loot_box_mock(
        lootbox: LootBox,
        config: &GameConfig,
        rand: u8,
        ctx: &mut TxContext,
    ): GameItem {
        let rarity = rarity_from_roll(
            rand,
            config.common_weight,
            config.rare_weight,
            config.epic_weight,
        );

        let power = if (rarity == 0) {
            1
        } else if (rarity == 1) {
            11
        } else if (rarity == 2) {
            26
        } else {
            41
        };

        let name = if (rarity == 0) {
            b"P250 Sand Dune"
        } else if (rarity == 1) {
            b"AK-47 Redline"
        } else if (rarity == 2) {
            b"M4A1-S Printstream"
        } else {
            b"AWP Dragon Lore"
        };

        let item = GameItem {
            id: object::new(ctx),
            rarity,
            power,
            name,
        };

        let LootBox { id } = lootbox;
        object::delete(id);

        item
    }

    /// -------------------------------
    /// TRANSFER ITEM
    /// -------------------------------

    public entry fun transfer_item(
        item: GameItem,
        recipient: address
    ) {
        transfer::transfer(item, recipient);
    }

    /// -------------------------------
    /// BURN ITEM
    /// -------------------------------

    public entry fun burn_item(item: GameItem) {
        let GameItem { id, rarity: _, power: _, name: _ } = item;
        object::delete(id);
    }
}