/**
 * A class representing a Did Identifier
 */
import { VerificationMethod } from 'did-resolver';
import { ChainEnviroment, DID_BNB_PREFIX } from '../utils';

export type DidIdentifierConstructor = {
  chainEnviroment: ChainEnviroment | undefined;
  identifier: string;
  fragment?: string;
};

export class DidIdentifier {
  /**
   * The cluster the DID points to
   */
  chainEnviroment: ChainEnviroment | undefined;
  /**
   * The method specific identifier of the did
   */
  identifier: string;
  /**
   * The optional field following the DID address and `#`
   */
  fragment?: string;

  constructor(constructor: DidIdentifierConstructor) {
    this.chainEnviroment = constructor.chainEnviroment;
    this.identifier = constructor.identifier;
    this.fragment = constructor.fragment;
  }

  /**
   * Clones this
   */
  clone(): DidIdentifier {
    return new DidIdentifier({
      chainEnviroment: this.chainEnviroment,
      identifier: this.identifier,
      fragment: this.fragment,
    });
  }

  /**
   * Returns a new `DecentralizedIdentifier` but with `urlField` swapped to the parameter
   * @param urlField The new url field
   */
  withUrl(urlField: string): DidIdentifier {
    return new DidIdentifier({
      ...this,
      fragment: urlField,
    });
  }

  private get didMethodSuffixString(): string {
    if (!this.chainEnviroment) {
      return 'unknown:';
    }
    if (this.chainEnviroment === 'mainnet') {
      return '';
    }
    return `${this.chainEnviroment}:`;
  }

  toString(includeURL = true): string {
    const path = ''; // TODO
    const query = ''; // TODO
    const fragment =
      !this.fragment || this.fragment === '' ? '' : `#${this.fragment}`;

    let urlExtension = '';
    if (includeURL) {
      urlExtension = `${path}${query}${fragment}`;
    }
    return `${DID_BNB_PREFIX}:${this.didMethodSuffixString}${this.identifier}${urlExtension}`;
  }

  // Note fragment is always the last field in the URI.
  // https://www.rfc-editor.org/rfc/rfc3986#section-3.5
  // TODO: Note, this REGEX is not robust towards URI spec, specifically paths and queries.
  // TODO add support for / urls and ? query params
  static REGEX = new RegExp(`^${DID_BNB_PREFIX}:?(\\w*):(\\w+)#?(\\w*)$`);

  /**
   * Parses a given did string
   * @param did the did string
   */
  static parse(did: string | VerificationMethod): DidIdentifier {
    if (isStringDID(did)) {
      const matches = DidIdentifier.REGEX.exec(did);

      if (!matches) throw new Error('Invalid DID');

      const identifier = matches[2];

      return new DidIdentifier({
        chainEnviroment: mapDidSuffix(matches[1]),
        identifier,
        fragment: matches[3],
      });
    } else {
      throw new Error('Provided DID is not a string');
    }
  }

  static valid(did: string): boolean {
    try {
      DidIdentifier.parse(did);
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Creates a new did
   * @param authority The authority and key of the did
   * @param clusterType The cluster the did points to
   * @param urlField An optional extra field
   */
  static create(
    identifier: string,
    chainEnviroment: ChainEnviroment | undefined,
    urlField?: string
  ): DidIdentifier {
    return new DidIdentifier({
      chainEnviroment,
      identifier,
      fragment: urlField,
    });
  }
}

export const mapDidSuffix = (
  didSuffix: string
): ChainEnviroment | undefined => {
  switch (didSuffix) {
    case '':
      return 'mainnet';
    case 'testnet':
      return 'testnet';
  }
  // return undefined if not found
};

export const isStringDID = (
  identifier: VerificationMethod | DidIdentifier | string
): identifier is string => typeof identifier === 'string';
