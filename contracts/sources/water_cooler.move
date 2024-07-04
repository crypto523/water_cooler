module galliun::water_cooler {
    // === Imports ===
    use std::string::{Self, String};
    use sui::{
        balance::{Self, Balance},
        sui::SUI,
        coin::{Self, Coin},
        display,
        kiosk,
        table_vec::{Self, TableVec},
        transfer_policy
    };
    use galliun::{
        mizu_nft::{Self, MizuNFT},
        registry::{Self, Registry},
        collection::{Self, Collection},
    };

    // === Errors ===

    const EWaterCoolerAlreadyInitialized: u64 = 0;
    // const EWaterCoolerNotInitialized: u64 = 1;
    // const EWaterCoolerNotEmpty: u64 = 2;

    // === Structs ===

    public struct WATER_COOLER has drop {}

    // This is the structure of WaterCooler that will be loaded with and distribute the NFTs
    public struct WaterCooler has key {
        id: UID,
        name: String,
        description: String,
        // We concatinate this url with the number of the NFT in order to find it on chain
        image_url: String,
        // This is the image that will be displayed on your NFT until they are revealed
        placeholder_image_url: String,
        // This is the address to where the royalty and mint fee will be sent
        treasury: address,
        // This table will keep track of all the created NFTs
        nfts: TableVec<ID>,
        // This is the ID of the registry that keeps track of the NFTs in the collection
        registry_id: ID,
        supply: u64,
        // This is the ID that is associalted with this NFT collection. 
        // It was created for the purpose of avoiding a cercular dependency 
        // between the Registry and the WaterCooler which need to share the 
        // supply of NFTs in the collection
        collection_id: ID,
        // This is the ID of the mint settings that manages the minting process for the NFTs
        setting_id: ID,
        // This is the ID of the mint wearhouse that will store the NFTs before mint
        wearhouse_id: ID,
        is_initialized: bool,
        // balance for creator
        balance: Balance<SUI>,
    }

    // Admin cap of this Water Cooler to be used but the Cooler owner when making changes
    public struct WaterCoolerAdminCap has key { id: UID }

    // === Public mutative functions ===

    #[allow(lint(share_owned))]
    fun init(otw: WATER_COOLER, ctx: &mut TxContext) {
        // Claim the Publisher object.
        let publisher = sui::package::claim(otw, ctx);

        let mut display = display::new<MizuNFT>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{collection_name} #{number}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"attributes"), string::utf8(b"{attributes}"));
        display::add(&mut display, string::utf8(b"minted_by"), string::utf8(b"{minted_by}"));
        display::add(&mut display, string::utf8(b"kiosk_id"), string::utf8(b"{kiosk_id}"));
        display::add(&mut display, string::utf8(b"kiosk_owner_cap_id"), string::utf8(b"{kiosk_owner_cap_id}"));
        display::update_version(&mut display);

        let (policy, policy_cap) = transfer_policy::new<MizuNFT>(&publisher, ctx);
        
        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(policy_cap,ctx.sender());
        transfer::public_transfer(display, ctx.sender());

        transfer::public_share_object(policy);
    }

    // === Package Functions ===

    // The function that allow the Cooler Factory to create coolers and give them to creators
    public(package) fun create_water_cooler(
        name: String,
        description: String,
        image_url: String,
        placeholder_image_url: String,
        supply: u64,
        treasury: address,
        setting_id: ID,
        wearhouse_id: ID,
        ctx: &mut TxContext
    ) {

        let collection = collection::new(supply as u16, ctx);
        let registry = registry::create_registry(name, description, image_url, ctx);

        transfer::share_object(
            WaterCooler {
                id: object::new(ctx),
                name,
                description,
                image_url,
                placeholder_image_url,
                supply,
                nfts: table_vec::empty(ctx),
                treasury,
                registry_id: object::id(&registry),
                collection_id: object::id(&collection),
                setting_id,
                wearhouse_id,
                is_initialized: false,
                balance: balance::zero(),
            }
        );

        collection::transfer_collection(collection, ctx);
        registry::transfer_registry(registry, ctx);
        

        transfer::transfer(WaterCoolerAdminCap { id: object::new(ctx) }, ctx.sender());
    }

    public(package) fun add_balance(
        self: &mut WaterCooler,
        coin: Coin<SUI>
    ) {
        self.balance.join(coin.into_balance());
    }
    
    public fun supply(self: &WaterCooler): u64 {
        self.supply
    }

    // === Admin Functions ===

    // TODO: might need to split in multiple calls if the supply is too high
    #[allow(lint(share_owned))]
    public entry fun initialize_water_cooler(
        _: &WaterCoolerAdminCap,
        self: &mut WaterCooler,
        registry: &mut Registry,
        collection: &Collection,
        ctx: &mut TxContext,
    ) {
        assert!(self.is_initialized == false, EWaterCoolerAlreadyInitialized);

        let mut number = collection::supply(collection) as u64;
        // Pre-fill the water cooler with the kiosk NFTs to the size of the NFT collection
        // ! using LIFO here because TableVec
        while (number != 0) {
            let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

            let nft: MizuNFT = mizu_nft::new(
                number,
                self.name,
                self.description,
                option::some(self.placeholder_image_url), // image_url
                option::none(), // attributes
                option::none(), // image
                option::none(), // minted_by
                object::id(&kiosk),
                object::id(&kiosk_owner_cap),
                object::id(self),
                ctx,
            );

            registry::add(number as u16, object::id(&nft), registry, collection);

            // Set the Kiosk's 'owner' field to the address of the MizuNFT.
            kiosk::set_owner_custom(&mut kiosk, &kiosk_owner_cap, object::id_address(&nft));

            transfer::public_transfer(kiosk_owner_cap, object::id_to_address(&object::id(&nft)));
            transfer::public_share_object(kiosk);

            // Add MizuNFT to factory.
            self.nfts.push_back(object::id(&nft));

            transfer::public_transfer(nft, ctx.sender());

            number = number - 1;
        };

        // Initialize water cooler if the number of NFT created is equal to the size of the collection.
        if (self.nfts.length() == collection::supply(collection) as u64) {
            self.is_initialized = true;
        };
    }
    
    public entry fun claim_balance(
        _: &WaterCoolerAdminCap,
        self: &mut WaterCooler,
        ctx: &mut TxContext
    ) {
        let value = self.balance.value();
        let coin = coin::take(&mut self.balance, value, ctx);
        transfer::public_transfer(coin, self.treasury);
    }

    public fun set_treasury(_: &WaterCoolerAdminCap, self: &mut WaterCooler, treasury: address) {
        self.treasury = treasury;
    }



    // === Public view functions ===

    public fun get_nfts_num(self: &WaterCooler): u64 {
        table_vec::length(&self.nfts)
    }
    
    public fun name(self: &WaterCooler): String {
        self.name
    }
    
    public fun image_url(self: &WaterCooler): String {
        self.image_url
    }

    public fun is_initialized(self: &WaterCooler): bool {
        self.is_initialized
    }

    public fun treasury(self: &WaterCooler): address {
        self.treasury
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_water(ctx: &mut TxContext) {
        init(WATER_COOLER {}, ctx);
    }
}
