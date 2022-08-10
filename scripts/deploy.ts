import { ethers } from "hardhat";

async function main() {
  // const currentTimestampInSeconds = Math.round(Date.now() / 1000);
  // const ONE_YEAR_IN_SECS = 365 * 24 * 60 * 60;
  // const unlockTime = currentTimestampInSeconds + ONE_YEAR_IN_SECS;

  // const lockedAmount = ethers.utils.parseEther("1");

  const ERC20 = await ethers.getContractFactory("TestERC20");
  const _token = await ERC20.deploy("USDC", "USDC");
  const token = await _token.deployed();

  const rentable = await ethers.getContractFactory("Rentable");
  const Rentable = await rentable.deploy(token.address, "5");

  // await lock.deployed();

  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
