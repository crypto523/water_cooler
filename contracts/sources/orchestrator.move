module galliun::orchestrator {
    // === Imports ===

    use std::string::{Self, String};
    use sui::{
        coin::Coin,
        display::{Self},
        kiosk::{Self},
        package::{Self},
        sui::{SUI},
        table_vec::{Self, TableVec},
        transfer_policy::{TransferPolicy},
    };
    use galliun::{
        attributes::{Self},
        water_cooler::{Self, WaterCooler},
        mizu_nft::{Self, MizuNFT},
        // image::{Image},
        registry::{Registry}
    };

    // === Errors ===
    
    const ENotOwner: u64 = 0;
    const EInvalidPaymentAmount: u64 = 1;
    const EInvalidPhaseNumber: u64 = 2;
    const EInvalidPrice: u64 = 3;
    const EInvalidStatusNumber: u64 = 4;
    const EInvalidTicketForMintPhase: u64 = 5;
    const EMintNotLive: u64 = 6;
    const EMintWarehouseAlreadyInitialized: u64 = 7;
    const EMintWarehouseNotEmpty: u64 = 8;
    const EMintWarehouseNotInitialized: u64 = 9;
    // const EMizuNFTNotRevealed: u64 = 10;
    const EWarehouseIsEmpty: u64 = 11;
    const EWrongPhase: u64 = 12;
    const ENFTNotFromCollection: u64 = 13;
    const ESettingsDoesNotMatchCooler: u64 = 14;
    const EWearhouseDoesNotMatchCooler: u64 = 15;

    // === Constants ===

    const MINT_STATE_INACTIVE: u8 = 0;
    const MINT_STATE_ACTIVE: u8 = 1;

    // === Structs ===

    public struct ORCHESTRATOR has drop {}


    public struct Settings has key {
        id: UID,
        // We add this id so we can insure that the water cooler that
        // is passed coresponds with the current mint settings
        // We have to add it here because we cannot do the check in the
        // watercooler module as there will be a circular dependency
        // between the Setting in the Mint module and the Water Cooler
        // in the watercooler modules
        waterCoolerId: ID,
        // This is the price that must be paid by the minter to get the NFT
        price: u64,
        /// The phase determins the current minting phase
        /// 1 = og
        /// 2 = whiteList
        /// 3 = public
        phase: u8,
        /// The state determings whether the mint is active or not
        /// 0 = inactive
        /// 1 = active
        status: u8,
    }

    public struct Warehouse has key {
        id: UID,
        // We add this id so we can insure that the water cooler that
        // is passed coresponds with the current mint settings
        // We have to add it here because we cannot do the check in the
        // watercooler module as there will be a circular dependency
        // between the Setting in the Mint module and the Water Cooler
        // in the watercooler modules
        waterCoolerId: ID,
        nfts: TableVec<MizuNFT>,
        is_initialized: bool,
    }

    public struct WhitelistTicket has key {
        id: UID,
        waterCoolerId: ID,
        name: String,
        image_url: String,
        phase: u8,
    }

    public struct OriginalGangsterTicket has key {
        id: UID,
        waterCoolerId: ID,
        name: String,
        image_url: String,
        phase: u8,
    }

    // === Events ===

    // Orch Admin cap this can be used to make changes to the orch setting and warehouse
    public struct OrchAdminCap has key { id: UID, `for_settings`: ID, `for_warehouse`: ID}

    public struct OrchCap has key { id: UID, `for`: ID}


    // === Init Function ===

    fun init(
        otw: ORCHESTRATOR,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);


        let mut wl_ticket_display = display::new<WhitelistTicket>(&publisher, ctx);
        display::add(&mut wl_ticket_display, string::utf8(b"name"), string::utf8(b"{name} WL Ticket"));
        display::add(&mut wl_ticket_display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut wl_ticket_display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::update_version(&mut wl_ticket_display);

        transfer::public_transfer(wl_ticket_display, ctx.sender());

        let mut og_ticket_display = display::new<OriginalGangsterTicket>(&publisher, ctx);
        display::add(&mut og_ticket_display, string::utf8(b"name"), string::utf8(b"{name} OG Ticket"));
        display::add(&mut og_ticket_display, string::utf8(b"description"), string::utf8(b"{description}"));
        display::add(&mut og_ticket_display, string::utf8(b"image_url"), string::utf8(b"{image_url}"));
        display::update_version(&mut og_ticket_display);


        transfer::public_transfer(og_ticket_display, ctx.sender());
        transfer::public_transfer(publisher, ctx.sender());
    }

     // === Public-view Functions ===

    public fun get_mintwarehouse_length(self: &Warehouse) : u64 {
        self.nfts.length()
    }

    // === Public-Mutative Functions ===


    public entry fun public_mint(
        waterCooler: &WaterCooler,
        warehouse: &mut Warehouse,
        settings: &Settings,
        policy: &TransferPolicy<MizuNFT>,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.waterCoolerId == object::id(waterCooler), EWearhouseDoesNotMatchCooler);
        assert!(settings.waterCoolerId == object::id(waterCooler), ESettingsDoesNotMatchCooler);
        assert!(warehouse.nfts.length() > 0, EWarehouseIsEmpty);
        assert!(settings.phase == 3, EWrongPhase);
        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(waterCooler, warehouse, policy, payment, ctx);
    }

    #[allow(unused_variable)]
    public fun whitelist_mint(
        ticket: WhitelistTicket,
        waterCooler: &WaterCooler,
        warehouse: &mut Warehouse,
        settings: &Settings,
        policy: &TransferPolicy<MizuNFT>,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.waterCoolerId == object::id(waterCooler), EWearhouseDoesNotMatchCooler);
        assert!(settings.waterCoolerId == object::id(waterCooler), ESettingsDoesNotMatchCooler);

        let WhitelistTicket { id, name, image_url, waterCoolerId, phase } = ticket;
        
        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
        assert!(waterCoolerId == object::id(waterCooler), EInvalidTicketForMintPhase);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);


        mint_internal(waterCooler, warehouse, policy, payment, ctx);
        id.delete();
    }

    #[allow(unused_variable)]
    public fun og_mint(
        ticket: OriginalGangsterTicket,
        waterCooler: &WaterCooler,
        warehouse: &mut Warehouse,
        settings: &Settings,
        policy: &TransferPolicy<MizuNFT>,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.waterCoolerId == object::id(waterCooler), EWearhouseDoesNotMatchCooler);
        assert!(settings.waterCoolerId == object::id(waterCooler), ESettingsDoesNotMatchCooler);

        let OriginalGangsterTicket { id, name, image_url, waterCoolerId, phase } = ticket;
        
        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
        assert!(waterCoolerId == object::id(waterCooler), EInvalidTicketForMintPhase);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(waterCooler, warehouse, policy,  payment, ctx);
        id.delete();
    }

    // === Admin functions ===

    /// Add MizuNFTs to the mint warehouse.
    public fun stock_warehouse(
        cap: &OrchAdminCap,
        water_cooler: &WaterCooler,
        mut nfts: vector<MizuNFT>,
        warehouse: &mut Warehouse,
    ) {
        assert!(object::id(warehouse) == cap.`for_warehouse`, ENotOwner);        
        assert!(warehouse.is_initialized == false, EMintWarehouseAlreadyInitialized);

        while (!nfts.is_empty()) {
            let pfp = nfts.pop_back();
            warehouse.nfts.push_back(pfp);
        };
        nfts.destroy_empty();

        if (warehouse.nfts.length() as u64 == water_cooler.supply()) {
            warehouse.is_initialized = true;
        };
    }

    public fun admin_reveal_nft(
        _: &OrchAdminCap,
        registry: &Registry,
        nft: &mut MizuNFT,
        keys: vector<String>,
        values: vector<String>,
        // _image: Image,
        image_url: String,
        ctx: &mut TxContext
    ) {
        assert!(registry.is_nft_registered(object::id(nft)), ENFTNotFromCollection);

        let attributes = attributes::admin_new(keys, values, ctx);

        mizu_nft::set_attributes(nft, attributes);
        // mizu_nft::set_image(nft, image);
        mizu_nft::set_image_url(nft, image_url);
    }


    /// Destroy an empty mint warehouse when it's no longer needed.
    public fun destroy_mint_warehouse(
        cap: &OrchAdminCap,
        warehouse: Warehouse,
    ) {
        assert!(warehouse.nfts.is_empty(), EMintWarehouseNotEmpty);
        assert!(warehouse.is_initialized == true, EMintWarehouseNotInitialized);

        let Warehouse {
            id,
            waterCoolerId: _,
            nfts,
            is_initialized: _,
        } = warehouse;

        assert!(object::uid_to_inner(&id) == cap.`for_warehouse`, ENotOwner);        

        nfts.destroy_empty();
        id.delete();
    }

    // Set mint price, status, phase
    public fun set_mint_price(
        cap: &OrchAdminCap,
        settings: &mut Settings,
        price: u64,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);        

        assert!(price >= 0, EInvalidPrice);
        settings.price = price;
    }

    public fun set_mint_status(
        cap: &OrchAdminCap,
        settings: &mut Settings,        
        status: u8,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);
        assert!(settings.status == MINT_STATE_INACTIVE || settings.status == MINT_STATE_ACTIVE, EInvalidStatusNumber);
        settings.status = status;
    }

    public fun set_mint_phase(
        cap: &OrchAdminCap,
        settings: &mut Settings,
        phase: u8,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);
        assert!(phase >= 1 && phase <= 3, EInvalidPhaseNumber);
        settings.phase = phase;
    }

    public fun create_og_ticket(
        _: &OrchAdminCap,
        waterCooler: &WaterCooler,
        owner: address,
        ctx: &mut TxContext
    ) {
        let og_ticket =  OriginalGangsterTicket {
            id: object::new(ctx),
            name: water_cooler::name(waterCooler),
            waterCoolerId: object::id(waterCooler),
            image_url: water_cooler::placeholder_image(waterCooler),
            phase: 1
        };

        transfer::transfer(og_ticket, owner);
    }

    public fun create_wl_ticket(
        _: &OrchAdminCap,
        waterCooler: &WaterCooler,
        owner: address,
        ctx: &mut TxContext
    ) {
        let whitelist_ticket =  WhitelistTicket {
            id: object::new(ctx),
            name: water_cooler::name(waterCooler),
            waterCoolerId: object::id(waterCooler),
            image_url: water_cooler::placeholder_image(waterCooler),
            phase: 2
        };

        transfer::transfer(whitelist_ticket, owner);
    }

    // === Package functions ===

    public(package) fun create_mint_distributer(waterCoolerId: ID, ctx: &mut TxContext): (Settings, Warehouse) {
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        let settings = Settings {
            id: object::new(ctx),
            waterCoolerId,
            price: 0,
            phase: 0,
            status: 0,
        };
        
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        let warehouse = Warehouse {
            id: object::new(ctx),
            waterCoolerId,
            nfts: table_vec::empty(ctx),
            is_initialized: false,
        };

        // Here we transfer the mint admin cap to the person that bought the WaterCooler
        transfer::transfer(
            OrchAdminCap {
                id: object::new(ctx),
                `for_settings`: object::id(&settings),
                `for_warehouse`: object::id(&warehouse)
            },
             ctx.sender()
        );

        (settings, warehouse)
    }
    
    #[allow(lint(share_owned))]
    public(package) fun transfer_setting(self: Settings) {
        transfer::share_object(self);
    }

    #[allow(lint(share_owned))]
    public(package) fun transfer_warehouse(self: Warehouse) {
        transfer::share_object(self);
    }

    // === Private Functions ===

    #[allow(lint(self_transfer, share_owned))]
    public fun mint_internal(
        waterCooler: &WaterCooler,
        warehouse: &mut Warehouse,
        _policy: &TransferPolicy<MizuNFT>,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        // Safely unwrap the NFT from the warehouse
        let nft = warehouse.nfts.pop_back();

        // Create a new kiosk and its owner capability
        let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

        // Place the NFT in the kiosk
        kiosk::place(&mut kiosk, &kiosk_owner_cap, nft);

        // Lock MizuNFT into buyer's kiosk.
        // TO DO: Lock NFT in kiosk using NFT policy
        // kiosk::lock(&mut kiosk, &mut kiosk_owner_cap, policy, nft);

        // Transfer the kiosk owner capability to the sender
        transfer::public_transfer(kiosk_owner_cap, ctx.sender());

        // Share the kiosk object publicly
        transfer::public_share_object(kiosk);

        // Send the payment to the water cooler
        waterCooler.send_fees(payment);
    }


    // === Test Functions ===
    #[test_only]
    public fun init_for_mint(ctx: &mut TxContext) {
        init(ORCHESTRATOR {}, ctx);
    }

    // #[test_only]
    // public fun get_nft_id(self: &Mint) : ID {
    //    let nft = self.nft.borrow();
    //    object::id(nft)
    // }
}
