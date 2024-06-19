module galliun::cooler_factory {
    // === Imports ===

    use std::string::{String};
    use sui::{
        sui::SUI,
        coin::Coin,
        balance::{Self, Balance},
    };
    use galliun::water_cooler::{Self};
    use galliun::mint::{Self};

    // === Errors ===

    const EInsufficientBalance: u64 = 0;

    // === Structs ===

    public struct CoolerFactory has key {
        id: UID,
        price: u64,
        balance: Balance<SUI>,
        owner: address
    }

    public struct FactoryOwnerCap has key { id: UID }

    // === Public mutative functions ===

    fun init(ctx: &mut TxContext) {
        transfer::transfer(
            FactoryOwnerCap { id: object::new(ctx) }, 
            ctx.sender()
        );
        
        transfer::share_object(
            CoolerFactory {
                id: object::new(ctx),
                price: 100,
                balance: balance::zero(),
                owner: ctx.sender()
            }
        );
    }

    public entry fun buy_water_cooler(
        factory: &mut CoolerFactory, 
        payment: Coin<SUI>,
        name: String, 
        description: String, 
        image_url: String,
        size: u16, 
        treasury: address, 
        ctx: &mut TxContext
    ) {
        assert!(payment.value() == factory.price, EInsufficientBalance);

        // Create a WaterCooler and give it to the buyer
        water_cooler::createWaterCooler(name, description, image_url, size, treasury, ctx);

        // Create a Mint distributer and give it to the buyer
        mint::create_mint_distributer(ctx);

        // Send payment to the owner of the Factory
        transfer::public_transfer(payment, factory.owner);
    }

    
    public entry fun update_price(_: &FactoryOwnerCap, factory: &mut CoolerFactory, price: u64) {
        factory.price = price;
    }
    
    public entry fun update_owner(_: &FactoryOwnerCap, factory: &mut CoolerFactory, owner: address) {
        factory.owner = owner;
    }
}
