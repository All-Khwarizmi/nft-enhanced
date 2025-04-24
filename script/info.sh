#!/bin/bash
# Script pour afficher les informations de base du contrat NFT

# Vérification des arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 NFT_ADDRESS RPC_URL"
    exit 1
fi

NFT_ADDRESS=$1
RPC_URL=$2

# Fonction pour une sortie formatée
print_info() {
    printf "%-20s: %s\n" "$1" "$2"
}

echo "=== INFORMATIONS DU CONTRAT NFT ==="
echo "Adresse: $NFT_ADDRESS"

# Informations de base
NAME=$(cast call $NFT_ADDRESS "name()(string)" --rpc-url $RPC_URL)
print_info "Nom" "$NAME"

SYMBOL=$(cast call $NFT_ADDRESS "symbol()(string)" --rpc-url $RPC_URL)
print_info "Symbole" "$SYMBOL"

TOTAL_SUPPLY=$(cast call $NFT_ADDRESS "totalSupply()(uint256)" --rpc-url $RPC_URL)
print_info "Offre actuelle" "$TOTAL_SUPPLY"

MAX_SUPPLY=$(cast call $NFT_ADDRESS "MAX_SUPPLY()(uint256)" --rpc-url $RPC_URL)
print_info "Offre maximum" "$MAX_SUPPLY"

FEE_WEI=$(cast call $NFT_ADDRESS "FEE()(uint256)" --rpc-url $RPC_URL)
# FEE_ETH=$(cast --from-wei $FEE_WEI)
# print_info "Prix de mint" "$FEE_WEI  ETH"

OWNER=$(cast call $NFT_ADDRESS "owner()(address)" --rpc-url $RPC_URL)
print_info "Propriétaire" "$OWNER"

# État de la collection
IS_REVEALED=$(cast call $NFT_ADDRESS "isCollectionRevealed()(bool)" --rpc-url $RPC_URL)
print_info "Collection révélée" "$IS_REVEALED"

if [ "$IS_REVEALED" = "true" ]; then
    BASE_URI=$(cast call $NFT_ADDRESS "baseURI()(string)" --rpc-url $RPC_URL)
    print_info "Base URI" "$BASE_URI"
    
    # Afficher un exemple d'URI de token si des tokens existent
    if [ "$TOTAL_SUPPLY" -gt "0" ]; then
        TOKEN_URI=$(cast call $NFT_ADDRESS "tokenURI(uint256)(string)" 0 --rpc-url $RPC_URL 2>/dev/null)
        if [ -n "$TOKEN_URI" ]; then
            print_info "Exemple Token URI" "$TOKEN_URI"
        fi
    fi
fi

echo
echo "=== INFORMATIONS FINANCIÈRES ==="

# Calculer le montant total des ETH collectés (approximation)
WEI_COLLECTED=$(echo "$TOTAL_SUPPLY * $FEE_WEI" | bc)
ETH_COLLECTED=$(cast --from-wei $WEI_COLLECTED)
print_info "ETH collectés (approx)" "$ETH_COLLECTED ETH"

# Vérifier le solde ETH du contrat
CONTRACT_BALANCE=$(cast balance $NFT_ADDRESS --rpc-url $RPC_URL)
CONTRACT_BALANCE_ETH=$(cast --from-wei $CONTRACT_BALANCE)
print_info "Solde du contrat" "$CONTRACT_BALANCE_ETH ETH"

echo
echo "=== RÉCAPITULATIF DES TOKENS ==="
print_info "Tokens mintés" "$TOTAL_SUPPLY / $MAX_SUPPLY"
PERCENT_MINTED=$(echo "scale=2; $TOTAL_SUPPLY * 100 / $MAX_SUPPLY" | bc)
print_info "Pourcentage minté" "$PERCENT_MINTED%"

echo
echo "=== INTERACTIONS POSSIBLES ==="

if [ "$TOTAL_SUPPLY" -lt "$MAX_SUPPLY" ]; then
    REMAINING=$((MAX_SUPPLY - TOTAL_SUPPLY))
    echo "- Vous pouvez minter jusqu'à $REMAINING tokens supplémentaires"
    echo "  make mint AMOUNT=$REMAINING NFT_ADDRESS=$NFT_ADDRESS"
fi

if [ "$IS_REVEALED" = "false" ]; then
    echo "- La collection n'est pas encore révélée"
    echo "  make reveal NFT_ADDRESS=$NFT_ADDRESS"
fi

if [ "$TOTAL_SUPPLY" -gt "0" ]; then
    echo "- Vérifiez les détails d'un token spécifique"
    echo "  make check TOKEN_ID=0 NFT_ADDRESS=$NFT_ADDRESS"
fi

echo "- Transfert d'un token"
echo "  make transfer TOKEN_ID=0 TO_ADDRESS=0x... NFT_ADDRESS=$NFT_ADDRESS"