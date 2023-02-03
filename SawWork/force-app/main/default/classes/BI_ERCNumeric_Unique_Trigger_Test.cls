@isTest(SeeAllData=true)
private class BI_ERCNumeric_Unique_Trigger_Test
{
	testmethod static void beforeInsertPositive(){
        List<Account> accs = new List<Account>();
        accs = [select Id, AKERC__c from Account where AKERC__c = '1ABD' and ERC_Numeric__c = '1223'];
        if(accs.size() == 0){
            Account acc = new Account(Name = 'account AKERC test', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0', AKERC__c = '1ABD');
            insert acc;
        accs = [select id from Account where AKERC__c = '1ABD'];
        System.assertNotEquals(accs.size(),0);
        }

	}

    
    testmethod static void beforeInsertNegative(){
        List<Account> accs = new List<Account>();

        accs = [select Id, AKERC__c from Account where  AKERC__c = 'ADGJ' and ERC_Numeric__c = '2345'];
        if(accs.size() == 0){
            Account acc =  new Account(Name = 'account AKERC test', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0', AKERC__c = 'ADGJ');  

            insert acc;
        }   
        
        accs = [select Id, AKERC__c from Account where  AKERC__c = 'ADGK'];
        if(accs.size() == 0){

           Account acc =  new Account(Name = 'account AKERC2 test', Website = 'wwww.akamai.com', Support_Level__c = 'Premium_2.0', AKERC__c = 'ADGK');
            try{
                insert acc;
                }

            catch(Exception exe){
                accs = [select id from Account where AKERC__c = 'ADGK'];
                System.assertEquals(accs.size(),0);
            }
        }
    }
}