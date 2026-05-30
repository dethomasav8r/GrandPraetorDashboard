// Run this to simulate exactly what the Apex controller does
// when called from the Experience Cloud session for Rob Silvers

// Simulate running AS Rob's user context
User robUser = [SELECT Id, ContactId, Name, Profile.Name FROM User WHERE Id = '005VH000005PR9EYAW' LIMIT 1];
System.debug('=== ROB USER INFO ===');
System.debug('Name: ' + robUser.Name);
System.debug('ContactId: ' + robUser.ContactId);
System.debug('Profile: ' + robUser.Profile.Name);

System.runAs(robUser) {
    System.debug('=== RUNNING AS ROB ===');
    System.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
    System.debug('UserInfo.getName(): ' + UserInfo.getName());

    // Exact query from Apex controller
    User currentUser = [SELECT ContactId FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    System.debug('ContactId from query: ' + currentUser.ContactId);

    if (currentUser.ContactId == null) {
        System.debug('FAIL: ContactId is null - stopping here');
        return;
    }

    Id contactId = currentUser.ContactId;

    // Badge check
    List<OrderApi__Badge__c> gpBadges = [
        SELECT Id
        FROM OrderApi__Badge__c
        WHERE OrderApi__Contact__c = :contactId
          AND OrderApi__Badge_Type__r.Name = 'Grand Praetor'
          AND OrderApi__Is_Active__c = true
        LIMIT 1
    ];
    System.debug('Badge check result: ' + gpBadges.size() + ' records');

    if (gpBadges.isEmpty()) {
        System.debug('FAIL: No active GP badge found for contactId: ' + contactId);
        return;
    }

    // Position check
    List<OrderApi__Position__c> gpPositions = [
        SELECT Id, Name, OrderApi__Account__r.Name
        FROM OrderApi__Position__c
        WHERE OrderApi__Contact__c = :contactId
          AND OrderApi__Role__c = 'Grand Praetor'
          AND OrderApi__Status__c = 'Active'
        LIMIT 5
    ];
    System.debug('Position check result: ' + gpPositions.size() + ' records');
    for (OrderApi__Position__c p : gpPositions) {
        System.debug('Found position: ' + p.Name + ' - ' + p.OrderApi__Account__r.Name);
    }

    System.debug('=== END RUNASROB ===');
}
