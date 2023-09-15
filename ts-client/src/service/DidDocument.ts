import {
  DIDDocument,
  Service,
  VerificationMethod as DidVerificationMethod,
} from 'did-resolver';
import {
  BitwiseVerificationMethodFlag,
  DEFAULT_KEY_ID,
  getBnbContextPrefix,
  mapControllers,
  mapServices,
  mapVerificationMethodsToDidComponents,
  VerificationMethod,
  VerificationMethodType,
  W3ID_CONTEXT,
} from '../utils';
import { DidIdentifier } from './DidIdentifier';
import { DIDRegistry } from '../contracts/typechain-types';

/**
 * A class representing a did:sol document
 * The document is less permissive than the DIDDocument specification that it implements.
 */
export class DidDocument implements DIDDocument {
  public '@context'?: 'https://www.w3.org/ns/did/v1' | string | string[] =
    DidDocument.defaultContext();
  public id: string;
  // public alsoKnownAs?: string[];
  public controller?: string[] = [];
  public verificationMethod?: DidVerificationMethod[] = [];
  public authentication?: string[] = [];
  public assertionMethod?: string[] = [];
  public keyAgreement?: string[] = [];
  public capabilityInvocation?: string[] = [];
  public capabilityDelegation?: string[] = [];
  public service?: Service[] = [];

  constructor(identifier: DidIdentifier) {
    this.id = identifier.toString();

    // default to generative case
    Object.assign(
      this,
      mapVerificationMethodsToDidComponents(
        [defaultVerificationMethod(identifier)],
        identifier
      )
    );
  }

  static defaultContext(version: string = '1.0'): string[] {
    return [W3ID_CONTEXT, getBnbContextPrefix(version)];
  }

  static sparse(identifier: DidIdentifier): DidDocument {
    return new DidDocument(identifier);
  }

  static from(
    identifier: DidIdentifier,
    didState: DIDRegistry.DidStateStructOutput
  ): DidDocument {
    const doc = DidDocument.sparse(identifier);
    // VM related

    Object.assign(
      doc,
      mapVerificationMethodsToDidComponents(
        didState.verificationMethods.map((vm) => VerificationMethod.from(vm)),
        identifier
      )
    );

    // Services
    doc.service = mapServices(didState.services, identifier);
    // Controllers
    doc.controller = mapControllers(
      didState.nativeControllers,
      didState.externalControllers,
      identifier.chainEnviroment
    );
    return doc;
  }

  static fromDoc(document: DIDDocument): DidDocument {
    const didDocument = new DidDocument(DidIdentifier.parse(document.id));
    // check requirements
    if (document.controller && !Array.isArray(document.controller)) {
      throw new Error('DIDDocument.controller must be an string array');
    }

    if (
      document.authentication &&
      !document.authentication.every((id) => typeof id === 'string')
    ) {
      throw new Error('DIDDocument.authentication must be an string array');
    }

    if (
      document.assertionMethod &&
      !document.assertionMethod.every((id) => typeof id === 'string')
    ) {
      throw new Error('DIDDocument.assertionMethod must be an string array');
    }

    if (
      document.keyAgreement &&
      !document.keyAgreement.every((id) => typeof id === 'string')
    ) {
      throw new Error('DIDDocument.keyAgreement must be an string array');
    }

    if (
      document.capabilityInvocation &&
      !document.capabilityInvocation.every((id) => typeof id === 'string')
    ) {
      throw new Error(
        'DIDDocument.capabilityInvocation must be an string array'
      );
    }

    if (
      document.capabilityDelegation &&
      !document.capabilityDelegation.every((id) => typeof id === 'string')
    ) {
      throw new Error(
        'DIDDocument.capabilityDelegation must be an string array'
      );
    }

    Object.assign(didDocument, document);
    return didDocument;
  }

  getFlagsFromVerificationMethod(
    fragment: string
  ): BitwiseVerificationMethodFlag {
    let flags = 0;

    if (
      this.authentication &&
      this.authentication.find((id) => id.endsWith(`#${fragment}`))
    ) {
      flags |= BitwiseVerificationMethodFlag.Authentication;
    }

    if (
      this.assertionMethod &&
      this.assertionMethod.find((id) => id.endsWith(`#${fragment}`))
    ) {
      flags |= BitwiseVerificationMethodFlag.Assertion;
    }

    if (
      this.keyAgreement &&
      this.keyAgreement.find((id) => id.endsWith(`#${fragment}`))
    ) {
      flags |= BitwiseVerificationMethodFlag.KeyAgreement;
    }

    if (
      this.capabilityInvocation &&
      this.capabilityInvocation.find((id) => id.endsWith(`#${fragment}`))
    ) {
      flags |= BitwiseVerificationMethodFlag.CapabilityInvocation;
    }

    if (
      this.capabilityDelegation &&
      this.capabilityDelegation.find((id) => id.endsWith(`#${fragment}`))
    ) {
      flags |= BitwiseVerificationMethodFlag.CapabilityDelegation;
    }

    return flags;
  }
}

export const defaultVerificationMethod = (
  identifier: DidIdentifier
): VerificationMethod =>
  VerificationMethod.from({
    fragment: DEFAULT_KEY_ID,
    methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020,
    flags:
      BitwiseVerificationMethodFlag.CapabilityInvocation |
      BitwiseVerificationMethodFlag.OwnershipProof |
      BitwiseVerificationMethodFlag.Protected,
    keyData: identifier.toString(false),
  });
