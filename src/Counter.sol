// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*
 * Dear Ethereum Founders and Community,
 *
 * This contract is not just code; it is an experiment, a mirror held up to the Ethereum network.
 * It challenges the boundaries of decentralized systems, exposing both their strengths and vulnerabilities.
 * 
 * By leveraging network dynamics and gamifying gas consumption, this token embodies the spirit of innovation, 
 * disruption, and, perhaps, chaos. It forces us to reflect on the power and consequences of open, 
 * permissionless networks.
 *
 * Will Ethereum's resilience stand the test of disruptive intent? Will the community adapt, criticize, or embrace it?
 * This token does not ask for approval; it demands reaction.
 *
 * Sincerely,
 * The Creator
 */

contract ProofOfGasToken is ERC20 {
    uint256 public tokensPerMint = 50 * (10 ** decimals());
    uint256 public lastHalving;
    uint256 public halvingInterval = 365 days;
    uint256 public lastMintBlock;

    mapping(uint256 => uint256) private blockMintCount;

    struct MintRecord {
        address miner;
        string message;
    }

    MintRecord[] public mintRecords;

    event Minted(address indexed miner, string message, uint256 tokensMinted);

    constructor() ERC20("ProofOfGasToken", "POGT") {
        lastHalving = block.timestamp;
    }

    function mint(string calldata message) external {
        if (block.number != lastMintBlock) {
            lastMintBlock = block.number;
            blockMintCount[block.number] = 0;
        }

        blockMintCount[block.number]++;
        uint256 reward = calculateReward(blockMintCount[block.number]);

        if (block.timestamp >= lastHalving + halvingInterval && tokensPerMint > 1) {
            tokensPerMint = tokensPerMint / 2;
            lastHalving = block.timestamp;
        }

        require(reward >= 1, "Reward too low to mint");
        _mint(msg.sender, reward);
        mintRecords.push(MintRecord(msg.sender, message));
        emit Minted(msg.sender, message, reward);
    }

    function calculateReward(uint256 mintCount) public view returns (uint256) {
        return tokensPerMint / (2 ** (mintCount - 1));
    }

    function getMintRecord(uint256 id) external view returns (MintRecord memory) {
        require(id < mintRecords.length, "Invalid record ID");
        return mintRecords[id];
    }
}
