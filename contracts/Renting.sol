// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFT.sol";

interface HouseNFTInterface {
    function viewOwnerList(uint256 _id)
        external
        view
        returns (address[] memory);

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id)
        external
        view
        returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids)
        external
        view
        returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

contract RentingContract {
    address public owner;
    mapping(uint256 => rent) public listOfRenting;
    uint256 public rentingID = 0;
    address nftContractAddress;

    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
    }

    enum statusOfRent {
        pending,
        cancel,
        active,
        complete
    }
    struct rent {
        address[] OwnerAdress;
        address renterAdress;
        uint256 price;
        uint256 propertyID;
        statusOfRent status;
    }

    function viewAl(uint256 _id) public view returns (address[] memory) {
        return listOfRenting[_id].OwnerAdress;
    }

    function rentNewProperty(uint256 _id) public payable {
        address[] memory allOwner = HouseNFTInterface(nftContractAddress)
            .viewOwnerList(_id);
        listOfRenting[rentingID] = rent(
            allOwner,
            msg.sender,
            msg.value,
            _id,
            statusOfRent.pending
        );
        rentingID += 1;
    }

    function checkTheValidOwner(address[] memory _add, address _owner)
        public
        returns (bool)
    {
        for (uint256 i; i < _add.length; i++) {
            if (_add[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    function getRentingRequest(uint256 _propertyId)
        public
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        for (uint256 i; i < rentingID; i++) {
            if (
                listOfRenting[i].propertyID == _propertyId &&
                listOfRenting[i].status == statusOfRent.pending
            ) {
                return (
                    i,
                    listOfRenting[i].price,
                    listOfRenting[i].renterAdress
                );
            }
        }
    }

    function approveRent(uint256 _rentingId) public {
        require(
            checkTheValidOwner(
                listOfRenting[_rentingId].OwnerAdress,
                address(msg.sender)
            ),
            "Not the property owner"
        );

        uint256 _propertyId = listOfRenting[_rentingId].propertyID;
        address[] memory allOwner = HouseNFTInterface(nftContractAddress)
            .viewOwnerList(_propertyId);

        for (uint256 i; i < allOwner.length; i++) {
            uint256 percent = HouseNFTInterface(nftContractAddress).balanceOf(
                allOwner[i],
                _propertyId
            );
            uint256 amount = (listOfRenting[_rentingId].price * percent) / 100;
            payable(allOwner[i]).transfer(amount);
        }
    }

    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getBlance(uint256 id) public view returns (uint256) {
        uint256 percent = HouseNFTInterface(nftContractAddress).balanceOf(
            msg.sender,
            id
        );
        return percent;
    }
}
