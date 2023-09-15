import { BigNumber } from 'ethers';
export const DEFAULT_DID_CONTRACT_ADDRESS =
  '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266'; // Proxy address

export const DEFAULT_KEY_ID = 'default';
export const VALID_DID_REGEX = /^did:([a-z\d:]*):([a-zA-z\d]+)$/;

export const DID_BNB_PREFIX = 'did:bnb';

export const W3ID_CONTEXT = 'https://w3id.org/did/v1.0';
export const getBnbContextPrefix = (version: string) =>
  `https://w3id.org/bnb/v${version}`;

export const NULL_ADDRESS = '0x0000000000000000000000000000000000000000';
export const ZERO_BN = BigNumber.from('0');
export const ONE_BN = BigNumber.from('1');
