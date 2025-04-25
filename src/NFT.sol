// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "./interface/IERC721.sol";
import {IERC165} from "./interface/IERC165.sol";
import {IERC721TokenReceiver} from "./interface/IERC721TokenReceiver.sol";
import {IERC721Metadata} from "./interface/IERC721Metadata.sol";

/**
 * @title NFT
 * @dev Implementation ERC721 Non-Fungible Token Standard
 * @custom:security-contact https://github.com/All-Khwarizmi/
 * Design Choices:
 * 1. Ownership Model:
 *    - Single owner per NFT
 *    - Multiple operators possible per owner
 *    - One approved address per NFT
 *
 * 2. Storage Design Options Considered:
 *    - Current: Separate mappings for flexibility
 *
 * 3. Security Requirements:
 *    - Zero address validations
 *    - Operation authorization checks
 *    - Token validity verification
 */
contract NFT is IERC721, IERC721Metadata, IERC165 {
    using Strings for uint256;

    // =========================================================================
    // Errors
    // =========================================================================
    error InvalidToken(uint256 tokenId);
    error ZeroAddress();
    error NotAuthorized(address account);
    error NotExpectedValue();
    error NotEnoughSupply();
    error NotOnReceivedImplementer();
    error NotRevealed();
    error NotEnoughEth();
    error GracePeriodNotOver();
    error TransferFailed();

    // =========================================================================
    // Events
    // =========================================================================
    event Mint(address indexed owner, uint256 tokenId);
    event Reveal(string baseURI);
    event Withdraw(uint256 amount);
    event InitiateWithdrawalPeriod();
    event WithdrawCollectedEth();
    event SetPendingOwner(address pendingOwner);
    event AcceptOwnership();

    // =========================================================================
    // Constants
    // =========================================================================
    /// @notice Minting fee in ETH
    uint256 public constant FEE = 0.01 ether;
    uint256 public immutable MAX_SUPPLY;

    /// @notice Default time before revealing token metadata
    uint256 private constant DEFAULT_REVEAL_TIME = 1 days;

    /// @notice Default grace period for withdrawals
    uint256 private constant GRACE_PERIOD = 1 weeks;

    // =========================================================================
    // State Variables
    // =========================================================================

    // Collection metadata
    string private _name;
    string private _symbol;
    string private _baseURI;
    bytes32 private _baseURIHash;

    /// @notice Time after which the collection will be revealed
    uint256 private revealTime;

    uint256 public totalSupply;

    // Contract ownership
    address private _owner;
    address private pendingOwner;

    // Financial state
    /// @notice Total ETH collected from sales
    uint256 private weiCollected;

    /// @notice Timestamp when the grace period for withdrawals ends
    uint256 private endGracePeriod;

    /// @notice Maps user addresses to their refundable ETH balances
    mapping(address => uint256) public ethBalances;

    // Token ownership & approvals
    /// @notice Maps owner addresses to their token balance
    mapping(address => uint256) public balances;

    mapping(uint256 => address) private idToOwner;
    mapping(address => mapping(address => bool)) public delegatedOperators;
    mapping(uint256 => address) private approvedAddress;

    // =========================================================================
    // Modifiers
    // =========================================================================
    /// @notice Ensures the provided address is not the zero address
    /// @param adr The address to check
    modifier zeroAddressCheck(address adr) {
        if (adr == address(0)) {
            revert ZeroAddress();
        }
        _;
    }

    /// @notice Ensures the collection has been revealed
    modifier isRevealed() {
        if (!isCollectionRevealed()) {
            revert NotRevealed();
        }
        _;
    }

    /// @notice Ensures the caller is the contract owner
    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert NotAuthorized(msg.sender);
        }
        _;
    }

    // @notice Ensures token exists
    modifier tokenExists(uint256 tokenId) {
        if (idToOwner[tokenId] == address(0)) {
            revert InvalidToken(tokenId);
        }
        _;
    }

    // =========================================================================
    // Constructor
    // =========================================================================
    /// @notice Initializes the NFT contract
    /// @param name_ The name of the NFT collection
    /// @param symbol_ The symbol of the NFT collection
    /// @param _revealTime Time after which the collection will be revealed (0 for default)
    /// @param hashedURI Hash of the baseURI for verification when revealed
    constructor(string memory name_, string memory symbol_, uint256 _revealTime, bytes32 hashedURI, uint256 maxSupply) {
        _name = name_;
        _symbol = symbol_;
        revealTime = _revealTime == 0 ? DEFAULT_REVEAL_TIME : _revealTime;
        _baseURIHash = hashedURI;
        _owner = msg.sender;
        MAX_SUPPLY = maxSupply;
    }

    // =========================================================================
    // Receive
    // =========================================================================
    /// @notice Handles direct ETH transfers to mint tokens
    /// @dev Calculates how many tokens can be minted with the sent ETH
    /// and refunds any excess (using pull pattern)
    receive() external payable {
        uint256 tokens = msg.value / FEE;
        uint256 remainingWei = msg.value % FEE;

        weiCollected += msg.value - remainingWei;
        ethBalances[msg.sender] += remainingWei;

        _mint(msg.sender, tokens);
    }

    // =========================================================================
    // External Functions
    // =========================================================================
    /// @notice Allows users to buy a specific amount of tokens
    /// @param amount The number of tokens to purchase
    /// @dev Reverts if the amount is not exactly equal to FEE (per token)
    function buyTokens(uint256 amount) external payable {
        if (msg.value != FEE * amount) {
            revert NotExpectedValue();
        }
        weiCollected += msg.value;
        _mint(msg.sender, amount);
    }

    /// @notice Allows users to withdraw their excess ETH
    /// @param amount The amount of ETH to withdraw
    function withdrawEth(uint256 amount) external {
        if (amount > ethBalances[msg.sender]) {
            revert NotEnoughEth();
        }
        ethBalances[msg.sender] -= amount;
        emit Withdraw(amount);
        payable(msg.sender).transfer(amount);
    }

    /// @notice Initiates the withdrawal grace period
    /// @dev Only the contract owner can call this function
    function initiateWithdrawalPeriod() external onlyOwner {
        endGracePeriod = block.timestamp + GRACE_PERIOD;
        emit InitiateWithdrawalPeriod();
    }

    /// @notice Allows withdrawal of collected ETH after grace period
    /// @dev Transfers all collected ETH to the caller
    function withdrawCollectedEth() external onlyOwner {
        if (block.timestamp < endGracePeriod || endGracePeriod == 0) {
            revert GracePeriodNotOver();
        }
        uint256 amountToWithdraw = weiCollected;
        weiCollected = 0;
        endGracePeriod = 0;
        emit WithdrawCollectedEth();

        (bool success,) = payable(_owner).call{value: amountToWithdraw}("");
        if (!success) {
            revert TransferFailed();
        }
    }

    /// @notice Reveals the token URI if it matches the stored hash
    /// @param value The baseURI to set
    /// @dev Only the contract owner can call this function after revealTime
    function revealTokenURI(string memory value) external onlyOwner {
        if (block.timestamp < revealTime) {
            revert NotRevealed();
        }
        if (keccak256(bytes(value)) != _baseURIHash) {
            revert NotExpectedValue();
        }

        _baseURI = value;
        emit Reveal(value);
    }

    /// @notice Sets a pending owner for ownership transfer
    /// @param newOwner The address of the new pending owner
    /// @dev Only the current owner can call this function
    function setPendingOwner(address newOwner) external onlyOwner zeroAddressCheck(newOwner) {
        pendingOwner = newOwner;
        emit SetPendingOwner(newOwner);
    }

    /// @notice Completes the ownership transfer process
    /// @dev Only the pending owner can call this function
    function acceptOwnership() external {
        if (msg.sender != pendingOwner) {
            revert NotAuthorized(msg.sender);
        }
        _owner = pendingOwner;
        pendingOwner = address(0);
        emit AcceptOwnership();
    }

    /// @notice Approves an address to transfer a specific NFT
    /// @param approved Address to be approved
    /// @param tokenId ID of NFT to approve for
    /// @dev Only the owner or an approved operator can call this function
    function approve(address approved, uint256 tokenId) external payable zeroAddressCheck(approved) tokenExists(tokenId) {
        address nftOwner = idToOwner[tokenId];
        bool isOwner = nftOwner == msg.sender;
        bool isAllowedOperator = delegatedOperators[nftOwner][msg.sender];
        if (!isOwner && !isAllowedOperator) {
            revert NotAuthorized(msg.sender);
        }

        approvedAddress[tokenId] = approved;
        emit Approval(nftOwner, approved, tokenId);
    }

    /// @notice Approves an operator for all NFTs of the sender
    /// @dev Cannot approve zero address as operator
    /// @param operator Address to approve
    /// @param approved True to approve, false to revoke
    function setApprovalForAll(address operator, bool approved) external zeroAddressCheck(operator) {
        delegatedOperators[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /// @notice Transfers NFT between addresses
    /// @dev Updates balances and clears approval
    /// @param from Address sending the NFT
    /// @param to Address receiving the NFT
    /// @param tokenId ID of the NFT being transferred
    function transferFrom(address from, address to, uint256 tokenId) public payable zeroAddressCheck(to) {
        address currentNFTOwner = idToOwner[tokenId];
        if (idToOwner[tokenId] == address(0)) {
            revert InvalidToken(tokenId);
        }
        if (from != currentNFTOwner) revert NotAuthorized(from);
        if (
            (
                msg.sender != currentNFTOwner && msg.sender != approvedAddress[tokenId]
                    && !delegatedOperators[currentNFTOwner][msg.sender]
            )
        ) {
            revert NotAuthorized(msg.sender);
        }
        unchecked {
            balances[from]--;
        }
        balances[to]++;

        idToOwner[tokenId] = to;
        delete approvedAddress[tokenId];

        emit Transfer(from, to, tokenId);
    }

    /// @notice Safely transfers NFT between addresses
    /// @param _from Address sending the NFT
    /// @param _to Address receiving the NFT
    /// @param _tokenId ID of the NFT being transferred
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable override {
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    // =========================================================================
    // Public Functions
    // =========================================================================
    /// @notice Safely transfers NFT between addresses with additional data
    /// @param _from Address sending the NFT
    /// @param _to Address receiving the NFT
    /// @param _tokenId ID of the NFT being transferred
    /// @param data Additional data to send to receiver if it's a contract
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory data)
        public
        payable
        override
    {
        transferFrom(_from, _to, _tokenId);

        if (isContract(_to)) {
            (bool success, bytes memory returnData) = _to.call(
                abi.encodeWithSelector(IERC721TokenReceiver.onERC721Received.selector, _from, _to, _tokenId, data)
            );
            if (!success || bytes4(returnData) != bytes4(keccak256("onERC721Received(address,address,uint256,bytes)")))
            {
                revert NotOnReceivedImplementer();
            }
        }
    }

    // =========================================================================
    // Internal Functions
    // =========================================================================
    /// @notice Mints NFTs to the specified address
    /// @param to Address to mint the tokens to
    /// @param amount Number of tokens to mint
    /// @dev Reverts if minting would exceed maximum supply
    function _mint(address to, uint256 amount) internal {
        if (totalSupply >= MAX_SUPPLY || totalSupply + amount > MAX_SUPPLY) {
            revert NotEnoughSupply();
        }
        uint256 finalTotalSupply = totalSupply + amount;
        balances[to] += amount;
        for (uint256 i = totalSupply; i < finalTotalSupply; i++) {
            uint256 tokenId = i;
            idToOwner[tokenId] = to;
            emit Transfer(address(0), to, tokenId);
        }
        totalSupply = finalTotalSupply;
    }

    /// @notice Checks if an address is a contract
    /// @param account Address to check
    /// @return True if the address is a contract, false otherwise
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    // =========================================================================
    // View & Pure Functions
    // =========================================================================
    /// @notice Gets the name of the token collection
    /// @return The name of the token collection
    function name() external view override returns (string memory) {
        return _name;
    }

    /// @notice Gets the symbol of the token collection
    /// @return The symbol of the token collection
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /// @notice Gets the current owner of the contract
    /// @return The address of the current owner
    function owner() external view returns (address) {
        return _owner;
    }

    /// @notice Gets the base URI for token metadata
    /// @return The base URI string
    function baseURI() external view returns (string memory) {
        return _baseURI;
    }

    /// @notice Gets the URI for a specific token
    /// @param _tokenId The ID of the token
    /// @return The complete URI for the token
    function tokenURI(uint256 _tokenId)
        external
        view
        override
        isRevealed
        tokenExists(_tokenId)
        returns (string memory)
    {
        return string(string.concat(_baseURI, _tokenId.toString(), ".json"));
    }

    /// @notice Checks if the contract supports a specific interface
    /// @param interfaceID The interface identifier
    /// @return True if the interface is supported, false otherwise
    function supportsInterface(bytes4 interfaceID) external pure override returns (bool) {
        return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC165).interfaceId;
    }

    /// @notice Checks if the collection has been revealed
    /// @return True if the collection is revealed, false otherwise
    function isCollectionRevealed() public view returns (bool) {
        return block.timestamp >= revealTime && _baseURIHash == keccak256(bytes(_baseURI));
    }

    /// @notice Gets the owner of a specific NFT
    /// @param tokenId The ID of the token
    /// @return The address of the token owner
    function ownerOf(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return idToOwner[tokenId];
    }

    /// @notice Gets the number of NFTs owned by an address
    /// @param account Address to query
    /// @return The number of NFTs owned by the address
    function balanceOf(address account) external view zeroAddressCheck(account) returns (uint256) {
        return balances[account];
    }

    /// @notice Gets the approved address for a specific NFT
    /// @param tokenId The ID of the token
    /// @return The address approved for the token
    function getApproved(uint256 tokenId) external view tokenExists(tokenId) returns (address) {
        return approvedAddress[tokenId];
    }

    /// @notice Checks if an address is an approved operator for another address
    /// @param account The address that owns the NFTs
    /// @param operator The address to check for approval
    /// @return True if the operator is approved, false otherwise
    function isApprovedForAll(address account, address operator) external view zeroAddressCheck(account) zeroAddressCheck(operator) returns (bool) {
        return delegatedOperators[account][operator];
    }
}
