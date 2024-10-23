// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.16;

import {Test} from "forge-std/Test.sol";
import {DeployRaffle} from "script/DeployRaffle.s.sol";
import {Raffle} from "src/Raffle.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";

contract RaffleTest is Test {

     Raffle public raffle;
     HelperConfig public helperConfig;

     uint256 entranceFee;
     uint256 interval;
     address vrfCoordinator;
     bytes32 gasLane;
     uint256 subscriptionId;
     uint32 callbackGasLimit;

     address public  PLAYER = makeAddr("player");
     uint256 public constant STARTING_PLAYER_BALANCE = 10 ether;

     event RaffleEntered(address indexed player);
     event WinnerPicked(address indexed winner);

     function setUp() external {
          DeployRaffle deployer = new DeployRaffle();
         (raffle, helperConfig) = deployer.DeployContract();
         HelperConfig.NetworkConfig memory config = helperConfig.getConfig();
         entranceFee = config.entranceFee;
         interval = config.interval;
         vrfCoordinator = config.vrfCoordinator;
         gasLane = config.gasLane;
         subscriptionId = config.subscriptionId;
         callbackGasLimit = config.callbackGasLimit;

         vm.deal(PLAYER, STARTING_PLAYER_BALANCE);
     }

     function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
     }

     function testRaffleRevertsWhenYouDontPayTheEntranceFee() public {
        vm.prank(PLAYER);
        vm.expectRevert(Raffle.Raffle_SendMoreToEnterRaffle.selector);
        raffle.enterRaffle/*{value: entranceFee - 1}*/();
     }    

     function testRaffleRecordsPlayerWhenTheyEnter() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        assert(raffle.getPlayer(0) == PLAYER);
     }

     function testRaffleEmitsEventOnEntrance() public {
        vm.prank(PLAYER);
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RaffleEntered(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
     } 

     function testDontAllowPlayersToEnterWhileRaffleIsCalculating() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();

        vm.expectRevert(Raffle.Raffle_RaffleNotOpen.selector);
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
     }
// upkeep tests
     function testCheckUpKeepReturnsFalseIfItHasNoBalance() public {
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }

     function testCheckUpKeepReturnsFalseIfRaffleNotOpen() public raffleIsOpen {
        (bool upkeepNeeded, ) = raffle.checkUpkeep("");
        assert(!upkeepNeeded);
     }


     // testupkeepreturnsfalseifenoughtimehasntpassed
     // testCheckUpkeepReturnsTrueWhenParametersAreGood
   //   Challenge 1. testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed
    function testCheckUpkeepReturnsFalseIfEnoughTimeHasntPassed() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(!upkeepNeeded);
    }

    // Challenge 2. testCheckUpkeepReturnsTrueWhenParametersGood
    function testCheckUpkeepReturnsTrueWhenParametersGood() public {
        // Arrange
        vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);

        // Act
        (bool upkeepNeeded,) = raffle.checkUpkeep("");

        // Assert
        assert(upkeepNeeded);
    }

     modifier raffleIsOpen() {
         vm.prank(PLAYER);
        raffle.enterRaffle{value: entranceFee}();
        vm.warp(block.timestamp + interval + 1);
        vm.roll(block.number + 1);
        raffle.performUpkeep();
        _;
     }
}
