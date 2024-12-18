#!/bin/bash

# VARIABLES
EE_NEW_IMAGE=$1
EE_TEST_IMAGE=ee-supported-rhel8
EE_HUB_HOST=hub01.jferre.local

# BUILD IMAGE AND PUSH
echo "BUILDING IMAGE USING EXECUTION ENVIRONMENT FILE -------------------------------"
if ansible-builder build -v3 --tag $EE_HUB_HOST/$EE_NEW_IMAGE --file ee-files/execution-environment.yml; then
   echo "PUSH NEW IMAGE ON AUTOMATION HUB ----------------------------------------------"
   podman push $EE_HUB_HOST/$EE_NEW_IMAGE
else
   echo "ERROR TO CREATE NEW IMAGE FROM EXECUTION ENVIRONMENT!"
   set -e
fi

# TESTING NEW EXECUTION ENVIRONMENT
echo "VALIDATING NEW EE RUNNING A PLAYBOOK WITH CUSTOM COLLECTION -------------------"
ansible-navigator run -m stdout mysql_info.yml -i inv -e "vmname=srv02" --eei $EE_HUB_HOST/$EE_NEW_IMAGE
printf "\n"

# ANSIBLE-NAVIGATOR TO CONFIGURE A CUSTOM EXECUTION ENVIRONMENT
echo "CONFIGURING NEW EXECUTION ENVIRONMENT USING ANSIBLE CONTROLLER COLLECTION -----"
ansible-navigator run -m stdout create_ee_aap.yml -e "ee_name=$EE_NEW_IMAGE ee_image=$EE_HUB_HOST/$EE_NEW_IMAGE" --eei $EE_HUB_HOST/$EE_TEST_IMAGE
printf "\n"

# DELETING IMAGES LOCALHOST
echo "DELETING IMAGES UNUSED"
for images in `podman images | grep -v docker | awk '{print $3}' | grep -v IMAGE`; do 
  podman rmi $images -f
done
printf "\n"

echo "Creation custom EE completed!"
