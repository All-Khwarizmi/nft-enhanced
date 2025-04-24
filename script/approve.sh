#!/bin/bash
# Script pour approuver une adresse pour un NFT

# Vérification des arguments
if [ "$#" -lt 5 ]; then
    echo "Usage: $0 NFT_ADDRESS TOKEN_ID TO_ADDRESS RPC_URL PRIVATE_KEY"
    exit 1
fi

NFT_ADDRESS=$1
TOKEN_ID=$2
TO_ADDRESS=$3
RPC_URL=$4
PRIVATE_KEY=$5

# Vérification que le token existe
TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
if [ "$TOKEN_ID" -ge "$TOTAL_SUPPLY" ]; then
    echo "Erreur: Le token #$TOKEN_ID n'existe pas. Offre actuelle: $TOTAL_SUPPLY"
    exit 1
fi

# Récupération de l'adresse du sender
FROM_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

# Vérification que le sender est le propriétaire ou un opérateur
OWNER=$(cast call $NFT_ADDRESS "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL 2>/dev/null)
if [ -z "$OWNER" ] || [ "$OWNER" = "0x" ]; then
    echo "Erreur: Impossible de récupérer le propriétaire. Le token n'existe peut-être pas."
    exit 1
fi

IS_OPERATOR=$(cast call $NFT_ADDRESS "isApprovedForAll(address,address)(bool)" $OWNER $FROM_ADDRESS --rpc-url $RPC_URL)

if [ "$OWNER" != "$FROM_ADDRESS" ] && [ "$IS_OPERATOR" != "true" ]; then
    echo "Erreur: Vous n'êtes pas autorisé à approuver ce token."
    echo "Propriétaire: $OWNER"
    echo "Votre adresse: $FROM_ADDRESS"
    echo "Vous êtes un opérateur: $IS_OPERATOR"
    exit 1
fi

# Vérification de l'approbation actuelle
CURRENT_APPROVED=$(cast call $NFT_ADDRESS "getApproved(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
if [ "$CURRENT_APPROVED" = "$TO_ADDRESS" ]; then
    echo "Cette adresse est déjà approuvée pour ce token."
    exit 0
fi

# Confirmation de l'approbation
echo "Vous êtes sur le point d'approuver $TO_ADDRESS pour le NFT #$TOKEN_ID"
echo "Propriétaire: $OWNER"
if [ "$CURRENT_APPROVED" != "0x0000000000000000000000000000000000000000" ]; then
    echo "Approbation actuelle: $CURRENT_APPROVED (sera remplacée)"
fi
read -p "Confirmer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Approbation annulée."
    exit 1
fi

# Exécution de l'approbation
echo "Approbation de $TO_ADDRESS pour le token #$TOKEN_ID..."
RESULT=$(cast send $NFT_ADDRESS "approve(address,uint256)" $TO_ADDRESS $TOKEN_ID --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Approbation réussie!"
    
    # Vérifier la nouvelle approbation
    NEW_APPROVED=$(cast call $NFT_ADDRESS "getApproved(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
    echo "Nouvelle adresse approuvée pour le token #$TOKEN_ID: $NEW_APPROVED"
else
    echo "Échec de l'approbation. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
fi