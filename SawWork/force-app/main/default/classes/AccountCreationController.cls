Public class AccountCreationController{
    
    public AccountCreationController(ApexPages.StandardController controller) {
        
    }
    
    
    
    public PageReference AddNewAccount(){
        
        String Prefix =  Schema.Sobjecttype.Account_Creation_Request__c.getKeyPrefix();
        String accessProfileIds = GSMSettings.getVerbose('AccountCreationProfileIds');
        String accessProfileId1 = GSMSettings.getVerbose('AccountCreationProfileId1');
            String accessProfileId2 = GSMSettings.getVerbose('AccountCreationProfileId2');

         if(accessProfileIds.contains(userinfo.getProfileId()) || accessProfileId1.contains(userinfo.getProfileId()) || accessProfileId2.contains(userinfo.getProfileId()) ){
             
            PageReference pageRef = new PageReference('/apex/AdvAccAndConSearch');
            return pageRef;
             
            
        }else{
            system.debug('Inside if');
            PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');
            returnURL.getParameters().put('nooverride', '1');
            returnURL.setRedirect(true); 
            return returnURL;
            // returnURL.getParameters().remove('save_new');
          }
        
        
    }
    
}