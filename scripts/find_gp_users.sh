#!/bin/bash
# ─────────────────────────────────────────────
# Find portal users who have active Grand
# Praetor positions, then assign the perm set
# Usage: bash scripts/find_gp_users.sh GrandPraetorSandbox
# ─────────────────────────────────────────────

ORG_ALIAS="${1:-GrandPraetorSandbox}"

echo ""
echo "=== Step 1: All Active GP Contact IDs ==="
sf data query \
  --query "SELECT DISTINCT OrderApi__Contact__c, OrderApi__Contact__r.Name FROM OrderApi__Position__c WHERE OrderApi__Role__c = 'Grand Praetor' AND OrderApi__Status__c = 'Active' ORDER BY OrderApi__Contact__r.Name" \
  --target-org "$ORG_ALIAS"

echo ""
echo "=== Step 2: Portal Users Matching Those Contacts ==="
sf data query \
  --query "SELECT u.Id, u.Name, u.Username, u.IsActive, u.ContactId, u.Profile.Name FROM User u WHERE u.ContactId IN (SELECT OrderApi__Contact__c FROM OrderApi__Position__c WHERE OrderApi__Role__c = 'Grand Praetor' AND OrderApi__Status__c = 'Active') AND u.IsActive = true" \
  --target-org "$ORG_ALIAS"

echo ""
echo "=== Step 3: Assign Permission Set to Each User Above ==="
echo "Run this command for each USERNAME found in Step 2:"
echo ""
echo "  sf org assign permset --name GrandPraetorDashboardAccess --on-behalf-of USERNAME --target-org $ORG_ALIAS"
echo ""
