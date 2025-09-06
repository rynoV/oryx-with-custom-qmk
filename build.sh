#!/bin/bash
# vim: set expandtab shiftwidth=4 tabstop=4:

set -euo pipefail

# Set up cleanup trap for any exit (normal or error)
cleanup() {
    # We temporarily checkout the oryx branch in the script, so we need to clean up
    # by checking out the previous branch before exiting
    if [[ "$(git rev-parse --abbrev-ref HEAD)" == "oryx" ]]; then
        git checkout -
    fi
}
trap cleanup EXIT

# Required parameters
LAYOUT_ID=""
LAYOUT_GEOMETRY=""
FLASH=false

usage() {
    echo "Usage: $0 -l <layout_id> -g <layout_geometry> [-f]"
    exit 1
}

# Parse command line arguments
while getopts "l:g:f" opt; do
    case $opt in
        l) LAYOUT_ID="$OPTARG";;
        g) LAYOUT_GEOMETRY="$OPTARG";;
        f) FLASH=true;;
        *) usage;;
    esac
done

# Check if required parameters are provided
if [ -z "$LAYOUT_ID" ] || [ -z "$LAYOUT_GEOMETRY" ]; then
    usage
fi

git checkout --no-force -B oryx refs/remotes/origin/oryx
git pull

echo "Downloading layout source..."

query=$(cat <<'EOF'
query getLayout($hashId: String!, $revisionId: String!, $geometry: String) {
  layout(hashId: $hashId, geometry: $geometry, revisionId: $revisionId) {
    revision {
      hashId
      qmkVersion
      title
    }
  }
}
EOF
)

variables=$(cat <<EOF
{
  "hashId": "${LAYOUT_ID}",
  "geometry": "${LAYOUT_GEOMETRY}",
  "revisionId": "latest"
}
EOF
)

response=$(curl --location 'https://oryx.zsa.io/graphql' \
  --header 'Content-Type: application/json' \
  --data "$(jq -n \
    --arg query "$query" \
    --arg vars "$variables" \
    '{query: $query, variables: ($vars | fromjson)}'
  )" | jq '.data.layout.revision | [.hashId, .qmkVersion, .title]')

hash_id=$(echo "${response}" | jq -r '.[0]')
firmware_version=$(printf "%.0f" $(echo "${response}" | jq -r '.[1]'))
change_description=$(echo "${response}" | jq -r '.[2]')
if [[ -z "${change_description}" ]]; then
    change_description="latest layout modification made with Oryx"
fi

curl -L "https://oryx.zsa.io/source/${hash_id}" -o source.zip

echo "Extracting source files..."
unzip -oj source.zip '*_source/*' -d "$LAYOUT_ID"
rm source.zip

echo "Committing changes from Oryx to oryx branch..."
git add $LAYOUT_ID
git commit -m "✨(oryx): ${change_description}" || echo "No layout change"
git push

echo "Merging Oryx with custom QMK..."
git fetch origin main
git checkout main
git pull
git merge --no-edit -Xignore-all-space oryx

echo "Updating QMK firmware submodule..."
git submodule update --init --remote --depth=1
cd qmk_firmware
git checkout -B firmware${firmware_version} origin/firmware${firmware_version}
git submodule update --init --recursive
cd ..
git add qmk_firmware
git commit -m "✨(qmk): Update firmware" || echo "No QMK change"

echo "Building the layout..."
# Set keyboard directory and make prefix based on firmware version
if [ "$firmware_version" -ge 24 ]; then
    keyboard_directory="qmk_firmware/keyboards/zsa"
    make_prefix="zsa/"
else
    keyboard_directory="qmk_firmware/keyboards"
    make_prefix=""
fi

# Copy layout files to the qmk folder
rm -rf "${keyboard_directory}/${LAYOUT_GEOMETRY}/keymaps/${LAYOUT_ID}"
mkdir -p "${keyboard_directory}/${LAYOUT_GEOMETRY}/keymaps" && cp -r "$LAYOUT_ID" "$_"

# Check if qmk is available locally
if command -v qmk >/dev/null 2>&1; then
    echo "Using local QMK installation..."
    cd qmk_firmware
    qmk setup zsa/qmk_firmware --branch firmware${firmware_version} --yes --home .
    make ${make_prefix}${LAYOUT_GEOMETRY}:${LAYOUT_ID}
    cd ..
else
    echo "Using Docker for QMK build..."
    docker build -t qmk .
    docker run -v ./qmk_firmware:/root --rm qmk /bin/sh -c "
        qmk setup zsa/qmk_firmware -b firmware${firmware_version} -y
        make ${make_prefix}${LAYOUT_GEOMETRY}:${LAYOUT_ID}
    "
fi

# Note: for some boards it's necessary to use the custom defined bootloader, or
# the keyboard won't be recognized; using make instead of qmk flash
# accomplishes this.
if [ "$FLASH" = true ]; then
    echo "Flashing the layout..."
    cd qmk_firmware
    make ${make_prefix}${LAYOUT_GEOMETRY}:${LAYOUT_ID}:flash
    cd ..
else
    # Find built layout
    normalized_layout_geometry="$(echo "$LAYOUT_GEOMETRY" | sed 's/\//_/g')"
    built_layout_file=$(find ./qmk_firmware -maxdepth 1 -type f -regex ".*${normalized_layout_geometry}.*\.\(bin\|hex\)$")
    echo -e "Flash with\n:make ${make_prefix}${LAYOUT_GEOMETRY}:${LAYOUT_ID}:flash"
fi
