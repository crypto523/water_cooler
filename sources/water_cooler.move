module galliun::water_cooler {
  use std::option::{Self, Option};
  use std::string::{Self, String};
  use std::vector::{Self};

  use sui::display::{Self};
  use sui::kiosk::{Self, Kiosk, KioskOwnerCap};
  use sui::package::{Self, Publisher};
  use sui::sui::SUI;
  use sui::balance::{Self, Balance};
  use sui::object::{Self, ID, UID};
  use sui::object_table::{Self, ObjectTable};
  use sui::transfer_policy::{Self};

  use galliun::attributes::{Attributes};

  // === Errors ===

    const EWaterCoolerAlreadyInitialized: u64 = 0;
    const EWaterCoolerNotInitialized: u64 = 1;
    const EWaterCoolerNotEmpty: u64 = 2;
    const EAttributesAlreadySet: u64 = 3;
    const EImageAlreadySet: u64 = 4;
    const EImageNotSet: u64 = 5;

  // This is the structure that will be used to create the NFTs
  public struct MizuNFT has key, store {
    id: UID,
    // This name will be joined with the number to create the NFT name
    collection_name: String,
    description: String,
    // This url will be joined with the id to create the image url
    image_url: String,
    number: u16,
    attributes: Option<Attributes>,
    image: Option<String>,
    minted_by: Option<address>,
    // ID of the Kiosk assigned to the NFT.
    kiosk_id: ID,
    // ID of the KioskOwnerCap owned by the NFT.
    kiosk_owner_cap_id: ID,
  }

  // This is the structure of WaterCooler that will be loaded with and distribute the NFTs
  public struct WaterCooler has key, store {
    id: UID,
    name: String,
    description: String,
    // We concatinate this url with the number of the NFT in order to find it on chain
    image_url: String,
    // This is so we have the address of the person that created the Water Cooler
    owner: address,
    // This is the address to where the royalty and mint fee will be sent
    treasury: address,
    // This table will keep track of all the created NFTs
    nfts: ObjectTable<u16, MizuNFT>,
    // This is the number of NFTs that will be in the collection
    size: u16,
    is_initialized: bool
  }

  public struct WATER_COOLER has drop {}

  // Admin cap of this Water Cool to be used but the Cooler owner when making changes
  public struct WaterCoolerAdminCap has key { id: UID }

  fun init(otw: WATER_COOLER, ctx: &mut TxContext,) {
    // Claim the Publisher object.
    let publisher = sui::package::claim(otw, ctx);

    let mut display = display::new<MizuNFT>(&publisher, ctx);
    display::add(&mut display, string::utf8(b"name"), string::utf8(b"{collection_name} #{number}"));
    display::add(&mut display, string::utf8(b"description"), string::utf8(b"{description}"));
    display::add(&mut display, string::utf8(b"image_url"), string::utf8(b"{image_url}/{id}"));
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

  // The function that allow the Cooler Factory to create coolers and give them to creators
  public(package) fun createWaterCooler(name: String, description: String, image_url: String, size: u16, treasury: address, ctx: &mut TxContext) {
    let sender = tx_context::sender(ctx);

    let waterCooler = WaterCooler {
      id: object::new(ctx),
      name,
      description,
      image_url,
      owner: sender,
      nfts: object_table::new(ctx),
      treasury,
      size,
      is_initialized: false
    };

    transfer::transfer(WaterCoolerAdminCap{ id: object::new(ctx) }, sender);
    transfer::transfer(waterCooler, sender);
  }



  // === Admin Functions ===
  #[allow(lint(share_owned))]
    public fun admin_initialize_water_cooler(
        _: &WaterCoolerAdminCap,
        waterCooler: &mut WaterCooler,
        ctx: &mut TxContext,
    ) {
      assert!(waterCooler.is_initialized == false, EWaterCoolerAlreadyInitialized);

      let mut number: u16 = (object_table::length(&waterCooler.nfts) as u16) + 1;

      // Pre-fill the water cooler with the kiosk NFTs to the size of the NFT collection
      while (number <= waterCooler.size) {

        let (mut kiosk, kiosk_owner_cap) = kiosk::new(ctx);

        let pfp = MizuNFT {
          id: object::new(ctx),
          number: number,
          collection_name: waterCooler.name,
          description: waterCooler.description,
          image_url: waterCooler.image_url,
          attributes: option::none(),
          image: option::none(),
          minted_by: option::none(),
          kiosk_id: object::id(&kiosk),
          kiosk_owner_cap_id: object::id(&kiosk_owner_cap),
        };


        // Set the Kiosk's 'owner' field to the address of the MizuNFT.
        kiosk::set_owner_custom(&mut kiosk, &kiosk_owner_cap, object::id_address(&pfp));

        transfer::public_transfer(kiosk_owner_cap, object::id_to_address(&object::id(&pfp)));
        transfer::public_share_object(kiosk);

        // Add MizuNFT to factory.
        object_table::add(&mut waterCooler.nfts, number, pfp);

        number = number + 1;
      };

      // Initialize water cooler if the number of NFT created is equal to the size of the collection.
      if ((object_table::length(&waterCooler.nfts) as u16) == waterCooler.size) {
          waterCooler.is_initialized = true;
      };
    }

  }
