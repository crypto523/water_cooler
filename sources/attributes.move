module galliun::attributes {
    // === Imports ===

    use std::string::{String};
    use sui::vec_map::{VecMap};

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

    // === Package functions ===

    /// Create an `Attributes` object with a `CreateAttributesCap`.
    public(package) fun new(
        number: u16,
        attributes: VecMap<String, String>,
        ctx: &mut TxContext,
    ): Attributes {
        let attributes_data = AttributesData {
            map: attributes
        };

        let attributes = Attributes {
            id: object::new(ctx),
            number,
            fields: attributes_data,
        };

        attributes
    }

    /// Returns the number of the `Attributes` object.
    public(package) fun number(
        attributes: &Attributes,
    ): u16 {
        attributes.number
    }
}