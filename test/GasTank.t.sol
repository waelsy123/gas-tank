// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GasTank} from "../src/GasTank.sol";

contract GasTankTest is Test {
    GasTank public gasTank;

    function setUp() public {
        gasTank = new GasTank();
    }

    function testInitialDeployment() public view {
        assertEq(gasTank.halvings(), 0);
        assertEq(gasTank.lastHalvingBlock(), block.number);
        assertEq(gasTank.tokensPerMint(), 420 * (10 ** gasTank.decimals()));
    }

    function testMinting() public {
        string memory message = "Test mint";
        gasTank.mint(message);

        uint256 expectedReward = gasTank.tokensPerMint();
        assertEq(gasTank.balanceOf(address(this)), expectedReward);
    }

    function testHalving() public {
        gasTank.mint("mint");

        uint256 initialBlock = block.number;
        vm.roll(initialBlock + 5256000);
        gasTank.mint("First mint after halving");

        assertEq(gasTank.halvings(), 1);

        uint256 expectedReward = gasTank.tokensPerMint() * 3 / 2;
        assertEq(gasTank.balanceOf(address(this)), expectedReward);
    }

    function testBlockMintCount() public {
        gasTank.mint("Mint 1");
        gasTank.mint("Mint 2");

        assertEq(gasTank.getBlockMintCount(block.number), 2);

        uint256 expectedReward = gasTank.tokensPerMint() * 3 / 2;
        assertEq(gasTank.balanceOf(address(this)), expectedReward);
    }
}
