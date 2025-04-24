# NFT Operations Makefile
.PHONY: deploy mint reveal info check transfer approve withdraw help

# Configuration
# Ajustez ces variables selon votre environnement
RPC_URL ?= http://localhost:8545
PRIVATE_KEY ?= 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
# Adresse du contrat NFT (sera définie après déploiement)
NFT_ADDRESS ?= 

# Paramètres par défaut
AMOUNT ?= 1
TOKEN_ID ?= 0
TO_ADDRESS ?= 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
ETH_AMOUNT ?= 0.01

# Couleurs pour la sortie
GREEN := \033[0;32m
YELLOW := \033[0;33m
CYAN := \033[0;36m
NC := \033[0m # No Color

help:
	@echo "$(CYAN)NFT Opérations Makefile$(NC)"
	@echo "$(YELLOW)Commandes disponibles:$(NC)"
	@echo "  $(GREEN)make deploy$(NC)        - Déploie le contrat NFT"
	@echo "  $(GREEN)make mint$(NC)          - Mint un ou plusieurs NFT (AMOUNT=n)"
	@echo "  $(GREEN)make reveal$(NC)        - Révèle les métadonnées des NFTs"
	@echo "  $(GREEN)make info$(NC)          - Affiche les informations de base du contrat"
	@echo "  $(GREEN)make check TOKEN_ID=n$(NC) - Vérifie les informations d'un token spécifique"
	@echo "  $(GREEN)make transfer TOKEN_ID=n TO_ADDRESS=0x...$(NC) - Transfère un NFT"
	@echo "  $(GREEN)make approve TOKEN_ID=n TO_ADDRESS=0x...$(NC) - Approuve une adresse pour un NFT"
	@echo "  $(GREEN)make withdraw ETH_AMOUNT=n$(NC) - Retire l'ETH en excès"
	@echo "  $(GREEN)make start-withdraw$(NC) - Démarre la période de retrait (owner only)"
	@echo "  $(GREEN)make withdraw-all$(NC)  - Retire tous les ETH collectés (après période de grâce)"
	@echo ""
	@echo "$(YELLOW)Variables:$(NC)"
	@echo "  $(GREEN)RPC_URL$(NC)      - URL RPC (défaut: http://localhost:8545)"
	@echo "  $(GREEN)PRIVATE_KEY$(NC)  - Clé privée pour les transactions"
	@echo "  $(GREEN)NFT_ADDRESS$(NC)  - Adresse du contrat NFT"
	@echo "  $(GREEN)AMOUNT$(NC)       - Nombre de NFT à minter (défaut: 1)"
	@echo "  $(GREEN)TOKEN_ID$(NC)     - ID du token pour les opérations (défaut: 0)"
	@echo "  $(GREEN)TO_ADDRESS$(NC)   - Adresse destinataire (défaut: compte Anvil #1)"
	@echo "  $(GREEN)ETH_AMOUNT$(NC)   - Montant d'ETH en ether (défaut: 0.01)"

deploy:
	@echo "$(YELLOW)Déploiement du contrat NFT...$(NC)"
	@forge script script/DeployNFT.s.sol --rpc-url $(RPC_URL) --private-key $(PRIVATE_KEY) --broadcast
	@echo "$(GREEN)Contrat déployé! Veuillez définir NFT_ADDRESS avec l'adresse du déploiement.$(NC)"

mint:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Minting $(AMOUNT) NFT(s)...$(NC)"
	@script/mint.sh $(NFT_ADDRESS) $(AMOUNT) $(RPC_URL) $(PRIVATE_KEY)

reveal:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Révélation des métadonnées NFT...$(NC)"
	@script/reveal.sh $(NFT_ADDRESS) $(RPC_URL) $(PRIVATE_KEY)

info:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Récupération des informations du contrat...$(NC)"
	@script/info.sh $(NFT_ADDRESS) $(RPC_URL)

check:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Vérification du token $(TOKEN_ID)...$(NC)"
	@script/check_token.sh $(NFT_ADDRESS) $(TOKEN_ID) $(RPC_URL)

transfer:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Transfert du token $(TOKEN_ID) vers $(TO_ADDRESS)...$(NC)"
	@script/transfer.sh $(NFT_ADDRESS) $(TOKEN_ID) $(TO_ADDRESS) $(RPC_URL) $(PRIVATE_KEY)

approve:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Approbation de $(TO_ADDRESS) pour le token $(TOKEN_ID)...$(NC)"
	@script/approve.sh $(NFT_ADDRESS) $(TOKEN_ID) $(TO_ADDRESS) $(RPC_URL) $(PRIVATE_KEY)

withdraw:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Retrait de $(ETH_AMOUNT) ETH...$(NC)"
	@script/withdraw.sh $(NFT_ADDRESS) $(ETH_AMOUNT) $(RPC_URL) $(PRIVATE_KEY)

start-withdraw:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Démarrage de la période de retrait...$(NC)"
	@script/start_withdraw.sh $(NFT_ADDRESS) $(RPC_URL) $(PRIVATE_KEY)

withdraw-all:
	@if [ -z "$(NFT_ADDRESS)" ]; then echo "$(YELLOW)Erreur: NFT_ADDRESS non définie$(NC)" && exit 1; fi
	@echo "$(YELLOW)Retrait de tous les ETH collectés...$(NC)"
	@script/withdraw_all.sh $(NFT_ADDRESS) $(RPC_URL) $(PRIVATE_KEY)