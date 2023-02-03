trigger ContentVersionAttrTrigger_ai_au on ContentVersionAttribute__c (before insert) {
	
    List<Id> contentVersionIds = new List<id>();
    List<Id> contentDocumentIds = new List<Id>();
    
    for (ContentVersionAttribute__c attr:Trigger.new) {
        contentVersionIds.add(attr.ContentVersionId__c );
    }

    // Added as part of SFDC-2133 by Mayank Bansal
    // List<String> avoidNAPReports = new List<String>();
    // List<Reports_MetaData__mdt> reports_MetaData = [SELECT DeveloperName, Columns_Name__c, Object_Name__c, Filters__c, Start_Date__c, End_Date__c, Date_Range_Field_API__c, Date_Range__c FROM Reports_MetaData__mdt];
    
    // for(Reports_MetaData__mdt report: reports_MetaData){
    //     avoidNAPReports.add(report.DeveloperName);
    // }  // Removed in SDFC 7172
    
    // Updated below query as part of SFDC-2133 to exclude NAP Reporting excels
    //List<ContentVersion> contentVersionList = [Select id,ContentDocumentId From ContentVersion where Id in:contentVersionIds and Tag__c not in :avoidNAPReports];

    
    List<ContentVersion> contentVersionList = [Select id,ContentDocumentId From ContentVersion where Id in:contentVersionIds]; //SDFC 7172
    for (ContentVersion cv:contentVersionList) {
        contentDocumentIds.add(cv.ContentDocumentId);
    }
    
    if (contentDocumentIds.size() > 0) {
        List<NAP_File_Subscribe__c> napFileSubscribeRecords = [Select id From NAP_File_Subscribe__c where Content_Document_Id__c  in:contentDocumentIds];
        
        if (napFileSubscribeRecords.size() > 0)
            delete napFileSubscribeRecords;
    }
    
}