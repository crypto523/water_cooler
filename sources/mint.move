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
        attributes::Attributes,
        water_cooler::{Self, MizuNFT, WaterCooler},
    };

    // === Errors ===

    const EInvalidPaymentAmount: u64 = 4;
    const EInvalidPhaseNumber: u64 = 5;
    const EInvalidPrice: u64 = 6;
    const EInvalidStatusNumber: u64 = 9;
    const EInvalidTicketForMintPhase: u64 = 10;
    const EMintNotLive: u64 = 17;
    const EMintWarehouseAlreadyInitialized: u64 = 19;
    const EMintWarehouseNotEmpty: u64 = 20;
    const EMintWarehouseNotInitialized: u64 = 21;
    const EMizuNFTNotRevealed: u64 = 22;
    const EWarehouseIsEmpty: u64 = 23;

    // === Constants ===

    const EPOCHS_TO_CLAIM_MINT: u64 = 30;

    // === Structs ===

    public struct MINT has drop {}

    public struct Mint has key {
        id: UID,
        number: u16,    
        nft: Option<MizuNFT>,
        payment: Option<Coin<SUI>>,
        is_revealed: bool,
        minted_by: address,
        claim_expiration_epoch: u64,
    }


    public struct MintSettings has key {
        id: UID,
        price: u64,
        phase: u8,
        status: u8,
    }

    public struct MintWarehouse has key {
        id: UID,
        nfts: TableVec<MizuNFT>,
        is_initialized: bool,
    }

    public struct WhitelistTicket has key {
        id: UID,
        phase: u8,
    }

    public struct OriginalGangsterTicket has key {
        id: UID,
        phase: u8,
    }

    // === Events ===
    
    public struct MintClaimedEvent has copy, drop {
        nft_id: ID,
        nft_number: u16,
        claimed_by: address,
        kiosk_id: ID,
    }

    public struct MintEvent has copy, drop {
        mint_id: ID,
        nft_id: ID,
        nft_number: u16,
        minted_by: address,
    }

    // Mint Admin cap this can be used to make changes to the mint setting and warehouse
    public struct MintAdminCap has key { id: UID }

    // === Init Function ===

    #[allow(unused_variable)]
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

    public(package) fun create_mint_distributer(ctx: &mut TxContext) {
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

        let adminCap = MintAdminCap{ id: object::new(ctx) };

        // Here we transfer the mint admin cap to the person that bought the WaterCooler
        transfer::transfer(adminCap, ctx.sender());

      // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        transfer::share_object(mint_settings);
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        transfer::share_object(mint_warehouse);
    }

    public(package) fun create_wl_distributer(ctx: &mut TxContext) {
        let whitelist_ticket =  WhitelistTicket {
            id: object::new(ctx),
            phase: 0,
        };

        transfer::transfer(whitelist_ticket, ctx.sender());
    }

    public(package) fun create_og_distributer(ctx: &mut TxContext) {
        let og_ticket =  OriginalGangsterTicket {
            id: object::new(ctx),
            phase: 0,
        };

        transfer::transfer(og_ticket, ctx.sender());
    }

    // === Public-Mutative Functions ===

    public fun public_mint(
        payment: Coin<SUI>,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.nfts.length() > 0, EWarehouseIsEmpty);

        assert!(settings.status == 1, EMintNotLive);

        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        let nft = warehouse.nfts.pop_back();

        mint_internal(nft, payment, ctx);
    }

    public fun whitelist_mint(
        ticket: WhitelistTicket,
        payment: Coin<SUI>,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        ctx: &mut TxContext,
    ) {
        assert!(settings.status == 1, EMintNotLive);
        assert!(ticket.phase == settings.phase, EInvalidTicketForMintPhase);

        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        let nft = warehouse.nfts.pop_back();
        mint_internal(nft, payment, ctx);

        let WhitelistTicket { id, phase: _ } = ticket;
        id.delete();
    }

    public fun og_mint(
        ticket: OriginalGangsterTicket,
        payment: Coin<SUI>,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        ctx: &mut TxContext,
    ) {
        assert!(settings.status == 1, EMintNotLive);
        assert!(ticket.phase == settings.phase, EInvalidTicketForMintPhase);

        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        let nft = warehouse.nfts.pop_back();
        mint_internal(nft, payment, ctx);

        let OriginalGangsterTicket { id, phase: _ } = ticket;
        id.delete();
    }

    public fun claim_mint(
        water_cooler: &WaterCooler,
        mint: &mut Mint,
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        policy: &TransferPolicy<MizuNFT>,
        ctx: &TxContext,
    ) {
        assert!(mint.is_revealed == true, EMizuNFTNotRevealed);

        // Extract MizuNFT and payment from Mint.
        let nft = mint.nft.extract();
        let payment = mint.payment.extract();

        event::emit(
            MintClaimedEvent {
                nft_id: nft.id(),
                nft_number: nft.number(),
                claimed_by: ctx.sender(),
                kiosk_id: object::id(kiosk),
            }
        );

        // Lock MizuNFT into buyer's kiosk.
        kiosk.lock(kiosk_owner_cap, policy, nft);

        // Transfer payment to Water cooler owner.
        transfer::public_transfer(payment, water_cooler.owner());

        // Destroy the mint.
        // destroy_mint_internal(mint);
    }

    /// Add MizuNFTs to the mint warehouse.
    public fun admin_add_to_mint_warehouse(
        _: &MintAdminCap,
        water_cooler: &WaterCooler,
        nfts: &mut vector<MizuNFT>,
        warehouse: &mut MintWarehouse,
    ) {
        assert!(warehouse.is_initialized == false, EMintWarehouseAlreadyInitialized);

        while (!nfts.is_empty()) {
            let pfp = nfts.pop_back();
            warehouse.nfts.push_back(pfp);
        };

        if (warehouse.nfts.length() == water_cooler.size() as u64) {
            warehouse.is_initialized = true;
        };
        
        // vector::destroy_empty(nfts);
    }


    /// Destroy an empty mint warehouse when it's no longer needed.
    public fun admin_destroy_mint_warehouse(
        _: &MintAdminCap,
        warehouse: MintWarehouse,
    ) {
        assert!(warehouse.nfts.is_empty(), EMintWarehouseNotEmpty);
        assert!(warehouse.is_initialized == true, EMintWarehouseNotInitialized);

        let MintWarehouse {
            id,
            nfts,
            is_initialized: _,
        } = warehouse;

        nfts.destroy_empty();
        id.delete();
    }

    // Set mint price, status, phase
    public fun admin_set_mint_price(
        _: &MintAdminCap,
        price: u64,
        settings: &mut MintSettings,
    ) {
        assert!(price > 0, EInvalidPrice);
        settings.price = price;
    }

    public fun admin_set_mint_status(
        _: &MintAdminCap,
        status: u8,
        settings: &mut MintSettings,
    ) {
        assert!(settings.status == 0 || settings.status == 1, EInvalidStatusNumber);
        settings.status = status;
    }

    public fun admin_set_mint_phase(
        _: &MintAdminCap,
        phase: u8,
        settings: &mut MintSettings,
    ) {
        assert!(phase >= 1 && phase <= 3, EInvalidPhaseNumber);
        settings.phase = phase;
    }

    public fun admin_reveal_mint(
        _: &MintAdminCap,
        mint: &mut Mint,
        attributes: Attributes,
        image: String
    ) {
        let nft = option::borrow_mut(&mut mint.nft);

        water_cooler::set_attributes(nft, attributes);
        water_cooler::set_image(nft, image);

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

    fun mint_internal(
        nft: MizuNFT,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let mut mint = Mint {
            id: object::new(ctx),
            number: nft.number(),
            nft: option::none(),
            payment: option::some(payment),
            is_revealed: false,
            minted_by: ctx.sender(),
            claim_expiration_epoch: ctx.epoch() + EPOCHS_TO_CLAIM_MINT,
        };

        event::emit(
            MintEvent {
                mint_id: object::id(&mint),
                nft_id: nft.id(),
                nft_number: nft.number(),
                minted_by: ctx.sender(),
            }
        );

        mint.nft.fill(nft);
        let nftMut = mint.nft.borrow_mut();
        nftMut.set_minted_by_address(ctx.sender());

        transfer::share_object(mint);
    }

    fun destroy_mint_internal(
        mint: Mint,
    ) {
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
    public fun init_for_testing(ctx: &mut TxContext) {
        init(MINT {}, ctx);
    }
}