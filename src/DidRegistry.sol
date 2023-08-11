/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;

import "./IDidRegistry.sol";

contract DIDRegistry is IDidRegistry {

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

    mapping(address => DidState) private didStates; // Mapping from didIdentifier to the state

    uint16 private DEFAULT_VERIFICATION_FLAGS = uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED);
    

    modifier onlyAuthorizedKeys(address didIdentifier) {
        require(msg.sender == didIdentifier || _isKeyAuthority(didIdentifier, msg.sender), "Message sender is not an authorized user of this did");
        _;
    }

    modifier onlyNonGenerativeDid(address didIdentifier) {
        require(!isGenerativeDidState(didIdentifier), "Only non-generative didStates are allowed for this call");
        _;
    }
    
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

    /////////// didState Update public methods ////////
    function addVerificationMethod(address didIdentifier, VerificationMethod calldata verificationMethod) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {

        require(!_doesFragmentExist(didIdentifier, verificationMethod.fragment), "Fragment already exist");
        
        // Apply a bitmask on the verificationMethodFlags
        bool hasOwnershipFlag = verificationMethod.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF)) != 0;
        bool hasProtectedFlag = verificationMethod.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED)) != 0;

        bool isValidVerificationMethod = !hasOwnershipFlag && !hasProtectedFlag;

        require(isValidVerificationMethod, "Cannot add verification method with ownership_proof or protected flags");
        
        didStates[didIdentifier].verificationMethods.push(verificationMethod);
        
        emit VerificationMethodAdded(didIdentifier, verificationMethod.fragment);
        return true;
    }

    function removeVerificationMethod(address didIdentifier, string calldata fragment) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        require(didState.verificationMethods.length > 1, "Did must always have at least 1 verification method");
        require(_doesFragmentExist(didIdentifier, fragment), "Fragment does not match any verification methods with this did");

        // Load verification method and validate it does not have a protected flag before removing
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(_stringCompare(vm.fragment, fragment)) {
                bool hasProtectedFlag = vm.flags & uint16(uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED)) != 0;
                require(!hasProtectedFlag, "Cannot remove verification method because of protected flag");

                // Remove verification method from array (not built into solidity so manipulating array to remove)
                didState.verificationMethods[i] = didState.verificationMethods[didState.verificationMethods.length - 1];
                didState.verificationMethods.pop();

                emit VerificationMethodRemoved(didIdentifier, vm.fragment);
                return true;
            }
        }
        return false;
    }

    function updateVerificationMethodFlags(address didIdentifier, string calldata fragment, uint16 flags) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(_doesFragmentExist(didIdentifier, fragment), "Fragment does not match any verification methods with this did");

        DidState storage didState = didStates[didIdentifier];
        // Load verification method and validate it does not have a protected flag before updating flags.
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(_stringCompare(vm.fragment, fragment)) {
                uint16 oldFlags = didState.verificationMethods[i].flags;              
                didState.verificationMethods[i].flags = flags;

                emit VerificationMethodFlagsUpdated(didIdentifier, fragment, oldFlags, flags);
                return true;
            }
        }
        return false;
    }

    function addService(address didIdentifier, Service calldata service) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(!_doesFragmentExist(didIdentifier, service.fragment), "Fragment already exist on another service");

        didStates[didIdentifier].services.push(service);

        emit ServiceAdded(didIdentifier, service.fragment);
        return true;
    }

    function removeService(address didIdentifier, string calldata fragment) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(_doesFragmentExist(didIdentifier, fragment), "Fragment not found");

        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.services.length; i++) {
            if(_stringCompare(didState.services[i].fragment, fragment)) {
                // Remove service from array (not built into solidity so manipulating array to remove)
                didState.services[i] = didState.services[didState.services.length - 1];
                didState.services.pop();

                emit ServiceRemoved(didIdentifier, fragment);
                return true;
            }
        }
        return false;
    }

    function addNativeController(address didIdentifier, address controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(!_doesNativeControllerExist(didIdentifier,controller), "Native controller already exist");
        didStates[didIdentifier].nativeControllers.push(controller);
        
        emit ControllerAdded(didIdentifier, abi.encodePacked(controller), true);
        return true;
    }

    function removeNativeController(address didIdentifier, address controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(didIdentifier != controller, "Cannot remove default authority key");
        require(_doesNativeControllerExist(didIdentifier,controller), "Native controller does not exist");

        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.nativeControllers.length; i++) {
            if(didState.nativeControllers[i] == controller) {
                // Remove native controller from array (not built into solidity so manipulating array to remove)
                didState.nativeControllers[i] = didState.nativeControllers[didState.nativeControllers.length - 1];
                didState.nativeControllers.pop();

                emit ControllerRemoved(didIdentifier, abi.encodePacked(controller), true);
                return true;
            }
        }
        return false;
    }

     function addExternalController(address didIdentifier, string calldata controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(!_doesExternalControllerExist(didIdentifier,controller), "External controller already exist");
        didStates[didIdentifier].externalControllers.push(controller);

        emit ControllerAdded(didIdentifier, abi.encodePacked(controller), false);
        return true;
    }

    function removeExternalController(address didIdentifier, string calldata controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(_doesExternalControllerExist(didIdentifier,controller), "External controller does not exist");

        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.externalControllers.length; i++) {
            if(_stringCompare(didState.externalControllers[i], controller)) {
                // Remove native controller from array (not built into solidity so manipulating array to remove)
                didState.externalControllers[i] = didState.externalControllers[didState.externalControllers.length - 1];
                didState.externalControllers.pop();

                emit ControllerRemoved(didIdentifier, abi.encodePacked(controller), false);
                return true;
            }
        }
        return false;
    }

    function _isKeyAuthority(address didIdentifier, address authority) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.verificationMethods.length; i++) {
            // Iterate through verification methods looking for key
            if(address(bytes20(didState.verificationMethods[i].keyData)) == authority) {
                // Does the key authority have permission to invoke
                return uint16(1) << uint16(VerificationMethodFlagBitMask.CAPABILITY_INVOCATION) != 0;
            }
        }
        return false;
    }

    function _getDefaultVerificationMethod(address authorityKey) internal view returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'verification-default',
            flags: DEFAULT_VERIFICATION_FLAGS,
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


    function _doesFragmentExist(address didIdentifier, string calldata fragment) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        // Check if fragment exist on any services 
        for(uint i=0; i < didState.services.length; i++) {
            if(_stringCompare(didState.services[i].fragment, fragment)) {
                return true;
            }
        }

        // Check if fragment exist on any verification methods
        for(uint i=0; i < didState.verificationMethods.length; i++) {
            if(_stringCompare(didState.verificationMethods[i].fragment, fragment)) {
                return true;
            }
        }
        return false;
    }

    function _doesNativeControllerExist(address didIdentifier, address controller) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];
        for(uint i=0; i < didState.nativeControllers.length; i++) {
            if(didState.nativeControllers[i] == controller) {
                return true;
            }
        }
        return false;
    }

    function _doesExternalControllerExist(address didIdentifier, string calldata controller) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];
        for(uint i=0; i < didState.externalControllers.length; i++) {
            if(_stringCompare(didState.externalControllers[i], controller)) {
                return true;
            }
        }
        return false;
    }

    function _stringCompare(string memory str1, string memory str2) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }
}