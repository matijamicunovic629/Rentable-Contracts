// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Rentable is ERC721Enumerable {
    using SafeMath for uint256;

    struct RentalUnit {
        address tokenAddr;
        uint256 tokenId;
        uint256 deposit;
        uint256 fee;
        uint256 duration;
        uint256 expiry;
        address renter;
        bool rented;
        bool complete;
    }

    uint256 NETWORK_FEE; // 1000;
    uint256 nextId;

    address USDC;
    
    mapping(uint256 => RentalUnit) unitData;
    constructor(address _USDC, uint256 _feeValue) ERC721("Rentable", "RENT") {
        USDC = _USDC;
        NETWORK_FEE = _feeValue;
    }

    function createRentalUnit(
        address _tokenAddr, 
        uint256 _tokenId, 
        uint256 _deposit, 
        uint256 _fee, 
        uint256 _duration
    ) external {
        require(_fee > 0, "Rentable: fee cannot be zero");
        require(_deposit > 0, "rentable: deposit cannot be zero");
        require(_duration > 0, "duration cannot be zero");
        require(IERC721(_tokenAddr).ownerOf(_tokenId) == msg.sender, "You do not own the token");

        unitData[nextId].tokenAddr = _tokenAddr;
        unitData[nextId].tokenId = _tokenId;
        unitData[nextId].deposit = _deposit;
        unitData[nextId].fee = _fee;
        unitData[nextId].duration = _duration;

        _mint(msg.sender, nextId);

        nextId = nextId.add(1);

        IERC721(_tokenAddr).transferFrom(msg.sender, address(this), _tokenId);

        // emit event
    }

    function rentNFT(uint256 _unitId) external {

    }

    function returnNFT(uint256 _unitId) external {

    }

    function liquidateNFT(uint256 _unitId) external {

    }
    // GET functions

    function getRentalUnit(uint256 unitId) view external returns(RentalUnit memory _unit) {
        _unit = unitData[unitId];
    }

}