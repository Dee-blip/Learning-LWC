// AUTHOR : Sumanth Naik
// 
// changes by Vandhana for ESESP-2039 : AMG Lightning Migration
// Test Class : SC_CustomLookUpController_Test

public class SC_CustomLookUpController 
{    
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord , String ObjectName , String pdId) 
    {
        String searchKey = searchKeyWord + '%';
        String policyDomain = pdId;
        List < sObject > returnList = new List < sObject > ();
        
        String sQuery;
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
        if(ObjectName == 'SC_SOCC_Escalation_List__c')
        {
            policyDomain=pdId;
            sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey and Policy_Domain__c=\''+policyDomain+'\'order by createdDate DESC limit 5';
        }  
        else 
        if(ObjectName == 'User')
        {
           sQuery =  'SELECT Id, Name FROM User WHERE Name LIKE: searchKey and Profile.Name like \'%AMG%\' ' 
                    + 'AND IsActive = TRUE order by Name ASC limit 5'; 
        }
        else
        {
            sQuery =  'select id, Name from ' + ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
        }
        system.debug(sQuery);
        List < sObject > lstOfRecords = Database.query(sQuery);
        
        for (sObject obj: lstOfRecords) 
        {
            returnList.add(obj);
        }
        return returnList;
    }
}