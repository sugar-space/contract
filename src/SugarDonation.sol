// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title SugarDonation Contract
/// @notice This contract facilitates donations to creators, supporting both ETH and ERC20 tokens, while taking a platform fee.
/// @dev Uses OpenZeppelin's Ownable and IERC20 for ownership and token transfers.
contract SugarDonation is Ownable {
    /// @notice Emitted when a donation is received.
    /// @param sender Address of the sender.
    /// @param creator Address of the creator receiving the donation.
    /// @param token Address of the token donated (address(0) for ETH).
    /// @param amount Amount of tokens (or ETH) donated after fees.
    event DonationReceived(
        address indexed sender,
        address indexed creator,
        address token,
        uint256 amount
    );

    /// @notice Emitted when funds are withdrawn.
    /// @param recipient Address receiving the withdrawn funds.
    /// @param token Address of the token withdrawn (address(0) for ETH).
    /// @param amount Amount of tokens (or ETH) withdrawn.
    event Withdraw(address indexed recipient, address token, uint256 amount);

    /// @notice Emitted when a token is whitelisted or removed from the whitelist by a creator.
    /// @param creator Address of the creator.
    /// @param token Address of the token.
    /// @param status Whitelist status (true for whitelisted, false for removed).
    event TokenWhitelisted(address indexed creator, address token, bool status);

    /// @dev Mapping to track whitelisted tokens for each creator.
    mapping(address => mapping(address => bool)) public whitelistedTokens;

    /// @dev Mapping to track creator balances for each token.
    mapping(address => mapping(address => uint256)) public creatorBalances;

    /// @dev Mapping to track platform fees collected for each token.
    mapping(address => mapping(address => uint256)) public ownerFees;

    /// @notice Platform fee percentage (2%).
    uint256 public constant FEE_PERCENTAGE = 2;

    /// @dev Reentrancy guard variable.
    bool private _notEntered;

    /// @notice Constructor initializes the contract with the owner and sets the reentrancy guard.
    constructor() Ownable(msg.sender) {
        _notEntered = true;
    }

    /// @dev Modifier to prevent reentrant calls.
    modifier nonReentrant() {
        require(_notEntered, "ReentrancyGuard: reentrant call");
        _notEntered = false;
        _;
        _notEntered = true;
    }

    /// @notice Allows a creator to whitelist or remove a token from their accepted tokens list.
    /// @param token Address of the token to whitelist/remove.
    /// @param status Boolean indicating whether to whitelist (true) or remove (false) the token.
    function setWhitelistToken(address token, bool status) external {
        whitelistedTokens[msg.sender][token] = status;
        emit TokenWhitelisted(msg.sender, token, status);
    }

    /// @notice Allows a sender to send a donation to a creator in ETH or an ERC20 token.
    /// @param creator Address of the creator to receive the donation.
    /// @param token Address of the token to donate (address(0) for ETH).
    /// @param amount Amount of tokens (or ETH) to donate.
    function donate(
        address creator,
        address token,
        uint256 amount
    ) external payable nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        if (token != address(0)) {
            require(
                whitelistedTokens[creator][token],
                "Token not whitelisted by the creator"
            );
        }

        uint256 fee = (amount * FEE_PERCENTAGE) / 100;
        uint256 amountAfterFee = amount - fee;

        ownerFees[owner()][token] += fee;
        creatorBalances[creator][token] += amountAfterFee;

        if (token == address(0)) {
            require(msg.value == amount, "Ether value must be equal to amount");
        } else {
            require(msg.value == 0, "Do not send ETH with ERC20 donation");
            bool success = IERC20(token).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            require(success, "ERC20 transfer failed");
        }

        emit DonationReceived(msg.sender, creator, token, amountAfterFee);
    }

    /// @notice Allows the owner to withdraw collected fees in ETH or ERC20 tokens.
    /// @param token Address of the token to withdraw (address(0) for ETH).
    function withdrawOwnerFees(address token) external nonReentrant onlyOwner {
        address currentOwner = owner();
        uint256 amount = ownerFees[currentOwner][token];

        require(amount > 0, "No fees to withdraw");

        ownerFees[currentOwner][token] = 0;

        if (token == address(0)) {
            (bool success, ) = currentOwner.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            bool success = IERC20(token).transfer(currentOwner, amount);
            require(success, "ERC20 transfer failed");
        }

        emit Withdraw(currentOwner, token, amount);
    }

    /// @notice Allows a creator to withdraw their collected funds in ETH or ERC20 tokens.
    /// @param token Address of the token to withdraw (address(0) for ETH).
    function withdrawCreatorFunds(address token) external nonReentrant {
        uint256 amount = creatorBalances[msg.sender][token];
        require(amount > 0, "No funds to withdraw");

        creatorBalances[msg.sender][token] = 0;

        if (token == address(0)) {
            (bool success, ) = msg.sender.call{value: amount}("");
            require(success, "ETH transfer failed");
        } else {
            bool success = IERC20(token).transfer(msg.sender, amount);
            require(success, "ERC20 transfer failed");
        }

        emit Withdraw(msg.sender, token, amount);
    }

    /// @notice Checks if a token is whitelisted by a specific creator.
    /// @param creator Address of the creator.
    /// @param token Address of the token to check.
    /// @return Boolean indicating if the token is whitelisted.
    function isTokenWhitelisted(
        address creator,
        address token
    ) external view returns (bool) {
        return whitelistedTokens[creator][token];
    }
}
