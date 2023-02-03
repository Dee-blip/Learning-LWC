public class GSM_LeadGenContactController {
    
    // SFDC-6910 Changes for component to move Contacts under wwwLeadGen account to 
    // own Account
    
    
    // Get Paginated records for all contacts listed under LeadGen account
    @AuraEnabled
    public static List<Contact> getLeadGenContacts(String query, Integer pageNumber, String currentAccountId){
        
        
        Integer offset = 20*(pageNumber-1);
        
        Set<String> accountIdSet = getWWWLeadGenAccountId();
        if(accountIdSet.contains(currentAccountId)){
            return null; 
        }
        else{
            if(query != null && query != ''){
                query = '%'+query+'%';
                return [select id,name,title,phone,email 
                        from Contact 
                        WHERE AccountId in :accountIdSet AND
                        (Name LIKE :query OR 
                         phone like :query OR
                         email like :query) 
                         order by name limit 20 offset :offset];
            }
            else{
                
                
                return [select id,name,title,phone,email 
                        from Contact 
                        where Accountid in :accountIdSet  order by name  limit 20 offset :offset];
            }
        }
        
    }
    
    // Get WWWLeadGen Account from metadata 
    public static Set<String> getWWWLeadGenAccountId(){
        Set<String> setOfLeadGenIds = new Set<String>();
        for( LeanData__mdt mdtRecord :  [SELECT value__c FROM LeanData__mdt  WHERE QualifiedApiName = 'WWWLeadGenAccountId']){
            setOfLeadGenIds.add(mdtRecord.value__c);
        }
        return setOfLeadGenIds;
        
    }
    
    // Move the selected contacts to own Account
    // Run in Sys admin context to bypass permissions
    @AuraEnabled
    public static String moveLeadGenContacts(List<Contact> contactsToMove, String newAccountId){
        return GSM_LeadGenContactHelper.moveLeadGenContacts(contactsToMove,newAccountId);      
    }
       
    
}