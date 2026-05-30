// Backfill: Assigns GrandPraetorDashboardAccess permission set to all
// portal users who currently have an active Grand Praetor badge.
// Run once after deploying the Flow.

// Get the permission set
PermissionSet ps = [
    SELECT Id
    FROM PermissionSet
    WHERE Name = 'GrandPraetorDashboardAccess'
    LIMIT 1
];
System.debug('Permission Set Id: ' + ps.Id);

// Get all active GP badge contact IDs
List<OrderApi__Badge__c> activeBadges = [
    SELECT OrderApi__Contact__c
    FROM OrderApi__Badge__c
    WHERE OrderApi__Badge_Type__r.Name = 'Grand Praetor'
      AND OrderApi__Is_Active__c = true
      AND OrderApi__Contact__c != null
];

Set<Id> contactIds = new Set<Id>();
for (OrderApi__Badge__c b : activeBadges) {
    contactIds.add(b.OrderApi__Contact__c);
}
System.debug('Active GP badge contacts found: ' + contactIds.size());

// Find portal users for those contacts
List<User> gpUsers = [
    SELECT Id, Name, Username
    FROM User
    WHERE ContactId IN :contactIds
      AND IsActive = true
];
System.debug('Portal users found: ' + gpUsers.size());

// Get existing assignments to avoid duplicates
Set<Id> userIds = new Set<Id>();
for (User u : gpUsers) { userIds.add(u.Id); }

List<PermissionSetAssignment> existing = [
    SELECT AssigneeId
    FROM PermissionSetAssignment
    WHERE PermissionSetId = :ps.Id
      AND AssigneeId IN :userIds
];

Set<Id> alreadyAssigned = new Set<Id>();
for (PermissionSetAssignment psa : existing) {
    alreadyAssigned.add(psa.AssigneeId);
}
System.debug('Already have perm set: ' + alreadyAssigned.size());

// Build new assignments
List<PermissionSetAssignment> toAssign = new List<PermissionSetAssignment>();
for (User u : gpUsers) {
    if (!alreadyAssigned.contains(u.Id)) {
        toAssign.add(new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        ));
        System.debug('Assigning to: ' + u.Name + ' (' + u.Username + ')');
    } else {
        System.debug('Already assigned: ' + u.Name);
    }
}

// Insert
if (!toAssign.isEmpty()) {
    insert toAssign;
    System.debug('SUCCESS: Assigned to ' + toAssign.size() + ' users');
} else {
    System.debug('No new assignments needed');
}
