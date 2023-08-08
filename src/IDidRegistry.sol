/* SPDX-License-Identifier: MIT */

pragma solidity ^0.8.19;
interface IDidRegistry {
    /**
        - Events from Update and Delete operations will live here
     */
    event VerificationMethodAdded();
    event VerificationMethodRemoved();
    event VerificationMethodUpdated();

    event ServiceAdded();
    event ServiceRemoved();

    event ControllerAdded();
    event ControllerRemoved();

}

/**
1) Write out events (just names)
2) Write out methods (just shell)
3) Write out test (just names)
 */