import { ethers, upgrades } from "hardhat";

async function main() {
  const didRegistryProxyContract = await ethers.getContractFactory("DIDRegistry");
  const deployment = await upgrades.deployProxy(didRegistryProxyContract, []);
  await deployment.waitForDeployment();

  console.log(`${await deployment.getAddress()}`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
