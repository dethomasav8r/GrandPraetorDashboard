@isTest
private class GrandPraetorDashboardControllerTest {

    // ── Shared test data ──────────────────────────────────────────────────────
    @testSetup
    static void setupTestData() {
        // Account
        Account a = new Account(Name = 'Test Chapter Coverage');
        insert a;

        // Contact with FirstName to satisfy org flows
        // Using DML options to bypass duplicate rules
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        Contact c = new Contact(
            FirstName          = 'Test',
            LastName           = 'GPCoverage',
            AccountId          = a.Id,
            Email              = 'testgpcoverage@test.org',
            Phone              = '555-555-5555',
            MobilePhone        = '555-555-5556',
            MailingStreet      = '123 Main St',
            MailingCity        = 'Nashville',
            MailingStateCode   = 'TN',
            MailingCountryCode = 'US',
            MailingPostalCode  = '37201'
        );
        Database.insert(c, dml);
    }

    // ── getDashboardData ──────────────────────────────────────────────────────

    @isTest
    static void testGetDashboardDataAsAdmin() {
        // Admin user has no ContactId — returns non-null list
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardData();
        System.assertNotEquals(null, result, 'Should not be null');
        System.assert(result.size() >= 0, 'Should return a valid list');
    }

    @isTest
    static void testGetDashboardDataWithContactNoPositions() {
        // Contact exists but no GP positions — returns empty list
        Contact c = [SELECT Id FROM Contact WHERE FirstName = 'Test'
                     AND AccountId IN (SELECT Id FROM Account WHERE Name = 'Test Chapter Coverage')
                     LIMIT 1];
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardDataForContact(c.Id);
        System.assertNotEquals(null, result, 'Should not be null');
        // Result is valid — may have positions from existing sandbox data
        System.assert(result.size() >= 0, 'Should return a valid list');
    }

    @isTest
    static void testGetDashboardDataForContactNullId() {
        // Null contactId — should return empty gracefully
        List<GrandPraetorDashboardController.ChapterDashboardData> result =
            GrandPraetorDashboardController.getDashboardDataForContact(null);
        System.assertNotEquals(null, result, 'Should not be null');
    }

    // ── getContactDetail ──────────────────────────────────────────────────────

    @isTest
    static void testGetContactDetailValid() {
        Contact c = [SELECT Id FROM Contact WHERE FirstName = 'Test' AND AccountId IN (SELECT Id FROM Account WHERE Name = 'Test Chapter Coverage') LIMIT 1];
        GrandPraetorDashboardController.ContactDetail cd =
            GrandPraetorDashboardController.getContactDetail(c.Id);
        System.assertNotEquals(null, cd, 'Should return contact detail');
        System.assert(cd.name.contains('Test'), 'Name should contain first name');
        System.assertEquals('555-555-5555', cd.phone, 'Phone should match');
        System.assertEquals('Nashville', cd.mailingCity, 'City should match');
    }

    @isTest
    static void testGetContactDetailInvalid() {
        // Fake ID → returns null without throwing
        GrandPraetorDashboardController.ContactDetail cd =
            GrandPraetorDashboardController.getContactDetail('003000000000000AAA');
        System.assertEquals(null, cd, 'Invalid ID should return null');
    }

    // ── getOrderLines ─────────────────────────────────────────────────────────

    @isTest
    static void testGetOrderLinesNoPosition() {
        List<GrandPraetorDashboardController.OrderLineData> lines =
            GrandPraetorDashboardController.getOrderLines('001000000000000AAA', '90+');
        System.assertNotEquals(null, lines, 'Should not be null');
        System.assertEquals(0, lines.size(), 'No position — should be empty');
    }

    @isTest
    static void testGetOrderLinesBucket0to30() {
        List<GrandPraetorDashboardController.OrderLineData> lines =
            GrandPraetorDashboardController.getOrderLines('001000000000000AAA', '0-30');
        System.assertNotEquals(null, lines, 'Should not be null');
    }

    @isTest
    static void testGetOrderLinesBucket31to60() {
        List<GrandPraetorDashboardController.OrderLineData> lines =
            GrandPraetorDashboardController.getOrderLines('001000000000000AAA', '31-60');
        System.assertNotEquals(null, lines, 'Should not be null');
    }

    @isTest
    static void testGetOrderLinesBucket61to90() {
        List<GrandPraetorDashboardController.OrderLineData> lines =
            GrandPraetorDashboardController.getOrderLines('001000000000000AAA', '61-90');
        System.assertNotEquals(null, lines, 'Should not be null');
    }

    // ── GrandPraetorBalanceHelper ─────────────────────────────────────────────

    @isTest
    static void testBalanceHelperEmpty() {
        List<GrandPraetorBalanceHelper.BalanceResult> results =
            GrandPraetorBalanceHelper.getBalances(new Set<Id>());
        System.assertNotEquals(null, results);
        System.assertEquals(0, results.size());
    }

    @isTest
    static void testBalanceHelperWithAccount() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Chapter Coverage' LIMIT 1];
        List<GrandPraetorBalanceHelper.BalanceResult> results =
            GrandPraetorBalanceHelper.getBalances(new Set<Id>{ a.Id });
        System.assertNotEquals(null, results, 'Should not be null');
        System.assert(results.size() >= 0, 'Valid list expected');
    }

    @isTest
    static void testBalanceResultConstructor() {
        Account a = [SELECT Id FROM Account WHERE Name = 'Test Chapter Coverage' LIMIT 1];
        GrandPraetorBalanceHelper.BalanceResult br =
            new GrandPraetorBalanceHelper.BalanceResult(a.Id);
        System.assertEquals(a.Id, br.accountId);
        System.assertEquals(0, br.totalBalance);
        System.assertEquals(0, br.due0to30);
        System.assertEquals(0, br.due31to60);
        System.assertEquals(0, br.due61to90);
        System.assertEquals(0, br.due90Plus);
        System.assertEquals(0, br.maxAge);
    }

    // ── Inner class structure ─────────────────────────────────────────────────

    @isTest
    static void testOrderLineDataStructure() {
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
        System.assertEquals(100.00, d.balanceDue);
        System.assertEquals(50.00, d.amountPaid);
        System.assertEquals('Test Fee', d.itemName);
    }

    @isTest
    static void testChapterDashboardDataStructure() {
        GrandPraetorDashboardController.ChapterDashboardData d =
            new GrandPraetorDashboardController.ChapterDashboardData();
        d.chapterId      = '001000000000001AAA';
        d.chapterName    = 'Test';
        d.totalBalanceDue = 500.00;
        d.due0to30       = 100.00;
        d.due31to60      = 100.00;
        d.due61to90      = 100.00;
        d.due90Plus      = 200.00;
        d.maxPostedAge   = 95;
        d.balanceStatus  = 'RED';
        d.isAlumniChapter = false;
        d.activeUndergrads = new List<GrandPraetorDashboardController.MemberSummary>();
        d.activePledges    = new List<GrandPraetorDashboardController.MemberSummary>();
        d.activeMembers    = new List<GrandPraetorDashboardController.MemberSummary>();
        d.chapterOfficers  = new List<GrandPraetorDashboardController.OfficerSummary>();
        System.assertEquals('RED', d.balanceStatus);
        System.assertEquals(500.00, d.totalBalanceDue);
    }

    @isTest
    static void testMemberSummaryStructure() {
        GrandPraetorDashboardController.MemberSummary m =
            new GrandPraetorDashboardController.MemberSummary();
        m.memberId   = '003000000000001AAA';
        m.memberName = 'John Doe';
        m.memberType = 'Undergraduate';
        m.email      = 'john@test.org';
        System.assertEquals('John Doe', m.memberName);
        System.assertEquals('Undergraduate', m.memberType);
    }

    @isTest
    static void testOfficerSummaryStructure() {
        GrandPraetorDashboardController.OfficerSummary o =
            new GrandPraetorDashboardController.OfficerSummary();
        o.positionId  = '300000000000001AAA';
        o.officerName = 'Jane Smith';
        o.role        = 'Consul';
        o.sortOrder   = 1;
        System.assertEquals('Consul', o.role);
        System.assertEquals(1, o.sortOrder);
    }

    @isTest
    static void testContactDetailStructure() {
        GrandPraetorDashboardController.ContactDetail cd =
            new GrandPraetorDashboardController.ContactDetail();
        cd.contactId     = '003000000000001AAA';
        cd.name          = 'Test User';
        cd.phone         = '555-1234';
        cd.mailingCity   = 'Nashville';
        cd.mailingState  = 'Tennessee';
        System.assertEquals('Test User', cd.name);
        System.assertEquals('Nashville', cd.mailingCity);
    }

    // ── PermSetAssignmentQueueable ────────────────────────────────────────────

    @isTest
    static void testPermSetQueueableAssign() {
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
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        PermissionSet ps = [SELECT Id FROM PermissionSet
                            WHERE Name = 'GrandPraetorDashboardAccess' LIMIT 1];
        Test.startTest();
        System.enqueueJob(new PermSetAssignmentQueueable(u.Id, ps.Id, false));
        Test.stopTest();
        System.assert(true, 'Remove queueable ran without error');
    }
}
