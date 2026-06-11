public without sharing class GrandPraetorDashboardController {

    public class ChapterDashboardData {
        @AuraEnabled public String chapterId;
        @AuraEnabled public String chapterName;
        @AuraEnabled public String schoolName;
        @AuraEnabled public Date foundingDate;
        @AuraEnabled public String chapterAddress;
        @AuraEnabled public String chapterType;
        @AuraEnabled public String accountType;
        @AuraEnabled public Boolean isAlumniChapter;
        @AuraEnabled public String positionId;
        @AuraEnabled public String positionNumber;
        @AuraEnabled public Date positionStartDate;
        @AuraEnabled public String positionStatus;
        @AuraEnabled public Integer alumniCount;
        @AuraEnabled public Integer undergradCount;
        @AuraEnabled public Integer pledgeCount;
        @AuraEnabled public Integer pnmCount;
        @AuraEnabled public Integer associateCount;
        @AuraEnabled public Integer totalMemberCount;
        @AuraEnabled public List<MemberSummary> activeUndergrads;
        @AuraEnabled public List<MemberSummary> activePledges;
        @AuraEnabled public List<MemberSummary> activeMembers;
        @AuraEnabled public List<OfficerSummary> chapterOfficers;
        @AuraEnabled public String debugInfo;
        @AuraEnabled public Decimal totalBalanceDue;
        @AuraEnabled public Decimal due0to30;
        @AuraEnabled public Decimal due31to60;
        @AuraEnabled public Decimal due61to90;
        @AuraEnabled public Decimal due90Plus;
        @AuraEnabled public Integer maxPostedAge;
        @AuraEnabled public String balanceStatus; // GREEN, YELLOW, AMBER, RED
    }

    public class MemberSummary {
        @AuraEnabled public String memberId;
        @AuraEnabled public String memberName;
        @AuraEnabled public String memberType;
        @AuraEnabled public Date pledgeDate;
        @AuraEnabled public Date initiationDate;
        @AuraEnabled public String email;
        @AuraEnabled public String contactId;
    }

    public class OfficerSummary {
        @AuraEnabled public String positionId;
        @AuraEnabled public String officerName;
        @AuraEnabled public String role;
        @AuraEnabled public String email;
        @AuraEnabled public Date startDate;
        @AuraEnabled public Date initiationDate;
        @AuraEnabled public String status;
        @AuraEnabled public Integer sortOrder;
        @AuraEnabled public String contactId;
    }

    public class ContactDetail {
        @AuraEnabled public String contactId;
        @AuraEnabled public String name;
        @AuraEnabled public String phone;
        @AuraEnabled public String mobilePhone;
        @AuraEnabled public String email;
        @AuraEnabled public String mailingStreet;
        @AuraEnabled public String mailingCity;
        @AuraEnabled public String mailingState;
        @AuraEnabled public String mailingPostalCode;
        @AuraEnabled public String preferredEmail;
        @AuraEnabled public String preferredPhone;
    }

    public class OfficerComparator implements Comparator<OfficerSummary> {
        public Integer compare(OfficerSummary a, OfficerSummary b) {
            if (a.sortOrder != b.sortOrder) return a.sortOrder - b.sortOrder;
            String roleA = a.role != null ? a.role.toLowerCase() : '';
            String roleB = b.role != null ? b.role.toLowerCase() : '';
            if (roleA < roleB) return -1;
            if (roleA > roleB) return 1;
            return 0;
        }
    }

    public class ChapterComparator implements Comparator<ChapterDashboardData> {
        public Integer compare(ChapterDashboardData a, ChapterDashboardData b) {
            Integer sortA = chapterTypeSort(a.accountType);
            Integer sortB = chapterTypeSort(b.accountType);
            if (sortA != sortB) return sortA - sortB;
            String nameA = a.chapterName != null ? a.chapterName.toLowerCase() : '';
            String nameB = b.chapterName != null ? b.chapterName.toLowerCase() : '';
            if (nameA < nameB) return -1;
            if (nameA > nameB) return 1;
            return 0;
        }
        private Integer chapterTypeSort(String t) {
            if (t == null) return 99;
            String tl = t.toLowerCase();
            if (tl == 'undergrad chapter')     return 1;
            if (tl == 'associate chapter')     return 2;
            if (tl.contains('alumni chapter')) return 3;
            if (tl.contains('alumni club'))    return 4;
            if (tl.contains('alumni'))         return 5;
            return 6;
        }
    }

    private static Integer undergradOfficerSort(String role) {
        if (role == null) return 99;
        String r = role.toLowerCase();
        if (r == 'consul')                                                  return 1;
        if (r == 'pro consul')                                              return 2;
        if (r == 'quaestor')                                                return 3;
        if (r == 'magister')                                                return 4;
        if (r.contains('recruitment chair') || r == 'recruitment chairman') return 5;
        if (r == 'kustos')                                                  return 6;
        if (r.contains('risk manager'))                                     return 7;
        return 50;
    }

    private static Integer alumniOfficerSort(String role) {
        if (role == null) return 99;
        String r = role.toLowerCase();
        if (r.contains('president') && !r.contains('vice')) return 1;
        if (r.contains('vice president'))                   return 2;
        if (r.contains('treasurer'))                        return 3;
        if (r.contains('secretary'))                        return 4;
        return 50;
    }

    @AuraEnabled
    // Test-visible entry point — allows tests to pass contactId directly
    @TestVisible
    public static List<ChapterDashboardData> getDashboardDataForContact(Id contactId) {
        return getDashboardDataImpl(contactId);
    }

    @AuraEnabled
    public static List<ChapterDashboardData> getDashboardData() {
        Id userId = UserInfo.getUserId();
        User currentUser;
        try {
            currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        } catch(Exception e) {
            return new List<ChapterDashboardData>();
        }
        if (currentUser.ContactId == null) return new List<ChapterDashboardData>();
        return getDashboardDataImpl(currentUser.ContactId);
    }

    public static List<ChapterDashboardData> getDashboardDataImpl(Id contactId) {

        ChapterDashboardData debugData = new ChapterDashboardData();
        debugData.chapterId        = 'DEBUG';
        debugData.chapterName      = 'DEBUG';
        debugData.isAlumniChapter  = false;
        debugData.alumniCount      = 0;
        debugData.undergradCount   = 0;
        debugData.pledgeCount      = 0;
        debugData.pnmCount         = 0;
        debugData.associateCount   = 0;
        debugData.totalMemberCount = 0;
        debugData.activeUndergrads = new List<MemberSummary>();
        debugData.activePledges    = new List<MemberSummary>();
        debugData.activeMembers    = new List<MemberSummary>();
        debugData.chapterOfficers  = new List<OfficerSummary>();

        debugData.debugInfo = 'ContactId=' + contactId;

        List<OrderApi__Position__c> gpPositions;
        try {
            gpPositions = [
                SELECT Id, Name, OrderApi__Type__c, OrderApi__Status__c,
                       OrderApi__Start_Date__c, OrderApi__Account__c,
                       OrderApi__Account__r.Name,
                       OrderApi__Account__r.School__c,
                       OrderApi__Account__r.OrderApi__Founding_Date__c,
                       OrderApi__Account__r.BillingStreet,
                       OrderApi__Account__r.BillingCity,
                       OrderApi__Account__r.BillingState,
                       OrderApi__Account__r.BillingPostalCode,
                       OrderApi__Account__r.Type,
                       OrderApi__Account__r.RecordType.Name,
                       OrderApi__Account__r.OrderApi__Chapter_Status__c
                FROM OrderApi__Position__c
                WHERE OrderApi__Contact__c = :contactId
                  AND OrderApi__Role__c IN ('Grand Praetor', 'Assistant Grand Praetor')
                  AND OrderApi__Status__c = 'Active'
            ];
            debugData.debugInfo += ' | PositionCount=' + gpPositions.size();
        } catch(Exception e) {
            debugData.debugInfo += ' | POSITION_ERR=' + e.getMessage();
            return new List<ChapterDashboardData>{ debugData };
        }

        if (gpPositions.isEmpty()) {
            debugData.debugInfo += ' | FAIL=NoPositions';
            return new List<ChapterDashboardData>{ debugData };
        }

        Set<Id> chapterIds = new Set<Id>();
        for (OrderApi__Position__c pos : gpPositions) {
            if (pos.OrderApi__Account__c != null
                && (pos.OrderApi__Account__r.RecordType == null ||
                    pos.OrderApi__Account__r.RecordType.Name != 'Province')) {
                chapterIds.add(pos.OrderApi__Account__c);
            }
        }

        List<OrderApi__Member_Information__c> allMembers;
        try {
            allMembers = [
                SELECT Id, Name, OrderApi__Member_Name__c, Fon_Member_Type__c,
                       OrderApi__Member_Status__c, OrderApi__Pledge_Date__c,
                       OrderApi__Initiation_Date__c, OrderApi__Email__c,
                       OrderApi__Chapter__c, OrderApi__Member__c
                FROM OrderApi__Member_Information__c
                WHERE OrderApi__Chapter__c IN :chapterIds
                  AND Is_Current_chapter__c = true
                  AND OrderApi__Member_Status__c = 'Active'
                ORDER BY OrderApi__Member_Name__c ASC
            ];
        } catch(Exception e) {
            allMembers = new List<OrderApi__Member_Information__c>();
        }

        List<OrderApi__Position__c> officerPositions;
        try {
            officerPositions = [
                SELECT Id, Name, OrderApi__Role__c, OrderApi__Status__c,
                       OrderApi__Start_Date__c, OrderApi__Account__c,
                       OrderApi__Contact__c,
                       OrderApi__Contact__r.Name,
                       OrderApi__Contact__r.Initiation_Date__c,
                       OrderApi__Email__c
                FROM OrderApi__Position__c
                WHERE OrderApi__Account__c IN :chapterIds
                  AND OrderApi__Status__c = 'Active'
                  AND OrderApi__Type__c = 'Chapter'

            ];
        } catch(Exception e) {
            officerPositions = new List<OrderApi__Position__c>();
        }

        // Use helper class to get balance aging buckets
        Map<Id, GrandPraetorBalanceHelper.BalanceResult> balanceMap =
            new Map<Id, GrandPraetorBalanceHelper.BalanceResult>();
        for (GrandPraetorBalanceHelper.BalanceResult br : GrandPraetorBalanceHelper.getBalances(chapterIds)) {
            balanceMap.put(br.accountId, br);
        }

        Map<Id, List<OrderApi__Member_Information__c>> membersByChapter =
            new Map<Id, List<OrderApi__Member_Information__c>>();
        for (OrderApi__Member_Information__c mi : allMembers) {
            if (!membersByChapter.containsKey(mi.OrderApi__Chapter__c)) {
                membersByChapter.put(mi.OrderApi__Chapter__c, new List<OrderApi__Member_Information__c>());
            }
            membersByChapter.get(mi.OrderApi__Chapter__c).add(mi);
        }

        Map<Id, List<OrderApi__Position__c>> officersByChapter =
            new Map<Id, List<OrderApi__Position__c>>();
        for (OrderApi__Position__c pos : officerPositions) {
            if (!officersByChapter.containsKey(pos.OrderApi__Account__c)) {
                officersByChapter.put(pos.OrderApi__Account__c, new List<OrderApi__Position__c>());
            }
            officersByChapter.get(pos.OrderApi__Account__c).add(pos);
        }

        List<ChapterDashboardData> results = new List<ChapterDashboardData>();

        for (OrderApi__Position__c gpPos : gpPositions) {
            // Skip Province accounts
            if (gpPos.OrderApi__Account__r.RecordType != null &&
                gpPos.OrderApi__Account__r.RecordType.Name == 'Province') continue;
            ChapterDashboardData data = new ChapterDashboardData();
            data.chapterId       = gpPos.OrderApi__Account__c;
            data.chapterName     = gpPos.OrderApi__Account__r.Name;
            data.schoolName      = gpPos.OrderApi__Account__r.School__c;
            data.foundingDate    = gpPos.OrderApi__Account__r.OrderApi__Founding_Date__c;
            String chapterAddr = '';
            if (gpPos.OrderApi__Account__r.BillingStreet != null) chapterAddr += gpPos.OrderApi__Account__r.BillingStreet;
            if (gpPos.OrderApi__Account__r.BillingCity != null) chapterAddr += (chapterAddr.length() > 0 ? ', ' : '') + gpPos.OrderApi__Account__r.BillingCity;
            if (gpPos.OrderApi__Account__r.BillingState != null) chapterAddr += (chapterAddr.length() > 0 ? ', ' : '') + gpPos.OrderApi__Account__r.BillingState;
            if (gpPos.OrderApi__Account__r.BillingPostalCode != null) chapterAddr += ' ' + gpPos.OrderApi__Account__r.BillingPostalCode;
            data.chapterAddress  = chapterAddr.trim().length() > 0 ? chapterAddr.trim() : null;
            data.chapterType     = gpPos.OrderApi__Type__c;
            data.accountType     = gpPos.OrderApi__Account__r.Type;
            data.positionId      = gpPos.Id;
            data.positionNumber  = gpPos.Name;
            data.positionStartDate = gpPos.OrderApi__Start_Date__c;
            String chapStatus = gpPos.OrderApi__Account__r.OrderApi__Chapter_Status__c;
            data.positionStatus  = String.isNotBlank(chapStatus) ? chapStatus : gpPos.OrderApi__Status__c;
            data.debugInfo       = 'OK|BalMap=' + balanceMap.size() + '|Bal=' + data.totalBalanceDue + '|Age=' + data.maxPostedAge;

            // Balance data from helper
            GrandPraetorBalanceHelper.BalanceResult br = balanceMap.containsKey(gpPos.OrderApi__Account__c)
                ? balanceMap.get(gpPos.OrderApi__Account__c) : null;
            Decimal totalBal = br != null ? br.totalBalance : 0;
            Integer maxAge   = br != null ? br.maxAge : 0;
            data.totalBalanceDue = totalBal;
            data.due0to30        = br != null ? br.due0to30  : 0;
            data.due31to60       = br != null ? br.due31to60 : 0;
            data.due61to90       = br != null ? br.due61to90 : 0;
            data.due90Plus       = br != null ? br.due90Plus : 0;
            data.maxPostedAge    = maxAge;
            if (totalBal <= 0) {
                data.balanceStatus = 'BLUE';
            } else if (maxAge <= 30) {
                data.balanceStatus = 'GREEN';
            } else if (maxAge <= 60) {
                data.balanceStatus = 'YELLOW';
            } else if (maxAge <= 90) {
                data.balanceStatus = 'AMBER';
            } else {
                data.balanceStatus = 'RED';
            }

            String acctType = gpPos.OrderApi__Account__r.Type != null ? gpPos.OrderApi__Account__r.Type : '';
            String acctTypeLower = acctType.toLowerCase();
            String recType = gpPos.OrderApi__Account__r.RecordType != null
                ? gpPos.OrderApi__Account__r.RecordType.Name : '';
            Boolean isAlumni = acctTypeLower.contains('alumni') || recType == 'Province';
            data.isAlumniChapter = isAlumni;

            Integer alumniCount = 0, undergradCount = 0, pledgeCount = 0,
                    pnmCount = 0, associateCount = 0, totalCount = 0;
            List<MemberSummary> undergradList = new List<MemberSummary>();
            List<MemberSummary> pledgeList    = new List<MemberSummary>();
            List<MemberSummary> memberList    = new List<MemberSummary>();

            List<OrderApi__Member_Information__c> chapterMembers =
                membersByChapter.containsKey(gpPos.OrderApi__Account__c)
                    ? membersByChapter.get(gpPos.OrderApi__Account__c)
                    : new List<OrderApi__Member_Information__c>();

            for (OrderApi__Member_Information__c mi : chapterMembers) {
                String mType = mi.Fon_Member_Type__c;
                totalCount++;
                if (!isAlumni) {
                    if (mType == null) continue;
                    if (mType == 'Alumni')                    alumniCount++;
                    else if (mType == 'Undergrad')             undergradCount++;
                    else if (mType == 'Pledge')                pledgeCount++;
                    else if (mType == 'Potential New Member')  pnmCount++;
                    else if (mType == 'Associate Member')      associateCount++;
                    if (mType == 'Undergrad') {
                        MemberSummary ms  = new MemberSummary();
                        ms.memberId       = mi.Id;
                        ms.memberName     = mi.OrderApi__Member_Name__c != null ? mi.OrderApi__Member_Name__c : mi.Name;
                        ms.memberType     = mType;
                        ms.pledgeDate     = mi.OrderApi__Pledge_Date__c;
                        ms.initiationDate = mi.OrderApi__Initiation_Date__c;
                        ms.email          = mi.OrderApi__Email__c;
                        ms.contactId      = mi.OrderApi__Member__c;
                        undergradList.add(ms);
                    } else if (mType == 'Pledge') {
                        MemberSummary ms  = new MemberSummary();
                        ms.memberId       = mi.Id;
                        ms.memberName     = mi.OrderApi__Member_Name__c != null ? mi.OrderApi__Member_Name__c : mi.Name;
                        ms.memberType     = mType;
                        ms.pledgeDate     = mi.OrderApi__Pledge_Date__c;
                        ms.initiationDate = mi.OrderApi__Initiation_Date__c;
                        ms.email          = mi.OrderApi__Email__c;
                        ms.contactId      = mi.OrderApi__Member__c;
                        pledgeList.add(ms);
                    }
                } else {
                    MemberSummary ms  = new MemberSummary();
                    ms.memberId       = mi.Id;
                    ms.memberName     = mi.OrderApi__Member_Name__c != null ? mi.OrderApi__Member_Name__c : mi.Name;
                    ms.memberType     = mType;
                    ms.pledgeDate     = mi.OrderApi__Pledge_Date__c;
                    ms.initiationDate = mi.OrderApi__Initiation_Date__c;
                    ms.email          = mi.OrderApi__Email__c;
                    ms.contactId      = mi.OrderApi__Member__c;
                    memberList.add(ms);
                }
            }

            data.alumniCount      = alumniCount;
            data.undergradCount   = undergradCount;
            data.pledgeCount      = pledgeCount;
            data.pnmCount         = pnmCount;
            data.associateCount   = associateCount;
            data.totalMemberCount = totalCount;
            data.activeUndergrads = undergradList;
            data.activePledges    = pledgeList;
            data.activeMembers    = memberList;

            List<OfficerSummary> officers = new List<OfficerSummary>();
            List<OrderApi__Position__c> chapterOfficers =
                officersByChapter.containsKey(gpPos.OrderApi__Account__c)
                    ? officersByChapter.get(gpPos.OrderApi__Account__c)
                    : new List<OrderApi__Position__c>();

            for (OrderApi__Position__c op : chapterOfficers) {
                // Exclude Alumni Chapter Member from non-alumni chapters
                if (op.OrderApi__Role__c == 'Alumni Chapter Member' && !isAlumni) continue;
                // Exclude university staff roles
                if (op.OrderApi__Role__c == 'University President' ||
                    op.OrderApi__Role__c == 'University Vice President' ||
                    op.OrderApi__Role__c == 'University Dean of Students' ||
                    op.OrderApi__Role__c == 'Univ. Alumni Office' ||
                    (op.OrderApi__Role__c != null && op.OrderApi__Role__c.startsWith('KTLW Attendee')) ||
                    op.OrderApi__Role__c == 'Sweetheart') continue;
                OfficerSummary os = new OfficerSummary();
                os.positionId  = op.Id;
                os.officerName = op.OrderApi__Contact__r.Name;
                os.role        = op.OrderApi__Role__c;
                os.email       = op.OrderApi__Email__c;
                os.startDate   = op.OrderApi__Start_Date__c;
                os.status      = op.OrderApi__Status__c;
                os.contactId      = op.OrderApi__Contact__c;
                os.initiationDate = op.OrderApi__Contact__r != null
                    ? op.OrderApi__Contact__r.Initiation_Date__c : null;
                os.sortOrder   = isAlumni
                    ? alumniOfficerSort(op.OrderApi__Role__c)
                    : undergradOfficerSort(op.OrderApi__Role__c);
                officers.add(os);
            }
            officers.sort(new OfficerComparator());
            data.chapterOfficers = officers;
            results.add(data);
        }

        results.sort(new ChapterComparator());
        return results;
    }

    // Called from LWC when user clicks a contact name
    @AuraEnabled
    public static ContactDetail getContactDetail(Id contactId) {
        try {
            Contact c = [
                SELECT Id, Name, Phone, MobilePhone, Email,
                       OrderApi__Preferred_Email__c,
                       OrderApi__Preferred_Phone__c,
                       MailingStreet, MailingCity,
                       MailingState, MailingPostalCode
                FROM Contact
                WHERE Id = :contactId
                LIMIT 1
            ];
            ContactDetail cd       = new ContactDetail();
            cd.contactId           = c.Id;
            cd.name                = c.Name;
            cd.phone               = c.Phone;
            cd.mobilePhone         = c.MobilePhone;
            cd.email               = c.Email;
            cd.preferredEmail      = c.OrderApi__Preferred_Email__c;
            cd.preferredPhone      = c.OrderApi__Preferred_Phone__c;
            cd.mailingStreet       = c.MailingStreet;
            cd.mailingCity         = c.MailingCity;
            cd.mailingState        = c.MailingState;
            cd.mailingPostalCode   = c.MailingPostalCode;
            return cd;
        } catch(Exception e) {
            return null;
        }
    }

    public class OrderLineData {
        @AuraEnabled public String  salesOrderId;
        @AuraEnabled public String  salesOrderName;
        @AuraEnabled public String  itemName;
        @AuraEnabled public Decimal balanceDue;
        @AuraEnabled public Decimal amountPaid;
        @AuraEnabled public Date    postedDate;
        @AuraEnabled public Date    dueDate;
        @AuraEnabled public Decimal quantity;
        @AuraEnabled public Decimal total;
        @AuraEnabled public String  contactName;
    }

    @AuraEnabled
    public static List<OrderLineData> getOrderLines(Id chapterId, String bucket) {
        // Security gate — verify running user is an active GP on this chapter
        Id userId = UserInfo.getUserId();
        User currentUser;
        try {
            currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
        } catch(Exception e) { return new List<OrderLineData>(); }
        if (currentUser.ContactId == null) return new List<OrderLineData>();

        List<OrderApi__Position__c> gpCheck = [
            SELECT Id FROM OrderApi__Position__c
            WHERE OrderApi__Contact__c = :currentUser.ContactId
              AND OrderApi__Account__c = :chapterId
              AND OrderApi__Role__c    IN ('Grand Praetor', 'Assistant Grand Praetor')
              AND OrderApi__Status__c  = 'Active'
            LIMIT 1
        ];
        if (gpCheck.isEmpty()) return new List<OrderLineData>();

        // Step 1: Get parent Sales Orders for this chapter
        List<OrderApi__Sales_Order__c> orders = [
            SELECT Id, Name, OrderApi__Due_Date__c,
                   OrderApi__Posted_Date__c, Posted_Age__c,
                   OrderApi__Balance_Due__c
            FROM OrderApi__Sales_Order__c
            WHERE OrderApi__Account__c    = :chapterId
              AND OrderApi__Balance_Due__c > 0
              AND OrderApi__Is_Posted__c   = true
              AND OrderApi__Is_Voided__c   = false
              AND OrderApi__Entity__c       = 'Account'
        ];

        // Step 2: Filter to the requested bucket
        Set<Id> bucketOrderIds = new Set<Id>();
        for (OrderApi__Sales_Order__c so : orders) {
            Decimal age = so.Posted_Age__c != null ? so.Posted_Age__c : 0;
            Boolean inBucket = false;
            if      (bucket == '0-30')  inBucket = age <= 30;
            else if (bucket == '31-60') inBucket = age > 30 && age <= 60;
            else if (bucket == '61-90') inBucket = age > 60 && age <= 90;
            else if (bucket == '90+')   inBucket = age > 90;
            if (inBucket) bucketOrderIds.add(so.Id);
        }
        if (bucketOrderIds.isEmpty()) return new List<OrderLineData>();

        // Step 3: Get Sales Order Lines for those orders
        List<OrderApi__Sales_Order_Line__c> lines = [
            SELECT Id, Name,
                   OrderApi__Item_Name__c,
                   OrderApi__Balance_Due__c,
                   OrderApi__Quantity__c,
                   OrderApi__Total__c,
                   OrderApi__Contact__r.Name,
                   OrderApi__Sales_Order__c,
                   OrderApi__Sales_Order__r.Name,
                   OrderApi__Sales_Order__r.OrderApi__Due_Date__c,
                   OrderApi__Sales_Order__r.OrderApi__Posted_Date__c
            FROM OrderApi__Sales_Order_Line__c
            WHERE OrderApi__Sales_Order__c IN :bucketOrderIds
              AND OrderApi__Balance_Due__c  > 0
              AND OrderApi__Is_Posted__c    = true
            ORDER BY OrderApi__Sales_Order__r.OrderApi__Posted_Date__c ASC,
                     OrderApi__Item_Name__c ASC
        ];

        List<OrderLineData> results = new List<OrderLineData>();
        for (OrderApi__Sales_Order_Line__c ln : lines) {
            OrderLineData d    = new OrderLineData();
            d.salesOrderId     = ln.OrderApi__Sales_Order__c;
            d.salesOrderName   = ln.OrderApi__Sales_Order__r.Name;
            d.itemName         = ln.OrderApi__Item_Name__c;
            d.balanceDue       = ln.OrderApi__Balance_Due__c;
            d.postedDate       = ln.OrderApi__Sales_Order__r.OrderApi__Posted_Date__c;
            d.dueDate          = ln.OrderApi__Sales_Order__r.OrderApi__Due_Date__c;
            d.quantity         = ln.OrderApi__Quantity__c;
            d.total            = ln.OrderApi__Total__c;
            Decimal paid = (ln.OrderApi__Total__c != null && ln.OrderApi__Balance_Due__c != null)
                ? ln.OrderApi__Total__c - ln.OrderApi__Balance_Due__c : 0;
            d.amountPaid       = paid > 0 ? paid : 0;
            d.contactName      = ln.OrderApi__Contact__r != null
                                     ? ln.OrderApi__Contact__r.Name : null;
            results.add(d);
        }
        return results;
    }
}