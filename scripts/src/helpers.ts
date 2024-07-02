import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import type { SuiObjectChange } from "@mysten/sui/client";
import { fromB64 } from "@mysten/sui/utils";
export interface IObjectInfo {
    type: string | undefined;
    id: string | undefined;
}

export const admin_keypair = () => {
    const privkey = process.env.PRIVATE_KEY
if (!privkey) {
    console.log("Error: DEPLOYER_B64_PRIVKEY not set as env variable.")
    process.exit(1)
}
const keypair = Ed25519Keypair.fromSecretKey(fromB64(privkey).slice(1))
return keypair
}

export const client = new SuiClient({ url: getFullnodeUrl('testnet') });

export const parse_amount = (amount: string) => {
    return parseInt(amount) / 1_000_000_000;
}

export const find_one_by_type = (changes: SuiObjectChange[], type: string) => {
    const object_change = changes.find(change => change.type === "created" && 'objectType' in change && change.objectType === type);
    if (object_change?.type === "created") {
        return object_change.objectId;
    }
}
