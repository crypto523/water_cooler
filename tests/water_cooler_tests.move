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

    use std::vector::{Self};
    use std::string::{Self, String};

    use galliun::helpers::{Self, init_test_helper};
    use galliun::water_cooler::{Self, WaterCooler, WaterCoolerAdminCap, MizuNFT};
    use galliun::cooler_factory::{Self, CoolerFactory, FactoryOwnerCap};
    use galliun::mint::{Self, Mint, MintAdminCap, MintSettings, MintWarehouse, WhitelistTicket};


    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    const TEST_ADDRESS2: address = @0xC;

    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );
            // check the balance 
            assert_eq(cooler_factory.get_balance(), 100);

            ts::return_shared(cooler_factory);
        };

        next_tx(scenario, ADMIN);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let cap = ts::take_from_sender<FactoryOwnerCap>(scenario);
            // admin can claim fee which is 100 
            let coin_ = cooler_factory::claim_fee(&cap, &mut cooler_factory, ts::ctx(scenario));
            // it should be equal to 100
            assert_eq(coin_.value(), 100);
            // transfer it to admin address 
            transfer::public_transfer(coin_, ADMIN);
     
            ts::return_to_sender(scenario, cap);
            ts::return_shared(cooler_factory);
        };
        // set the new fee 
        next_tx(scenario, ADMIN);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let cap = ts::take_from_sender<FactoryOwnerCap>(scenario);
          
            let new_fee_rate: u64 = 90;
            cooler_factory::update_fee(&cap, &mut cooler_factory, new_fee_rate);
            assert_eq(cooler_factory.get_fee(), new_fee_rate);

            ts::return_to_sender(scenario, cap);
            ts::return_shared(cooler_factory);
        };

        // init WaterCooler. the number count to 1. So it is working. 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let water_cooler_admin_cap = ts::take_from_sender<WaterCoolerAdminCap>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, water_cooler_admin_cap);
        };
        // check that does user has MizuNFT ?
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let nft = ts::take_from_sender<MizuNFT>(scenario);
            ts::return_to_sender(scenario, nft);
        };

        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let water_cooler = ts::take_shared<WaterCooler>(scenario);

            // Check Nft Created
            assert!(ts::has_most_recent_for_sender<MizuNFT>(scenario), 0);
            assert!(water_cooler.is_initialized() == true, 0);
            // the number of supply should be stay as 150. 
            assert_eq(water_cooler.supply(), 150);
            // in the vec_map the nft ID 's are must be 150. 
            assert_eq(water_cooler.get_nfts_num(), 150);
            ts::return_shared(water_cooler);
        };

        ts::end(scenario_test);
    }

    #[test]
    public fun test_cooler_factory() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );
            // check the balance 
            assert_eq(cooler_factory.get_balance(), 100);

            ts::return_shared(cooler_factory);
        };

        // init WaterCooler. the number count to 1. So it is working. 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let water_cooler_admin_cap = ts::take_from_sender<WaterCoolerAdminCap>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, water_cooler_admin_cap);
        };

        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            // Check Nft Created
            assert!(ts::has_most_recent_for_sender<MizuNFT>(scenario), 0);
            assert!(water_cooler.is_initialized() == true, 0);
            // the number of supply should be stay as 150. 
            assert_eq(water_cooler.supply(), 150);
            // in the vec_map the nft ID 's are must be 150. 
            assert_eq(water_cooler.get_nfts_num(), 150);
            ts::return_shared(water_cooler);
        };
        // we can push MizuNFT into the warehouse
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<MintAdminCap>(scenario);
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            let mut mint_warehouse = ts::take_shared<MintWarehouse>(scenario);
            let nft = ts::take_from_sender<MizuNFT>(scenario);
            let mut vector_mizu = vector::empty<MizuNFT>();
            vector_mizu.push_back(nft);

            mint::add_to_mint_warehouse(
                &mint_cap,
                &water_cooler,
                vector_mizu,
                &mut mint_warehouse
            );
            // the nft's length should be equal to 1 
            assert_eq(mint::get_mintwarehouse_length(&mint_warehouse), 1);
    
            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_warehouse);
            ts::return_shared(water_cooler);
        };



        ts::end(scenario_test);
    }
}
