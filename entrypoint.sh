#!/usr/bin/env bash

#Move to app source code
cd $INPUT_APP_SOURCE_CODE

#Install dependencies
echo "Installing dependencies"
npm install > /dev/null 2>&1

#Build application
echo "Building application"

#Execute the command provided
`echo $INPUT_BUILD_COMMAND` 

# echo "aws --region $INPUT_AWS_DEFAULT_REGION s3 sync ./dist s3://$INPUT_AWS_BUCKET_NAME --no-progress --delete"
#Sync files with amazon s3 bucket app
aws --region $INPUT_AWS_DEFAULT_REGION s3 sync ./dist s3://$INPUT_AWS_BUCKET_NAME --no-progress --delete

aws s3api get-bucket-website --region $INPUT_AWS_DEFAULT_REGION --bucket "$INPUT_AWS_BUCKET_NAME"

redirect_rules_file="redirect_rules.json"
cat <<EOF > "$redirect_rules_file"
{
  "IndexDocument": {
    "Suffix": "index.html"
  },
  "RoutingRules": [
EOF

i=0
filetype="js"

ls ./dist/assets | grep "index" | while read -r line ; do
    echo "Processing $line"
    # your code goes here
    if [ $i -gt 0 ]; then
      cat <<EOF >> "$redirect_rules_file"
      ,
EOF
    fi

if [[ $line == *"css"* ]]; then
  filetype="css"
fi

filenamefiletype="index.$filetype"

cat <<EOF >> "$redirect_rules_file"
      {
        "Condition": {
          "KeyPrefixEquals": "assets/$filenamefiletype"
        },
        "Redirect": {
          "ReplaceKeyWith": "assets/$line"
        }
      }
EOF
i=$(( i + 1 ))
done
cat <<EOF >> "$redirect_rules_file"
  ]
}
EOF

aws s3api put-bucket-website --region $INPUT_AWS_DEFAULT_REGION --bucket "$INPUT_AWS_BUCKET_NAME" --website-configuration "file://$redirect_rules_file"
# Clean up the temporary JSON file
rm "$redirect_rules_file"