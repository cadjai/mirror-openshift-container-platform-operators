#!/bin/bash


while getopts a:d:m: flag
do
    case "${flag}" in
        a) AUTH=${OPTARG};;
        # json formatted auth token for registry login
        d) DEST=${OPTARG};;
        # URL of target registry to upload to. Sometimes requires port appended to end of url
        m) MAPPING=${OPTARG};;
        # Path to mapping.txt file that was created during bundle creation.
    esac
done

function buildSource() {
  # First grap the source server and namespace   
  SOURCE=$(grep -oP '(?&lt;=\=).*' &lt;&lt;&lt; $1)    
  # Second grab the digest of the image   
  DIGEST=$(grep -oP '\@.*(?=\=)' &lt;&lt;&lt; $1)   
  if [ ! -z ${DIGEST} ]    
  then    
    echo "$SOURCE$DIGEST"  else    echo "$SOURCE"    
  fi
}

function buildDestination() {
  # Grab the namespace of the referenced image
  NS=$(grep -oP '(?<=\=localhost:5000).*' <<< $1)
  echo "$DEST$NS"
}

function upload() {
for i in $(cat $MAPPING)
do
  SRC=$(buildSource $i)
  DST=$(buildDestination $i)
  skopeo copy docker://$SRC docker://$DST --tls-verify=false --all --authfile=$AUTH
done
}

upload
