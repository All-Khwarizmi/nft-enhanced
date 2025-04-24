#!/bin/bash
# Script pour vérifier les informations d'un token spécifique

# Vérification des arguments
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 NFT_ADDRESS TOKEN_ID RPC_URL"
    exit 1
fi

NFT_ADDRESS=$1
TOKEN_ID=$2
RPC_URL=$3

# Fonction pour une sortie formatée
print_info() {
    printf "%-20s: %s\n" "$1" "$2"
}

echo "=== DÉTAILS DU TOKEN #$TOKEN_ID ==="
echo "Contrat: $NFT_ADDRESS"

# Vérification si le token existe
TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
if [ "$TOKEN_ID" -ge "$TOTAL_SUPPLY" ]; then
    echo "Erreur: Le token #$TOKEN_ID n'existe pas. Offre actuelle: $TOTAL_SUPPLY"
    exit 1
fi

# Informations du token
OWNER=$(cast call $NFT_ADDRESS "ownerOf(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL 2>/dev/null)
if [ -z "$OWNER" ] || [ "$OWNER" = "0x" ]; then
    echo "Erreur: Impossible de récupérer le propriétaire. Le token n'existe peut-être pas."
    exit 1
fi

print_info "Propriétaire" "$OWNER"

# Vérifier l'approbation
APPROVED=$(cast call $NFT_ADDRESS "getApproved(uint256)(address)" $TOKEN_ID --rpc-url $RPC_URL)
if [ "$APPROVED" = "0x0000000000000000000000000000000000000000" ]; then
    print_info "Approuvé pour" "Aucun"
else
    print_info "Approuvé pour" "$APPROVED"
fi

# Vérifier l'URI du token
IS_REVEALED=$(cast call $NFT_ADDRESS "isCollectionRevealed()(bool)" --rpc-url $RPC_URL)
if [ "$IS_REVEALED" = "true" ]; then
    TOKEN_URI=$(cast call $NFT_ADDRESS "tokenURI(uint256)(string)" $TOKEN_ID --rpc-url $RPC_URL 2>/dev/null)
    if [ -n "$TOKEN_URI" ]; then
        print_info "URI du token" "$TOKEN_URI"
        
        # Tenter de récupérer les métadonnées si l'URI est accessible
        if [[ "$TOKEN_URI" == http* ]]; then
            echo
            echo "Tentative de récupération des métadonnées..."
            METADATA=$(curl -s "$TOKEN_URI")
            if [ -n "$METADATA" ]; then
                echo "Métadonnées:"
                echo "$METADATA" | jq . 2>/dev/null || echo "$METADATA"
                
                # Extraire l'URL de l'image si présente
                IMAGE_URL=$(echo "$METADATA" | grep -o '"image":.*' | cut -d'"' -f4)
                if [ -n "$IMAGE_URL" ]; then
                    print_info "URL de l'image" "$IMAGE_URL"
                fi
            else
                echo "Impossible de récupérer les métadonnées. URI peut-être inaccessible."
            fi
        fi
    else
        print_info "URI du token" "Non disponible"
    fi
else
    print_info "URI du token" "Collection non révélée"
fi

echo
echo "=== ACTIONS POSSIBLES ==="
echo "- Transférer ce token:"
echo "  make transfer TOKEN_ID=$TOKEN_ID TO_ADDRESS=0x... NFT_ADDRESS=$NFT_ADDRESS"
echo
echo "- Approuver une adresse pour ce token:"
echo "  make approve TOKEN_ID=$TOKEN_ID TO_ADDRESS=0x... NFT_ADDRESS=$NFT_ADDRESS"