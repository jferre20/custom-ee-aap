#!/bin/bash

# VARIABLES
EE_NEW_IMAGE=$1
EE_PUSH_IMAGE=ee-supported-rhel8
EE_HUB_HOST=hub01.jferre.local

# VARIABLES ECHO
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m'

# BUILD IMAGE AND PUSH
echo "LOGIN INTO PRIVATE HUB --------------------------------------------------------"
podman login -u jferre  --password-stdin < .credential-hub $EE_HUB_HOST
printf "\n"

echo "BUILDING IMAGE USING EXECUTION ENVIRONMENT FILE -------------------------------"
if ansible-builder build -v3 --tag $EE_HUB_HOST/$EE_NEW_IMAGE --file ee-files/execution-environment.yml; then
   printf "\n"

   if ansible-navigator run -m stdout mysql_info.yml -i inventory -e "vmname=srv02" --eei $EE_HUB_HOST/$EE_NEW_IMAGE; then
      printf "\n"
      echo -e "${GREEN}The image is working! Let's go to push it and configure into Automation Controller.${NC}"
      echo "-------------------------------------------------------------------------------"
      podman push $EE_HUB_HOST/$EE_NEW_IMAGE
      printf "\n"
      ansible-navigator run -m stdout create_ee_aap.yml -e "ee_name=$EE_NEW_IMAGE ee_image=$EE_HUB_HOST/$EE_NEW_IMAGE" --eei $EE_HUB_HOST/$EE_PUSH_IMAGE
      echo -e "${GREEN}The image was configured into Automation Controller. Enjoy it!${NC}"
   else
      echo -e "${RED}The image $EE_NEW_IMAGE is not working! Please proceed to validate it.${NC}"
      rm -rf context/
      for images in `podman images | grep -v docker | awk '{print $3}' | grep -v IMAGE`; do 
        podman rmi $images -f
      done
      podman logout $EE_HUB_HOST
      exit 1
   fi
else
   printf "\n"
   echo -e "${RED}ERROR TO CREATE NEW IMAGE FROM EXECUTION ENVIRONMENT!${NC}"
   rm -rf context/
   for images in `podman images | grep -v docker | awk '{print $3}' | grep -v IMAGE`; do 
     podman rmi $images -f
   done
   podman logout $EE_HUB_HOST
   exit 1
fi

printf "\n"

echo "DELETING ALL IMAGES CREATED ON LOCALHOST"
rm -rf context/
for images in `podman images | grep -v docker | awk '{print $3}' | grep -v IMAGE`; do 
  podman rmi $images -f
done
podman logout $EE_HUB_HOST
