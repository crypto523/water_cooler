import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import fs from 'fs';
import path from "path";

const keypair = user1_keypair();

const packageId = data.packageId;
const cooler_factory = data.cooler_factory.CoolerFactory;
const name: String = "anıl";
const description: String = "asd";
const img_url: String = "asd";
const placeholder_image_url: String = "asd";
const supply = 25;

(async () => {
    const txb = new Transaction;
    const [coin] = txb.splitCoins(txb.gas, [100000000]);

    console.log("User1 buy water_cooler");

    txb.moveCall({
        target: `${packageId}::cooler_factory::buy_water_cooler`,
        arguments: [
            txb.object(cooler_factory),
            txb.object(coin),
            txb.pure(name as any),
            txb.pure(description as any),
            txb.pure(img_url as any),
            txb.pure(placeholder_image_url as any),
            txb.pure(supply as any),
            txb.pure("0xa7f5dc1b23c3b8999f209186c0b4943587123b9293d84aea75a034dc2fb0d3d0" as any)
        ],
    });

    const { objectChanges } = await client.signAndExecuteTransaction({
        signer: keypair,
        transaction: txb,
        options: { showObjectChanges: true }
    });

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }
    console.log(objectChanges);

    // Get water_cooler object
    const userFilePath = path.join(__dirname, './user_objects.json');
    let userObjects = {
        user_objects: {
            water_cooler: "",
            water_cooler_cap: "",
            MintSettings: "",
            MintWarehouse: "",
            MintAdminCap: "",
            collection: "",
            registry: "",
            mizu_kiosk: "",
            mizu_nft: "",
            mint: "",
            mint_cap: "",
            attributes_cap: "",
            image_cap: "",
            OriginalGangsterTicket: "",
            attributes: "",
            image: ""
        }
    };

    // get watercooler share object 
    const water_cooler = `${packageId}::water_cooler::WaterCooler`;
    const water_cooler_id = find_one_by_type(objectChanges, water_cooler);

    if (!water_cooler_id) {
        console.log("Error: Could not find WaterCooler object");
        process.exit(1);
    }

    userObjects.user_objects.water_cooler = water_cooler_id;

    // get watercoolercap object 
    const water_cooler_cap = `${packageId}::water_cooler::WaterCoolerAdminCap`;
    const water_cooler_cap_id = find_one_by_type(objectChanges, water_cooler_cap);

    if (!water_cooler_cap_id) {
        console.log("Error: Could not find WaterCoolercap object");
        process.exit(1);
    }

    userObjects.user_objects.water_cooler_cap = water_cooler_cap_id;

    // get MintSettings object 
    const mintsettings = `${packageId}::mint::MintSettings`;
    const mintsettings_id = find_one_by_type(objectChanges, mintsettings);

    if (!mintsettings_id) {
        console.log("Error: Could not find MintSettings object");
        process.exit(1);
    }

    userObjects.user_objects.MintSettings = mintsettings_id;

    // get MintWarehouse object 
    const MintWarehouse = `${packageId}::mint::MintWarehouse`;
    const MintWarehouse_id = find_one_by_type(objectChanges, MintWarehouse);
    
    if (!MintWarehouse_id) {
        console.log("Error: Could not find MintWarehouse object");
        process.exit(1);
    }
    
    userObjects.user_objects.MintWarehouse = MintWarehouse_id;

    // get MintAdminCap object 
    const MintAdminCap = `${packageId}::mint::MintAdminCap`;
    const MintAdminCap_id = find_one_by_type(objectChanges, MintAdminCap);
    
    if (!MintAdminCap_id) {
        console.log("Error: Could not find MintAdminCap object");
        process.exit(1);
    }
    
    userObjects.user_objects.MintAdminCap = MintAdminCap_id;

    // get Collection object 
    const collection = `${packageId}::collection::Collection`;
    const collection_id = find_one_by_type(objectChanges, collection);
    
    if (!collection_id) {
        console.log("Error: Could not find Collection object");
        process.exit(1);
    }
    
    userObjects.user_objects.collection = collection_id;

    // get registry object 
    const registry = `${packageId}::registry::Registry`;
    const registry_id = find_one_by_type(objectChanges, registry);
    
    if (!registry_id) {
        console.log("Error: Could not find registry object");
        process.exit(1);
    }
    
    userObjects.user_objects.registry = registry_id;

    // Write updated user objects to user_objects.json
    fs.writeFileSync(userFilePath, JSON.stringify(userObjects, null, 2), 'utf8');

    console.log('Updated user_objects.json successfully');
})()
