pragma solidity ^0.4.17;
import "github.com/Arachnid/solidity-stringutils/strings.sol";

contract MainContract {
    
    address addressList;
    
    uint deneme;
    function AddNewCampaign(address add1) public
    {
        addressList = add1;
        //addressList.push(add1);
    }
    
    function GetCampaignList() constant public returns (address)
    {
        return addressList;
    }
    
    function setdeneme(uint a) public
    {
        deneme = a;
    }
    
    function getdeneme() public constant returns (uint)
    {
        return deneme;
    }
    
}

contract CampEth {
    //TODO use modifier
    
    using strings for *;

    struct Campaign {
        string name;
        string description;
        uint endTime;
        uint limit;
    }

    struct CampaignDetail {
        uint quantityLevel;
        uint price;
    }
    
    struct Buyer {
        uint quantity;
        uint value;
        address buyeraddress;
    }
    
    Campaign campaign;
    CampaignDetail[] campaignDetails;
    Buyer[] buyers;
    address owner;
    bool ended;
    bool started;
    uint currentPrice = 0;
    bytes32[] private coupons;
    address mainContractAddress;
    MainContract mainContract;
    
    mapping(address => string) private soldcoupons;
    
    event PriceDecreased(uint price);
    event CampaignEnded(uint price);
    
    function CampEth(address _mainContract, string _name, string _description, uint _limit, uint _addPriceTime, bytes32[] _coupons) public { 
        require(_coupons.length == _limit);
        
        started = false;
		ended = false;
        campaign = Campaign({
            name: _name,
            description: _description,
            endTime: now + _addPriceTime,
            limit: _limit
        });
        mainContractAddress = _mainContract;
        
        //TODO coupons must be distinct
        
        coupons = _coupons;
        
        owner = msg.sender;
    }

    
    function AddCampaignDetail(uint _quantityLevel, uint _price) public {
		require(msg.sender == owner);
		require(!started);
		require(!ended);
		require(_quantityLevel >= 0 && _price > 0);
		
		if(campaignDetails.length != 0)
		{
		    uint lastIndex = campaignDetails.length - 1;
		    require(campaignDetails[lastIndex].quantityLevel < _quantityLevel && campaignDetails[lastIndex].price > _price);
		}
		
        campaignDetails.push(CampaignDetail ({
             quantityLevel: _quantityLevel,
             price: _price
        }));
    }
    
    function GetCampaignInfo() public constant returns(string,string,uint,uint[],uint[])
    {
        uint[] memory quantityLevels = new uint[](campaignDetails.length);
        uint[] memory prices = new uint[](campaignDetails.length);
        
        for (uint i = 0; i < campaignDetails.length; i++) {
            quantityLevels[i] = campaignDetails[i].quantityLevel;
            prices[i] = campaignDetails[i].price;
        }
        
        
        return (campaign.name, campaign.description, campaign.limit, quantityLevels, prices);
    }
    
    //TODO Remove Campaign Detail function must be added (before Start Campaign)
    
    function StartCampaign() public returns(bool) {
		require(msg.sender == owner);
		require(!started);
		require(!ended);
		require(campaignDetails.length >= 2);
		
        started = true;
        
        //Can no change other contract property
        //mainContract = MainContract(mainContractAddress);
        //mainContract.AddNewCampaign.gas(800)(address(this));
        
        //mainContract.setdeneme(5);
        
        //return mainContractAddress.call(bytes4(keccak256("AddNewCampaign(address)")), address(this));
        
        //require(mainContractAddress.call(bytes4(keccak256("setdeneme(uint)")), 3) == true);
        //mainContract = MainContract(mainContractAddress);
        //mainContract.setdeneme.gas(800)(4);
        
        //TODO validation must be added : limit must be bigger or equal to the biggest value at the list
        //TODO quantityLevel must be distinct.
    }

    function Buy(uint quantity) payable public {
        require(msg.sender != owner);
        require(!ended);
        require(started);
        uint totalQuantity = getTotalQuantity();
        require(totalQuantity + quantity <= campaign.limit);
        
		//According to bought quantity, new price is calculated and validate required amount for this new price.
        uint newQuantity = totalQuantity + quantity;
        
        uint newPrice = getPriceForQuantity(newQuantity);

        require(newPrice <= msg.value / quantity);
        
        if(newPrice != currentPrice)
        {
            currentPrice = newPrice;
            PriceDecreased(newPrice);
        }
        
		//TODO distint process may be done according to address
        buyers.push(Buyer({
                quantity: quantity,
                value: msg.value,
                buyeraddress: msg.sender
            }));
    }
    
    function checkBalance() returns(uint)
    {
        return this.balance;
    }
    
	
	//TODO : Scheduling may be implemented for automatic end.
    function EndCampaign() public
    {
        require(owner == msg.sender);
        require(!ended);
        require(started);
		
		/*
        //If minimum quantitylevel not reached, then return all the money to the buyers 
        if(now >= campaign.endTime)
        {
            ended = true;
            if(getTotalQuantity() < campaignDetails[0].quantityLevel)
            {
                for(uint i = 0; i < buyers.length;i ++)
                {
                    buyers[i].buyeraddress.transfer(buyers[i].value);
                } 
                
                CampaignEnded(0);
                return;
            }
        }
        */
        
        if(getTotalQuantity() >= campaign.limit || ended)
        { 
            ended = true;
            currentPrice = getCurrentPrice();
            
            uint usedCouponIndex = 0;
            uint totalPrice = 0;
            uint rowTotal = 0;
            for(uint j = 0; j < buyers.length; j ++)
            {
                //return difference amounts according to decreased price
                rowTotal = buyers[j].quantity * currentPrice;
                buyers[j].buyeraddress.transfer(buyers[j].value - rowTotal);
                totalPrice += rowTotal;
                
                for(uint k = 0; k < buyers[j].quantity; k ++)
                {
                    soldcoupons[buyers[j].buyeraddress] = soldcoupons[buyers[j].buyeraddress].toSlice().concat(bytes32ToString(coupons[usedCouponIndex]).toSlice());

                    usedCouponIndex ++;
                }
            }

            owner.transfer(totalPrice);
            
            CampaignEnded(currentPrice);
        }
    }

    
    function GetCoupon() public constant returns (string)
    {
        require(started && ended);
        return soldcoupons[msg.sender];
    }
    
    /*
    function GetUsedCoupons() public constant returns (string[])
    {
        require(owner == msg.sender);
        require(started && ended);
        return soldcoupons[msg.sender];
    }
    */
    
    function getTotalQuantity() public constant returns (uint totalQuantity)
    {
        totalQuantity = 0;
        for(uint i = 0; i < buyers.length;i ++)
        {
            totalQuantity += buyers[i].quantity;
        }
    }
    
    function getCurrentPrice() public constant returns (uint _currentPrice)
    {
        uint totalQuantity = getTotalQuantity();

        _currentPrice = getPriceForQuantity(totalQuantity);
    }
    
    function getPriceForQuantity(uint quantity) public constant returns (uint _price)
    {
        if(campaignDetails[0].quantityLevel > quantity)
        {
            _price = 0;
            return;
        }
        
        uint maxValidIndex = 0;
        for(uint i = 1; i < campaignDetails.length; i ++)
        {
            if(campaignDetails[i].quantityLevel <= quantity)
                maxValidIndex = i;
            else
                break;
        }
        
        _price = campaignDetails[maxValidIndex].price;

    }
    
    function bytes32ToString(bytes32 x) constant returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
    
    
    //Test Debug
    function TestCreateDetail() public
    {
        AddCampaignDetail(0,125000000);
        AddCampaignDetail(1,100000000);
        AddCampaignDetail(2,75000000);
        //StartCampaign();
    }
    
    function GetStarted() public constant returns (bool)
    {
        return started;
    }
    
    function GetEnded() public constant returns (bool)
    {
        return ended;
    }
    
    function GetCoupon1() constant public returns(string)
    {
        return bytes32ToString(coupons[0]);
    }
}
