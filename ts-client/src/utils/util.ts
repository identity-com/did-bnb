import 'dotenv/config';
import { Wallet, ethers } from 'ethers';
import {
  DIDRegistry,
  DIDRegistry__factory,
} from '../contracts/typechain-types';
import { JsonRpcProvider } from '@ethersproject/providers';

export const fetchRpcProvider = (): JsonRpcProvider => {
  return new JsonRpcProvider(process.env.RPC_URL);
};

export const fetchRpcWallet = (signerKey: string): Wallet => {
  const provider = new JsonRpcProvider(process.env.RPC_URL);
  return new ethers.Wallet(signerKey, provider);
};

export const fetchDidRegistryContractInstance = (
  didRegistryAddress: string,
  privateKey: string
): DIDRegistry => {
  const wallet = fetchRpcWallet(privateKey);
  return DIDRegistry__factory.connect(didRegistryAddress, wallet.provider);
};

export const fetchReadOnlyDidRegistryContractInstance = (
  didRegistryAddress: string
): DIDRegistry => {
  return DIDRegistry__factory.connect(didRegistryAddress, fetchRpcProvider());
};
