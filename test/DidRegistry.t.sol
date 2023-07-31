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

}
