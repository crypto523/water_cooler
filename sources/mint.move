module galliun::mint {

    // === Imports ===
    use std::string::{Self, String};

    use sui::coin::{Self, Coin};
    use sui::display::{Self};
    use sui::event;
    use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
    use sui::object_table::{Self, ObjectTable};
    use sui::package::{Self};
    use sui::sui::{SUI};
    use sui::table_vec::{Self, TableVec};
    use sui::transfer_policy::{TransferPolicy};

    use galliun::attributes::{Self, Attributes};
    use galliun::water_cooler::{Self , MizuNFT, WaterCooler};

    // === Errors ===

    const EInvalidDestroyCapForMintReceipt: u64 = 2;
    const EInvalidPaymentAmount: u64 = 4;
    const EInvalidPrice: u64 = 6;
    const EInvalidRevealMintCapForMint: u64 = 7;
    const EInvalidReceiptForMint: u64 = 8;
    const EInvalidStatusNumber: u64 = 9;
    const EMigrationMintWarehouseNotIntialized: u64 = 12;
    const EMigrationWarehouseAlreadyInitialized: u64 = 13;
    const EMigrationWarehouseNotEmpty: u64 = 14;
    const EMigrationWarehouseNotInitialized: u64 = 15;
    const EMintClaimPeriodNotExpired: u64 = 16;
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
        status: u8,
    }

    public struct MintWarehouse has key {
        id: UID,
        nfts: TableVec<MizuNFT>,
        is_initialized: bool,
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

      transfer::public_transfer(publisher, tx_context::sender(ctx));
    }

    public(package) fun create_mint_distributer(ctx: &mut TxContext) {
      // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        let mint_settings = MintSettings {
          id: object::new(ctx),
          price: 0,
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
        transfer::transfer(adminCap, tx_context::sender(ctx));

      // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        transfer::share_object(mint_settings);
        // This might need to be moved to a seperate function
        // that will be called by the owner of the WaterCooler
        transfer::share_object(mint_warehouse);
    }

    // === Public-Mutative Functions ===

    public fun public_mint(
      payment: Coin<SUI>,
      warehouse: &mut MintWarehouse,
      settings: &MintSettings,
      ctx: &mut TxContext,
    ) {
        assert!(table_vec::length(&warehouse.nfts) > 0, EWarehouseIsEmpty);

        assert!(settings.status == 1, EMintNotLive);

        assert!(coin::value(&payment) == settings.price, EInvalidPaymentAmount);

        let nft = table_vec::pop_back(&mut warehouse.nfts);

        mint_internal(nft, payment, ctx);
    }

    public fun claim_mint(
        waterCooler: &WaterCooler,
        mint: &mut Mint,
        kiosk: &mut Kiosk,
        kiosk_owner_cap: &KioskOwnerCap,
        policy: &TransferPolicy<MizuNFT>,
        ctx: &TxContext,
    ) {
        assert!(mint.is_revealed == true, EMizuNFTNotRevealed);

        // Extract MizuNFT and payment from Mint.
        let nft = option::extract(&mut mint.nft);
        let payment = option::extract(&mut mint.payment);

        event::emit(
          MintClaimedEvent {
            nft_id: water_cooler::id(&nft),
            nft_number: water_cooler::number(&nft),
            claimed_by: tx_context::sender(ctx),
            kiosk_id: object::id(kiosk),
          }
        );

        // Lock MizuNFT into buyer's kiosk.
        kiosk::lock(kiosk, kiosk_owner_cap, policy, nft);

        // Transfer payment to Water cooler owner.
        transfer::public_transfer(payment, water_cooler::owner(waterCooler));

        // Destroy the mint.
        // destroy_mint_internal(mint);
    }

    /// Add MizuNFTs to the mint warehouse.
    public fun admin_add_to_mint_warehouse(
        _: &MintAdminCap,
        waterCooler: &WaterCooler,
        nfts: &mut vector<MizuNFT>,
        warehouse: &mut MintWarehouse,
        _: &TxContext,
    ) {

        assert!(warehouse.is_initialized == false, EMintWarehouseAlreadyInitialized);

        while (!vector::is_empty(nfts)) {
            let pfp = vector::pop_back(nfts);
            table_vec::push_back(&mut warehouse.nfts, pfp);
        };

        if ((table_vec::length(&warehouse.nfts) as u16) == water_cooler::size(waterCooler)) {
            warehouse.is_initialized = true;
        };

        
        // vector::destroy_empty(nfts);
    }


    /// Destroy an empty mint warehouse when it's no longer needed.
    public fun admin_destroy_mint_warehouse(
        _: &MintAdminCap,
        warehouse: MintWarehouse,
        _: &TxContext,
    ) {
        assert!(table_vec::is_empty(&warehouse.nfts), EMintWarehouseNotEmpty);
        assert!(warehouse.is_initialized == true, EMintWarehouseNotInitialized);

        let MintWarehouse {
            id,
            nfts,
            is_initialized: _,
        } = warehouse;

        table_vec::destroy_empty(nfts);
        object::delete(id);
    }

    public fun admin_set_mint_price(
        _: &MintAdminCap,
        price: u64,
        settings: &mut MintSettings,
        _: &TxContext,
    ) {
        assert!(price > 0, EInvalidPrice);
        settings.price = price;
    }

    public fun admin_set_mint_status(
        _: &MintAdminCap,
        status: u8,
        settings: &mut MintSettings,
        _: &TxContext,
    ) {
        assert!(settings.status == 0 || settings.status == 1, EInvalidStatusNumber);
        settings.status = status;
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

    fun mint_internal(
        nft: MizuNFT,
        payment: Coin<SUI>,
        ctx: &mut TxContext,
    ) {
        let mut mint = Mint {
            id: object::new(ctx),
            number: water_cooler::number(&nft),
            nft: option::none(),
            payment: option::some(payment),
            is_revealed: false,
            minted_by: tx_context::sender(ctx),
            claim_expiration_epoch: tx_context::epoch(ctx) + EPOCHS_TO_CLAIM_MINT,
        };

        event::emit(
            MintEvent {
                mint_id: object::id(&mint),
                nft_id: water_cooler::id(&nft),
                nft_number: water_cooler::number(&nft),
                minted_by: tx_context::sender(ctx),
            }
        );

        option::fill(&mut mint.nft, nft);

        let nftMut = option::borrow_mut(&mut mint.nft);

        water_cooler::set_minted_by_address(nftMut, tx_context::sender(ctx));

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
}