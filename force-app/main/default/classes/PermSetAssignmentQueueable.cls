public class PermSetAssignmentQueueable implements Queueable {
    private Id userId;
    private Id permSetId;
    private Boolean assign; // true = assign, false = remove

    public PermSetAssignmentQueueable(Id userId, Id permSetId, Boolean assign) {
        this.userId    = userId;
        this.permSetId = permSetId;
        this.assign    = assign;
    }

    public void execute(QueueableContext ctx) {
        if (assign) {
            List<PermissionSetAssignment> existing = [
                SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSetId = :permSetId
            ];
            if (existing.isEmpty()) {
                insert new PermissionSetAssignment(
                    AssigneeId = userId, PermissionSetId = permSetId
                );
            }
        } else {
            List<PermissionSetAssignment> toDelete = [
                SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSetId = :permSetId
            ];
            if (!toDelete.isEmpty()) delete toDelete;
        }
    }

    // Invocable method called from Flow
    @InvocableMethod(label='Assign or Remove Permission Set (Async)'
                     description='Queues a perm set assignment or removal to avoid MIXED_DML')
    public static void invoke(List<PermSetRequest> requests) {
        for (PermSetRequest req : requests) {
            System.enqueueJob(new PermSetAssignmentQueueable(
                req.userId, req.permSetId, req.assign
            ));
        }
    }

    public class PermSetRequest {
        @InvocableVariable(required=true label='User ID')
        public Id userId;
        @InvocableVariable(required=true label='Permission Set ID')
        public Id permSetId;
        @InvocableVariable(required=true label='Assign (true) or Remove (false)')
        public Boolean assign;
    }
}
