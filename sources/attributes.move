module galliun::attributes {
    // === Imports ===

    use std::string::{String};
    use sui::vec_map::{Self, VecMap};

    // === Structs ===
    
    /// An object an "attributes" field of a `NFT` object.
    public struct Attributes has key, store {
        id: UID,
        fields: VecMap<String, String>,
    }

    // === Public view functions ===

    /// Returns the number of the `Attributes` object.
    public fun number(attributes: &Attributes): u64 {
        attributes.fields.size()
    }

    // === Package functions ===

    /// Create an `Attributes` object with a `CreateAttributesCap`.
    public(package) fun new(
        keys: vector<String>,
        values: vector<String>,
        ctx: &mut TxContext,
    ): Attributes {
        Attributes {
            id: object::new(ctx),
            fields: vec_map::from_keys_values(keys, values),
        }
    }
}