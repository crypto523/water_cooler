module galliun::mint {
    // === Imports ===

    use std::string::String;
    use sui::{
        coin::Coin,
        display::{Self, Display},
        event,
        kiosk::{Kiosk, KioskOwnerCap},
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
    const ENotOwner: u64 = 0;
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
        number: u64,    
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

    // === Public-Mutative Functions ===

    public fun public_mint(
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        payment: Coin<SUI>,        
        ctx: &mut TxContext,
    ) {
        assert!(warehouse.nfts.length() > 0, EWarehouseIsEmpty);
        assert!(settings.status == 1, EMintNotLive);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(warehouse, payment, ctx);
    }

    public fun whitelist_mint(
        ticket: WhitelistTicket,
        payment: Coin<SUI>,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        ctx: &mut TxContext,
    ) {
        let WhitelistTicket { id, phase } = ticket;
        id.delete();

        assert!(settings.status == 1, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
        assert!(payment.value() == settings.price, EInvalidPaymentAmount);

        mint_internal(warehouse, payment, ctx);
    }

    public fun og_mint(
        ticket: OriginalGangsterTicket,
        payment: Coin<SUI>,
        warehouse: &mut MintWarehouse,
        settings: &MintSettings,
        ctx: &mut TxContext,
    ) {
        let OriginalGangsterTicket { id, phase } = ticket;
        id.delete();

        assert!(settings.status == 1, EMintNotLive);
        assert!(phase == settings.phase, EInvalidTicketForMintPhase);
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
        assert!(mint.is_revealed == true, EMizuNFTNotRevealed);

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

        if (warehouse.nfts.length() == water_cooler.supply()) {
            warehouse.is_initialized = true;
        };
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

        assert!(price > 0, EInvalidPrice);
        settings.price = price;
    }

    public fun set_mint_status(
        cap: &MintAdminCap,
        settings: &mut MintSettings,        
        status: u8,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);        
        assert!(settings.status == 0 || settings.status == 1, EInvalidStatusNumber);
        settings.status = status;
    }

    public fun set_mint_phase(
        cap: &MintAdminCap,
        phase: u8,
        settings: &mut MintSettings,
    ) {
        assert!(object::id(settings) == cap.`for_settings`, ENotOwner);        
        assert!(phase >= 1 && phase <= 3, EInvalidPhaseNumber);
        settings.phase = phase;
    }
    // FIXME: we should discuss 
    public fun reveal_mint(
        cap: &MintAdminCap,
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

    // === Package functions ===

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

        // Here we transfer the mint admin cap to the person that bought the WaterCooler
        transfer::transfer(MintAdminCap{
             id: object::new(ctx),
            `for_settings`: object::id(&mint_settings),
            `for_warehouse`: object::id(&mint_warehouse)},
             ctx.sender());

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

    // === Private Functions ===

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

    public fun get_mintwarehouse_length(self: &MintWarehouse) : u64 {
        self.nfts.length()
    }

    // === Test Functions ===
    #[test_only]
    public fun init_for_mint(ctx: &mut TxContext) {
        init(MINT {}, ctx);
    }
}