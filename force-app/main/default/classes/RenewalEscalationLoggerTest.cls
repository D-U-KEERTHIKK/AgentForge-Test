@IsTest
private class RenewalEscalationLoggerTest {

    @TestSetup
    static void setup() {
        // Create test users
        User testUser = new User(
            Username = 'testuser@renewal.test',
            Email = 'testuser@renewal.test',
            FirstName = 'Test',
            LastName = 'User',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert testUser;

        User escalationUser = new User(
            Username = 'escalationuser@renewal.test',
            Email = 'escalationuser@renewal.test',
            FirstName = 'Escalation',
            LastName = 'User',
            Alias = 'euser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert escalationUser;
    }

    @IsTest
    static void testCreateEscalationLogsHappyPath() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@renewal.test' LIMIT 1];
        User escalationUser = [SELECT Id FROM User WHERE Username = 'escalationuser@renewal.test' LIMIT 1];

        System.runAs(testUser) {
            // Create test account and opportunity
            Account testAccount = new Account(Name = 'Test Account');
            insert testAccount;

            Opportunity testOpp = new Opportunity(
                Name = 'Test Renewal Opportunity',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(15),
                OwnerId = testUser.Id
            );
            insert testOpp;

            // Create escalation request using Map for invocable input
            Map<String, Object> requestMap = new Map<String, Object>();
            requestMap.put('opportunityId', testOpp.Id);
            requestMap.put('escalatedToUserId', escalationUser.Id);
            requestMap.put('escalationDate', System.today());
            requestMap.put('notes', 'Test escalation note');

            List<Map<String, Object>> requests = new List<Map<String, Object>>{requestMap};

            Test.startTest();
            RenewalEscalationLogger.createEscalationLogs(requests);
            Test.stopTest();

            // Verify escalation log was created
            List<Renewal_Escalation_Log__c> logs = [
                SELECT Id, Renewal_Escalation_Log_Opportunity__c, Renewal_Escalation_Log_EscalatedTo__c, 
                       Renewal_Escalation_Log_EscalationDate__c, Renewal_Escalation_Log_Notes__c
                FROM Renewal_Escalation_Log__c
            ];

            Assert.areEqual(1, logs.size(), 'Should create exactly one escalation log');
            Assert.areEqual(testOpp.Id, logs[0].Renewal_Escalation_Log_Opportunity__c, 'Opportunity ID should match');
            Assert.areEqual(escalationUser.Id, logs[0].Renewal_Escalation_Log_EscalatedTo__c, 'Escalated To user should match');
            Assert.areEqual(System.today(), logs[0].Renewal_Escalation_Log_EscalationDate__c, 'Escalation date should match');
            Assert.areEqual('Test escalation note', logs[0].Renewal_Escalation_Log_Notes__c, 'Notes should match');
        }
    }

    @IsTest
    static void testCreateEscalationLogsBulk() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@renewal.test' LIMIT 1];
        User escalationUser = [SELECT Id FROM User WHERE Username = 'escalationuser@renewal.test' LIMIT 1];

        System.runAs(testUser) {
            // Create test account
            Account testAccount = new Account(Name = 'Test Account Bulk');
            insert testAccount;

            // Create multiple test opportunities
            List<Opportunity> opportunities = new List<Opportunity>();
            for (Integer i = 0; i < 10; i++) {
                opportunities.add(new Opportunity(
                    Name = 'Bulk Test Opp ' + i,
                    AccountId = testAccount.Id,
                    StageName = 'Prospecting',
                    CloseDate = System.today().addDays(20 + i),
                    OwnerId = testUser.Id
                ));
            }
            insert opportunities;

            // Create bulk escalation requests
            List<Map<String, Object>> requests = new List<Map<String, Object>>();
            for (Integer i = 0; i < opportunities.size(); i++) {
                Map<String, Object> requestMap = new Map<String, Object>();
                requestMap.put('opportunityId', opportunities[i].Id);
                requestMap.put('escalatedToUserId', escalationUser.Id);
                requestMap.put('escalationDate', System.today().addDays(i));
                requestMap.put('notes', 'Bulk escalation note ' + i);
                requests.add(requestMap);
            }

            Test.startTest();
            RenewalEscalationLogger.createEscalationLogs(requests);
            Test.stopTest();

            // Verify all escalation logs were created
            List<Renewal_Escalation_Log__c> logs = [
                SELECT Id, Renewal_Escalation_Log_Opportunity__c, Renewal_Escalation_Log_Notes__c
                FROM Renewal_Escalation_Log__c
                ORDER BY Renewal_Escalation_Log_Notes__c ASC
            ];

            Assert.areEqual(10, logs.size(), 'Should create 10 escalation logs');
            
            for (Integer i = 0; i < logs.size(); i++) {
                Assert.isNotNull(logs[i].Renewal_Escalation_Log_Opportunity__c, 
                    'Opportunity ID should not be null for index ' + i);
                Assert.areEqual('Bulk escalation note ' + i, logs[i].Renewal_Escalation_Log_Notes__c, 
                    'Notes should match for index ' + i);
            }
        }
    }

    @IsTest
    static void testCreateEscalationLogsEmptyList() {
        User testUser = [SELECT Id FROM User WHERE Username = 'testuser@renewal.test' LIMIT 1];

        System.runAs(testUser) {
            List<Map<String, Object>> requests = new List<Map<String, Object>>();

            Test.startTest();
            RenewalEscalationLogger.createEscalationLogs(requests);
            Test.stopTest();

            List<Renewal_Escalation_Log__c> logs = [SELECT Id FROM Renewal_Escalation_Log__c];
            Assert.areEqual(0, logs.size(), 'Should not create any logs for empty request list');
        }
    }

    @IsTest
    static void testCreateEscalationLogsWithDifferentUsers() {
        User testUser1 = [SELECT Id FROM User WHERE Username = 'testuser@renewal.test' LIMIT 1];
        User escalationUser = [SELECT Id FROM User WHERE Username = 'escalationuser@renewal.test' LIMIT 1];

        // Create second test user for owner
        User testUser2 = new User(
            Username = 'testuser2@renewal.test',
            Email = 'testuser2@renewal.test',
            FirstName = 'Test',
            LastName = 'User2',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1].Id
        );
        insert testUser2;

        System.runAs(testUser1) {
            // Create test account and opportunities
            Account testAccount = new Account(Name = 'Test Account Multi User');
            insert testAccount;

            Opportunity opp1 = new Opportunity(
                Name = 'Opp User1',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(15),
                OwnerId = testUser1.Id
            );
            Opportunity opp2 = new Opportunity(
                Name = 'Opp User2',
                AccountId = testAccount.Id,
                StageName = 'Prospecting',
                CloseDate = System.today().addDays(20),
                OwnerId = testUser2.Id
            );
            insert new List<Opportunity>{opp1, opp2};

            // Create escalation requests
            List<Map<String, Object>> requests = new List<Map<String, Object>>();
            
            Map<String, Object> req1Map = new Map<String, Object>();
            req1Map.put('opportunityId', opp1.Id);
            req1Map.put('escalatedToUserId', escalationUser.Id);
            req1Map.put('escalationDate', System.today());
            req1Map.put('notes', 'Escalated from User1');
            requests.add(req1Map);

            Map<String, Object> req2Map = new Map<String, Object>();
            req2Map.put('opportunityId', opp2.Id);
            req2Map.put('escalatedToUserId', escalationUser.Id);
            req2Map.put('escalationDate', System.today());
            req2Map.put('notes', 'Escalated from User2');
            requests.add(req2Map);

            Test.startTest();
            RenewalEscalationLogger.createEscalationLogs(requests);
            Test.stopTest();

            // Verify both escalation logs were created correctly
            List<Renewal_Escalation_Log__c> logs = [
                SELECT Id, Renewal_Escalation_Log_Opportunity__c, Renewal_Escalation_Log_Notes__c
                FROM Renewal_Escalation_Log__c
                ORDER BY Renewal_Escalation_Log_Notes__c ASC
            ];

            Assert.areEqual(2, logs.size(), 'Should create 2 escalation logs');
            Assert.areEqual('Escalated from User1', logs[0].Renewal_Escalation_Log_Notes__c, 'First escalation note should match');
            Assert.areEqual('Escalated from User2', logs[1].Renewal_Escalation_Log_Notes__c, 'Second escalation note should match');
        }
    }
}