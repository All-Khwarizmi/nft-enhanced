#!/bin/bash
# Script pour révéler les métadonnées NFT

# Vérification des arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 NFT_ADDRESS RPC_URL PRIVATE_KEY"
    exit 1
fi

NFT_ADDRESS=$1
RPC_URL=$2
PRIVATE_KEY=$3

# Vérification si la collection est déjà révélée
IS_REVEALED=$(cast call $NFT_ADDRESS "isCollectionRevealed()(bool)" --rpc-url $RPC_URL)
if [ "$IS_REVEALED" = "true" ]; then
    echo "La collection est déjà révélée!"
    
    # Afficher l'URI de base actuel
    BASE_URI=$(cast call $NFT_ADDRESS "baseURI()(string)" --rpc-url $RPC_URL)
    echo "Base URI actuel: $BASE_URI"
    exit 0
fi

# Récupération du baseURI depuis le script de déploiement
# Notez que cela suppose que votre script de déploiement utilise cette valeur
# Récupération du baseURI depuis le script de déploiement
DEPLOY_SCRIPT="script/DeployNFT.s.sol"
if [ -f "$DEPLOY_SCRIPT" ]; then
    # Essayer différentes façons d'extraire le baseURI
    BASE_URI=$(grep -o 'baseURI = "[^"]*"' $DEPLOY_SCRIPT | cut -d'"' -f2)
    
    # Si la première méthode échoue, essayer une autre approche
    if [ -z "$BASE_URI" ]; then
        BASE_URI=$(grep -o 'string memory baseURI = "[^"]*"' $DEPLOY_SCRIPT | cut -d'"' -f2)
    fi
    
    # Si toujours pas trouvé, essayer encore une autre approche
    if [ -z "$BASE_URI" ]; then
        BASE_URI=$(grep -o '"https://[^"]*"' $DEPLOY_SCRIPT | head -1 | tr -d '"')
    fi
    
    # Demander à l'utilisateur si rien n'est trouvé
    if [ -z "$BASE_URI" ]; then
        echo "Impossible de trouver le baseURI dans le script de déploiement"
        read -p "Veuillez entrer le baseURI manuellement: " BASE_URI
    else
        echo "baseURI trouvé dans le script de déploiement: $BASE_URI"
    fi
else
    read -p "Veuillez entrer le baseURI pour la révélation: " BASE_URI
fi
# Confirmation du baseURI
echo "Vous êtes sur le point de révéler la collection avec le baseURI suivant:"
echo "$BASE_URI"
read -p "Confirmer? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Révélation annulée."
    exit 1
fi

# Vérification que l'utilisateur est le propriétaire du contrat
OWNER=$(cast call $NFT_ADDRESS "owner()(address)" --rpc-url $RPC_URL)
FROM_ADDRESS=$(cast wallet address --private-key $PRIVATE_KEY)

if [ "$OWNER" != "$FROM_ADDRESS" ]; then
    echo "Erreur: Seul le propriétaire ($OWNER) peut révéler la collection. Vous êtes $FROM_ADDRESS."
    exit 1
fi

# Exécution de la révélation
echo "Révélation de la collection..."
RESULT=$(cast send $NFT_ADDRESS "revealTokenURI(string)" "$BASE_URI" --rpc-url $RPC_URL --private-key $PRIVATE_KEY)

# Vérification de la transaction
TX_STATUS=$(echo "$RESULT" | grep "status" | awk '{print $2}')
if [[ "$TX_STATUS" == "1" ]]; then
    echo "Révélation réussie!"
    
    # Vérifier que la collection est maintenant révélée
    IS_REVEALED=$(cast call $NFT_ADDRESS "isCollectionRevealed()(bool)" --rpc-url $RPC_URL)
    if [ "$IS_REVEALED" = "true" ]; then
        echo "La collection est maintenant officiellement révélée."
        
        # Essayer d'afficher l'URI d'un token (si au moins un token existe)
        TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
        if [ "$TOTAL_SUPPLY" -gt "0" ]; then
            TOKEN_URI=$(cast call $NFT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url $RPC_URL)
            echo "URI du token #0: $TOKEN_URI"
        else
            echo "Aucun token n'a encore été minté."
        fi
    else
        echo "La collection n'a pas été révélée correctement. Vérifiez les paramètres."
    fi
else
    echo "Échec de la révélation. Vérifiez les logs pour plus de détails."
    echo "$RESULT"
fi