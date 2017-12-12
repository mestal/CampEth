pragma solidity ^0.4.0;
contract UseCampaign {

    struct Campaign {
        string name;
        string description;
        uint priceAddEnd;
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
    
    event PriceDecreased(uint price);
    event CampaignEnded(uint price);
    
    function UseCampaign(string _name, string _description, uint _limit, uint _addPriceTime) public {
        started = false;
		ended = false;
        campaign = Campaign({
            name: _name,
            description: _description,
            priceAddEnd: now + _addPriceTime,
            limit: _limit
        });

        owner = msg.sender;
    }
    
    function AddCampaignDetail(CampaignDetail _campaignDetail) public {
		require(msg.sender == owner);
		require(!started);
		require(!ended);
		require(_campaignDetail.quantityLevel > 0 && _campaignDetail.price > 0);
		
		if(campaignDetails.length != 0)
		{
		    uint lastIndex = campaignDetails.length - 1;
		    require(campaignDetails[lastIndex].quantityLevel < _campaignDetail.quantityLevel && campaignDetails[lastIndex].price > _campaignDetail.price);
		}
		
        campaignDetails.push(CampaignDetail ({
             quantityLevel: _campaignDetail.quantityLevel,
             price: _campaignDetail.price
        }));
    }
    
    //TODO Remove Campaign Detail function must be added (before Start Campaign)
    
    function StartCampaign() public {
		require(msg.sender == owner);
		require(!started);
		require(!ended);
		require(campaignDetails.length >= 2);
		
        started = true;
        //TODO validation must be added : limit must be bigger or equal to the biggest value at the list
        //TODO quantityLevel must be distinct.
    }

    function Buy(uint quantity) payable public {
        require(msg.sender != owner);
        require(!ended);
        require(started);
        require(getTotalQuantity() + quantity <= campaign.limit); 
        
		//According to bought quantity, new price is calculated and validate required amount for this new price.
        uint newQuantity = getTotalQuantity() + quantity;
        
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
    
	
	//TODO : Scheduling may be implemented for automatic end.
    function EndBuying() public
    {
        require(owner == msg.sender);
        require(!ended);
        require(started);
		
        //If minimum quantitylevel not reached, then return all the money to the buyers 
        if(now >= campaign.priceAddEnd)
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
        
        if(getTotalQuantity() >= campaign.limit || ended)
        {
            ended = true;
            
            uint totalPrice = 0;
            uint rowTotal = 0;
            for(uint j = 0; j < buyers.length; j ++)
            {
            currentPrice = getCurrentPrice();
                rowTotal = buyers[j].quantity * currentPrice;
                buyers[j].buyeraddress.transfer(buyers[j].value - rowTotal);
                totalPrice += rowTotal;
            }

            owner.transfer(totalPrice);
            
            CampaignEnded(currentPrice);
        }
    }
    
    function getTotalQuantity() private constant returns (uint totalQuantity)
    {
        totalQuantity = 0;
        for(uint i = 0; i < buyers.length;i ++)
        {
            totalQuantity += buyers[i].quantity;
        }
    }
    
    function getCurrentPrice() private constant returns (uint _currentPrice)
    {
        uint totalQuantity = getTotalQuantity();

        _currentPrice = getPriceForQuantity(totalQuantity);
    }
    
    function getPriceForQuantity(uint quantity) private constant returns (uint _price)
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
}
