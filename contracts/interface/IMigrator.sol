// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

/// @title Migrator Interface
/// @notice Interface for the Migrator contract called by the LevelStaking Pool's migrate() function
interface IMigrator {
    ///@notice Function called by the LevelStaking Pool to facilitate migration of staked tokens from the LevelStaking Pool to Level
    ///@param _user The address of the user whose staked funds are being migrated to Level
    ///@param _tokens The tokens being migrated to Level from the LevelStaking Pool
    ///@param _destination The address which will be credited the tokens on Level
    ///@param _amounts The amounts of each token to be migrated to Level for the _user
    function migrate(
        address _user,
        address[] calldata _tokens,
        address _destination,
        uint256[] calldata _amounts
    ) external;
}
