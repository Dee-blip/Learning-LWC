public class IW_reUsableMultiSelectLookupCtrl {
    
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, List<sObject> ExcludeitemsList) {
        String searchKey = '%' + searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
 
        List<string> lstExcludeitems = new List<string>();
        for(sObject item : ExcludeitemsList ){
            lstExcludeitems.add(item.id);
        }
        
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 and exclude already selected records
        String sQuery = '';
        if(ObjectName != 'User'){ 
        	sQuery =  'select id, Name from ' +ObjectName + ' where Name LIKE: searchKey AND Id NOT IN : lstExcludeitems order by createdDate DESC limit 5';
        }
        else{
            sQuery =  'select id, Name,Profile.UserLicense.Name from ' +ObjectName + ' where Name LIKE: searchKey and Profile.UserLicense.Name = \''+'Salesforce'+'\''+ 'order by createdDate DESC limit 5';
        }
        
        if(sQuery != ''){
            List < sObject > lstOfRecords = Database.query(sQuery);
            
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        }
        return returnList;
    }
    
    // Fetching type of account to restrict account on Bulk IW creation
    @AuraEnabled
    public static String getAccountInternal(String accountId){

        account acc = [select id , Vertical__c, Account_Status__c from account where id=:accountId];
        System.debug('accc :: ' + acc );
        if (acc.Account_Status__c == 'Akamai Internal - Inactive' || acc.Account_Status__c == 'Akamai Internal - Active' ) {
            return JSON.serialize('true') ;
        } else {
            return JSON.serialize('false') ;
        }

    }
}