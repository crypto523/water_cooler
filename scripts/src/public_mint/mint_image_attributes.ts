import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair, find_one_by_type } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from '../user_objects.json';
import fs from 'fs';
import path from 'path';

const keypair = user1_keypair();

const packageId = data.packageId;
const mint_cap = user_data.user_objects.mint_cap;
const mint = user_data.user_objects.mint;
const attributes_cap = user_data.user_objects.attributes_cap;
const image_cap = user_data.user_objects.image_cap;

// Define the file path for the user objects JSON
const filePath = path.join(__dirname, '../user_objects.json');

// Load the user objects JSON file
let userObjects = JSON.parse(fs.readFileSync(filePath, 'utf8'));

(async () => {
    const txb = new Transaction();

    let image_url: string = "asd";

    let key1 = "asd";
    const keys = txb.makeMoveVec({
        type: `0x1::string::String`,
        elements: [txb.pure.string(key1)]
    });
    
    let value1 = "asd";
    const values = txb.makeMoveVec({
        type: `0x1::string::String`,
        elements: [txb.pure.string(value1)]
    });

    console.log("User1 creates Attributes");

    const attributes = txb.moveCall({
        target: `${packageId}::attributes::new`,
        arguments: [
            txb.object(attributes_cap),
            keys,
            values,
        ],
    });

    const keys1 = txb.makeMoveVec({
        type: `0x1::string::String`,
        elements: [txb.pure.string(key1)]
    });

    const image = txb.moveCall({
        target: `${packageId}::image::create_image`,
        arguments: [
            txb.object(image_cap),
            txb.pure.string(image_url),
            keys1,
        ],
    });


    txb.transferObjects([txb.object(attributes)], keypair.getPublicKey().toSuiAddress());

    const { objectChanges } = await client.signAndExecuteTransaction({
        signer: keypair,
        transaction: txb,
        options: { showObjectChanges: true }
    });

    if (!objectChanges) {
        console.log("Error: objectChanges is null or undefined");
        process.exit(1);
    }

    // Get Attributes object
    const attribute = `${packageId}::attributes::Attributes`;
    const attribute_id = find_one_by_type(objectChanges, attribute);

    if (!attribute_id) {
        console.log("Error: Could not find Attributes object");
        process.exit(1);
    }
    userObjects.user_objects.attribute = attribute_id;

    // Get Image object
    const image_object = `${packageId}::image::Image`;
    const image_object_id = find_one_by_type(objectChanges, image_object);

    if (!image_object_id) {
        console.log("Error: Could not find Image object");
        process.exit(1);
    }
    userObjects.user_objects.image = image_object_id;

    fs.writeFileSync(filePath, JSON.stringify(userObjects, null, 2), 'utf8');
    console.log(objectChanges);
})();
