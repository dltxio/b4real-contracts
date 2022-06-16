import { expect } from "chai";
import { ethers } from "hardhat";
import { ethers as tsEthers } from "ethers";
import hre from "hardhat";

import { getRevertMessage } from "./utils";

let B4REAL: tsEthers.Contract;
let deployer: tsEthers.Signer;
let taxAddress: string;
let userAddress: string;
let whiteListAddress: string;

describe("B4REAL token tests", async () => {
  before(async () => {
    deployer = (await ethers.getSigners())[0];
    userAddress = "0x18a5ff44dcc65e8bFD01F48496f8f4Be6980CaA9";
    taxAddress = "0xe3F078F80A530cCD3BbF221612dDca3B0724579D";
    whiteListAddress = "0xb7c87887173cA53Db40f706b671602ad8D1479F4";

    const B4REALContract = await ethers.getContractFactory("B4REAL");

    B4REAL = await B4REALContract.deploy();

    await B4REAL.deployed();
  });

  it("Should get 50 million balance after contract deployment", async () => {
    const balance = await B4REAL.balanceOf(await deployer.getAddress());
    expect(balance.toString()).to.equal("50000000000000000000000000");
  });

  it("Should get all of the fee setup after contract deployment", async () => {
    const taxFee = ethers.BigNumber.from("10");
    const taxFeeDecimals = ethers.BigNumber.from("0");
    expect(await B4REAL.taxFee()).to.equal(taxFee);
    expect(await B4REAL.taxFeeDecimals()).to.equal(taxFeeDecimals);
  });

  it("Should only allow admin to setup fees", async () => {
    const taxFee = ethers.BigNumber.from("10");
    const taxFeeDecimals = ethers.BigNumber.from("0");
    try {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [userAddress]
      });

      await B4REAL.setTaxFee(taxFee, taxFeeDecimals);
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [userAddress]
      });
    } catch (error) {
      expect(getRevertMessage(error)).to.equal(
        "Address does not have admin permission"
      );
    }
  });

  it("Should allow admin to add or remove whitelist", async () => {
    await B4REAL.exemptFromFee(whiteListAddress);
    const isWhitelisted = await B4REAL.whitelisted(whiteListAddress);
    expect(isWhitelisted).to.equal(false);

    await B4REAL.includeInFee(whiteListAddress);
    const isWhitelisted2 = await B4REAL.whitelisted(whiteListAddress);
    expect(isWhitelisted2).to.equal(true);
  });

  it("Should only allow admin to add whiteList", async () => {
    try {
      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [userAddress]
      });
      await B4REAL.exemptFromFee(whiteListAddress);
      await hre.network.provider.request({
        method: "hardhat_stopImpersonatingAccount",
        params: [userAddress]
      });
    } catch (error) {
      expect(getRevertMessage(error)).to.equal(
        "Address does not have admin permission"
      );
    }
  });

  it("Should calculate fee", async () => {
    const amount = ethers.utils.parseEther("100");
    const feePercentage = ethers.BigNumber.from("2000");
    const feeDecimals = ethers.BigNumber.from("3");
    const fee = await B4REAL.calculateFee(amount, feePercentage, feeDecimals);
    expect(fee).to.equal(ethers.utils.parseEther("2"));
  });

  it("Should test the transfer function and not tax with a normal tranaction", async () => {
    const openingBalance = await B4REAL.balanceOf(userAddress);
    expect(openingBalance.toString()).to.equal("0");

    const amount = ethers.utils.parseEther("100");

    await B4REAL.transfer(userAddress, amount);

    const currentBalance = await B4REAL.balanceOf(userAddress);

    const taxBalance = Number(
      ethers.utils.formatEther(await B4REAL.balanceOf(taxAddress))
    );

    const amountEth = Number(ethers.utils.formatEther(amount));
    const currentBalanceEth = Number(ethers.utils.formatEther(currentBalance));

    // no tax should be applied
    expect(currentBalanceEth.toString()).to.equal("100");
    expect(taxBalance.toString()).to.equal("0");
  });

  it("Should test the transfer function and apply tax correctly", async () => {
    await B4REAL.includeInFee(whiteListAddress);
    const isWhitelisted2 = await B4REAL.whitelisted(whiteListAddress);
    expect(isWhitelisted2).to.equal(true);

    const openingBalance = await B4REAL.balanceOf(whiteListAddress);
    expect(openingBalance.toString()).to.equal("0");

    const amount = ethers.utils.parseEther("100");

    await B4REAL.transfer(whiteListAddress, amount);

    const currentBalance = await B4REAL.balanceOf(whiteListAddress);

    const taxBalance = Number(
      ethers.utils.formatEther(await B4REAL.balanceOf(taxAddress))
    );

    const currentBalanceEth = Number(ethers.utils.formatEther(currentBalance));

    // 2% of 100 is 2, 100 - 2 = 98 ect
    expect(taxBalance.toString()).to.equal("10");
    expect(currentBalanceEth.toString()).to.equal("90");
  });

  it("Should allow owner role to be changed", async () => {
    const deployerAddress = await deployer.getAddress();
    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [deployerAddress]
    });
    const OWNER_ROLE = await B4REAL.OWNER_ROLE();

    const ownerIsDeployer = await B4REAL.hasRole(OWNER_ROLE, deployerAddress);
    expect(ownerIsDeployer).to.equal(true);

    await B4REAL.transferOwnership(userAddress);

    const userIsDeployer = await B4REAL.hasRole(OWNER_ROLE, userAddress);
    expect(userIsDeployer).to.equal(true);

    await hre.network.provider.request({
      method: "hardhat_stopImpersonatingAccount",
      params: [deployerAddress]
    });
  });
});