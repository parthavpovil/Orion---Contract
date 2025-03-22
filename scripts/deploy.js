const hre = require("hardhat");

async function main() {
  console.log("Deploying SimpleScholarDAO contract to Open Campus...");

  const deployedContract = await hre.ethers.deployContract("SimpleScholarDAO");
  await deployedContract.waitForDeployment();

  console.log(`SimpleScholarDAO deployed to ${deployedContract.target}`);
  console.log("Admin address (your address):", deployedContract.runner.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });