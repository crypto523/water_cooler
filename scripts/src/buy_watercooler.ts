import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, user_keypair, find_one_by_type } from './helpers.js';
import data from '../deployed_objects.json';
import fs from 'fs';
import path, { dirname } from "path";

const keypair = user_keypair();

const packageId = data.packageId;
const cooler_factory = data.cooler_factory.CoolerFactory;
const name: String = "anıl";
const description: String = "asd";
const img_url: String = "asd";
const supply = 25;

(async () => {
    const txb = new TransactionBlock;
    const [coin] = txb.splitCoins(txb.gas, [100000000]);

    console.log("User1 buy water_cooler");

    txb.moveCall({
        target: `${packageId}::cooler_factory::buy_water_cooler`,
        arguments: [
            txb.object(cooler_factory),
            txb.object(coin),
            txb.pure(name),
            txb.pure(description),
            txb.pure(img_url),
            txb.pure(supply),
            txb.pure("0xa7f5dc1b23c3b8999f209186c0b4943587123b9293d84aea75a034dc2fb0d3d0")
        ],
    });

    const { objectChanges } = await client.signAndExecuteTransactionBlock({
        signer: keypair,
        transactionBlock: txb,
        options: { showObjectChanges: true }
    });

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }
    console.log(objectChanges);

    // Get water_cooler object
    const userFilePath = path.join(__dirname, '../user_objects.json');
    let userObjects = {
        user_objects: {
            water_cooler: "",
        }
    };

    const water_cooler = `${packageId}::water_cooler::WaterCooler`;
    const water_cooler_id = find_one_by_type(objectChanges, water_cooler);

    if (!water_cooler_id) {
        console.log("Error: Could not find WaterCooler object");
        process.exit(1);
    }

    userObjects.user_objects.water_cooler = water_cooler_id;

    // Write updated user objects to user_objects.json
    fs.writeFileSync(userFilePath, JSON.stringify(userObjects, null, 2), 'utf8');

    console.log('Updated user_objects.json successfully');

})()
