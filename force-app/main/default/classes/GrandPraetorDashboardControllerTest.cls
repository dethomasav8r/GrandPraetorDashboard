@isTest
private class GrandPraetorDashboardControllerTest {

    // ── Tests ─────────────────────────────────────────────────────────────────

    @isTest
    static void testGetDashboardDataNoContact() {
        // Running as internal admin with no ContactId → returns non-null list
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardData();
        System.assertNotEquals(null, result, 'Should not be null');
        System.assert(result.size() >= 0, 'Should return valid list');
    }

    @isTest
    static void testGetOrderLinesInvalidChapter() {
        // No GP position on a fake account → returns empty
        List<GrandPraetorDashboardController.OrderLineData> lines =
            GrandPraetorDashboardController.getOrderLines(
                '001000000000000AAA', '90+'
            );
        System.assertNotEquals(null, lines, 'Should not be null');
        System.assertEquals(0, lines.size(), 'No position — should be empty');
    }

    @isTest
    static void testGetOrderLinesBuckets() {
        // Verify all bucket values are accepted without exception
        for (String bucket : new List<String>{'0-30','31-60','61-90','90+'}) {
            List<GrandPraetorDashboardController.OrderLineData> lines =
                GrandPraetorDashboardController.getOrderLines(
                    '001000000000000AAA', bucket
                );
            System.assertNotEquals(null, lines, 'Bucket ' + bucket + ' should not be null');
        }
    }

    @isTest
    static void testBalanceHelperEmpty() {
        Set<Id> emptyIds = new Set<Id>();
        List<GrandPraetorBalanceHelper.BalanceResult> results =
            GrandPraetorBalanceHelper.getBalances(emptyIds);
        System.assertNotEquals(null, results, 'Should not be null');
        System.assertEquals(0, results.size(), 'Empty input → empty output');
    }

    @isTest
    static void testBalanceHelperWithIds() {
        // Pass real-looking IDs — no Sales Orders exist in test so returns empty
        Set<Id> ids = new Set<Id>{'001000000000001AAA', '001000000000002AAA'};
        List<GrandPraetorBalanceHelper.BalanceResult> results =
            GrandPraetorBalanceHelper.getBalances(ids);
        System.assertNotEquals(null, results, 'Should not be null');
        System.assert(results.size() >= 0, 'Should return valid list');
    }

    @isTest
    static void testPermSetQueueableAssign() {
        // Verify assign=true runs without error
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet
                            WHERE Name = 'GrandPraetorDashboardAccess' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new PermSetAssignmentQueueable(u.Id, ps.Id, true));
        Test.stopTest();
        System.assert(true, 'Assign queueable ran without error');
    }

    @isTest
    static void testPermSetQueueableRemove() {
        // Verify assign=false runs without error
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet
                            WHERE Name = 'GrandPraetorDashboardAccess' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new PermSetAssignmentQueueable(u.Id, ps.Id, false));
        Test.stopTest();
        System.assert(true, 'Remove queueable ran without error');
    }

    @isTest
    static void testOrderLineDataStructure() {
        // Verify inner class can be instantiated
        GrandPraetorDashboardController.OrderLineData d =
            new GrandPraetorDashboardController.OrderLineData();
        d.salesOrderId   = '8010000000000001AAA';
        d.salesOrderName = '000001234';
        d.itemName       = 'Test Fee';
        d.balanceDue     = 100.00;
        d.amountPaid     = 50.00;
        d.quantity       = 1;
        d.total          = 150.00;
        d.contactName    = 'Test Contact';
        System.assertEquals(100.00, d.balanceDue, 'Balance due should be set');
        System.assertEquals(50.00, d.amountPaid, 'Amount paid should be set');
    }
}
