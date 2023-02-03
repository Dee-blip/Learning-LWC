trigger Invoice_Review_Case_Audit_ai_au on Invoice_Review_Case_Audit__c (before insert, before update, after insert, after update) 
{
     
    List<Invoice_Review_Case_Audit__c> ircalist = new List<Invoice_Review_Case_Audit__c>();
    if(Trigger.isBefore)
    {
        for (Invoice_Review_Case_Audit__c irca : Trigger.new)
        {
            if (Trigger.isInsert && IRCaseHelperClass.hasOtherIRCIntegrationInProgress())
                irca.addError(Label.IR_Cases_Error_Message_Multiple_InProgress_Records);
            if (Trigger.isUpdate && irca.Import_Status__c=='Success'  && irca.Trigger_Case_Creation__c &&  Trigger.oldMap.get(irca.id).Trigger_Case_Creation__c != irca.Trigger_Case_Creation__c)
            {
                irca.Case_Creation_Start_Date__c= Datetime.now();
                irca.Case_Creation_Status__c='In-Progress';
            }
        }   
    }
    
    if(Trigger.isAfter && Trigger.isUpdate)
    {   
        Integer count=0;     
        for (Invoice_Review_Case_Audit__c irca : Trigger.new)
        { 
            if (irca.Import_Status__c=='Success'  && irca.Trigger_Case_Creation__c &&  Trigger.oldMap.get(irca.id).Trigger_Case_Creation__c != irca.Trigger_Case_Creation__c)
            {   
                if (irca.Import_End_Date__c !=null && irca.Import_Start_Date__c !=null && irca.Invoice_Review_Date__c!= null)
                {
                    ircalist.add(irca);
                    count++;
                }
            }
        }
    }
    
    if (ircalist.size()>0)
    {   
        //process for duplicates
        List<Draft_Invoice__c> duplicateDIList = new List<Draft_Invoice__c>();
        Map<Id,Draft_Invoice__c> mchIdDIIdMap = new Map<Id,Draft_Invoice__c>();
        for (Draft_Invoice__c di : [Select Id, isDuplicate__c,Original_Contract_Id__c from Draft_Invoice__c where Invoice_Review_Case_Audit__c=:ircalist[0].Id AND CreatedDate= LAST_N_DAYS:6])
        {
            if (mchIdDIIdMap.containsKey(di.Original_Contract_Id__c) && di.isDuplicate__c==false)
            {
                duplicateDIList.add(di);
                duplicateDiList.add(mchIdDIIdMap.get(di.Original_Contract_Id__c));
            }
        }
        if (duplicateDiList.size()>0)
        {
            for (Draft_Invoice__c di : duplicateDiList)
            {
                di.isDuplicate__c=true;
                di.Validation_Override__c=true;
            }
            update duplicateDiList; 
        } 
        // find previous IRCAudit Record.
        Invoice_Review_Case_Audit__c lastIrcaAudit=null; 
        for (Invoice_Review_Case_Audit__c irca: [SELECT Invoice_Review_Date__c,Case_Creation_Completed__c,Case_Creation_End_Date__c,Case_Creation_Status__c, CreatedDate,Id,
            Import_End_Date__c,Import_Results__c,Case_Creation_Start_Date__c,Total_Cases_Created__c,Import_Start_Date__c,Import_Type__c,IsDeleted,LastModifiedById,
                LastModifiedDate,Name,OwnerId,Import_Status__c FROM Invoice_Review_Case_Audit__c WHERE Invoice_Review_Date__c = :ircalist[0].Invoice_Review_Date__c AND CreatedDate = 
                    LAST_N_DAYS:90 AND Case_Creation_Completed__c=true AND Id != :ircalist[0].Id Order by CreatedDate Desc limit 1])
                    {
                        lastIrcaAudit = irca;
                    } 
        if (!Test.isRunningTest())
        {
	        IRCaseCreationBatchable execIRCaseCreation = new IRCaseCreationBatchable(ircalist[0], lastIrcaAudit);
	        Integer batchSize = Integer.valueOf(GsmUtilClass.GetCustomSettingValue('IR_NewMissingProcess_BatchSize'));
	        System.debug(Database.executeBatch(execIRCaseCreation,batchSize));
        }
    }
}