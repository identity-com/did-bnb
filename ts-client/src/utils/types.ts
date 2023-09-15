import { Overrides } from 'ethers';
import { DIDRegistry } from '../contracts/typechain-types';
import { VerificationMethod } from 'did-resolver';
import { ChainEnviroment } from './doc';

export type Options = Overrides & {
  chainEnvironment?: ChainEnviroment;
};

// List of the write operations on the Did contract that are exposed via this library
export type WriteOps =
  | 'addExternalController'
  | 'addNativeController'
  | 'addService'
  | 'addVerificationMethod'
  | 'initializeDidState'
  | 'removeExternalController'
  | 'removeNativeController'
  | 'removeService'
  | 'removeVerificationMethod'
  | 'updateVerificationMethodFlags';
export const mappedOpNames = [
  'addExternalController',
  'addNativeController',
  'addService',
  'addVerificationMethod',
  'initializeDidState',
  'removeExternalController',
  'removeNativeController',
  'removeService',
  'removeVerificationMethod',
  'updateVerificationMethodFlags',
];

type SubsetMappedWriteOps = Pick<DIDRegistry, WriteOps>;

// A GatewayToken contract instance with the write operations converted from their default
// ethers.js return values to the type passed as O
export type MappedWriteOperation<O> = {
  [Property in keyof SubsetMappedWriteOps]: (
    ...args: Parameters<SubsetMappedWriteOps[Property]>
  ) => Promise<O>;
};

// List of the read operations on the GatewayToken contract that are exposed via this library
export type ReadOnlyOps = 'resolveDidState' | 'isGenerativeDidState';
export const readOnlyOpNames = ['resolveDidState', 'isGenerativeDidState'];

// A GatewayToken contract instance with the read operations exposed
export type ReadOnlyOperation = Pick<DIDRegistry, ReadOnlyOps>;
