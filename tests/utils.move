#[test_only]
module galliun::test_utils {
    use std::{
        string::{Self, String}
    };
    use sui::{
        test_scenario::{Self as ts, Scenario},
        clock::{Self, Clock},
    };
    use galliun::{
        cooler_factory,
        water_cooler::{Self, WaterCooler},
        mint
    };

    const OWNER: address = @0xBABE;

    // hot potato holding the state
    public struct World {
        scenario: Scenario,
        water_cooler: WaterCooler,
        clock: Clock,
    }

    public struct Obj has key, store { id: UID }

    // === Utils ===

    public fun start_world(): World {
        let mut scenario = ts::begin(OWNER);
        // init modules
        cooler_factory::init_for_testing(scenario.ctx());
        water_cooler::init_for_testing(scenario.ctx());
        mint::init_for_testing(scenario.ctx());

        let clock = clock::create_for_testing(scenario.ctx());
        clock::share_for_testing(clock);
        scenario.next_tx(OWNER);

        // get shared objects
        let water_cooler = ts::take_shared<WaterCooler>(&scenario);
        let clock = ts::take_shared<Clock>(&scenario);

        World { scenario, water_cooler, clock }
    }

    public fun forward_world(world: &mut World, addr: address) {
        world.scenario.next_tx(addr);
    }

    public fun end_world(world: World) {
        let World { scenario, water_cooler, clock } = world;
        ts::return_shared(water_cooler);
        ts::return_shared(clock);
        ts::end(scenario);
    }

    public fun assert_most_recent_for_sender<T: key>(world: &World) {
        assert!(ts::has_most_recent_for_sender<T>(&world.scenario));
    }

    // === Water cooler ===

    public fun create_water_cooler(
        world: &mut World, 
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
            world.scenario.ctx()
        );
    }
}