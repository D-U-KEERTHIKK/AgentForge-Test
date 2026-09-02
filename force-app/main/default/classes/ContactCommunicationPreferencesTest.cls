/**
 * @description Test class for Contact communication preferences validation rules.
 * Validates: (1) Do_Not_Contact_Reason__c required when Preferred_Contact_Method__c = 'Do Not Contact'
 *            (2) MobilePhone required when Preferred_Contact_Method__c = 'SMS'
 */
@IsTest
public class ContactCommunicationPreferencesTest {

    /**
     * @description Create a test user with standard Contact permissions.
     */
    private static User createTestUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            FirstName = 'Test',
            LastName = 'User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'testuser' + System.currentTimeMillis() + '@example.com'
        );
        insert testUser;
        return testUser;
    }

    /**
     * @description Test that 'Do Not Contact' requires Do_Not_Contact_Reason__c to be populated.
     */
    @IsTest
    static void testDoNotContactRequiresReason() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Do Not Contact',
                Do_Not_Contact_Reason__c = null
            );

            Test.startTest();
            try {
                insert contact;
                System.assert(false, 'Expected validation error when Do Not Contact selected without reason');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('Do_Not_Contact_Reason_Required') || 
                    e.getMessage().contains('required'),
                    'Expected validation rule error: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test that 'Do Not Contact' with valid reason passes validation.
     */
    @IsTest
    static void testDoNotContactWithValidReason() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Do Not Contact',
                Do_Not_Contact_Reason__c = 'Customer Request'
            );

            Test.startTest();
            insert contact;
            Test.stopTest();

            Contact inserted = [SELECT Id, Preferred_Contact_Method__c, Do_Not_Contact_Reason__c FROM Contact WHERE Id = :contact.Id];
            Assert.areEqual('Do Not Contact', inserted.Preferred_Contact_Method__c);
            Assert.areEqual('Customer Request', inserted.Do_Not_Contact_Reason__c);
        }
    }

    /**
     * @description Test that SMS preference requires MobilePhone to be populated.
     */
    @IsTest
    static void testSmsRequiresMobilePhone() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'SMS',
                MobilePhone = null
            );

            Test.startTest();
            try {
                insert contact;
                System.assert(false, 'Expected validation error when SMS selected without MobilePhone');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('SMS_Requires_Mobile_Phone') || 
                    e.getMessage().contains('Mobile Phone'),
                    'Expected validation rule error: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test that SMS with valid MobilePhone passes validation.
     */
    @IsTest
    static void testSmsWithValidMobilePhone() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'SMS',
                MobilePhone = '+1234567890'
            );

            Test.startTest();
            insert contact;
            Test.stopTest();

            Contact inserted = [SELECT Id, Preferred_Contact_Method__c, MobilePhone FROM Contact WHERE Id = :contact.Id];
            Assert.areEqual('SMS', inserted.Preferred_Contact_Method__c);
            Assert.areEqual('+1234567890', inserted.MobilePhone);
        }
    }

    /**
     * @description Test that Email preference passes without Do_Not_Contact_Reason__c.
     */
    @IsTest
    static void testEmailMethodDoesNotRequireReason() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Email',
                Do_Not_Contact_Reason__c = null
            );

            Test.startTest();
            insert contact;
            Test.stopTest();

            Contact inserted = [SELECT Id, Preferred_Contact_Method__c, Do_Not_Contact_Reason__c FROM Contact WHERE Id = :contact.Id];
            Assert.areEqual('Email', inserted.Preferred_Contact_Method__c);
            Assert.isNull(inserted.Do_Not_Contact_Reason__c);
        }
    }

    /**
     * @description Test that Phone preference passes without MobilePhone.
     */
    @IsTest
    static void testPhoneMethodDoesNotRequireMobilePhone() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Phone',
                MobilePhone = null
            );

            Test.startTest();
            insert contact;
            Test.stopTest();

            Contact inserted = [SELECT Id, Preferred_Contact_Method__c, MobilePhone FROM Contact WHERE Id = :contact.Id];
            Assert.areEqual('Phone', inserted.Preferred_Contact_Method__c);
            Assert.isNull(inserted.MobilePhone);
        }
    }

    /**
     * @description Test that Marketing_Opt_In__c defaults to false.
     */
    @IsTest
    static void testMarketingOptInDefaults() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact'
            );

            Test.startTest();
            insert contact;
            Test.stopTest();

            Contact inserted = [SELECT Id, Marketing_Opt_In__c FROM Contact WHERE Id = :contact.Id];
            Assert.isFalse(inserted.Marketing_Opt_In__c, 'Marketing_Opt_In__c should default to false');
        }
    }

    /**
     * @description Test update with SMS preference and no MobilePhone fails validation.
     */
    @IsTest
    static void testUpdateSmsWithoutMobilePhoneFails() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Email'
            );
            insert contact;

            contact.Preferred_Contact_Method__c = 'SMS';
            contact.MobilePhone = null;

            Test.startTest();
            try {
                update contact;
                System.assert(false, 'Expected validation error on update');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('SMS_Requires_Mobile_Phone') || 
                    e.getMessage().contains('Mobile Phone'),
                    'Expected validation rule error: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }

    /**
     * @description Test update with Do Not Contact and no reason fails validation.
     */
    @IsTest
    static void testUpdateDoNotContactWithoutReasonFails() {
        User testUser = createTestUser();

        System.runAs(testUser) {
            Contact contact = new Contact(
                LastName = 'TestContact',
                Preferred_Contact_Method__c = 'Email'
            );
            insert contact;

            contact.Preferred_Contact_Method__c = 'Do Not Contact';
            contact.Do_Not_Contact_Reason__c = null;

            Test.startTest();
            try {
                update contact;
                System.assert(false, 'Expected validation error on update');
            } catch (DmlException e) {
                System.assert(
                    e.getMessage().contains('Do_Not_Contact_Reason_Required') || 
                    e.getMessage().contains('required'),
                    'Expected validation rule error: ' + e.getMessage()
                );
            }
            Test.stopTest();
        }
    }
}