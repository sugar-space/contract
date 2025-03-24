// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "lib/forge-std/src/Test.sol";
import "../src/SugarDonation.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract MockToken is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 1000000 * 10 ** 18);

    }
    function mint(address to, uint256 amount) public {
        _mint(to, amount);
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

    function testDonate() public {
        uint256 donationAmount = 100 * 10 ** 18;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;
        uint256 amountAfterFee = donationAmount - fee;
        
        console.log(donor.balance,"<--creator");
        vm.prank(creator);
        sugarDonation.whitelistToken(address(token));

        vm.prank(donor);
        token.approve(address(sugarDonation), donationAmount);


        vm.prank(donor);
        // vm.deal(donor,1 ether);
        sugarDonation.donate(creator, address(token), donationAmount);

        assertEq(token.balanceOf(address(deployer)), fee, "Owner fee should be 2 MTK");
        assertEq(sugarDonation.creatorBalances(creator, address(token)), amountAfterFee, "Creator balance should be 98 MTK");
        // assertEq(token.balanceOf(deployer), 2 * 10 ** 18, "Deployer should receive 2 MTK as fee");
        // assertEq(token.balanceOf(creator), 98 * 10 ** 18, "Creator should receive 98 MTK");
    }

    function testDonateWithNonWhitelistedToken() public {
        vm.prank(donor);
        token.approve(address(sugarDonation), 100 * 10 ** 18);

        vm.prank(donor);
        vm.expectRevert("Token not whitelisted by the creator");
        sugarDonation.donate(creator, address(token), 100 * 10 ** 18);
    }

     function testWithdrawOwnerFees() public {
        vm.prank(creator);
        sugarDonation.whitelistToken(address(token));

        uint256 donationAmount = 100 * 10 ** 18;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;

        token.mint(address(sugarDonation), fee);

        vm.deal(donor, 1 ether);

        vm.prank(donor);
        token.approve(address(sugarDonation), donationAmount);
        vm.prank(donor);
        sugarDonation.donate{value: 1 ether}(
            creator,
            address(token),
            donationAmount
        );

        assertEq(sugarDonation.ownerFee(deployer, address(token)), fee);

        uint256 ownerBalanceBefore = token.balanceOf(deployer);

        vm.prank(deployer);
        sugarDonation.withdrawOwnerFees(address(token));

        assertEq(
            sugarDonation.ownerFee(deployer, address(token)),
            0,
            "Owner fee should be zero after withdrawal"
        );
        assertEq(
            token.balanceOf(deployer),
            ownerBalanceBefore + fee,
            "Owner should receive tokens"
        );
    }

    function testWithdrawOwnerFeesWithNoFees() public {
        vm.prank(deployer);
        vm.expectRevert("No fees to withdraw");
        sugarDonation.withdrawOwnerFees(address(token));
    }

    function testWithdrawEther() public {
        uint256 amount = 1 ether;
        vm.deal(donor, amount);

        uint256 ownerBalanceBefore = deployer.balance;

        vm.prank(deployer);
        sugarDonation.withdrawEther(deployer);

        assertEq(deployer.balance, ownerBalanceBefore + amount);
    }
    
}

