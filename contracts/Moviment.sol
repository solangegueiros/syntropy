pragma solidity 0.5.11;

// Syntropy By Solange Gueiros
// versao 0.2.2


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

    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
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

    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }

}

contract SolUSD is Token {
    // Syntropy By Solange Gueiros
    uint8 private constant decimals_ = 4;
    uint256 private constant initialSupply_ = 1000000 * (10 ** uint256(decimals_));
    constructor () public Token("Sol USD", "SUSD", decimals_) {
        _mint(msg.sender, initialSupply_);
    }
}

contract TokenBorder is Token {
    // Syntropy By Solange Gueiros
    uint8 private constant decimals_ = 4;
    address public owner;

    constructor (string memory _name, string memory _symbol)
        public Token(_name, _symbol, decimals_) {
        owner = msg.sender;
    }

    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);

        //Atualiza proporcoes na Borda
        Border border = Border(owner);
        //border.updateRatio();

        if (! border.isOwner(to)) {
            border.addOwner(to);
        }

        for (uint256 i = 0; i < border.countOwners(); i++) {
            address addressAux = border.getOwner(i);
            uint256 ratio = balanceOf(addressAux).mul(border.decimalpercent());
            ratio = ratio.div(totalSupply());
            border.setRatioOwner(addressAux, ratio);
        }

        return true;
    }

    modifier onlyOwner() {
        require((msg.sender == owner), "Only owner");
        _;
    }

    //function mint(address to, uint256 value) public onlyMinter returns (bool) {
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(msg.sender == owner, "TokenBorder mint: only border can mint token");
        _mint(to, value);
        return true;
    }

}

contract Border {
    using SafeMath for uint256;
    // Syntropy By Solange Gueiros

    string public name;
    address public creator;
    TokenBorder public tokenBorder;
    address public usdAddress;

    uint256 public decimalpercent = 10000;                  //100.00 = precisão da porcentagem (2) + 2 casas para 100%
    uint32  public constant MAX_COUNT = 100;                //Número máximo de transferencias / depósitos em batch
    mapping (address => uint256) public ratioOwner;
    address[] public owners;


    constructor(string memory _name, string memory _tokenName, string memory _tokenSymbol, address _usdAddress, address _ownerAddress) public {
        creator = _ownerAddress;
        name = _name;
    
        tokenBorder = new TokenBorder (_tokenName, _tokenSymbol);
        usdAddress = _usdAddress;

        owners.push(_ownerAddress);
        ratioOwner[_ownerAddress] = decimalpercent;
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

    function getOwner(uint256 i) public view returns (address) {
        return owners[i];
    }

    function countOwners() public view returns (uint256) {
        return owners.length;
    }


    event DepositUSD(uint256 _totalValue, address[] indexed _froms, uint256[] _values);

    function depositUSD(uint256 _totalValue, address[] memory _froms, uint256[] memory _values) public {
        require(_froms.length == _values.length, "Amount of recipients and values don't match");
        require(_froms.length < MAX_COUNT, "Too many recipients");


        SolUSD solUSD = SolUSD(usdAddress);
        //A soma dos valores não pode ser maior que o allowance
        require(_totalValue >= solUSD.allowance(msg.sender, address(this)), "Ammount not approved");

        require(solUSD.transferFrom(msg.sender, address(this), _totalValue), "Can not transfer to border");

        emit DepositUSD(_totalValue, _froms, _values);


        /*
            Deveria ser atualizado somente após a emissão de tokens, porém se alguém transferiu tokens para outra pessoa, ratio foi alterado.
            updateRatio();
            Atualmente é atualizado no transfer do token
        */

        for (uint256 n = 0; n < _froms.length; n++) {
        
            //Futuros problemas aqui
            for (uint256 i = 0; i < owners.length; i++) {

                //Pode dar problema de overflow em primeiro multiplicar e depois dividir, mas o contrario acarreta perda no arredondamento.
                uint256 amountPart = _values[n].mul(ratioOwner[owners[i]]);
                amountPart = amountPart.div(decimalpercent);

                //Divide de acordo com ratio
                require(solUSD.transfer(owners[i], amountPart), "solUSD transfer error");
            }

            if (ratioOwner[_froms[n]] == 0) {
                owners.push(_froms[n]);
            }
            require(tokenBorder.mint(_froms[n], _values[n]), "tokenBorder mint error");
        }
        
        updateRatio();
    }

    
    function updateRatio() public {
        //Atualiza ratio de acordo com a distribuicao de tokenBorder
        if (tokenBorder.totalSupply() == 0)
         return;

        for (uint256 i = 0; i < owners.length; i++) {
            uint256 ratio = tokenBorder.balanceOf(owners[i]).mul(decimalpercent);
            ratio = ratio.div(tokenBorder.totalSupply());
            ratioOwner[owners[i]] = ratio;
        }
    }

    
    //Para que o tokenBorder possa atualizar o ratio
    modifier onlyTokenBorder {
        require(msg.sender == address(tokenBorder), "Only tokenBorder");
        _;
    }
    
    function setRatioOwner(address _address, uint256 _ratio) external onlyTokenBorder {
        ratioOwner[_address] = _ratio;
    }

    function addOwner(address _address) external onlyTokenBorder {
        owners.push(_address);
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

    function createBorder (string memory _name, string memory _tokenName, string memory _tokenSymbol) public returns (Border) {
        Border border = new Border (_name, _tokenName, _tokenSymbol, usdAddress, msg.sender);

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
    address[] public owners;                            //Donos "permanentes" do movimento
    address[] public shareOwners;                       //Donos "temporarios" do movimento, quando alguém compartilha sua parte temporariamente
    mapping (address => uint256) public indexOwner;     //posicao no array
    mapping (address => uint256) public ratioOwner;     // % total de cada nó, permanente

    mapping (address => mapping (address => uint256)) public shareOwner; //% temporária que cada nó encaminha para outro nó a partir deste movimento
    mapping (address => uint256) public indexShareOwner;     //posicao no array
    mapping (address => uint256) public ratioShareOwner;     // % total de cada nó, temporário

    address[] public borders;                           //Bordas que recebem deste movimento
    mapping (address => uint256) public indexBorder;    //borda que recebe deste movimento - posicao no array
    //ratioBorder é a % total que cada owner envia para a borda. Como é relativa a cada owner, o total pode ser mais de 100%
    mapping (address => uint256) public ratioBorder;    // % total de cada borda
    mapping (address => mapping (address => uint256)) public shareBorder; //% que cada nó encaminha para a borda a partir deste movimento
    
    //From BorderFactory
    BorderFactory public borderFactory;

    address public usdAddress;
    

    constructor(string memory _name, address _borderFactory, address _usdAddress, address _ownerAddress) public {
        creator = _ownerAddress;
        name = _name;
        owners.push(address(0x0));  //posicao 0 zerada
        indexOwner[_ownerAddress] = owners.push(_ownerAddress)-1;
        ratioOwner[_ownerAddress] = decimalpercent;
        shareOwner[_ownerAddress][_ownerAddress] = decimalpercent;

        shareOwners.push(address(0x0));  //posicao 0 zerada

        borderFactory = BorderFactory(_borderFactory);
        borders.push(address(0x0));  //posicao 0 zerada
        usdAddress = _usdAddress;
    }
    
    modifier onlyOwner {
        require(indexOwner[msg.sender] > 0, "Only owner");
        _;
    }

    function listOwners() public view returns (address[] memory) {
        return owners;
    }

    function listBorders() public view returns (address[] memory) {
        return borders;
    }
    
    function listShareOwners() public view returns (address[] memory) {
        return shareOwners;
    }

    function inBorderFactory (address _address) public view returns (bool) {
        return borderFactory.inBorderFactory (_address);
    }


    event SetRatioOwner (address indexed _from, address indexed _to, uint256 _ratio);
    event SetRatioShare (address indexed _from, address indexed _to, uint256 _ratio);
    event SetBorderShare (address indexed _from, address indexed _to, uint256 _ratio);
    event AddOwner (address indexed _address);
    event RemoveOwner (address indexed _address);
    event AddShareOwner (address indexed _address);
    event RemoveShareOwner (address indexed _address);
    event AddBorder (address indexed _address);
    event RemoveBorder (address indexed _address);


    function setRatioOwner (address _address, uint256 _ratio) public onlyOwner {
        require(!inBorderFactory(_address), "Border can not have a RatioOwner");
        require(_ratio <= ratioOwner[msg.sender], "value greater than owner's ratio");

        ratioOwner[msg.sender] = ratioOwner[msg.sender].sub(_ratio);
        ratioOwner[_address] = ratioOwner[_address].add(_ratio);
        if (indexOwner[_address] == 0) {
            indexOwner[_address] = owners.push(_address)-1;
            emit AddOwner(_address);
        }

        if (ratioOwner[msg.sender] == 0) {
            removeOwner (msg.sender);
        }
        
        //Atualiza o shareOwner
        shareOwner[_address][_address] = decimalpercent;
        ratioShareOwner[_address] = decimalpercent;
        emit SetRatioOwner (msg.sender, _address, _ratio);
    }

    function removeOwner(address _address) internal returns (bool) {
        //Retirar do array Owner        
        uint256 indexToDelete = indexOwner[_address];
        address addressToMove = owners[owners.length-1];
        indexOwner[addressToMove] = indexToDelete;
        owners[indexToDelete] = addressToMove;
        owners.length--;
        emit RemoveOwner(_address);
        return true;
    }

    function removeShareOwner(address _address) internal returns (bool) {
        //Retirar do array ShareOwner
        uint256 indexToDelete = indexShareOwner[_address];
        address addressToMove = shareOwners[owners.length-1];
        indexShareOwner[addressToMove] = indexToDelete;
        shareOwners[indexToDelete] = addressToMove;
        shareOwners.length--;
        emit RemoveShareOwner(_address);
        return true;
    }

    function removeBorder(address _address) internal returns (bool) {
        //Retirar do array Border
        uint256 indexToDelete = indexBorder[_address];
        address addressToMove = borders[borders.length-1];
        indexBorder[addressToMove] = indexToDelete;
        borders[indexToDelete] = addressToMove;
        borders.length--;
        emit RemoveBorder(_address);
        return true;
    }

    function setRatioShare (address _from, address _to, uint256 _ratio) public onlyOwner  {

        //_from é uma borda?
        if (inBorderFactory(_from)) {
            require(_ratio <= shareBorder[msg.sender][_from], "value greater than origin's share");

            shareBorder[msg.sender][_from] = shareBorder[msg.sender][_from].sub(_ratio);
            ratioBorder[_from] = ratioBorder[_from].sub(ratioOwner[msg.sender].mul(_ratio).div(decimalpercent));
            if (ratioBorder[_from] == 0) {
                //Significa que todos os owners retiraram sua parte para a borda.
                removeBorder (_from);
            }
            emit SetBorderShare (_from, _to, _ratio);
        }
        else {
            require(_ratio <= shareOwner[msg.sender][_from], "value greater than origin's share");

            shareOwner[msg.sender][_from] = shareOwner[msg.sender][_from].sub(_ratio);
            if (msg.sender != _from) {
                ratioShareOwner[_from] = ratioShareOwner[_from].sub(ratioOwner[msg.sender].mul(_ratio).div(decimalpercent));
                if (ratioShareOwner[_from] == 0) {
                    //Significa que todos os owners retiraram sua parte para a borda.
                    removeShareOwner (_from);
                }
            }
            emit SetRatioShare (_from, _to, _ratio);
        }

        //_to é uma borda?
        if (inBorderFactory(_to)) {
            if (ratioBorder[_to] == 0) {
                //A borda não recebia nada antes do movimento, então inclui a borda na lista que recebe deste movimento.
                //isBorder[_to] = true;
                indexBorder[_to] = borders.push(_to)-1;
                emit AddBorder (_to);
            }
            
            shareBorder[msg.sender][_to] = shareBorder[msg.sender][_to].add(_ratio);
            ratioBorder[_to] = ratioBorder[_to].add(ratioOwner[msg.sender].mul(_ratio).div(decimalpercent));
            emit SetBorderShare (_from, _to, _ratio);
        }
        else {
            if (ratioShareOwner[_to] == 0) {
                //O nó não recebia nada antes do movimento, então inclui o nó na lista que recebe deste movimento.
                indexShareOwner[_to] = shareOwners.push(_to)-1;
                emit AddShareOwner (_to);
            }

            shareOwner[msg.sender][_to] = shareOwner[msg.sender][_to].add(_ratio);
            ratioShareOwner[_to] = ratioShareOwner[_to].add(ratioOwner[msg.sender].mul(_ratio).div(decimalpercent));
            emit SetRatioShare (_from, _to, _ratio);
        }
    }


    event Incoming(address indexed from, uint256 value, string description);
    event BorderIncoming(address indexed from, address indexed to, uint256 value, string description);
    event ShareIncoming(address indexed from, address indexed to, uint256 value, string description);

    function reportIncoming (uint256 _value, string memory _description) public onlyOwner {

        emit Incoming(msg.sender, _value, _description);

        uint256 valueAux = 0;

        for (uint256 o = 1; o < owners.length; o++) {
            //Aviso de entrada para as bordas
            for (uint256 b = 1; b < borders.length; b++) {
                valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareBorder[owners[o]][borders[b]]).div(decimalpercent);
                if (valueAux > 0)
                    emit BorderIncoming (owners[o], borders[b], valueAux, _description);
            }

            valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareOwner[owners[o]][owners[o]]).div(decimalpercent);
            if (valueAux > 0)
                emit ShareIncoming (owners[o], owners[o], valueAux, _description);

            //Aviso de entrada para os nos
            for (uint256 n = 1; n < shareOwners.length; n++) {
                valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareOwner[owners[o]][shareOwners[n]]).div(decimalpercent);
                if (valueAux > 0)
                    emit ShareIncoming (owners[o], shareOwners[n], valueAux, _description);
            }
        }
    }


    event TransferToBorder(address indexed from, address indexed to, uint256 value, string description);
    event TransferToOwner(address indexed from, address indexed to, uint256 value, string description);
    event TransferToShare(address indexed from, address indexed to, uint256 value, string description);

    function reportToTransfer (uint256 _value, string memory _description) public onlyOwner {

        emit Incoming(msg.sender, _value, _description);

        uint256 valueTotal = 0;
        uint256 valueAux = 0;

        // O que o sender tem que mandar para cada um (permanent owner), já subtraindo as bordas?
        for (uint256 o = 1; o < owners.length; o++) {
            valueTotal = 0;
            for (uint256 b = 1; b < borders.length; b++) {
                valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareBorder[owners[o]][borders[b]]).div(decimalpercent);
                valueTotal = valueTotal.add(valueAux);
            }

            if (owners[o] == msg.sender) {
                //Entrada para ele mesmo
                valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareOwner[owners[o]][owners[o]]).div(decimalpercent);
                emit TransferToOwner (msg.sender, owners[o], valueAux, _description);

                //Aviso de entrada para os nos
                for (uint256 n = 1; n < shareOwners.length; n++) {
                    valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareOwner[owners[o]][shareOwners[n]]).div(decimalpercent);
                    if (valueAux > 0)
                        emit TransferToShare (owners[o], shareOwners[n], valueAux, _description);
                }
            }
            else {
                //Quando o sender não é o owner
                valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).sub(valueTotal);
                emit TransferToOwner (msg.sender, owners[o], valueAux, _description);
            }
        }

        //A partir do sender, verificar tudo o que ele tem que mandar para as bordas, mesmo em nome dos outros.
        for (uint256 b = 1; b < borders.length; b++) {
            valueTotal = 0;

            for (uint256 o = 1; o < owners.length; o++) {
                //Verifica se o owner quer enviar para a borda
                if (shareBorder[owners[o]][borders[b]] > 0) {
                    valueAux = _value.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareBorder[owners[o]][borders[b]]).div(decimalpercent);
                    valueTotal = valueTotal.add(valueAux);
                }
            }
            if (valueTotal > 0){
                emit TransferToBorder (msg.sender, borders[b], valueTotal, _description);
            }
        }

    }


    address[] private borderFroms;
    uint256[] private borderValues;

    function borderIncoming (uint256 _total, uint256 _borderAmount) public onlyOwner {
        //Fazer o approve do USD, para que seja distribuido aqui
        SolUSD solUSD = SolUSD(usdAddress);
        Border border;
        require(solUSD.transferFrom(msg.sender, address(this), _borderAmount), "Can not transfer to moviment");

        //valueTotal, valueBorder, valueAux;
        uint256[3] memory valuesAux;
        valuesAux[0] = 0;
        valuesAux[1] = 0;
        valuesAux[2] = 0;

        for (uint256 b = 1; b < borders.length; b++) {
            valuesAux[1] = 0;

            for (uint256 o = 1; o < owners.length; o++) {
                //Verifica se o owner quer enviar para a borda
                if (shareBorder[owners[o]][borders[b]] > 0) {
                    valuesAux[2] = _total.mul(ratioOwner[owners[o]]).div(decimalpercent).mul(shareBorder[owners[o]][borders[b]]).div(decimalpercent);
                    valuesAux[1] = valuesAux[1].add(valuesAux[2]);

                    borderFroms.push(owners[o]);
                    borderValues.push(valuesAux[2]);
                }
            }

            if (valuesAux[1] > 0) {
                valuesAux[0] = valuesAux[0].add(valuesAux[1]);
                solUSD.approve(borders[b], valuesAux[1]);
                border = Border(borders[b]);
                border.depositUSD (valuesAux[1], borderFroms, borderValues);
            }

            delete borderFroms;
            delete borderValues;
        }

        //Sobrou troco? devolve para o sender
        valuesAux[2] = _borderAmount.sub(valuesAux[0]);
        if (valuesAux[2] > 0) {
            solUSD.transfer(msg.sender, valuesAux[2]);
        }
    }

}


contract MovimentFactory {
    // Syntropy By Solange Gueiros

    address[] public moviments;
    mapping (address => bool) public isMoviment;
    address public usdAddress;
    address public borderFactory;

    constructor(address _usdAddress, address _borderFactory) public {
        usdAddress = _usdAddress;
        borderFactory = _borderFactory;
    }

    function inMovimentFactory (address _address) public view returns (bool) {
        return (isMoviment[_address]);
    }

    function listMoviments() public view returns (address[] memory) {
        return moviments;
    }

    event CreateMoviment (address indexed _address, string _name);

    function createMoviment (string memory _name) public returns (address) {
        Moviment moviment = new Moviment (_name, borderFactory, usdAddress, msg.sender);
        moviments.push(address(moviment));
        isMoviment[address(moviment)] = true;
        emit CreateMoviment (address(moviment), _name);
        return address(moviment);
    }
}



library SafeMath {
    //By OpenZeppelin

    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}