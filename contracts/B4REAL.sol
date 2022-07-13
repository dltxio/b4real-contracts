// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract B4REAL is ERC20, AccessControl {
    using SafeERC20 for IERC20;

    address private taxAddress = 0xe3F078F80A530cCD3BbF221612dDca3B0724579D;
    address public penddingOwner;
    uint256 public taxFee;
    uint256 public taxFeeDecimals;

    bool public waiveFees = false;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event ToggleWaiveFees(bool _status);

    event SetTaxFee(uint256 _fee, uint256 _decimals);
    event ExemptFromFee(address _account);
    event IncludeInFee(address _account);
    event UpdateB4REALTaxAddress(address _address);
    event SetAdmin(address _account);
    event TransferOwnership(address _newOwner);

    mapping(address => bool) public whitelist;

    modifier onlyValidAddress(address wallet) {
        require(wallet != address(0), "The address cannot be the zero address");
        require(wallet != msg.sender, "The address cannot be the sender");
        require(wallet != taxAddress, "The address cannot be the tax");
        require(wallet != address(this), "The address cannot be the contract");
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(ADMIN_ROLE, msg.sender) || hasRole(OWNER_ROLE, msg.sender),
            "Address does not have admin permission"
        );
        _;
    }

    modifier onlyOwner() {
        require(
            hasRole(OWNER_ROLE, msg.sender),
            "Address does not have owner permission"
        );
        _;
    }

    constructor() ERC20("B4REAL", "B4RE") {
        penddingOwner = msg.sender;
        _setupRole(OWNER_ROLE, msg.sender);
        _setRoleAdmin(OWNER_ROLE, OWNER_ROLE);
        _setRoleAdmin(ADMIN_ROLE, OWNER_ROLE);
        _mint(msg.sender, 50_000_000 * 10**decimals()); // 50 million tokens

        // set the Tax fee to be 10%
        setTaxFee(10, 0);
    }

    /// @notice Sets the fee percentage for the B4REAL Tax fund
    function setTaxFee(uint256 fee, uint256 feeDecimals) public onlyAdmin {
        require(fee >= 0, "The B4REAL Tax fee must be greater than 0");
        if (feeDecimals == 0) {
            // If the feeDecimals is greater than 0 then the percent is less then 100%
            require(fee < 100, "The B4REAL Tax fee must be less than 100");
        }
        taxFee = fee;
        taxFeeDecimals = feeDecimals;
        emit SetTaxFee(fee, feeDecimals);
    }

    /// @notice Toggles the in-built transaction fee on and off for all transactions
    function toggleTransactionFees() external onlyAdmin {
        waiveFees = !waiveFees;
        emit ToggleWaiveFees(waiveFees);
    }

    /// @notice Whether a wallet has been whitelisted or not
    function whitelisted(address wallet) public view returns (bool) {
        return whitelist[wallet];
    }

    /// @notice Removes a wallet address to the whitelist
    function exemptFromFee(address wallet)
        external
        onlyAdmin
        onlyValidAddress(wallet)
    {
        whitelist[wallet] = false;
        emit ExemptFromFee(wallet);
    }

    /// @notice Adds a wallet address from the whitelist
    function includeInFee(address wallet)
        external
        onlyAdmin
        onlyValidAddress(wallet)
    {
        whitelist[wallet] = true;
        emit IncludeInFee(wallet);
    }

    /// @notice Updates the tax contract address
    function updateB4REALTaxAddress(address newAddress) external onlyAdmin {
        require(taxAddress != newAddress, "New address cannot be the same");
        taxAddress = newAddress;
        emit UpdateB4REALTaxAddress(newAddress);
    }

    /// @return Number of tokens to hold as the fee
    function calculateFee(
        uint256 _amount,
        uint256 _feePercentage,
        uint256 _feeDecimals
    ) public pure returns (uint256) {
        uint256 numerator = _amount * _feePercentage;
        // 2, because e.g. 1% = 1 * 10^-2 = 0.01
        uint256 denominator = 10**(_feeDecimals + 2);
        require(denominator > 0, "Denominator cannot be zero");
        return numerator / denominator;
    }

    function transfer(address to, uint256 amount)
        public
        override
        returns (bool)
    {
        require(amount > 0, "The amount must be greater than 0");

        uint256 tokensForTax;

        uint256 remainder = amount;

        // calculate the number of tokens the Tax should take
        if (whitelist[to] && !waiveFees) {
            tokensForTax = calculateFee(amount, taxFee, taxFeeDecimals);
            remainder -= tokensForTax;
            super.transfer(taxAddress, tokensForTax);
        }
        super.transfer(to, remainder);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        require(amount > 0, "The amount must be greater than 0");

        uint256 tokensForTax;

        uint256 remainder = amount;

        // calculate the number of tokens the Tax should take
        if (whitelist[recipient] && !waiveFees) {
            tokensForTax = calculateFee(amount, taxFee, taxFeeDecimals);
            remainder -= tokensForTax;
            // send tax
            transferTax(sender, tokensForTax);
        }

        super.transferFrom(sender, recipient, remainder);
        return true;
    }

    function transferTax(
        address sender,
        uint256 amount
    ) private {
        address recipient = taxAddress;
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");

        _balances[sender] = senderBalance - amount;

        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function initializeTransferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "The address cannot be the zero address");
        require(newOwner != penddingOwner, "The address cannot be the existing penddingOwner");
        require(newOwner != taxAddress, "The address cannot be the tax address");
        require(newOwner != address(this), "The address cannot be the contract");
        penddingOwner = newOwner;
    }

    function confirmTransferOwnership() external onlyOwner {
        grantRole(OWNER_ROLE, penddingOwner);
        revokeRole(OWNER_ROLE, msg.sender);
        emit TransferOwnership(penddingOwner);
    }
}
