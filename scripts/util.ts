import { Contract, Signer } from "ethers";
import hre, { ethers, defender, run, upgrades } from "hardhat";
import { DefenderRelayProvider, DefenderRelaySigner } from "@openzeppelin/defender-relay-client/lib/ethers";
import { fromChainId } from '@openzeppelin/defender-base-client';
import { AdminClient } from '@openzeppelin/defender-admin-client';

export async function loadRelayerSigner() {
  const credentials = {apiKey: process.env.DEFENDER_RELAY_KEY!, apiSecret: process.env.DEFENDER_RELAY_SECRET!};
  const provider = new DefenderRelayProvider(credentials);
  return new DefenderRelaySigner(credentials, provider, { speed: 'fast' });
}

export async function addContractToAdmin(contractAddress: string, name: string) {
  const client = new AdminClient({ apiKey: process.env.DEFENDER_KEY!, apiSecret: process.env.DEFENDER_SECRET! });

  await client.addContract({
    network: fromChainId(hre.network.config.chainId!)!!,
    address: contractAddress,
    name
  });
}

// We use a UUPS proxy so the upgrade logic is on the implementation contract https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent-vs-uups
export async function upgradeContractAdminToMultiSig(implementationContract: Contract, signer: Signer) {
  const didRegistryContractFactory = await ethers.getContractFactory("DIDRegistry", signer);

  const contract = didRegistryContractFactory.attach(implementationContract);

  console.log("Previous didRegistry owner:", await contract.owner());

  console.log("Tansferring ownership to multi-sig:", process.env.GNOSIS_ADDRESS!);

  const tx = await contract.transferOwnership(process.env.GNOSIS_ADDRESS!);
}

export async function verify(contractAddress: string, constructorArgs: any[]) {
  console.log("Verifying contract...");
  try {
      await run("verify:verify", {
          address: contractAddress,
          constructorArguments: constructorArgs,
      });
  } catch (e: any) {
      if (e.message.toLowerCase().includes("already verified")) {
          console.log("Already verified!");
      } else {
          console.log(e);
      }
  }
};

export const sleep = (ms: number) => new Promise(r => setTimeout(r, ms));

