module loot_box::loot_box_tests {

    use loot_box::loot_box;
    use sui::coin;
    use sui::sui::SUI;
    use sui::tx_context;

    #[test]
    fun test_rarity_common() {
        let rarity = loot_box::rarity_from_roll_for_test(10, 60, 25, 12);
        assert!(rarity == 0, 1);
    }

    #[test]
    fun test_rarity_legendary() {
        let rarity = loot_box::rarity_from_roll_for_test(99, 60, 25, 12);
        assert!(rarity == 3, 2);
    }

    #[test]
    fun test_full_flow_mock() {
        let mut ctx = tx_context::dummy();

        // Init with one-time publisher capability.
        let publisher = loot_box::publisher_for_testing(&mut ctx);
        loot_box::init_game(publisher, &mut ctx);

        // Mock config for deterministic local testing.
        let mut config = loot_box::config_for_testing(0, @0x1, &mut ctx);

        // Purchase mock loot box with zero-value SUI coin.
        let payment = coin::zero<SUI>(&mut ctx);
        let lootbox = loot_box::purchase_loot_box_mock(&mut config, payment, &mut ctx);

        // Open with deterministic roll in common range.
        let item = loot_box::open_loot_box_mock(lootbox, &config, 10, &mut ctx);

        let (rarity, power) = loot_box::get_item_stats(&item);
        assert!(rarity == 0, 3);
        assert!(power == 1, 4);

        loot_box::burn_item(item);
        assert!(loot_box::treasury_for_testing(&config) == 0, 5);
        loot_box::destroy_config_for_testing(config);
    }
}