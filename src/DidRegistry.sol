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

    struct Service {
        bytes32 fragment;
        string service_type;
        string service_endpoint;
    }

    struct DidDocument {
        string id;
        VerificationMethod[] verificationMethods;
        Service[] services;
        address[] nativeControllers;
        string[] assertionMethod;
        string[] authentication;
        string[] capabilityInvocation;
        string[] capabilityDelegation;
    }

    mapping(string => DidDocument) private didDocuments;

    //////// Fetching/Resolving Did /////////////
    function resolveDid(address authorityKey) public pure returns(string memory) {
        return string(bytes.concat("did:bnb:", bytes20(authorityKey)));
    }

    function resolveDidDocument(string calldata didId) external view returns(DidDocument memory) {
        DidDocument memory didDocument = didDocuments[didId];

        if(bytes(didDocument.id).length != 0) {
            return didDocument;
        }

        DidDocument memory defaultDidDocument = _getDefaultDidDocument(didId);
        return defaultDidDocument;
    }


    //////// Create/Update Did ////////////
    // TODO Should external calls explixitly create did documents or should they automatically be created upon updates? 
    function createDidDocument(address authorityKey) external returns(string memory didId) {
        require(!_doesDidDocumentExist(authorityKey), "Did document already exist");

        didId = resolveDid(authorityKey);

        DidDocument memory loadedDocument = _getDefaultDidDocument(didId);
        DidDocument storage didDocument = didDocuments[didId];

        didDocument.id = didId;
        didDocument.verificationMethods.push(loadedDocument.verificationMethods[0]);
        didDocument.authentication.push(loadedDocument.authentication[0]);
        didDocument.capabilityInvocation.push(loadedDocument.capabilityInvocation[0]);

        return didId;
    }

    function addVerificationMethod(string calldata didId, VerificationMethod calldata verificationMethod) public returns(bool) {
        // - Verify message sender has permission to update
        // - Add verification method to did

        /**
            Questions: 
            - Should duplicates be allowed?
            - Are the authentication keys the only eligible actors that can invoke an update?
         */
    }

    function removeVerificationMethod(string calldata didId, VerificationMethod calldata verificationMethod) public returns(bool) {
        // - Verify message sender has permission to remove verification method
        // - Verify that there will still be at least 1 verification method after removal
        // - If method is a recovery key verify that msg.sender has the authority to remove it
        // - Delete verification method from did

        /**
            Questions: 
            - Are the authentication keys the only eligible actors that can invoke a removal?
         */
    }

    function addService(string calldata didId, Service calldata service) public returns(bool) {
        // - Verify message sender has permission to update
        // - Add service method to did

        /**
            Questions: 
            - Should duplicates be allowed?
            - Are the authentication keys the only eligible actors that can invoke an update?
         */
    }

    function removeService(string calldata didId, Service calldata service) public returns(bool) {
        // - Verify message sender has permission to delete
        // - Delete service method from did

        /**
            Questions: 
            - Are the authentication keys the only eligible actors that can invoke a removal?
         */
    }

    function _doesDidDocumentExist(address authorityKey) internal view returns(bool) {
        DidDocument memory didDocument = didDocuments[resolveDid(authorityKey)];
        return bytes(didDocument.id).length != 0;
    }

    function _getDefaultVerificationMethod(address authorityKey) internal pure returns(VerificationMethod memory verificationMethod) {
        return VerificationMethod({
            fragment: 'default',
            flags: 
                uint16(1) << uint16(VerificationMethodFlagBitMask.OWNERSHIP_PROOF) | 
                uint16(1) << uint16(VerificationMethodFlagBitMask.PROTECTED),
            methodType: VerificationMethodType.EcdsaSecp256k1RecoveryMethod,
            keyData: uint160(authorityKey)
        });
    }

    function _getAddressFromDid(string memory didId) internal pure returns (address) {
        // TODO make more generic to resolve address from different identifiers (ex did:bnb and did:dnd:testnet)
        return address(uint160(uint256(bytes32(bytes(didId)))));
    }

    function _getDefaultDidDocument(string memory didId) internal pure returns(DidDocument memory) {
        address authorityKey = _getAddressFromDid(didId);
        
        DidDocument memory defaultDidDocument;

        defaultDidDocument.id = didId;

        defaultDidDocument.verificationMethods = new VerificationMethod[](1);
        defaultDidDocument.verificationMethods[0] = _getDefaultVerificationMethod(authorityKey);

        defaultDidDocument.authentication = new string[](1);
        defaultDidDocument.authentication[0] = string.concat(didId, "#key1");

        defaultDidDocument.capabilityInvocation = new string[](1);
        defaultDidDocument.capabilityInvocation[0] = string.concat(didId, "#key1");


        return defaultDidDocument;
    }

}
