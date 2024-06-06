#!/bin/bash
# CloudInit Image Creation Script for Proxmox VE by Alx

# Function to display the header
function header_info {
    clear
    cat <<"EOF"
╔═╗──────╔╦╗──╔╦╗─╔══╗
║╔╬╗╔═╦╦╦╝╠╬═╦╬╣╚╗╚║║╬══╦═╗╔═╦═╦╦╗
║╚╣╚╣╬║║║╬║║║║║║╔╣╔║║╣║║║╬╚╣╬║╩╣╔╝
╚═╩═╩═╩═╩═╩╩╩═╩╩═╝╚══╩╩╩╩══╬╗╠═╩╝
───────────────────────────╚═╝
EOF
}

# Check if whiptail is installed, otherwise install it
if ! command -v whiptail &> /dev/null
then
    echo "whiptail is not installed. Installing..."
    apt-get update
    apt-get install whiptail -y
fi

# Display the header
header_info

# List of URLs for CloudInit images
ubuntu1804="https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img"
ubuntu2004="https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img"
ubuntu2204="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
ubuntu2310="https://cloud-images.ubuntu.com/mantic/current/mantic-server-cloudimg-amd64.img"
ubuntu2404="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"

# Function to handle cancellation
function check_cancel {
    if [ $? -ne 0 ]; then
        whiptail --msgbox "Script cancelled. Exiting..." 8 40
        exit 1
    fi
}

# Prompt the user to choose a CloudInit image or a custom image
CHOICE=$(whiptail --title "Choose Image" --menu "Choose your CloudInit image" 15 60 6 \
"1" "Ubuntu 18.04" \
"2" "Ubuntu 20.04" \
"3" "Ubuntu 22.04" \
"4" "Ubuntu 23.10" \
"5" "Ubuntu 24.04" \
"6" "Custom Image" 3>&1 1>&2 2>&3)
check_cancel

case $CHOICE in
    1) url=$ubuntu1804 ;;
    2) url=$ubuntu2004 ;;
    3) url=$ubuntu2204 ;;
    4) url=$ubuntu2310 ;;
    5) url=$ubuntu2404 ;;
    6) 
        url=$(whiptail --inputbox "Please provide the URL of your image:" 8 60 3>&1 1>&2 2>&3)
        check_cancel
        ;;
    *) exit 1 ;;
esac

# Prompt the user to name their template
NAME=$(whiptail --inputbox "What do you want to name your template (no spaces)?" 8 60 3>&1 1>&2 2>&3)
check_cancel

# Prompt the user to enter the template ID
ID=$(whiptail --inputbox "Please provide a unique ID for your template:" 8 60 3>&1 1>&2 2>&3)
check_cancel

# Get available storage options
mapfile -t STORAGE_OPTIONS < <(pvesm status -content rootdir | awk 'NR>1 {print $1, $2, $6/1024/1024 "GB free"}')

# Prepare the storage menu
STORAGE_MENU=()
for OPTION in "${STORAGE_OPTIONS[@]}"; do
    STORAGE_MENU+=("$OPTION" "")
done

# Prompt the user to choose a storage
STORAGE=$(whiptail --title "Choose Storage" --menu "Select the storage for your template:" 15 60 6 "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3)
check_cancel

# Prompt the user to choose a network
NETWORK=$(whiptail --inputbox "Select the network for your VM (usually 'vmbr0'):" 8 60 3>&1 1>&2 2>&3)
check_cancel

# Prompt for additional packages
PACKAGES=$(whiptail --title "Additional Packages" --menu "Do you want to add additional packages to your image?" 15 60 2 \
"1" "Yes" \
"2" "No" 3>&1 1>&2 2>&3)
check_cancel

if [ "$PACKAGES" -eq 1 ]; then
    whiptail --msgbox "This feature is under development." 8 60
    check_cancel
fi

# Start the image creation process
whiptail --msgbox "Starting the image creation process, please wait..." 8 60
check_cancel

# Download the chosen image
apt install wget -y
wget $url

# Update and install necessary packages
apt update -y
apt install qemu-utils -y
apt install libguestfs-tools -y

# Customize the image
image_name=$(ls *.img)
virt-customize -a "$image_name" --install qemu-guest-agent
virt-customize -a "$image_name" --run-command "echo -n > /etc/machine-id"

# Create the VM template
qm create $ID --name $NAME --memory 512 --net0 virtio,bridge=$NETWORK --cores 1 --sockets 1 --description "CloudInit Image"
qm importdisk $ID "$image_name" $STORAGE
qm set $ID --scsihw virtio-scsi-pci --scsi0 $STORAGE:vm-$ID-disk-0
qm resize $ID scsi0 +15G
qm set $ID --ide2 $STORAGE:cloudinit
qm set $ID --boot c --bootdisk scsi0
qm set $ID --agent enabled=1
qm set $ID --ciuser ubuntu --cipassword ubuntu

# Clean up the downloaded image
rm -rf $image_name

# Convert the VM to a template
qm template $ID

# Completion message
clear
whiptail --msgbox "The image creation process is complete! You can now create a VM from this template in Proxmox VE. Don't forget to change the VM password or update the CloudInit configuration for better security. Thank you for using this script!" 15 60
