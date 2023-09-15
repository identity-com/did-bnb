import {
  RawVerificationMethod,
  VerificationMethodType,
  BitwiseVerificationMethodFlag,
} from './doc';
import { DIDRegistry } from '../contracts/typechain-types';

export class VerificationMethod {
  private constructor(private _rawVerificationMethod: RawVerificationMethod) {}

  get raw(): RawVerificationMethod {
    return this._rawVerificationMethod;
  }

  static from(
    rawVerificationMethod: RawVerificationMethod
  ): VerificationMethod {
    return new VerificationMethod(rawVerificationMethod);
  }

  get fragment(): string {
    return this._rawVerificationMethod.fragment;
  }

  get keyData(): string {
    // TODO, this should be generates as a Byteslike from Typechain.
    return this._rawVerificationMethod.keyData;
  }

  get methodType(): VerificationMethodType {
    return this._rawVerificationMethod.methodType;
  }

  get flags(): VerificationMethodFlags {
    return new VerificationMethodFlags(this._rawVerificationMethod.flags);
  }
}

export class VerificationMethodFlags {
  constructor(private _flags: number) {}

  static none() {
    return new VerificationMethodFlags(0);
  }

  static of(flags: number) {
    return new VerificationMethodFlags(flags);
  }

  get raw(): number {
    return this._flags;
  }

  static ofArray(
    flags: BitwiseVerificationMethodFlag[]
  ): VerificationMethodFlags {
    return flags.reduce(
      (acc, flag) => acc.set(flag),
      VerificationMethodFlags.none()
    );
  }

  get array(): BitwiseVerificationMethodFlag[] {
    return Object.keys(BitwiseVerificationMethodFlag)
      .map((i) => parseInt(i))
      .filter((i) => !isNaN(i) && this.has(i));
  }

  has(flag: BitwiseVerificationMethodFlag): boolean {
    return (this._flags & flag) === flag;
  }

  set(flag: BitwiseVerificationMethodFlag): VerificationMethodFlags {
    this._flags |= flag;
    return this;
  }

  clear(flag: BitwiseVerificationMethodFlag): VerificationMethodFlags {
    this._flags &= ~flag;
    return this;
  }
}
