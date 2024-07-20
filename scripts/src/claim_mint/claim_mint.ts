import { Inputs, Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair } from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';
import { KioskClient, Network, KioskTransaction } from '@mysten/kiosk';
import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';



const keypair = user1_keypair();

const packageId = data.packageId;
const watercooler = user_data.user_objects.water_cooler;
const mint = user_data.user_objects.mint;
let policy = data.water_cooler.policy;

(async () => {
    try {
        const suiClient = new SuiClient({ url: getFullnodeUrl('testnet') });

        const kioskClient = new KioskClient({
            client: suiClient as any,
            network: Network.TESTNET,
        });
        
        const txb = new Transaction();

        const kioskTx = new KioskTransaction({ transaction: txb as any, kioskClient });

        console.log("User1 claims mint")

        kioskTx.create();

        txb.moveCall({
            target: `${packageId}::mint::claim_mint`,
            arguments: [
                txb.object(watercooler),
                txb.object(mint),
                txb.object(kioskTx.getKiosk() as any),
                txb.object(kioskTx.getKioskCap() as any),
                txb.object(policy),
            ],
        });

        kioskTx.shareAndTransferCap(keypair.getPublicKey().toSuiAddress());

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
