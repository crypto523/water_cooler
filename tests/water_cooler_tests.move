#[test_only]
module galliun::water_cooler_test {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::coin::{Self, Coin, CoinMetadata, mint_for_testing};
    use sui::sui::SUI;
    use sui::tx_context::TxContext;
    use sui::test_utils::{assert_eq};
    use sui::clock::{Self, Clock};
    use sui::transfer::{Self};
    use sui::balance::{Self, Balance};

    use std::vector;
    use std::string::{Self, String};

    use galliun::helpers::{Self, init_test_helper};
    
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;

        next_tx(scenario, TEST_ADDRESS1);
        {
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let size = 150;
            helpers::create_water_cooler(scenario, name, description, image_url, size, TEST_ADDRESS1);
        };
        
    

        ts::end(scenario_test);
    }
}