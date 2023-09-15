import {
  DIDRegistry,
  DIDRegistry__factory,
} from '../../src/contracts/typechain-types';
import { JsonRpcProvider } from '@ethersproject/providers';

import { Wallet } from 'ethers';
import { Provider } from '@ethersproject/providers';

export const DEFAULT_MNEMONIC =
  'test test test test test test test test test test test junk';

// During testing, the 0th index is the deployer key, the 2nd index is used as the did wallet key
export const getDeployerWallet = (provider: Provider) =>
  Wallet.fromMnemonic(DEFAULT_MNEMONIC, "m/44'/60'/0'/0/0").connect(provider);
export const getMainDidWallet = (provider: Provider) =>
  Wallet.fromMnemonic(DEFAULT_MNEMONIC, "m/44'/60'/0'/0/2").connect(provider);
export const getSecondaryDidWallet = (provider: Provider) =>
  Wallet.fromMnemonic(DEFAULT_MNEMONIC, "m/44'/60'/0'/0/3").connect(provider);
export const getUnauthorizedDidWallet = (provider: Provider) =>
  Wallet.fromMnemonic(DEFAULT_MNEMONIC, "m/44'/60'/0'/0/4").connect(provider);

export const setAccountBalance = async (
  provider: Provider,
  address: string,
  amount: string
) => {
  // TODO: Verify provider is a JsonRpcProvider
  const rpcProvider = provider as JsonRpcProvider;
  const test = await rpcProvider.send('tenderly_setBalance', [address, amount]);
};

export const deployDidRegistryContractInstance = async (
  wallet: Wallet
): Promise<DIDRegistry> => {
  const result = await new DIDRegistry__factory(wallet).deploy({
    gasLimit: 4000000,
  });
  await result.deployTransaction.wait();
  return result;
};

export const addBalanceToTenderlyAccount = async (
  wallet: Wallet,
  amount = '0xDE0B6B3A7640000'
): Promise<void> => {
  return await setAccountBalance(wallet.provider, wallet.address, amount);
};

export const getGeneratedDidDocument = (
  didIdentifier: string,
  didMethodPrefix: string
) => ({
  '@context': ['https://w3id.org/did/v1.0', 'https://w3id.org/bnb/v1.0'],
  controller: [],
  verificationMethod: [
    {
      id: `${didMethodPrefix}${didIdentifier}#default`,
      type: 'EcdsaSecp256k1RecoveryMethod2020',
      controller: `${didMethodPrefix}${didIdentifier}`,
      ethereumAddress: didIdentifier.toLowerCase(),
    },
  ],
  authentication: [],
  assertionMethod: [],
  keyAgreement: [],
  capabilityInvocation: [`${didMethodPrefix}${didIdentifier}#default`],
  capabilityDelegation: [],
  service: [],
  id: `${didMethodPrefix}${didIdentifier}`,
});
