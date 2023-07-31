/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.13;

contract DIDRegistryEvents {
    event DIDOwnerChanged(
        address indexed identity,
        address owner,
        uint previousChange
    );

    event DIDDelegateChanged(
        address indexed identity,
        bytes32 delegateType,
        address delegate,
        uint validTo,
        uint previousChange
    );

    event DIDAttributeChanged(
        address indexed identity,
        bytes32 name,
        bytes value,
        uint validTo,
        uint previousChange
    );
}

contract DIDRegistry is DIDRegistryEvents {

    enum VerificationMethodType { 
        EcdsaSecp256k1RecoveryMethod // Verification Method for For 20-bytes Ethereum Keys
    }

    // Each flag is represented by a specific bit. This enum specifies what flag corresponds to which bit.
    enum VerificationMethodFlagBitMask {
        NONE, // bit 0
        AUTHENTICATION, // bit 1
        ASSERTION, // bit 2
        CAPABILITY_INVOCATION, // bit 3
        CAPABILITY_DELEGATION, // bit 4
        OWNERSHIP_PROOF, // bit 5
        PROTECTED // bit 6
    }

    struct VerificationMethod {
        bytes32 fragment;
        uint16 flags; // The permissions this key has
        VerificationMethodType methodType;
        uint160 keyData; // Key data to match the given verification type
    }


    function _getDefaultVerificationMethod(address owner) internal pure returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'default',
            flags: uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF),
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: uint160(owner)
        });
    }

}
