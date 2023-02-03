/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
   Test Class Name : SC_Case_Trgr_EmlServc_Class_TC, Method : testSC_HomePageCaseNotifications                                                   
|  24-Nov-2014    Akhila      2650602     Controller Class for SC_HomePageCaseNotifications
   20-Mar-15	  Akhila	CR 2907264 -  New Homescreen Phase 2 changes      
   28-May-2015	  Jay		CR 3008063    -- sreaming APi	
   24-June-2015   Jay		CR 3058101    -- manualy supression of case updates	
+=====================================================================================================*/
public with sharing class SC_HomePageCaseNotificationsCtrl {
    //Notifications
    public List<Case> lCaseUpdates{get;set;}
    public Integer lCaseUpdatesCnt{get;set;}  
    public String profileCheck{get;set;}
    public String recTypeId;
    public boolean enablePolling{get;set;}
    public string hiddenCaseId{get;set;}
    
    public SC_HomePageCaseNotificationsCtrl(){
    	profileCheck='false';
        enablePolling = true;
         SC_Streaming_Settings__c c  = SC_Streaming_Settings__c.getInstance('Enable Case Notifications Streaming');
         if (c != null && c.keyvalue__c == 'true'){
            enablePolling = false;
         }
    	recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Invalid Case').getRecordTypeId();
    	Set<String> sProfiles = new Set<String>();
    	for(SC_HomeScreen_Profiles__c  p : SC_HomeScreen_Profiles__c.getAll().Values()) {
        	sProfiles.add(p.Profile__c);
    	}
    	String p =[Select Profile.Name from User where Id=:Userinfo.getUserId()][0].Profile.Name;
    	if(sProfiles.contains(p)) {
    		profileCheck='true';
    		updatelCaseUpdates();
    	}
    	else {
    		lCaseUpdates=new List<Case>();
    		lCaseUpdatesCnt=0;
    	}
    }
    
    public void updatelCaseUpdates() {
    	List<Case> lc = [Select Id,Akam_Case_Id__c,Subject,Account.Name from Case where Recent_Update__c = true and RecordTypeId!=:recTypeId and isClosed = false
        	            and OwnerId= :UserInfo.getUserId() ];
    	lCaseUpdates=new List<Case>();
    	lCaseUpdates=lc;
    	lCaseUpdatesCnt=lc.size();
    }
    
    public void suppressCaseUpdate(){
        try{
            case c = new Case(id=hiddenCaseId);
            c.recent_update__c = false;
            update c;
        } 
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
    }
    
}