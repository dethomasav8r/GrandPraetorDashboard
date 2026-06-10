PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'GrandPraetorDashboardAccess' LIMIT 1];
User u = [SELECT Id FROM User WHERE Id = '005VH000005PRYXYA4' LIMIT 1];

List<PermissionSetAssignment> existing = [
    SELECT Id FROM PermissionSetAssignment
    WHERE AssigneeId = :u.Id AND PermissionSetId = :ps.Id
];

if (existing.isEmpty()) {
    insert new PermissionSetAssignment(AssigneeId = u.Id, PermissionSetId = ps.Id);
    System.debug('Assigned GrandPraetorDashboardAccess to Scott Quinn');
} else {
    System.debug('Already assigned');
}
