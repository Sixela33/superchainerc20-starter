// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Predeploys} from "@contracts-bedrock/libraries/Predeploys.sol";
import {SuperchainERC20} from "@contracts-bedrock/L2/SuperchainERC20.sol";
import {Ownable} from "@solady/auth/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";

contract L2NativeSuperchainERC20 is SuperchainERC20, Ownable, ReentrancyGuard {
    string private immutable _name;
    string private immutable _symbol;
    uint8 private immutable _decimals;
    uint256 public immutable _maxSupply;
    uint256 public immutable _unitPriceEther;
    
    event TokensPurchased(address indexed buyer, uint256 amount, uint256 value);


    constructor(
        address owner_, 
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_, 
        uint256 maxSupply_, 
        uint256 unitPriceEther
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _maxSupply = maxSupply_;
        _initializeOwner(owner_);
        _unitPriceEther = unitPriceEther;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function maxSupply() public view returns (uint256) {
        return _maxSupply;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function mintTo(address to_, uint256 amount_) external onlyOwner whenNotPaused nonReentrant {
        _mint(to_, amount_);
    }

    function purchaseTokens() external payable nonReentrant whenNotPaused {
        require(msg.value > 0, "Must send ETH");
        require(totalSupply() < _maxSupply, "All tokens have been minted");
        
        uint256 amount = msg.value / _unitPriceEther;

        if (totalSupply() + amount > _maxSupply) {
            amount = _maxSupply - totalSupply();
        }

        _mint(msg.sender, amount);

        emit TokensPurchased(msg.sender, amount, msg.value); 
    }
}
