module galliun::registry {

    // === Imports ===

    use std::string::{String};
    use sui::{
        display,
        package,
        table::{Self, Table}
    };
    use galliun::collection::{Self, Collection};

    // === Friends ===

    /* friend galliun::factory; */

    public struct REGISTRY has drop {}

    /// Stores an NFT number: to ID mapping.
    ///
    /// This object is used to maintain a stable mapping between a NFT's
    /// number: and its object ID. When the contract is deployed, `is_initialized` is set to false.
    /// Once all NFTs have been registered, `is_initialized` will be set to
    /// true. At this point, the registry should be transformed into an immutable object.
    public struct Registry has key {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        nft_ids: vector<ID>,
        num_to_nft: Table<u16, ID>,
        nft_to_num: Table<ID, u16>,
        is_initialized: bool,
        is_frozen: bool,
    }

    // Admin cap of this registry can be used to make changes to the Registry
    public struct RegistryAdminCap has key { id: UID }

    // === Constants ===

    const EInvalidnftNumber: u64 = 1;
    const ERegistryNotIntialized: u64 = 2;
    const ERegistryAlreadyFrozen: u64 = 3;
    const ERegistryNotFrozen: u64 = 4;
    const ERegistryNotFromThisCollection: u64 = 5;

    // === Init Function ===

    #[allow(unused_variable, lint(share_owned))]
    fun init(
        otw: REGISTRY,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);

        let mut registry_display = display::new<Registry>(&publisher, ctx);
        registry_display.add(b"name".to_string(), b"NFT Registry".to_string());
        registry_display.add(b"description".to_string(), b"The registry for your NFT collection.".to_string());
        registry_display.add(b"image_url".to_string(), b"{image_url}".to_string());
        registry_display.add(b"is_initialized".to_string(), b"{is_initialized}".to_string());
        registry_display.add(b"is_frozen".to_string(), b"{is_frozen}".to_string());

        transfer::public_transfer(registry_display, ctx.sender());
        transfer::public_transfer(publisher, ctx.sender());
    }

    // === Package Functions ===

    public(package) fun create_registry(
        name: String,
        description: String,
        image_url: String,
        ctx: &mut TxContext,
    ): Registry {
        Registry {
            id: object::new(ctx),
            nft_ids: vector::empty(),
            num_to_nft: table::new(ctx),
            nft_to_num: table::new(ctx),
            name,
            description,
            image_url,
            is_initialized: false,
            is_frozen: false,
        }
    }

    // This function was created so I can transfer the Registries to the sender 
    // after adding the objectId to the WaterCooler object which allows me to 
    // keep track of which Colleection belongs to each Water Cooler
    public(package) fun transfer_registry(self: Registry, ctx: &mut TxContext) {
        transfer::transfer(RegistryAdminCap { id: object::new(ctx) }, ctx.sender());
        transfer::transfer(self, ctx.sender());
    }

    public fun nft_id_from_number(
        registry: &Registry,
        collection: &Collection,
        number: u16,
    ): ID {
        assert!(number >= 1 && number <= collection::supply(collection), EInvalidnftNumber);
        assert!(registry.is_frozen == true, ERegistryNotFrozen);

        registry.num_to_nft[number]
    }
    
    public fun nft_number_from_id(
        registry: &Registry,
        id: ID,
    ): u16 {
        assert!(registry.is_frozen == true, ERegistryNotFrozen);
        assert!(registry.nft_ids.contains(&id) == true, ERegistryNotFromThisCollection);

        registry.nft_to_num[id]
    }

    // === Package Functions ===

    public(package) fun add(
        number: u16,
        nft_id: ID,
        registry: &mut Registry,
        collection: &Collection,
    ) {

        registry.num_to_nft.add(number, nft_id);
        registry.nft_to_num.add(nft_id, number);
        registry.nft_ids.push_back(nft_id);

        if ((registry.num_to_nft.length() as u16) == collection::supply(collection) as u16) {
            registry.is_initialized = true;
        };
    }

    public(package) fun is_frozen(
        registry: &Registry,
    ): bool {
        registry.is_frozen
    }

    public(package) fun is_initialized(
        registry: &Registry,
    ): bool {
        registry.is_initialized
    }

    // === Admin Functions ===

    #[lint_allow(freeze_wrapped)]
    public fun admin_freeze_registry(
        _cap: &RegistryAdminCap,
        mut registry: Registry,
        _ctx: &TxContext,
    ) {
        assert!(registry.is_frozen == false, ERegistryAlreadyFrozen);
        assert!(registry.is_initialized == true, ERegistryNotIntialized);
        registry.is_frozen = true;
        transfer::freeze_object(registry);
    }
}
