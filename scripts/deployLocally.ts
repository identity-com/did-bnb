import { ethers } from "hardhat";

export const DETERMINISTIC_ADDRESS = "0x0d2026b3EE6eC71FC6746ADb6311F6d3Ba1C000B";

async function main() {
  //@ts-ignore

  const deployment = await ethers.deployContract("DIDRegistry", []);

  const deployedAddress = await deployment.getAddress();

  const bytecode = await deployment.getDeployedCode();

  console.log(`Did Registry deployed at: ${deployedAddress}`);

  await ethers.provider.send('anvil_setCode',[
    DETERMINISTIC_ADDRESS,
    bytecode
  ])

  console.log(`Did Registry deployed at deterministic address: ${DETERMINISTIC_ADDRESS}`);

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
