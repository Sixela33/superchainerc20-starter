// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Predeploys} from "@contracts-bedrock/libraries/Predeploys.sol";
import {SuperchainERC20} from "@contracts-bedrock/L2/SuperchainERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract L2NativeSuperchainERC20 is SuperchainERC20, Ownable, ReentrancyGuard, Pausable {
    // Immutable variables
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals;
    uint256 public immutable maxSupply;
    uint256 public immutable unitPriceEther;

    // Events
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value, uint256 remainingSupply);

    // Custom errors
    error InsufficientETH();
    error ExceedsMaxSupply();

    /**
     * @dev Constructor initializes the token contract.
     * @param owner_ Address of the contract owner.
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token.
     * @param decimals_ Number of decimals for the token.
     * @param maxSupply_ Maximum supply of tokens.
     * @param unitPriceEther_ Unit price of tokens in wei.
     */
    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 maxSupply_,
        uint256 unitPriceEther_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        maxSupply = maxSupply_;
        unitPriceEther = unitPriceEther_;
        _initializeOwner(owner_);
    }

    // Public view functions

    function name() public view virtual override returns (string memory) {
        return _name;
    }


    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function sayHello() public pure returns (string memory) {
        return "Hello, world!";
    }

    /**
     * @dev Mints tokens to a specific address.
     * @param to_ Address to receive the tokens.
     * @param amount_ Amount of tokens to mint.
     */
    function mintTo(address to_, uint256 amount_) external onlyOwner whenNotPaused nonReentrant {
        if (totalSupply() + amount_ > maxSupply) {
            revert ExceedsMaxSupply();
        }
        _mint(to_, amount_);
    }

    /*
    /**
     * @dev Allows users to purchase tokens using ETH.
    */
    function purchaseTokens() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        require(totalSupply() < maxSupply, "All tokens have been minted");

        
        uint256 amount = msg.value / unitPriceEther;
        require(amount > 0, "Insufficient ETH for one token");

        if (totalSupply() + amount > maxSupply) {
            amount = maxSupply - totalSupply();
        }

        require(amount > 0, "Nothing to mint");

        // Mint tokens
        _mint(msg.sender, amount);

        // Refund excess ETH
        uint256 refund = msg.value - (amount * unitPriceEther);
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }

        emit TokensPurchased(msg.sender, amount, msg.value, maxSupply - totalSupply());
    }

    /**
     * @dev Fallback function to prevent accidental ETH transfers.
     */
    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }
}
