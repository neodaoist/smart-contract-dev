// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Cheater {
    //
    error LieTold();
    error LieToldWithParams(uint256 _input);

    function tellTruth(uint256 _input) public pure returns (bool) {
        if (_input != 1337) {
            revert("SOMETHING_WENT_WRONG");
        }

        return true;
    }

    function tellTruthWithError(uint256 _input) public pure returns (bool) {
        if (_input != 1337) {
            revert LieTold();
        }

        return true;
    }

    function tellTruthWithErrorWithParams(uint256 _input) public pure returns (bool) {
        if (_input != 1337) {
            revert LieToldWithParams(_input);
        }

        return true;
    }

    function tellTruthWithRequire(uint256 _input) public pure returns (bool) {
        require(_input == 1337, "Requirement not met");

        return true;
    }
}
