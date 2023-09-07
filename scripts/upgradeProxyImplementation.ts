import { ethers, defender } from "hardhat";

async function main() {
  const didRegistryContract = await ethers.getContractFactory("DIDRegistry");
  const deployment = await defender.upgradeProxy(process.env.DID_REGISTRY_PROXY_ADDRESS!, didRegistryContract);

  console.log(`DidRegistry upgraded`);
}


main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
