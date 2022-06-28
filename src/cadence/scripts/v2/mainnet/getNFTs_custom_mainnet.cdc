import NonFungibleToken from 0x1d7e57aa55817448
import MatrixMarket from 0x2162bbe13ade251e

pub struct NFTCollection {
    pub let owner: Address
    pub let nfts: [NFTData]

    init(owner: Address) {
        self.owner = owner
        self.nfts = []
    }
}

pub struct NFTData {
    pub let contract: NFTContractData
    pub let id: UInt64
    pub let uuid: UInt64?
    pub let title: String?
    pub let description: String?
    pub let external_domain_view_url: String?
    pub let token_uri: String?
    pub let media: [NFTMedia?]
    pub let metadata: {String: String?}

    init(
        contract: NFTContractData,
        id: UInt64,
        uuid: UInt64?,
        title: String?,
        description: String?,
        external_domain_view_url: String?,
        token_uri: String?,
        media: [NFTMedia?],
        metadata: {String: String?}
    ) {
        self.contract = contract
        self.id = id
        self.uuid = uuid
        self.title = title
        self.description = description
        self.external_domain_view_url = external_domain_view_url
        self.token_uri = token_uri
        self.media = media
        self.metadata = metadata
    }
}

pub struct NFTContractData {
    pub let name: String
    pub let address: Address
    pub let storage_path: String
    pub let public_path: String
    pub let public_collection_name: String
    pub let external_domain: String

    init(
        name: String,
        address: Address,
        storage_path: String,
        public_path: String,
        public_collection_name: String,
        external_domain: String
    ) {
        self.name = name
        self.address = address
        self.storage_path = storage_path
        self.public_path = public_path
        self.public_collection_name = public_collection_name
        self.external_domain = external_domain
    }
}

pub struct NFTMedia {
    pub let uri: String?
    pub let mimetype: String?

    init(
        uri: String?,
        mimetype: String?
    ) {
        self.uri = uri
        self.mimetype = mimetype
    }
}

pub fun main(ownerAddress: Address, ids: {String:[UInt64]}): [NFTData?] {
    let NFTs: [NFTData?] = []
    let owner = getAccount(ownerAddress)

    for key in ids.keys {
        for id in ids[key]! {
            var d: NFTData? = nil

            switch key {
                case "MatrixMarket": d = getMatrixMarket(owner: owner, id: id)
                default:
                    panic("adapter for NFT not found: ".concat(key))
            }
            NFTs.append(d)
        }
    }

    return NFTs
}

// https://flow-view-source.com/mainnet/account/0x2162bbe13ade251e/contract/MatrixMarket
pub fun getMatrixMarket(owner: PublicAccount, id: UInt64): NFTData? {
    let contract = NFTContractData(
        name: "MatrixMarket",
        address: 0x2162bbe13ade251e,
        storage_path: "MatrixMarket.CollectionStoragePath",
        public_path: "MatrixMarket.CollectionPublicPath",
        public_collection_name: "NonFungibleToken.CollectionPublic, NonFungibleToken.Receiver, MatrixMarket.MatrixMarketCollectionPublic", // interfaces required for initialization
        external_domain: "https://matrixworld.org",
    )

    let col= owner
        .getCapability(MatrixMarket.CollectionPublicPath)
        .borrow<&{MatrixMarket.MatrixMarketCollectionPublic, NonFungibleToken.CollectionPublic}>()
        ?? panic("NFT Collection not found")
    if col == nil { return nil }

    let nft = col!.borrowMatrixMarket(id: id)
    if nft == nil { return nil }

    let metadata = nft!.getRawMetadata()
    let rawMetadata: {String:String?} = {}
    for key in metadata.keys {
        rawMetadata.insert(key: key, metadata[key])
    }

    return NFTData(
        contract: contract,
        id: id,
        uuid: nft!.uuid,
        title: metadata["name"],
        description: metadata["description"],
        external_domain_view_url: "https://matrixworld.org/profile",
        token_uri: nil,
        media: [
            NFTMedia(uri: metadata["displayUrl"], mimetype: metadata["displayUrlMediaType"]),
            NFTMedia(uri: metadata["contentUrl"], mimetype: metadata["contentUrlMediaType"])
        ],
        metadata: rawMetadata
    )
}