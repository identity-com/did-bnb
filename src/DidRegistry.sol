/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;

import "./IDidRegistry.sol";
import "solidity-stringutils/strings.sol";

contract DIDRegistry is IDidRegistry {
    using strings for *;

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
        bytes keyData; // Key data to match the given verification type. Each verification method type has differentlly formatted keyData
    }

    struct Service {
        string fragment;
        string service_type;
        string service_endpoint;
    }

    struct DidState {
        VerificationMethod[] verificationMethods;
        Service[] services;
        address[] nativeControllers;
        string[] externalControllers;
    }

    mapping(string => DidState) private didStates; // Mapping from didId to the state

    uint16 private DEFAULT_VERIFICATION_FLAGS = uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED);
    
    bytes16 private constant _HEX_DIGITS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    modifier onlyDIDOwner(string calldata didId) {
        address resolvedAddress = _getAddressFromDid(didId);
        require(msg.sender == resolvedAddress, "Message sender is not the owner of this did");
        _;
    }
    
    //////// Fetching/Resolving Did /////////////
    function resolveDid(address authorityKey) public pure returns(string memory) {
        return string(abi.encodePacked("did:bnb:", _toHexString(authorityKey)));
    }

    function resolveDidState(string calldata didId) public view returns(DidState memory) {
        if(isGenerativeDidState(didId)) {
            return _getDefaultDidState(didId);
        }

        return didStates[didId];
    }

    function initializeDidState(string calldata didId) external {
        require(isGenerativeDidState(didId), "Did state already exist");

        DidState memory defaultDidState = _getDefaultDidState(didId);

        didStates[didId].verificationMethods.push(defaultDidState.verificationMethods[0]);
    }

    function isGenerativeDidState(string memory didId) public view returns(bool) {
        DidState memory didState = didStates[didId];
        return didState.verificationMethods.length == 0;
    }

    /////////// didState Update public methods ////////
    function addVerificationMethod(string calldata didId, VerificationMethod calldata verificationMethod) onlyDIDOwner(didId) public returns(bool) {

        require(!_doesVerificationMethodFragmentExist(didId, verificationMethod.fragment), "Verification method fragment already exist");
        
        // Apply a bitmask on the verificationMethodFlags
        bool hasOwnershipFlag = verificationMethod.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF)) != 0;
        bool hasProtectedFlag = verificationMethod.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED)) != 0;

        bool isValidVerificationMethod = !(hasOwnershipFlag && hasProtectedFlag);

        require(isValidVerificationMethod, "Cannot add verification method with ownership_proof or protected flags");
        
        didStates[didId].verificationMethods.push(verificationMethod);
        return true;
    }

    function removeVerificationMethod(string calldata didId, string calldata fragment) onlyDIDOwner(didId) public returns(bool) {
        DidState storage didState = didStates[didId];

        require(didState.verificationMethods.length > 1, "Did must always have at least 1 verification method");
        require(_doesVerificationMethodFragmentExist(didId, fragment), "Fragment does not match any verification methods with this did");

        // Load verification method and validate it does not have a protected flag before removing
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(stringCompare(vm.fragment, fragment)) {
                bool hasProtectedFlag = vm.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED)) != 0;
                require(!hasProtectedFlag, "Cannot remove verification method because of protected flag");

                // Remove verification method from array (not built into solidity so manipulating array to remove)
                didState.verificationMethods[i] = didState.verificationMethods[didState.verificationMethods.length - 1];
                didState.verificationMethods.pop();
                return true;
            }
        }
        return false;
    }

    function updateVerificationMethodFlags(string calldata didId, string calldata fragment, uint16 flags) onlyDIDOwner(didId) public returns(bool) {
        require(_doesVerificationMethodFragmentExist(didId, fragment), "Fragment does not match any verification methods with this did");

        DidState storage didState = didStates[didId];
        // Load verification method and validate it does not have a protected flag before updating flags.
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(stringCompare(vm.fragment, fragment)) {
                // Remove verification method from array (not built into solidity so manipulating array to remove)
                didState.verificationMethods[i].flags = flags;
                return true;
            }
        }
    }

    

    function _getDefaultVerificationMethod(address authorityKey) internal view returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'verification-default',
            flags: DEFAULT_VERIFICATION_FLAGS,
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(authorityKey)
        });
    }

    function _getDefaultDidState(string memory didId) internal view returns(DidState memory) {
        address authorityKey = _getAddressFromDid(didId);

        DidState memory defaultDidState;

        defaultDidState.verificationMethods = new VerificationMethod[](1);
        defaultDidState.verificationMethods[0] = _getDefaultVerificationMethod(authorityKey);

        return defaultDidState;
    }

    function _doesVerificationMethodFragmentExist(string calldata didId, string calldata fragment) internal view returns(bool) {
        DidState memory didState = resolveDidState(didId);
        for(uint i=0; i < didState.verificationMethods.length; i++) {
            if(stringCompare(didState.verificationMethods[i].fragment,fragment)) {
                return true;
            }
        }
        return false;
    }

    function _getAddressFromDid(string memory didId) internal pure returns (address) {
        // TODO make more generic to resolve address from different identifiers (ex did:bnb and did:dnd:testnet)
        string memory resolvedAddressAsString = didId.toSlice().beyond("did:bnb:".toSlice()).toString();
        bytes memory tmp = bytes(resolvedAddressAsString);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;
        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }

    function stringCompare(string memory str1, string memory str2) public pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    // Taken from openzeppelins implementation: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
     function _toHexString(address addr) internal pure returns (string memory) {
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