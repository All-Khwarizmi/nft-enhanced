#!/bin/bash
# Script pour transférer un NFT

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

# Vérification que le sender est le propriétaire
OWNER=$(cast call $NFT_ADDRESS "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL 2>/dev/null)
if [ -z "$OWNER" ] || [ "$OWNER" = "0x" ]; then
    echo "Erreur: Impossible de récupérer le propriétaire. Le token n'existe peut-être pas."
    exit 1
fi

if [ "$OWNER" != "$FROM_ADDRESS" ]; then
    # Vérifier si le sender est approuvé
    APPROVED=$(cast call $NFT_ADDRESS "getApproved(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
    IS_OPERATOR=$(cast call $NFT_ADDRESS "isApprovedForAll(address,address)(bool)" $OWNER $FROM_ADDRESS --rpc-url $RPC_URL)
    
    if [ "$APPROVED" != "$FROM_ADDRESS" ] && [ "$IS_OPERATOR" != "true" ]; then
        echo "Erreur: Vous n'êtes pas autorisé à transférer ce token."
        echo "Propriétaire: $OWNER"
        echo "Votre adresse: $FROM_ADDRESS"
        echo "Adresse approuvée: $APPROVED"
        echo "Vous êtes un opérateur: $IS_OPERATOR"
        exit 1
    fi
fi

# Confirmation du transfert
echo "Vous êtes sur le point de transférer le NFT #$TOKEN_ID à $TO_ADDRESS"
echo "De: $FROM_ADDRESS"
read -p "Confirmer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Transfert annulé."
    exit 1
fi

# Exécution du transfert
echo "Transfert du token #$TOKEN_ID vers $TO_ADDRESS..."
RESULT=$(cast send $NFT_ADDRESS "transferFrom(address,address,uint256)" $OWNER $TO_ADDRESS $TOKEN_ID --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Transfert réussi!"
    
    # Vérifier le nouveau propriétaire
    NEW_OWNER=$(cast call $NFT_ADDRESS "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
    echo "Nouveau propriétaire du token #$TOKEN_ID: $NEW_OWNER"
    
    # Vérifier que l'approbation est bien effacée
    NEW_APPROVED=$(cast call $NFT_ADDRESS "getApproved(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
    if [ "$NEW_APPROVED" = "0x0000000000000000000000000000000000000000" ]; then
        echo "Approbation réinitialisée comme prévu."
    else
        echo "Attention: L'approbation n'a pas été réinitialisée comme prévu."
        echo "Nouvelle adresse approuvée: $NEW_APPROVED"
    fi
else
    echo "Échec du transfert. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
fi