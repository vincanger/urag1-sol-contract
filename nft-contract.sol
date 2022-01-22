pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "hardhat/console.sol";
import { Base64 } from "./libraries/Base64.sol";

contract NFTcontract is ERC721URIStorage {
  // OpenZeppelin counter
  using Counters for Counters.Counter;
  // using ECDSA for bytes32;
  Counters.Counter private _tokenIds;

  string baseSvg = '<svg id="etyTFDswJi61" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" viewBox="0 0 500 500" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" width="500" height="500" style="background-color:rgb(255,255,255)">';

  // We need to pass the name of our NFTs token and it's symbol.
  constructor() ERC721 ("UrAGood1", "URAG1") {
    console.log("You Are a Good One");
  }

  event NewNFTMinted(address sender, uint256 tokenId);

  function makeNFT(string memory _metadata, uint8 v, bytes32 r, bytes32 s) public {
    require(verifyString(_metadata, v, r, s), "NOT SIGNED CORRECTLY!");
    
    uint256 newItemId = _tokenIds.current();
    string memory numberStr = Strings.toString(_tokenIds.current());
    string memory finalSvg = string(abi.encodePacked(baseSvg, _metadata, '<tspan> #', numberStr, '</tspan></text></svg>'));
    require(utfStringLength(finalSvg), "invalid NFT");
    
    string memory json = Base64.encode(
        bytes(
            string(
                abi.encodePacked(
                    '{"name": "URAG1 - #', numberStr, '", "description": "URAG1 Series by HOT TOWN", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(finalSvg)),'"}'
                )
            )
        )
    );
    console.log(finalSvg);

    string memory finalTokenUri = string(
        // abi.encodePacked("data:application/json;base64,", '"', json, '"')
        abi.encodePacked('data:application/json;base64,', json)
    );

    console.log("::::: \n", finalTokenUri);
    console.log("::::: \n");

     // Actually mint the NFT to the sender using msg.sender.
    _safeMint(msg.sender, newItemId);

    // Set the NFTs data.
    _setTokenURI(newItemId, finalTokenUri);
    console.log("An NFT w/ ID %s has been minted to %s", newItemId, msg.sender);
    console.log("Here is the byte64 encoded data: %s", finalTokenUri);

    // Increment the counter for when the next NFT is minted.
    _tokenIds.increment();
    emit NewNFTMinted(msg.sender, newItemId);
  }

  // Returns the address that signed a given string message
  function verifyString(string memory message, uint8 v, bytes32 r, bytes32 s) public pure returns (bool) {
    // The message header; we will fill in the length next
    string memory header = "\x19Ethereum Signed Message:\n000000";
    uint256 lengthOffset;
    uint256 length;
    assembly {
      // The first word of a string is its length
      length := mload(message)
      // The beginning of the base-10 message length in the prefix
      lengthOffset := add(header, 57)
    }
    // Maximum length we support
    require(length <= 999999);
    // The length of the message's length in base-10
    uint256 lengthLength = 0;
    // The divisor to get the next left-most message length digit
    uint256 divisor = 100000;
    // Move one digit of the message length to the right at a time
    while (divisor != 0) {
      // The place value at the divisor
      uint256 digit = length / divisor;
      if (digit == 0) {
        // Skip leading zeros
        if (lengthLength == 0) {
          divisor /= 10;
          continue;
        }
      }
      // Found a non-zero digit or non-leading zero digit
      lengthLength++;
      // Remove this digit from the message length's current value
      length -= digit * divisor;
      // Shift our base-10 divisor over
      divisor /= 10;
      
      // Convert the digit to its ASCII representation (man ascii)
      digit += 0x30;
      // Move to the next character and write the digit
      lengthOffset++;
      assembly {
        mstore8(lengthOffset, digit)
      }
    }
    // The null string requires exactly 1 zero (unskip 1 leading 0)
    if (lengthLength == 0) {
      lengthLength = 1 + 0x19 + 1;
    } else {
      lengthLength += 1 + 0x19;
    }
    // Truncate the tailing zeros from the header
    assembly {
      mstore(header, lengthLength)
    }
    // Perform the elliptic curve recover operation
    bytes32 check = keccak256(abi.encodePacked(header, message));
    return ecrecover(check, v, r, s) == address(0x2bF81110e1e106Fd55AcA832CFAefA13571f7348);
  }

  function utfStringLength(string memory str) internal pure returns (bool) {
    bytes memory string_rep = bytes(str);

    return string_rep.length != 0;
  }
}
