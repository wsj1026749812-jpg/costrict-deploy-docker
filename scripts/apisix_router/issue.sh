#!/bin/sh
#
# Submit issue reports, page resources are hosted on the portal service, API '/api/feedbacks/issue' is implemented by chatgpt.
#

# Define upstream for login-related page resources
curl -i http://$APISIX_ADDR/apisix/admin/upstreams -H "$AUTH" -H "$TYPE" -X PUT  -d '{
    "id": "portal",
    "nodes": {
        "portal:80": 1
    },
    "type": "roundrobin"
}'

# Resources used by login pages
curl -i  http://$APISIX_ADDR/apisix/admin/routes -H "$AUTH" -H "$TYPE" -X PUT -d '{
    "id": "issue-resources",
    "name": "issue-resources",
    "uris": ["/issue/*"],
    "upstream_id": "portal"
  }'

curl -i http://$APISIX_ADDR/apisix/admin/upstreams -H "$AUTH" -H "$TYPE" -X PUT -d '{
    "id": "issue-manager",
    "nodes": {
      "issue-manager:8080": 1
    },
    "type": "roundrobin"
  }'

curl -i http://$APISIX_ADDR/apisix/admin/routes -H "$AUTH" -H "$TYPE" -X PUT -d '{
    "id": "issue-manager",
    "name": "issue-manager-api",
    "uris": ["/issue-manager/*"],
    "upstream_id": "issue-manager"
  }'
