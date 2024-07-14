#!/bin/bash

# Usage: ./replace_yaml_value.sh path_to_yaml_file key_to_replace new_value

# Assign command line arguments to variables
YAML_FILE=$1
KEY=$2
NEW_VALUE=$3

# Check if the correct number of arguments is provided
if [ "$#" -ne 3 ]; then
  echo "Usage: $0 path_to_yaml_file key_to_replace new_value"
  exit 1
fi

# Use sed to find and replace the key's value
sed -i.bak -e "s|\($KEY:*\).*|\1 $NEW_VALUE|" ./ha-setup-k8.yaml
# sed -i.bak -e "s/\($KEY: *\).*/\1$NEW_VALUE/" $YAML_FILE

# Check if sed was successful
if [ $? -eq 0 ]; then
  echo "Successfully replaced the value of '$KEY' with '$NEW_VALUE' in '$YAML_FILE'."
else
  echo "Failed to replace the value. Please check the provided arguments and the YAML file format."
fi

