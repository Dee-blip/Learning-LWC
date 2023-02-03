/** This class is a daily job that populates correct Channel level to oppty
	-> create a field to capture this change with prev key, (key)-> get all opptys which were associated with prev change and modify their channel level to remove existing and search again to have correct look up.
	Modify all channel levels field which was used to capture change to reflect blank.

Author        Date        Description
Ruchika Sharma   05/02/19       Created class.
                SFDC-4223 : Channels -- Channel Levels
**/
global class ChannelLevelKeyChangeSyncOppty implements Database.Batchable<sObject>, Database.Stateful {
	
	String query;
	global DMLResults results;
	String res;
	Integer backHourToLook;
	
	global ChannelLevelKeyChangeSyncOppty() {
		results= new DMLResults(); 
		 results.storeObjectState();
		 res='';
		 query = 'select id,GSSM_Key__c,Channel_Hierarchy_Map__c,name from Opportunity where GSSM_Key__c!=null AND Channel_Hierarchy_Map__c=null AND Deal_Type__c!=null AND Deal_Type__c=\'Indirect\' AND Partner_Involved__c!=null AND (NOT stageName Like \'Closed%\')' ;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		system.debug(LoggingLevel.ERROR,'query: '+query);
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Opportunity> populateChannelLevelList = (List<Opportunity>)scope;
   		List<String> gssmkeyOppty = new List<String>();
   		for(Opportunity oppty: populateChannelLevelList)
   			gssmkeyOppty.add(oppty.GSSM_Key__c);
   		
   		system.debug(LoggingLevel.ERROR,'gssmkeyOppty: '+gssmkeyOppty);
   		backHourToLook = - (Integer.valueOf(GsmUtilClass.getGSMSettingValue('ChannelLevel_prevHourToLook')));
   		DateTime dt = DateTime.now().addHours(backHourToLook);
   		system.debug(LoggingLevel.ERROR,'dt: '+dt);
		List<Channel_Hierarchy_Map__c> chmList = [select id,Name from Channel_Hierarchy_Map__c where name in :gssmkeyOppty and SystemModstamp>=:dt];
		system.debug(LoggingLevel.ERROR,'chmList: '+chmList);
		Map<String,id> chmMapNameId = new Map<String,id>();
		for(Channel_Hierarchy_Map__c chm: chmList)
			chmMapNameId.put(chm.name,chm.id);

		for(Opportunity opp: populateChannelLevelList){
			opp.Channel_Hierarchy_Map__c = chmMapNameId.get(opp.GSSM_Key__c);
            opp.Validation_Override__c= true;
            if(String.isBlank(res))
            	res=opp.id;	
            else
            	res=res+','+opp.id;
		}

		if(populateChannelLevelList!=null && populateChannelLevelList.size()>0)
          results.add(Database.update(populateChannelLevelList,false),populateChannelLevelList);
	}
	
	global void finish(Database.BatchableContext BC) {
		//GsmUtilClass.getGSMSettingValue()
    	Integer count =0;
    	if(res!=null)
    		 count = res.split(',').size();
    	if(results.failureCount!=0)
    		res = res+'failure: '+results.failureCount;
        //results.withJobName('\'Update Channel Level on Opportunity\'').toAddress(GsmUtilClass.getGSMSettingValue('ChannelLevel_EmailIdsToSendResult')).sendLogMail();
        results.withClassName('ChannelLevelKeyChangeSyncOppty').insertRecordsInErrorLog();
        String toAddress = GsmUtilClass.getGSMSettingValue('ChannelLevel_EmailIdsToSendResult');
        String reportLink = GsmUtilClass.getPRMSettingValue('Channel_Level_Report_Link');
        sendReportInLogMail(reportLink,toAddress,'Update Channel Level for Opportunity');
        Util.updateCronRunWithResult('Update Channel Level for Opportunity', count+'Records'+res);	
	}
	 public void sendReportInLogMail(String reportLink,String toAddress,String jobName) {
        // Send an email to the Apex job's submitter (or emailOverride) notifying of job completion. 
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        String[] toAddresses=toAddress.split(',');

        mail.setToAddresses(toAddresses); 
        mail.setSubject('Apex Job '+jobName+' completed'); 

        string s = 'Your Apex Job '+jobName+' completed.<br/><br/>';

         string htmlResult; 
        htmlResult='Total records that were attempted to modify : '+results.dmlsAttempted+'<br/>'; 
        htmlResult+='Total records failed : '+results.failureCount+'<br/><br/><br/>';
        Boolean errorExists=(results.failureCount>0);

        if(errorExists){
        	reportLink=URL.getSalesforceBaseUrl().toExternalForm() + '/'+reportLink;
        	htmlResult += 'Please see this report for all the errors:<br/><br/>'+reportLink;

        }
            s+=htmlResult; 
            System.Debug(LoggingLevel.Error, 'rsh:: '+s);
            mail.setHtmlBody(s); 
         
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail }); 
    }
}