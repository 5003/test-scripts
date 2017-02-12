user='5003'
pass='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'

org=$user
repo='testing'
tag='latest'

token=$(curl --silent --header 'Content-Type: application/json' --request POST --data '{ "username": "'${user}'", "password": "'${pass}'" }' https://hub.docker.com/v2/users/login/ | jq --raw-output .token)

curl --silent --header "Authorization: JWT ${token}" --request DELETE https://hub.docker.com/v2/repositories/${org}/${repo}/tags/${tag}/