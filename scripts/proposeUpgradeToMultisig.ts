import { ethers, defender } from "hardhat";

async function main() {
  const proxyAddress = process.env.DID_REGISTRY_PROXY_ADDRESS!;
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry");

  console.log("Preparing proposal...");

  const proposal = await defender.proposeUpgrade(proxyAddress, 
    didRegistryContract, {title: 'Propose Upgrade to set gnosisSafe multi sig as admin', multisig: process.env.GNOSIS_ADDRESS! });
  console.log("Upgrade proposal created at:", proposal.url);
}

main()
  .then(() => process.exit(0))
  .catch(error => {
  console.error(error);
  process.exit(1);
})
