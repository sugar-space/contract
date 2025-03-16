// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {SugarDonation} from "../src/SugarDonation.sol";
import "forge-std/console.sol";

contract DeploySugarDonation is Script {
    function run() external returns (SugarDonation) {
        vm.startBroadcast();

        SugarDonation sugarDonation = new SugarDonation();
        console.log("SugarDonation deployed at:", address(sugarDonation));

        vm.stopBroadcast();

        return sugarDonation;
    }
}
