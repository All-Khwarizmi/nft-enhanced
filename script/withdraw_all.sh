#!/bin/bash
# Script pour retirer tous les ETH collectés (après période de grâce)

# Vérification des arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 NFT_ADDRESS RPC_URL PRIVATE_KEY"
    exit 1
fi

NFT_ADDRESS=$1
RPC_URL=$2
PRIVATE_KEY=$3

# Récupération de l'adresse du sender
FROM_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

# Estimation des ETH collectés
TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
FEE_WEI=$(cast call $NFT_ADDRESS "FEE()(uint256)" --rpc-url $RPC_URL)
WEI_COLLECTED=$(echo "$TOTAL_SUPPLY * $FEE_WEI" | bc)
ETH_COLLECTED=$(cast --from-wei $WEI_COLLECTED)

# Vérification du solde réel du contrat
CONTRACT_BALANCE=$(cast balance $NFT_ADDRESS --rpc-url $RPC_URL)
CONTRACT_BALANCE_ETH=$(cast --from-wei $CONTRACT_BALANCE)

# Confirmation
echo "===== RETRAIT COMPLET DES ETH ====="
echo "Adresse du contrat: $NFT_ADDRESS"
echo "Votre adresse: $FROM_ADDRESS"
echo "Estimation des ETH collectés: $ETH_COLLECTED ETH"
echo "Solde réel du contrat: $CONTRACT_BALANCE_ETH ETH"

echo
echo "ATTENTION: Cette opération ne peut être exécutée que:"
echo "1. Après initiation de la période de retrait (via start-withdraw)"
echo "2. Après expiration du délai de grâce d'une semaine"
echo

read -p "Êtes-vous sûr de vouloir continuer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Retrait annulé."
    exit 1
fi

# Exécution du retrait
echo "Retrait de tous les ETH collectés..."
RESULT=$(cast send $NFT_ADDRESS "withdrawCollectedEth()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Retrait réussi!"
    
    # Vérifier le nouveau solde du contrat
    NEW_BALANCE=$(cast balance $NFT_ADDRESS --rpc-url $RPC_URL)
    NEW_BALANCE_ETH=$(cast --from-wei $NEW_BALANCE)
    ETH_WITHDRAWN=$(echo "$CONTRACT_BALANCE_ETH - $NEW_BALANCE_ETH" | bc)
    
    echo "Montant retiré: $ETH_WITHDRAWN ETH"
    echo "Nouveau solde du contrat: $NEW_BALANCE_ETH ETH"
else
    echo "Échec du retrait. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
    
    # Vérifier si c'est à cause de la période de grâce
    echo
    echo "Causes possibles de l'échec:"
    echo "1. La période de retrait n'a pas été initiée (utilisez make start-withdraw)"
    echo "2. La période de grâce d'une semaine n'est pas encore terminée"
    echo "3. Vous n'êtes pas autorisé à effectuer cette opération"
    echo "4. Une erreur s'est produite lors de la transaction"
fi