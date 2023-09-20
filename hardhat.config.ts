import { HardhatUserConfig } from "hardhat/config";
import { config as dotEnvConfig } from "dotenv";
import "@openzeppelin/hardhat-upgrades";
import "@nomicfoundation/hardhat-verify";
import "hardhat-preprocessor";
import fs from "fs";

dotEnvConfig();

// Preprocessor logic is directly from foundry docs: https://book.getfoundry.sh/config/hardhat

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  defender: {
    apiKey: process.env.DEFENDER_KEY!,
    apiSecret: process.env.DEFENDER_SECRET!
  },
  networks: {
    testnetBnb: {
      url: process.env.BNB_TESTNET_RPC_URL!,
      chainId: 97
    },
    opBnb: {
      url: "https://opbnb-testnet-rpc.bnbchain.org",
      accounts: [process.env.BNB_TESTNET_PK!]
    },
    bnbSmartChain: {
      url: process.env.BNB_RPC_URL!,
      chainId: 56,
    }
  },
  etherscan: {
    apiKey: process.env.BNB_EXPLORER_API_KEY!
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          getRemappings().forEach(([find, replace]) => {
            if (line.match(find)) {
              line = line.replace(find, replace);
            }
          });
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./src",
    cache: "./cache_hardhat",
  },
};


export default config;
