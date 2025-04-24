# NFT Contract Project

Ce projet contient un contrat NFT complet conforme à la norme ERC-721, avec des fonctionnalités avancées comme le minting payant, la révélation programmée des métadonnées, et un système de gestion des retraits ETH. Il inclut un ensemble complet de scripts pour simplifier le déploiement et l'interaction avec le contrat.

## Table des matières

- [NFT Contract Project](#nft-contract-project)
  - [Table des matières](#table-des-matières)
  - [Prérequis](#prérequis)
  - [Structure du projet](#structure-du-projet)
  - [Installation](#installation)
  - [Configuration](#configuration)
  - [Utilisation](#utilisation)
    - [Déploiement](#déploiement)
    - [Minting](#minting)
    - [Révélation](#révélation)
    - [Transfert](#transfert)
    - [Autres fonctionnalités](#autres-fonctionnalités)
  - [Métadonnées et IPFS](#métadonnées-et-ipfs)
    - [Format des métadonnées](#format-des-métadonnées)
    - [Structure IPFS](#structure-ipfs)
    - [Exemple de workflow](#exemple-de-workflow)
  - [Tests](#tests)
  - [Sécurité](#sécurité)
  - [Licence](#licence)

## Prérequis

- [Foundry](https://book.getfoundry.sh/getting-started/installation)
- [jq](https://stedolan.github.io/jq/download/) (pour traiter les JSON)
- [bc](https://www.gnu.org/software/bc/) (pour les calculs dans les scripts)

## Structure du projet

```
.
├── src/
│   └── NFT.sol                # Contrat principal NFT
├── script/
│   ├── DeployNFT.s.sol        # Script de déploiement
│   ├── mint.sh                # Script pour minter des NFTs
│   ├── reveal.sh              # Script pour révéler les métadonnées
│   ├── info.sh                # Affiche les informations du contrat
│   ├── check_token.sh         # Vérifie les détails d'un token
│   ├── transfer.sh            # Transfère un NFT
│   ├── approve.sh             # Approuve une adresse pour un NFT
│   ├── withdraw.sh            # Retire l'ETH en excès
│   ├── start_withdraw.sh      # Démarre la période de retrait
│   └── withdraw_all.sh        # Retire tous les ETH collectés
├── test/                      # Tests du contrat
└── Makefile                   # Automatisation des tâches
```

## Installation

1. Clonez ce dépôt :

   ```bash
   git clone <URL_DU_DÉPÔT>
   cd nft-project
   ```

2. Installez les dépendances Foundry :

   ```bash
   forge install
   ```

3. Rendez les scripts exécutables :
   ```bash
   chmod +x script/*.sh
   ```

## Configuration

Avant d'utiliser les scripts, vous devez configurer quelques variables dans le Makefile ou les définir lors de l'exécution :

- `RPC_URL` : URL RPC de votre nœud (par défaut: http://localhost:8545 pour Anvil)
- `PRIVATE_KEY` : Clé privée pour signer les transactions
- `NFT_ADDRESS` : Adresse du contrat NFT après déploiement

## Utilisation

Le projet inclut un Makefile qui simplifie les opérations courantes. Utilisez `make help` pour voir toutes les commandes disponibles.

### Déploiement

1. Démarrez un nœud local Anvil (si nécessaire) :

   ```bash
   anvil
   ```

2. Déployez le contrat NFT :

   ```bash
   make deploy
   ```

3. Notez l'adresse du contrat et configurez-la pour les futures commandes :
   ```bash
   export NFT_ADDRESS=0x...
   ```

### Minting

Minter un NFT :

```bash
chmod +x script/mint.sh
make mint
make mint NFT_ADDRESS=0x0165878A594ca255338adfa4d48449f69242Eb8F RPC_URL=http://localhost:8545 PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Minter plusieurs NFTs :

```bash
make mint AMOUNT=5
```

### Révélation

Une fois que vous êtes prêt à révéler les métadonnées de vos NFTs :

```bash
make reveal
```

Cela utilise le baseURI défini dans votre script de déploiement.

### Transfert

Transférer un NFT à une autre adresse :

```bash
make transfer TOKEN_ID=0 TO_ADDRESS=0x...
```

### Autres fonctionnalités

- **Approuver une adresse** :

  ```bash
  make approve TOKEN_ID=0 TO_ADDRESS=0x...
  ```

- **Obtenir des informations sur le contrat** :

  ```bash
  make info
  ```

- **Vérifier un token spécifique** :

  ```bash
  make check TOKEN_ID=0
  ```

- **Retirer l'ETH en excès** :

  ```bash
  make withdraw ETH_AMOUNT=0.1
  ```

- **Démarrer la période de retrait** (uniquement le propriétaire) :

  ```bash
  make start-withdraw
  ```

- **Retirer tous les ETH collectés** (après la période de grâce) :
  ```bash
  make withdraw-all
  ```

## Métadonnées et IPFS

### Format des métadonnées

Les métadonnées des NFTs doivent suivre le format standard ERC-721 :

```json
{
  "name": "Nom du NFT #0",
  "description": "Description de votre NFT",
  "image": "https://lime-active-caterpillar-261.mypinata.cloud/ipfs/bafkreifpsndiuodlmv3elsbvfdprcdm4apymhfezz3mq6aqgbpypzb6oyu",
  "attributes": [
    {
      "trait_type": "Couleur",
      "value": "Bleu"
    },
    {
      "trait_type": "Forme",
      "value": "Carré"
    }
  ]
}
```

### Structure IPFS

Pour que votre contrat fonctionne correctement avec la révélation :

1. Créez un fichier JSON pour chaque token (0.json, 1.json, 2.json, etc.)
2. Téléchargez ces fichiers dans un dossier sur Pinata ou un autre service IPFS
3. Utilisez l'URL du dossier comme baseURI dans votre contrat

### Exemple de workflow

1. Créez vos fichiers de métadonnées
2. Téléchargez-les sur Pinata et obtenez le CID du dossier
3. Mettez à jour le baseURI dans script/DeployNFT.s.sol :
   ```solidity
   string memory baseURI = "https://gateway.pinata.cloud/ipfs/YOUR_CID/";
   ```
4. Calculez le hash pour baseURIHash :
   ```bash
   cast keccak "https://gateway.pinata.cloud/ipfs/YOUR_CID/"
   ```
5. Mettez à jour le hash dans le script de déploiement
6. Déployez le contrat

## Tests

Le projet inclut des tests complets pour toutes les fonctionnalités du contrat. Pour exécuter les tests :

```bash
forge test
```

Pour une couverture de code détaillée :

```bash
forge coverage
```

## Sécurité

Le contrat inclut plusieurs mesures de sécurité :

1. **Contrôles d'autorisation** pour toutes les opérations sensibles
2. **Système en deux étapes** pour les retraits d'ETH
3. **Vérification du hash** pour la révélation des métadonnées
4. **Période de grâce** pour les retraits majeurs
5. **Transfert de propriété en deux étapes** pour éviter les erreurs

## Licence

[MIT](LICENSE) - Voir le fichier LICENSE pour plus de détails.
