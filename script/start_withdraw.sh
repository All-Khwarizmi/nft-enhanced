#!/bin/bash
# Script pour démarrer la période de retrait (owner only)

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

# Vérification que le sender est le propriétaire
OWNER=$(cast call $NFT_ADDRESS "owner()(address)" --rpc-url $RPC_URL)
if [ "$OWNER" != "$FROM_ADDRESS" ]; then
    echo "Erreur: Seul le propriétaire ($OWNER) peut initier la période de retrait. Vous êtes $FROM_ADDRESS."
    exit 1
fi

# Confirmation
echo "Vous êtes sur le point de démarrer la période de retrait."
echo "Une fois la période de grâce terminée (1 semaine), le propriétaire pourra retirer tous les ETH collectés."
read -p "Confirmer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Opération annulée."
    exit 1
fi

# Exécution de l'initialisation
echo "Démarrage de la période de retrait..."
RESULT=$(cast send $NFT_ADDRESS "initiateWithdrawalPeriod()" --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Période de retrait initiée avec succès!"
    echo "La période de grâce d'une semaine a commencé."
    
    # Calculer la date de fin
    END_DATE=$(date -d "+1 week" "+%Y-%m-%d %H:%M:%S")
    echo "Vous pourrez retirer les ETH collectés après: $END_DATE"
else
    echo "Échec de l'initialisation. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
fi