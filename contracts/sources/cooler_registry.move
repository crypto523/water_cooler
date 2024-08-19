module galliun::cooler_registry {
    // === Imports ===

    use std::string::{String};
    use sui::{
        sui::SUI,
        coin::{Coin},
        table::{Self, Table}
    };
    use galliun::water_cooler::{WaterCooler};

    // === Errors ===

    const EInsufficientBalance: u64 = 0;
    const NotTheOwner: u64 = 1;
    const NameAlreadyRegistered: u64 = 2;

    // === Structs ===

    // shared object where creators register their Water cooler
    // For it to be displayed on the launchpad
    public struct CoolerRegistry has key {
        id: UID,
        fee: u64,
        name_to_id: Table<String, ID>,
        treasury: address,
    }

    public struct CoolerRegistryOwnerCap has key, store { id: UID }

    // === Public mutative functions ===

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            CoolerRegistryOwnerCap { id: object::new(ctx) }, 
            ctx.sender()
        );
        
        transfer::share_object(
            CoolerRegistry {
                id: object::new(ctx),
                fee: 100_000_000,
                name_to_id: table::new(ctx),
                treasury: @galliun_treasury,
            }
        );
    }

    public entry fun register_water_cooler(
        self: &mut CoolerRegistry, 
        payment: Coin<SUI>,
        waterCooler: &WaterCooler,
        name: String,
        ctx: &mut TxContext
    ) {
        assert!(payment.value() == self.fee, EInsufficientBalance);
        assert!(waterCooler.owner() == ctx.sender(), NotTheOwner);
        assert!(!self.name_to_id.contains(name), NameAlreadyRegistered);

        self.name_to_id.add(name, object::id(waterCooler));

        // Transfer fees to treasury
        self.send_fees(payment);
    }

    
    public entry fun update_fee(_: &CoolerRegistryOwnerCap, self: &mut CoolerRegistry, fee: u64) {
        self.fee = fee;
    }
   
    public fun get_fee(self: &CoolerRegistry) : u64 {
        self.fee
    }
    
    public fun get_water_cooler(self: &CoolerRegistry, name: String) : ID {
        self.name_to_id[name]
    }

    public(package) fun send_fees(
        self: &CoolerRegistry,
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
