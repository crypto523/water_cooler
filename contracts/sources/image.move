module galliun::image {

    // === Imports ===

    // === Errors ===


    // === Structs ===


    public struct Image has key, store {
        id: UID,
        name: vector<u8>,
        description: vector<u8>,
        data: vector<u8>, // Binary data of the image
    }


    // === Events ===

    

    // === Init Function ===

    /// Function to inscribe a new image on-chain
    #[allow(lint(self_transfer))]
    public fun inscribe_image(
        name: vector<u8>, 
        description: vector<u8>, 
        data: vector<u8>, 
        ctx: &mut TxContext
    ) {
        let image = Image {
            id: object::new(ctx),
            name,
            description,
            data,
        };
        transfer::public_transfer(image, ctx.sender());
    }

    /// Function to get image metadata
    public fun get_image_metadata(image: &Image): (vector<u8>, vector<u8>, vector<u8>) {
        (image.name, image.description, image.data)
    }
}
