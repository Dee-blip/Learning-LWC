//Created by Mayank Bansal as part of SFDC-4047
public class RecordUpdateHistoryHandler implements Queueable {

	private List<Sobject> sobjectList;
	private String objectName;
	private String themeName;
    
    public RecordUpdateHistoryHandler(List<Sobject> sobjectList, String objectName, String themeName) {
        this.sobjectList = sobjectList;
        this.objectName = objectName;
        this.themeName = themeName;
    }

	public void execute(QueueableContext context){

		try{
			String exclusionStr = GsmUtilClass.getGSMSettingValue('ObjectTrackingFeatureExclusionList');
			exclusionStr = exclusionStr.replaceAll(', ', ',');
			List<String> exclusionNameList = exclusionStr.split(',');
			List<User> exclusionIdList = [Select Id from User where name like :exclusionNameList];
			List<RecordUpdateHistory__c> recordUpdateList = new List<RecordUpdateHistory__c>();
	    	
	    	for(Sobject sobj: sobjectList){
	    		Boolean exclude = false;
	    		String str = (String) sobj.get('LastModifiedById');
	    		for(User user: exclusionIdList){
	    			if(str == user.Id){
	    				exclude = true;
	    			}
	    		}
	    		
	    		if(!exclude){
	    			RecordUpdateHistory__c recordUpdate = new RecordUpdateHistory__c();
	    			if(sobj.get('Name') != null){
				        recordUpdate.Record_Name__c = (String) sobj.get('Name');
				    } else if(sobj.get('firstName') != null || sobj.get('LastName') != null){
				        if(sobj.get('firstName') != null && sobj.get('LastName') != null)
				        	recordUpdate.Record_Name__c = ((String) sobj.get('firstName') +' '+ (String) sobj.get('LastName'));
				        else if(sobj.get('LastName') != null)
				        	recordUpdate.Record_Name__c = (String) sobj.get('LastName');
				    }
				    recordUpdate.Name = objectName;
				    recordUpdate.Modified_By__c = (Id) sobj.get('LastModifiedById');
				    recordUpdate.Modified_Date_Time__c = (Datetime) sobj.get('lastModifiedDate')  ;
			        recordUpdate.Capture_Device__c = GsmUtilClass.getGSMSettingValue(themeName);
			        recordUpdate.Record_Id__c = (Id) sobj.id;
			        recordUpdateList.add(recordUpdate);
				}
	    	}

			Database.SaveResult[] result = Database.insert(recordUpdateList, false);
			// Check the save results from the bulk insert
            for (Database.SaveResult sr: result) {
                if (sr.isSuccess()) {
                       System.debug('Successfully inserted.');
                } else {
                       for (Database.Error err : sr.getErrors()) {
                        System.debug(err.getStatusCode() + ': ' + err.getMessage() + '; ' +
                                    'Error fields: ' + err.getFields());
                    }
                }
            }

		} catch(Exception e){
			System.debug('Exception: ' + e.getTypeName() + ', ' + e.getMessage());
		}
	}

}