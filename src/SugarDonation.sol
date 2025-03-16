// SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SugarDonation is Ownable {
    event DonationReceived(address indexed donor, address indexed creator, address token, uint256 amount);
    event TokenWhitelisted(address indexed creator, address token);

    mapping(address => mapping(address => bool)) public whitelistedTokens;
    mapping(address => uint256) public totalDonations;

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

    function whitelistToken(address token) external {
        whitelistedTokens[msg.sender][token] = true;
        emit TokenWhitelisted(msg.sender, token);
    }

    function donate(address creator, address token, uint256 amount) external nonReentrant {
        require(whitelistedTokens[creator][token], "Token not whitelisted by the creator");

        uint256 fee = (amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - fee;

        totalDonations[creator] += amountAfterFee;

        emit DonationReceived(msg.sender, creator, token, amountAfterFee);

        bool feeSuccess = IERC20(token).transferFrom(msg.sender, owner(), fee);
        require(feeSuccess, "Fee transfer failed");

        bool donationSuccess = IERC20(token).transferFrom(msg.sender, creator, amountAfterFee);
        require(donationSuccess, "Donation transfer failed");
    }

    function isTokenWhitelisted(address creator, address token) external view returns (bool) {
        return whitelistedTokens[creator][token];
    }
}
