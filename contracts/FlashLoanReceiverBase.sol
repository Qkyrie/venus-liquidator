pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IFlashLoanReceiver.sol";
import "./ILendingPoolAddressesProvider.sol";

abstract contract FlashLoanReceiverBase is IFlashLoanReceiver {

    ILendingPoolAddressesProvider public addressesProvider;

    address public constant BNB_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(ILendingPoolAddressesProvider _provider) {
        addressesProvider = _provider;
    }

    receive() external payable {}

    function transferFundsBackToPoolInternal(address _reserve, uint256 _amount)
    internal
    {
        address payable core = addressesProvider.getLendingPoolCore();
        transferInternal(core, _reserve, _amount);
    }

    function transferInternal(
        address payable _destination,
        address _reserve,
        uint256 _amount
    ) internal {
        if (_reserve == BNB_ADDRESS) {
            //solium-disable-next-line
            _destination.call{value: _amount, gas: 50000}("");
            return;
        }
        IERC20(_reserve).transfer(_destination, _amount);
    }

    function getBalanceInternal(address _target, address _reserve)
    internal
    view
    returns (uint256)
    {
        if (_reserve == BNB_ADDRESS) {
            return _target.balance;
        }
        return IERC20(_reserve).balanceOf(_target);
    }
}