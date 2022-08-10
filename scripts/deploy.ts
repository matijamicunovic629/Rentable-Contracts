import { ethers } from "hardhat";

async function main() {

  // const address = "USDC Address";

  const ERC721 = await ethers.getContractFactory("SampleERC721");
  const erc721 = await ERC721.deploy();
  await erc721.deployed();

  console.log("ERC721 deployed to:", erc721.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
