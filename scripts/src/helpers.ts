import { getFullnodeUrl, SuiClient } from '@mysten/sui/client';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { fromB64 } from "@mysten/sui/utils";
import type { SuiObjectChange } from "@mysten/sui/client";

export interface IObjectInfo {
    type: string | undefined;
    id: string | undefined;
}

export const getKeypair = () => {
    const seedPhrase = process.env.SEED_PHRASE as string;
    if (!seedPhrase || seedPhrase == "") {
        console.log("Error: SEED_PHRASE not set as env variable.");
        process.exit(1);
    }
    const keypair = Ed25519Keypair.deriveKeypair(process.env.SEED_PHRASE as string);
    return keypair;
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
