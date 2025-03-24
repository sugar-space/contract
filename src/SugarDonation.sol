// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SugarDonation is Ownable {
    event DonationReceived(address indexed donor, address indexed creator, address token, uint256 amount);
    event Withdraw(address indexed recipient, address token, uint256 amount);
    event TokenWhitelisted(address indexed creator, address token, bool status);

    mapping(address => mapping(address => bool)) public whitelistedTokens;
    mapping(address => mapping(address => uint256)) public creatorBalances;
    mapping(address => mapping(address => uint256)) public ownerFees;

    bool private _notEntered;

    uint256 public constant FEE_PERCENTAGE = 2; // fee 2%

    constructor() Ownable(msg.sender) {
        _notEntered = true;
    }

    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    function setWhitelistToken(address token, bool status) external {
        whitelistedTokens[msg.sender][token] = status;
        emit TokenWhitelisted(msg.sender, token, status);
    }

    function donate(address creator, address token, uint256 amount) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");
        require(whitelistedTokens[creator][token], "Token not whitelisted by the creator");

        uint256 fee = (amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - fee;

        ownerFees[owner()][token] += fee;
        creatorBalances[creator][token] += amountAfterFee;

        if (token == address(0)) {
            require(msg.value == amount, "Ether value must be equal to amount");
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20 donation");
            bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
            require(success, "ERC20 transfer failed");
        }

        emit DonationReceived(msg.sender, creator, token, amountAfterFee);
    }

    function withdrawOwnerFees(address token) external nonReentrant onlyOwner {
        address currentOwner = owner();
        uint256 amount = ownerFees[currentOwner][token];
        require(amount > 0, "No fees to withdraw");

        ownerFees[currentOwner][token] = 0;

        if (token == address(0)) {
            (bool success,) = currentOwner.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            bool success = IERC20(token).transfer(currentOwner, amount);
            require(success, "ERC20 transfer failed");
        }

        emit Withdraw(currentOwner, token, amount);
    }

    function withdrawCreatorFunds(address token) external nonReentrant {
        uint256 amount = creatorBalances[msg.sender][token];
        require(amount > 0, "No funds to withdraw");

        creatorBalances[msg.sender][token] = 0;

        if (token == address(0)) {
            (bool success,) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            bool success = IERC20(token).transfer(msg.sender, amount);
            require(success, "ERC20 transfer failed");
        }

        emit Withdraw(msg.sender, token, amount);
    }

    function isTokenWhitelisted(address creator, address token) external view returns (bool) {
        return whitelistedTokens[creator][token];
    }
}
