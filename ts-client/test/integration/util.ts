import { BigNumberish, ContractRunner, JsonRpcProvider, Wallet, ethers } from "ethers";
import { fetchRpcProvider } from "../../src/utils"


export const setAccountBalance = async (rpcProvider: JsonRpcProvider, address: string, amount: BigNumberish) => {
    const test = await rpcProvider.send("tenderly_setBalance",[address, ethers.toBeHex(amount)]);
}