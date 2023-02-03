//Created by Mayank Bansal as part of SFDC-4547
//Test Class: DRASubprocessAutomatedJobTest
//SFDC-4547-4

global class DRASubprocessAutomatedJob implements Database.Batchable<sObject>, Database.Stateful
{
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
        DateTime yesterday = System.now()-1;
        List<String> verticalList = new List<String>();
        List<String> subVerticalList = new List<String>();
        for(DRASubprocessConfig__c dra : [Select Country__c, Industry__c, 
                        Region_or_State__c, 
                        State_Code__c, 
                        SDR_Name__c, 
                        SDR_Name__r.isActive,
                        Sub_Vertical__c, 
                        Vertical__c 
                        from DRASubprocessConfig__c
                        where LastModifiedDate > :yesterday
                        order by createdDate desc
                        ])
        {
            verticalList.add(dra.Vertical__c);
            subVerticalList.add(dra.Sub_Vertical__c);
        }
        
        String ONA_User_Id = GSMSettings.getValue('ONA_User_Id');
        String query = 'Select id, name,Sub_Vertical__c, Vertical__c, Industry__c, BillingState, BillingCountry, Projected_Sales_Owner__c, OwnerId from Account where Owner.id = :ONA_User_Id and Vertical__c in :verticalList and Sub_Vertical__c in :subVerticalList';
        if(verticalList.size() == 0){
            query += ' LIMIT 0';
        }
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext bc,List<sObject> scope)
    {
        List<Account> accList = (List<Account>)scope;
        accList = LeadToContactConversionClass.populateProjectedSalesOwner(accList);
        update accList;
    }

    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
    }

}