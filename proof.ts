import { ethers } from 'ethers'
import { ethGetProof, ethGetStorageAt, getCurrentBlockNum } from './quicknode'
import { Data } from "../utils/data"
import { BigNumber } from "ethers"

export const proof = async (address: string, contract_address: string, block_number: number, storage_slot: number) => {

    const state = ethers.utils.keccak256(
        ethers.utils.concat([
            ethers.utils.zeroPad(address, 8),
            ethers.utils.defaultAbiCoder.encode(
                ['uint256'],
                [storage_slot]
            )
        ])
    )





    const options = {
        method: 'POST',
        headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
        },
        body: JSON.stringify({ state }),
    };
    fetch('https://api.testnets.sismo.io/', options)
        .then(response => {
            console.log(response)
            if (response.ok) {

                return response.json();
            } else {

                throw new Error(`Request failed. Status: ${response.status}`);
            }
        })
}
export const herodotusProof = async (address: string, blockNum: number) => {
    const herodotus_endpoint = process.env.HERODOTUS_API as string
    const herodotus_api_key = process.env.HERODOTUS_API_KEY as string
    const body = {
        originChain: "STARKNET_GOERLI",
        destinationChain: "STARKNET_GOERLI",
        blockNumber: blockNum,
        type: "ACCOUNT_ACCESS",
        requestedProperties: {
            ACCOUNT_ACCESS: {
                account: address,
                properties: [
                    "storageHash"
                ]
            }
        },
    }

    const response = await fetch(herodotus_endpoint + '?apiKey=' + herodotus_api_key, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(body)
    });
    const data = await response.json();
    return data;
}

export const starknetVerify = async (address: string, slot: string, blockNum: number) => {
    const ethProof = await ethGetProof(address, [slot], blockNum)
    const rawProof = ethProof.storageProof[0].proof;
    const proof = rawProof.map((leaf: any) => Data.fromHex(leaf).toInts());

    const flatProofByteLengths: number[] = [];
    const flatProofWordLengths: number[] = [];
    let flatProofValues: BigNumber[] = [];

    for (const element of proof) {
        flatProofByteLengths.push(element.sizeBytes);
        flatProofWordLengths.push(element.values.length);
        flatProofValues = flatProofValues.concat(element.values);
    }

    const slot_from_hex = Data.fromHex(slot)
        .toInts()
        .values.map((value: any) => value.toHexString())

    const calldata = [
        BigNumber.from(blockNum).toHexString(),
        address,
        ...slot_from_hex,
        BigNumber.from(flatProofByteLengths.length).toHexString(),
        ...flatProofByteLengths.map((length) => "0x" + length.toString(16)),
        BigNumber.from(flatProofWordLengths.length).toHexString(),
        ...flatProofWordLengths.map((length) => "0x" + length.toString(16)),
        BigNumber.from(flatProofValues.length).toHexString(),
        ...flatProofValues.map((value) => value.toHexString()),
    ]

    return calldata
}