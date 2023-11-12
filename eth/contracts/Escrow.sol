// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IFactRegistry {
    function isValid(bytes32 _fact) external view returns (bool);
}

contract Escrow is Ownable {
    IFactRegistry private factRegistry =
        IFactRegistry(0x5274D7321E14407b30a21606D0034e694f502889);
    string StarkAddress =
        "0x05F761ae8fb3207e8F676eBF4b12e1b15459439E704A88Bca6aa64F81A2CF36C";
    address public borrower; //NFT Lender = Money Borrower
    //No need to store the Lender address, as we don't need to update it on L1 till L2 contract resolves
    address public nftContract;
    uint256 public nftTokenId;

    //This is to trigger Herodotus so we don't have to store them on L1 but to sync with L2 we need to emit those parameters
    event LendingNft(address borrower, address nftContract, uint256 nftTokenId);

    constructor(address initialOwner) Ownable(initialOwner) {}

    //We could have just one function and could operate without holding the borrower
    function sendToLender(address lender) internal {
        ERC721(nftContract).transferFrom(address(this), lender, nftTokenId);
        _clearStateVariables();
    }

    function sendToBorrower() internal {
        ERC721(nftContract).transferFrom(address(this), borrower, nftTokenId);
        _clearStateVariables();
    }

    function lendNft(address _nftContract, uint256 _nftTokenId) public {
        require(borrower == address(0), "NFT already lent");
        ERC721(_nftContract).transferFrom(
            msg.sender,
            address(this),
            _nftTokenId
        );
        emit LendingNft(msg.sender, _nftContract, _nftTokenId);
    }

    function resolveNft(uint256 blockNumOfProof) public onlyOwner {
        if (
            factRegistry.isValid(
                keccak256(abi.encodePacked("2", StarkAddress, blockNumOfProof))
            )
        ) {
            sendToBorrower();
        } else if (
            factRegistry.isValid(
                keccak256(abi.encodePacked("3", StarkAddress, blockNumOfProof))
            )
        ) {
            sendToLender(msg.sender);
        }
    }

    function _clearStateVariables() private {
        borrower = address(0);
        nftContract = address(0);
        nftTokenId = 0;
    }
}
