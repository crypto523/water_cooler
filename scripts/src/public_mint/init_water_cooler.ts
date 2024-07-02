import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from '../../user_objects.json';
import fs from 'fs';
import path from "path";

const keypair = user1_keypair();

const packageId = data.packageId;
const water_cooler = user_data.user_objects.water_cooler;
const water_cooler_cap = user_data.user_objects.water_cooler_cap;
const registry = user_data.user_objects.registry;
const collection = user_data.user_objects.collection;

(async () => {
    const txb = new Transaction;

    console.log("User1 initialize_water_cooler ");

    txb.moveCall({
        target: `${packageId}::water_cooler::initialize_water_cooler`,
        arguments: [
            txb.object(water_cooler_cap),
            txb.object(water_cooler),
            txb.object(registry),
            txb.object(collection),
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

    const filePath = path.join(__dirname, '../user_objects.json');
    const userObjects = JSON.parse(fs.readFileSync(filePath, 'utf8'));

    // Get mizu_kiosk object
    const kiosk = `0x2::kiosk::Kiosk`
    const kiosk_id = find_one_by_type(objectChanges, kiosk);

    if (!kiosk_id) {
        console.log("Error: Could not find MizuKiosk object");
        process.exit(1);
    }
    userObjects.user_objects.mizu_kiosk = kiosk_id;

    // Get mizu_nft object
    const mizu_nft = `${packageId}::mizu_nft::MizuNFT`;
    const mizu_nft_id = find_one_by_type(objectChanges, mizu_nft);

    if (!mizu_nft_id) {
        console.log("Error: Could not find MizuNFT object");
        process.exit(1);
    }
    userObjects.user_objects.mizu_nft = mizu_nft_id;

    fs.writeFileSync(filePath, JSON.stringify(userObjects, null, 2), 'utf8');

    console.log('Updated user_objects.json successfully');

})()
