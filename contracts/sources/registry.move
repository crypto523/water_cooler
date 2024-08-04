/*
 * Copyright (c) 2024 Studio Mirai, Ltd.
 * SPDX-License-Identifier: MIT
 */

/*
 * This code has been modified and is maintained by Galliun
 * Copyright (c) 2024 Galliun, Limited.
 * SPDX-License-Identifier: MIT
 */

module galliun::registry {

    // === Imports ===

    use std::string::{String};
    use sui::{
        display,
        package,
        table::{Self, Table}
    };
    use galliun::collection::{Self, Collection};

    public struct REGISTRY has drop {}

    /// Stores an NFT number: to ID mapping.
    ///
    /// This object is used to keep a mapping between a NFT's and it's number and object ID
    /// When all the NFTs are register, `is_ready` will be set to true.
    public struct Registry has key {
        id: UID,
        name: String,
        description: String,
        image_url: String,
        nft_ids: vector<ID>,
        kiosk_ids: vector<ID>,
        num_to_nft: Table<u16, ID>,
        nft_to_num: Table<ID, u16>,
        is_ready: bool
    }

    // Admin cap of this registry can be used to make changes to the Registry
    public struct RegistryAdminCap has key { id: UID }

    // === Constants ===

    const EInvalidnftNumber: u64 = 1;
    const ERegistryNotFromThisCollection: u64 = 2;

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
        registry_display.add(b"is_ready".to_string(), b"{is_ready}".to_string());

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
            kiosk_ids: vector::empty(),
            num_to_nft: table::new(ctx),
            nft_to_num: table::new(ctx),
            name,
            description,
            image_url,
            is_ready: false
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
        self: &Registry,
        collection: &Collection,
        number: u16,
    ): ID {
        assert!(number >= 1 && number <= collection::supply(collection), EInvalidnftNumber);

        self.num_to_nft[number]
    }
    
    public fun nft_number_from_id(
        self: &Registry,
        id: ID,
    ): u16 {
        assert!(self.kiosk_ids.contains(&id) == true, ERegistryNotFromThisCollection);

        self.nft_to_num[id]
    }
    
    public fun is_kiosk_registered(
        self: &Registry,
        id: ID,
    ): bool {
        self.kiosk_ids.contains(&id)
    }
    
    public fun is_nft_registered(
        self: &Registry,
        id: ID,
    ): bool {
        self.nft_ids.contains(&id)
    }

    // === Package Functions ===

    public(package) fun add(
        number: u16,
        nft_id: ID,
        kiosk_id: ID,
        self: &mut Registry,
        collection: &Collection,
    ) {

        self.num_to_nft.add(number, nft_id);
        self.nft_to_num.add(nft_id, number);
        self.nft_ids.push_back(nft_id);
        self.kiosk_ids.push_back(kiosk_id);

        if ((self.num_to_nft.length() as u16) == collection::supply(collection) as u16) {
            self.is_ready = true;
        };
    }
    
    public(package) fun add_new(
        number: u16,
        nft_id: ID,
        self: &mut Registry,
        collection: &Collection,
    ) {

        self.num_to_nft.add(number, nft_id);
        self.nft_to_num.add(nft_id, number);
        self.nft_ids.push_back(nft_id);

        if ((self.num_to_nft.length() as u16) == collection::supply(collection) as u16) {
            self.is_ready = true;
        };
    }

    public(package) fun is_ready(
        self: &Registry,
    ): bool {
        self.is_ready
    }

    // === Admin Functions ===

    
}
