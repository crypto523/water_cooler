module galliun::cooler_factory {
    // === Imports ===

    use std::string::{String};
    use sui::{
        sui::SUI,
        coin::{Coin}
    };
    use galliun::{
        water_cooler::{Self},
        orchestrator::{Self},
        settings::{Self},
        warehouse::{Self},
    };

    // === Errors ===

    const EInsufficientBalance: u64 = 0;

    // === Structs ===

    // shared object collecting fees from generated water coolers
    public struct CoolerFactory has key {
        id: UID,
        fee: u64,
        treasury: address,
        cooler_list: vector<ID>
    }

    public struct FactoryOwnerCap has key, store { id: UID }

    // === Public mutative functions ===

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            FactoryOwnerCap { id: object::new(ctx) }, 
            ctx.sender()
        );
        
        transfer::share_object(
            CoolerFactory {
                id: object::new(ctx),
                fee: 100_000_000,
                treasury: @galliun_treasury,
                cooler_list: vector::empty()
            }
        );
    }

    public entry fun buy_water_cooler(
        self: &mut CoolerFactory, 
        payment: Coin<SUI>,
        name: String, 
        description: String, 
        image_url: String,
        placeholder_image_url: String,
        supply: u64, 
        treasury: address, 
        ctx: &mut TxContext
    ) {
        assert!(payment.value() == self.fee, EInsufficientBalance);

                // Create a Mint distributer and give it to the buyer. 
        // We do this here to avoid create a dependency circle 
        // with the Mint and water_cooler modules
        // let settings = settings::new(waterCoolerID, ctx);
        // let warehouse = warehouse::new(waterCoolerID, ctx);

        let (settings, warehouse) = orchestrator::create_mint_distributer(ctx);

        

        // Create a WaterCooler and give it to the buyer
        let waterCoolerID = water_cooler::create_water_cooler(
            name,
            description,
            image_url,
            placeholder_image_url,
            supply,
            treasury,
            object::id(&settings),
            object::id(&warehouse),
            ctx
        );

        settings::transfer_setting(settings, ctx);
        warehouse::transfer_warehouse(warehouse, ctx);



        self.cooler_list.push_back(waterCoolerID);

        // Transfer fees to treasury
        self.send_fees(payment);
    }

    
    public entry fun update_fee(_: &FactoryOwnerCap, self: &mut CoolerFactory, fee: u64) {
        self.fee = fee;
    }
   
    public fun get_fee(self: &CoolerFactory) : u64 {
        self.fee
    }

    public(package) fun send_fees(
        self: &CoolerFactory,
        coins: Coin<SUI>
    ) {
        transfer::public_transfer(coins, self.treasury);
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_cooler(ctx: &mut TxContext) {
        init(ctx);
    }
}
