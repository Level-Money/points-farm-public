// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

/// @title LevelStaking Pool Interface
/// @notice An interface containing externally accessible functions of the LevelStakingPool contract
/// @dev The automatically generated public view functions for the state variables and mappings are not included in the interface
interface ILevelStakingPool {
    /*//////////////////////////////////////////////////////////////
                            Errors
    //////////////////////////////////////////////////////////////*/

    error SignerCannotBeZeroAddress(); //Thrown when proposed signer is the zero address
    error SignerAlreadySetToAddress(); //Thrown when proposed signer is already set
    error SignatureInvalid(); // Thrown when the migration signature is invalid
    error SignatureExpired(); // Thrown when the migration signature has expired
    error TokenCannotBeZeroAddress(); // Thrown when the specified token is the zero address
    error WETHCannotBeZeroAddress(); // Thrown when the specified token is the zero address
    error TokenAlreadyConfiguredWithState(); //Thrown if the token as already been enabled or disabled
    error DepositAmountCannotBeZero(); // Thrown if staker attempts to call deposit() with zero amount
    error WithdrawAmountCannotBeZero(); //Thrown if staker attempts to call withdraw() with zero amount
    error TokenNotAllowedForStaking(); // Thrown if staker attempts to stake unsupported token (or token disabled for staking)
    error StakingLimitExceeded();
    error UserDoesNotHaveStake(); //Thrown if the staker is attempting to migrate with no stake
    error MigratorCannotBeZeroAddress(); //Thrown if the provided migrator is the zero address
    error MigratorAlreadyAllowedOrBlocked(); //Thrown if attempting to block a migrator which has already been blocked or attempting to allow a migrator which is already allowed
    error MigratorBlocked(); //Thrown if the provided migrator contract has been blacklisted.
    error CannotDepositForZeroAddress(); //Thrown if caller tries to deposit on behalf of the zero address
    error CannotRenounceOwnership(); //Thrown if the renounceOwnership() function is called
    error DuplicateToken(); //Thrown when there is a duplicate in the provided token address array
    error TokenArrayCannotBeEmpty(); //Thrown when the provided token address array is empty

    /*//////////////////////////////////////////////////////////////
                            Staker Events
    //////////////////////////////////////////////////////////////*/

    ///@notice Emitted when a staker deposits/stakes a supported token into the LevelStaking Pool
    ///@param eventId The unique event Id associated with the Deposit event
    ///@param depositor The address of the depositer/staker transfering funds to the LevelStaking Pool
    ///@param token The address of the token deposited/staked into the pool
    ///@param amount The amount of token deposited/staked into the pool
    event Deposit(
        uint256 indexed eventId,
        address indexed depositor,
        address indexed token,
        uint256 amount
    );

    ///@notice Emitted when a staker withdraws a previously staked tokens from the LevelStaking Pool
    ///@param eventId The unique event Id associated with the Withdraw event
    ///@param withdrawer The address of the staker withdrawing funds from the LevelStaking Pool
    ///@param token The address of the token being withdrawn from the pool
    ///@param amount The amount of tokens withdrawn the pool
    event Withdraw(
        uint256 indexed eventId,
        address indexed withdrawer,
        address indexed token,
        uint256 amount
    );

    ///@notice Emitted when a staker migrates their tokens from the LevelStakingPool to Level.
    ///@param eventId The unique event Id associated with the Migrate event
    ///@param user The address of the staker migrating funds to Level
    ///@param tokens The addresses of the tokens being being migrated from the LevelStakingPool to Level
    ///@param destination The address which the tokens will be transferred to on Level
    ///@param migrator The address of the migrator contract which initially receives the migrated tokens
    ///@param amounts The amounts of each token migrated to Level
    event Migrate(
        uint256 indexed eventId,
        address indexed user,
        address[] tokens,
        address destination,
        address migrator,
        uint256[] amounts
    );

    /*//////////////////////////////////////////////////////////////
                            Admin Events
    //////////////////////////////////////////////////////////////*/

    ///@notice Emitted when the required signer for the migration signature is changed
    ///@param newSigner The address of the new signer which must sign the migration signature
    event SignerChanged(address newSigner);

    ///@notice Emitted when a token has been enabled or disabled for staking
    ///@param token The address of the token which has been enabled/disabled for staking
    ///@param amount amount of tokens stakeable
    event TokenStakabilityChanged(address token, uint256 amount);

    ///@notice Emitted when a migrator has been added or removed from the blocklist
    ///@param migrator The address of the migrator which has been added or removed from the blocklist
    ///@param blocked Is true if the migrator was added to the blocklist, and false if it was removed from the blocklist
    event BlocklistChanged(address migrator, bool blocked);

    /*//////////////////////////////////////////////////////////////
                            Staker Functions
    //////////////////////////////////////////////////////////////*/

    ///@notice Stake a specified amount of a particular supported token into the LevelStaking Pool
    ///@param _token The token to deposit/stake in the LevelStaking Pool
    ///@param _for The user to deposit/stake on behalf of
    ///@param _amount The amount of token to deposit/stake into the LevelStaking Pool
    function depositFor(address _token, address _for, uint256 _amount) external;

    ///@notice Stake a specified amount of ether into the LevelStaking Pool
    ///@param _for The user to deposit/stake on behalf of
    ///@dev the amount deposited is specified by msg.value
    function depositETHFor(address _for) external payable;

    ///@notice Withdraw a specified amount of a particular supported token previously staked into the LevelStaking Pool
    ///@param _token The token to withdraw from the LevelStaking Pool
    ///@param _amount The amount of token to withdraw from the LevelStaking Pool
    function withdraw(address _token, uint256 _amount) external;

    ///@notice Migrate the staked tokens for the caller from the LevelStaking Pool to Level
    ///@dev called by the staker
    ///@param _tokens The tokens to migrate to Level from the LevelStaking Pool
    ///@param _migratorContract The migrator contract which will initially receive the migrated tokens before moving them to Level
    ///@param _destination The address which will receive the migrated tokens on Level
    ///@param _signatureExpiry The timestamp at which the signature in _authorizationSignatureFromLevel expires
    ///@param _authorizationSignatureFromLevel The authorization signature which is signed by the level signer and indicates the correct migrator contract
    function migrate(
        address[] calldata _tokens,
        address _migratorContract,
        address _destination,
        uint256 _signatureExpiry,
        bytes memory _authorizationSignatureFromLevel
    ) external;

    ///@notice Migrate the staked tokens for the caller from the LevelStaking Pool to Level
    ///@param _user The staker to migrate tokens for
    ///@param _tokens The tokens to migrate to Level from the LevelStaking Pool
    ///@param _migratorContract The migrator contract which will initially receive the migrated tokens before moving them to Level
    ///@param _destination The address which will receive the migrated tokens on Level
    ///@param _signatureExpiry The timestamp at which the signature in _authorizationSignatureFromLevel expires
    ///@param _stakerSignature The signature from the staker authorizing the migration of their tokens
    function migrateWithSig(
        address _user,
        address[] calldata _tokens,
        address _migratorContract,
        address _destination,
        uint256 _signatureExpiry,
        bytes memory _stakerSignature
    ) external;

    /*//////////////////////////////////////////////////////////////
                            Admin Functions
    //////////////////////////////////////////////////////////////*/

    ///@notice Set/Change the required signer for the migration signature (_authorizationSignatureFromLevel in the migrate() function)
    ///@param _signer The address of the new signer for the migration signature
    ///@dev Only callable by the owner
    function setLevelSigner(address _signer) external;

    ///@notice Enable or disable the specified token for staking
    ///@param _token The token to enable or disable for staking
    ///@param _amount limit for stakable tokens
    ///@dev Only callable by the owner
    function setStakableAmount(address _token, uint256 _amount) external;

    ///@notice Add or remove the migrator to/from the blocklist, such that it can no longer be used from migrating tokens from the staking pool
    ///@param _migrator The migrator contract to add or remove from the blocklist
    ///@param _blocklisted If true, then add the migrator to the blocklist. If false, then remove the migrator from the blocklist.
    ///@dev Only callable by the owner
    function blockMigrator(address _migrator, bool _blocklisted) external;

    ///@notice Pause further staking through the deposit function.
    ///@dev Only callable by the owner. Withdrawals and migrations will still be possible when paused
    function pause() external;

    ///@notice Unpause staking allowing the deposit function to be used again
    ///@dev Only callable by the owner
    function unpause() external;
}
