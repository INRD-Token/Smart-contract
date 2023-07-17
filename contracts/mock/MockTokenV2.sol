// SPDX-License-Identifier: MIT
// Used for testing upgradability
pragma solidity ^0.8.4;

import "../INRD.sol";

contract MockTokenV2 is INRD {
    bool public isThisNewVersion = true;
}
