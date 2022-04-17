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
    address public owner; // owner of the contract
    mapping(uint256 => rent) public listOfRenting; // list of renting property
    uint256 public rentingID = 0; // renting index
    address nftContractAddress; // NFT contract address

    ///@notice this function is a constructor function
    ///@param _nftContractAddress is the address of the NFT
    constructor(address _nftContractAddress) {
        owner = msg.sender;
        nftContractAddress = _nftContractAddress;
    }

    // renting state
    enum statusOfRent {
        pending,
        cancel,
        complete
    }

    // Rent attributes
    struct rent {
        address[] OwnerAdress;
        address renterAdress;
        uint256 price;
        uint256 propertyID;
        statusOfRent status;
    }

    event RentNewProperty(uint256 propertyID, address renterAdress);
    event ApproveRent(uint256 rentingId, address owner);

    ///@notice Users can rent a new property by paying the renting fee using this function
    ///@param _id is the ID of the NFT that the renter wants to rent
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
        emit RentNewProperty(_id, msg.sender);
    }

    ///@notice this function can validate the ownership of a property(NFT)
    ///@param _add is the address of the owner's of the property
    ///@param _owner is the address of one of the owner of that property
    ///@return true if the _owner is one of the owner of the property
    function checkTheValidOwner(address[] memory _add, address _owner)
        private
        returns (bool)
    {
        for (uint256 i; i < _add.length; i++) {
            if (_add[i] == _owner) {
                return true;
            }
        }
        return false;
    }

    ///@notice this function can will return the renting request of that property
    ///@param _propertyId is the ID of the property
    ///@return the renting request of that property
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

    ///@notice this function can approve the renting request of that property,only owner can call this function
    ///@param _rentingId is the ID of the renting list
    function approveRent(uint256 _rentingId) public {
        require(
            checkTheValidOwner(
                listOfRenting[_rentingId].OwnerAdress,
                address(msg.sender)
            ),
            "Not the property owner"
        );
        listOfRenting[_rentingId].status = statusOfRent.complete;
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
        emit ApproveRent(_rentingId, msg.sender);
    }

    ///@notice this function can cancel the renting request of that property,only owner can call this function
    ///@param _rentingId is the ID of the renting list
    function cancelRent(uint256 _rentingId) public {
        require(
            checkTheValidOwner(
                listOfRenting[_rentingId].OwnerAdress,
                address(msg.sender)
            ),
            "Not the property owner"
        );
        listOfRenting[_rentingId].status = statusOfRent.cancel;
        payable(listOfRenting[_rentingId].renterAdress).transfer(
            listOfRenting[_rentingId].price
        );
    }

    ///@notice this function is used to show the current balance of the function
    ///@return it returns the total balance of the contract
    function contractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
