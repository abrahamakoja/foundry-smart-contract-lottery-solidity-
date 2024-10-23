// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.16;
import {Script, console} from "forge-std/Script.sol";
import {HelperConfig, CodeConstants} from "script/HelperConfig.s.sol";
import {VRFCoordinatorV2_5Mock} from "@chainlink/contracts/src/v0.8/vrf/mocks/VRFCoordinatorV2_5Mock.sol";
import {LinkToken} from "test/mocks/LinkToken.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";

contract CreateSubscription is Script {
    function CreateSubscriptionUsingConfig() public returns (uint256, address) {
        HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
    (uint256 subId,) =     createSubscription(vrfCoordinator);
        return (subId,vrfCoordinator);
  }

    function createSubscription(address vrfCoordinator) public returns (uint256, address) {
        console.log("Creating subscription on chain: ", block.chainid);
        vm.startBroadcast();
        uint256 subId = VRFCoordinatorV2_5Mock(vrfCoordinator).createSubscription();
        vm.stopBroadcast();

        console.log("Subscription ID: ", subId);
        return (subId, vrfCoordinator);
    }

    function run() public {
        CreateSubscriptionUsingConfig();
}
}


contract FundSubscription is Script, CodeConstants {
uint256 public constant FUND_AMOUNT = 3 ether;

    function fundSubscriptionUsingConfig() public {
       HelperConfig helperconfig = new HelperConfig();
        address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
        uint256 subscriptionId = helperconfig.getConfig().subscriptionId;
        address linkToken = helperconfig.getConfig().link;
        fundSubscription(vrfCoordinator, subscriptionId, linkToken);
    }

    function fundSubscription(address vrfCoordinator, uint256 subscriptionId, address linkToken) public {
        console.log("Funding subscription: ", subscriptionId);
        console.log("using vrfCoordinator: ", vrfCoordinator);
        console.log("on chain: ", block.chainid);
        // vm.startBroadcast();
        //if LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
        // vm.stopBroadcast();
        if(block.chainid == LOCAL_CHAIN_ID){
           vm.startBroadcast();
           VRFCoordinatorV2_5Mock(vrfCoordinator).fundSubscription(subscriptionId, FUND_AMOUNT);
           vm.stopBroadcast();
        }else {
            vm.startBroadcast();
            LinkToken(linkToken).transferAndCall(vrfCoordinator, FUND_AMOUNT, abi.encode(subscriptionId));
            vm.stopBroadcast();
        }
    }

    function run() public {
        
        fundSubscriptionUsingConfig();
    }
}

contract AddConsumer is Script {
 function addConsumerUsingConfig(address mostRecentlyDeployed) public {
    HelperConfig helperconfig = new HelperConfig();
    address vrfCoordinator = helperconfig.getConfig().vrfCoordinator;
    uint256 subscriptionId = helperconfig.getConfig().subscriptionId;
    addConsumer(mostRecentlyDeployed,vrfCoordinator, subscriptionId);
 }

 function addConsumer(address contractToAddtoVrf, address vrfCoordinator, uint256 subId) public {
   console.log("Adding consumer contract: ", contractToAddtoVrf);
   console.log("to vrfCoodinator: ", vrfCoordinator);
   console.log("on chain: ", block.chainid);
   vm.startBroadcast();
   VRFCoordinatorV2_5Mock(vrfCoordinator).addConsumer(subId, contractToAddtoVrf);
   vm.stopBroadcast();
 }

 function run() external{
    address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("Raffle", block.chainid);
    addConsumerUsingConfig(mostRecentlyDeployed);
 }
}

