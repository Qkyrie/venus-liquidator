pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Router.sol";
import "./IComptroller.sol";
import "./Cerc20.sol";
import "./Cether.sol";
import "./FlashLoanReceiverBase.sol";
import "./ILendingPool.sol";
import "hardhat/console.sol";

contract VenusFlashLiquidator is Ownable, FlashLoanReceiverBase {

    address public comptrollerAddress = 0xfD36E2c2a6789Db23113685031d7F16329158384;
    address public uniswapIntermediateAsset = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public uniswapRouter02Address = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;

    address public uniswapFactoryAddress = 0xBCfCcbde45cE874adCB698cC183deBcF17952812;


    address public vBNB = 0xA07c5b74C9B40447a954e1466938b865b6BBea36;
    address public wBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;

    using SafeERC20 for IERC20;

    uint256 public MAX_INT = 2 ** 256 - 1;

    constructor() FlashLoanReceiverBase(ILendingPoolAddressesProvider(0xCc0479a98cC66E85806D0Cd7970d6e07f77Fd633)) Ownable() public {

    }

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) override external {
        require(
            _amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance, was the flashLoan successful?"
        );

        console.log('we have %s BNB', address(this).balance);

        LiquidationData memory liquidationData = abi.decode(_params, (LiquidationData));
        if (liquidationData.vTokenDebt == vBNB) {
            //debt is bnb, we can just liquidate this
        } else {
            //first wrap the BNB
            IWETH(wBNB).deposit{value : _amount}();
            uint256 wbnbBalance = IERC20(wBNB).balanceOf(address(this));
            if (wbnbBalance > 0) {
                uniswap(wBNB, Cerc20(liquidationData.vTokenDebt).underlying(), wbnbBalance, 0);
            }

            uint256 amount = IERC20(Cerc20(liquidationData.vTokenDebt).underlying()).balanceOf(address(this));

            doLiquidation(liquidationData.vTokenDebt, amount, liquidationData.user, liquidationData.vTokenCollateral);
        }


        console.log("done liquidation");
        console.log('we have % BNB', address(this).balance);
        console.log('we have %s wBNB', IERC20(wBNB).balanceOf(address(this)));

        //we switch everything back to WBNB
        if (liquidationData.vTokenCollateral != vBNB) {
            uint256 collateralBalance = IERC20(Cerc20(liquidationData.vTokenCollateral).underlying()).balanceOf(address(this));
            console.log('vTokens: %s', IERC20(liquidationData.vTokenCollateral).balanceOf(address(this)));
            if (collateralBalance > 0) {
                console.log('we had %s collateral', collateralBalance);
                uniswap(Cerc20(liquidationData.vTokenCollateral).underlying(), wBNB, collateralBalance, 0);
                console.log('we have %s wBNB', IERC20(wBNB).balanceOf(address(this)));
            }
        }
        if (liquidationData.vTokenDebt != vBNB) {
            uint256 debtBalance = IERC20(Cerc20(liquidationData.vTokenDebt).underlying()).balanceOf(address(this));
            if (debtBalance > 0) {
                console.log(' we still had a debt left of %s', debtBalance);
                uniswap(Cerc20(liquidationData.vTokenDebt).underlying(), wBNB, debtBalance, 0);
                console.log('we have %s wBNB', IERC20(wBNB).balanceOf(address(this)));
            }
        }

        //withdraw everything from wbnb

        uint256 wBNBBalance = IERC20(wBNB).balanceOf(address(this));
        if (wBNBBalance > 0) {
            console.log('wbnb balance was %', wBNBBalance);
            IWETH(wBNB).withdraw(wBNBBalance);
        }

        uint256 totalDebt = _amount + _fee;
        console.log('total debt is %', totalDebt);
        console.log('we have %', address(this).balance);
        console.log('vDebt: %s', IERC20(liquidationData.vTokenDebt).balanceOf(address(this)));
        console.log('collateral: %s', IERC20(liquidationData.vTokenCollateral).balanceOf(address(this)));
        console.log('wBNB: %', IERC20(wBNB).balanceOf(address(this)));
        transferFundsBackToPoolInternal(_reserve, totalDebt);
    }

    struct LiquidationData {
        address vTokenCollateral;
        address vTokenDebt;
        address user;
        uint256 borrowAmount;
    }

    // @notice Call this function to make a flash swap
    function liquidate(
        address _vTokenCollateral,
        address _vTokenDebt,
        address _user,
        uint256 _borrowAmount) external onlyOwner payable {

        validateUser(_user);

        bytes memory data = abi.encode(
            LiquidationData(
            {
            user : _user,
            vTokenCollateral : _vTokenCollateral,
            vTokenDebt : _vTokenDebt,
            borrowAmount : _borrowAmount
            }
            )
        );

        ILendingPool lendingPool = ILendingPool(
            addressesProvider.getLendingPool()
        );
        lendingPool.flashLoan(address(this), BNB_ADDRESS, _borrowAmount, data);
    }

    function validateUser(address _user) internal {
        IComptroller comptroller = IComptroller(comptrollerAddress);
        (uint256 err, uint256 liquidity, uint256 shortfall) = comptroller.getAccountLiquidity(_user);
        require(shortfall > 0, "user was healthy");
    }

    function doLiquidation(address _vTokenDebt, uint256 _amount, address _userToLiquidate, address _vTokenCollateral) internal {
        if (_vTokenDebt == vBNB) {
            Cether vTokenDebt = Cether(_vTokenDebt);
            vTokenDebt.liquidateBorrow{value : _amount}(_userToLiquidate, Cerc20(_vTokenCollateral));
        } else {
            safeAllow(Cerc20(_vTokenDebt).underlying(), _vTokenDebt);
            Cerc20 vTokenDebt = Cerc20(_vTokenDebt);

            console.log('_userToLiquidate %s', _userToLiquidate);
            console.log('_vTokenCollateral %s', _vTokenCollateral);
            uint256 error = vTokenDebt.liquidateBorrow(_userToLiquidate, _amount, _vTokenCollateral);
            console.log(error);
        }
    }

    function uniswap(address _fromToken, address _toToken, uint256 _fromAmount, uint256 _minimumToAmount) private {
        safeAllow(_fromToken, uniswapRouter02Address);
        IUniswapV2Router uniswapRouter = IUniswapV2Router(uniswapRouter02Address);

        if (directPairExists(_fromToken, _toToken)) {
            address[] memory path = new address[](2);
            path[0] = address(_fromToken);
            path[1] = address(_toToken);
            uniswapRouter.swapExactTokensForTokens(
                _fromAmount,
                _minimumToAmount,
                path,
                address(this),
                block.timestamp + 1
            );
        } else {
            address[] memory path = new address[](3);
            path[0] = address(_fromToken);
            path[1] = address(uniswapIntermediateAsset);
            path[2] = address(_toToken);
            uniswapRouter.swapExactTokensForTokens(
                _fromAmount,
                _minimumToAmount,
                path,
                address(this),
                block.timestamp + 1
            );
        }
    }

    function setUniswapIntermediateAsset(address _uniswapIntermediateAsset) public onlyOwner {
        uniswapIntermediateAsset = _uniswapIntermediateAsset;
    }

    function setUniswapRouter02Address(address _uniswapRouter02Address) public onlyOwner {
        uniswapRouter02Address = _uniswapRouter02Address;
    }

    function setUniswapFactoryAddress(address _uniswapFactoryAddress) public onlyOwner {
        uniswapFactoryAddress = _uniswapFactoryAddress;
    }

    function directPairExists(address fromToken, address toToken) view public returns (bool) {
        return IUniswapV2Factory(uniswapFactoryAddress).getPair(fromToken, toToken) != address(0);
    }

    function safeAllow(address asset, address allowee) private {
        IERC20 token = IERC20(asset);

        if (token.allowance(address(this), allowee) == 0) {
            token.safeApprove(allowee, MAX_INT);
        }
    }

    function transferTo(address _asset, address _beneficiary, uint256 _amount) external onlyOwner {
        IERC20(_asset).transfer(address(_beneficiary), _amount);
    }


    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
}
