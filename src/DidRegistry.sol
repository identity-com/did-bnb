/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.20;

import "./IDidRegistry.sol";

contract DIDRegistry is IDidRegistry {

    bytes16 private constant _HEX_DIGITS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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
        string fragment;
        uint16 flags; // The permissions this key has where each bit corresponds to a configuration flag
        VerificationMethodType methodType;
        bytes keyData; // Key data to match the given verification type
    }

    struct Service {
        string fragment; //TODO: Are fragments globally unique? Ie can a service and a verification method have the same fragment?
        string service_type;
        string service_endpoint;
    }

    struct DidState {
        VerificationMethod[] verificationMethods;
        Service[] services;
        address[] nativeControllers;
        string[] externalControllers;
    }

    mapping(address => DidState) private didStates;

    //////// Fetching/Resolving Did /////////////
    function resolveDid(address authorityKey) public pure returns(string memory) {
        return string(abi.encodePacked("did:bnb:", toHexString(authorityKey)));
    }

    function resolveDidState(string calldata didId) external view returns(DidState memory) {
        address authorityKey = _getAddressFromDid(didId);

        if(_isGenerativeDidState(authorityKey)) {
            return _getDefaultDidState(didId);
        }

        return didStates[_getAddressFromDid(didId)];
    }

    function _isGenerativeDidState(address authorityKey) internal view returns(bool) {
        DidState memory didState = didStates[authorityKey];
        return didState.nativeControllers.length != 0;
    }

    function _getDefaultVerificationMethod(address authorityKey) internal pure returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'default',
            flags: 
                uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | 
                uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED),
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: _toBytes(authorityKey)
        });
    }

    function _getDefaultDidState(string memory didId) internal pure returns(DidState memory) {
        address authorityKey = _getAddressFromDid(didId);

        DidState memory defaultDidState;

        defaultDidState.verificationMethods = new VerificationMethod[](1);
        defaultDidState.verificationMethods[0] = _getDefaultVerificationMethod(authorityKey);

        defaultDidState.nativeControllers[0] = authorityKey;

        return defaultDidState;
    }

    function _getAddressFromDid(string memory didId) internal pure returns (address) {
        // TODO make more generic to resolve address from different identifiers (ex did:bnb and did:dnd:testnet)
        return address(uint160(uint256(bytes32(bytes(didId)))));
    }


    function _toBytes(address a) internal pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    // Taken from openzeppelins implementation: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     function toHexString(address addr) internal pure returns (string memory) {
        uint256 localValue = uint256(uint160(addr));
        bytes memory buffer = new bytes(2 * _ADDRESS_LENGTH + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * _ADDRESS_LENGTH + 1; i > 1; --i) {
            buffer[i] = _HEX_DIGITS[localValue & 0xf];
            localValue >>= 4;
        }
        return string(buffer);
    }

}