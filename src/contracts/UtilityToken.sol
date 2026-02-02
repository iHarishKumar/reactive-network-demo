// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {ERC20} from "openzeppelin/token/ERC20.sol";
import {AbstractCallback} from "reactive-lib/abstract-base/AbstractCallback.sol";

/**
 * @title UtilityToken
 * @notice An ERC20 token contract that tracks transfers via Reactive Network callbacks
 * @dev Extends ERC20 and AbstractCallback to receive cross-chain callbacks from Reactive Network
 * when transfer events are detected. The contract maintains a counter of how many times
 * callbacks have been triggered.
 */
contract UtilityToken is ERC20, AbstractCallback {
    /// @notice Counter tracking the number of callbacks received from Reactive Network
    uint256 public transferCount;

    /// @notice Emitted when the transfer counter is incremented
    /// @param newCount The new value of the counter
    event CounterIncremented(uint256 newCount);
    
    /**
     * @notice Emitted when a callback is received from the Reactive Network
     * @param msgSender The address that called the callback function (Callback Proxy)
     * @param txOrigin The origin address of the transaction
     * @param reactiveSender The address of the reactive contract that triggered the callback
     * @param amount The current transfer count after incrementing
     */
    event TransferCounts(
        address indexed msgSender,
        address indexed txOrigin,
        address indexed reactiveSender,
        uint256 amount
    );

    /**
     * @notice Initializes the UtilityToken contract
     * @dev Mints 1000 tokens to the deployer and sets up callback authorization
     * @param _callback_sender The address of the Callback Proxy contract authorized to send callbacks
     */
    constructor(
        address _callback_sender
    ) payable ERC20("UtilityToken", "UT") AbstractCallback(_callback_sender) {
        _mint(msg.sender, 1000 * 10 ** decimals());
    }

    /**
     * @notice Callback function invoked by the Reactive Network when a Transfer event is detected
     * @dev Only callable by the authorized Callback Proxy contract. Increments the transfer counter
     * and emits an event with callback details.
     * @param sender The address of the reactive contract that triggered this callback
     */
    function callback(address sender) external authorizedSenderOnly {
        transferCount++;
        emit TransferCounts(msg.sender, tx.origin, sender, transferCount);
    }
}
