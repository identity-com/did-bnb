import { Overrides } from 'ethers';

import {
  MappedWriteOperation,
  Options,
  ReadOnlyOperation,
} from '../utils';
import { omit } from 'ramda';
import { DIDRegistry } from '../contracts/typechain-types';
import { DidIdentifier } from './DidIdentifier';
import { DidDocument } from './DidDocument';
import {
  BitwiseVerificationMethodFlag,
  RawService,
  reduceVmFlagArray,
  validateExternalController,
} from '../utils';

/**
 * The main API of the Ethereum DID Client.
 * This class expects a contract object, that contains the methods specified in the
 * DID smart contract, but is agnostic to the return values of those methods.
 *
 * This allows it to be used with a contract object that returns a transaction receipt
 * (i.e. creates, signs and sends the transaction) or a PopulatedTransaction, or others.
 *
 */
export abstract class DidRegistryInternal<
  I extends MappedWriteOperation<O> & ReadOnlyOperation,
  O,
> {
  protected didRegistryContract: I;
  protected options: Options;

  protected constructor(didRegistryContract: I, options?: Options) {
    this.didRegistryContract = didRegistryContract;
    this.options = options ?? {};
  }

  abstract getDid(): DidIdentifier;

  private get overrides(): Overrides {
    return omit(['chainEnvironment'], this.options);
  }

  /**
   * Overrides that are safe to use for read-only operations.
   * Some chains / RPC providers (e.g. Polygon zkEVM) do not allow gasPrice to be set
   * for read-only operations.
   * @private
   */
  private get readOnlyOverrides(): Overrides {
    return omit(['gasPrice'], this.overrides);
  }

  public async resolve(did?: DidIdentifier): Promise<DidDocument> {
    if (!did) {
      did = this.getDid();
    }
    const didState = await this.didRegistryContract.resolveDidState(
      did.identifier,
      this.readOnlyOverrides
    );

    return DidDocument.from(did, didState);
  }

  public async isGenerativeDidState(did?: DidIdentifier): Promise<boolean> {
    if (!did) {
      did = this.getDid();
    }

    return this.didRegistryContract.isGenerativeDidState(
      did.identifier,
      this.readOnlyOverrides
    );
  }

  public async addExternalController(externalController: string): Promise<O> {
    validateExternalController(externalController);

    return this.didRegistryContract.addExternalController(
      this.getDid().identifier,
      externalController,
      this.overrides
    );
  }

  public async addNativeController(controller: DidIdentifier): Promise<O> {
    return this.didRegistryContract.addNativeController(
      this.getDid().identifier,
      controller.identifier,
      this.overrides
    );
  }

  public async addService(service: RawService): Promise<O> {
    return this.didRegistryContract.addService(
      this.getDid().identifier,
      service,
      this.overrides
    );
  }

  public async addVerificationMethod(
    verificationMethod: DIDRegistry.VerificationMethodStruct
  ): Promise<O> {
    return this.didRegistryContract.addVerificationMethod(
      this.getDid().identifier,
      verificationMethod,
      this.overrides
    );
  }

  public async initializeDidState(): Promise<O> {
    return this.didRegistryContract.initializeDidState(
      this.getDid().identifier,
      this.overrides
    );
  }

  public async removeExternalController(
    externalController: string
  ): Promise<O> {
    return this.didRegistryContract.removeExternalController(
      this.getDid().identifier,
      externalController,
      this.overrides
    );
  }

  public async removeNativeController(
    nativeController: DidIdentifier
  ): Promise<O> {
    return this.didRegistryContract.removeNativeController(
      this.getDid().identifier,
      nativeController.identifier,
      this.overrides
    );
  }

  public async removeService(fragment: string): Promise<O> {
    return this.didRegistryContract.removeService(
      this.getDid().identifier,
      fragment,
      this.overrides
    );
  }

  public async removeVerificationMethod(fragment: string): Promise<O> {
    return this.didRegistryContract.removeVerificationMethod(
      this.getDid().identifier,
      fragment,
      this.overrides
    );
  }

  public async setVerificationMethodFlags(
    fragment: string,
    flags: BitwiseVerificationMethodFlag[]
  ): Promise<O> {
    return this.didRegistryContract.updateVerificationMethodFlags(
      this.getDid().identifier,
      fragment,
      reduceVmFlagArray(flags),
      this.overrides
    );
  }
}
