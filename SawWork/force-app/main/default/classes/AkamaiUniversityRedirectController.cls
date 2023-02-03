public class AkamaiUniversityRedirectController {
    public string value {get;set;}
    public Contact currentContact {get;set;}
    private string currentUserId {get;set;}
    //private Contact conList = new List<Contact>();
    public string target {get;set;}
    public AkamaiUniversityRedirectController(){
    //value = Util.getCsodSamlUrl();
    init();
    }
    //CR 3018377
    public void init()
      {
        currentUserId=UserInfo.getUserId();
        value = Util.getCsodSamlUrl();
        
        System.debug('Echo: currentUserId: '+currentUserId);
       
        target = '_blank';
       
        for(Contact c:[select Id, Name, Last_AU_Login__c from Contact where Partner_User__c = :currentUserId])
        {
            currentContact = c;
            currentContact.Last_AU_Login__c = System.now();
            currentContact.Validation_Override__c = true;
            System.debug('currentContact: '+currentContact);
        }
        
    }

    @AuraEnabled
    public static string getAUURL(){
        
        string currentUserId = UserInfo.getUserId();
        string value = Util.getCsodSamlUrl();
        
        System.debug('Echo: currentUserId: '+currentUserId);
        
        string target = '_blank';
        
        List<Contact> contactsList = new List<Contact>();
        for(Contact c:[select Id, Name, Last_AU_Login__c from Contact where Partner_User__c = :currentUserId])
        {
            c.Last_AU_Login__c = System.now();
            c.Validation_Override__c = true;
            System.debug('currentContact: '+c);
            //update c;
            contactsList.add(c);
        }
        update contactsList;
        return value;
    }

    public void captureAULogin(){
        
        Map<String,String> param = new Map<String,String>();
        param=ApexPages.currentPage().getParameters();
        if(param.containsKey('target')){
            target = param.get('target');      
        }
        
        System.debug('target is: '+target);
    	if(currentContact!=null )
    		update currentContact;
    }
    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static testmethod void AkamaiUniversityRedirectControllerTest(){
    //    Test.setCurrentPageReference(Page.AkamaiUniversityRedirect);
    //    AkamaiUniversityRedirectController fruc = new AkamaiUniversityRedirectController();
    //}
}