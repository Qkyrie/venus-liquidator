async function main() {
    // We get the contract to deploy
    const VenusFlashLiquidator = await ethers.getContractFactory("VenusFlashLiquidator");
    const cream = await VenusFlashLiquidator.deploy();

    console.log("VenusFlashLiquidator deployed to:", cream.address);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });