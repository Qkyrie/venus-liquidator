pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

abstract contract Cerc20 {
    address public underlying;
    function liquidateBorrow(address borrower, uint amount, address collateral) virtual external returns (uint);
    function redeem(uint redeemTokens) public virtual returns (uint);
}