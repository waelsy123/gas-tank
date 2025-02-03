// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GasTank} from "../src/GasTank.sol";

/// @notice A helper contract to test the noContract modifier.
/// It attempts to call the mint function of GasTank.
contract MintCaller {
    GasTank public gasTank;

    constructor(GasTank _gasTank) {
        gasTank = _gasTank;
    }

    function callMint(string calldata message, uint8 maxBlockMintCount) external {
        gasTank.mint(message, maxBlockMintCount);
    }
}

contract GasTankTest is Test {
    GasTank public gasTank;
    address public eoa1;
    address public eoa2;

    /// @dev Set up two EOA addresses that have no code.
    function setUp() public {
        // Use Foundry cheat codes to generate addresses
        eoa1 = vm.addr(1);
        eoa2 = vm.addr(2);
        gasTank = new GasTank();
    }

    function testInitialDeployment() public {
        // Because tokensPerMint is immutable we compare against the calculation.
        uint256 expectedTokensPerMint = 420 * (10 ** gasTank.decimals());
        assertEq(gasTank.halvings(), 0, "halvings should be zero");
        assertEq(gasTank.lastHalvingBlock(), block.number, "lastHalvingBlock should be set to deployment block");
        assertEq(gasTank.tokensPerMint(), expectedTokensPerMint, "tokensPerMint not set correctly");
    }

    function testMinting() public {
        // Use an EOA address that has no code by pranking eoa1.
        string memory message = "Test mint";
        uint8 maxBlockMintCount = 1;
        uint256 expectedReward = gasTank.tokensPerMint();

        // Expect events from the mint call.
        vm.prank(eoa1);
        vm.expectEmit(true, true, true, true);
        emit GasTank.Message(message);
        // Note: We do not check Minted here because the event order might be different.
        gasTank.mint(message, maxBlockMintCount);

        // Verify balance and block count.
        assertEq(gasTank.balanceOf(eoa1), expectedReward, "eoa1 did not receive correct reward");
        assertEq(gasTank.getBlockMintCount(block.number), 1, "Block mint count should be 1");
    }

    function testBlockMintCount() public {
        // Two mints in the same block from the same EOA.
        string memory firstMessage = "Mint 1";
        string memory secondMessage = "Mint 2";
        uint8 maxBlockMintCount = 2;

        vm.prank(eoa1);
        gasTank.mint(firstMessage, maxBlockMintCount);

        // Second mint in the same block should get a halved reward.
        uint256 secondReward = gasTank.tokensPerMint() / 2;
        vm.prank(eoa1);
        gasTank.mint(secondMessage, maxBlockMintCount);

        assertEq(gasTank.getBlockMintCount(block.number), 2, "Block mint count should be 2");
        uint256 expectedTotalBalance = gasTank.tokensPerMint() + secondReward;
        assertEq(gasTank.balanceOf(eoa1), expectedTotalBalance, "Total balance does not match expected rewards");
    }

    function testMintingExceedsMaxBlockMintCount() public {
        string memory firstMessage = "Mint 1";
        string memory secondMessage = "Mint 2";
        uint8 maxBlockMintCount = 1;

        // First mint should succeed.
        vm.prank(eoa1);
        gasTank.mint(firstMessage, maxBlockMintCount);

        // Second mint in the same block exceeds the allowed max.
        vm.prank(eoa1);
        vm.expectRevert("Block mint count exceeded");
        gasTank.mint(secondMessage, maxBlockMintCount);
    }

    function testHalving() public {
        // Mint from eoa1 in the current block.
        string memory initialMessage = "Initial mint";
        uint8 maxBlockMintCount = 1;
        vm.prank(eoa1);
        gasTank.mint(initialMessage, maxBlockMintCount);

        // Move forward in time to simulate a halving interval passing.
        uint256 currentBlock = block.number;
        // Roll forward by HALVING_BLOCKS (simulate passing of ~2 years)
        vm.roll(currentBlock + gasTank.getHalvingBlocks());

        // Next mint should trigger halving.
        string memory postHalvingMessage = "Mint after halving";
        uint256 halvedReward = gasTank.tokensPerMint() / 2;
        vm.prank(eoa1);
        gasTank.mint(postHalvingMessage, maxBlockMintCount);

        assertEq(gasTank.halvings(), 1, "Halvings counter should have incremented");
        uint256 expectedTotalBalance = gasTank.tokensPerMint() + halvedReward;
        assertEq(gasTank.balanceOf(eoa1), expectedTotalBalance, "Balance after halving mint incorrect");
    }

    function testGetNextReward() public {
        // Mint once and then query the next reward.
        string memory firstMessage = "Mint 1";
        string memory secondMessage = "Mint 2";
        uint8 maxBlockMintCount = 2;

        vm.prank(eoa1);
        gasTank.mint(firstMessage, maxBlockMintCount);

        uint256 expectedNextReward = gasTank.tokensPerMint() / 2;
        uint256 actualNextReward = gasTank.getNextReward();
        assertEq(actualNextReward, expectedNextReward, "Next reward after one mint incorrect");

        vm.prank(eoa1);
        gasTank.mint(secondMessage, maxBlockMintCount);

        expectedNextReward = gasTank.tokensPerMint() / 4;
        actualNextReward = gasTank.getNextReward();
        assertEq(actualNextReward, expectedNextReward, "Next reward after two mints incorrect");
    }

    function testNoContractCall() public {
        // Deploy a helper contract that will try to call mint.
        MintCaller caller = new MintCaller(gasTank);

        // When the helper contract calls mint, msg.sender will be the contract address,
        // and the noContract modifier should cause a revert.
        vm.expectRevert("No contract calls allowed");
        caller.callMint("Contract call", 1);
    }
}
