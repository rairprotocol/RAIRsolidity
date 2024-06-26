// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.25;

import {ERC721Storage} from "../AppStorage.sol";
import {ERC721AccessControlRoles} from "../AccessControlRoles.sol";
import {AccessControlEnumerable} from "../../../common/DiamondStorage/AccessControlEnumerable.sol";

/// @title  RAIR Product facet contract
/// @notice Facets for Product management
contract RAIRProductFacet is AccessControlEnumerable, ERC721AccessControlRoles {
    /// @param  collectionIndex 	Index for the collection
	/// @param  collectionName 		Name for the collection
	/// @param  startingToken 		First token in the collection (include)
	/// @param  collectionLength 	Number of tokens in the collection
	event CreatedCollection(uint indexed collectionIndex, string collectionName, uint startingToken, uint collectionLength);

	/// @notice Verifies that the product exists
	/// @param	collectionId	Collection to verify
	modifier collectionExists(uint collectionId) {
		require(ERC721Storage.layout().products.length > collectionId, "RAIR ERC721: Collection does not exist");
		_;
	}

	/// @notice Verifies that the range exists
	/// @param	rangeID	Range to verify
	modifier rangeExists(uint rangeID) {
		require(ERC721Storage.layout().ranges.length > rangeID, "RAIR ERC721: Range does not exist");
		_;
	}

	/// @notice Verifies that the token exists
	/// @param	tokenIndex	Range to verify
	modifier tokenExists(uint tokenIndex) {
		require(
			ERC721Storage.layout()._owners[tokenIndex] != address(0),
			"RAIR ERC721: Query for nonexistent token"
		);
		_;
	}

	/// @notice Wrapper for the validator, searching for the entire product
	/// @dev 	This function require that the product exist
	/// @param	find			Address to search
	/// @param	productIndex	Collection to verify
	/// @return bool 			For the existence or not, of the token in the product 
	function ownsTokenInProduct(address find, uint productIndex) public view collectionExists(productIndex) returns (bool) {
		ERC721Storage.product storage selectedProduct = ERC721Storage.layout().products[productIndex];
		return _ownsTokenInsideRange(find, selectedProduct.startingToken, selectedProduct.endingToken);
	}

	/// @notice Wrapper for the validator, searching for the entire range
	/// @dev 	This function require that the range exist 
	/// @param	find		Address to search
	/// @param	rangeIndex	Range to verify
	/// @return bool 		For the existence or not, of the token in the range 
	function ownsTokenInRange(address find, uint rangeIndex) public view rangeExists(rangeIndex) returns (bool) {
		ERC721Storage.Layout storage store = ERC721Storage.layout();
		ERC721Storage.range storage selectedRange = store.ranges[rangeIndex];
		uint startOfProduct = store.products[store.rangeToProduct[rangeIndex]].startingToken;
		return _ownsTokenInsideRange(find, startOfProduct + selectedRange.rangeStart, startOfProduct + selectedRange.rangeEnd);
	}

	/// @notice Validates that an address owns at least one token inside a specified range
	/// @dev Loops through the range, don't use on non-view functions
	/// @param	find	Address to validate
	/// @param	from	Range start
	/// @param	to		Range end
	/// @return bool 	For the existence or not, of the token inside the range 
	function _ownsTokenInsideRange(address find, uint from, uint to) internal view returns (bool) {
		for (uint i = from; i < to; i++) {
			if (ERC721Storage.layout()._owners[i] == find) {
				return true;
			}
		}
		return false;
	}

	/// @notice This function allow us to see the position of creation of a token
	/// @dev 	This function require that the collection exist
	/// @param 	productIndex_ Contains the index of the collection where is the token
	/// @param 	tokenIndex_   Contains the index of the token inside the collection
	/// @return uint		  With the value of the token in that indexed position 
	function tokenByProduct(uint productIndex_, uint tokenIndex_) public view collectionExists(productIndex_) returns (uint) {
		return ERC721Storage.layout().tokensByProduct[productIndex_][tokenIndex_];
	}

	/// @notice This function will search in a collection for a especific token and return its value
	/// @dev 	This function require that the collection exist\
	/// @param 	productIndex_ Contains the index of the collection where is the token
	/// @param 	tokenIndex_   Contains the index of the token inside the collection
	/// @return uint		  With the value of the token in that indexed position 
	function productToToken(uint productIndex_, uint tokenIndex_) public view collectionExists(productIndex_) returns(uint) {
		return ERC721Storage.layout().products[productIndex_].startingToken + tokenIndex_;
	}

	/// @notice This function allow us to know the index of the collection that contains the token
	/// @dev 	This function require that the token exist
	/// @param  tokenIndex_  Contains the index of the token inside the collection
	/// @return uint 		 Return the ID of the collection 
	function tokenToProductIndex(uint tokenIndex_) public view tokenExists(tokenIndex_) returns (uint) {
		ERC721Storage.Layout storage store = ERC721Storage.layout();
		return tokenIndex_ - store.products[store.tokenToProduct[tokenIndex_]].startingToken;
	}

	/// @notice This function allow us to locaste the collection & range of a token 
	/// @dev 	This function require that the token exist
	/// @param 	tokenIndex_   Contains the index of the token which info we want to know 
	/// @return productIndex  With the corresponding collection ID for the token
	/// @return rangeIndex	  With the corresponding range of the collection 
	function tokenToProduct(uint tokenIndex_) public view tokenExists(tokenIndex_) returns (uint productIndex, uint rangeIndex) {
		ERC721Storage.Layout storage store = ERC721Storage.layout();
		productIndex = store.tokenToProduct[tokenIndex_];
		rangeIndex = store.tokenToRange[tokenIndex_];
	}

	/// @notice	Returns the number of products on the contract
	/// @dev	Use with get product to list all of the products
	/// @return uint With the total of products
	function getProductCount() external view returns(uint) {
		return ERC721Storage.layout().products.length;
	}

	/// @notice This function allow us to check the information of a product
	/// @dev 	This function require that the collection exist
	/// @param productIndex_ Contains the id of the product that we want to verify
	/// @return product which contain the information of the product
	function getProductInfo(uint productIndex_)
		external
		view
	collectionExists(productIndex_) returns (ERC721Storage.product memory) {
		return ERC721Storage.layout().products[productIndex_];
	}

	/// @notice This functions allow us to check is a token is owned by an account
	/// @param owner Contains address of the acount that we want to verify
	/// @param index Contains the position in the owned tokens list
	/// @return uint with the token that is owned by the account in that position 
	function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
		require(index < RAIRProductFacet.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
		return ERC721Storage.layout()._ownedTokens[owner][index];
	}

	/// @notice this funtions allow us to know the balance of an account
	/// @param owner Contains the address which balance we want to verify
	/// @return uint256 with the current balance of the account
	function balanceOf(address owner) public view returns (uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");
		return ERC721Storage.layout()._balances[owner];
	}

	/// @notice 		Check if the NFT has an owner
	/// @param tokenId 	NFT id to check
	/// @return bool 	to indicate if the token exist or not
	function _exists(uint256 tokenId) internal view returns (bool) {
        return ERC721Storage.layout()._owners[tokenId] != address(0);
    }
	
	/// @notice	Loops through a range of tokens inside a collection and returns the first token without an owner
	/// @dev	Uses a loop, do not call this from a non-view function!
	/// @dev 	This functions require that the collection exist to properly work 
	/// @param	collectionId	Index of the collection that we want to loop
	/// @param	startingIndex	Index of the starting token of the product
	/// @param	endingIndex		Index of the last token of the product 
	/// @return nextIndex		With the next starting point available for new products
	function getNextSequentialIndex(uint collectionId, uint startingIndex, uint endingIndex) public view collectionExists(collectionId) returns(uint nextIndex) {
		ERC721Storage.product memory currentProduct = ERC721Storage.layout().products[collectionId];
		for (uint i = currentProduct.startingToken + startingIndex; i <= currentProduct.startingToken + endingIndex; i++) {
			if (!_exists(i)) {
				return i - currentProduct.startingToken;
			}
		}
		require(false, "RAIR ERC721: There are no available tokens in this range.");
	}

	/// @notice	Loops over the user's tokens looking for one that belongs to a product and a specific range
	/// @dev	Loops are expensive in solidity, so don't use this in a function that requires gas
	/// @param	userAddress			Address that will be uses to see the belonging tokens of a product and a range
	/// @param	productIndex		Index of the collection to search
	/// @param	startingToken		Starting token to search
	/// @param	endingToken			Last token to search 
	/// @return bool 				Which respond if the tokens belongs or not to a product and a range
	function hasTokenInProduct(
				address userAddress,
				uint productIndex,
				uint startingToken,
				uint endingToken) public view returns (bool) {
		ERC721Storage.Layout storage store = ERC721Storage.layout();
		ERC721Storage.product memory aux = store.products[productIndex];
		if (aux.endingToken != 0) {
			for (uint i = 0; i < balanceOf(userAddress); i++) {
				uint token = tokenOfOwnerByIndex(userAddress, i);
				if (store.tokenToProduct[token] == productIndex &&
						token >= aux.startingToken + startingToken &&
						token <= aux.startingToken + endingToken) {
					return true;
				}
			}
		}
		return false;
	}

	/// @notice	Returns the number of tokens inside a product
	/// @param	productIndex 	Product index to verify
	/// @return length  	 	Number of tokens already minted
	function mintedTokensInProduct(uint productIndex) public view returns (uint length) {
		length = ERC721Storage.layout().tokensByProduct[productIndex].length;
	}
	
	/// @notice	Creates a new product
	/// @dev 	This function is only available to an account with a `CREATOR` role
	/// @param	_productName 	Name of the product to create
	/// @param	_copies			Amount of tokens inside the product
	function createProduct(string memory _productName, uint _copies) public onlyRole(CREATOR) {
		ERC721Storage.Layout storage store = ERC721Storage.layout();
		uint lastToken = store.products.length == 0 ? 0 : store.products[store.products.length - 1].endingToken + 1;
		
		ERC721Storage.product storage newProduct = store.products.push();

		newProduct.startingToken = lastToken;
		newProduct.endingToken = newProduct.startingToken + _copies - 1;
		newProduct.name = string(_productName);
		newProduct.mintableTokens = _copies;
		
		emit CreatedCollection(store.products.length - 1, _productName, lastToken, _copies);
	}
}