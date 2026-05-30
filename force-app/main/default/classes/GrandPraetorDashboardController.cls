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
    public static List<ChapterDashboardData> getDashboardData() {

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

        Id userId = UserInfo.getUserId();
        debugData.debugInfo = 'UserId=' + userId;

        User currentUser;
        try {
            currentUser = [SELECT ContactId FROM User WHERE Id = :userId LIMIT 1];
            debugData.debugInfo += ' | ContactId=' + currentUser.ContactId;
        } catch(Exception e) {
            debugData.debugInfo += ' | USER_ERR=' + e.getMessage();
            return new List<ChapterDashboardData>{ debugData };
        }

        if (currentUser.ContactId == null) {
            debugData.debugInfo += ' | FAIL=NoContact';
            return new List<ChapterDashboardData>{ debugData };
        }

        Id contactId = currentUser.ContactId;

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
                       OrderApi__Account__r.RecordType.Name
                FROM OrderApi__Position__c
                WHERE OrderApi__Contact__c = :contactId
                  AND OrderApi__Role__c = 'Grand Praetor'
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
            if (pos.OrderApi__Account__c != null) chapterIds.add(pos.OrderApi__Account__c);
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
                       OrderApi__Contact__r.Name, OrderApi__Email__c
                FROM OrderApi__Position__c
                WHERE OrderApi__Account__c IN :chapterIds
                  AND OrderApi__Status__c = 'Active'
                  AND OrderApi__Type__c = 'Chapter'
            ];
        } catch(Exception e) {
            officerPositions = new List<OrderApi__Position__c>();
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
            data.positionStatus  = gpPos.OrderApi__Status__c;
            data.debugInfo       = 'OK';

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
                OfficerSummary os = new OfficerSummary();
                os.positionId  = op.Id;
                os.officerName = op.OrderApi__Contact__r.Name;
                os.role        = op.OrderApi__Role__c;
                os.email       = op.OrderApi__Email__c;
                os.startDate   = op.OrderApi__Start_Date__c;
                os.status      = op.OrderApi__Status__c;
                os.contactId   = op.OrderApi__Contact__c;
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
}
