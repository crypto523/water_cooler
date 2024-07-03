import { Transaction } from '@mysten/sui/transactions';
import { client, user1_keypair , find_one_by_type} from '../helpers.js';
import data from '../../deployed_objects.json';
import user_data from './user_objects.json';
import fs from 'fs';
import path from "path";

const keypair = user1_keypair();

const packageId = data.packageId;
const mintcap = user_data.user_objects.MintAdminCap;
const warehouse = user_data.user_objects.MintWarehouse;

(async () => {
    
        const txb = new Transaction();
    
        console.log("User1 creates WhitelistTicket");

        txb.moveCall({
            target: `${packageId}::mint::create_wl_ticket`,
            arguments: [
                txb.object(mintcap),
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

    const filePath = path.join(__dirname, './user_objects.json');
    const userObjects = JSON.parse(fs.readFileSync(filePath, 'utf8'));
         
    // Get OriginalGangsterTicket object
    const ticket = `${packageId}::mint::WhitelistTicket`;
    const ticket_id = find_one_by_type(objectChanges, ticket);

    if (!ticket_id) {
        console.log("Error: Could not find WhitelistTicket object");
        process.exit(1);
    }
    userObjects.user_objects.WhitelistTicket = ticket_id;

    fs.writeFileSync(filePath, JSON.stringify(userObjects, null, 2), 'utf8');
})();
