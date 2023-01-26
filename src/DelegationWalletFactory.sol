// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { DelegationOwner } from "./DelegationOwner.sol";
import { IDelegationWalletRegistry } from "./interfaces/IDelegationWalletRegistry.sol";

import { GnosisSafeProxyFactory, GnosisSafeProxy } from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import { GnosisSafe } from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

/**
 * @title DelegationWalletFactory
 * @author BootNode
 * @dev Factory contract for deploying and configuring a new Delegation Wallet
 * Deploys a GnosisSafe, a DelegationOwner and a DelegationGuard, sets Safe wallet threshold to 1, the DelegationOwner
 * contract as owner together with the deployer and the DelegationGuard as the Safe's guard.
 */
contract DelegationWalletFactory {
    /**
     * @notice Stores the Safe proxy factory address.
     */
    address immutable gnosisSafeProxyFactory;
    /**
     * @notice Stores the Safe implementation address.
     */
    address immutable singleton;
    /**
     * @notice Stores the Safe CompatibilityFallbackHandler address.
     */
    address immutable compatibilityFallbackHandler;
    /**
     * @notice Stores the DelegationGuard beacon contract address.
     */
    address immutable guardBeacon;
    /**
     * @notice Stores the DelegationOwner beacon contract address.
     */
    address immutable ownerBeacon;
    /**
     * @notice Stores the DelegationWalletRegistry contract address.
     */
    address immutable registry;

    // ========== Events ===========
    event WalletDeployed(
        address indexed safe,
        address indexed owner,
        address indexed delegationOwner,
        address delegationGuard,
        address sender
    );

    // ========== Custom Errors ===========

    constructor(
        address _gnosisSafeProxyFactory,
        address _singleton,
        address _compatibilityFallbackHandler,
        address _guardBeacon,
        address _ownerBeacon,
        address _registry
    ) {
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
        singleton = _singleton;
        compatibilityFallbackHandler = _compatibilityFallbackHandler;
        guardBeacon = _guardBeacon;
        ownerBeacon = _ownerBeacon;
        registry = _registry;
    }

    /**
     * @notice Deploys a new DelegationWallet with the msg.sender as the owner.
     */
    function deploy(
        address _delegationController,
        address _lockController
    ) external returns (address, address, address) {
        return deployFor(msg.sender, _delegationController, _lockController);
    }

    /**
     * @notice Deploys a new DelegationWallet for a given owner.
     * @param _owner - The owner's address.
     */
    function deployFor(
        address _owner,
        address _delegationController,
        address _lockController
    ) public returns (address, address, address) {
        address safeProxy = address(
            GnosisSafeProxyFactory(gnosisSafeProxyFactory).createProxy(singleton, new bytes(0))
        );
        address delegationOwnerProxy = address(new BeaconProxy(ownerBeacon, new bytes(0)));

        address[] memory owners = new address[](2);
        owners[0] = _owner;
        owners[1] = delegationOwnerProxy;

        // setup owners and threshold, this should be done before delegationOwner.initialize because DelegationOwners
        // has to be an owner to be able to set the guard
        GnosisSafe(payable(safeProxy)).setup(
            owners,
            1,
            address(0),
            new bytes(0),
            compatibilityFallbackHandler,
            address(0),
            0,
            payable(address(0))
        );

        DelegationOwner delegationOwner = DelegationOwner(delegationOwnerProxy);
        delegationOwner.initialize(guardBeacon, address(safeProxy), _owner, _delegationController, _lockController);
        address delegationGuard = address(delegationOwner.guard());

        IDelegationWalletRegistry(registry).setWallet(safeProxy, _owner, delegationOwnerProxy, delegationGuard);

        emit WalletDeployed(safeProxy, _owner, delegationOwnerProxy, delegationGuard, msg.sender);

        return (safeProxy, delegationOwnerProxy, delegationGuard);
    }
}
