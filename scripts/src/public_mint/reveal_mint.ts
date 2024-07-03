import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';

const keypair = user1_keypair();

const packageId = data.packageId;
const mint_cap = user_data.user_objects.mint_cap;
const mint = user_data.user_objects.mint;
const attributes = user_data.user_objects.attributes;
const image = user_data.user_objects.image;

(async () => {
    const txb = new Transaction();

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

    console.log("User1 execute reveal_mint");

    txb.moveCall({
        target: `${packageId}::mint::reveal_mint`,
        arguments: [
            txb.object(mint_cap),
            txb.object(mint),
            txb.object(attributes),
            txb.object(image),
            txb.pure.string(key1),
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
})();
