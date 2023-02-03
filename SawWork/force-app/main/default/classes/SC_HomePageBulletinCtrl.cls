/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  24-Nov-2014    Akhila      2650602     Controller Class for SC_HomePageBulletin
   28-May-2015	   Jay		  CR 3008063    -- sreaming APi
   27-July-2015	   Jay		  CR 3060381    -- handling single quotes for bulletin message
                                                       
+=====================================================================================================*/
public with sharing class SC_HomePageBulletinCtrl {
    public String profileCheck{get;set;}
    public boolean enablePolling{get;set;}
    public String bulletinMessage{get;set;}
    public String bulletinMessageEncoded{get;set;}

    public SC_HomePageBulletinCtrl(){
    	profileCheck='false';
        enablePolling = true;
        SC_Streaming_Settings__c c  = SC_Streaming_Settings__c.getInstance('Enable Bulletin Streaming');
        if (c != null && c.keyvalue__c == 'true'){
            enablePolling = false;
        }
    	Set<String> sProfiles = new Set<String>{'Support - Tech Support Agent','Support - Tech Support Agent with Customer Notification','Support - Tech Support Manager','Support - Tech Support Manager with Customer Notification',
                'Technical Relationship Engineer'};
    	String p =[Select Profile.Name from User where Id=:Userinfo.getUserId()][0].Profile.Name;
    	if(sProfiles.contains(p)) {
    		profileCheck='true';
    	}
      
        loadScrollMessage();
    }

    //Scroll text
    public void loadScrollMessage(){
    	String j='';
    	for(SC_BulletinMsg__c m : [Select Message_Text__c from SC_BulletinMsg__c where Start_Date__c<=:Datetime.now() and End_Date__c >=:Datetime.now() order by CreatedDate asc]) {
     		j=j+' '+m.Message_Text__c.replaceAll('[\n\r]', '')+' ';
       }
    	bulletinMessage = j ;
        //keeping separate variable to have encoded. button will by default have decoded. but 
        //there is also text area which displays. for this we need this variable
        bulletinMessageEncoded = string.escapeSingleQuotes(bulletinMessage);
    }
    
}