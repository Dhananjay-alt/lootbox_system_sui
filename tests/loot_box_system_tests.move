module loot_box::loot_box_tests {

    use loot_box::loot_box;

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
}