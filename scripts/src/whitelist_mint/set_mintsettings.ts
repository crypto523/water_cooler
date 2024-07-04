import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';

const keypair = user1_keypair();

const packageId = data.packageId;
const mintcap = user_data.user_objects.MintAdminCap;
const mintsettings = user_data.user_objects.MintSettings;

(async () => {
    try {
        const txb = new Transaction();
        const price = 100000000;
        const status = 1;
        const phase = 2;

        console.log("User1 set_mintsettings ");

        txb.moveCall({
            target: `${packageId}::mint::set_mint_price`,
            arguments: [
                txb.object(mintcap),
                txb.object(mintsettings),
                txb.pure(price as any)
            ],
        });

        txb.moveCall({
            target: `${packageId}::mint::set_mint_status`,
            arguments: [
                txb.object(mintcap),
                txb.object(mintsettings),
                txb.pure(status as any)
            ],
        });

        txb.moveCall({
            target: `${packageId}::mint::set_mint_phase`,
            arguments: [
                txb.object(mintcap),
                txb.object(mintsettings),
                txb.pure(phase as any)
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
    } catch (error) {
        console.error("Error executing the transaction block:", error);
    }
})();
