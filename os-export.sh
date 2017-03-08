for var in OS_USERNAME \
           OS_PASSWORD \
           OS_TENANT_ID \
           OS_TENANT_NAME \
           OS_AUTH_URL
  do

echo -n $var
read $var
export $var

done