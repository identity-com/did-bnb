import * as assert from 'assert';
import * as dotenv from 'dotenv';

dotenv.config();

import {
  deployDidRegistryContractInstance,
  getDeployerWallet,
  getMainDidWallet,
  addBalanceToTenderlyAccount,
} from './testUtils';
import { DIDRegistry } from '../../src/contracts/typechain-types';
import { getDefaultProvider, Provider } from '@ethersproject/providers';
import { Wallet } from 'ethers';

describe('TypeChain Client Integration Test', () => {
  let didRegistryContract: DIDRegistry;
  let provider: Provider;
  let didWallet: Wallet;

  before(async () => {
    provider = getDefaultProvider(process.env.RPC_URL);
    const deployerWallet = getDeployerWallet(provider);
    didWallet = getMainDidWallet(provider);

    if (process.env.RPC_URL?.includes('tenderly')) {
      await addBalanceToTenderlyAccount(deployerWallet);
      await addBalanceToTenderlyAccount(didWallet);
    }

    didRegistryContract =
      await deployDidRegistryContractInstance(deployerWallet);

    // Connect didWallet to didRegistryContract
    didRegistryContract = didRegistryContract.connect(didWallet);
  });

  it('should verify initial did on state', async () => {
    const isGenerative: boolean =
      await didRegistryContract.isGenerativeDidState(didWallet.address, {
        gasLimit: 30000000,
      });
    assert.equal(isGenerative, true);
  });

  it('should initialize did on chain', async () => {
    const tx = await didRegistryContract.initializeDidState(didWallet.address, {
      gasLimit: 30000000,
    });
    await tx.wait();

    const isGenerative: boolean =
      await didRegistryContract.isGenerativeDidState(didWallet.address, {
        gasLimit: 30000000,
      });
    assert.equal(isGenerative, false);
  });

  it('should create verification method on chain', async () => {
    const vmTx = await didRegistryContract.addVerificationMethod(
      didWallet.address,
      {
        fragment: 'test',
        flags: 0,
        methodType: 0,
        keyData: didWallet.address,
      },
      { gasLimit: 30000000 }
    );
    await vmTx.wait();

    const didState = await didRegistryContract.resolveDidState(
      didWallet.address,
      { gasLimit: 30000000 }
    );
    assert.equal(didState.verificationMethods.length, 2);
  });
});
