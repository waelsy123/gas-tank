// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {GasTank} from "../src/GasTank.sol";

contract DeployGasTank is Script {
    GasTank public gasTank;
    uint256 private _deployerPvtKey;

    function setUp() public {
        _deployerPvtKey = vm.envUint("PRIVATE_KEY");
    }

    function run() public {
        vm.startBroadcast(_deployerPvtKey);

        uint256 gasUsed = gasleft();
        gasTank = new GasTank();
        gasUsed = gasUsed - gasleft();
        console.log("Gas used to deploy GasTank contract:", gasUsed);
        console.log("GasTank contract deployed at address:", address(gasTank));

        vm.stopBroadcast();
    }

    function mint() public {
        vm.startBroadcast(_deployerPvtKey);

        gasTank = GasTank(0x0c25798271Cd0B8c97eCce31932Cc5C76C7d8888);

        uint256 gasUsed = gasleft();
        gasTank.mint("", 0);
        gasUsed = gasUsed - gasleft();
        console.log("Gas used to mint:", gasUsed);

        uint256 totalBalance = gasTank.balanceOf(address(0x3b57a32CF20595a5020458463ffF889db752d772));
        console.log("Total balance after minting:", totalBalance);
        vm.stopBroadcast();
    }
}
