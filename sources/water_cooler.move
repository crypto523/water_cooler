module water_cooler::water_cooler {
  // use sui::transfer;
  use std::string::{String};

  public struct WaterCooler has key {
    id: UID,
    name: String
  }

  // fun newWaterCooler(name: String, ctx: &mut TxContext): WaterCooler {
  //   let waterCooler = newWaterCooler(name, ctx);
  // }
  
  public(package) fun createWaterCooler(name: String, ctx: &mut TxContext) {
    let waterCooler = WaterCooler {id: object::new(ctx), name};
    transfer::transfer(waterCooler, tx_context::sender(ctx));
  }

}
