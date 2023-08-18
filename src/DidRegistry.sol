/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;

import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "./IDidRegistry.sol";

contract DIDRegistry is IDidRegistry, Initializable, UUPSUpgradeable, OwnableUpgradeable {

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

    mapping(address => DidState) private didStates; // Mapping from didId to the state

    uint16 private constant DEFAULT_VERIFICATION_METHOD_FLAGS = uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(VerificationMethodFlagBitMask.CAPABILITY_INVOCATION);
    
    bytes16 private constant _HEX_DIGITS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    ///@dev no constructor in upgradable contracts. Instead we have initializers
    function initialize() public initializer {
        ///@dev as there is no constructor, we need to initialise the OwnableUpgradeable explicitly
        ///@dev sets owner of contract to deployer
       __Ownable_init();
       __UUPSUpgradeable_init();
    }

    ///@dev Required by the OZ UUPS module
   function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
    
    //////// Fetching/Resolving Did /////////////
    function resolveDidState(address didIdentifier) external view returns(DidState memory) {
        if(isGenerativeDidState(didIdentifier)) {
            return _getDefaultDidState(didIdentifier);
        }

        return didStates[didIdentifier];
    }

    function initializeDidState(address didIdentifier) external {
        require(isGenerativeDidState(didIdentifier), "Did state already exist");

        DidState memory defaultDidState = _getDefaultDidState(didIdentifier);

        didStates[didIdentifier].verificationMethods.push(defaultDidState.verificationMethods[0]);
    }

    function isGenerativeDidState(address didIdentifier) public view returns(bool) {
        DidState memory didState = didStates[didIdentifier];
        return didState.verificationMethods.length == 0;
    }

    function _getDefaultVerificationMethod(address authorityKey) internal view returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'default',
            flags: DEFAULT_VERIFICATION_METHOD_FLAGS,
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(authorityKey)
        });
    }

    function _getDefaultDidState(address didIdentifier) internal view returns(DidState memory) {

        DidState memory defaultDidState;

        defaultDidState.verificationMethods = new VerificationMethod[](1);
        defaultDidState.verificationMethods[0] = _getDefaultVerificationMethod(didIdentifier);

        return defaultDidState;
    }

}