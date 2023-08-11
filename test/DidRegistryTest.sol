// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import {DIDRegistry} from "../src/DidRegistry.sol";

contract DidRegistryTest is Test {
    DIDRegistry public didRegistry;

    function setUp() public {
        didRegistry = new DIDRegistry();
    }

    function test() public {}

    function _attemptToAddVerificationMethod(address user, DIDRegistry.VerificationMethod memory newVm) internal  {
        didRegistry.initializeDidState(user);
        didRegistry.addVerificationMethod(user, newVm);
    }
}
