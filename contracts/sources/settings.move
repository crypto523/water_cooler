module galliun::settings {
  // === Imports ===
    use sui::{
        // coin::Coin,
        coin::{Self, Coin},
        display::{Self},
        kiosk::{Self},
        package::{Self},
        sui::{SUI},
        table_vec::{Self, TableVec},
        transfer_policy::{TransferPolicy},
    };
    use galliun::{
        // attributes::{Self},
        factory_settings::{FactorySetings},
        water_cooler::{Self, WaterCooler},
        capsule::{Capsule},
        // image::{Image},
        // registry::{Registry}
    };

    // === Errors ===

    // === Structs ===

    public struct Settings has key {
        id: UID,
        // We add this id so we can insure that the water cooler that
        // is passed coresponds with the current mint settings
        // We have to add it here because we cannot do the check in the
        // watercooler module as there will be a circular dependency
        // between the Setting in the Mint module and the Water Cooler
        // in the watercooler modules
        // waterCoolerId: ID,
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

    // Admin cap of this registry can be used to make changes to the Registry
    public struct SettingsAdminCap has key { id: UID }


    // === Package Functions ===

    public(package) fun new(
        ctx: &mut TxContext,
    ): Settings {
        Settings {
            id: object::new(ctx),
            price: 0,
            phase: 0,
            status: 0,
        }
    }

    // === Public view functions ===
    public(package) fun uid_mut(self: &mut Settings): &mut UID {
        &mut self.id
    }

    public(package) fun price(
        self: &Settings,
    ): u64 {
        self.price
    }

    public(package) fun phase(
        self: &Settings,
    ): u8 {
        self.phase
    }

    public(package) fun status(
        self: &Settings,
    ): u8 {
        self.status
    }


    #[allow(lint(share_owned))]
    public(package) fun transfer_setting(self: Settings, ctx: &mut TxContext,) {
        transfer::transfer(SettingsAdminCap { id: object::new(ctx) }, ctx.sender());
        transfer::share_object(self);
    }
    
    public(package) fun set_price(self: &mut Settings, price: u64) {
        self.price = price;
    }

    public(package) fun set_status(self: &mut Settings, status: u8) {
        self.status = status;
    }
    
    public(package) fun set_phase(self: &mut Settings, phase: u8) {
        self.phase = phase;
    }
}