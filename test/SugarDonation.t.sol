// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/SugarDonation.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract SugarDonationTest is Test {
    SugarDonation public sugarDonation;
    MockToken public token;

    address public creator = address(0x1);
    address public donor = address(0x2);
    address public deployer;

    function setUp() public {
        deployer = address(0x3);
        vm.prank(deployer);
        sugarDonation = new SugarDonation();

        token = new MockToken("MockToken", "MTK");
        token.transfer(donor, 1000 * 10 ** 18);
    }

    // function testWhitelistToken() public {
    //     vm.prank(creator);
    //     sugarDonation.whitelistToken(address(token));

    //     assertTrue(sugarDonation.isTokenWhitelisted(creator, address(token)), "Token should be whitelisted");
    // }

    // function testDonate() public {
    //     vm.prank(creator);
    //     sugarDonation.whitelistToken(address(token));

    //     vm.prank(donor);
    //     token.approve(address(sugarDonation), 100 * 10 ** 18);

    //     vm.prank(donor);
    //     sugarDonation.donate(creator, address(token), 100 * 10 ** 18);

    //     assertEq(sugarDonation.totalDonations(creator), 98 * 10 ** 18, "Total donations should be 98 MTK");
    //     assertEq(token.balanceOf(deployer), 2 * 10 ** 18, "Deployer should receive 2 MTK as fee");
    //     assertEq(token.balanceOf(creator), 98 * 10 ** 18, "Creator should receive 98 MTK");
    // }

    function testDonateWithNonWhitelistedToken() public {
        vm.prank(donor);
        token.approve(address(sugarDonation), 100 * 10 ** 18);

        vm.prank(donor);
        vm.expectRevert("Token not whitelisted by the creator");
        sugarDonation.donate(creator, address(token), 100 * 10 ** 18);
    }
}
