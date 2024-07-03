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

    /// A cap object that gives ADMIN the ability to create
    /// `Attributes` and `AttributesData` objects.
    public struct CreateAttributesCap has key, store {
        id: UID,
        number: u16,
    }

    // === Public view functions ===

    /// Returns the number of the `Attributes` object.
    public fun number(self: &Attributes): u64 {
        self.fields.size()
    }

    // === Package functions ===

    /// Create an `Attributes` object with a `CreateAttributesCap`.
    public fun new(
        cap: CreateAttributesCap,
        keys: vector<String>,
        values: vector<String>,
        ctx: &mut TxContext,
    ): Attributes {
        let CreateAttributesCap { id, number: _ } = cap;
        id.delete();

        Attributes {
            id: object::new(ctx),
            fields: vec_map::from_keys_values(keys, values),
        }
    }

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
}