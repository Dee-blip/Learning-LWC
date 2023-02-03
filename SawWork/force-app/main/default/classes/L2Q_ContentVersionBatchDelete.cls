global class L2Q_ContentVersionBatchDelete extends GenericBatchClass  {

    global Date startDt;
    global Date endDt;

    global L2Q_ContentVersionBatchDelete() {
        
        super();

		operationType = 'Delete';
		className = 'L2Q_ContentVersionBatchDelete';

        //Datetime startDatetime = Datetime.valueOf(startDate);
        String startDate = GSMSettings.getValue('startDate_L2Q_ContentVersionBatchDelete');
        startDt= Date.valueOf(startDate);
        //Datetime endDatetime = Datetime.valueOf(endDate);
        String endDate = GSMSettings.getValue('endDate_L2Q_ContentVersionBatchDelete');
        endDt = Date.valueOf(endDate);

        String modeType = GSMSettings.getValue('L2Q_ContentVersionBatchDelete_ModeType');
        if(modeType == 'CustomMode') {
            query = 'SELECT Id from ContentDocument where id in (SELECT ContentDocumentID from ContentVersion where isDuplicate__c = true and lastModifiedDate > : startDt and lastModifiedDate < :endDt)' ;
        }
        else {
            query = 'SELECT Id from ContentDocument where id in (SELECT ContentDocumentID from ContentVersion where isDuplicate__c = true)';
        }

    }  

    global override void execute(Database.BatchableContext BC,List<SObject> scope){
        //delete scope;
        try {
            delete scope;
        }
        catch (Exception e){
            Error_log__c erroLog = new Error_log__c(Name = 'L2Q_ContentVersionBatchDelete Error', Class__c = 'L2Q_ContentVersionBatchDelete ',Error_Message__c = String.valueOf(e));
            insert erroLog;
        }
        
    }     
    
    global override void finish(Database.BatchableContext BC){
        super.finish(BC);
        System.DEBUG('Done: \n');
    }
    
}