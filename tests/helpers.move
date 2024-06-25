#[test_only]
module galliun::helpers {
    use sui::test_scenario::{Self as ts, next_tx,Scenario};
    
    use galliun::cooler_factory::{init_for_cooler};
    use galliun::mint::{init_for_mint};
    use galliun::water_cooler::{init_for_water};

    const ADMIN: address = @0xA;

    public fun init_test_helper() : Scenario {
       let mut scenario_val = ts::begin(ADMIN);
       let scenario = &mut scenario_val;
 
       {
        init_for_cooler(ts::ctx(scenario));
       };
       {
        init_for_mint(ts::ctx(scenario));
       };
       {
        init_for_water(ts::ctx(scenario));
       };
       scenario_val
    }
}