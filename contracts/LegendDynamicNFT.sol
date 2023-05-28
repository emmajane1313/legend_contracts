// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./LegendKeeper.sol";
import "./LegendAccessControl.sol";

contract LegendDynamicNFT is ERC721 {
    using Counters for Counters.Counter;
    uint256 private _editionAmount;
    uint256 private _currentCounter;
    uint256 private _maxSupply;
    string[] private _URIArray;
    string private _myBaseURI;
    address private _deployerAddress;

    mapping(address => bool) private _collectorClaimedNFT;
    mapping(address => uint256) private _collectorMapping;
    mapping(uint256 => string) private _tokenURIs;

    Counters.Counter private _tokenIdCounter;
    ICollectNFT private _collectNFT;
    ILensHubProxy private _lensHubProxy;
    LegendKeeper private _legendKeeper;
    LegendAccessControl private _legendAccessControl;

    event TokenURIUpdated(
        uint256 indexed tokenId,
        string newURI,
        address updater
    );

    modifier onlyAdmin() {
        require(
            _legendAccessControl.isAdmin(msg.sender),
            "LegendAccessControl: Only admin can perform this action"
        );
        _;
    }

    modifier onlyKeeper() {
        require(
            msg.sender == address(_legendKeeper),
            "LegendDynamicNFT: Only the Keeper Contract can perform this action"
        );
        _;
    }

    modifier onlyCollector() {
        require(
            _collectNFT.balanceOf(msg.sender) > 0,
            "LegendDynamicNFT: Only Publication Collectors can perform this action"
        );
        _;
    }

    constructor(
        address _legendAccessControlAddress,
        address _lensHubProxyAddress,
        string[] memory _URIArrayValue,
        uint256 _editionAmountValue
    ) ERC721("LegendDynamicNFT", "LNFT") {
        _editionAmount = _editionAmountValue;
        _URIArray = _URIArrayValue;
        _currentCounter = 0;

        _lensHubProxy = ILensHubProxy(_lensHubProxyAddress);
        _legendAccessControl = LegendAccessControl(_legendAccessControlAddress);
        _myBaseURI = _URIArray[0];
    }

    function safeMint(address _to) external onlyCollector {
        require(
            !_collectorClaimedNFT[msg.sender],
            "LegendDynamicNFT: Only 1 NFT can be claimed per unique collector."
        );

        require(
            _tokenIdCounter.current() < _maxSupply,
            "LegendDynamicNFT: Cannot mint above the max supply."
        );

        uint256 _tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(_to, _tokenId);

        _collectorClaimedNFT[msg.sender] = true;
        _collectorMapping[msg.sender] = _lensHubProxy.defaultProfile(
            _deployerAddress
        );
    }

    function updateMetadata(uint256 _totalAmountOfCollects)
        external
        onlyKeeper
    {
        if (_totalAmountOfCollects > _editionAmount) return;

        _currentCounter += _totalAmountOfCollects;

        // update new uri for all tokenids
        _myBaseURI = _URIArray[_currentCounter];
    }

    function _burn(uint256 _tokenId) internal override {
        super._burn(_tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _myBaseURI;
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return _myBaseURI;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        override
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    function setLegendKeeperContract(address _legendKeeperContract)
        public
        onlyAdmin
    {
        _legendKeeper = LegendKeeper(_legendKeeperContract);
    }

    function setCollectNFTAddress(address _collectNFTAddress)
        external
        onlyKeeper
    {
        require(address(_collectNFT) == address(0));
        _collectNFT = ICollectNFT(_collectNFTAddress);
    }

    function getEditionAmount() public view returns (uint256) {
        return _editionAmount;
    }

    function getCurrentCounter() public view returns (uint256) {
        return _currentCounter;
    }

    function getCollectorClaimedNFT(address _collectorAddress)
        public
        view
        returns (bool)
    {
        return _collectorClaimedNFT[_collectorAddress];
    }

    function getCollectorMapping(address _collectorAddress)
        public
        view
        returns (uint256)
    {
        return _collectorMapping[_collectorAddress];
    }

    function getMaxSupply() public view returns (uint256) {
        return _maxSupply;
    }
}
