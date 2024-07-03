import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from '../user_objects.json';

const keypair = user1_keypair();

const packageId = data.packageId;
const mint_cap = user_data.user_objects.mint_cap;
const mint = user_data.user_objects.mint;

function stringToUint8Array(str: string): Uint8Array {
    return new TextEncoder().encode(str);
}

(async () => {
    const txb = new Transaction();

    let key1 = "asd";
    const keys = txb.makeMoveVec({
        type: `${packageId}::attributes::String`,
        elements: [txb.pure(stringToUint8Array(key1))]
    });
    
    let value1 = "asd";
    const values = txb.makeMoveVec({
        type: `${packageId}::attributes::String`,
        elements: [txb.pure(stringToUint8Array(value1))]
    });

    console.log("User1 creates Attributes");

    const attributes = txb.moveCall({
        target: `${packageId}::attributes::new`,
        arguments: [
            keys,
            values,
        ],
    });

    txb.transferObjects([attributes], keypair.getPublicKey().toSuiAddress());

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
