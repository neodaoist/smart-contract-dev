// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract HelloWorld {
    //

    // uint256 public first = 123;
    // uint256 public second;

    bytes[2] public packed;

    // bytes public packed;

    constructor() {
        packed[0] = abi.encode(123);
        packed[1] = abi.encode(1);
        // packed = abi.encode(123);
    }

    function setFirst(uint256 _first) public {
        // first = first_;
        packed[0] = abi.encode(_first);
        // packed = abi.encode(_first);
    }

    function getFirst() public view returns (uint256) {
        // return first;
        return toUint256(packed[0], 0);
        // return toUint256(packed, 0);
    }

    function setSecond(uint256 _second) public {
        // second = _second;
        packed[1] = abi.encode(_second);
        // packed = abi.encode(_second + );
    }

    function getSecond() public view returns (uint256) {
        // return second;
        return toUint256(packed[1], 0);
        //
    }

    // from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L374
    function toUint256(bytes memory _bytes, uint256 _start) internal pure returns (uint256) {
        require(_bytes.length >= _start + 32, "toUint256_outOfBounds");

        uint256 temp;

        assembly {
            temp := mload(add(add(_bytes, 0x20), _start))
        }

        return temp;
    }

    // from https://ethereum.stackexchange.com/questions/4170/how-to-convert-a-uint-to-bytes-in-solidity
    function toBytes(uint256 _uint) internal pure returns (bytes memory temp) {
        temp = new bytes(32);
        assembly {
            mstore(add(temp, 32), _uint)
        }

        return temp;
    }
}
