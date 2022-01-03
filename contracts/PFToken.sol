// SPDX-License-Identifier: MIT

/**
    #PFT features: 
    2% fee auto moved to PETFI project wallet
    2% fee auto distribute to all holders
    1% fee burned forever
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PFToken is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;

    struct RValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rBurn;
        uint256 rProject;
    }

    struct TValuesStruct {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tBurn;
        uint256 tProject;
    }

    struct ValuesStruct {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 rBurn;
        uint256 rProject;
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tBurn;
        uint256 tProject;
    }

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    string private _name = "PETFI TOKEN";
    string private _symbol = "PFT";
    uint8 private _decimals = 9;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 248012500 * 10 ** uint256(_decimals); // 248012500
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _tBurnTotal;

    uint256 public _taxFee = 2;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _burnFee = 1;
    uint256 private _previousBurnFee = _burnFee;

    uint256 public _projectFee = 2;
    uint256 private _previousProjectFee = _projectFee;

    address public projectWallet = 0x8b32911c9C027461D0EEEed64881688b9899dBD4;

    uint256 public _maxTxAmount = 40 * 10 ** 6 * 10 ** uint256(_decimals);

    constructor() {
        _rOwned[_msgSender()] = _rTotal;        

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function totalBurn() public view returns (uint256) {
        return _tBurnTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        uint256 rAmount = tAmount * _getRate();
        _rOwned[sender] -= rAmount;
        _rTotal -= rAmount;
        _tFeeTotal += tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            uint256 rAmount = tAmount * _getRate();
            return rAmount;
        } else {
            uint256 rTransferAmount = _getValues(tAmount).rTransferAmount;
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns (uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(account != 0x10ED43C718714eb63d5aA57B78B54704E256024E, 'We can not exclude Pancake router.');
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length < 50, "Excluded list is too long");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _distributeFee(uint256 rFee, uint256 rBurn, uint256 rProject, uint256 tFee, uint256 tBurn, uint256 tProject) private {
        _rTotal -= (rFee + rBurn);
        _tFeeTotal += tFee;
        _tTotal -= tBurn;
        _tBurnTotal += tBurn;

        _rOwned[projectWallet] += rProject;
        if (_isExcluded[projectWallet]) {
            _tOwned[projectWallet] += tProject;
        }
    }

    function _getValues(uint256 tAmount) private view returns (ValuesStruct memory) {
        TValuesStruct memory tvs = _getTValues(tAmount);
        RValuesStruct memory rvs = _getRValues(tAmount, tvs.tFee, tvs.tBurn, tvs.tProject, _getRate());

        return ValuesStruct(
            rvs.rAmount,
            rvs.rTransferAmount,
            rvs.rFee,
            rvs.rBurn,
            rvs.rProject,      
            tvs.tTransferAmount,
            tvs.tFee,
            tvs.tBurn,
            tvs.tProject   
        );
    }

    function _getTValues(uint256 tAmount) private view returns (TValuesStruct memory) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tProject = calculateProjectFee(tAmount);        
        uint256 tTransferAmount = tAmount - tFee - tBurn - tProject;
        return TValuesStruct(tTransferAmount, tFee, tBurn, tProject);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tBurn, uint256 tProject, uint256 currentRate) private view returns (RValuesStruct memory) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 rProject = tProject * currentRate;        
        uint256 rTransferAmount = rAmount - rFee - rBurn - rProject;
        return RValuesStruct(rAmount, rTransferAmount, rFee, rBurn, rProject);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }   

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(
            10**2
        );
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(
            10**2
        );
    }

    function calculateProjectFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_projectFee).div(
            10**2
        );
    }    

    function removeAllFee() private {
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousProjectFee = _projectFee;        
        _taxFee = 0; 
        _burnFee = 0;
        _projectFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;        
        _burnFee = _previousBurnFee;
        _projectFee = _previousProjectFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _tokenTransfer(from, to, amount);
    }    

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount) private {
        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient]) {
            removeAllFee();
        }
        else {
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");
        }

        ValuesStruct memory vs = _getValues(amount);        
        _distributeFee(vs.rFee, vs.rBurn, vs.rProject, vs.tFee, vs.tBurn, vs.tProject);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount, vs);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, vs);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, vs);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount, vs);
        }

        if (_isExcludedFromFee[sender] || _isExcludedFromFee[recipient])
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] -= vs.rAmount;
        _rOwned[recipient] += vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, ValuesStruct memory vs) private {
        _rOwned[sender] -= vs.rAmount;
        _tOwned[recipient] += vs.tTransferAmount;
        _rOwned[recipient] += vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= vs.rAmount;
        _rOwned[recipient] += vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount, ValuesStruct memory vs) private {
        _tOwned[sender] -= tAmount;
        _rOwned[sender] -= vs.rAmount;
        _tOwned[recipient] += vs.tTransferAmount;
        _rOwned[recipient] += vs.rTransferAmount;
        emit Transfer(sender, recipient, vs.tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    //Call this function after finalizing the presale
    function enableAllFees() external onlyOwner() {
        restoreAllFee();
        _previousTaxFee = _taxFee;
        _previousBurnFee = _burnFee;
        _previousProjectFee = _projectFee;
    }

    function disableAllFees() external onlyOwner() {
        removeAllFee();
    }

    function setProjectWallet(address newWallet) external onlyOwner {
        projectWallet = newWallet;
    }

    function setMaxTxAmount(uint256 maxTxAmount) external onlyOwner {
        _maxTxAmount = maxTxAmount;
    }

    function setTaxFee(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setBurnFee(uint256 burnFee) external onlyOwner {
        _burnFee = burnFee;
    }

    function setProjectFee(uint256 projectFee) external onlyOwner {
        _projectFee = projectFee;
    }
}