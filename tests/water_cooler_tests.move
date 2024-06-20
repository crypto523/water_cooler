#[test_only]
module galliun::water_cooler_tests {
    // use sui::{
    //     test_scenario::{Self as ts, Scenario},
    // };
    use galliun::{
        test_utils as utils,
        water_cooler::WaterCooler,
    };

    // === Users ===
    const USER: address = @0xab;
    
    #[test]
    fun test_water_cooler() {
        let mut world = utils::start_world();

        // create WaterCooler
        world.forward_world(USER);
        let name = b"watercoolername".to_string();
        let description = b"some desc".to_string();
        let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
        let size = 150;
        utils::create_water_cooler(&mut world, name, description, image_url, size, USER);

        world.forward_world(USER);
        utils::assert_most_recent_for_sender<WaterCooler>(&world);

        // init WaterCooler
        // test_scenario::next_tx(scenario, USER);
        // {
        // let mut water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
        // let water_cooler_admin_cap = test_scenario::take_from_sender<WaterCoolerAdminCap>(scenario);

        // water_cooler::admin_initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, test_scenario::ctx(scenario));

        // test_scenario::return_to_sender(scenario, water_cooler);
        // test_scenario::return_to_sender(scenario, water_cooler_admin_cap);
        // };
        // test_scenario::next_tx(scenario, USER);
        // {
        // let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);

        // // Check Nft Created
        // assert!(test_scenario::has_most_recent_for_sender<MizuNFT>(scenario), 0);
        // assert!(water_cooler.is_initialized() == true, 0);     

        // test_scenario::return_to_sender(scenario, water_cooler);
        // };

        world.end_world();
    }

    // #[test]
    // fun test_mint() {

    //     let mut scenario_val = test_scenario::begin(USER);
    //     let scenario = &mut scenario_val;

    //     // === Test Init ===
    //     test_scenario::next_tx(scenario, USER);
    //     {
    //         mint::init_for_testing(test_scenario::ctx(scenario))
    //     };

    //     // === Test Create Mint Distributer ===
    //     test_scenario::next_tx(scenario, USER);
    //     {
    //         mint::create_mint_distributer(test_scenario::ctx(scenario));
    //     };

        /*// === Test Public Mint ===
        test_scenario::next_tx(scenario, USER);
        {
            let mut warehouse = test_scenario::take_shared<MintWarehouse>(scenario);
            let mut settings = test_scenario::take_shared<MintSettings>(scenario);
            let mint_admin_cap = test_scenario::take_from_sender<MintAdminCap>(scenario);
            let payment = coin::mint_for_testing<SUI>(100, test_scenario::ctx(scenario));
            let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
            let nfts = test_scenario::take_from_sender<MizuNFT>(scenario);

            mint::admin_add_to_mint_warehouse(&mint_admin_cap, &water_cooler, &mut vector[nfts], &mut warehouse, test_scenario::ctx(scenario));

            // set mint price at 10 sui
            mint::admin_set_mint_price(&mint_admin_cap, 100, &mut settings, test_scenario::ctx(scenario));
            // test public mint at 10sui payment
            mint::public_mint(payment, &mut warehouse, &settings, test_scenario::ctx(scenario));

            test_scenario::return_shared(warehouse);
            test_scenario::return_shared(settings);
            test_scenario::return_to_sender(scenario, mint_admin_cap);
            test_scenario::return_to_sender(scenario, water_cooler);
        };
        
        // Test Destroy Mint Warehouse
        test_scenario::next_tx(scenario, USER);
        {
            let warehouse = test_scenario::take_shared<MintWarehouse>(scenario);
            let mint_admin_cap = test_scenario::take_from_sender<MintAdminCap>(scenario);

            mint::admin_destroy_mint_warehouse(&mint_admin_cap, warehouse, test_scenario::ctx(scenario));

            test_scenario::return_to_sender(scenario, mint_admin_cap);
        }; */
    //     test_scenario::end(scenario_val);
    // }
}
