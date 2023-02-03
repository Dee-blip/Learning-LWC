/*
   
Last Modified BY      Last Modified Date  Purpose
----------------      ------------------  ---------
Akhila                06-01-14        CR#2883378 : Added DR bypass condition
*/

trigger CreateCommunityUserOrContact on Case (before insert, before update)
{
    /*
    //This is to populate CaseType__c which is used in Report - Non-community Cases vs. Community Cases
    if(Trigger.isBefore && Trigger.isInsert){
        for(Case c: Trigger.new){
            c.CaseType__c = (c.Origin == 'Jive') ? 'Community Cases' : 'Non-community Cases';
        }
    }else if(Trigger.isBefore && Trigger.isUpdate){
        for(Case c: Trigger.new){
            if(c.Origin != Trigger.oldMap.get(c.id).Origin){
                c.CaseType__c = (c.Origin == 'Jive') ? 'Community Cases' : 'Non-community Cases';
            }
        }
    }
    */
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
    if(Trigger.isBefore && Trigger.isInsert){
        //check custom setting if we need to create a contact or not    
        List<Case> listOfNewCases = Trigger.new;
        Integer numberOfCases = listOfNewCases.size();
        
        if(numberOfCases == 1) {
        //put first element of list in Case object...
            Case c=listOfNewCases.get(0);   
            
            system.debug('PremiumSupportGroup__c'+c.PremiumSupportGroup__c);
            
            if (c.Jive_Author_Email__c != null && c.Status == 'New' && c.Origin == 'Jive') {
        
                Set<String> set_newAuthorEmailsOnCommUsr = new Set<String>();
                Set<String> set_newAuthorEmails = new Set<String>();
                Map<String,String>  map_newAuthorEmailNameOnCommUsr= new Map<String,String>();
                Map<String,String>  map_newAuthorEmailName= new Map<String,String>();
                Map<String,Id> map_Email_CommUsrId = new Map<String,Id>();
                Map<String,Id> map_Email_ContactID = new Map<String,Id>();
                JiveCommunitySettings__c jcs = JiveCommunitySettings__c.getValues('DefaultSetting');
                if(jcs==NULL) {
        
                    jcs=new JiveCommunitySettings__c
                    (  
                    Name ='DefaultSetting' ,
                    Community_Base_URL__c ='https://ec2.compute.amazonaws.com:8090',
                    Create_Contact__c     = false,
                    Jive_URL__c           = 'https://jive-community.jiveon.com'
                    ); 
                }
                system.debug('Custom setting'+jcs.Create_Contact__c);
        
                //put Jive_Author_Email__c from new cases in a set       
                set_newAuthorEmailsOnCommUsr.add( c.Jive_Author_Email__c );
             
                //put in map key = Jive_Author_Email__c Value=Jive_Author_Name__c
                map_newAuthorEmailNameOnCommUsr.put(c.Jive_Author_Email__c,c.Jive_Author_Name__c);
                  
                //if new contact needs to be created
                if(jcs.Create_Contact__c==true)  {  
            
                //put in set Jive_Author_Email__c 
                set_newAuthorEmails.add( c.Jive_Author_Email__c );
             
                //put in map key = Jive_Author_Email__c Value=Jive_Author_Name__c
                map_newAuthorEmailName.put(c.Jive_Author_Email__c,c.Jive_Author_Name__c);
        
                }
            
     
            
                //create new community user
                for (Jive_Community_User__c commUsr : [SELECT Id, Email__c FROM Jive_Community_User__c WHERE Email__c =:set_newAuthorEmailsOnCommUsr] )
                {
                    //key=commUsr.Email__c value=commUsr.Id
                    map_Email_CommUsrId.put(commUsr.Email__c,commUsr.Id);
            
                    //Remove all existing emails from the set when community user with same email already exists
                    set_newAuthorEmailsOnCommUsr.remove(commUsr.Email__c );
                
                    //Remove all existing emails from the map when community user with same email already exists
                    map_newAuthorEmailNameOnCommUsr.remove(commUsr.Email__c);
                }
            
                List<Jive_Community_User__c> list_communityUsersToInsert = new List<Jive_Community_User__c>();
            
                for ( String anEmail :set_newAuthorEmailsOnCommUsr) {
        
                    //first check if the key exists or not
                    if(map_newAuthorEmailNameOnCommUsr.containsKey(anEmail)){
                        list_communityUsersToInsert.add
                        ( 
                            new Jive_Community_User__c
                            (  
                    
                                Name = map_newAuthorEmailNameOnCommUsr.get(anEmail),
                                Last_Name__c   = map_newAuthorEmailNameOnCommUsr.get(anEmail),
                                Email__c       = anEmail
                            )
                        );
                    }
                }
        
                //check if list is not empty
                try {
        
                    if(list_communityUsersToInsert.size()>0) {
                        insert list_communityUsersToInsert;
                        System.debug('Community User inserted ');
                    }
                }
                catch(Exception ex) {
        
                    system.debug('Exception occurred while inserting community user'+ex.getMessage());
        
                }
        
                // update the map of exixting community users
                for ( Jive_Community_User__c aContact : list_communityUsersToInsert)
                {
                    map_Email_CommUsrId.put( aContact.Email__c, aContact.Id );
                }
                //community user insertion complete
        
                //contact insertion 
                if(jcs.Create_Contact__c==true) {
                    for ( Contact aContact : [SELECT Id, Email FROM Contact WHERE Email IN :set_newAuthorEmails] ){
                        //  Map of all key=contact Email value=contact Id
                        map_Email_ContactID.put( aContact.Email, aContact.Id );
                        //remove contact emails if contact with same email already exists
                        set_newAuthorEmails.remove( aContact.Email );
                        map_newAuthorEmailName.remove(aContact.Email);
           
                    }
                
                    List<Contact> list_contactsToInsert = new List<Contact>();
                
                    for ( String anEmail :set_newAuthorEmails ){
                
                    if(map_newAuthorEmailName.containsKey(anEmail))
                    {
                        list_contactsToInsert.add
                        (
                            new Contact
                           (  
                                LastName = map_newAuthorEmailName.get(anEmail),
                                Email     = anEmail
                            )
                        );
                    }
                }
                
                try
                {
                    if(list_contactsToInsert.size()>0)
                    {
                        insert list_contactsToInsert;
                        System.debug('Community User inserted ');
                    }
                }
                catch(Exception ex)
                {
                        
                         system.debug('Exception in contact insertion '+ex.getMessage());
                
                }
                System.debug('Contact inserted');
                
                //  Map the new contact in map
                for ( Contact aContact : list_contactsToInsert )
                {
                    map_Email_ContactID.put( aContact.Email, aContact.Id );
                }
    
            } //end of if
        
            //contact insertion complete
        
            // Populate the contact ID based on the email address
            //check the custom setting again and based on that populate contact name or cummunity user contact name
            //if ( c.Jive_Author_Email__c!=NULL &&  c.Status == 'New' && c.Origin == 'Jive' ) {
                
            c.Community_Contact_Name__c=map_Email_CommUsrId.get(c.Jive_Author_Email__c);
            
            System.debug('contact name'+c.Community_Contact_Name__c);
            
            System.debug('Community contact name in case updated');
            
            if(jcs.Create_Contact__c==true) {
                    c.ContactId = map_Email_ContactID.get(c.Jive_Author_Email__c );
            
                    System.debug('contact name in case updated');
            }
            else {
               
                Integer count=[SELECT count() FROM Contact WHERE Email =:c.Jive_Author_Email__c limit 1] ;
                if(count==1)
                {
                    Contact aContact = [SELECT Id FROM Contact WHERE Email =:c.Jive_Author_Email__c limit 1] ;
                    c.ContactId  = aContact.ID;
                }
          
           
            }
       
        }
        }
    }
    }      
}