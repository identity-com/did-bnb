import { ethers, upgrades } from "hardhat";
import { sleep, upgradeContractAdminToMultiSig, verify } from "./util";

async function main() {
  const didRegistryProxyContract = await ethers.getContractFactory("DIDRegistry");
  const deployment = await upgrades.deployProxy(didRegistryProxyContract, []);
  await deployment.waitForDeployment();

  const deployedAddress = await deployment.getAddress();

  console.log(`Implementation deployed at: ${await deployment.getAddress()}`);

  // Need to wait for block with contract to be produced and all events to fire before verifying

  await sleep(5000);

  await verify(deployedAddress,[]);

  // Need to wait to avoid rate limit
  await sleep(2000);

  await upgradeContractAdminToMultiSig(deployedAddress);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
