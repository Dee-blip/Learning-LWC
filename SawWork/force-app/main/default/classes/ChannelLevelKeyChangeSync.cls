/** This class is a daily job that populates correct Channel level to oppty
	when channel level changes-> create a field to capture this change with prev key, (key)-> get all opptys which were associated with prev change and modify their channel level to remove existing and search again to have correct look up.
	Modify all channel levels field which was used to capture change to reflect blank.

Author        Date        Description
Ruchika Sharma   20/06/17       Created class.
                SFDC-1595 : Channels -- Channel Levels
**/

global class ChannelLevelKeyChangeSync implements Database.Batchable<sObject>, Database.Stateful {
	
	String query;
	global DMLResults results;
	String res;
	Integer backHourToLook;

	//when channel level inserted search if this fills up new oppty?
	global ChannelLevelKeyChangeSync() {
		 results= new DMLResults(); 
		 results.storeObjectState();
		 res='';
		 
		 backHourToLook = - (Integer.valueOf(GsmUtilClass.getGSMSettingValue('ChannelLevel_prevHourToLook')));
		 system.debug(LoggingLevel.ERROR,'backHourToLook: '+backHourToLook);
		 //DAY_ONLY
		query = 'select id,CHANNEL_GEOGRAPHY__c,CHANNEL_ID__c,Name from Channel_Hierarchy_Map__c where SystemModstamp >= :dt' ;//
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		
		DateTime dt = DateTime.now().addHours(backHourToLook);
		system.debug(LoggingLevel.ERROR,'query: '+query);
		return Database.getQueryLocator(query);
	}

//make batch size configurable
   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
   		List<Opportunity> populateChannelLevelList = new List<Opportunity>();
   		List<String> changedUniqeKeyList = new List<String>();
   		for(Channel_Hierarchy_Map__c clmObj: (List<Channel_Hierarchy_Map__c>)scope){
   			changedUniqeKeyList.add(clmObj.Name);
   		}
   		system.debug(LoggingLevel.ERROR,'changedUniqeKeyList: '+changedUniqeKeyList);
   		populateChannelLevelList = [select id,GSSM_Key__c,Channel_Hierarchy_Map__c,name from Opportunity where GSSM_Key__c IN :changedUniqeKeyList AND Channel_Hierarchy_Map__c=null AND Deal_Type__c!=null AND Deal_Type__c='Indirect' AND Partner_Involved__c!=null AND (NOT stageName Like 'Closed%')];
   		system.debug(LoggingLevel.ERROR,'populateChannelLevelList: '+populateChannelLevelList);
   		//remove prev channel mapping from all opp as now channel level mapping is changed.
		for(Opportunity opp:populateChannelLevelList){
		for(Channel_Hierarchy_Map__c clmObj: (List<Channel_Hierarchy_Map__c>)scope){
				if(opp.GSSM_Key__c==clmObj.Name){
                            opp.Channel_Hierarchy_Map__c = clmObj.id;
                            opp.Validation_Override__c= true;
                            if(String.isBlank(res))
                            	res=opp.id;	
                            else
                            	res=res+','+opp.id;
                        }
                    system.debug(LoggingLevel.ERROR,'opp.Channel_Hierarchy_Map__c: '+opp.Channel_Hierarchy_Map__c);
                 

			}
		}
		if(populateChannelLevelList!=null && populateChannelLevelList.size()>0)
          results.add(Database.update(populateChannelLevelList,false),populateChannelLevelList);
  	
	}
	
	global void finish(Database.BatchableContext BC)
    {
    	//GsmUtilClass.getGSMSettingValue()
    	Integer count =0;
    	if(res!=null)
    		 count = res.split(',').size();
    	if(results.failureCount!=0)
    		res = res+'failure: '+results.failureCount;
        //results.withJobName('\'Update Channel Level on Opportunity\'').toAddress(GsmUtilClass.getGSMSettingValue('ChannelLevel_EmailIdsToSendResult')).sendLogMail();
        results.withClassName('ChannelLevelOnOpptyBatchClass').insertRecordsInErrorLog();
        String toAddress = GsmUtilClass.getGSMSettingValue('ChannelLevel_EmailIdsToSendResult');
        String reportLink = GsmUtilClass.getPRMSettingValue('Channel_Level_Report_Link');
        sendReportInLogMail(reportLink,toAddress,'Update Channel Level on Opportunity');
        Util.updateCronRunWithResult('Update Channel Level on Opportunity', count+'Records'+res);
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