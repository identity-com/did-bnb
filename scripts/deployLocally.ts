import { ethers } from "hardhat";

async function main() {
  //@ts-ignore

  const deployment = await ethers.deployContract("DIDRegistry", []);

  const deployedAddress = await deployment.getAddress();

  console.log(`Did Registry deployed at: ${deployedAddress}`);

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
