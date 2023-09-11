import { ethers, upgrades } from "hardhat";

async function main() {
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry");
  const deployment = await upgrades.upgradeProxy(process.env.DID_REGISTRY_IMPLEMENTATION_ADDRESS!, didRegistryContract);
  await deployment.waitForDeployment();
  console.log(await deployment.getAddress());
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
