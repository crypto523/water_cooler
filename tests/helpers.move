#[test_only]
module galliun::helpers {
    use sui::test_scenario::{Self as ts, next_tx, Scenario};
    use sui::clock::{Self};
    use std::string::{String};

    use galliun::cooler_factory::{init_for_cooler};
    use galliun::mint::{init_for_mint};
    use galliun::water_cooler::{Self, init_for_water};

    const ADMIN: address = @0xA;

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
        size: u64,
        addr: address,
    ) {
        water_cooler::create_water_cooler(
            name, 
            description, 
            image_url, 
            size, 
            addr, 
            ts::ctx(ts)
        );
    }
}