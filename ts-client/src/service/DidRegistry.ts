import { DidRegistryInternal } from './DidRegistryInternal';
import {
  DIDRegistry as DIDRegistryTypechain,
  DIDRegistry__factory,
} from '../contracts/typechain-types';
import { ContractTransaction, Wallet } from 'ethers';
import { Options } from '../utils/types';
import { Provider } from '@ethersproject/providers';
import { DidIdentifier } from './DidIdentifier';
import { Signer } from '@ethersproject/abstract-signer';
import { ChainEnviroment } from '../utils';

export class DidRegistry extends DidRegistryInternal<
  DIDRegistryTypechain,
  ContractTransaction
> {
  readonly providerOrWallet: Provider | Wallet;
  private chainEnviorment: ChainEnviroment = 'mainnet';
  private did?: DidIdentifier;

  constructor(
    // ethers.js requires a Wallet instead of Signer for the _signTypedData function, until v6
    providerOrWallet: Provider | Wallet,
    didRegistryContractAddress: string,
    options: Options = {}
  ) {
    const didRegistryContract = DIDRegistry__factory.connect(
      didRegistryContractAddress,
      providerOrWallet
    );
    super(didRegistryContract, options);

    if (options.chainEnvironment) {
      this.chainEnviorment = options.chainEnvironment;
    }

    this.providerOrWallet = providerOrWallet;
  }

  /**
   * Can be used to optionally set a DID in Read-Only Setups (when passed a Provider)
   */
  setDidIdentifier(identifier: string | undefined) {
    if (identifier) {
      this.did = DidIdentifier.create(identifier, this.chainEnviorment);
    } else {
      this.did = undefined;
    }
  }

  get address(): string | undefined {
    const anyProviderOrWallet = this.providerOrWallet as any;
    if (anyProviderOrWallet.address) {
      // Address property of Wallet
      return anyProviderOrWallet.address;
    }
  }

  getDid(): DidIdentifier {
    if (this.did) {
      return this.did;
    }

    if (this.address) {
      return DidIdentifier.create(this.address, this.chainEnviorment);
    }

    throw new Error('No Signer to access DID');
  }
}
