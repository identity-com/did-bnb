import {
  VerificationMethod as DidVerificationMethod,
  Service as DidService,
} from 'did-resolver';
import { DidIdentifier } from '../service/DidIdentifier';
import { VerificationMethod } from './wrappers';
import { DID_BNB_PREFIX, VALID_DID_REGEX } from './constants';

export type DidVerificationMethodComponents = {
  verificationMethod: DidVerificationMethod[];
  authentication: (string | DidVerificationMethod)[];
  assertionMethod: (string | DidVerificationMethod)[];
  keyAgreement: (string | DidVerificationMethod)[];
  capabilityInvocation: (string | DidVerificationMethod)[];
  capabilityDelegation: (string | DidVerificationMethod)[];
};

export enum BitwiseVerificationMethodFlag {
  KeyAgreement = 1 << 0,
  Authentication = 1 << 1,
  Assertion = 1 << 2,
  CapabilityInvocation = 1 << 3,
  CapabilityDelegation = 1 << 4,
  OwnershipProof = 1 << 5,
  Protected = 1 << 6,
  DidDocHidden = 1 << 7,
}

export enum VerificationMethodType {
  // TODO: Verify that this mapping is right.
  // The main Ed25519Verification Method.
  // https://w3c-ccg.github.io/lds-ed25519-2018/
  // Ed25519VerificationKey2018,
  // Verification Method for For 20-bytes Ethereum Keys
  EcdsaSecp256k1RecoveryMethod2020,
  // Verification Method for a full 32 bytes Secp256k1 Verification Key
  EcdsaSecp256k1VerificationKey2019,
}

export const mapControllers = (
  nativeControllers: string[],
  otherControllers: string[],
  chainEnv: ChainEnviroment | undefined
): string[] => {
  return [
    ...nativeControllers.map((identifier) =>
      DidIdentifier.create(identifier, chainEnv).toString()
    ),
    ...otherControllers,
  ];
};

export type RawVerificationMethod = {
  fragment: string;
  flags: number;
  methodType: number;
  keyData: string;
};

export type ChainEnviroment = 'mainnet' | 'testnet' | 'localnet';

export type RawService = {
  fragment: string;
  service_type: string;
  service_endpoint: string;
};

export const mapVerificationMethodsToDidComponents = (
  methods: VerificationMethod[],
  identifier: DidIdentifier
): DidVerificationMethodComponents => {
  const didComponents: DidVerificationMethodComponents = {
    verificationMethod: new Array<DidVerificationMethod>(),
    authentication: new Array<string>(),
    assertionMethod: new Array<string>(),
    keyAgreement: new Array<string>(),
    capabilityInvocation: new Array<string>(),
    capabilityDelegation: new Array<string>(),
  };

  for (const method of methods) {
    if (method.flags.has(BitwiseVerificationMethodFlag.DidDocHidden)) {
      continue;
    }
    if (method.flags.has(BitwiseVerificationMethodFlag.Authentication)) {
      didComponents.authentication.push(
        `${identifier.toString()}#${method.fragment}`
      );
    }
    if (method.flags.has(BitwiseVerificationMethodFlag.Assertion)) {
      didComponents.assertionMethod.push(
        `${identifier.toString()}#${method.fragment}`
      );
    }
    if (method.flags.has(BitwiseVerificationMethodFlag.KeyAgreement)) {
      didComponents.keyAgreement.push(
        `${identifier.toString()}#${method.fragment}`
      );
    }
    if (method.flags.has(BitwiseVerificationMethodFlag.CapabilityInvocation)) {
      didComponents.capabilityInvocation.push(
        `${identifier.toString()}#${method.fragment}`
      );
    }
    if (method.flags.has(BitwiseVerificationMethodFlag.CapabilityDelegation)) {
      didComponents.capabilityDelegation.push(
        `${identifier.toString()}#${method.fragment}`
      );
    }

    let vm: DidVerificationMethod = {
      id: identifier.withUrl(method.fragment).toString(),
      type: VerificationMethodType[method.methodType],
      controller: identifier.toString(),
    };

    switch (method.methodType) {
      case VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020:
        vm.ethereumAddress = method.keyData; // TODO: Update if that should be changed back to a Buffer
        break;
      case VerificationMethodType.EcdsaSecp256k1VerificationKey2019:
        vm.publicKeyHex = method.keyData; // TODO: Update if that should be changed back to a Buffer
        break;
      default:
        throw new Error(
          `Verification method type '${method.methodType}' not recognized`
        );
    }

    didComponents.verificationMethod.push(vm);
  }

  return didComponents;
};

export const mapServices = (
  services: RawService[],
  identifier: DidIdentifier
): DidService[] =>
  services.map((service) => ({
    id: `${identifier.toString()}#${service.fragment}`,
    type: service.service_type,
    serviceEndpoint: service.service_endpoint,
  }));

export const reduceVmFlagArray = (
  flags: BitwiseVerificationMethodFlag[]
): number => flags.reduce((acc, flag) => acc | flag, 0);

export const isValidDid = (did: string): boolean => VALID_DID_REGEX.test(did);

export const isDidBnb = (did: string): boolean =>
  did.startsWith(DID_BNB_PREFIX);
export const validateExternalController = (externalController: string) => {
  if (!isValidDid(externalController)) {
    throw new Error('Invalid DID');
  }

  if (isDidBnb(externalController)) {
    throw new Error(
      'did:bnb: cannot be used as an external controller. Add it as a native controller'
    );
  }
};
