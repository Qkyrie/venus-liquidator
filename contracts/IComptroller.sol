pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

interface IComptroller {
    function getAccountLiquidity(address account) view external returns (uint, uint, uint);
}