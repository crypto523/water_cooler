import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';
import fs from 'fs';
import path from 'path';

const keypair = user1_keypair();

const packageId = data.packageId;
const mintsettings = user_data.user_objects.MintSettings;
const mintwarehouse = user_data.user_objects.MintWarehouse;

(async () => {
    const txb = new Transaction();

    const [coin] = txb.splitCoins(txb.gas, [100000000]);

    console.log("Admin calls public_mint");

    txb.moveCall({
        target: `${packageId}::mint::public_mint`,
        arguments: [
            txb.object(mintwarehouse),
            txb.object(mintsettings),
            txb.object(coin)
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

    const filePath = path.join(__dirname, './user_objects.json');
    const userObjects = JSON.parse(fs.readFileSync(filePath, 'utf8'));

    // Get Mint object
    const mint = `${packageId}::mint::Mint`;
    const mint_id = find_one_by_type(objectChanges, mint);

    if (!mint_id) {
        console.log("Error: Could not find Mint object");
        process.exit(1);
    }
    userObjects.user_objects.mint = mint_id;

    // Get MintCap object
    const mint_cap = `${packageId}::mint::MintCap`;
    const mint_cap_id = find_one_by_type(objectChanges, mint_cap);

    if (!mint_cap_id) {
        console.log("Error: Could not find MintCap object");
        process.exit(1);
    }
    userObjects.user_objects.mint_cap = mint_cap_id;

    // Get AttributesCap object
    const attributes_cap = `${packageId}::attributes::CreateAttributesCap`;
    const attributes_cap_id = find_one_by_type(objectChanges, attributes_cap);

    if (!mint_cap_id) {
        console.log("Error: Could not find attributes_cap object");
        process.exit(1);
    }
    userObjects.user_objects.attributes_cap = attributes_cap_id;

    // Get image_cap object
    const image_cap = `${packageId}::image::CreateImageCap`;
    const image_cap_id = find_one_by_type(objectChanges, image_cap);

    if (!mint_cap_id) {
        console.log("Error: Could not find image_cap object");
        process.exit(1);
    }
    userObjects.user_objects.image_cap = image_cap_id;

    fs.writeFileSync(filePath, JSON.stringify(userObjects, null, 2), 'utf8');

    console.log('Updated user_objects.json successfully');
    console.log(`Mint object ID: ${mint_id}`);
    console.log(`MintCap object ID: ${mint_cap_id}`);
})();
