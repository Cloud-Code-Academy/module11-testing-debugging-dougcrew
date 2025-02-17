public class TestDataFactory {
    
    public static Account createAccount(){
        Account acc = new Account();
           acc.Name = 'Test Account';
            return acc;
    }
    public static Contact createContact(String email, Id accountId) {
        Contact cont = new Contact(
            AccountId = accountId,
            LastName = 'Test Name',
            Email = email
            ); 
            insert cont;
            return cont;



    }
    public static List<Lead> createAndConvertLeads(Integer numLeads, String leadSource, String email, String phone, String industry, Boolean shouldConvert) {
        // Create basic leads first
        List<Lead> leads = new List<Lead>();
        
        for(Integer i = 0; i < numLeads; i++) {
            Lead lead = new Lead(
                LastName = 'TestLead' + i,
                Company = 'TestCompany' + i,
                LeadSource = leadSource,
                Email = email,
                Phone = phone,
                Industry = industry,
                Status = 'Open - Not Contacted'
            );
            leads.add(lead);
        }
        
        insert leads;
        
        if (shouldConvert) {
            // First create an account to link the converted lead to
            Account acc = new Account(Name = 'Test Account');
            insert acc;
            
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
            
            for(Lead lead : leads) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(lead.Id);
                lc.setConvertedStatus('Closed - Converted');  // Make sure this matches your org's valid converted status
                lc.setAccountId(acc.Id);  // Set the account Id
                lc.setDoNotCreateOpportunity(true);  // Set to false if you need opportunities
                leadConverts.add(lc);
            }
            
            try {
                List<Database.LeadConvertResult> lcrs = Database.convertLead(leadConverts, false);
                // Check for conversion success
                for(Database.LeadConvertResult lcr : lcrs) {
                    if(!lcr.isSuccess()) {
                        System.debug('Lead conversion failed: ' + lcr.getErrors());
                        throw new TestDataFactoryException('Lead conversion failed: ' + lcr.getErrors());
                    }
                }
            } catch(Exception e) {
                System.debug('Lead conversion exception: ' + e.getMessage());
                throw e;
            }
        }
        
        return leads;
    }
    
    public class TestDataFactoryException extends Exception {}
}