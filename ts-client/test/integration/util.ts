import { JsonRpcProvider, ethers } from "ethers";
import { fetchRpcWallet } from "../../src/utils"
import { DIDRegistry, DIDRegistry__factory } from "../../types/ethers-contracts";


export const setAccountBalance = async (rpcProvider: JsonRpcProvider, address: string, amount: string) => {
    const test = await rpcProvider.send("tenderly_setBalance",[address, amount]);
}

export const deployDidRegistryContractInstance = async (signer: string): Promise<DIDRegistry & { deploymentTransaction(): ethers.ContractTransactionResponse}> => {
    const wallet = fetchRpcWallet(signer);
    const result = await new DIDRegistry__factory(wallet).deploy({gasLimit: 4000000});
    await result.deploymentTransaction().wait();
    return result;
}