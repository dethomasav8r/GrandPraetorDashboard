// Debug: Run the exact same logic as the Apex controller
// but as an admin so we can see what Rob's contact returns

Id robUserId = '005VH000005PR9EYAW';
User robUser = [SELECT ContactId, Name FROM User WHERE Id = :robUserId LIMIT 1];
System.debug('Rob ContactId: ' + robUser.ContactId);

// Step 1: Badge check
List<OrderApi__Badge__c> gpBadges = [
    SELECT Id, OrderApi__Is_Active__c
    FROM OrderApi__Badge__c
    WHERE OrderApi__Contact__c = :robUser.ContactId
      AND OrderApi__Badge_Type__r.Name = 'Grand Praetor'
      AND OrderApi__Is_Active__c = true
    LIMIT 1
];
System.debug('Active GP badges found: ' + gpBadges.size());
if (!gpBadges.isEmpty()) {
    System.debug('Badge Id: ' + gpBadges[0].Id);
}

// Step 2: Position check
List<OrderApi__Position__c> gpPositions = [
    SELECT Id, Name, OrderApi__Status__c, OrderApi__Account__r.Name
    FROM OrderApi__Position__c
    WHERE OrderApi__Contact__c = :robUser.ContactId
      AND OrderApi__Role__c = 'Grand Praetor'
      AND OrderApi__Status__c = 'Active'
    LIMIT 5
];
System.debug('Active GP positions found: ' + gpPositions.size());
for (OrderApi__Position__c p : gpPositions) {
    System.debug('Position: ' + p.Name + ' - ' + p.OrderApi__Account__r.Name);
}

// Step 3: Check sharing — can the portal user's profile see these records?
// Check object-level access for the portal profile
List<ObjectPermissions> objPerms = [
    SELECT SObjectType, PermissionsRead
    FROM ObjectPermissions
    WHERE ParentId IN (
        SELECT PermissionSetId
        FROM PermissionSetAssignment
        WHERE AssigneeId = :robUserId
    )
    AND SObjectType IN ('OrderApi__Badge__c', 'OrderApi__Position__c', 'OrderApi__Member_Information__c')
];
System.debug('Object permissions count: ' + objPerms.size());
for (ObjectPermissions op : objPerms) {
    System.debug('Object: ' + op.SObjectType + ' Read: ' + op.PermissionsRead);
}
