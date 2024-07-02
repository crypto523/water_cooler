import { Transaction } from '@mysten/sui/transactions';
import { client, getKeypair, find_one_by_type } from './helpers.js';
import data from '../deployed_objects.json';
import user_data from '../user_objects.json';

const keypair = getKeypair();

const packageId = data.packageId;
const water_cooler = user_data.user_objects.water_cooler;
const mintcap = user_data.user_objects.MintAdminCap;
const warehouse = user_data.user_objects.MintWarehouse;
const mizu_nft = user_data.user_objects.mizu_nft;

(async () => {
    const txb = new Transaction;
    const mizu_nft_vec = txb.makeMoveVec({
        type: `${packageId}::mizu_nft::MizuNFT`,
        elements: [txb.object(mizu_nft)]
    });

    console.log("User1 add_to_mint_warehouse ");

    txb.moveCall({
        target: `${packageId}::mint::add_to_mint_warehouse`,
        arguments: [
            txb.object(mintcap),
            txb.object(water_cooler),
            mizu_nft_vec,
            txb.object(warehouse),
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
})()
