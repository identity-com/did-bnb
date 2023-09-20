import { ethers, upgrades } from "hardhat";
import { addContractToAdmin, loadRelayerSigner, sleep, upgradeContractAdminToMultiSig, verify } from "./util";

async function main() {
  const relaySigner = await loadRelayerSigner();

  //@ts-ignore
  const didRegistryProxyContract = await ethers.getContractFactory("DIDRegistry", relaySigner);

  const deployment = await upgrades.deployProxy(didRegistryProxyContract, []);

  const deployedProxyAddress = await deployment.getAddress();

  console.log(`Proxy deployed at: ${deployedProxyAddress}`);

  // Need to wait for block with contract to be produced and all events to fire before verifying

  await sleep(6000);

  await verify(deployedProxyAddress,[]);

  // Need to wait to avoid rate limit
  await sleep(2000);

  //@ts-ignore
  await upgradeContractAdminToMultiSig(deployment, relaySigner);
  
  // Need to wait to avoid rate limit
  await sleep(2000);
  await addContractToAdmin(deployedProxyAddress, 'DidRegistry');

}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
