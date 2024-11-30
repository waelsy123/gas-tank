// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

/*
 * Dear Ethereum Community,
 *
 * This contract is not just code; it is an experiment, a mirror held up to the Ethereum network.
 * It challenges the boundaries of decentralized systems, exposing both their strengths and vulnerabilities.
 *
 * By leveraging network dynamics and gamifying gas consumption, this token derives its value from gas on-chain.
 * It behaves as a store of value for underutilized block space, introducing Proof of Gas — a concept akin to a battery for the EVM world.
 *
 * The minting mechanism is designed to incentivize early action within each block. The first caller to mint within a block receives the highest reward of 420 tokens. 
 * Subsequent calls within the same block see the reward halved successively (i.e., 210, 105, 52.5, etc.).
 *
 * Supply:
 * Initially, each block allows for a maximum of 420 tokens to be minted by the first participant. Subsequent participants receive progressively smaller rewards according to the halving logic.
 * Given approximately 7200 blocks per day, and the 2-year halving mechanism, the total maximum supply over the contract's lifetime will be capped at less than 8,830,080,000 tokens.
 *
 * github: https://github.com/waelsy123/gas-tank
*/

contract GasTank is ERC20, ERC20Permit {
    uint256 public constant HALVING_BLOCKS = 5256000; // approximately 2 years in blocks

    uint256 public immutable tokensPerMint = 420 * (10 ** decimals());

    uint256 public halvings;
    uint256 public lastHalvingBlock;

    mapping(uint256 => uint256) public blockMintCount;

    event Message(string message);

    constructor() ERC20("GasTank", "TANK") ERC20Permit("GasTank") {
        halvings = 0;
        lastHalvingBlock = block.number;
    }

    modifier noContract(address _addr) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        require(size == 0);
        _;
    }

    /**
     * @notice Allows users to mint tokens by proof-of-gas
     * The goal to allow only one mint per tx, we should not worry about being called by newly deployed contract
     * constructor taking into consideration amount of gas needed to deploy new contract.
     * @param message Custom message to be emitted in the `Message` event.
     * @param maxBlockMintCount User-defined maximum block mint count to protect from miner front-running.
     */
    function mint(string calldata message, uint8 maxBlockMintCount) external noContract(msg.sender) {
        require(blockMintCount[block.number] <= maxBlockMintCount, "Block mint count exceeded"); // to protect miner from being front-run

        if (block.number >= lastHalvingBlock + HALVING_BLOCKS) {
            lastHalvingBlock = block.number;
            halvings++;
        }

        uint256 currentCount = ++blockMintCount[block.number];

        // reward will be more than zero as long as exponent is < 69
        uint256 exponent = currentCount + halvings - 1;
        uint256 reward = tokensPerMint / (2 ** exponent);

        _mint(msg.sender, reward);
        emit Message(message);
    }

    function getBlockMintCount(uint256 blockNumber) external view returns (uint256) {
        return blockMintCount[blockNumber];
    }
}
