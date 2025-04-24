#!/bin/bash
# Script pour retirer l'ETH en excès

# Vérification des arguments
if [ "$#" -lt 5 ]; then
    echo "Usage: $0 NFT_ADDRESS ETH_AMOUNT RPC_URL PRIVATE_KEY"
    exit 1
fi

NFT_ADDRESS=$1
ETH_AMOUNT=$2
RPC_URL=$3
PRIVATE_KEY=$4

# Convertir le montant ETH en wei
WEI_AMOUNT=$(cast --to-wei $ETH_AMOUNT)

# Récupération de l'adresse du sender
FROM_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

# Vérification du solde ETH
ETH_BALANCE=$(cast call $NFT_ADDRESS "ethBalances(address)(uint256)" $FROM_ADDRESS --rpc-url $RPC_URL)
ETH_BALANCE_ETH=$(cast --from-wei $ETH_BALANCE)

if [ "$WEI_AMOUNT" -gt "$ETH_BALANCE" ]; then
    echo "Erreur: Solde insuffisant. Vous avez seulement $ETH_BALANCE_ETH ETH disponible."
    exit 1
fi

# Confirmation du retrait
echo "Vous êtes sur le point de retirer $ETH_AMOUNT ETH"
echo "Solde actuel: $ETH_BALANCE_ETH ETH"
echo "Solde après retrait: $(echo "$ETH_BALANCE_ETH - $ETH_AMOUNT" | bc) ETH"
read -p "Confirmer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Retrait annulé."
    exit 1
fi

# Exécution du retrait
echo "Retrait de $ETH_AMOUNT ETH..."
RESULT=$(cast send $NFT_ADDRESS "withdrawEth(uint256)" $WEI_AMOUNT --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Retrait réussi!"
    
    # Vérifier le nouveau solde
    NEW_BALANCE=$(cast call $NFT_ADDRESS "ethBalances(address)(uint256)" $FROM_ADDRESS --rpc-url $RPC_URL)
    NEW_BALANCE_ETH=$(cast --from-wei $NEW_BALANCE)
    echo "Nouveau solde: $NEW_BALANCE_ETH ETH"
else
    echo "Échec du retrait. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
fi