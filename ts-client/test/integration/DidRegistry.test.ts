import * as dotenv from 'dotenv';
import chai, { expect } from 'chai';
import chaiAsPromised from 'chai-as-promised';

import {
  addBalanceToTenderlyAccount,
  deployDidRegistryContractInstance,
  getDeployerWallet,
  getGeneratedDidDocument,
  getMainDidWallet,
  getSecondaryDidWallet,
  getUnauthorizedDidWallet,
} from './testUtils';
import { getDefaultProvider, Provider } from '@ethersproject/providers';
import { utils, Wallet } from 'ethers';
import {
  BitwiseVerificationMethodFlag,
  DEFAULT_KEY_ID,
  DidRegistry,
  reduceVmFlagArray,
  VerificationMethodType,
} from '../../src';
import { DidIdentifier } from '../../src/service/DidIdentifier';

dotenv.config();
chai.use(chaiAsPromised);

describe('Native TS Client Integration Test', () => {
  let didRegistry: DidRegistry;
  let otherDidRegistry: DidRegistry;
  let unauthorizedDidRegistry: DidRegistry;
  let provider: Provider;
  let didWallet: Wallet;
  let otherDidWallet: Wallet;
  let unauthorizedWallet: Wallet;

  const SECONDARY_KEY_ID = 'secondary';

  before(async () => {
    provider = getDefaultProvider(process.env.RPC_URL);
    const deployerWallet = getDeployerWallet(provider);
    didWallet = getMainDidWallet(provider);
    otherDidWallet = getSecondaryDidWallet(provider);
    unauthorizedWallet = getUnauthorizedDidWallet(provider);

    if (process.env.RPC_URL?.includes('tenderly')) {
      await addBalanceToTenderlyAccount(deployerWallet);
      await addBalanceToTenderlyAccount(didWallet);
      await addBalanceToTenderlyAccount(otherDidWallet);
      await addBalanceToTenderlyAccount(unauthorizedWallet);
    }

    const { address } = await deployDidRegistryContractInstance(deployerWallet);

    // Connect didWallet and otherDidWallet to didRegistryContract
    didRegistry = new DidRegistry(didWallet, address, {chainEnvironment: 'localnet'});
    otherDidRegistry = new DidRegistry(otherDidWallet, address, {chainEnvironment: 'localnet'});
    otherDidRegistry.setDidIdentifier(didWallet.address); // otherDidWallet is message sender, but DID is still from didWallet
    unauthorizedDidRegistry = new DidRegistry(unauthorizedWallet, address, {chainEnvironment: 'localnet'});
    unauthorizedDidRegistry.setDidIdentifier(didWallet.address); // unauthorizedDidWallet is message sender, but DID is still from didWallet
  });

  it('should generate DIDs with the correct prefix', () => {
    expect(didRegistry.getDid().toString()).to.be.a('string').and.satisfy((did: string) => did.startsWith('did:bnb:localnet:'));
  });

  it('should resolve an initial DID State of the didWallet', async () => {
    const isGenerative: boolean = await didRegistry.isGenerativeDidState();
    expect(isGenerative).to.equal(true);
    const doc = await didRegistry.resolve();
    expect(doc).to.deep.equal(
      getGeneratedDidDocument(didWallet.address, 'did:bnb:localnet:')
    );
  });

  it('should resolve an a random external (generative) external DID', async () => {
    const randomWallet = Wallet.createRandom();
    const randomDid = DidIdentifier.create(
      randomWallet.address,
      didRegistry.getDid().chainEnviroment
    );
    const isGenerative: boolean =
      await didRegistry.isGenerativeDidState(randomDid);
    expect(isGenerative).to.equal(true);
    const doc = await didRegistry.resolve(randomDid);
    expect(doc).to.deep.equal(
      getGeneratedDidDocument(randomDid.identifier, 'did:bnb:localnet:')
    );
  });

  it('should initialize a DID method on-chain', async () => {
    const tx = await didRegistry.initializeDidState().then((tx) => tx.wait());
    expect(tx.status).to.equal(1);

    const isGenerative: boolean = await didRegistry.isGenerativeDidState();
    expect(isGenerative).to.equal(false);
  });

  it('should be able to add a service to the DID', async () => {
    const service = {
      fragment: 'test',
      service_type: 'testType',
      service_endpoint: 'testEndpoint',
    };
    const tx = await didRegistry.addService(service).then((tx) => tx.wait());
    expect(tx.status).to.equal(1);

    const doc = await didRegistry.resolve();
    expect(doc.service).to.have.lengthOf(1);
    const didWithFragment = DidIdentifier.create(
      didRegistry.getDid().identifier,
      didRegistry.getDid().chainEnviroment,
      service.fragment
    );
    expect(doc.service?.[0]).to.deep.equal({
      id: didWithFragment.toString(),
      serviceEndpoint: service.service_endpoint,
      type: service.service_type,
    });
  });

  it('should be able to add a verificationMethod to the DID', async () => {
    const verificationMethod = {
      fragment: SECONDARY_KEY_ID,
      flags: reduceVmFlagArray([
        BitwiseVerificationMethodFlag.CapabilityInvocation,
      ]),
      methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020,
      keyData: utils.arrayify(otherDidWallet.address),
    };
    const tx = await didRegistry
      .addVerificationMethod(verificationMethod)
      .then((tx) => tx.wait());
    expect(tx.status).to.equal(1);
    const doc = await didRegistry.resolve();
    expect(doc.verificationMethod).to.have.lengthOf(2);
    const didWithFragment = DidIdentifier.create(
      didRegistry.getDid().identifier,
      didRegistry.getDid().chainEnviroment,
      verificationMethod.fragment
    );
    expect(doc.verificationMethod?.[1]).to.deep.equal({
      id: didWithFragment.toString(),
      controller: didRegistry.getDid().toString(),
      ethereumAddress: otherDidWallet.address.toLowerCase(),
      type: 'EcdsaSecp256k1RecoveryMethod2020',
    });
  });

  it('should be able to add a third verificationMethod with the new key', async () => {
    const randomWallet = Wallet.createRandom();
    const verificationMethod = {
      fragment: 'third',
      flags: reduceVmFlagArray([]),
      methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020,
      keyData: utils.arrayify(randomWallet.address),
    };

    const tx = await otherDidRegistry
      .addVerificationMethod(verificationMethod)
      .then((tx) => tx.wait());
    expect(tx.status).to.equal(1);
    const doc = await otherDidRegistry.resolve();
    expect(doc.verificationMethod).to.have.lengthOf(3);
    const didWithFragment = DidIdentifier.create(
      otherDidRegistry.getDid().identifier,
      otherDidRegistry.getDid().chainEnviroment,
      verificationMethod.fragment
    );
    expect(doc.verificationMethod?.[2]).to.deep.equal({
      id: didWithFragment.toString(),
      controller: otherDidRegistry.getDid().toString(),
      ethereumAddress: randomWallet.address.toLowerCase(),
      type: 'EcdsaSecp256k1RecoveryMethod2020',
    });
  });

  it('should be able to add native controller', async () => {
    const randomWallet = Wallet.createRandom();
    const nativeController = DidIdentifier.create(
      randomWallet.address,
      didRegistry.getDid().chainEnviroment
    );

    const tx = await otherDidRegistry
      .addNativeController(nativeController)
      .then((tx) => tx.wait());
    expect(tx.status).to.equal(1);

    const doc = await otherDidRegistry.resolve();
    expect(doc.controller).to.have.lengthOf(1);
    expect(doc.controller?.[0]).to.equal(nativeController.toString());
  });

  it('should be able to add external controller', async () => {
    const externalController = `did:ethr:${Wallet.createRandom().address}`;

    const tx = await otherDidRegistry
      .addExternalController(externalController)
      .then((tx) => tx.wait());
    expect(tx.status).to.equal(1);

    const doc = await otherDidRegistry.resolve();
    expect(doc.controller).to.have.lengthOf(2);
    expect(doc.controller?.[1]).to.equal(externalController);
  });

  it('should not able remove a protected key', async () => {
    return expect(
      didRegistry.removeVerificationMethod(DEFAULT_KEY_ID)
    ).to.be.rejectedWith(
      'Cannot remove verification method because of protected flag'
    );
  });

  it('should be able set Verification Method flags', async () => {
    const tx = await didRegistry
      .setVerificationMethodFlags(DEFAULT_KEY_ID, [
        BitwiseVerificationMethodFlag.Authentication,
      ])
      .then((tx) => tx.wait());
    expect(tx.status).to.equal(1);

    const doc = await didRegistry.resolve();
    const didWithFragment = DidIdentifier.create(
      didRegistry.getDid().identifier,
      didRegistry.getDid().chainEnviroment,
      DEFAULT_KEY_ID
    );
    expect(doc.authentication?.[0]).to.equal(didWithFragment.toString());
    expect(doc.capabilityInvocation?.[0]).to.not.equal(
      didWithFragment.toString()
    );
  });

  it('should not able set Ownership proof for a different key', async () => {
    return expect(
      didRegistry.setVerificationMethodFlags(SECONDARY_KEY_ID, [
        BitwiseVerificationMethodFlag.CapabilityInvocation,
        BitwiseVerificationMethodFlag.OwnershipProof,
      ])
    ).to.be.rejectedWith(
      'Message sender is not an authorized user of this did'
    );
  });

  it('should fail if an external controller has the wrong format', async () => {
    const noDid = 'adfhakjsdfhjew4';

    return expect(
      otherDidRegistry.addExternalController(noDid)
    ).to.be.rejectedWith('Invalid DID');
  });

  it('should fail if an external controller id a did:bnb', async () => {
    const randomWallet = Wallet.createRandom();
    const wrongExternalController = DidIdentifier.create(
      randomWallet.address,
      didRegistry.getDid().chainEnviroment
    ).toString();
    return expect(
      otherDidRegistry.addExternalController(wrongExternalController)
    ).to.be.rejectedWith(
      'did:bnb: cannot be used as an external controller. Add it as a native controller'
    );
  });

  it('should fail with an unauthorized key (add VM)', async () => {
    const randomWallet = Wallet.createRandom();

    const verificationMethod = {
      fragment: 'will-fail',
      flags: reduceVmFlagArray([
        BitwiseVerificationMethodFlag.CapabilityInvocation,
      ]),
      methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod2020,
      keyData: utils.arrayify(randomWallet.address),
    };

    return expect(
      unauthorizedDidRegistry.addVerificationMethod(verificationMethod)
    ).to.be.rejectedWith(
      'Message sender is not an authorized user of this did'
    );
  });

  it('should fail with an unauthorized key (add Service)', async () => {
    const service = {
      fragment: 'test',
      service_type: 'testType',
      service_endpoint: 'testEndpoint',
    };

    return expect(
      unauthorizedDidRegistry.addService(service)
    ).to.be.rejectedWith(
      'Message sender is not an authorized user of this did'
    );
  });
});
