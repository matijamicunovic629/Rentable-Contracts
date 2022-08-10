// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Import this file to use console.log
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IRentable.sol";

contract Rentable is ERC721Enumerable, IRentable {
    using SafeMath for uint256;

    uint256 NETWORK_FEE; // 1000;
    uint256 nextId;
    address USDC;
    mapping(uint256 => RentalUnit) unitData;

    constructor(address _USDC, uint256 _feeValue) ERC721("Rentable", "RENT") {
        USDC = _USDC;
        NETWORK_FEE = _feeValue;
    }

    //
    // @dev Creates an order for a rental. Order is represented in ERC721
    // @param _tokenAddr - address of the NFT smart contract for rent
    // @param _tokenId - tokenID of the NFT to rent
    // @param _deposit - the collateral/deposit needed to cover NFT
    // @param _fee - the rental fee to be given to NFT owner
    // @param _duration - the suggested timeframe for rental
    //
    function createRentalUnit(
        address _tokenAddr, 
        uint256 _tokenId, 
        uint256 _deposit, 
        uint256 _fee, 
        uint256 _duration
    ) external {
        require(_tokenAddr != address(0), "ERCRentable20: token address should not be the zero address");
        require(_fee > 0, "Rentable: fee cannot be zero");
        require(_deposit > 0, "rentable: deposit cannot be zero");
        require(_duration > 0, "duration cannot be zero");
        require(IERC721(_tokenAddr).ownerOf(_tokenId) == msg.sender, "You do not own the token");

        IERC721(_tokenAddr).transferFrom(msg.sender, address(this), _tokenId);

        unitData[nextId].tokenAddr = _tokenAddr;
        unitData[nextId].tokenId = _tokenId;
        unitData[nextId].deposit = _deposit;
        unitData[nextId].fee = _fee;
        unitData[nextId].duration = _duration;

        _mint(msg.sender, nextId);

        emit CreateRentalUnit(msg.sender, _tokenAddr, _tokenId, _deposit, _fee, _duration, nextId);
        nextId = nextId.add(1);
    }

    //
    // @dev - renter calls this function to rent an NFT
    // @dev - renter must deposit payment + collateral
    // @param _unitId - token ID of the order
    //
    function rentNFT(uint256 _unitId) external {
        require(_exists(_unitId), "token does not exist");
        require(msg.sender != ownerOf(_unitId), "Cannot borrow to yourself");

        uint256 extraCost = unitData[_unitId].fee.mul(NETWORK_FEE).div(1000);
        uint256 totalAmount = unitData[_unitId].fee.add(unitData[_unitId].deposit).add(extraCost);

        require(IERC20(USDC).balanceOf(msg.sender) >= totalAmount, "Insufficient funds");

        IERC20(USDC).transferFrom(msg.sender, address(this), totalAmount);
        IERC721(unitData[_unitId].tokenAddr).transferFrom(address(this), msg.sender, unitData[_unitId].tokenId);

        unitData[_unitId].expiry = unitData[_unitId].duration.add(block.timestamp);
        unitData[_unitId].renter = msg.sender;
        unitData[_unitId].rented = true;

        emit RentNFT(msg.sender, _unitId);
    }

    //
    // @dev - renter calls this function to return an NFT
    // @dev - asset returns to owner, fee goes to owner, renter receives deposit
    // @param _unitId - token ID of the order
    //
    function returnNFT(uint256 _unitId) external {
        require(_exists(_unitId), "token does not exist");

        address holder = ownerOf(_unitId);
        require(IERC721(unitData[_unitId].tokenAddr).ownerOf(unitData[_unitId].tokenId) == msg.sender, "You do not own the NFT");
        
        IERC20(USDC).transfer(msg.sender, unitData[_unitId].deposit);
        IERC20(USDC).transfer(holder, unitData[_unitId].fee);
        IERC721(unitData[_unitId].tokenAddr).transferFrom(msg.sender, holder, unitData[_unitId].tokenId);

        unitData[_unitId].complete = true;
        _burn(_unitId);

        emit ReturnNFT(msg.sender, _unitId);
    }

    //
    // @dev - Liquidator may call this function
    // @dev - renters deposit is given to original asset owner
    // @dev - can only be called if loan time expires
    // @param _unitId - token ID of the order
    //
    function liquidateNFT(uint256 _unitId) external {
        require(_exists(_unitId), "token does not exist");
        require(unitData[_unitId].rented && !unitData[_unitId].complete, "Token not rented or order complete");
        require(unitData[_unitId].expiry < block.timestamp, "Not ready to liquidate");

        address holder = ownerOf(_unitId);
        uint256 liquidatorTip = unitData[_unitId].fee.div(2);
        uint256 toSend = unitData[_unitId].deposit.add(unitData[_unitId].fee).sub(liquidatorTip);

        IERC20(USDC).transfer(holder, toSend);
        IERC20(USDC).transfer(msg.sender, liquidatorTip);

        unitData[_unitId].complete = true;
        _burn(_unitId);

        emit LiquidateNFT(msg.sender, holder, _unitId);
    }

    //
    // @dev - Liquidator may call this function
    // @dev - renters deposit is given to original asset owner
    // @dev - can only be called if loan time expires
    // @param _unitId - token ID of the order
    //
    function liquidateNFTLoop() external {
        for (uint _unitId = 0; _unitId < nextId; _unitId++){
            if(!_exists(_unitId)) {
                continue;
            }

            if(!unitData[_unitId].complete && unitData[_unitId].rented && unitData[_unitId].expiry < block.timestamp) {
                address holder = ownerOf(_unitId);
                uint256 liquidatorTip = unitData[_unitId].fee.div(2);
                uint256 toSend = unitData[_unitId].deposit.add(unitData[_unitId].fee).sub(liquidatorTip);
                _burn(_unitId);
                
                IERC20(USDC).transfer(holder, toSend);
                IERC20(USDC).transfer(msg.sender, liquidatorTip);

                //emit event
            }
        }
    }

    // GET functions

    //
    // @dev - retrieves RentalUnit struct of given unitId
    // @param _unitId - token ID of the order
    //
    function getRentalUnit(uint256 unitId) view external returns(RentalUnit memory _unit) {
        _unit = unitData[unitId];
    }

    //
    // @dev - retrieves list of RentalUnit structs of given range of unitId
    // @param _from - unitID to begin at
    // @param _to - unitID to end at
    //
    function getRentalUnitList(uint256 _from, uint256 _to) view external returns(RentalUnit[] memory) {
        require(_from > 0 && _from < _to, "Invalid");
        require(_to < nextId, "Invalid");
        uint256 range = _to.sub(_from);
        require(range <= 100, "Invalid");

        RentalUnit[] memory items = new RentalUnit[](range);
        uint256 k = 0;
        for (uint256 i = _from; i <= _to; i++) {
            items[k] = unitData[i];
            k++;
        }
        return items;
    }
}