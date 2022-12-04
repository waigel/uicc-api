#bin/sh

#CONSTANTS for this script

host="https://www.etsi.org"
path="/deliver/etsi_ts/102200_102299/102241"
url="${host}${path}"


# Download the file
body=$(wget -q -O - $url  | tr '[:upper:]' '[:lower:]')
links=$(echo $body | grep -o -E 'href="[^"]+"' | cut -d'"' -f2)
links=$(echo $links | grep -o -E $path'/[0-9]{2}\.[0-9]{2}\.[0-9]{2}_[0-9]{2}/')

echo "Found $(echo $links | wc -w) links"

mkdir -p zip java temp

for link in $links
do
    echo "Processing $link"
    body=$(wget -q -O - $host$link  | tr '[:upper:]' '[:lower:]')
    zip=$(echo $body | grep -o -E 'href="[^"]+\.zip"' | cut -d'"' -f2)
    echo "Download  $zip"
    wget -q $host$zip -P ./zip
done

echo "[i] Downloaded $(ls -1 zip | wc -l) files"


echo "[i] Start extracting files"

for file in zip/*.zip; do
    echo "Extracting $file"
    filename=$(echo $file | cut -d'/' -f2)
    unzip -o -d "temp/${filename}" "$file"
done

echo "[i] Extraction finished"

for file in temp/*; do
    echo "Copying files from $file"
    for jar in $file/*.jar; do
        echo "Copying $jar"
        
        major=$(echo $file | sed -e 's/.*v\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\1/')
        minor=$(echo $file | sed -e 's/.*v\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\2/')
        patch=$(echo $file | sed -e 's/.*v\([0-9]\{2\}\)\([0-9]\{2\}\)\([0-9]\{2\}\).*/\3/')

        #remove one leading 0
        major=$(echo $major | sed -e 's/^0//')
        minor=$(echo $minor | sed -e 's/^0//')
        patch=$(echo $patch | sed -e 's/^0//')

        version="${major}_${minor}_${patch}"
        # if patch is 0 and minior is 0 then it is a major version
        if [ $patch -eq 0 ] && [ $minor -eq 0 ]; then
            version="${major}"
        fi

        # if patch is 0 and minior is not 0 then it is a minor version
        if [ $patch -eq 0 ] && [ $minor -ne 0 ]; then
            version="${major}_${minor}"
        fi
        cp "$jar" "java/uicc-api-for-java-card-REL-${version}.jar"
    done
done

echo "[i] Copying files to root folder"

for file in ./*.jar; do
    rm "$file"
done

for file in java/*.jar; do
    cp "$file" .
done

echo "[i] Cleaning up"
rm -rf java temp zip

