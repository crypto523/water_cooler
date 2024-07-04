#[test_only]
module galliun::test_water_cooler {
    // === Imports ===
    use sui::{
        test_scenario::{Self as ts, next_tx},
        coin::{Self},
        sui::SUI,
        test_utils::{assert_eq},
    };
    use galliun::{
        helpers::{init_test_helper},
        water_cooler::{Self, WaterCooler, WaterCoolerAdminCap},
        mizu_nft::{MizuNFT},
        cooler_factory::{Self, CoolerFactory, FactoryOwnerCap},
        collection::{Collection},
        registry::{Registry},
    };

    // === Constants ===
    const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    // const TEST_ADDRESS2: address = @0xC;

    // === Test functions ===
    #[test]
    public fun test_water_cooler() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
        // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let placeholder_image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                placeholder_image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );
            // check the balance 
            assert_eq(cooler_factory.get_balance(), 100_000_000);

            ts::return_shared(cooler_factory);
        };

        next_tx(scenario, ADMIN);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let cap = ts::take_from_sender<FactoryOwnerCap>(scenario);
            
            // confirm correct balance is 100_000_000 
            let balance_ = cooler_factory::get_balance(&cooler_factory);
            // it should be equal to 100_000_000
            assert_eq(balance_, 100_000_000);
            // admin can claim fee which is 100_000_000 
            cooler_factory::claim_fee(&cap, &mut cooler_factory, ts::ctx(scenario));
     
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
            let mut registry = ts::take_from_sender<Registry>(scenario);
            let collection = ts::take_from_sender<Collection>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, &mut registry, &collection, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, collection);
            ts::return_to_sender(scenario, registry);
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
}