// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract HouseNFT is ERC1155 {
    address public owner;
    uint256 public collectionId = 0;
    mapping(uint256 => address[]) public ownerPropertyList;
    uint256 public ownerPropertyId = 0;

    constructor() ERC1155("https://ipfs.io/ipfs/HASH_VALUE/{id}.json") {
        owner = msg.sender;
    }

    function CreateNewSingleHouseNFT() public {
        _mint(msg.sender, collectionId, 100, "");
        ownerPropertyList[collectionId].push(msg.sender);
        collectionId += 1;
    }

    function TransferFrom(
        address _to,
        uint256 _id,
        uint256 _value,
        string memory _data
    ) public {
        bytes memory data = convertIntoByte(_data);
        safeTransferFrom(msg.sender, _to, _id, _value, data);
        ownerPropertyList[_id].push(_to);
    }

    function convertIntoByte(string memory _a)
        private
        pure
        returns (bytes memory)
    {
        return (bytes(_a));
    }

    function uri(uint256 _tokenid)
        public
        pure
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "https://ipfs.io/ipfs/HASH_VALUE/",
                    Strings.toString(_tokenid),
                    ".json"
                )
            );
    }

    function viewOwnerList(uint256 _id)
        external
        view
        returns (address[] memory)
    {
        return ownerPropertyList[_id];
    }
}
