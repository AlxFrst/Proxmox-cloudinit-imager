#!/bin/bash
# Script de création d'image CloudInit pour Proxmox VE par Alx

echo "🚀 Bienvenue dans le script de création d'image CloudInit pour Proxmox VE, version 1.0, conçu par Alx ! 🚀"
echo "✨ Je suis là pour te guider dans la création d'une image CloudInit qui sera ensuite transformée en un modèle pour Proxmox VE. C'est parti ! ✨"

# Liste des URL pour les images CloudInit
ubuntu1804="https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
ubuntu2204="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
ubuntu2304="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
debian10="https://cloud.debian.org/images/cloud/buster/20220307-641/debian-10-generic-amd64-20220307-641.qcow2"
debian11="https://cloud.debian.org/images/cloud/bullseye/20220307-641/debian-11-generic-amd64-20220307-641.qcow2"
centos8="https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.5.2105-20210603.0.x86_64.qcow2"

# Inviter l'utilisateur à choisir une image CloudInit ou une image personnalisée
echo " "
echo "🌐 Il est temps de choisir ton image CloudInit 🌐"
echo "1. Ubuntu 18.04"
echo "2. Ubuntu 22.04"
echo "3. Debian 10"
echo "4. Debian 11"
echo "5. CentOS 8"
echo "6. Image personnalisée"
read -p "Quel est ton choix ? " choix

# Si l'utilisateur choisit une image personnalisée, demander l'URL de l'image
if [ $choix -eq 6 ]; then
    echo " "
    read -p "🔗 Merci de fournir l'URL de ton image : " url
fi

# Demander à l'utilisateur de nommer son modèle
echo " "
read -p "💡 Comment souhaites-tu nommer ton modèle (sans espaces) ? " nom

# Demander à l'utilisateur d'entrer l'ID du modèle
echo " "
read -p "🔑 Peux-tu définir un ID unique pour ton modèle ? " id

# Afficher tous les stockages disponibles dans Proxmox VE et demander à l'utilisateur d'en choisir un
echo " "
echo "📦 Sélectionne le stockage pour ton modèle 📦"
pvesm status
read -p "Quel est le nom du stockage que tu choisis ? " stockage

# Afficher tous les réseaux disponibles dans Proxmox VE et demander à l'utilisateur d'en choisir un
echo " "
echo "🌍 Sélectionne le réseau pour ta VM 🌍"
echo "Le plus souvent, c'est vmbr0 pour le premier réseau, mais vérifie dans l'onglet réseau de Proxmox VE"
read -p "Quel est le nom du réseau que tu choisis ? " reseau

echo "🚀 Je commence la création de l'image, reste attentif ! 🚀"
# Téléchargement de l'image
apt install wget -y
if [ $choix -eq 1 ]; then
    wget $ubuntu1804
elif [ $choix -eq 2 ]; then
    wget $ubuntu2204
elif [ $choix -eq 3 ]; then
    wget $debian10
elif [ $choix -eq 4 ]; then
    wget $debian11
elif [ $choix -eq 5 ]; then
    wget $centos8
elif [ $choix -eq 6 ]; then
    wget $url
fi
apt update -y
apt install qemu-utils -y
apt install libguestfs-tools -y
nomImage=$(ls *.img)
virt-customize -a "$nomImage" --install qemu-guest-agent
virt-customize -a "$nomImage" --run-command "echo -n > /etc/machine-id"
qm create $id --name $nom --memory 512 --net0 virtio,bridge=$reseau --cores 1 --sockets 1 --description "Image CloudInit"
qm importdisk $id "$nomImage" $stockage
qm set $id --scsihw virtio-scsi-pci --scsi0 $stockage:vm-$id-disk-0
qm resize $id scsi0 +15G
qm set $id --ide2 $stockage:cloudinit
qm set $id --boot c --bootdisk scsi0
qm set $id --agent enabled=1
qm set $id --ciuser ubuntu --cipassword ubuntu
rm -rf $nomImage
qm template $id

clear
echo "✅ Le processus de création de l'image est maintenant terminé ! ✅"
echo "🎉 Tu peux désormais créer une VM à partir de ce modèle dans Proxmox VE. 🎉"
echo "🔐 N'oublie pas de changer le mot de passe de la VM ou de modifier la configuration CloudInit pour une sécurité optimale. 🔐"
echo "💾 Tu as la possibilité de personnaliser davantage ta VM en ajustant le disque, en ajoutant du CPU, de la mémoire, une carte réseau, etc. 💾"
echo "👥 Clone ce modèle pour déployer plusieurs VMs avec la même configuration facilement. 👥"
echo "Merci d'avoir utilisé ce script pour la création de ton image CloudInit. À la prochaine ! 🙏"
