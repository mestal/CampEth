contract CampEth {
    
    //using strings for *;

    struct Campaign {
        string code;
        string name;
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
    
    Campaign _campaign;
    CampaignDetail[] _campaignDetails;
    Buyer[] _buyers;
    address _owner;
    bool _ended;
    bool _started;
    uint _currentPrice = 0;
    bytes32[] public _coupons;
    
    mapping(address => string) public _soldcoupons;
    
    event PriceDecreased(uint price);
    event CampaignEnded(uint price);
    
    function CampEth(string code, string name, uint limit, uint addPriceTime, bytes32[] coupons) public { 
        require(coupons.length == limit);
        
        _started = false;
		_ended = false;
        _campaign = Campaign({
            code: code,
            name: name,
            endTime: now + addPriceTime,
            limit: limit
        });
        
        //TODO coupons must be distinct
        
        _coupons = coupons;
        
        _owner = msg.sender;
    }

    
    function AddCampaignDetail(uint quantityLevel, uint price) public {
		require(msg.sender == _owner);
		require(!_started);
		require(!_ended);
		require(quantityLevel >= 0 && price > 0);
		
		if(_campaignDetails.length != 0)
		{
		    uint lastIndex = _campaignDetails.length - 1;
		    require(_campaignDetails[lastIndex].quantityLevel < quantityLevel && _campaignDetails[lastIndex].price > price);
		}
		
        _campaignDetails.push(CampaignDetail ({
             quantityLevel: quantityLevel,
             price: price
        }));
    }
    
    function GetCampaignInfo() public constant returns(string,uint,bool,bool,uint[],uint[],address,address, uint)
    {
        uint[] memory quantityLevels = new uint[](_campaignDetails.length);
        uint[] memory prices = new uint[](_campaignDetails.length);
        
        for (uint i = 0; i < _campaignDetails.length; i++) {
            quantityLevels[i] = _campaignDetails[i].quantityLevel;
            prices[i] = _campaignDetails[i].price;
        }
        
        uint totalQuantity = getTotalQuantity();
        
        return (_campaign.code, _campaign.limit, _started, _ended, quantityLevels, prices,  _owner, this, totalQuantity);
    }
    
    //TODO Remove Campaign Detail function must be added (before Start Campaign)
    
    function StartCampaign() public returns(bool) {
		require(msg.sender == _owner);
		require(!_started);
		require(!_ended);
		require(_campaignDetails.length >= 2);
		
        _started = true;
        
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
        require(msg.sender != _owner);
        require(!_ended);
        require(_started);
        uint totalQuantity = getTotalQuantity();
        require(totalQuantity + quantity <= _campaign.limit);
        
		//According to bought quantity, new price is calculated and validate required amount for this new price.
        uint newQuantity = totalQuantity + quantity;
        
        uint newPrice = getPriceForQuantity(newQuantity);

        require(newPrice <= msg.value / quantity);
        
        if(newPrice != _currentPrice)
        {
            _currentPrice = newPrice;
            PriceDecreased(newPrice);
        }
        
		//TODO distint process may be done according to address
        _buyers.push(Buyer({
                quantity: quantity,
                value: msg.value,
                buyeraddress: msg.sender
            }));
    }
    
    function checkBalance() constant public returns(uint)
    {
        return this.balance;
    }
    
	
	//TODO : Scheduling may be implemented for automatic end.
    function EndCampaign() public
    {
        require(_owner == msg.sender);
        require(!_ended);
        require(_started);
        
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
        
        if(getTotalQuantity() >= _campaign.limit || _ended)
        { 
            _ended = true;
            _currentPrice = getCurrentPrice();
            
            uint usedCouponIndex = 0;
            uint totalPrice = 0;
            uint rowTotal = 0;
            for(uint j = 0; j < _buyers.length; j ++)
            {
                //return difference amounts according to decreased price
                rowTotal = _buyers[j].quantity * _currentPrice;
                _buyers[j].buyeraddress.transfer(_buyers[j].value - rowTotal);
                totalPrice += rowTotal;
                
                
                _soldcoupons[_buyers[j].buyeraddress] = bytes32ToString(_coupons[usedCouponIndex]);
                usedCouponIndex ++;
                
                /*
                for(uint k = 0; k < _buyers[j].quantity; k ++)
                {
                    _soldcoupons[_buyers[j].buyeraddress] = _soldcoupons[_buyers[j].buyeraddress].toSlice().concat(bytes32ToString(_coupons[usedCouponIndex]).toSlice());
                    usedCouponIndex ++;
                }
                */
            }

            _owner.transfer(totalPrice);
            
            CampaignEnded(_currentPrice);
        }
    }
    
    function GetCoupon() public constant returns (string)
    {
        require(_started && _ended);
        return _soldcoupons[msg.sender];
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
        for(uint i = 0; i < _buyers.length;i ++)
        {
            totalQuantity += _buyers[i].quantity;
        }
    }
    
    function getCurrentPrice() public constant returns (uint _currentPrice)
    {
        uint totalQuantity = getTotalQuantity();

        _currentPrice = getPriceForQuantity(totalQuantity);
    }
    
    function getPriceForQuantity(uint quantity) public constant returns (uint _price)
    {
        if(_campaignDetails[0].quantityLevel > quantity)
        {
            _price = 0;
            return;
        }
        
        uint maxValidIndex = 0;
        for(uint i = 1; i < _campaignDetails.length; i ++)
        {
            if(_campaignDetails[i].quantityLevel <= quantity)
                maxValidIndex = i;
            else
                break;
        }
        
        _price = _campaignDetails[maxValidIndex].price;

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
        AddCampaignDetail(3,100000000);
        AddCampaignDetail(7,75000000);
        AddCampaignDetail(9,60000000);
        AddCampaignDetail(11,50000000);
        StartCampaign();
    }
    
    //Test Debug
    function TestCreateDetail2() public
    {
        AddCampaignDetail(0,125000000);
        AddCampaignDetail(1,100000000);
        AddCampaignDetail(2,75000000);
        StartCampaign();
    }
    
    function GetBuyers() public constant returns (address[],uint[])
    {
        address[] memory addresses = new address[](_buyers.length);
        uint[] memory quantities = new uint[](_buyers.length);
        
        for (uint i = 0; i < _buyers.length; i++) {
            addresses[i] = _buyers[i].buyeraddress;
            quantities[i] = _buyers[i].quantity;
        }
        
        return (addresses, quantities);
    }
    
    function GetStarted() public constant returns (bool)
    {
        return _started;
    }
    
    function GetEnded() public constant returns (bool)
    {
        return _ended;
    }
    
    
    function TestGetCoupon(uint index) constant public returns(string)
    {
        return bytes32ToString(_coupons[index]);
    }
}
