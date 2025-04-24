Voici un cheat sheet rapide pour interagir avec votre contrat NFT à l'aide de l'outil Cast, qui fait partie de la suite Foundry.

# Cheat Sheet Cast pour NFT

## Configuration initiale

Définir des variables pour faciliter les commandes:
```bash
# Adresse du contrat NFT déployé
export NFT_ADDRESS=0x...

# Adresse de votre wallet
export MY_ADDRESS=0x...

# URL RPC de votre nœud local Anvil
export RPC_URL=http://localhost:8545
```

## Lecture de données (calls)

### Informations de base
```bash
# Vérifier le nom du NFT
cast call $NFT_ADDRESS "name()" --rpc-url $RPC_URL

# Vérifier le symbole
cast call $NFT_ADDRESS "symbol()" --rpc-url $RPC_URL

# Vérifier l'offre totale
cast call $NFT_ADDRESS "totalSupply()" --rpc-url $RPC_URL

# Vérifier l'offre maximale
cast call $NFT_ADDRESS "MAX_SUPPLY()" --rpc-url $RPC_URL

# Vérifier le prix de frappe (FEE)
cast call $NFT_ADDRESS "FEE()" --rpc-url $RPC_URL
```

### État de la collection
```bash
# Vérifier si la collection est révélée
cast call $NFT_ADDRESS "isCollectionRevealed()" --rpc-url $RPC_URL

# Vérifier le baseURI (si accessible)
cast call $NFT_ADDRESS "baseURI()" --rpc-url $RPC_URL

# Vérifier le propriétaire du contrat
cast call $NFT_ADDRESS "owner()" --rpc-url $RPC_URL
```

### Informations sur les tokens
```bash
# Vérifier le propriétaire d'un token
cast call $NFT_ADDRESS "ownerOf(uint256)(address)" 0 --rpc-url $RPC_URL

# Vérifier le solde d'un utilisateur
cast call $NFT_ADDRESS "balanceOf(address)(uint256)" $MY_ADDRESS --rpc-url $RPC_URL

# Essayer d'accéder au tokenURI (peut échouer si non révélé)
cast call $NFT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url $RPC_URL

# Vérifier l'adresse approuvée pour un token
cast call $NFT_ADDRESS "getApproved(uint256)(address)" 0 --rpc-url $RPC_URL

# Vérifier si un opérateur est approuvé
cast call $NFT_ADDRESS "isApprovedForAll(address,address)(bool)" $MY_ADDRESS $OPERATOR_ADDRESS --rpc-url $RPC_URL
```

## Écriture de données (transactions)

### Minting
```bash
# Minter un NFT en payant la FEE
cast send $NFT_ADDRESS "buyTokens(uint256)" 1 --value 0.01ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Envoyer de l'ETH directement au contrat (utilise la fonction receive)
cast send $NFT_ADDRESS --value 0.01ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### Approbations et transferts
```bash
# Approuver une adresse pour un token spécifique
cast send $NFT_ADDRESS "approve(address,uint256)" $OPERATOR_ADDRESS 0 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Approuver une adresse pour tous les tokens
cast send $NFT_ADDRESS "setApprovalForAll(address,bool)" $OPERATOR_ADDRESS true --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Transférer un token
cast send $NFT_ADDRESS "transferFrom(address,address,uint256)" $MY_ADDRESS $TO_ADDRESS 0 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Transférer un token en toute sécurité
cast send $NFT_ADDRESS "safeTransferFrom(address,address,uint256)" $MY_ADDRESS $TO_ADDRESS 0 --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

### Fonctions administratives
```bash
# Révéler les métadonnées de la collection
cast send $NFT_ADDRESS "revealTokenURI(string)" "https://lime-active-caterpillar-261.mypinata.cloud/ipfs/QmYOUR_CID/" --rpc-url $RPC_URL --private-key $OWNER_PRIVATE_KEY

# Initier la période de retrait
cast send $NFT_ADDRESS "initiateWithdrawalPeriod()" --rpc-url $RPC_URL --private-key $OWNER_PRIVATE_KEY

# Retirer l'ETH collecté (après la période de grâce)
cast send $NFT_ADDRESS "withdrawCollectedEth()" --rpc-url $RPC_URL --private-key $OWNER_PRIVATE_KEY

# Définir un propriétaire en attente
cast send $NFT_ADDRESS "setPendingOwner(address)" $NEW_OWNER_ADDRESS --rpc-url $RPC_URL --private-key $OWNER_PRIVATE_KEY

# Accepter la propriété
cast send $NFT_ADDRESS "acceptOwnership()" --rpc-url $RPC_URL --private-key $NEW_OWNER_PRIVATE_KEY
```

### Retrait des soldes ETH
```bash
# Vérifier le solde ETH d'un utilisateur
cast call $NFT_ADDRESS "ethBalances(address)(uint256)" $MY_ADDRESS --rpc-url $RPC_URL

# Retirer le solde ETH
cast send $NFT_ADDRESS "withdrawEth(uint256)" 0.005ether --rpc-url $RPC_URL --private-key $PRIVATE_KEY
```

## Astuces supplémentaires

### Calcul d'un hash pour baseURI
```bash
# Calculer le hash keccak256 d'une chaîne (pour baseURIHash)
cast keccak "ipfs://example/"
```

### Conversion d'unités
```bash
# Convertir ETH en wei
cast --to-wei 0.01eth

# Convertir wei en ETH
cast --from-wei 10000000000000000
```

### Obtenir les logs d'événements
```bash
# Obtenir les événements Transfer
cast logs --from-block 0 --to-block latest $NFT_ADDRESS "Transfer(address,address,uint256)" --rpc-url $RPC_URL
```

N'oubliez pas de remplacer les variables (`$NFT_ADDRESS`, `$MY_ADDRESS`, etc.) par vos propres valeurs, ou de les exporter comme suggéré au début.