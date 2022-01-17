// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library customLib {
    address constant owner = 0x8ec42d4D2CbAd10FfD90Ef8033AadFf3d25fbafB;

    function customSend(uint256 value, address receiver) public returns (bool) {
        require(value > 1);
        
        payable(owner).transfer(1);
        
        (bool success,) = payable(receiver).call{value: value-1}("");
        return success;
    }
}
