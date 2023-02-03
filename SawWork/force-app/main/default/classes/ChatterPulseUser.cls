global class ChatterPulseUser {  
 
@future   
    public static void PulseAdd(Set<Id> userIds) {
        List<User> user = [select Id, CurrentStatus from user where Id IN :userIds];
        //Create a list to store the update tracker
        List<CP_Chatter_Pulse__c> listChatterPulse = new List<CP_Chatter_Pulse__c>(); 
        
        for (User usr : User) {
                
                //Create a ParentID and something similar to the FeedItem type used in the FeedItem/FeedComment triggers
                String userId = String.valueOf(usr.Id);
                String postType = 'Status: StatusCleared'; //Make this look similar to Feed and Comment triggers
                
                if(usr.CurrentStatus != NULL) {
                    postType = 'Status: StatusUpdate'; 
                }
                
                listChatterPulse.add(new CP_Chatter_Pulse__c(Chatter_User__c = usr.Id ,
                Reporting_Date__c = Date.today(), Update_Type__c = postType, Related_Record__c = userId ));                    
        }
        
        if(listChatterPulse.size() > 0) {
            insert listChatterPulse;
        }
        
    }
}