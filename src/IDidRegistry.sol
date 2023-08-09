/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;
interface IDidRegistry {
    /**
        - Events from Update and Delete operations will live here
     */
    event VerificationMethodAdded(string indexed didId, string indexed fragment);
    event VerificationMethodRemoved(string indexed didId, string indexed fragment);
    event VerificationMethodFlagsUpdated(string indexed didId, string indexed fragment, uint16 oldFlags, uint16 newFlags);

    event ServiceAdded(string indexed didId, string indexed fragment);
    event ServiceRemoved(string indexed didId, string indexed fragment);

    event ControllerAdded();
    event ControllerRemoved();

}
