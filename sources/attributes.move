module galliun::attributes {

    // === Imports ===

    use std::string::{String};

    use sui::object::{Self, ID, UID};
    use sui::tx_context::{TxContext};
    use sui::vec_map::{VecMap};

    // === Friends ===

    use galliun::water_cooler;

    // === Structs ===
    
    /// An object that holds a `AttributesData` object,
    /// assigned to the "attributes" field of a `NFT` object.
    public struct Attributes has key, store {
        id: UID,
        number: u16,
        fields: AttributesData
    }

    /// An object that holds the NFTs attributes.
    public struct AttributesData has store {
        map: VecMap<String, String>,
    }

    /// A cap object that gives ADMIN the ability to create
    /// `Attributes` and `AttributesData` objects.
    public  struct CreateAttributesCap has key, store {
        id: UID,
        number: u16,
    }

    /// Create an `Attributes` object with a `CreateAttributesCap`.
    public fun new(
        cap: CreateAttributesCap,
        attributes: VecMap<String, String>,
        ctx: &mut TxContext,
    ): Attributes {
        let attributes_data = AttributesData {
            map: attributes
        };

        let attributes = Attributes {
            id: object::new(ctx),
            number: cap.number,
            fields: attributes_data,
        };

        let CreateAttributesCap { id, number: _ } = cap;
        object::delete(id);

        attributes
    }

    /// Create a `CreateAttributesCap`.
    public(package) fun issue_create_attributes_cap(
        number: u16,
        ctx: &mut TxContext,
    ): CreateAttributesCap {
        let cap = CreateAttributesCap {
            id: object::new(ctx),
            number: number,
        };

        cap
    }

    /// Returns the number of the `Attributes` object.
    public(package) fun number(
        attributes: &Attributes,
    ): u16 {
        attributes.number
    }

    /// Returns the ID of the `CreateAttributesCap` object.
    public(package) fun create_attributes_cap_id(
        cap: &CreateAttributesCap,
    ): ID {
        object::id(cap)
    }
}