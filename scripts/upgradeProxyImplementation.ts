import { ethers, defender } from "hardhat";
import { verify, sleep, loadRelayerSigner } from "./util";

async function main() {
  const relaySigner = await loadRelayerSigner();

  //@ts-ignore
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry", relaySigner);
  const proposalResponse = await defender.proposeUpgrade(process.env.DID_REGISTRY_PROXY_ADDRESS!, didRegistryContract, {
    multisig: process.env.GNOSIS_ADDRESS!,
    kind: 'uups',
    redeployImplementation: 'always'
  });
}



main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
