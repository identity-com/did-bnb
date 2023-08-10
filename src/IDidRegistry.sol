/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;
interface IDidRegistry {
    /**
        - Events from Update and Delete operations will live here
     */
    event VerificationMethodAdded(address indexed didIdentifier, string indexed fragment);
    event VerificationMethodRemoved(address indexed didIdentifier, string indexed fragment);
    event VerificationMethodFlagsUpdated(address indexed didIdentifier, string indexed fragment, uint16 oldFlags, uint16 newFlags);

    event ServiceAdded(address indexed didIdentifier, string indexed fragment);
    event ServiceRemoved(address indexed didIdentifier, string indexed fragment);

    event ControllerAdded();
    event ControllerRemoved();

}
