import { TransactionBlock } from '@mysten/sui.js/transactions';
import { client, keyPair, find_one_by_type } from './helpers.js';
import data from '../deployed_objects.json';
import user_data from '../user_objects.json';

const keypair = keyPair();

const packageId = data.packageId;
const mintsettings = user_data.user_objects.MintSettings;
const mintwarehouse = user_data.user_objects.MintWarehouse;

(async () => {
    try {
        const txb = new TransactionBlock();
        const [coin] = txb.splitCoins(txb.gas, [100000000]);

        console.log("Admin calls public_mint ");

        txb.moveCall({
            target: `${packageId}::mint::public_mint`,
            arguments: [
                txb.object(mintwarehouse),
                txb.object(mintsettings),
                txb.object(coin)
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
    } catch (error) {
        console.error("Error executing the transaction block:", error);
    }
})();
