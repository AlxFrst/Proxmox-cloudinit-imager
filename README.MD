
# Création d'Image CloudInit pour Proxmox VE

Bienvenue dans le dépôt du script de création d'image CloudInit pour Proxmox VE, conçu par Alx. Ce script simplifie le processus de création et de configuration d'images CloudInit pour une utilisation avec Proxmox VE, facilitant la mise en place de modèles de machines virtuelles prêts à l'emploi.

## 🚀 Fonctionnalités

- Téléchargement automatique d'images CloudInit pour différentes distributions (Ubuntu, Debian, CentOS).
- Configuration d'un modèle VM dans Proxmox VE avec l'image téléchargée.
- Personnalisation facile de l'image, y compris le nom du modèle, l'ID, le stockage, et les paramètres réseau.
- Installation automatique des utilitaires nécessaires et configuration de l'agent QEMU pour les VMs.

## 📋 Prérequis

Pour utiliser ce script, assurez-vous que votre système Proxmox VE est à jour et dispose des paquets `wget`, `qemu-utils`, et `libguestfs-tools`. Le script doit être exécuté sur un hôte Proxmox VE.

## 🛠️ Installation

1. Clonez ce dépôt sur votre hôte Proxmox VE.
   ```
   git clone <URL_DU_DEPOT>
   ```
2. Rendez le script exécutable.
   ```
   chmod +x script_creation_image_cloudinit.sh
   ```

## 🔧 Utilisation

Pour lancer le script, exécutez la commande suivante dans le répertoire du script :
```
./script_creation_image_cloudinit.sh
```
Suivez ensuite les instructions à l'écran pour sélectionner votre image CloudInit, nommer votre modèle, et configurer les autres paramètres nécessaires.

## 🖼️ Images CloudInit supportées

- Ubuntu 18.04
- Ubuntu 22.04
- Debian 10
- Debian 11
- CentOS 8
- Image personnalisée (vous pouvez fournir l'URL de votre choix)

## ⚙️ Configuration Avancée

Le script vous permet de personnaliser plusieurs aspects de l'image CloudInit et du modèle VM, y compris :

- Nom du modèle
- ID unique du modèle
- Sélection du stockage
- Configuration du réseau

Pour une configuration plus avancée, vous pouvez modifier le script selon vos besoins ou ajouter des commandes `qm` supplémentaires après la création du modèle.

---

Bonne création de VM avec Proxmox VE !
