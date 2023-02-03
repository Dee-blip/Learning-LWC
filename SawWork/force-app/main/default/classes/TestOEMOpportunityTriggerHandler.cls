@isTest

public class TestOEMOpportunityTriggerHandler {
    
    static {
        utilTestClass.insertCustomSettings();
    }
    private static OEM_Opportunity__c createOEMOpportunities(Id AccountId, String stage, Integer i) {
        
        OEM_Opportunity__c o = createOEMOpportunity('__ TEST'+i,stage);
        o.Account_Name__c = AccountId;
        o.Close_Date__c = Date.today();
        return o;
    }
    
    private static Id createAccount(){
        Account a = utilTestClass.CreateAccount('__ TEST');
        Database.insert(a);
        return a.id;
    }
    
    public static OEM_Opportunity__c createOEMOpportunity(String pOpptyName, String pStageName)
    {
        OEM_Opportunity__c opp = new OEM_Opportunity__c();
        opp.Name = pOpptyName;
        opp.Stage__c = pStageName;
        opp.Amount__c = 10000;
        return opp;
    }
    
    public static testmethod void testUpdationOfAmountWithUSDCurrency() {
    
        // create account
        Id accountId = createAccount();
        
        List<OEM_Opportunity__c> listOfTestOEMOpp = new List<OEM_Opportunity__c>();
        
        Integer numOfTimes=20;
        for(Integer num=0 ; num<numOfTimes ; num++){
            OEM_Opportunity__c o = createOEMOpportunity('TEST '+num,'3-Qualified');
            o.Account_Name__c = accountId;
            o.CurrencyIsoCode = 'USD';
            o.name = 'test'+ String.valueof(num+1);
            o.Close_Date__c    = Date.today().addDays(60);
            listOfTestOEMOpp.add(o);
        }
        insert(listOfTestOEMOpp);
        
        List<OEM_Opportunity__c> oemOppAfterInsertList = [Select id,Amount__c,CurrencyISOCode,Amount_In_USD__c,Close_Date__c from OEM_Opportunity__c limit 20];
        
        for(OEM_Opportunity__c oemOpp : oemOppAfterInsertList ) {
            System.assertEquals(oemOpp.Amount_In_USD__c, oemOpp.Amount__c);
        }
        
        //change closedate and verify that MRR and MRR in dollar fields are same
        for(OEM_Opportunity__c OEMOpportunity : oemOppAfterInsertList ) {
            OEMOpportunity.Close_Date__c = OEMOpportunity.Close_Date__c + (90);
        }
        update listOfTestOEMOpp;
        
        List<OEM_Opportunity__c> oemOppAfterUpdateList = [Select id,Amount__c,Amount_In_USD__c,Close_Date__c from OEM_Opportunity__c limit 20];
        
        for(OEM_Opportunity__c oemOppAfterUpdate : oemOppAfterUpdateList ) {
            System.assertEquals(oemOppAfterUpdate.Amount_in_USD__c, oemOppAfterUpdate.Amount__c);
        }
        
    }
    
    public static testmethod void testUpdationOfAmountWithNonUSDCurrency() {
    
        // create account
        Id accountId = createAccount();
        
        List<OEM_Opportunity__c> listOfTestOEMOpp = new List<OEM_Opportunity__c>();
        
        Integer numOfTimes=10;
        
        for(Integer num=0 ; num<numOfTimes ; num++){
            OEM_Opportunity__c o = createOEMOpportunity('TEST '+num,'3-Qualified');
            o.Account_Name__c = accountId;
            o.CurrencyIsoCode = 'INR';
            o.name = 'test'+ String.valueof(num+1);
            o.Close_Date__c    = Date.today() + (-365-num);
            listOfTestOEMOpp.add(o);
        }
        insert(listOfTestOEMOpp);
        
        List<OEM_Opportunity__c> oemOppAfterInsertList = [Select id,Amount__c,CurrencyISOCode,Amount_In_USD__c,Close_Date__c from OEM_Opportunity__c limit 10];
        
        List<DatedConversionRate> dcrList = [SELECT IsoCode, ConversionRate, NextStartDate, StartDate
                                             FROM DatedConversionRate 
                                             WHERE IsoCode = 'INR'];
                                             
        for(OEM_Opportunity__c OEMOpp : oemOppAfterInsertList)
        {
            //Opportunity parentOpp = mapOfOpportunityIdToOpportunity.get(oli.OpportunityId);
            
            for(DatedConversionRate tempDCR : dcrList)
            {
                if(tempDCR.StartDate <= OEMOpp.Close_Date__c && tempDCR.NextStartDate > OEMOpp.Close_Date__c)
                {
                    System.assertEquals(OEMOpp.Amount_In_USD__c, (OEMOpp.Amount__c / tempDCR.ConversionRate));
                }
            }
        }
       
    }

    public static testmethod void testupdateForecastCategory() {
    
        // create account
        Id accountId = createAccount();
        
        List<OEM_Opportunity__c> listOfTestOEMOpp = new List<OEM_Opportunity__c>();
        
        
            OEM_Opportunity__c o = createOEMOpportunity('TEST 12','3-Qualified');
            o.Account_Name__c = accountId;
            o.CurrencyIsoCode = 'INR';
            o.Close_Date__c    = Date.today() + (-365);

            listOfTestOEMOpp.add(o);

            OEM_Opportunity__c oem = createOEMOpportunity('TEST 123','3-Qualified');
            oem.Account_Name__c = accountId;
            oem.CurrencyIsoCode = 'INR';
            oem.Close_Date__c    = Date.today() + (-365);

            listOfTestOEMOpp.add(oem);

            OEM_Opportunity__c oem2 = createOEMOpportunity('TEST 1234','5-Closed/Booked');
            oem2.Account_Name__c = accountId;
            oem2.CurrencyIsoCode = 'INR';
            oem2.Close_Date__c    = Date.today() + (-365);

            listOfTestOEMOpp.add(oem2);

        
        insert(listOfTestOEMOpp);


        
        List<OEM_Opportunity__c> oemOppAfterInsertList = [Select id,Name,Override_Forecast_Category__c,Forecast_Category__c,Stage__c,Amount__c,CurrencyISOCode,Amount_In_USD__c,Close_Date__c from OEM_Opportunity__c limit 10];
        List<OEM_Opportunity__c> oemOppAfterUpdate = new List<OEM_Opportunity__c>();
        
                                             
        for(OEM_Opportunity__c OEMOpp : oemOppAfterInsertList)
        {
                   
            if(OEMOpp.Name == 'TEST 12' || OEMOpp.Name == 'TEST 1234')
            {
                OEMOpp.Override_Forecast_Category__c = 'Best Case';
                oemOppAfterUpdate.add(OEMOpp);
            }
            else if(OEMOpp.Name == 'TEST 123')
            {
                OEMOpp.Stage__c = '5-Closed/Booked';
                oemOppAfterUpdate.add(OEMOpp);
            }
            
        }

        update oemOppAfterUpdate;
    }


       
    
}