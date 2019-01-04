pragma solidity ^0.4.23;

import "./Ownable.sol";

contract Blocklords is Ownable {


/////////////////////////////////////   MISC    ////////////////////////////////////////////////    

uint duration8Hours = 28800;      // 28_800 Seconds are 8 hours
uint duration12Hours = 43200;     // 43_200 Seconds are 12 hours
uint duration24Hours = 86400;     // 86_400 Seconds are 24 hours

uint createHeroFee = 888000000; //TRX in SUN, 1 TRX * 1000000
                        //000000
uint fee8Hours =   50000000;
                     //000000
uint fee12Hours =  88000000;
                     //000000
uint fee24Hours = 100000000;
                     //000000
uint siegeBattleFee = 333000000;
                         //000000
uint banditBattleFee = 100000000;
                          //000000
uint strongholdBattleFee = 200000000;
                              //000000

uint ATTACKER_WON = 1;
uint ATTACKER_LOSE = 2;
uint DRAW = 3;

uint PVP= 1;       // Player Against Player at the Strongholds
uint PVC= 2;       // Player Against City
uint PVE= 3;       // Player Against NPC on the map



uint coffersTotal = allCoffers();

function getBalance() onlyOwner public returns(uint) {
    return this.balance;
}

function withdraw(uint amount) onlyOwner public returns(bool) { // only contract's owner can withdraw to owner's address
        // require(amount < address(this).balance-coffersTotal,
        // "balance is insufficient");  // Umcomment this requirement if you want the amount stored in coffers to be not withdrawable
        address owner_ = owner();
        owner_.transfer(amount);
        return true;    
}

function random(uint entropy, uint number) private view returns (uint8) {   
     // NOTE: This random generator is not entirely safe and   could potentially compromise the game, 
        return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%number);
   }

function randomFromAddress(address entropy) private view returns (uint8) {  
       return uint8(1 + uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, entropy)))%256);
   }

////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// PAYMENT STRUCT ///////////////////////////////////////////////    

    struct Payment{
        address PAYER;
        uint HERO_ID;
    }
    
    mapping (uint => Payment) payments;
    
    function heroCreationPayment(uint heroId)  payable returns(uint, uint, bool){
        require(msg.value == createHeroFee, "Payment fee does not match");
        payments[heroId] = Payment(msg.sender, heroId);
        return(msg.value, createHeroFee, msg.value == createHeroFee);
    }
    
    function getPayments(uint heroId) public view returns(address, uint){
        return(payments[heroId].PAYER, payments[heroId].HERO_ID);
    } //TODO: add event

////////////////////////////////////////////////////////////////////////////////////////////////////    


///////////////////////////////////// HERO STRUCT ////////////////////////////////////////////////    

    struct Hero{
        address OWNER;     // Wallet address of Player that owns Hero
        uint TROOPS_CAP;   // Troops limit for this hero
        uint LEADERSHIP;   // Leadership Stat value
        uint INTELLIGENCE; // Intelligence Stat value
        uint STRENGTH;     // Strength Stat value
        uint SPEED;        // Speed Stat value
        uint DEFENSE;      // Defense Stat value
        // bytes32 TX;     // Transaction ID where Hero creation was recorded
    }
    
    mapping (uint => Hero) heroes;
    
    function putHero(uint id, uint troopsCap, uint leadership,  uint intelligence, uint strength, uint speed, uint defense, uint item1, uint item2, uint item3, uint item4, uint item5) public payable returns(bool){ 
            require(msg.value == createHeroFee, "Payment fee does not match");
            require(id > 0, 
            "Please insert id higher than 0");
            //require(payments[id].PAYER == owner, "Payer and owner do not match");
            require(heroes[id].OWNER == 0x0000000000000000000000000000000000000000,
            "Hero with this id already exists");

            // TODO check item is not for stronghold reward
             require(items[item1].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item2].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item3].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item4].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
             require(items[item5].OWNER != 0x0000000000000000000000000000000000000000, "Item is not exist");
            
            //delete payments[id]; // delete payment hash after the hero was created in order to prevent double spend
            heroes[id] = Hero(msg.sender, troopsCap, leadership,  intelligence, strength, speed, defense);

            items[item1].OWNER = msg.sender;
            items[item2].OWNER = msg.sender;
            items[item3].OWNER = msg.sender;
            items[item4].OWNER = msg.sender;
            items[item5].OWNER = msg.sender;
            

            return true;
    }
    
    function getHero(uint id) public view returns(address, uint, uint, uint, uint, uint, uint){ 
            return (heroes[id].OWNER, heroes[id].TROOPS_CAP, heroes[id].LEADERSHIP, heroes[id].INTELLIGENCE, heroes[id].STRENGTH, heroes[id].SPEED, heroes[id].DEFENSE);
        }

////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// ITEM STRUCT //////////////////////////////////////////////////   

    struct Item{

        bytes32 STAT_TYPE; // Item can increase only one stat of Hero, there are five: Leadership, Defense, Speed, Strength and Intelligence
        bytes32 QUALITY; // Item can be in different Quality. Used in Gameplay.
        
        uint GENERATION; // Items are given to Players only as a reward for holding Strongholds on map, or when players create a hero.
                         // Items are given from a list of items batches. Item batches are putted on Blockchain at once by Game Owner.
                         // Each of Item batches is called as a generation.

        uint STAT_VALUE;
        uint LEVEL;
        uint XP;         // Each battle where, Item was used by Hero, increases Experience (XP). Experiences increases Level. Level increases Stat value of Item
        address OWNER;   // Wallet address of Item owner.
    }
    
    mapping (uint => Item) items;

    // creationType StrongholdReward: 0, createHero 1
    function putItem(uint creationType, uint id, bytes32 statType, bytes32 quality, uint generation, uint statValue, uint level, uint xp ) public onlyOwner { // only contract owner can put new items
            require(id > 0,
            "Please insert id higher than 0");

            items[id] = Item(statType, quality, generation, statValue, level, xp, msg.sender);
            
            if (creationType == 0){
                addStrongholdReward(id);     //if putItem(stronghold reward) ==> add to StrongholdReward
            }
        }

    function getItem(uint id) public view returns(bytes32, bytes32, uint, uint, uint, uint, address){
            return (items[id].STAT_TYPE, items[id].QUALITY, items[id].GENERATION, items[id].STAT_VALUE, items[id].LEVEL, items[id].XP, items[id].OWNER);
        }
    
    function updateItemsStats(uint[] itemIds) public {
        for (uint i=0; i < itemIds.length ; i++){
            
            uint id = itemIds[i];
            Item storage item = items[id];
            uint seed = item.GENERATION+item.LEVEL+item.STAT_VALUE+item.XP + itemIds.length + randomFromAddress(item.OWNER); // my poor attempt to make the random generation a little bit more random

            // Increase XP that represents on how many battles the Item was involved into
            item.XP = item.XP + 1;
            
            // Increase Level
            if (item.QUALITY == 1 && item.LEVEL == 3 ||
                item.QUALITY == 2 && item.LEVEL == 5 ||
                item.QUALITY == 3 && item.LEVEL == 7 ||
                item.QUALITY == 4 && item.LEVEL == 9 ||
                item.QUALITY == 5 && item.LEVEL == 10){
                    // return "The Item reached max possible level. So do not update it";
                    continue;
            } if (
                item.LEVEL == 1 && item.XP >= 4 ||
                item.LEVEL == 2 && item.XP >= 14 ||
                item.LEVEL == 3 && item.XP >= 34 ||
                item.LEVEL == 4 && item.XP >= 74 ||
                item.LEVEL == 5 && item.XP >= 144 ||
                item.LEVEL == 6 && item.XP >= 254 ||
                item.LEVEL == 7 && item.XP >= 404 ||
                item.LEVEL == 8 && item.XP >= 604 ||
                item.LEVEL == 9 && item.XP >= 904
                ) {
                    
                    item.LEVEL = item.LEVEL + 1;
                    // return "Item level is increased by 1";
            } 
            // Increase Stats based on Quality
            if (item.QUALITY == 1){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3);
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 3;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 6;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 9;
            } else if (item.QUALITY == 2){
                item.STAT_VALUE = item.STAT_VALUE + random(seed, 3) + 12;
            }

        }
        
    }
    
////////////////////////////////////////////////////////////////////////////////////////////////////////    

///////////////////////////////////// MARKET ITEM STRUCT ///////////////////////////////////////////////   

    struct MarketItemData{
        
            uint Price; // Fixed Price of Item defined by Item owner
            uint AuctionDuration; // 8, 12, 24 hours
            uint AuctionStartedTime; // Unix timestamp in seconds
            uint City; // City ID (item can be added onto the market only through cities.)
            address Seller; // Wallet Address of Item owner
            // bytes32 TX; // Transaction ID, (Transaction that has a record of Item Adding on Market)

    }

    mapping (uint => MarketItemData) market_items_data;

    function auctionBegin(uint itemId, uint price, uint auctionDuration, uint city) public payable { // START AUCTION FUNCTION
            require(items[itemId].OWNER == msg.sender, "You don't own this item");
            require(auctionDuration == duration8Hours || auctionDuration == duration12Hours || auctionDuration == duration24Hours,
            "Incorrect auction duration");
            if (auctionDuration == duration8Hours){
                require(msg.value == fee8Hours,
                "Incorrect fee amount");
            } else if (auctionDuration == duration12Hours){
                require(msg.value == fee12Hours,
                "Incorrect fee amount");
            } else if (auctionDuration == duration24Hours){
                require(msg.value == fee24Hours,
                "Incorrect fee amount");
            }
            address seller = msg.sender; 
            uint auctionStartedTime = now;
            market_items_data[itemId] = MarketItemData(price, auctionDuration, auctionStartedTime, city, seller);
        }
    
    function getAuctionData(uint itemId) public view returns(uint, uint, uint, uint, address){
            return(market_items_data[itemId].Price, market_items_data[itemId].AuctionDuration, market_items_data[itemId].AuctionStartedTime, market_items_data[itemId].City, market_items_data[itemId].Seller);
    }

    function auctionEnd(uint itemId) public payable returns(bool) {
        require(market_items_data[itemId].AuctionStartedTime+market_items_data[itemId].AuctionDuration>=now,
        "Auction is no longer available"); // check  auction duration time
        require(msg.value == (market_items_data[itemId].Price / 100 * 110),
        "The value sent is incorrect"); // check transaction amount
        
        uint city = market_items_data[itemId].City; // get the city id
        
        uint cityHero = cities[city].Hero;  // get the hero id
        address cityOwner = heroes[cityHero].OWNER; // get the hero owner
        address seller = market_items_data[itemId].Seller;
        
        uint amount = msg.value;
        
        cityOwner.transfer(amount / 110 * 5); // send 5% to city owner
        seller.transfer(amount / 110 * 100); // send 90% to seller
        
        items[itemId].OWNER = msg.sender; // change owner
        delete market_items_data[itemId]; // delete auction
        return (true); 
        
    }

    function auctionCancel(uint itemId) public returns(bool){
        require(market_items_data[itemId].Seller == msg.sender,
                "You do not own this item");
        delete market_items_data[itemId];
        return true;
    }


//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  
///////////////////////////////////// CITY STRUCT //////////////////////////////////////////////////////////   

    struct City{
        
        uint ID; // city ID
        uint Hero;  // id of the hero owner
        uint Size; // BIG, MEDIUM, SMALL
        uint CofferSize; // size of the city coffer
        
    }

    City[16] public cities;

    mapping(uint => City[16]) public idToCity;

    function putCity(uint id, uint size, uint cofferSize) public payable onlyOwner {
        require(msg.value == cofferSize,
                "msg.value does not match cofferSize");
        uint blankHero = 0;
        cities[id] = City(id, blankHero, size, cofferSize);
    }

    function getCityData(uint id) public view returns(uint, uint){
        return (cities[id].Hero, cities[id].Size);
        
    }
    
    function allCoffers() public view returns(uint){
        uint total = 0;
        for (uint i=0; i < cities.length ; i++){
            total += cities[i].CofferSize;
        }
        return total;
    }
    
    uint cofferBlockNumber = block.number;
    uint CofferBlockDistance = 25000; 

    function dropCoffer() public {   // drop coffer (every 25 000 blocks) ==> 30% coffer goes to cityOwner
        require(block.number-cofferBlockNumber > CofferBlockDistance,
        "Please try again later");
        
        cofferBlockNumber = block.number; // this function can be called every "cofferBlockNumber" blocks

        for (uint cityNumber=0; cityNumber < cities.length ; cityNumber++){ // loop through each city

            uint cityHero = cities[cityNumber].Hero;
            address heroOwner = heroes[cityHero].OWNER;
            uint transferValue = cities[cityNumber].CofferSize/3;
            if (cityHero > 0){
                heroOwner.transfer(transferValue);
            } 
        }
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    
///////////////////////////////////// STRONGHOLD STRUCT //////////////////////////////////////////////////////////   

    struct Stronghold{
        uint ID;           // Stronghold ID
        uint Hero;         // Hero ID, that occupies Stronghold on map
        uint CreatedBlock; // The Blockchain Height
      
    }
    
    Stronghold[10] public strongholds;

    mapping(uint => Stronghold[10]) public idToStronghold;

    function changeStrongholdOwner(uint id, uint hero) public {
            require(heroes[hero].OWNER != 0x0000000000000000000000000000000000000000,
            "There is no such hero");
            require(heroes[hero].OWNER == msg.sender,
            "You dont own this hero");
            
            strongholds[id] = Stronghold(id, hero, block.number); // Stronghold ID is the only id that starts from 0, all other id's start from 1
    }
    
    function getStrongholdData(uint shId) public view returns(uint, uint){
            return(strongholds[shId].Hero, strongholds[shId].CreatedBlock);
    }
    
    function leaveStronghold(uint shId, uint heroId) public returns(bool){
            require(strongholds[shId].Hero == heroId,
            "Selected hero is not in the stronghold");
             require(heroes[heroId].OWNER == msg.sender,
            "You do not own this hero");
            strongholds[shId].Hero = 0;
            return true;
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// STRONGLOHD REWARD STRUCT /////////////////////////////////////////////////////////

    struct StrongholdReward{
        
        uint ID;           // Item ID
        uint CreatedBlock; // The Blockchain Height
        
    }
    
    mapping (uint => StrongholdReward) stronghold_rewards;
    
    function addStrongholdReward(uint id) public onlyOwner returns(bool){
        stronghold_rewards[id] = StrongholdReward(id, block.number);
    }
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////// BATTLELOG STRUCT /////////////////////////////////////////////////////////

    struct BattleLog{

        uint[] BattleResultType; // BattleResultType[0]: 0 - Attacker WON, 1 - Attacker Lose ; BattleResultType[1]: 0 - City, 1 - Stronghold, 2 - Bandit Camp
        uint Attacker;
        uint[] AttackerTroops;       // Attacker's troops amount that were involved in the battle & remained troops
        uint[] AttackerItems;        // Item IDs that were equipped by Attacker during battle.
        uint DefenderObject;   // City|Stronghold|NPC ID based on battle type
        uint Defender;         // City Owner ID|Stronghold Owner ID or NPC ID
        uint[] DefenderTroops;
        uint[] DefenderItems;
        uint Time;             // Unix Timestamp in seconds. Time, when battle happened 
        // bytes32 TX;                   // Transaction where Battle Log was recorded.
        }
        
    mapping(uint => BattleLog) battle_logs;
    
    // result type: win or lose/ battle type
    // last parameter 'dropItem' is only for contest version of game
    function addBattleLog(uint id, uint[] resultType, uint attacker, uint[] attackerTroops, uint[] attackerItems, 
                          uint defenderObject, uint defender, uint[] defenderTroops, uint[] defenderItems,
                          uint dropItem) public payable returns (bool){
                        
            require(resultType.length <=2 && resultType[0] <= 2 && resultType[1] <= 3 ,
                    "Incorrect number of result parametres or incorrect parametres");
            require(attackerTroops.length == 2,
                    "Incorrect number of arguments for attackerTroops");
            require(attackerItems.length <= 5,
                    "incorrect number of attacker items");
            require(defenderTroops.length == 2,
                    "Incorrect number of arguments for defenderTroops");
            require(defenderItems.length <=5,
                    "incorrect number of defender items");
            
            if (resultType[1] == PVC){ // siegeBattleFee if atack City
                require(msg.value == siegeBattleFee,
                "Incorrect fee amount");
            } else if (resultType[1] == PVP){ // strongholdBattleFee if atack Stronghold
                require(msg.value == strongholdBattleFee,
                "Incorrect fee amount");
            } else if (resultType[1] == PVE){ // banditBattleFee if atack Bandit Camp
                require(msg.value == banditBattleFee,
                "Incorrect fee amount");
            }

            uint time = now;
                            
            battle_logs[id] = BattleLog(resultType, attacker, attackerTroops, 
                                        attackerItems, defenderObject, defender, 
                                        defenderTroops, defenderItems, time); //add data to the struct 
                                        
            if (resultType[0] == ATTACKER_WON) {
                items[dropItem].OWNER = msg.sender;
            }

            if (resultType[0] == ATTACKER_WON && resultType[1] == PVP){ 
                strongholds[defenderObject].Hero = attacker; // if attack Stronghold && WIN ==> change stronghold Owner
            } else if (resultType[0] == ATTACKER_WON && resultType[1] == PVC) {
                cities[defenderObject].Hero = attacker; // else if attack City && WIN ==> change city owner 
                cities[defenderObject].CofferSize += (siegeBattleFee/2); // 50% of attack fee goes to coffer
            } else if (resultType[1] == PVE){
                updateItemsStats(attackerItems);     // else if attackBandit ==> update item stats
            } 
            return true;
    }


////////////////////////////////////////// DROP DATA STRUCT ///////////////////////////////////////////////////
    
    struct DropData{       // Information of Item that player can get as a reward.
        uint Block;        // Blockchain Height, in which player got Item as a reward
        uint StrongholdId; // Stronghold on the map, for which player got Item
        uint ItemId;       // Item id that was given as a reward
        uint HeroId;
    }

    uint blockNumber = block.number;
    uint blockDistance = 120; 


    function dropItems(uint itemNumber) public onlyOwner returns(string) {
        require(stronghold_rewards[itemNumber].ID > 0,
        "Not a reward item");
        require(block.number-blockNumber > blockDistance,
        "Please try again later");
                
        blockNumber = block.number; // this function can be called every "blockDistance" blocks
        uint strongholdNumber = random(randomFromAddress(msg.sender), 10)-1; // select randomly stronghold
        uint strongholdHero = strongholds[strongholdNumber].Hero;
        if (strongholdHero > 0){
           items[itemNumber].OWNER = heroes[strongholdHero].OWNER;
           delete stronghold_rewards[itemNumber];//delete item from strongHold reward struct
           delete strongholds[strongholdNumber];
           return("Supreme success!"); // check if hero exist
        } else {
            return ("No success");
        }
    }

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

}