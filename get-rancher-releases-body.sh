tag=$1
curl --silent https://api.github.com/repos/rancher/rancher/releases/${tag} | jq --raw-output .body > ./rancher-release-${tag}.md