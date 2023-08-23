import { JsonRpcProvider, ethers } from "ethers"
import 'dotenv/config';
import { deployDidRegistryContractInstance, fetchDidRegistryContractInstance, fetchRpcWallet } from "../../src/utils";

test('should initialize did on devnet', async () => {
    const address = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const signedWallet = fetchRpcWallet("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
    const contract = await deployDidRegistryContractInstance("0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");

    const isGenerative = await contract.isGenerativeDidState(address);
    expect(isGenerative).toBe(true);
})