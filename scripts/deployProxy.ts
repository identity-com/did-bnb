import { ethers, upgrades } from "hardhat";

async function main() {
  const didRegistryProxyContract = await ethers.getContractFactory("DIDRegistry");
  const deployment = await upgrades.deployProxy(didRegistryProxyContract, []);
  await deployment.waitForDeployment();

  console.log(`DidRegistry admin deployed at address: ${await deployment.getAddress()}`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
