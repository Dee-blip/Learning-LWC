public without sharing class GSM_LeadGenContactHelper{
    
    // SFDC-6910 Changes for component to move Contacts under wwwLeadGen account to 
    // own Account


   
    // Move the selected contacts to own Account
    public static String moveLeadGenContacts(List<Contact> contactsToMove, String newAccountId){
        try{
            for(Contact c : contactsToMove){
                c.accountId = newAccountId;
            }
            update contactsToMove;
            
            return 'success';
        }catch(Exception e ){
            return e.getMessage();
        }      
        
    }    
    
}