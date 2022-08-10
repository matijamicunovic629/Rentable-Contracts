// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC2981/ERC2981ContractWideRoyalties.sol";

contract SampleERC721 is
    ERC721,
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Pausable,
    AccessControl,
    ERC2981ContractWideRoyalties
{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    //interface ID of ERC2981 royalties stanadard
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // contract wide royalties can be set here
    uint256 private royalties;
    address private royaltiesRecipient = 0x5C5959C43663852416F4ce5A8dC63fb6d7e4B4CF; // address of the contract that will receive royalties


    event Mint(address indexed to, uint256 indexed tokenId, string tokenURI);

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Permission Denied: User does not have admin role"
        );
        _;
    }

    constructor() ERC721("RentableAsset", "RAST") {
        // Roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(DEFAULT_ADMIN_ROLE, DEFAULT_ADMIN_ROLE);
        //Setting contract wide royalties
        _setRoyalties(royaltiesRecipient, 500);
    }

    function pause() public onlyAdmin {
        _pause();
    }

    function unpause() public onlyAdmin {
        _unpause();
    }

    /// @notice Mint one token to `to`
    /// @param to the recipient of the token
    /// @param _tokenURI the URI of the token
    function mint(
        address to,
        string memory _tokenURI
    ) public onlyAdmin whenNotPaused {
        safeMint(to, _tokenURI);
    }

    function safeMint(
        address to,
        string memory _tokenURI
    ) internal onlyAdmin whenNotPaused {
        _safeMint(to, _tokenIdCounter.current());
        _setTokenURI(_tokenIdCounter.current(), _tokenURI);
        emit Mint(to, _tokenIdCounter.current(), _tokenURI);
        _tokenIdCounter.increment();
    }

    function setRoyalties(address _recipient, uint256 _value)
        external
        onlyAdmin
    {
        require(
            _value <= 5000,
            "ERC2981Royalties: Royalties can not be more than 50%"
        );
        _setRoyalties(_recipient, _value);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
        whenNotPaused
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
