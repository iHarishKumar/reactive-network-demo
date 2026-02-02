// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.26;

import {IReactive} from "reactive-lib/interfaces/IReactive.sol";
import {AbstractPausableReactive} from "reactive-lib/abstract-base/AbstractPausableReactive.sol";
import {ISystemContract} from "reactive-lib/interfaces/ISystemContract.sol";

/**
 * @title UtilityReactiveContract
 * @notice A reactive contract that monitors Transfer events from a UtilityToken contract on Sepolia
 * @dev Deployed on the Reactive Network, this contract subscribes to Transfer events from a specified
 * origin contract and triggers callbacks to the destination chain when those events are detected.
 * Extends AbstractPausableReactive for pausable subscription management.
 */
contract UtilityReactiveContract is AbstractPausableReactive {
    /// @notice Gas limit for callback execution on the destination chain
    uint64 private constant GAS_LIMIT = 1000000;
    
    /// @notice Address of the UtilityToken contract being monitored on the origin chain
    address public contract_address;
    
    /// @notice Chain ID for Ethereum Sepolia testnet
    uint256 private constant SEPOLIA_CHAIN_ID = 11155111;

    /**
     * @notice Topic hash for ERC20 Transfer event
     * @dev keccak256("Transfer(address,address,uint256)") = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef
     * Topic structure for Transfer events:
     * - topic_0: Event signature (Transfer selector)
     * - topic_1: 'from' address (indexed)
     * - topic_2: 'to' address (indexed)
     * - data: transfer amount (not indexed)
     */
    uint256 public constant TRANSFER_TOPIC_0 =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    /**
     * @notice Initializes the reactive contract and subscribes to Transfer events
     * @dev Automatically subscribes to Transfer events from the specified contract on Sepolia.
     * The subscription is skipped in VM/test mode.
     * @param _contract Address of the UtilityToken contract to monitor on Sepolia
     */
    constructor(
        address _contract
    ) payable {
        contract_address = _contract;

        if (!vm) {
            service.subscribe(
                SEPOLIA_CHAIN_ID,
                contract_address,
                TRANSFER_TOPIC_0,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE,
                REACTIVE_IGNORE
            );
        }
    }

    /**
     * @notice Processes indexed events and triggers callbacks to the destination chain
     * @dev Called by the Reactive Network VM when a subscribed event is detected.
     * Only processes Transfer events matching TRANSFER_TOPIC_0.
     * @param log The log record containing event data from the origin chain
     */
    function react(LogRecord calldata log) external vmOnly {
        if (log.topic_0 == TRANSFER_TOPIC_0) {
            bytes memory payload = abi.encodeWithSignature(
                "callback(address)",
                address(contract_address)
            );
            emit Callback(SEPOLIA_CHAIN_ID, contract_address, GAS_LIMIT, payload);
        }
    }

    /**
     * @notice Dynamically subscribes to events from a contract on a specified chain
     * @dev Allows the contract owner to add new event subscriptions at runtime.
     * Restricted to Reactive Network calls only.
     * @param chain_id The chain ID where the contract to monitor is deployed
     * @param contract_address The address of the contract to monitor
     * @param subscriber The address to filter events by (used in topic_1)
     * @param topic_0 The event signature hash to subscribe to
     */
    function subscribe(
        uint256 chain_id,
        address contract_address,
        address subscriber,
        uint256 topic_0
    ) external rnOnly onlyOwner {
        service.subscribe(
            chain_id,
            contract_address,
            topic_0,
            REACTIVE_IGNORE,
            uint256(uint160(subscriber)),
            REACTIVE_IGNORE
        );
    }

    /**
     * @notice Dynamically unsubscribes from events for a specific contract and event type
     * @dev Allows the contract owner to remove event subscriptions at runtime.
     * Restricted to Reactive Network calls only.
     * @param chain_id The chain ID of the monitored contract
     * @param contract_address The address of the monitored contract
     * @param subscriber The subscriber address used in the subscription
     * @param topic_0 The event signature hash to unsubscribe from
     */
    function unsubscribe(
        uint256 chain_id,
        address contract_address,
        address subscriber,
        uint256 topic_0
    ) external rnOnly onlyOwner {
        service.unsubscribe(
            chain_id,
            contract_address,
            topic_0,
            REACTIVE_IGNORE,
            uint256(uint160(subscriber)),
            REACTIVE_IGNORE
        );
    }

    /**
     * @notice Ideally, should return the list of subscriptions that can be paused but for this demo, we are ignoring this functionality
     * @dev Required override from AbstractPausableReactive. Used for pausing/resuming
     * @return An array of Subscription structs representing all pausable subscriptions
     */
    function getPausableSubscriptions()
        internal
        view
        override
        returns (Subscription[] memory)
    {
        Subscription[] memory result = new Subscription[](1);
        result[0] = Subscription(
            SEPOLIA_CHAIN_ID,
            contract_address,
            TRANSFER_TOPIC_0,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE,
            REACTIVE_IGNORE
        );
        return result;
    }
}
