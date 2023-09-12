import { ethers, defender, run } from "hardhat";

// We use a UUPS proxy so the upgrade logic is on the implementation contract https://docs.openzeppelin.com/contracts/4.x/api/proxy#transparent-vs-uups
export async function upgradeContractAdminToMultiSig(implementationAddress: string) {
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry");

  console.log("Preparing proposal...");

  const proposal = await defender.proposeUpgrade(implementationAddress, 
    didRegistryContract, {title: 'Propose Upgrade to set gnosisSafe multi sig as admin', multisig: process.env.GNOSIS_ADDRESS! });
  console.log("Upgrade proposal created at:", proposal.url);
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

