/* SPDX-License-Identifier: MIT */

pragma solidity 0.8.19;

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
        /// The VM can be used for encryption
        KEY_AGREEMENT, // bit 0
        /// The VM is able to authenticate the subject
        AUTHENTICATION, // bit 1
        /// The VM is able to proof assertions on the subject
        ASSERTION, // bit 2
        /// The VM can be used for issuing capabilities. Required for DID Update
        CAPABILITY_INVOCATION, // bit 3
        /// The VM can be used for delegating capabilities.
        CAPABILITY_DELEGATION, // bit 4
        /// The subject did proof to be in possession of the private key
        OWNERSHIP_PROOF, // bit 5
        /// The Verification Method is marked as protected. This means it cannot be removed
        PROTECTED, // bit 6
        /// The VM is hidden from the DID Document (off-chain only)
        DID_DOC_HIDDEN //bit 7
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

    uint16 private constant DEFAULT_VERIFICATION_METHOD_FLAGS = uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | uint16(1) << uint16(VerificationMethodFlagBitMask.CAPABILITY_INVOCATION) | uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED);

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
    

    modifier onlyAuthorizedKeys(address didIdentifier) {
        require(_isKeyAuthority(didIdentifier, msg.sender), "Message sender is not an authorized user of this did");
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
    function addVerificationMethod(address didIdentifier, VerificationMethod calldata verificationMethod) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public {

        require(!_doesFragmentExist(didIdentifier, verificationMethod.fragment), "Fragment already exist");
        require(_isValidFlag(verificationMethod.flags), "Attempted to add unsupported flag");
        
        // Apply a bitmask on the verificationMethodFlags
        bool hasOwnershipFlag =  _hasFlag(verificationMethod.flags, VerificationMethodFlagBitMask.OWNERSHIP_PROOF);
        bool hasProtectedFlag = _hasFlag(verificationMethod.flags, VerificationMethodFlagBitMask.PROTECTED);

        bool isValidVerificationMethod = !hasOwnershipFlag && !hasProtectedFlag;

        require(isValidVerificationMethod, "Cannot add verification method with ownership_proof or protected flags");
        
        didStates[didIdentifier].verificationMethods.push(verificationMethod);
        
        emit VerificationMethodAdded(didIdentifier, verificationMethod.fragment);
    }

    function removeVerificationMethod(address didIdentifier, string calldata fragment) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        require(didState.verificationMethods.length > 1, "Cannot remove verification method. Did must always have at least 1 verification method");
        require(_doesFragmentExist(didIdentifier, fragment), "Fragment does not match any verification methods with this did");

        // Load verification method and validate it does not have a protected flag before removing
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(_stringCompare(vm.fragment, fragment)) {
                bool hasProtectedFlag = _hasFlag(vm.flags, VerificationMethodFlagBitMask.PROTECTED);
                require(!hasProtectedFlag, "Cannot remove verification method because of protected flag");

                // Remove verification method from array (not built into solidity so manipulating array to remove)
                didState.verificationMethods[i] = didState.verificationMethods[didState.verificationMethods.length - 1];
                didState.verificationMethods.pop();

                // Prevent lockout
                require(_hasAuthorityVerificationMethod(didIdentifier), "Cannot remove last authority verification method");

                emit VerificationMethodRemoved(didIdentifier, vm.fragment);
                return true;
            }
        }
        return false;
    }

    function updateVerificationMethodFlags(address didIdentifier, string calldata fragment, uint16 flags) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public returns(bool) {
        require(_doesFragmentExist(didIdentifier, fragment), "Fragment does not match any verification methods with this did");
        require(_isValidFlag(flags), "Attempted to add unsupported flag");

        DidState storage didState = didStates[didIdentifier];

        // Load verification method and validate it does not have a protected flag before updating flags.
        for(uint i=0; i < didState.verificationMethods.length; i++) {

            VerificationMethod storage vm = didState.verificationMethods[i];

            if(_stringCompare(vm.fragment, fragment)) {
                // If trying to change the OWNERSHIP PROOF or PROTECTED flags the keyData must match the message sender
                bool isUpdatingOwnershipFlag =  _hasFlag(vm.flags, VerificationMethodFlagBitMask.OWNERSHIP_PROOF) != _hasFlag(flags,VerificationMethodFlagBitMask.OWNERSHIP_PROOF);
                bool isUpdatingProtectedFlag = _hasFlag(vm.flags, VerificationMethodFlagBitMask.PROTECTED)!= _hasFlag(flags,VerificationMethodFlagBitMask.PROTECTED);

                if(isUpdatingOwnershipFlag || isUpdatingProtectedFlag) {
                    require(address(bytes20(vm.keyData)) == msg.sender, "Only the verification method authority key can set the ownership proof or protected flags");
                }
                
                uint16 oldFlags = didState.verificationMethods[i].flags;              
                didState.verificationMethods[i].flags = flags;

                // Prevent lockout
                require(_hasAuthorityVerificationMethod(didIdentifier), "Cannot remove last authority verification method");

                emit VerificationMethodFlagsUpdated(didIdentifier, fragment, oldFlags, flags);
                return true;
            }
        }
        return false;
    }

    function addService(address didIdentifier, Service calldata service) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public {
        require(!_doesFragmentExist(didIdentifier, service.fragment), "Fragment already exist on another service");

        didStates[didIdentifier].services.push(service);

        emit ServiceAdded(didIdentifier, service.fragment);
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

    function addNativeController(address didIdentifier, address controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public {
        require(_doesNativeControllerExist(didIdentifier,controller) == -1, "Native controller already exist");
        didStates[didIdentifier].nativeControllers.push(controller);
        
        emit ControllerAdded(didIdentifier, abi.encodePacked(controller), true);
    }

    function removeNativeController(address didIdentifier, address controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public  {
        require(didIdentifier != controller, "Cannot remove default authority key");

        // If an index is returned the controller exits
        int index = _doesNativeControllerExist(didIdentifier,controller);
        require(index >= 0, "Native controller does not exist");

        DidState storage didState = didStates[didIdentifier];

        // Remove native controller from array (not built into solidity so manipulating array to remove)
        didState.nativeControllers[uint(index)] = didState.nativeControllers[didState.nativeControllers.length - 1];
        didState.nativeControllers.pop();

        emit ControllerRemoved(didIdentifier, abi.encodePacked(controller), true);
    }

     function addExternalController(address didIdentifier, string calldata controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public  {
        _doesExternalControllerHaveCorrectPrefix(controller);
        require(_doesExternalControllerExist(didIdentifier,controller) == -1, "External controller already exist");
        didStates[didIdentifier].externalControllers.push(controller);

        emit ControllerAdded(didIdentifier, abi.encodePacked(controller), false);
    }

    function removeExternalController(address didIdentifier, string calldata controller) onlyNonGenerativeDid(didIdentifier) onlyAuthorizedKeys(didIdentifier) public {
        
        // If an index is returned the controller exits
        int index = _doesExternalControllerExist(didIdentifier,controller);
        require(index >= 0, "External controller does not exist");

        DidState storage didState = didStates[didIdentifier];


        // Remove native controller from array (not built into solidity so manipulating array to remove)
        didState.externalControllers[uint(index)] = didState.externalControllers[didState.externalControllers.length - 1];
        didState.externalControllers.pop();

        emit ControllerRemoved(didIdentifier, abi.encodePacked(controller), false);
    }

    function _isKeyAuthority(address didIdentifier, address authority) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.verificationMethods.length; i++) {
            // Iterate through verification methods looking for key
            if(address(bytes20(didState.verificationMethods[i].keyData)) == authority) {
                // Does the key authority have permission to invoke
                if ( _hasFlag(didState.verificationMethods[i].flags, VerificationMethodFlagBitMask.CAPABILITY_INVOCATION) )
                {
                    return true;
                }
            }
        }
        return false;
    }

    function _getDefaultVerificationMethod(address authorityKey) internal pure returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'default',
            flags: DEFAULT_VERIFICATION_METHOD_FLAGS,
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: abi.encodePacked(authorityKey)
        });
    }

    function _getDefaultDidState(address didIdentifier) internal pure returns(DidState memory) {

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

    function _doesNativeControllerExist(address didIdentifier, address controller) internal view returns(int index) {
        DidState storage didState = didStates[didIdentifier];
        for(uint i=0; i < didState.nativeControllers.length; i++) {
            if(didState.nativeControllers[i] == controller) {
                // Return index if controller found
                return int(i);
            }
        }
        return -1;
    }

    function _doesExternalControllerExist(address didIdentifier, string calldata controller) internal view returns(int index) {
        DidState storage didState = didStates[didIdentifier];
        for(uint i=0; i < didState.externalControllers.length; i++) {
            if(_stringCompare(didState.externalControllers[i], controller)) {
                return int(i);
            }
        }
        return -1;
    }

    function _hasAuthorityVerificationMethod(address didIdentifier) internal view returns(bool) {
        DidState storage didState = didStates[didIdentifier];

        for(uint i=0; i < didState.verificationMethods.length; i++) {
            if(_hasFlag(didState.verificationMethods[i].flags, VerificationMethodFlagBitMask.CAPABILITY_INVOCATION)) {
                return true;
            }
        }

        return false;
    }

    function _doesExternalControllerHaveCorrectPrefix(string memory str) internal pure {
        bytes memory correctPrefix = bytes("did:");
        bytes memory bytesString = bytes(str);

        // Get first 4 charecters in string
        for(uint i = 0; i < 4; i++) {
            require(correctPrefix[i] == bytesString[i], "Invalid prefix for external controller. External controls must start with did:");
        }
    }

    function _stringCompare(string memory str1, string memory str2) internal pure returns (bool) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    function _hasFlag(uint16 flags, VerificationMethodFlagBitMask flag) internal pure returns(bool) {
        return flags & uint16(uint16(1) << uint16(flag)) != 0;
    }

    function _isValidFlag(uint16 flags) internal pure returns(bool) {
        // Shifts the input flag by the amount of flags avalible.
        return uint16(flags) >> (uint16(type(VerificationMethodFlagBitMask).max) + 1) == 0;
    }
}