#[test_only]
module galliun::test_claim_mint {
    // === Imports ===
    use sui::{
        test_scenario::{Self as ts, next_tx},
        coin::{Self},
        sui::SUI,
        test_utils::{assert_eq},
        kiosk::{Self},
        transfer_policy::{TransferPolicy}
    };
    use std::string::{Self, String};
    use galliun::{
        helpers::{init_test_helper},
        water_cooler::{Self, WaterCooler, WaterCoolerAdminCap},
        mizu_nft::{MizuNFT},
        cooler_factory::{Self, CoolerFactory},
        mint::{Self, Mint, MintCap, MintAdminCap, MintSettings, MintWarehouse, OriginalGangsterTicket},
        attributes::{Self, Attributes, CreateAttributesCap},
        collection::{Collection},
        registry::{Registry},
        image::{Self, Image}
    };

    // === Constants ===
    // const ADMIN: address = @0xA;
    const TEST_ADDRESS1: address = @0xB;
    // const TEST_ADDRESS2: address = @0xC;

    // === Test functions ===

    #[test]
    #[expected_failure(abort_code = 0000000000000000000000000000000000000000000000000000000000000002::kiosk::EItemLocked)]    
    public fun test_claim_mint() {

        let mut scenario_test = init_test_helper();
        let scenario = &mut scenario_test;
        
           // User has to buy water_cooler from cooler_factory share object. 
        next_tx(scenario, TEST_ADDRESS1);
        {
            let mut cooler_factory = ts::take_shared<CoolerFactory>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(100_000_000, ts::ctx(scenario));
            
            let name = b"watercoolername".to_string();
            let description = b"some desc".to_string();
            let image_url = b"https://media.nfts.photos/nft.jpg".to_string();
            let placeholder_image_url = b"https://media.nfts.photos/placeholder.jpg".to_string();
            let supply = 150;

            cooler_factory::buy_water_cooler(
                &mut cooler_factory,
                coin_,
                name,
                description,
                image_url,
                placeholder_image_url,
                supply,
                TEST_ADDRESS1,
                ts::ctx(scenario)
            );
            // check the balance 
            assert_eq(cooler_factory.get_balance(), 100_000_000);

            ts::return_shared(cooler_factory);
        };

        // init WaterCooler. the number count to 1. So it is working. 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let water_cooler_admin_cap = ts::take_from_sender<WaterCoolerAdminCap>(scenario);
            let mut registry = ts::take_from_sender<Registry>(scenario);
            let collection = ts::take_from_sender<Collection>(scenario);

            water_cooler::initialize_water_cooler(&water_cooler_admin_cap, &mut water_cooler, &mut registry, &collection, ts::ctx(scenario));

            ts::return_shared(water_cooler);
            ts::return_to_sender(scenario, collection);
            ts::return_to_sender(scenario, registry);
            ts::return_to_sender(scenario, water_cooler_admin_cap);
        };

        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            // Check Nft Created
            assert!(ts::has_most_recent_for_sender<MizuNFT>(scenario), 0);
            assert!(water_cooler.is_initialized() == true, 0);
            // the number of supply should be stay as 150. 
            assert_eq(water_cooler.supply(), 150);
            // in the vec_map the nft ID 's are must be 150. 
            assert_eq(water_cooler.get_nfts_num(), 150);
            ts::return_shared(water_cooler);
        };
        // we can push MizuNFT into the warehouse
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<MintAdminCap>(scenario);
            let water_cooler = ts::take_shared<WaterCooler>(scenario);
            let mut mint_warehouse = ts::take_shared<MintWarehouse>(scenario);
            let nft = ts::take_from_sender<MizuNFT>(scenario);
            let mut vector_mizu = vector::empty<MizuNFT>();
            vector_mizu.push_back(nft);

            mint::add_to_mint_warehouse(
                &mint_cap,
                &water_cooler,
                vector_mizu,
                &mut mint_warehouse
            );
            // the nft's length should be equal to 1 
            assert_eq(mint::get_mintwarehouse_length(&mint_warehouse), 1);
    
            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_warehouse);
            ts::return_shared(water_cooler);
        };
        // set mint_price and status
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<MintAdminCap>(scenario);
            let mut mint_settings = ts::take_shared<MintSettings>(scenario);
            let price: u64 = 1_000_000_000;
            let status: u8 = 1;
            let phase: u8 = 1;

            mint::set_mint_price(&mint_cap, &mut mint_settings, price);
            mint::set_mint_status(&mint_cap, &mut mint_settings, status);
            mint::set_mint_phase(&mint_cap, &mut mint_settings, phase);

            ts::return_to_sender(scenario, mint_cap);
      
            ts::return_shared(mint_settings);
        };

        // we must create WhitelistTicket 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<MintAdminCap>(scenario);
            let mint_warehouse = ts::take_shared<MintWarehouse>(scenario);
            mint::create_og_ticket(&mint_cap, &mint_warehouse, TEST_ADDRESS1, ts::ctx(scenario));
            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_warehouse);
        };

        // we can do whitelist_mint 
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_settings = ts::take_shared<MintSettings>(scenario);
            let mut mint_warehouse = ts::take_shared<MintWarehouse>(scenario);
            let ticket = ts::take_from_sender<OriginalGangsterTicket>(scenario);
            let coin_ = coin::mint_for_testing<SUI>(1_000_000_000, ts::ctx(scenario));

            mint::og_mint(ticket, &mut mint_warehouse, &mint_settings, coin_, ts::ctx(scenario));
            
            ts::return_shared(mint_warehouse);
            ts::return_shared(mint_settings);
        };

        // user needs to create Attributes and set the reveal_mint function
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let attributes_cap = ts::take_from_sender<CreateAttributesCap>(scenario);
            let mut key_vector = vector::empty<String>();
            let key1 = string::utf8(b"key1");
            let key2 = string::utf8(b"key2");
            key_vector.push_back(key1);
            key_vector.push_back(key2);

            let mut values_vector = vector::empty<String>();
            let value1 = string::utf8(b"value1");
            let value2 = string::utf8(b"value2");
            values_vector.push_back(value1);
            values_vector.push_back(value2);

            let attributes = attributes::new(
                attributes_cap,
                key_vector,
                values_vector,
                ts::ctx(scenario)
            );
            transfer::public_transfer(attributes, TEST_ADDRESS1);
        }; 

        // user needs to create Attributes and set the reveal_mint function
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mut _mint = ts::take_shared<Mint>(scenario);
            let image_ = string::utf8(b"image");

            let mut image_chunk_hashes = vector::empty<String>();
            let value1 = string::utf8(b"value1");
            let value2 = string::utf8(b"value2");

            image_chunk_hashes.push_back(value1);
            image_chunk_hashes.push_back(value2);

            let nft_id = mint::get_nft_id(&_mint);

            let image_cap = image::issue_create_image_cap(25, nft_id, ts::ctx(scenario));
            image::create_image(
                image_cap,
                image_,
                image_chunk_hashes,
                ts::ctx(scenario)
            );
            ts::return_shared(_mint);

        };
        // set the reveal_mint
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let mint_cap = ts::take_from_sender<MintCap>(scenario);
            let mut mint_ = ts::take_shared<Mint>(scenario);
            let attributes = ts::take_from_sender<Attributes>(scenario);
            let image_ = string::utf8(b"image");

            let image = ts::take_from_sender<Image>(scenario);

            mint::reveal_mint(
                &mint_cap,
                &mut mint_,
                attributes,
                image,
                image_
            );

            assert_eq(mint::get_mint_reveal(&mint_), true);

            ts::return_to_sender(scenario, mint_cap);
            ts::return_shared(mint_);
        };
        // user needs to creat his own kiosk
        ts::next_tx(scenario, TEST_ADDRESS1);
        {
            let (mut kiosk, cap) = kiosk::new(ts::ctx(scenario));
            let mut water_cooler = ts::take_shared<WaterCooler>(scenario);
            let mint = ts::take_shared<Mint>(scenario);
            let policy = ts::take_shared<TransferPolicy<MizuNFT>>(scenario);
            let nft_id = mint::get_nft_id(&mint);

            mint::claim_mint(
                &mut water_cooler,
                mint,
                &mut kiosk,
                &cap,
                &policy,
                ts::ctx(scenario)
            );
            assert_eq(kiosk::has_item(&kiosk, nft_id), true);
            assert_eq(kiosk::is_locked(&kiosk, nft_id), true);
            assert_eq(kiosk::is_listed(&kiosk, nft_id), false);
            assert_eq(kiosk::item_count(&kiosk), 1);

            // we are expecting an error. we cant take that nft. 
            let item = kiosk::take<MizuNFT>(
                &mut kiosk,
                &cap,
                nft_id
            );

            transfer::public_transfer(item, TEST_ADDRESS1);
            
            transfer::public_transfer(cap, TEST_ADDRESS1);
            transfer::public_share_object(kiosk);
            ts::return_shared(water_cooler);
            ts::return_shared(policy);
        }; 
           
        ts::end(scenario_test);
    }
}