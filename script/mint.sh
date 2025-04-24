#!/bin/bash
# Script simplifié pour minter des NFTs

# Vérification des arguments
if [ "$#" -lt 4 ]; then
    echo "Usage: $0 NFT_ADDRESS AMOUNT RPC_URL PRIVATE_KEY"
    exit 1
fi

NFT_ADDRESS=$1
AMOUNT=$2
RPC_URL=$3
PRIVATE_KEY=$4

# Valeur fixe pour 0.01 ETH en wei
FEE="10000000000000000"
FEE_ETH="0.01"

echo "Prix de mint pour chaque NFT: $FEE_ETH ETH"
echo "Montant total à envoyer: $(echo "$AMOUNT * $FEE_ETH" | bc 2>/dev/null || echo "$AMOUNT * 0.01") ETH"

# Calcul direct du montant total en wei
TOTAL_WEI=$((AMOUNT * 10000000000000000))

# Vérification de l'offre actuelle et maximale
TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")
MAX_SUPPLY=$(cast call $NFT_ADDRESS "MAX_SUPPLY()(uint256)" --rpc-url $RPC_URL 2>/dev/null || echo "0")

echo "Offre actuelle: $TOTAL_SUPPLY / $MAX_SUPPLY"

# Exécution de la transaction de mint
echo "Minting $AMOUNT NFT(s)..."
RESULT=$(cast send $NFT_ADDRESS "buyTokens(uint256)" $AMOUNT --value $TOTAL_WEI --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Affichage du résultat simplifié
echo "Transaction envoyée"
echo "Hash de transaction: $(echo "$RESULT" | grep "transactionHash" | awk '{print $2}' 2>/dev/null || echo "Non disponible")"
echo "Statut: $(echo "$RESULT" | grep "status" | awk '{print $2}' 2>/dev/null || echo "Non disponible")"