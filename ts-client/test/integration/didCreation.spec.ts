import { ContractTransactionResponse, HDNodeWallet, JsonRpcProvider, Wallet, ethers } from "ethers"
import 'dotenv/config';
import { deployDidRegistryContractInstance, fetchRpcWallet } from "../../src/utils";
import { setAccountBalance } from "./util";
import { DIDRegistry } from "../../types/ethers-contracts";

const FOUNDRY_DEFAULT_PRIVATE_KEY_ONE = "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80";
const FOUNDRY_DEFAULT_PUBLIC_KEY_ONE = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"

describe('TS-client Integration test', () => {
    let didRegistryContract: DIDRegistry;

    beforeAll(async () => {
        if(process.env.RPC_URL.includes("tenderly")) {
            await addBalanceToTenderlyAccount(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE, FOUNDRY_DEFAULT_PRIVATE_KEY_ONE);
        }

        didRegistryContract = await deployDidRegistryContractInstance(FOUNDRY_DEFAULT_PRIVATE_KEY_ONE);
    }, 15000)

    test('should verify initial did on state', async () => {
        const isGenerative: boolean = await didRegistryContract.isGenerativeDidState(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE,{gasLimit: 30000000});
        expect(isGenerative).toBe(true);
    }, 5000)

    test('should initialize did on chain', async () => {
        const tx = await didRegistryContract.initializeDidState(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE,{gasLimit: 30000000});
        await tx.wait();

        const isGenerative: boolean = await didRegistryContract.isGenerativeDidState(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE,{gasLimit: 30000000});
        expect(isGenerative).toBe(false);
    }, 15000)

    test('should create verification method on chain', async () => {

        const vmTx = await didRegistryContract.addVerificationMethod(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE, {fragment: "test", flags: 0, methodType: 0, keyData: FOUNDRY_DEFAULT_PUBLIC_KEY_ONE}, {gasLimit: 30000000});
        await vmTx.wait();

        const didState = await didRegistryContract.resolveDidState(FOUNDRY_DEFAULT_PUBLIC_KEY_ONE, {gasLimit: 30000000})
        expect(didState.verificationMethods.length).toBe(2);
    }, 15000)

    const addBalanceToTenderlyAccount = async (address: string, privateKey: string): Promise<void> => {
        const signedWallet = fetchRpcWallet(privateKey);
        return await setAccountBalance(signedWallet.provider as JsonRpcProvider, address, "0xDE0B6B3A7640000");
    }
})