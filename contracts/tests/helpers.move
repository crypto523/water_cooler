#[test_only]
module galliun::helpers {
    // === Imports ===
    use std::string::{String};
    use sui::{
        test_scenario::{Self as ts, Scenario},
        clock::{Self}
    };    
    use galliun::{
        cooler_factory::{init_for_cooler},
        mint::{init_for_mint},
        water_cooler::{Self, init_for_water}
    };

    // === Constants ===
    const ADMIN: address = @0xA;

    // === Test functions ===
    public fun init_test_helper() : Scenario {
       let mut scenario_val = ts::begin(ADMIN);
       let scenario = &mut scenario_val;
 
       {
        init_for_cooler(ts::ctx(scenario));
        let clock = clock::create_for_testing(scenario.ctx());
        clock::share_for_testing(clock);
       };
       {
        init_for_mint(ts::ctx(scenario));
       };
       {
        init_for_water(ts::ctx(scenario));
       };
       scenario_val
    }

    public fun create_water_cooler(
        ts: &mut Scenario,
        name: String,
        description: String,
        image_url: String,
        placeholder_image_url: String,
        size: u64,
        addr: address,
        mint_setting_id: ID,
         mint_warehouse_id: ID,
    ) {
        water_cooler::create_water_cooler(
            name,
            description,
            image_url,
            placeholder_image_url,
            size,
            addr,
            mint_setting_id,
            mint_warehouse_id,
            ts::ctx(ts)
        );
    }
}