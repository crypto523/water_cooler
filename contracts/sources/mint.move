/*
 * Copyright (c) 2024 Studio Mirai, Ltd.
 * SPDX-License-Identifier: MIT
 */


module galliun::mint {
    // === Imports ===

    use std::string::String;
    use sui::{
        coin::Coin,
        display::{Self, Display},
        event,
        kiosk::{Self, Kiosk, KioskOwnerCap},
        package::{Self},
        sui::{SUI},
        table_vec::{Self, TableVec},
        transfer_policy::{TransferPolicy},
    };
    use galliun::{
        attributes::{Self, Attributes},
        water_cooler::WaterCooler,
        mizu_nft::{Self, MizuNFT},
        image::{Self, Image},
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

    // === Constants ===

    const EPOCHS_TO_CLAIM_MINT: u64 = 30;
    const MINT_STATE_INACTIVE: u8 = 0;
    const MINT_STATE_ACTIVE: u8 = 1;

    // === Structs ===

    public struct MINT has drop {}

    public struct Mint has key, store {
        id: UID,
        number: u64,    
        nft: Option<MizuNFT>,
        payment: Option<Coin<SUI>>,
        is_revealed: bool,
        minted_by: address,
        claim_expiration_epoch: u64,
    }


    public struct MintSettings has key {
        id: UID,
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

    public struct MintWarehouse has key {
        id: UID,
        nfts: TableVec<MizuNFT>,
        is_initialized: bool,
    }

    public struct WhitelistTicket has key {
        id: UID,
        warehouseId: ID,
        phase: u8,
    }

    public struct OriginalGangsterTicket has key {
        id: UID,
        warehouseId: ID,
        phase: u8,
    }

    // === Events ===
    
    public struct MintClaimedEvent has copy, drop {
        nft_id: ID,
        nft_number: u64,
        claimed_by: address,
        kiosk_id: ID,
    }

    public struct MintEvent has copy, drop {
        mint_id: ID,
        nft_id: ID,
        nft_number: u64,
        minted_by: address,
    }

    // Mint Admin cap this can be used to make changes to the mint setting and warehouse
    public struct MintAdminCap has key { id: UID, `for_settings`: ID, `for_warehouse`: ID}

    public struct MintCap has key { id: UID, `for`: ID}


    // === Init Function ===

    fun init(
        otw: MINT,
        ctx: &mut TxContext,
    ) {
        let publisher = package::claim(otw, ctx);

        let mut wl_ticket_display = display::new<WhitelistTicket>(&publisher, ctx);
        wl_ticket_display.add(b"name".to_string(), b"name".to_string());
        wl_ticket_display.add(b"description".to_string(), b"description".to_string());
        wl_ticket_display.add(b"number".to_string(), b"{number}".to_string());
        wl_ticket_display.add(b"image_url".to_string(), b"image_url".to_string());
        wl_ticket_display.update_version();
        transfer::public_transfer(wl_ticket_display, ctx.sender());

        let mut og_ticket_display = display::new<OriginalGangsterTicket>(&publisher, ctx);
        og_ticket_display.add(b"name".to_string(), b"name".to_string());
        og_ticket_display.add(b"description".to_string(), b"description".to_string());
        og_ticket_display.add(b"number".to_string(), b"{number}".to_string());
        og_ticket_display.add(b"image_url".to_string(), b"image_url".to_string());
        og_ticket_display.update_version();
        transfer::public_transfer(og_ticket_display, ctx.sender());

        transfer::public_transfer(publisher, ctx.sender());
    }

     // === Public-view Functions ===

    public fun get_mintwarehouse_length(self: &MintWarehouse) : u64 {
        self.nfts.length()
    }

    public fun get_mint_reveal(self: &Mint) : bool {
        self.is_revealed
    }

    // === Public-Mutative Functions ===








    public entry fun public_mint_test(
        waterCooler: &WaterCooler,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        // kiosk: &mut Kiosk,
        // kiosk_owner_cap: KioskOwnerCap,
        // policy: &TransferPolicy<MizuNFT>,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.nfts.length() > 0, EWarehouseIsEmpty);
        assert!(settings.phase == 3, EWrongPhase);
        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        // mint_internal_test(waterCooler, warehouse, payment, ctx);
        mint_internal_test_updated(waterCooler, warehouse, payment, ctx);
    }


















    public entry fun public_mint(
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.nfts.length() > 0, EWarehouseIsEmpty);
        assert!(settings.phase == 3, EWrongPhase);
        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(warehouse, payment, ctx);
    }

    public fun whitelist_mint(
        ticket: WhitelistTicket,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let WhitelistTicket { id, warehouseId, phase } = ticket;
        id.delete();

        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
        assert!(warehouseId == object::id(warehouse), EInvalidTicketForMintPhase);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(warehouse, payment, ctx);
    }

    public fun og_mint(
        ticket: OriginalGangsterTicket,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        let OriginalGangsterTicket { id, warehouseId, phase } = ticket;
        id.delete();

        assert!(settings.status == MINT_STATE_ACTIVE, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
        assert!(warehouseId == object::id(warehouse), EInvalidTicketForMintPhase);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(warehouse, payment, ctx);
    }

    public fun claim_mint(
        water_cooler: &mut WaterCooler,
        mut mint: Mint,
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        policy: &TransferPolicy<MizuNFT>,
        ctx: &TxContext,
    ) {
        // assert!(mint.is_revealed == true, EMizuNFTNotRevealed);

        // Extract MizuNFT and payment from Mint.
        let nft = mint.nft.extract();
        let payment = mint.payment.extract();

        event::emit(
            MintClaimedEvent {
                nft_id: object::id(&nft),
                nft_number: nft.number(),
                claimed_by: ctx.sender(),
                kiosk_id: object::id(kiosk),
            }
        );

        // Lock MizuNFT into buyer's kiosk.
        kiosk.lock(kiosk_owner_cap, policy, nft);
        // collect payment
        water_cooler.add_balance(payment);
        // Destroy the mint.
        destroy_mint_internal(mint);
    }

    // === Admin functions ===

    /// Add MizuNFTs to the mint warehouse.
    public fun add_to_mint_warehouse(
        cap: &MintAdminCap,
        water_cooler: &WaterCooler,
        mut nfts: vector<MizuNFT>,
        warehouse: &mut MintWarehouse,
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
        _: &MintAdminCap,
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
        cap: &MintAdminCap,
        warehouse: MintWarehouse,
    ) {
        assert!(warehouse.nfts.is_empty(), EMintWarehouseNotEmpty);
        assert!(warehouse.is_initialized == true, EMintWarehouseNotInitialized);

        let MintWarehouse {
            id,
            nfts,
            is_initialized: _,
        } = warehouse;

        assert!(object::uid_to_inner(&id) == cap.`for_warehouse`, ENotOwner);        

        nfts.destroy_empty();
        id.delete();
    }

    // Set mint price, status, phase
    public fun set_mint_price(
        cap: &MintAdminCap,
        settings: &mut MintSettings,
        price: u64,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);        

        assert!(price >= 0, EInvalidPrice);
        settings.price = price;
    }

    public fun set_mint_status(
        cap: &MintAdminCap,
        settings: &mut MintSettings,        
        status: u8,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);
        assert!(settings.status == MINT_STATE_INACTIVE || settings.status == MINT_STATE_ACTIVE, EInvalidStatusNumber);
        settings.status = status;
    }

    public fun set_mint_phase(
        cap: &MintAdminCap,
        settings: &mut MintSettings,
        phase: u8,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);
        assert!(phase >= 1 && phase <= 3, EInvalidPhaseNumber);
        settings.phase = phase;
    }

    public fun create_og_ticket(
        _: &MintAdminCap,
        warehouse: &MintWarehouse,
        owner: address,
        ctx: &mut TxContext
    ) {
        let og_ticket =  OriginalGangsterTicket {
            id: object::new(ctx),
            warehouseId: object::id(warehouse),
            phase: 1,
        };

        transfer::transfer(og_ticket, owner);
    }

    public fun create_wl_ticket(_: &MintAdminCap, warehouse: &MintWarehouse, owner: address, ctx: &mut TxContext) {
        let whitelist_ticket =  WhitelistTicket {
            id: object::new(ctx),
            warehouseId: object::id(warehouse),
            phase: 2,
        };

        transfer::transfer(whitelist_ticket, owner);
    }
    
    public fun reveal_mint(
        cap: &MintCap,
        mint: &mut Mint,
        attributes: Attributes,
        image: Image,
        image_url: String,
    ) {
        assert!(object::id(mint) == cap.`for`, ENotOwner);
        let nft = option::borrow_mut(&mut mint.nft);

        mizu_nft::set_attributes(nft, attributes);
        mizu_nft::set_image(nft, image);
        mizu_nft::set_image_url(nft, image_url);

        mint.is_revealed = true;
    }

    // Modify wl & og tickets display
    public fun set_wl_ticket_display_name(
        wl_ticket_display: &mut Display<WhitelistTicket>, 
        new_name: String
    ) {
        wl_ticket_display.edit(b"name".to_string(), new_name);
    }

    public fun set_wl_ticket_display_image(
        wl_ticket_display: &mut Display<WhitelistTicket>, 
        new_image: String
    ) {
        wl_ticket_display.edit(b"image_url".to_string(), new_image);
    }

    public fun set_og_ticket_display_name(
        wl_ticket_display: &mut Display<OriginalGangsterTicket>, 
        new_name: String
    ) {
        wl_ticket_display.edit(b"name".to_string(), new_name);
    }

    public fun set_og_ticket_display_image(
        wl_ticket_display: &mut Display<OriginalGangsterTicket>, 
        new_image: String
    ) {
        wl_ticket_display.edit(b"image_url".to_string(), new_image);
    }

    // === Package functions ===

    public(package) fun create_mint_distributer(ctx: &mut TxContext): (MintSettings, MintWarehouse) {
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        let mint_settings = MintSettings {
            id: object::new(ctx),
            price: 0,
            phase: 0,
            status: 0,
        };
        
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        let mint_warehouse = MintWarehouse {
            id: object::new(ctx),
            nfts: table_vec::empty(ctx),
            is_initialized: false,
        };

        // Here we transfer the mint admin cap to the person that bought the WaterCooler
        transfer::transfer(
            MintAdminCap {
                id: object::new(ctx),
                `for_settings`: object::id(&mint_settings),
                `for_warehouse`: object::id(&mint_warehouse)
            },
             ctx.sender()
        );

        (mint_settings, mint_warehouse)
    }
    
    #[allow(lint(share_owned))]
    public(package) fun transfer_mint_setting(self: MintSettings) {
        transfer::share_object(self);
    }

    #[allow(lint(share_owned))]
    public(package) fun transfer_mint_warehouse(self: MintWarehouse) {
        transfer::share_object(self);
    }

    // === Private Functions ===









    #[allow(lint(self_transfer))]
    public fun mint_internal_test_updated(
        waterCooler: &WaterCooler,
        warehouse: &mut MintWarehouse,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        // Safely unwrap the NFT from the warehouse
        let mut nft = warehouse.nfts.pop_back();

        // Create a new kiosk and its owner capability
        let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

        // Place the NFT in the kiosk
        kiosk::place(&mut kiosk, &kiosk_owner_cap, nft);

        // Transfer the kiosk owner capability to the sender
        transfer::public_transfer(kiosk_owner_cap, ctx.sender());

        // Share the kiosk object publicly
        transfer::public_share_object(kiosk);

        // Send the payment to the water cooler
        waterCooler.send_fees(payment);
    }






    #[allow(lint(self_transfer))]
    fun mint_internal_test(
        waterCooler: &WaterCooler,
        warehouse: &mut MintWarehouse,
        // policy: &TransferPolicy<MizuNFT>,
        // kiosk: &mut Kiosk,
        // kiosk_owner_cap: KioskOwnerCap,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let mut nft = warehouse.nfts.pop_back();

        let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

        kiosk::set_owner_custom(&mut kiosk, &kiosk_owner_cap, object::id_address(&nft));

        transfer::public_transfer(kiosk_owner_cap, object::id_to_address(&object::id(&nft)));
        transfer::public_share_object(kiosk);


        waterCooler.send_fees(payment);

        transfer::public_transfer(nft, ctx.sender());
        
    }























    #[allow(lint(self_transfer))]
    fun mint_internal(
        warehouse: &mut MintWarehouse,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let nft = warehouse.nfts.pop_back();

        let mut mint = Mint {
            id: object::new(ctx),
            number: nft.number(),
            nft: option::none(),
            payment: option::some(payment),
            is_revealed: false,
            minted_by: ctx.sender(),
            claim_expiration_epoch: ctx.epoch() + EPOCHS_TO_CLAIM_MINT,
        };

        let attributes_cap = attributes::issue_create_attributes_cap(0, ctx);
        let image_cap = image::issue_create_image_cap(0, object::id(&mint), ctx);

        let cap = MintCap {
            id: object::new(ctx),
            `for`: object::id(&mint)
        };

        event::emit(
            MintEvent {
                mint_id: object::id(&mint),
                nft_id: object::id(&nft),
                nft_number: nft.number(),
                minted_by: ctx.sender(),
            }
        );

        mint.nft.fill(nft);
        let nft_mut = mint.nft.borrow_mut();
        nft_mut.set_minted_by_address(ctx.sender());
        
        transfer::transfer(cap, ctx.sender());
        transfer::public_transfer(attributes_cap, ctx.sender());
        transfer::public_transfer(image_cap, ctx.sender());
        transfer::share_object(mint);
    }

    fun destroy_mint_internal(mint: Mint) {
        let Mint {
            id,
            number: _,
            nft,
            payment,
            is_revealed: _,
            minted_by: _,
            claim_expiration_epoch: _,
        } = mint;
        
        option::destroy_none(nft);
        option::destroy_none(payment);
        object::delete(id);
    }

    // === Test Functions ===
    #[test_only]
    public fun init_for_mint(ctx: &mut TxContext) {
        init(MINT {}, ctx);
    }

    #[test_only]
    public fun get_nft_id(self: &Mint) : ID {
       let nft = self.nft.borrow();
       object::id(nft)
    }
}
