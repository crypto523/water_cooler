#[test_only]
module galliun::water_cooler_tests {
  use sui::test_scenario;

  use galliun::water_cooler::{Self as water_cooler, WaterCooler, WaterCoolerAdminCap, MizuNFT};

  // === Users ===
  const USER: address = @0xab;
    
  #[test]
  fun test_water_cooler() {

    let mut scenario_val = test_scenario::begin(USER);
    let scenario = &mut scenario_val;

    // === Test Init ===
    test_scenario::next_tx(scenario, USER);
    {
      water_cooler::init_for_testing(test_scenario::ctx(scenario))
    };

    // === Test Create Water Cooler ===
    test_scenario::next_tx(scenario, USER);
    {
      let name = b"watercoolername".to_string();
      let description = b"some desc".to_string();
      let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
      let size = 150;

      water_cooler::createWaterCooler(name, description, image_url, size, USER, test_scenario::ctx(scenario));
    };
    test_scenario::next_tx(scenario, USER);
    {
      assert!(test_scenario::has_most_recent_for_sender<WaterCooler>(scenario), 0);
    };

    // === Test Admin Water Cooler Init ===
    test_scenario::next_tx(scenario, USER);
    {
      let mut water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);
      let water_cooler_admin_cap = test_scenario::take_from_sender<WaterCoolerAdminCap>(scenario);

      water_cooler::admin_initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, test_scenario::ctx(scenario));

      test_scenario::return_to_sender(scenario, water_cooler);
      test_scenario::return_to_sender(scenario, water_cooler_admin_cap);
    };
      test_scenario::next_tx(scenario, USER);
    {
      let water_cooler = test_scenario::take_from_sender<WaterCooler>(scenario);

      // Check Nft Created
      assert!(test_scenario::has_most_recent_for_sender<MizuNFT>(scenario), 0);
      assert!(water_cooler.is_initialized() == true, 0);     

      test_scenario::return_to_sender(scenario, water_cooler);
    };

    test_scenario::end(scenario_val);
  }
}
