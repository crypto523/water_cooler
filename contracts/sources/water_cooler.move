module galliun::water_cooler {
    // === Imports ===
    use std::string::{Self, String};
    use sui::{
        balance::{Self, Balance},
        sui::SUI,
        coin::{Self, Coin},
        display,
        table_vec::{Self, TableVec},
        transfer_policy
    };
    use galliun::{
        capsule::{Self, Capsule},
        registry::{Self, Registry},
        collection::{Self, Collection},
        attributes::{Self},
        settings::{Self},
        warehouse::{Self},
    };

    // === Errors ===

    const EWaterCoolerAlreadyInitialized: u64 = 0;
    const ENFTNotFromCollection: u64 = 1;
    const ENFTAlreadyRevealed: u64 = 2;
    const ERegistryDoesNotMatchCooler: u64 = 3;
    const ECollectionDoesNotMatchCooler: u64 = 4;
    // const EWaterCoolerNotInitialized: u64 = 3;
    // const EWaterCoolerNotEmpty: u64 = 4;

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
        // This keeps tract of the NFTs that have been revealed. 
        // Meaning their metadata has been added
        revealed_nfts: vector<ID>,
        // This is the ID of the registry that keeps track of the NFTs in the collection
        registry_id: ID,
        supply: u64,
        // This is the ID that is associalted with this NFT collection. 
        // It was created for the purpose of avoiding a cercular dependency 
        // between the Registry and the WaterCooler which need to share the 
        // supply of NFTs in the collection
        collection_id: ID,
        // // This is the ID of the mint settings that manages the minting process for the NFTs
        settings_id: ID,
        // // This is the ID of the mint wearhouse that will store the NFTs before mint
        warehouse_id: ID,
        is_initialized: bool,
        is_revealed: bool,
        // balance for creator
        balance: Balance<SUI>,
        // Stores the address of the wallet that created the Water Cooler
        owner: address,
        // This bool determins wether or not a to display the Water cooler on the launchpad
        display: bool,
        init_counter: u64
    }

    // Admin cap of this Water Cooler to be used but the Cooler owner when making changes
    public struct WaterCoolerAdminCap has key { id: UID, `for`: ID }

    // === Public mutative functions ===

    #[allow(lint(share_owned))]
    fun init(otw: WATER_COOLER, ctx: &mut TxContext) {
        // Claim the Publisher object.
        let publisher = sui::package::claim(otw, ctx);

        let mut display = display::new<Capsule>(&publisher, ctx);
        display::add(&mut display, string::utf8(b"name"), string::utf8(b"{collection_name} #{number}"));
        display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::add(&mut display, string::utf8(b"attributes"), string::utf8(b"{attributes}"));
        display::add(&mut display, string::utf8(b"minted_by"), string::utf8(b"{minted_by}"));
        display::add(&mut display, string::utf8(b"kiosk_id"), string::utf8(b"{kiosk_id}"));
        display::add(&mut display, string::utf8(b"kiosk_owner_cap_id"), string::utf8(b"{kiosk_owner_cap_id}"));
        display::update_version(&mut display);

        let (policy, policy_cap) = transfer_policy::new<Capsule>(&publisher, ctx);
        
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
        settings_id: ID,
        warehouse_id: ID ,
        ctx: &mut TxContext
    ): ID {

        let collection = collection::new(supply as u16, ctx);
        let registry = registry::create_registry(name, description, image_url, ctx);
        // let settings = settings::new(ctx);
        // let warehouse = warehouse::new(ctx);

        let waterCooler = WaterCooler {
            id: object::new(ctx),
            name,
            description,
            image_url,
            placeholder_image_url,
            supply,
            nfts: table_vec::empty(ctx),
            revealed_nfts: vector::empty(),
            treasury,
            registry_id: object::id(&registry),
            collection_id: object::id(&collection),
            // settings_id: object::id(&settings),
            // warehouse_id: object::id(&warehouse),
            settings_id,
            warehouse_id,
            is_initialized: false,
            is_revealed: false,
            balance: balance::zero(),
            owner: ctx.sender(),
            display: false,
            init_counter: 0
        };

        transfer::transfer(
            WaterCoolerAdminCap { 
                id: object::new(ctx),
                `for`: object::id(&waterCooler)
            },
            ctx.sender()
        );

        let waterCoolerId = object::id(&waterCooler);

        transfer::share_object(waterCooler);

        collection::transfer_collection(collection, ctx);
        registry::transfer_registry(registry, ctx);
        // settings::transfer_setting(settings, ctx);
        // warehouse::transfer_warehouse(warehouse, ctx);
        
        waterCoolerId
    }


    public(package) fun send_fees(
        self: &WaterCooler,
        coins: Coin<SUI>
    ) {
        transfer::public_transfer(coins, self.treasury);
    }
    
    public(package) fun get_is_revealed(
        self: &WaterCooler,
    ): bool {
        self.is_revealed
    }
    
    public(package) fun get_is_initialized(
        self: &WaterCooler,
    ): bool {
        self.is_initialized
    }
    
    public(package) fun get_warehouse_id(
        self: &WaterCooler,
    ): ID {
        self.warehouse_id
    }
    
    public(package) fun get_settings_id(
        self: &WaterCooler,
    ): ID {
        self.settings_id
    }
    
    public(package) fun check_registry(
        self: &WaterCooler,
        registry: &Registry,
    ): bool {
        self.registry_id == object::id(registry)
    }
    
    public(package) fun check_collection(
        self: &WaterCooler,
        collection: &Collection,
    ): bool {
        self.collection_id == object::id(collection)
    }

    public(package) fun add_balance(
        self: &mut WaterCooler,
        coin: Coin<SUI>
    ) {
        self.balance.join(coin.into_balance());
    }

    // === Admin Functions ===

    // TODO: might need to split in multiple calls if the supply is too high
    #[allow(lint(share_owned))]
    public entry fun initialize_with_data(
        _: &WaterCoolerAdminCap,
        self: &mut WaterCooler,
        registry: &mut Registry,
        collection: &Collection,
        mut numbers: vector<u64>,
        mut image_urls: vector<String>,
        mut keys: vector<vector<String>>,
        mut values: vector<vector<String>>,
        ctx: &mut TxContext,
    ) {
        assert!(self.is_initialized == false, EWaterCoolerAlreadyInitialized);

        // let mut number = collection::supply(collection) as u64;

        

        // Pre-fill the water cooler with the NFTs to the size of the NFT collection
        // ! using LIFO here because TableVec
        while (image_urls.length() > 0) {

            let attributes = attributes::admin_new(keys.pop_back(), values.pop_back(), ctx);            

            let nft: Capsule = capsule::new(
                numbers.pop_back(),
                self.name,
                self.description,
                option::some(image_urls.pop_back()), // image_url
                option::some(attributes), // attributes
                // option::none(), // image
                // object::id(self), //water_cooler_id
                ctx,
            );

            // registry::add_new(number as u16, object::id(&nft), registry, collection);

            // Add Capsule to factory.
            // self.nfts.push_back(object::id(&nft));

            transfer::public_transfer(nft, ctx.sender());

            self.init_counter = self.init_counter + 1;
        };

        // Initialize water cooler if the number of NFT created is equal to the size of the collection.
        if (self.init_counter == collection::supply(collection) as u64) {
            self.is_initialized = true;
        };
    }
    
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
        // Pre-fill the water cooler with the NFTs to the size of the NFT collection
        // ! using LIFO here because TableVec
        while (number != 0) {

            let nft: Capsule = capsule::new(
                number,
                self.name,
                self.description,
                option::some(self.placeholder_image_url), // image_url
                option::none(), // attributes
                // option::none(), // image
                // object::id(self), //water_cooler_id
                ctx,
            );

            // registry::add_new(number as u16, object::id(&nft), registry, collection);

            // Add Capsule to factory.
            // self.nfts.push_back(object::id(&nft));

            transfer::public_transfer(nft, ctx.sender());

            number = number - 1;
        };

        // Initialize water cooler if the number of NFT created is equal to the size of the collection.
        if (self.nfts.length() == collection::supply(collection) as u64) {
            self.is_initialized = true;
        };
    }

    public fun reveal_nft(
        _: &WaterCoolerAdminCap,
        self: &mut WaterCooler,
        registry: &Registry,
        collection: &Collection,
        nft: &mut Capsule,
        keys: vector<String>,
        values: vector<String>,
        // _image: Image,
        image_url: String,
        ctx: &mut TxContext
    ) {
        assert!(self.registry_id == object::id(registry), ERegistryDoesNotMatchCooler);
        assert!(self.collection_id == object::id(collection), ECollectionDoesNotMatchCooler);
        let nft_id = object::id(nft);
        // assert!(registry.is_nft_registered(nft_id), ENFTNotFromCollection);
        assert!(!self.revealed_nfts.contains(&nft_id), ENFTAlreadyRevealed);

        let attributes = attributes::admin_new(keys, values, ctx);

        capsule::set_attributes(nft, attributes);
        // capsule::set_image(nft, image);
        capsule::set_image_url(nft, image_url);

        self.revealed_nfts.push_back(nft_id);

        if (self.revealed_nfts.length() == collection::supply(collection) as u64) {
            self.is_revealed = true;
        };
    }
    
    public fun set_treasury(_: &WaterCoolerAdminCap, self: &mut WaterCooler, treasury: address) {
        self.treasury = treasury;
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

    public fun supply(self: &WaterCooler): u64 {
        self.supply
    }
    
    public fun placeholder_image(self: &WaterCooler): String {
        self.placeholder_image_url
    }
    
    public fun owner(self: &WaterCooler): address {
        self.owner
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_water(ctx: &mut TxContext) {
        init(WATER_COOLER {}, ctx);
    }
}
