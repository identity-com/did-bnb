// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";
import "solidity-stringutils/strings.sol";

contract CounterTest is Test {
    using strings for *;

    DIDRegistry public didRegistry;

    function setUp() public {
        didRegistry = new DIDRegistry();
    }

    function test_should_resolve_did() public {
        address user = vm.addr(1);
        string memory userAsString = "0x7e5f4552091a69125d5dfcb7b8c2659029395bdf"; // foundry vm.addr(1) is deterministic
        string memory did = didRegistry.resolveDid(user);


        string memory resolvedAddressAsString = did.toSlice().beyond("did:bnb:".toSlice()).toString();

        // address addr = hexStringToAddress(resolvedAddressAsString);

       //  address resolvedAddress = address(bytes20(uint160(uint256(keccak256(abi.encodePacked(resolvedAddressAsString))))));
        console.log("%s with resolved address is: %s", did, userAsString);
        console.log(didRegistry._getAddressFromDid(did));

    }

    function test_fuzz_should_resolve_did() public {

    }

    function test_fuzz_should_resolve_did_state() public {

    }
}
