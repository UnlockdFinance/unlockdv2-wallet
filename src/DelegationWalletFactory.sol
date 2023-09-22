// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.19;

import { console } from "forge-std/console.sol";
import { GnosisSafeProxyFactory, GnosisSafeProxy } from "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import { UpgradeableBeacon } from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { IDelegationWalletRegistry } from "./interfaces/IDelegationWalletRegistry.sol";
import { GnosisSafe } from "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import { DelegationOwner } from "./libs/owners/DelegationOwner.sol";
import { ProtocolOwner } from "./libs/owners/ProtocolOwner.sol";
import { DelegationGuard } from "./libs/guards/DelegationGuard.sol";

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
    address public immutable gnosisSafeProxyFactory;
    /**
     * @notice Stores the Safe implementation address.
     */
    address public immutable singleton;
    /**
     * @notice Stores the Safe CompatibilityFallbackHandler address.
     */
    address public immutable compatibilityFallbackHandler;
    /**
     * @notice Stores the DelegationGuard beacon contract address.
     */
    address public immutable guardBeacon;
    /**
     * @notice Stores the DelegationOwner beacon contract address.
     */
    address public immutable ownerBeacon;
    /**
     * @notice Stores the DelegationOwner beacon contract address.
     */
    address public immutable protocolOwnerBeacon;
    /**
     * @notice Stores the DelegationWalletRegistry contract address.
     */
    address public immutable registry;

    event WalletDeployed(
        address indexed safe,
        address indexed owner,
        address indexed delegationOwner,
        address delegationGuard,
        address sender
    );

    constructor(
        address _gnosisSafeProxyFactory,
        address _singleton,
        address _compatibilityFallbackHandler,
        address _guardBeacon,
        address _ownerBeacon,
        address _protocolOwnerBeacon,
        address _registry
    ) {
        gnosisSafeProxyFactory = _gnosisSafeProxyFactory;
        singleton = _singleton;
        compatibilityFallbackHandler = _compatibilityFallbackHandler;
        guardBeacon = _guardBeacon;
        ownerBeacon = _ownerBeacon;
        protocolOwnerBeacon = _protocolOwnerBeacon;
        registry = _registry;
    }

    /**
     * @notice Deploys a new DelegationWallet with the msg.sender as the owner.
     */
    function deploy(
        address _delegationController
    ) external returns (
        address, 
        address, 
        address, 
        address
    ) {
        return deployFor(
            msg.sender, 
            _delegationController
        );
    }

    function deployFor(
        address _owner, 
        address _delegationController
    ) public returns (
        address, 
        address, 
        address,
        address
    ) {
        address[] memory proxies = deployProxies(_owner);
      
        initializeContracts(
            proxies, 
            _owner, 
            _delegationController
        );
        
        setupSafe(
            proxies[0], // safeProxy
            _owner,
            proxies[1], // delegationOwnerProxy
            proxies[2] // protocolOwnerProxy
         );
      
        registerWallet(
            proxies[0], // safeProxy
            proxies[1], // delegationOwnerProxy
            proxies[2],  // delegationGuard;
            proxies[3],  // protocolOwnerProxy 
            _owner
        );  

        return (
            proxies[0], // safeProxy
            proxies[1], // delegationOwnerProxy
            proxies[2],  // delegationGuard;
            proxies[3]  // protocolOwnerProxy
          );
    }

    function deployProxies(address _owner) internal returns (address[] memory) {

        address[] memory proxies = new address[](4);
      
        proxies[0] = deploySafeProxy();
        proxies[1] = deployDelegateOwnerProxy();
        proxies[2] = deployDelegationGuard();
        proxies[3] = deployProtocolOwnerProxy();
      
        return proxies;
    }

    function initializeContracts(address[] memory proxies, address _owner, address _delegationController) internal {
        DelegationGuard guard = DelegationGuard(proxies[2]); 
      
        guard.initialize(proxies[1], proxies[3]);
      
        DelegationOwner delegationOwner = DelegationOwner(proxies[1]);
      
        delegationOwner.initialize(
            proxies[2], // guard 
            proxies[0], // safe
            _owner,  
            _delegationController,
            proxies[3] // protocolOwner
        );
      
        ProtocolOwner protocolOwner = ProtocolOwner(proxies[3]);  
      
        protocolOwner.initialize(
            proxies[2], // guard
            proxies[0], // safe
            _owner, 
            proxies[1] // delegationOwner
        );
    }
      
      
    function setupSafe(address safeProxy, address _owner, address delegationOwnerProxy, address protocolOwnerProxy) internal {

        address[] memory owners = new address[](3);
      
        owners[0] = _owner; 
        owners[1] = delegationOwnerProxy;
        owners[2] = protocolOwnerProxy;
        
        GnosisSafe(payable(safeProxy)).setup(
            owners,
            1, // threshold
            address(0),
            new bytes(0),
            compatibilityFallbackHandler,
            address(0),  
            0,
            payable(address(0))
        );
      
      }
      
      
    function registerWallet(
        address safeProxy,
        address delegationOwnerProxy,  
        address delegationGuard,
        address protocolOwnerProxy, 
        address _owner  
    ) internal {
      
        IDelegationWalletRegistry(registry).setWallet(
            safeProxy,
            _owner,
            delegationOwnerProxy, 
            delegationGuard,
            protocolOwnerProxy
        );  
    }

    function deploySafeProxy() internal returns (address) {
        return address(GnosisSafeProxyFactory(gnosisSafeProxyFactory).createProxy(singleton, new bytes(0))); 
    }
      
    function deployDelegateOwnerProxy() internal returns (address) {
        return address(new BeaconProxy(ownerBeacon, new bytes(0)));
    }
      
    function deployProtocolOwnerProxy() internal returns (address) {
        return address(new BeaconProxy(protocolOwnerBeacon, new bytes(0))); 
    }

    function deployDelegationGuard() internal returns (address) {
        return address(new BeaconProxy(guardBeacon, new bytes(0)));
    }
}
