const {ethers} = require("hardhat");
const {use, expect} = require("chai");
const {solidity} = require("ethereum-waffle");

use(solidity);

describe("Single pool DEX", function () {
  let dexContract;
  let balloonsContract;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("Deploy contracts", function () {
    it("Should deploy BalloonsContract", async function () {
      const BalloonsContract = await ethers.getContractFactory("Balloons");
      balloonsContract = await BalloonsContract.deploy();
    });
    it("Should deploy DEX", async function () {
      const Dex = await ethers.getContractFactory("DEX");
      dexContract = await Dex.deploy(balloonsContract.address);
    });

    it("Should provide DEX with initial liquidity", async function () {
      await balloonsContract.approve(
        dexContract.address,
        ethers.utils.parseEther("3")
      );
      await dexContract.init(ethers.utils.parseEther("3"), {
        value: ethers.utils.parseEther("3"),
        gasLimit: 200000,
      });

      expect(await ethers.provider.getBalance(dexContract.address)).to.equal(
        ethers.utils.parseEther("3")
      );
      expect(await balloonsContract.balanceOf(dexContract.address)).to.equal(
        ethers.utils.parseEther("3")
      );
    });

    describe("Buy tokens", function () {
      it("Should be able to buy tokens", async function () {
        const dexTokenBalanceBefore = await balloonsContract.balanceOf(
          dexContract.address
        );

        const price = await dexContract.price(
          ethers.utils.parseEther("1"), // eth input
          await ethers.provider.getBalance(dexContract.address), // eth reserve
          dexTokenBalanceBefore // token reserve
        );

        const ethToTokenResult = await dexContract.ethToToken({
          value: ethers.utils.parseEther("1"),
        });
        await ethToTokenResult.wait();

        expect(await ethers.provider.getBalance(dexContract.address)).to.equal(
          ethers.utils.parseEther("4")
        );

        const dexTokenBalanceAfter = await balloonsContract.balanceOf(
          dexContract.address
        );

        expect(dexTokenBalanceAfter.add(price)).to.equal(dexTokenBalanceBefore);
      });
    });

    describe("Buy ETH", function () {
      it("Should be able to buy ETH", async function () {
        const ethBalanceBefore = await ethers.provider.getBalance(
          dexContract.address
        );

        const tokensReserve = await balloonsContract.balanceOf(
          dexContract.address
        );

        const price = await dexContract.price(
          ethers.utils.parseEther("1"), // input tokens
          tokensReserve, // tokens reserve
          ethBalanceBefore // eth reserve
        );

        await balloonsContract.approve(
          dexContract.address,
          ethers.utils.parseEther("1")
        );
        const tokenToEthResult = await dexContract.tokenToEth(
          ethers.utils.parseEther("1")
        );
        await tokenToEthResult.wait();

        const ethBalanceAfter = await ethers.provider.getBalance(
          dexContract.address
        );

        expect(ethBalanceBefore).to.equal(ethBalanceAfter.add(price));
      });
    });

    describe("Deposit to pool", function () {
      it("Should be able to deposit to pool", async function () {
        const ethReserveBefore = await ethers.provider.getBalance(
          dexContract.address
        );
        const tokensReserveBefore = await balloonsContract.balanceOf(
          dexContract.address
        );

        const ethTokenRatioBefore = ethReserveBefore.div(tokensReserveBefore);

        const depositAmount = ethers.utils.parseEther("1");
        await balloonsContract.approve(
          dexContract.address,
          ethers.utils.parseEther("10")
        );

        const depositResult = await dexContract.deposit({
          value: depositAmount,
        });
        await depositResult.wait();

        const ethReserveAfter = await ethers.provider.getBalance(
          dexContract.address
        );
        const tokensReserveAfter = await balloonsContract.balanceOf(
          dexContract.address
        );

        const ethTokenRatioAfter = ethReserveAfter.div(tokensReserveAfter);

        expect(ethTokenRatioBefore).to.equal(ethTokenRatioAfter);
      });
    });

    describe("Withdraw from the pool", function () {
      it("Should be able to withdraw from the pool", async function () {
        const ethReserveBefore = await ethers.provider.getBalance(
          dexContract.address
        );
        const tokensReserveBefore = await balloonsContract.balanceOf(
          dexContract.address
        );

        const ethTokenRatioBefore = ethReserveBefore.div(tokensReserveBefore);

        const withDrawAmount = ethers.utils.parseEther("1");
        await balloonsContract.approve(
          dexContract.address,
          ethers.utils.parseEther("10")
        );

        const withdrawResult = await dexContract.deposit({
          value: withDrawAmount,
        });
        await withdrawResult.wait();

        const ethReserveAfter = await ethers.provider.getBalance(
          dexContract.address
        );
        const tokensReserveAfter = await balloonsContract.balanceOf(
          dexContract.address
        );

        const ethTokenRatioAfter = ethReserveAfter.div(tokensReserveAfter);

        expect(ethTokenRatioBefore).to.equal(ethTokenRatioAfter);
      });
    });
  });
});
