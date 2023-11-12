// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Collection is ERC721, Ownable {
    uint256 private _nextTokenId;

    constructor(
        address initialOwner
    ) ERC721("Collection", "Col") Ownable(initialOwner) {}

    function _baseURI() internal pure override returns (string memory) {
        return
            "ipfs://QmWVerLza9fh55J7cr4bkiDE4koRp2ikLSsZiP8c3hrK8L/hoc-metadata/";
    }

    function safeMint(address to) public onlyOwner {
        uint256 tokenId = _nextTokenId++;
        _safeMint(to, tokenId);
    }
}
