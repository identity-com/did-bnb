import { ethers, defender } from "hardhat";
import { verify, sleep, loadRelayerSigner } from "./util";

async function main() {
  const relaySigner = await loadRelayerSigner();

  //@ts-ignore
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry", relaySigner);

  // Import the proxy and implementation contract so they are resolved
  await defender.forceImport(process.env.DID_REGISTRY_PROXY_ADDRESS!, didRegistryContract, {kind: 'uups'});

  const proposalResponse = await defender.proposeUpgrade(process.env.DID_REGISTRY_PROXY_ADDRESS!, didRegistryContract, {
    multisig: process.env.GNOSIS_ADDRESS!,
    kind: 'uups',
    redeployImplementation: 'always'
  });

  // Need to wait for block with contract to be produced and all events to fire before verifying
  console.log("waiting...");

  await sleep(7000);

  const newImplementationAddress = await proposalResponse.metadata?.newImplementationAddress!;
  await verify(newImplementationAddress,[]);
}



main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
