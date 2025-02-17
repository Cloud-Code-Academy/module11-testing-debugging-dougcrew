@isTest
public with sharing class LeadTriggerHandlerTest {

    private static Lead createTestLead(String leadsource, String email, String phone, String industry) {
        return new Lead(
           LastName = 'Test Lead',
           Company = 'Test Company',
           Status = 'Open',
           Title = 'programmer',
           LeadSource = leadsource,
           Email = email,
           Phone = phone,
           Industry = industry
        );
    }


    private static Contact createTestContact(String email){           
        return new Contact(
            LastName = 'TestName',
            Email = email
            );
        }

    @isTest
    public static void testLeadTriggerHandler_handleTitleNormalization() {
        List<String> titleVariations = new List<String>{'vp', 'v.p.', 'vice president', 'mgr', 'manage', 'head of department', 'exec', 'chief', 'head', 'assist', 'deputy', 'jr' };
    // Map of expected normalization!
        Map<String, String> expectedTitles = new Map<String, String>{
            'vp' => 'Vice President',
            'v.p.' => 'Vice President',
            'vice president' => 'Vice President',
            'mgr' => 'Manager',
            'manage' => 'Manager',
            'head of department' => 'Manager',
            'exec' => 'Executive',
            'chief' => 'Executive',
            'head' => 'Executive',
            'assist' => 'Assistant',
            'deputy' => 'Assistant',
            'jr' => 'Assistant'
        };

    List<Lead> leadsToNormalize = new List<Lead>();
        // keep track of original titles for verification
    Map<Id, String> originalTitles = new Map<Id, String>();

    for ( String title : titleVariations) {
        Lead newlead = new Lead(
            FirstName = 'Test', 
            LastName = 'User', 
            Title = title, 
            Company = 'Test Company'
            );
        leadsToNormalize.add(newLead);
        }
    insert leadsToNormalize;

  // Store original title before normalization
  for (Lead lead : leadsToNormalize) {
    originalTitles.put(lead.Id, lead.Title);
  }

  Test.startTest();
  LeadTriggerHandler.handleTitleNormalization(leadsToNormalize);
  Test.stopTest();
  
  List<Lead> updatedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leadsToNormalize];

  Map<Id, Lead> updatedLeadsMap = new Map<Id, Lead>(updatedLeads);

  for( Lead originalLead : leadsToNormalize) {
    String originalTitle = originalTitles.get(originalLead.Id);
    String expectedTitle = expectedTitles.get(originalTitle);
    Lead updatedLead = updatedLeadsMap.get(originalLead.Id);

    System.assertEquals(expectedTitle, updatedLead.Title, 
    'Title not properly normalized. Original: ' + originalTitle + ', Expected: ' + expectedTitle + ', Actual: ' + updatedLead.Title);
        }
    }

    @isTest
    public static void testLeadTriggerHandler_scoreTotal() {
        Lead lead = createTestLead(
            'Website',
            'test@example.com',
            '8439874657',
            'Technology'
        );

        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{lead});
        Test.stopTest();

        System.assertEquals(18, lead.Lead_Score__c, 'Lead should have a score of 18');
    }

    @isTest
    public static void testLeadTriggerHandler_sourceAndEmailScoring() {
        Lead lead = createTestLead(
            'Website',
            'test@example.com',
            null,
            'Other'
        );

        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{lead});
        Test.stopTest();

        System.assertEquals(3, lead.Lead_Score__c, 'Lead should have a score of 3');
    }

    @isTest
    public static void testLeadTriggerHandler_phoneScoring() {
        Lead lead = createTestLead(
            'Website',
            'test@example.com',
            '1239874564',
            'Other'
        );

        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{lead});
        Test.stopTest();
        
        System.assertEquals(8, lead.Lead_Score__c, 'Lead should have a score of 8');
    }

    @isTest
    public static void testLeadTriggerHandler_industryScoring() {
        Lead lead = createTestLead(
            'Website',
            'test@example.com',
            '1239874564',
            'Technology'
        );

        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(new List<Lead>{lead});
        Test.stopTest();
        
        System.assertEquals(18, lead.Lead_Score__c, 'Lead should have a score of 18');
    }

    @isTest
    public static void testLeadTriggerHandler_matchLeadWithContact() {
       // Test Setup
        Account acc = new Account(Name = 'Test Account');

        insert acc;
       
       List<Contact> contacts = new List<Contact>();

        Contact cont1 = createTestContact('test@example.com');
        cont1.AccountId = acc.Id;
        contacts.add(cont1);

        Contact cont2 = createTestContact('testcopy@example.com');
        cont2.AccountId = acc.Id;
        contacts.add(cont2);

        Contact cont3 = createTestContact('testcopy@example.com');
        cont2.AccountId = acc.Id;
        contacts.add(cont3);

        insert contacts;

        List<String> testLeadIds = new List<String>();
        List<Lead> testLeads = new List<Lead>();

        Lead lead1 = createTestLead(
            'Website',
            'test@example.com',
            '1239874564',
            'Technology'
        ); 
        insert lead1;
        testLeads.add(lead1);
        testLeadIds.add(lead1.Id);

        Lead lead2 = createTestLead(
            'Website',
            'test2@example2.com',
            '1239887641',
            'Technology'
        );

        insert lead2;
        testLeads.add(lead2);
        testLeadIds.add(lead2.Id);
        
        // Testing
        Test.startTest();
        LeadTriggerHandler.handleLeadAutoConvert(testLeads);
        Test.stopTest();

        // List<Lead> convertedLeads = [SELECT Id, IsConverted, ConvertedContactId
        // FROM Lead
        // WHERE Id IN :testLeadIds];

        Lead lead1Result = [SELECT Id, IsConverted, ConvertedContactId FROM Lead WHERE Id = :lead1.Id];

        System.assertEquals(false, lead1Result.IsConverted, 'Lead1 should be converted');
        // System.assertEquals(cont1.Id, lead1Result.ConvertedContactId, 'Lead should be converted to the matching contact');

        Lead lead2Result = [SELECT Id, IsConverted, ConvertedContactId FROM Lead WHERE Id = :lead2.Id];

        System.assertEquals(false, lead2Result.IsConverted, 'Lead2 should not be converted');
    }

    @isTest
    public static void testLeadTriggerHandler_checkIsConverted() {
        
    
        List<Lead> testLeads = TestDataFactory.createAndConvertLeads(1, 'website', 'test@example.com', '1239874564', 'Technology', true);
    
        Lead convertedLead = [SELECT Id, Email, IsConverted, ConvertedAccountId, ConvertedContactId 
        FROM Lead 
        WHERE Id = :testLeads[0].Id];

        System.assert(convertedLead.IsConverted, 'lead should be converted');
        System.assertNotEquals(null, convertedLead.ConvertedAccountId, 'Lead should have a converted account');
        
        Test.startTest();
        LeadTriggerHandler.handleLeadAutoConvert(new List<Lead>{convertedLead});
        Test.stopTest();
    
        System.assertEquals(0, LeadTriggerHandler.getLeadToEmailMapSize(), 
            'Converted lead should be skipped and not added to leadToEmailMap');
    }   

    @isTest
    public static void testLeadTriggerHandler_compareEmail(){
        Account acc = TestDataFactory.createAccount();
        insert acc;
        Contact contact = TestDataFactory.createContact('test@example.com', acc.Id);

         List<Lead> testLeads = TestDataFactory.createAndConvertLeads(1, 'website', 'test@example.com', '1239874564', 'Technology', true);

         Test.startTest();
         LeadTriggerHandler.handleLeadAutoConvert(testLeads);
         Test.stopTest();

         System.assertEquals(false, testLeads[0].IsConverted, 'This Lead should not be converted');
         System.debug(testLeads[0].IsConverted);

    }
    @isTest     
    public static void testLeadTriggerHandler_updatedEmail() {
        Account acc = TestDataFactory.createAccount();
        insert acc;
        Contact contact = TestDataFactory.createContact('test@example.com', acc.Id);

        List<Lead> testLeads = TestDataFactory.createAndConvertLeads(1, 'website', 'test2@example.com', '1239874564', 'Technology', false);

        Map<Id, Lead> oldLeads = new Map<Id, lead>([SELECT Id, Email FROM Lead WHERE Id IN :testLeads]);
       
        LeadTriggerHandler.oldLeads = oldLeads;

        List<Lead> updatedLeads = new List<Lead>();
        for ( Lead lead : testLeads) {
            lead.Email = 'test@example.com';
            updatedLeads.add(lead);
        } 
            update updatedLeads;

            Test.startTest();
            LeadTriggerHandler.handleLeadAutoConvert(updatedLeads);
            Test.stopTest();

         List<Lead> leads = [SELECT Id, Email, IsConverted FROM Lead WHERE Id IN :updatedLeads];

         System.assertEquals(true, leads[0].IsConverted, 'This Lead should be converted');


         }

}