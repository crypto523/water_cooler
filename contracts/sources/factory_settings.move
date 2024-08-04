/// This object was created to avoid a circular dependency
/// between the cooler factory and the orchestrator
/// This object manages the fees that will be paid at capsule mint
/// 

module galliun::factory_settings {
    // === Imports ===

    use sui::{
        sui::SUI,
        coin::{Coin}
    };

    // === Errors ===


    // === Structs ===

    // shared object collecting fees from generated water coolers
    public struct FactorySetings has key {
        id: UID,
        mint_fee: u64,
        treasury: address
    }

    public struct FactorySettingsOwnerCap has key, store { id: UID }

    // === Public mutative functions ===

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            FactorySettingsOwnerCap { id: object::new(ctx) }, 
            ctx.sender()
        );
        
        transfer::share_object(
            FactorySetings {
                id: object::new(ctx),
                mint_fee: 100_000,
                treasury: @galliun_treasury,
            }
        );
    }

    
    public entry fun update_mint_fee(_: &FactorySettingsOwnerCap, self: &mut FactorySetings, fee: u64) {
        self.mint_fee = fee;
    }
    
    public fun get_mint_fee(self: &FactorySetings) : u64 {
        self.mint_fee
    }

    public(package) fun send_fees(
        self: &FactorySetings,
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
