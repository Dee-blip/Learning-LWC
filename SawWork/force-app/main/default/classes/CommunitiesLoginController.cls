/**
 * Appirio | Dharmesh Patel | Initital Development
 * An apex page controller that exposes the site login functionality
 ppp
 */
global with sharing class CommunitiesLoginController {
    public String userName {get; set;}
    public String password {get; set {password = value == null ? value : value.trim(); } }
    private String startUrl;
    private String appendValue;
    global CommunitiesLoginController () {
        startUrl = System.currentPageReference().getParameters().get('startURL');
        Communities_Settings__c cs = Communities_Settings__c.getInstance('Community');
        appendValue = (cs.User_Name_Append_Value__c != null) ? cs.User_Name_Append_Value__c : '';  
    }
    
    // Code we will invoke on page load.
    /*
    // Unwanted code... commented by Dharmesh Patel
    global PageReference forwardToAuthPage() {
        String startUrl = System.currentPageReference().getParameters().get('startURL');
        String displayType = System.currentPageReference().getParameters().get('display');
        return Network.forwardToAuthPage(startUrl, displayType);
    }
    */
    public PageReference logIn(){
        if (!userName.toLowerCase().endsWith(appendValue.toLowerCase())) userName = userName + appendValue;
        PageReference pgResponse = Site.login(userName, password, startUrl);
        userName = userName.replace(appendValue.toLowerCase(),'');
        
        
 //CR2549010 change start
        if(pgResponse == null)
            pgResponse = Site.login(userName, password, startUrl);
        //CR2549010 change start
        return pgResponse;   
    }
}