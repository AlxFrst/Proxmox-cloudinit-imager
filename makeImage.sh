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
mapfile -t STORAGE_OPTIONS < <(pvesm status -content rootdir | awk 'NR>1 {printf "%s\t%s\t%.2fGB free\n", $1, $2, $6/1024/1024}')

# Prepare the storage menu items
STORAGE_MENU=()
for option in "${STORAGE_OPTIONS[@]}"; do
    # Split the line into ID and description
    IFS=$'\t' read -r id type space <<< "$option"
    STORAGE_MENU+=("$id" "$type ($space)")
done

# Prompt the user to choose a storage
STORAGE=$(whiptail --title "Choose Storage" --menu "Select the storage for your template:" 15 60 6 "${STORAGE_MENU[@]}" 3>&1 1>&2 2>&3)
check_cancel

# Prompt the user to choose a network
NETWORK=$(whiptail --inputbox "Select the network for your VM (usually 'vmbr0'):" 8 60 3>&1 1>&2 2>&3)
check_cancel

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
echo "Creating VM with ID $ID..."
qm create "$ID" --name "$NAME" --memory 512 --net0 "virtio,bridge=$NETWORK" --cores 1 --sockets 1 --description "CloudInit Image" || {
    echo "Failed to create VM"
    exit 1
}

echo "Importing disk..."
qm importdisk "$ID" "$image_name" "$STORAGE" || {
    echo "Failed to import disk"
    exit 1
}

echo "Configuring VM storage..."
qm set "$ID" --scsihw virtio-scsi-pci --scsi0 "$STORAGE:vm-$ID-disk-0" || {
    echo "Failed to configure storage"
    exit 1
}

# echo "Resizing disk..."
# qm resize "$ID" scsi0 +15G || {
#     echo "Failed to resize disk"
#     exit 1
# }

echo "Configuring CloudInit..."
qm set "$ID" --ide2 "$STORAGE:cloudinit" || {
    echo "Failed to configure CloudInit"
    exit 1
}

echo "Setting boot options..."
qm set "$ID" --boot c --bootdisk scsi0 || {
    echo "Failed to set boot options"
    exit 1
}

echo "Enabling QEMU agent..."
qm set "$ID" --agent enabled=1 || {
    echo "Failed to enable QEMU agent"
    exit 1
}

echo "Setting default user credentials..."
qm set "$ID" --ciuser ubuntu --cipassword "$(openssl rand -base64 12)" || {
    echo "Failed to set user credentials"
    exit 1
}

# Clean up the downloaded image
rm -f "$image_name"

echo "Converting to template..."
# Convert the VM to a template
qm template "$ID" || {
    echo "Failed to convert to template"
    exit 1
}

# Completion message
clear
whiptail --msgbox "The image creation process is complete! You can now create a VM from this template in Proxmox VE. Don't forget to change the VM password or update the CloudInit configuration for better security. Thank you for using this script!" 15 60
