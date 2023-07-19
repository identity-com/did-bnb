// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {DIDRegistry, DIDRegistryEvents} from "../src/DidRegistry.sol";

contract CounterTest is Test, DIDRegistryEvents {
    DIDRegistry public didRegistry;
    uint public testValidity = 86400;


    function setUp() public {
        didRegistry = new DIDRegistry();
    }

    function test_unknownIdentityOwnerIsIdentity(address identity) public {
        assertEq(identity, didRegistry.identityOwner(identity));
    }

    function test_changeOwner(address newOwner) public {
        address owner = address(1);
        vm.prank(owner);
        didRegistry.changeOwner(owner, newOwner);
        assertEq(newOwner, didRegistry.identityOwner(owner));
    }

    function test_addDelegate(address newDelegate) public {
        address owner = address(2);

        // setup event expectations
        vm.expectEmit(true, false, false, true, address(didRegistry));
        emit DIDDelegateChanged(owner, 0, newDelegate, block.timestamp + testValidity, 0);

        vm.prank(owner);
        didRegistry.addDelegate(owner, 0, newDelegate, testValidity);
    }


}
