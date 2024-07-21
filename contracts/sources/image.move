module galliun::image {

    // === Imports ===

    use sui::display;

    // === Errors ===


    // === Structs ===

    public struct IMAGE has drop {}

    public struct Image has key, store {
        id: UID,
        name: vector<u8>,
        description: vector<u8>,
        data: vector<u8>, // Binary data of the image
    }


    // === Events ===

    

    // === Init Function ===

    #[allow(unused_variable, lint(share_owned))]
    fun init(
        otw: IMAGE,
        ctx: &mut TxContext,
    ) {
        let publisher = sui::package::claim(otw, ctx);

        let mut image_chunk_display = display::new<Image>(&publisher, ctx);
        image_chunk_display.add(b"name".to_string(), b"{name}".to_string());
        image_chunk_display.add(b"description".to_string(), b"{description}".to_string());
        image_chunk_display.add(b"data".to_string(), b"{data}".to_string());

        transfer::public_transfer(publisher, ctx.sender());
        transfer::public_transfer(image_chunk_display, ctx.sender());
    }

    /// Function to inscribe a new image on-chain
    public fun inscribe_image(
        name: vector<u8>, 
        description: vector<u8>, 
        data: vector<u8>, 
        ctx: &mut TxContext
    ): Image {
        let image = Image {
            id: object::new(ctx),
            name,
            description,
            data,
        };
        transfer::public_transfer(image, ctx.sender());
        image
    }

    /// Function to get image metadata
    public fun get_image_metadata(image: &Image): (vector<u8>, vector<u8>, vector<u8>) {
        (image.name, image.description, image.data)
    }
}
