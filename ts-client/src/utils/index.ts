import 'dotenv/config';
import { JsonRpcProvider, Wallet, ethers } from 'ethers';
import { DIDRegistry, DIDRegistry__factory } from '../../types/ethers-contracts';


export const fetchRpcProvider = (): JsonRpcProvider => {
    return new ethers.JsonRpcProvider(process.env.RPC_URL);
}

export const fetchRpcWallet = (signerKey: string): Wallet => {
    const provider = new ethers.JsonRpcProvider(process.env.RPC_URL);
    return new ethers.Wallet(signerKey, provider);
}

export const fetchDidRegistryContractInstance = (didRegistryAddress: string, signer: string): DIDRegistry => {
    const wallet = fetchRpcWallet(signer);
    return DIDRegistry__factory.connect(didRegistryAddress, wallet.provider);
}

export const deployDidRegistryContractInstance = async (signer: string): Promise<DIDRegistry & { deploymentTransaction(): ethers.ContractTransactionResponse}> => {
    const wallet = fetchRpcWallet(signer);
    const result = await new DIDRegistry__factory(wallet).deploy({gasLimit: 4000000});
    await result.deploymentTransaction().wait();
    return result;
}