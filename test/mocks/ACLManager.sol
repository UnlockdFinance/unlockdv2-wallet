// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IACLManager } from "../../src/interfaces/IACLManager.sol";

/**
 * @title ACLManager
 * @author Unlockd
 * @notice Access Control List Manager. Main registry of system roles and permissions.
 */

contract ACLManager is AccessControl, IACLManager {
    bytes32 public constant override UTOKEN_ADMIN = keccak256("UTOKEN_ADMIN");
    bytes32 public constant override PROTOCOL_ADMIN = keccak256("PROTOCOL_ADMIN");
    bytes32 public constant override UPDATER_ADMIN = keccak256("UPDATER_ADMIN");

    bytes32 public constant override BORROW_MANAGER = keccak256("BORROW_MANAGER");
    bytes32 public constant override PRICE_UPDATER = keccak256("PRICE_UPDATER");

    bytes32 public constant override EMERGENCY_ADMIN = keccak256("EMERGENCY_ADMIN");
    bytes32 public constant override RISK_ADMIN = keccak256("RISK_ADMIN");
    bytes32 public constant override GOVERNANCE_ADMIN = keccak256("GOVERNANCE_ADMIN");

    /**
     * @dev Constructor
     * @dev The ACL admin should be initialized at the addressesProvider beforehand
     * @param aclAdmin address of the general admin
     */
    constructor(address aclAdmin) {
        require(aclAdmin != address(0), "ADMIN CANNOT BE ZERO");
        _setupRole(DEFAULT_ADMIN_ROLE, aclAdmin);
    }

    /// @inheritdoc IACLManager
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        _setRoleAdmin(role, adminRole);
    }

    /// @inheritdoc IACLManager
    function addUTokenAdmin(address admin) external override {
        grantRole(UTOKEN_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function removeUTokenAdmin(address admin) external override {
        revokeRole(UTOKEN_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function isUTokenAdmin(address admin) external view override returns (bool) {
        return hasRole(UTOKEN_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function addProtocolAdmin(address borrower) external override {
        grantRole(PROTOCOL_ADMIN, borrower);
    }

    /// @inheritdoc IACLManager
    function removeProtocolAdmin(address borrower) external override {
        revokeRole(PROTOCOL_ADMIN, borrower);
    }

    /// @inheritdoc IACLManager
    function isProtocolAdmin(address borrower) external view override returns (bool) {
        return hasRole(PROTOCOL_ADMIN, borrower);
    }

    /// @inheritdoc IACLManager
    function addUpdaterAdmin(address updater) external override {
        grantRole(UPDATER_ADMIN, updater);
    }

    /// @inheritdoc IACLManager
    function removeUpdaterAdmin(address updater) external override {
        revokeRole(UPDATER_ADMIN, updater);
    }

    /// @inheritdoc IACLManager
    function isUpdaterAdmin(address updater) external view override returns (bool) {
        return hasRole(UPDATER_ADMIN, updater);
    }

    /// @inheritdoc IACLManager
    function addEmergencyAdmin(address admin) external override {
        grantRole(EMERGENCY_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function removeEmergencyAdmin(address admin) external override {
        revokeRole(EMERGENCY_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function isEmergencyAdmin(address admin) external view override returns (bool) {
        return hasRole(EMERGENCY_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function addRiskAdmin(address admin) external override {
        grantRole(RISK_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function removeRiskAdmin(address admin) external override {
        revokeRole(RISK_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function isRiskAdmin(address admin) external view override returns (bool) {
        return hasRole(RISK_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function addBorrowManager(address admin) external override {
        grantRole(BORROW_MANAGER, admin);
    }

    /// @inheritdoc IACLManager
    function removeBorrowManager(address admin) external override {
        revokeRole(BORROW_MANAGER, admin);
    }

    /// @inheritdoc IACLManager
    function isBorrowManager(address admin) external view override returns (bool) {
        return hasRole(BORROW_MANAGER, admin);
    }

    /// @inheritdoc IACLManager
    function addPriceUpdater(address admin) external override {
        grantRole(PRICE_UPDATER, admin);
    }

    /// @inheritdoc IACLManager
    function removePriceUpdater(address admin) external override {
        revokeRole(PRICE_UPDATER, admin);
    }

    /// @inheritdoc IACLManager
    function isPriceUpdater(address admin) external view override returns (bool) {
        return hasRole(PRICE_UPDATER, admin);
    }

    /// @inheritdoc IACLManager
    function addGovernanceAdmin(address admin) external override {
        grantRole(GOVERNANCE_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function removeGovernanceAdmin(address admin) external override {
        revokeRole(GOVERNANCE_ADMIN, admin);
    }

    /// @inheritdoc IACLManager
    function isGovernanceAdmin(address admin) external view override returns (bool) {
        return hasRole(GOVERNANCE_ADMIN, admin);
    }
}
