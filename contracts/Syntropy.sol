pragma solidity 0.5.11;

// Syntropy By Solange Gueiros
// versao 0.3.0


contract Token {
    using SafeMath for uint256;
    //By OpenZeppelin


    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    //function mint(address to, uint256 value) public onlyMinter returns (bool) {
    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }


}

contract UsdS is Token {
    // Syntropy By Solange Gueiros
    uint8 private constant decimals_ = 2;
    uint256 private constant initialSupply_ = 1000000 * (10 ** uint256(decimals_));
    constructor () public Token("Syntropy USD", "USDS", decimals_) {
        _mint(msg.sender, initialSupply_);
    }
}

contract Border {
    using SafeMath for uint256;
    // Syntropy By Solange Gueiros

    string public name;
    address public creator;
    address public usdAddress;

    uint256 public decimalpercent = 10000;                  //100.00 = precisão da porcentagem (2) + 2 casas para 100%
    uint8  public constant MaxAccount = 49;                //Número máximo de transferencias / depósitos em batch

    mapping (address => uint256) public ratioOwner;
    address[] public owners;
    mapping (address => uint256) public indexOwner;     //posicao no array

    uint256 public totalRatio;                           //totalSupply do token
    uint256 public _valueDeposited;                     //Valor que será dividido de acordo com o shareRatio
    mapping (address => uint256) public _balances;      //Saldo disponivel em USD que cada pessoa pode retirar


    constructor(string memory _name, address _usdAddress, address _ownerAddress) public {
        creator = _ownerAddress;
        name = _name;
        usdAddress = _usdAddress;
        totalRatio = 0;
        _valueDeposited = 0;
    }

    function listOwners() public view returns (address[] memory) {
        return owners;
    }
    
    function isOwner(address _address) public view returns (bool) {
        if (ratioOwner[_address] > 0)
            return true;
        else
            return false;
    }

    function getIndexOwner(uint256 i) public view returns (address) {
        return owners[i];
    }

    function countOwners() public view returns (uint256) {
        return owners.length;
    }

    function _addOwner(address account, uint256 shareRatio) internal returns (bool) {
        require(account != address(0), "zero address");
        require(shareRatio > 0, "shares are 0");

        if (indexOwner[account] == 0) {
            indexOwner[account] = owners.push(account)-1;
            ratioOwner[account] = shareRatio;
            emit AddOwner(account, shareRatio);
        }
        else {
            ratioOwner[account] = ratioOwner[account].add(shareRatio);
        }

        totalRatio = totalRatio.add(shareRatio);
        return true;
    }

    function _removeOwner(address _address) internal returns (bool) {
        //Retirar do array Owner
        uint256 indexToDelete = indexOwner[_address];
        address addressToMove = owners[owners.length-1];
        indexOwner[addressToMove] = indexToDelete;
        owners[indexToDelete] = addressToMove;
        owners.length--;
        emit RemoveOwner(_address);
        return true;
    }

    event AddOwner (address indexed _address, uint256 shareRatio);
    event RemoveOwner (address indexed _address);


    event DepositUSD(uint256 _totalValue, address[] indexed _froms, uint256[] _values);

    function depositUSD(uint256 _totalValue, address[] memory _froms, uint256[] memory _values) public {
        require(_froms.length == _values.length, "number froms and values don't match");
        require(_froms.length < MaxAccount, "too many recipients");


        UsdS usdS = UsdS(usdAddress);
        //A soma dos valores não pode ser maior que o allowance
        require(_totalValue >= usdS.allowance(msg.sender, address(this)), "ammount not approved");
        require(usdS.transferFrom(msg.sender, address(this), _totalValue), "Can't transfer to border");

        emit DepositUSD(_totalValue, _froms, _values);


        if (owners.length == 0) {
            for (uint256 i = 0; i < _froms.length; i++) {
                _balances[_froms[i]] = _balances[_froms[i]].add(_values[i]);
            }
        }
        else {
             _valueDeposited = _totalValue;
            for (uint256 i = 0; i < owners.length; i++) {
                _releaseUSD(owners[i]);
            }
            _valueDeposited = 0;
        }

        for (uint256 i = 0; i < _froms.length; i++) {
            _addOwner(_froms[i], _values[i]);
        }
    }

    event ReleaseUSD(address indexed to, uint256 value);

    function _releaseUSD(address account) internal {
        require(ratioOwner[account] > 0, "no shares");

        uint256 payment = _valueDeposited.mul(ratioOwner[account]).div(totalRatio);
        _balances[account] = _balances[account].add(payment);
        emit ReleaseUSD(account, payment);
    }

    //Balance USD in the contract in behalf of account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //Withdrawal USD in the contract in behalf of msg.sender
    function withdrawalUSD() public {
        require(_balances[msg.sender] > 0, "balance is zero");

        uint256 value = _balances[msg.sender];
        _balances[msg.sender] = 0;
        UsdS usdS = UsdS(usdAddress);
        require(usdS.transfer(msg.sender, value), "usdS transfer error");
        delete value;
    }

    //Token Border equivalent
    function ratioOf(address account) public view returns (uint256) {
        uint256 value = decimalpercent.mul(ratioOwner[account]).div(totalRatio);
        return value;
    }

    event TransferRatio(address indexed from, address indexed to, uint256 value);

    //Transfer a amount of your part in Border to another account
    function transferRatio(address account, uint256 shareRatio) public {
        require(account != address(0), "zero address");
        require(shareRatio > 0, "shares are 0");

        //Não estou verificado se ele quer transferir mais do que tem, simplesmente vai dar erro no sub.
        uint256 newRatio = ratioOwner[msg.sender].sub(shareRatio);

        //Se ratioOwner[msg.sender] = 0, retiro do array para não passar por ele sem necessidade
        if (newRatio == 0) {
            require(_removeOwner(msg.sender), "removeOwner error");
            //_removeOwner(msg.sender);
        }

        ratioOwner[msg.sender] = newRatio;
        _addOwner(account, shareRatio);
        emit TransferRatio (msg.sender, account, shareRatio);
    }

}

contract BorderFactory {
    // Syntropy By Solange Gueiros

    address[] public borders;
    mapping (address => bool) public isBorder;
    address public usdAddress;

    constructor(address _usdAddress) public {
        usdAddress = _usdAddress;
    }

    function inBorderFactory (address _borderAddress) public view returns (bool) {
        return (isBorder[_borderAddress]);
    }

    function listBorders() public view returns (address[] memory) {
        return borders;
    }


    function lastBorderCreated () public view returns (address) {
        return borders[borders.length-1];
    }

    event CreateBorder (address indexed _address, string _name);

    function createBorder (string memory _name) public returns (Border) {
        Border border = new Border (_name, usdAddress, msg.sender);

        borders.push(address(border));
        isBorder[address(border)] = true;
        emit CreateBorder (address(border), _name);
        return border;
    }

}



contract Moviment {
    using SafeMath for uint256;
    // Syntropy By Solange Gueiros
    
    string public name;
    uint256 public decimalpercent = 10000;              //100.00 = precisão da porcentagem (2) + 2 casas para 100%
    address public creator;
    uint32  public constant MaxAccountIn = 277;             //Número máximo de transferencias / depósitos em batch
    
    BorderFactory public borderFactory;                 //From BorderFactory
    address public usdAddress;

    enum TypeShare {Out, In, Border}
    struct ShareStruct {
        address accountFrom;
        address accountTo;
        uint256 ratio;
        uint256 indexFrom;
        uint256 indexTo;
        TypeShare accountType;
    }
    ShareStruct[] public ownerShare;
    mapping (address => mapping (address => uint256)) public shareIndex;  //para cada AC1 AC2 guarda o indice da struct onde estao as informacoes
    mapping (address => uint256[]) public indexFrom;   //Guarda os indices da struct onde o endereço envia o share
    mapping (address => uint256[]) public indexTo;     //Guarda os indices da struct onde o endereço recebe o share

    address[] public borders;                           //Bordas que recebem deste movimento
    mapping (address => uint256) public indexBorder;    //borda que recebe deste movimento - posicao no array

    address[] public accountsIn;                            //Accounts que recebem deste movimento - por dentro - o movimento faz o pagamento
    mapping (address => uint256) public indexAccountIn;    //AccountsIn - posicao no array
    mapping (address => uint256) public countAccountIn;    //AccountsIn - quantos do IndexTo para Account são IN
    mapping (address => uint256) public _balances;         //Saldo disponivel em USD que cada account pode retirar



    constructor(string memory _name, address _borderFactory, address _usdAddress, address _ownerAddress) public {
        creator = _ownerAddress;
        name = _name;
        usdAddress = _usdAddress;
        borderFactory = BorderFactory(_borderFactory);
        borders.push(address(0x0));  //posicao 0 zerada
        accountsIn.push(address(0x0));  //posicao 0 zerada
        owners.push(address(0x0));  //posicao 0 zerada
        indexOwner[_ownerAddress] = owners.push(_ownerAddress)-1;

        addShareStruct(address(0x0), address(0x0), 0, TypeShare.Out);  //posicao 0 zerada
        addShareStruct(_ownerAddress, _ownerAddress, decimalpercent, TypeShare.Out);
    }

    function addShareStruct (address _accountFrom, address _accountTo, uint256 _ratio, TypeShare _accountType) internal returns (uint256 index) {
      //Verifica se já existe ownerShare para _accountFrom e _accountTo.
      require (shareIndex[_accountFrom][_accountTo] == 0, "ownerShare exists");

      uint256 posIndexFrom = indexFrom[_accountFrom].push(index) - 1;  //index = 0 aqui, só descobre qual é a posição no indexFrom
      uint256 posIndexTo = indexTo[_accountTo].push(index) - 1;

      ShareStruct memory s1 = ShareStruct({
          accountFrom: _accountFrom,
          accountTo: _accountTo,
          accountType: _accountType,
          ratio: _ratio,
          indexFrom: posIndexFrom,
          indexTo: posIndexTo
      });
      index = ownerShare.push(s1) - 1;
      shareIndex[_accountFrom][_accountTo] = index;

      indexFrom[_accountFrom][posIndexFrom] = index;
      indexTo[_accountTo][posIndexTo] = index;
    }

    function delShareStruct (uint256 _index) internal returns (bool) {
        address accountFrom = ownerShare[_index].accountFrom;
        address accountTo = ownerShare[_index].accountTo;

        //Retira do ownerShare
        uint256 keyToMove = ownerShare.length - 1;
        shareIndex[ownerShare[keyToMove].accountFrom][ownerShare[keyToMove].accountTo] = _index;
        ownerShare[_index].accountFrom = ownerShare[keyToMove].accountFrom;
        ownerShare[_index].accountTo = ownerShare[keyToMove].accountTo;
        ownerShare[_index].ratio = ownerShare[keyToMove].ratio;

        //Atualiza o index do From
        indexFrom[ownerShare[keyToMove].accountFrom][ownerShare[keyToMove].indexFrom] = _index;

        //Atualiza o index do To
        indexTo[ownerShare[keyToMove].accountTo][ownerShare[keyToMove].indexTo] = _index;

        ownerShare.length--;

        //Retira do From - VERIFICAR: é o último mesmo que tem que retirar?
        indexFrom[accountFrom].length--;
        
        //Retira do To - VERIFICAR: é o último mesmo que tem que retirar?
        indexTo[accountTo].length--;

        shareIndex[accountFrom][accountTo] = 0;
        return true;
    }

    function countIndexFrom(address _address) public view returns (uint256) {
        return indexFrom[_address].length;
    }

    function countIndexTo(address _address) public view returns (uint256) {
        return indexTo[_address].length;
    }

    function countAccountsIn() public view returns (uint256) {
        return accountsIn.length;
    }

    //SHARES
    function ratioShare (address accountFrom, address accountTo) public view returns (uint256) {
        uint256 index = shareIndex[accountFrom][accountTo];
        if (index == 0)
          return 0;
        else
          return ownerShare[index].ratio;
    }

    event ShareIncrease (address indexed _from, address indexed _to, uint256 _ratio);
    event ShareDecrease (address indexed _from, address indexed _to, uint256 _ratio);

    function shareIncrease(address _account, uint _ratio) public onlyOwner {
        TypeShare _accountType;

        if (isBorder(_account) && !inBorderList(_account)) {
        //if (isBorder(_account)) {
            _accountType = TypeShare.Border;
        }
        else
        {
            _accountType = TypeShare.Out;
        }

        _shareIncrease(_account, _ratio, _accountType);
        delete _accountType;
    }

    function _shareIncrease(address _account, uint _ratio, TypeShare _accountType) internal {
        uint256 from = shareIndex[msg.sender][msg.sender];
        uint256 ratio = ownerShare[from].ratio;
        require(ratio >= _ratio, "greater than owner share");

        ownerShare[from].ratio = ownerShare[from].ratio.sub(_ratio);

        uint256 to = shareIndex[msg.sender][_account];
        if (to > 0) {
            require(ownerShare[to].accountType == _accountType, "accountType mismach");
            //Já tem um share, so aumenta o ratio
            ownerShare[to].ratio = ownerShare[to].ratio.add(_ratio);
        }
        else {
          //Se msg.sender não share com _account ainda, adiciona _account
          if (_accountType == TypeShare.Border) {
          //if (isBorder(_account)) {
            //Se a borda não está na lista de bordas que recebe do movimento (array borders), adiciona
            if (indexTo[_account].length == 0) {
                addBorder(_account);
            }
            to = addShareStruct(msg.sender, _account,  _ratio, TypeShare.Border);
          }
          else
          {
            if (_accountType == TypeShare.In) {
                //Se account não está na lista de AccountIn que recebe do movimento (array AccountsIn), adiciona
                if (countAccountIn[_account] == 0) {
                    addAccountIn(_account);
                }
                countAccountIn[_account] ++;
            }
            to = addShareStruct(msg.sender, _account,  _ratio, _accountType);
          }
        }

        if (ownerShare[from].ratio == 0) {
            //msg.sender não tem mais ratio, retira do array de structs
            delShareStruct(from);
        }
        emit ShareIncrease(msg.sender, _account, _ratio);
        delete from;
        delete to;
        delete ratio;
    }

    function shareDecrease(address _account, uint _ratio) public onlyOwner {
        uint256 to = shareIndex[msg.sender][_account];
        uint256 ratio = ownerShare[to].ratio;
        require(ratio >= _ratio, "greater than account's share");

        ownerShare[to].ratio = ownerShare[to].ratio.sub(_ratio);

        uint256 from = shareIndex[msg.sender][msg.sender];
        if (from > 0) {
            ownerShare[from].ratio = ownerShare[from].ratio.add(_ratio);
        }
        else {
            //Se msg.sender não tinha mais share, adiciona
            from = addShareStruct(msg.sender, msg.sender,  _ratio, TypeShare.Out);
        }

        if (ownerShare[to].ratio == 0) {
            TypeShare accountType = ownerShare[to].accountType;
            //_account não tem mais share, retira do array de structs
            delShareStruct(to);
            //é uma borda e não recebe de mais ninguem
            if (inBorderList(_account) && indexTo[_account].length == 0 ) {
                removeBorder(_account);
            }
            if (accountType == TypeShare.In) {
                countAccountIn[_account] --;
                if (countAccountIn[_account] == 0)  {
                    removeAccountIn(_account);
                }
            }
        }
        emit ShareDecrease(msg.sender, _account, _ratio);
        delete from;
        delete to;
        delete ratio;        
    }


    //OWNERS
    address[] public owners;                            //Donos do movimento
    mapping (address => uint256) public indexOwner;     //posicao no array

    event AddOwner (address indexed _address);
    event RemoveOwner (address indexed _address);

    modifier onlyOwner {
        _onlyOwner();
        _;
    }
    function _onlyOwner() internal view {
        require(indexOwner[msg.sender] > 0, "only owner");
    }

    function inOwnerList (address _address) public view returns (bool) {
        if (indexOwner[_address] > 0)
            return true;
        else
            return false;
    }

    function addOwner (address _address) internal returns (uint256) {
        require (!inOwnerList(_address), "owner exists");
        indexOwner[_address] = owners.push(_address)-1;
        emit AddOwner(_address);
        return indexOwner[_address];
    }

    function removeOwner (address _address) internal returns (bool) {
        require (inOwnerList(_address), "owner not exists");
        //Retirar do array Owner
        uint256 indexToDelete = indexOwner[_address];
        address addressToMove = owners[owners.length-1];
        indexOwner[addressToMove] = indexToDelete;
        owners[indexToDelete] = addressToMove;
        owners.length--;
        indexOwner[_address] = 0;
        emit RemoveOwner(_address);
        delete indexToDelete;
        delete addressToMove;
        return true;
    }

    event OwnerTransfer (address indexed _from, address indexed _to, uint256 _ratio);

    function ownerTransfer(address _account, uint _ratio) public onlyOwner {
        //_account não pode ser uma borda
        require(!isBorder(_account), "is Border");

        uint256 from = shareIndex[msg.sender][msg.sender];
        uint256 ratio = ownerShare[from].ratio;
        require(ratio >= _ratio, "greater than owner share");
        ownerShare[from].ratio = ownerShare[from].ratio.sub(_ratio);

        uint256 to = shareIndex[_account][_account];
        if (to > 0) {
          //Já tem um share, so aumenta o ratio
          ownerShare[to].ratio = ownerShare[to].ratio.add(_ratio);
        }
        else {
            to = addShareStruct(_account, _account,  _ratio, TypeShare.Out);
            addOwner(_account);
        }

        if (ownerShare[from].ratio == 0) {
            //msg.sender não tem mais ratio, retira do array de structs
            delShareStruct(from);
            removeOwner(msg.sender);
        }
        emit OwnerTransfer(msg.sender, _account, _ratio);
        delete from;
        delete to;
        delete ratio;
    }

    function listOwners() public view returns (address[] memory) {
        return owners;
    }


    //BORDERS
    function inBorderList (address _address) public view returns (bool) {
        if (indexBorder[_address] > 0)
            return true;
        else
            return false;
    }

    function isBorder (address _address) public view returns (bool) {
        return borderFactory.inBorderFactory (_address);
    }

    event AddBorder (address indexed _address);
    event RemoveBorder (address indexed _address);

    function addBorder (address _address) internal returns (uint256) {
        require (!inBorderList(_address), "border exists");
        indexBorder[_address] = borders.push(_address)-1;
        emit AddBorder(_address);
        return indexBorder[_address];
    }

    function removeBorder (address _address) internal returns (bool) {
        require (inBorderList(_address), "border not exists");
        //Retirar do array Border
        uint256 indexToDelete = indexBorder[_address];
        address addressToMove = borders[borders.length-1];
        indexBorder[addressToMove] = indexToDelete;
        borders[indexToDelete] = addressToMove;
        borders.length--;
        indexBorder[_address] = 0;
        emit RemoveBorder(_address);
        delete indexToDelete;
        delete addressToMove;
        return true;
    }

    function listBorders() public view returns (address[] memory) {
        return borders;
    }

    //ACCOUNTINs
    event AddAccountIn (address indexed _address);
    event RemoveAccountIn (address indexed _address);

    function isAccountIn (address _address) public view returns (bool) {
        if (indexAccountIn[_address] > 0)
            return true;
        else
            return false;
    }

    function addAccountIn (address _address) internal returns (uint256) {
        require (!isAccountIn(_address), "accountIn exists");
        require(accountsIn.length < MaxAccountIn, "max number of accountIN");
        indexAccountIn[_address] = accountsIn.push(_address)-1;
        emit AddAccountIn(_address);
        return indexAccountIn[_address];
    }

    function removeAccountIn (address _address) internal returns (bool) {
        require (isAccountIn(_address), "accountIn not exists");
        //Retirar do array accountIn
        uint256 indexToDelete = indexAccountIn[_address];
        address addressToMove = accountsIn[accountsIn.length-1];
        indexAccountIn[addressToMove] = indexToDelete;
        accountsIn[indexToDelete] = addressToMove;
        accountsIn.length--;
        indexAccountIn[_address] = 0;
        emit RemoveAccountIn(_address);
        delete indexToDelete;
        delete addressToMove;
        return true;
    }

    // borderTransfer
    address[] private borderFroms;
    uint256[] private borderValues;

    function borderTransfer (uint256 _total, uint256 _borderAmount) public onlyOwner returns (uint256) {
        //Fazer o approve do USD, para que seja distribuido aqui
        UsdS usdS = UsdS(usdAddress);
        Border border;
        require(usdS.transferFrom(msg.sender, address(this), _borderAmount), "can not transfer to moviment");

        //E se o _borderAmount não é suficiente?

        uint256 totalTransfer = 0;

        for (uint256 b = 1; b < borders.length; b++) {
            uint256 totalBorder = 0;

            //Structs de quem a borda recebe
            for (uint256 t = 0; t < indexTo[borders[b]].length; t++) {
                uint256 index = indexTo[borders[b]][t];
                uint256 value = ownerShare[index].ratio.mul(_total).div(decimalpercent);
                totalBorder = totalBorder.add(value);
                borderFroms.push(ownerShare[index].accountFrom);
                borderValues.push(value);
            }

            if (totalBorder > 0) {
                totalTransfer = totalTransfer.add(totalBorder);
                usdS.approve(borders[b], totalBorder);
                border = Border(borders[b]);
                border.depositUSD (totalBorder, borderFroms, borderValues);
            }

            delete borderFroms;
            delete borderValues;
        }

        //Sobrou troco? devolve para o sender
        if (_borderAmount.sub(totalTransfer) > 0) {
            usdS.transfer(msg.sender, _borderAmount.sub(totalTransfer));
        }
        return totalTransfer;
    }


    // ACCOUNTS IN
    function shareIncreaseIn(address _account, uint _ratio) public onlyOwner {
        require (!isBorder(_account), "is border");

        TypeShare _accountType;
        _accountType = TypeShare.In;
        _shareIncrease(_account, _ratio, _accountType);
    }

    event Transfer(address indexed from, address indexed to, uint256 value);

    //AccountIN PROCESSAR as entradas - como o depositUSD do Border
    function accountInTransfer (uint256 _total, uint256 _accountAmount) public onlyOwner returns (uint256) {
        //Fazer o approve do USD, para que seja distribuido aqui
        UsdS usdS = UsdS(usdAddress);
        require(usdS.transferFrom(msg.sender, address(this), _accountAmount), "Can not transfer to moviment");
        //USD agora está armazenado no moviment

        //E se o _accountAmount não é suficiente?
        uint256 totalTransfer = 0;
        for (uint256 a = 1; a < accountsIn.length; a++) {
            uint256 totalAmount = 0;
            //Structs de quem accountIN recebe
            for (uint256 t = 0; t < indexTo[accountsIn[a]].length; t++) {
                uint256 index = indexTo[accountsIn[a]][t];
                uint256 amount = ownerShare[index].ratio.mul(_total).div(decimalpercent);
                totalAmount = totalAmount.add(amount);
                emit Transfer (ownerShare[index].accountFrom, ownerShare[index].accountTo, amount);
            }
            _balances[accountsIn[a]] = _balances[accountsIn[a]].add(totalAmount);
            totalTransfer = totalTransfer.add(totalAmount);
        }

        //Sobrou troco? devolve para o sender
        if (_accountAmount.sub(totalTransfer) > 0) {
            usdS.transfer(msg.sender, _accountAmount.sub(totalTransfer));
        }
        return totalTransfer;
    }

    //Balance USD in the contract in behalf of account
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //Withdrawal USD in the contract in behalf of msg.sender
    function withdrawalUSD() public {
        require(_balances[msg.sender] > 0, "balance is zero");

        uint256 value = _balances[msg.sender];
        _balances[msg.sender] = 0;
        UsdS usdS = UsdS(usdAddress);
        require(usdS.transfer(msg.sender, value), "usdS transfer error");
        delete value;
    }


    /*
    event Incoming(address indexed from, uint256 value, string description);
    event AnnounceBorderIncoming(address indexed from, address indexed to, uint256 value, string description);
    event AnnounceShareIncoming(address indexed from, address indexed to, uint256 value, TypeShare accountType, string description);

    function reportIncoming (uint256 _value, string memory _description) public onlyOwner {

        emit Incoming(msg.sender, _value, _description);

        uint256 index = 0;
        uint256 value = 0;
        address from = address(0x0);
        address to = address(0x0);
        TypeShare accountType = TypeShare.Out;

        for (uint256 o = 1; o < owners.length; o++) {
            //Structs para quem o owner envia
            for (uint256 f = 0; f < indexFrom[owners[o]].length; f++) {
                index = indexFrom[owners[o]][f];
                value = ownerShare[index].ratio.mul(_value).div(decimalpercent);
                from = ownerShare[index].accountFrom;
                to = ownerShare[index].accountTo;
                accountType = ownerShare[index].accountType;
                if (inBorderList(to))
                    emit AnnounceBorderIncoming (from, to, value, _description);
                else
                    emit AnnounceShareIncoming (from, to, value, accountType, _description);
            }
        }
    }


    //Se eu receber XXX, quanto tenho que enviar para as bordas e accountIns, seja em meu nome ou em nome dos outros?
    function getTransferAmount (uint256 _total) public view returns (uint256 totalBorders, uint256 totalAccountIns) {
        uint256 total = 0;

        //Borders
        for (uint256 b = 1; b < borders.length; b++) {
            //Structs de quem a borda recebe
            for (uint256 t = 0; t < indexTo[borders[b]].length; t++) {
                uint256 index = indexTo[borders[b]][t];
                uint256 value = ownerShare[index].ratio.mul(_total).div(decimalpercent);
                total = total.add(value);
            }
        }
        totalBorders = total;

        //AccountIns
        total = 0;
        for (uint256 a = 1; a < accountsIn.length; a++) {
            //Structs de quem a accountIN recebe
            for (uint256 t = 0; t < indexTo[accountsIn[a]].length; t++) {
                uint256 index = indexTo[accountsIn[a]][t];
                uint256 value = ownerShare[index].ratio.mul(_total).div(decimalpercent);
                total = total.add(value);
            }
        }
        totalAccountIns = total;

        return (totalBorders, totalAccountIns) ;
    }
    */



}

contract MovimentFactory {
    // Syntropy By Solange Gueiros

    address public usdAddress;
    address public borderFactory;

    constructor(address _usdAddress, address _borderFactory) public {
        usdAddress = _usdAddress;
        borderFactory = _borderFactory;
    }

    event CreateMoviment (address indexed _address, string _name);

    function createMoviment (string memory _name) public returns (address) {
        Moviment moviment = new Moviment (_name, borderFactory, usdAddress, msg.sender);
        emit CreateMoviment (address(moviment), _name);
        return address(moviment);
    }
}



library SafeMath {
    //By OpenZeppelin

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}