module galliun::water_cooler {
    use std::string::{Self, String};
    use sui::{
        balance::{Self, Balance},
        sui::SUI,
        coin::{Self, Coin},
        display,
        kiosk,
        table_vec::{Self, TableVec},
        transfer_policy,
    };
    use galliun::attributes::{Attributes};

    // === Errors ===

    const EWaterCoolerAlreadyInitialized: u64 = 0;
    // const EWaterCoolerNotInitialized: u64 = 1;
    // const EWaterCoolerNotEmpty: u64 = 2;
    const EAttributesAlreadySet: u64 = 3;
    // const EImageAlreadySet: u64 = 4;
    // const EImageNotSet: u64 = 5;

    // === Structs ===

    public struct WATER_COOLER has drop {}

    // This is the structure that will be used to create the NFTs
    public struct MizuNFT has key, store {
        id: UID,
        // This name will be joined with the number to create the NFT name
        collection_name: String,
        description: String,
        // This url will be joined with the id to create the image url
        image_url: String,
        number: u64,
        attributes: Option<Attributes>,
        image: Option<String>,
        minted_by: Option<address>,
        // ID of the Kiosk assigned to the NFT.
        kiosk_id: ID,
        // ID of the KioskOwnerCap owned by the NFT.
        kiosk_owner_cap_id: ID,
    }

    // This is the structure of WaterCooler that will be loaded with and distribute the NFTs
    public struct WaterCooler has key {
        id: UID,
        name: String,
        description: String,
        // We concatinate this url with the number of the NFT in order to find it on chain
        image_url: String,
        // This is the address to where the royalty and mint fee will be sent
        treasury: address,
        // This table will keep track of all the created NFTs
        nfts: TableVec<ID>,
        // This is the number of NFTs that will be in the collection
        supply: u64,
        is_initialized: bool,
        // balance for creator
        balance: Balance<SUI>,
    }

    // Admin cap of this Water Cool to be used but the Cooler owner when making changes
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

    // === Public view functions ===
    
    public fun supply(water_cooler: &WaterCooler): u64 {
        water_cooler.supply
    }
    
    public fun name(water_cooler: &WaterCooler): String {
        water_cooler.name
    }
    
    public fun image_url(water_cooler: &WaterCooler): String {
        water_cooler.image_url
    }

    public fun is_initialized(water_cooler: &WaterCooler): bool {
        water_cooler.is_initialized
    }

    public fun treasury(water_cooler: &WaterCooler): address {
        water_cooler.treasury
    }

    public fun number(nft: &MizuNFT): u64 {
        nft.number
    }

    public fun kiosk_id(nft: &MizuNFT): ID {
        nft.kiosk_id
    }

    public fun kiosk_owner_cap_id(nft: &MizuNFT): ID {
        nft.kiosk_owner_cap_id
    }

    // === Admin Functions ===

    // TODO: might need to split in multiple calls if the supply is too high
    #[allow(lint(share_owned))]
    public entry fun initialize_water_cooler(
        _: &WaterCoolerAdminCap,
        water_cooler: &mut WaterCooler,
        ctx: &mut TxContext,
    ) {
        assert!(water_cooler.is_initialized == false, EWaterCoolerAlreadyInitialized);

        let mut number = water_cooler.supply;
        // Pre-fill the water cooler with the kiosk NFTs to the size of the NFT collection
        // ! using LIFO here because TableVec
        while (number != 0) {

            let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

            let nft = MizuNFT {
                id: object::new(ctx),
                number,
                collection_name: water_cooler.name,
                description: water_cooler.description,
                image_url: water_cooler.image_url,
                attributes: option::none(),
                image: option::none(),
                minted_by: option::none(),
                kiosk_id: object::id(&kiosk),
                kiosk_owner_cap_id: object::id(&kiosk_owner_cap),
            };

            // Set the Kiosk's 'owner' field to the address of the MizuNFT.
            kiosk::set_owner_custom(&mut kiosk, &kiosk_owner_cap, object::id_address(&nft));

            transfer::public_transfer(kiosk_owner_cap, object::id_to_address(&object::id(&nft)));
            transfer::public_share_object(kiosk);

            // Add MizuNFT to factory.
            water_cooler.nfts.push_back(object::id(&nft));

            transfer::public_transfer(nft, ctx.sender());

            number = number - 1;
        };

        // Initialize water cooler if the number of NFT created is equal to the size of the collection.
        if (water_cooler.nfts.length() == water_cooler.supply) {
            water_cooler.is_initialized = true;
        };
    }
    
    public entry fun claim_balance(
        _: &WaterCoolerAdminCap,
        water_cooler: &mut WaterCooler,
        ctx: &mut TxContext
    ) {
        let value = water_cooler.balance.value();
        let coin = coin::take(&mut water_cooler.balance, value, ctx);
        transfer::public_transfer(coin, ctx.sender());
    }

    public fun set_treasury(_: &WaterCoolerAdminCap, water_cooler: &mut WaterCooler, treasury: address) {
        water_cooler.treasury = treasury;
    }

    // === Package Functions ===

    // The function that allow the Cooler Factory to create coolers and give them to creators
    public(package) fun create_water_cooler(
        name: String, 
        description: String, 
        image_url: String, 
        supply: u64, 
        treasury: address, 
        ctx: &mut TxContext
    ) {
        transfer::share_object(
            WaterCooler {
                id: object::new(ctx),
                name,
                description,
                image_url,
                nfts: table_vec::empty(ctx),
                treasury,
                supply,
                is_initialized: false,
                balance: balance::zero(),
            }
        );

        transfer::transfer(WaterCoolerAdminCap { id: object::new(ctx) }, ctx.sender());
    }

    public(package) fun add_balance(
        water_cooler: &mut WaterCooler,
        coin: Coin<SUI>
    ) {
        water_cooler.balance.join(coin.into_balance());
    }

    public(package) fun set_image(nft: &mut MizuNFT, image: String) {
        option::fill(&mut nft.image, image);
    }

    public(package) fun uid_mut(nft: &mut MizuNFT): &mut UID {
        &mut nft.id
    }

    public(package) fun set_attributes(nft: &mut MizuNFT, attributes: Attributes) {
        assert!(option::is_none(&nft.attributes), EAttributesAlreadySet);
        option::fill(&mut nft.attributes, attributes);
    }

    public(package) fun set_minted_by_address(nft: &mut MizuNFT, addr: address) {
        option::fill(&mut nft.minted_by, addr);
    }

    // === Test Functions ===

    #[test_only]
    public fun init_for_water(ctx: &mut TxContext) {
        init(WATER_COOLER {}, ctx);
    }

}
