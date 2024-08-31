module galliun::warehouse {
  // === Imports ===
    use sui::{
        // coin::Coin,
        coin::{Self, Coin},
        display::{Self},
        kiosk::{Self},
        package::{Self},
        sui::{SUI},
        table_vec::{Self, TableVec},
    };
    use galliun::{
        // attributes::{Self},
        capsule::{Capsule},
        // image::{Image},
        // registry::{Registry}
    };

    // === Errors ===

    const EMintWarehouseAlreadyInitialized: u64 = 0;

    // === Structs ===

    // Admin cap of this registry can be used to make changes to the Registry
    public struct WarehouseAdminCap has key { id: UID }

    public struct Warehouse has key {
        id: UID,
        // We add this id so we can insure that the water cooler that
        // is passed coresponds with the current mint settings
        // We have to add it here because we cannot do the check in the
        // watercooler module as there will be a circular dependency
        // between the Setting in the Mint module and the Water Cooler
        // in the watercooler modules
        // waterCoolerId: ID,
        nfts: TableVec<Capsule>,
        is_initialized: bool,
    }


    // === Package Functions ===

    public(package) fun new(
        ctx: &mut TxContext,
    ): Warehouse {
        Warehouse {
            id: object::new(ctx),
            nfts: table_vec::empty(ctx),
            is_initialized: false
        }
    }

    public fun stock(
        warehouse: &mut Warehouse,
        supply: u64,
        mut vector_nfts: vector<Capsule>
    ) {
        assert!(warehouse.is_initialized == false, EMintWarehouseAlreadyInitialized);

        while (!vector_nfts.is_empty()) {
            let nft = vector_nfts.pop_back();
            warehouse.nfts.push_back(nft);
        };

        vector_nfts.destroy_empty();

        if (warehouse.nfts.length() as u64 == supply) {
            warehouse.is_initialized = true;
        }
    }

    // // === Public view functions ===

    public(package) fun count(
        self: &Warehouse,
    ): u64 {
        self.nfts.length()
    }
    
    public(package) fun is_initialized(
        self: &Warehouse,
    ): bool {
        self.is_initialized
    }
    
    public(package) fun is_empty(
        self: &Warehouse,
    ): bool {
        self.nfts.is_empty()
    }
    
    public(package) fun pop_nft(
        self: &mut Warehouse,
    ): Capsule {
        self.nfts.pop_back()
    }

    #[allow(lint(share_owned))]
    public(package) fun transfer_warehouse(self: Warehouse, ctx: &mut TxContext) {
      transfer::transfer(WarehouseAdminCap { id: object::new(ctx) }, ctx.sender());
      transfer::share_object(self);
    }
    
    public(package) fun delete(self: Warehouse) {
      let Warehouse {
            id,
            nfts,
            is_initialized: _,
        } = self;


        nfts.destroy_empty();
        id.delete();
    }
}