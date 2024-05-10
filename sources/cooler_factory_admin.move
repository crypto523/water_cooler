module water_cooler::cooler_factory_admin {

  public struct CoolerFactoryAdminCap has key {
    id: UID
  }
  
  fun init(ctx: &mut TxContext) {
    transfer::transfer(CoolerFactoryAdminCap {
      id: object::new(ctx)
    }, tx_context::sender(ctx));
  }

  // public(package) fun verifyCoolerFactoryAdmin(ctx: &mut TxContext) {
  //   let waterCooler = WaterCooler {id: object::new(ctx), name};
  //   transfer::transfer(waterCooler, tx_context::sender(ctx));
  // }
}
