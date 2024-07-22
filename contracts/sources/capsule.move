module galliun::capsule {
  // === Imports ===
    use std::string::{String};
    use galliun::{
        image::Image,
        attributes::Attributes
    };

    // === Errors ===

    const EAttributesAlreadySet: u64 = 1;

    // === Structs ===

    // This is the structure that will be used to create the NFTs
    public struct Capsule has key, store {
        id: UID,
        // This name will be joined with the number to create the NFT name
        collection_name: String,
        description: String,
        // This url will be joined with the id to create the image url
        image_url: Option<String>,
        number: u64,
        attributes: Option<Attributes>,
        image: Option<Image>,
        water_cooler_id: ID
    }

    // === Public view functions ===

    public fun number(self: &Capsule): u64 {
        self.number
    }

    // === Package Functions ===

    public(package) fun new(
        number: u64,
        collection_name: String,
        description: String,
        image_url: Option<String>,
        attributes: Option<Attributes>,
        image: Option<Image>,
        water_cooler_id: ID,
        ctx: &mut TxContext,
    ): Capsule {
        Capsule {
            id: object::new(ctx),
            number,
            collection_name,
            description,
            image_url,
            attributes,
            image,
            water_cooler_id
        }
    }

    public(package) fun uid_mut(self: &mut Capsule): &mut UID {
        &mut self.id
    }

    public(package) fun set_attributes(self: &mut Capsule, attributes: Attributes) {
        assert!(option::is_none(&self.attributes), EAttributesAlreadySet);
        option::fill(&mut self.attributes, attributes);
    }

    public(package) fun set_image(self: &mut Capsule, image: Image) {
        option::fill(&mut self.image, image);
    }
    
    public(package) fun set_image_url(self: &mut Capsule, image_url: String) {
        option::swap_or_fill(&mut self.image_url, image_url);
    }
}