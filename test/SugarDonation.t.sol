// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../src/SugarDonation.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

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

    function test_SetWhitelistToken() public {
        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(token), true);

        assertTrue(sugarDonation.isTokenWhitelisted(creator, address(token)), "Token should be whitelisted");

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(token), false);
        assertFalse(sugarDonation.isTokenWhitelisted(creator, address(token)), "Token should not be whitelisted");
    }

    function test_DonateERC20() public {
        uint256 donationAmount = 100 * 10 ** 18;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;
        uint256 amountAfterFee = donationAmount - fee;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(token), true);

        vm.prank(donor);
        token.approve(address(sugarDonation), donationAmount);

        vm.prank(donor);
        sugarDonation.donate(creator, address(token), donationAmount);

        assertEq(sugarDonation.ownerFees(deployer, address(token)), fee, "Owner fee should be correct");
        assertEq(
            sugarDonation.creatorBalances(creator, address(token)), amountAfterFee, "Creator balance should be correct"
        );
    }

    function test_DonateETH() public {
        uint256 donationAmount = 1 ether;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;
        uint256 amountAfterFee = donationAmount - fee;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(0), true);

        vm.deal(donor, donationAmount);

        vm.prank(donor);
        sugarDonation.donate{value: donationAmount}(creator, address(0), donationAmount);

        assertEq(sugarDonation.ownerFees(deployer, address(0)), fee, "Owner fee should be correct");
        assertEq(
            sugarDonation.creatorBalances(creator, address(0)), amountAfterFee, "Creator balance should be correct"
        );
    }

    function test_DonateWithNonWhitelistedToken() public {
        vm.prank(donor);
        token.approve(address(sugarDonation), 100 * 10 ** 18);

        vm.prank(donor);
        vm.expectRevert("Token not whitelisted by the creator");
        sugarDonation.donate(creator, address(token), 100 * 10 ** 18);
    }

    function test_WithdrawOwnerFeesERC20() public {
        uint256 donationAmount = 100 * 10 ** 18;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(token), true);

        vm.prank(donor);
        token.approve(address(sugarDonation), donationAmount);
        vm.prank(donor);
        sugarDonation.donate(creator, address(token), donationAmount);

        assertEq(sugarDonation.ownerFees(deployer, address(token)), fee, "Owner fee should be set correctly");

        uint256 ownerBalanceBefore = token.balanceOf(deployer);

        vm.prank(deployer);
        sugarDonation.withdrawOwnerFees(address(token));

        assertEq(sugarDonation.ownerFees(deployer, address(token)), 0, "Owner fee should be zero after withdrawal");
        assertEq(token.balanceOf(deployer), ownerBalanceBefore + fee, "Owner should receive tokens");
    }

    function test_WithdrawOwnerFeesETH() public {
        uint256 donationAmount = 1 ether;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(0), true);

        vm.deal(donor, donationAmount);
        vm.prank(donor);
        sugarDonation.donate{value: donationAmount}(creator, address(0), donationAmount);

        assertEq(sugarDonation.ownerFees(deployer, address(0)), fee, "Owner fee should be set correctly");

        uint256 ownerBalanceBefore = deployer.balance;

        vm.prank(deployer);
        sugarDonation.withdrawOwnerFees(address(0));

        assertEq(sugarDonation.ownerFees(deployer, address(0)), 0, "Owner fee should be zero after withdrawal");
        assertEq(deployer.balance, ownerBalanceBefore + fee, "Owner should receive ETH");
    }

    function test_WithdrawOwnerFeesWithNoFees() public {
        vm.prank(deployer);
        vm.expectRevert("No fees to withdraw");
        sugarDonation.withdrawOwnerFees(address(token));
    }

    function test_WithdrawCreatorFundsERC20() public {
        uint256 donationAmount = 100 * 10 ** 18;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;
        uint256 amountAfterFee = donationAmount - fee;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(token), true);

        vm.prank(donor);
        token.approve(address(sugarDonation), donationAmount);
        vm.prank(donor);
        sugarDonation.donate(creator, address(token), donationAmount);

        uint256 creatorBalanceBefore = token.balanceOf(creator);

        vm.prank(creator);
        sugarDonation.withdrawCreatorFunds(address(token));

        assertEq(
            sugarDonation.creatorBalances(creator, address(token)), 0, "Creator balance should be zero after withdrawal"
        );
        assertEq(token.balanceOf(creator), creatorBalanceBefore + amountAfterFee, "Creator should receive tokens");
    }

    function test_WithdrawCreatorFundsETH() public {
        uint256 donationAmount = 1 ether;
        uint256 fee = (donationAmount * sugarDonation.FEE_PERCENTAGE()) / 100;
        uint256 amountAfterFee = donationAmount - fee;

        vm.prank(creator);
        sugarDonation.setWhitelistToken(address(0), true);

        vm.deal(donor, donationAmount);
        vm.prank(donor);
        sugarDonation.donate{value: donationAmount}(creator, address(0), donationAmount);

        uint256 creatorBalanceBefore = creator.balance;

        vm.prank(creator);
        sugarDonation.withdrawCreatorFunds(address(0));

        assertEq(
            sugarDonation.creatorBalances(creator, address(0)), 0, "Creator balance should be zero after withdrawal"
        );
        assertEq(creator.balance, creatorBalanceBefore + amountAfterFee, "Creator should receive ETH");
    }

    function test_WithdrawCreatorFundsWithNoFunds() public {
        vm.prank(creator);
        vm.expectRevert("No funds to withdraw");
        sugarDonation.withdrawCreatorFunds(address(token));
    }
}
