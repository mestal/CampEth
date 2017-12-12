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
        campaignDetails.push(CampaignDetail ({
             quantityLevel: _campaignDetail.quantityLevel,
             price: _campaignDetail.price
        }));
    }
    
    function StartCampaign() public {
		require(msg.sender == owner);
		require(!started);
		require(!ended);
		
        started = true;
        //TODO limit, listedeki en büyük deðerden büyük ya da eþit olmalý
        //TODO quantityLevel distinct olmalý
    }

    function addBuyer(uint quantity) payable public {
        require(msg.sender != owner);
        require(!ended);
        require(started);
        require(getTotalQuantity() + quantity <= campaign.limit); 
        
		//Eklenen quantity e göre yeni fiyat hesaplanarak minimum bu paranýn gönderilmesi kontrolü yapýlýyor.
        uint newQuantity = getTotalQuantity() + quantity;
        
        uint newPrice = getPriceForQuantity(newQuantity);

        require(newPrice <= msg.value / quantity);
        
        if(newPrice != currentPrice)
        {
            currentPrice = newPrice;
            PriceDecreased(newPrice);
        }
        
        //TODO adrese göre distinct yapýlarak push ya da update yapýlabilir.
        buyers.push(Buyer({
                quantity: quantity,
                value: msg.value,
                buyeraddress: msg.sender
            }));
    }
    
    function endAddBuyer() public
    {
        require(owner == msg.sender);
        require(!ended);
        require(started);
		
        //TODO minimum kiþi sayýsý oluþmamýþ ise tüm para iade edilir.
        
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
                //fazlalýklar iade ediliyor.
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
    
    function sortCampaignDetails(CampaignDetail[] details) private constant returns (CampaignDetail[] resultDetails)
    {
        //TODO
        resultDetails = details;
    }
}
