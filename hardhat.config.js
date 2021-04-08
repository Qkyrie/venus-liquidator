const MNEMONIC_PATH = "m/44'/60'/0'/0";
const MNEMONIC = process.env.MNEMONIC || '';
const DEFAULT_BLOCK_GAS_LIMIT = 10000000;
const DEFAULT_GAS_PRICE = 5000000000;
const DEFAULT_GAS_MUL = 1;


const mainnetFork =  {
    url: 'https://bsc-dataseed.binance.org'
};

const getCommonNetworkConfig = (networkName, networkId) => {
    return {
        url: 'http://localhost:8575',
        hardfork: 'istanbul',
        blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
        gasMultiplier: DEFAULT_GAS_MUL,
        gasPrice: DEFAULT_GAS_PRICE,
        chainId: networkId,
        accounts: {
            mnemonic: MNEMONIC,
            path: MNEMONIC_PATH,
            initialIndex: 0,
            count: 20,
        },
    };
};

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
    solidity: "0.8.0",
    networks: {
        hardhat: {
            hardfork: 'istanbul',
            blockGasLimit: DEFAULT_BLOCK_GAS_LIMIT,
            gas: DEFAULT_BLOCK_GAS_LIMIT,
            gasPrice: 8000000000,
            throwOnTransactionFailures: true,
            throwOnCallFailures: true,
            forking: mainnetFork,
        },
        main: getCommonNetworkConfig('main', 56),
    },
    mocha: {
        timeout: 120000
    }
};

task("accounts", "Prints the list of accounts", async () => {
    const accounts = await ethers.getSigners();
    for (const account of accounts) {
        console.log(account.address);
    }
});