delete_following_tag_prefix() {
  local list="$(openstack server list --long --format value | grep "instance_name_tag='$1-" | awk '{ print $1 }')"
  test ! -z "${list}" && openstack server delete --wait $list
}

create_new() {
  openstack server create --image ${2%:*} \
                          --flavor ${2#*:} \
                          --security-group gncs-ipv4-all \
                          --key-name $KEY_NAME \
                          --property instance_name_tag=${1//./-} \
                          --wait \
                          - > /dev/null
}