pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

/**
@title ILendingPoolAddressesProvider interface
@notice provides the interface to fetch the LendingPoolCore address
 */

interface ILendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);

    function setLendingPoolImpl(address _pool) external;

    function getLendingPoolCore() external view returns (address payable);

    function setLendingPoolCoreImpl(address _lendingPoolCore) external;

    function getLendingPoolConfigurator() external view returns (address);

    function setLendingPoolConfiguratorImpl(address _configurator) external;

    function getLendingPoolDataProvider() external view returns (address);

    function setLendingPoolDataProviderImpl(address _provider) external;

    function getLendingPoolParametersProvider() external view returns (address);

    function setLendingPoolParametersProvider(address _parametersProvider) external;

    function getFeeProvider() external view returns (address);

    function setFeeProviderImpl(address _feeProvider) external;

    function getLendingPoolLiquidationManager() external view returns (address);

    function setLendingPoolLiquidationManager(address _manager) external;

    function getLendingPoolManager() external view returns (address);

    function setLendingPoolManager(address _lendingPoolManager) external;

    function getPriceOracle() external view returns (address);

    function setPriceOracle(address _priceOracle) external;

    function getLendingRateOracle() external view returns (address);

    function setLendingRateOracle(address _lendingRateOracle) external;

    function getRewardManager() external view returns (address);

    function setRewardManager(address _manager) external;

    function getLpRewardVault() external view returns (address);

    function setLpRewardVault(address _address) external;

    function getGovRewardVault() external view returns (address);

    function setGovRewardVault(address _address) external;

    function getSafetyRewardVault() external view returns (address);

    function setSafetyRewardVault(address _address) external;

    function getStakingToken() external view returns (address);

    function setStakingToken(address _address) external;


}