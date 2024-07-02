// This object holds the supply of NFTs in a collection
// It was created for the purpose of avoiding a cercular dependency 
// between the Registry and the WaterCooler which need to share the 
// supply of NFTs in the collection
module galliun::collection {

    // === Structs ===

    public struct COLLECTION has drop {}

    public struct Collection has key {
        id: UID,
        supply: u16
    }

    // === Init Function ===

    #[allow(unused_function)]
    fun init(
        _otw: COLLECTION,
        _ctx: &mut TxContext,
    ) {}



    // === Package Functions ===

    public(package) fun new(supply: u16, ctx: &mut TxContext) : Collection {
        Collection {
            id: object::new(ctx),
            supply
        }
    }
    
    // This function was created so I can transfer the Collection to the sender 
    // after adding the objectId to the WaterCooler object which allows me to 
    // keep track of which Colleection belongs to each Water Cooler
    public(package) fun transfer_collection(self: Collection, ctx: &TxContext) {
        transfer::transfer(self, ctx.sender());
    }


    public(package) fun supply(self: &Collection): u16 {
        self.supply
    }
}
