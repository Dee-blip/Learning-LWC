/*=====================================================================================================+
Class name          :   SC_DD_ProcessODIDataJob
Author              :   Himanshu,Vishnu,Vamsee
Created             :   10-Mar-20
Purpose             :   Job to delete MRR,Revenue & Cost data after ODI sync to SFDC. 
                        Called from Trigger -  SC_QM_UserTrigger
Test Class          :   SC_DD_DealDeskTest

Last Modified Developer                 Purpose             
============= ========================  =======
10-Mar-20     Himanshu,Vishnu,Vamsee    Initial Development(Jira Ticket# ESESP- ) 
+=====================================================================================================*/

global class SC_DD_ProcessODIDataJob implements Database.Batchable<sObject>{
    
    // Getting current Batch Detail
    public SC_DD_BatchJob_Config__c currentBatchDet; 
        
    // Constructor
    public SC_DD_ProcessODIDataJob(boolean isODIData){
        
        // If Flag is true, then get Jobs related to ODI Object, else get record for PreDeal Object
        if(isODIData){
        
            // Query on Custom Setting to get the Current Batch
            currentBatchDet = [select Id,Is_Last_Record__c,Query__c,Status__c,IS_ODI_Data__c 
                            from SC_DD_BatchJob_Config__c 
                            where Status__c = 'New' and IS_ODI_Data__c = true
                            order by Sequence_No__c asc limit 1];
        }
        else{
            currentBatchDet = [select Id,Query__c,IS_ODI_Data__c 
                                from SC_DD_BatchJob_Config__c 
                                where IS_ODI_Data__c = false limit 1];
        }
        
    }

    // Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator(currentBatchDet.Query__c);
        
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
       
       // Call to Process Data Method
       processData(scope);
        
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){
        
        if(currentBatchDet.IS_ODI_Data__c){
            
            // If it is Last Batch, then update Status = New for all Records. 
            // Else update Status = Processed for Current Batch and Invokve Batch again to process next one  
            if(currentBatchDet.Is_Last_Record__c == true){
                
                // Step - 1 :Calling Update Method
                genericsObjectUpdate([select Id,Status__c from SC_DD_BatchJob_Config__c 
                                      where IS_ODI_Data__c = true ],
                                     'Status__c', 'New');
                
                // Step - 2 :Calling Another Batch for Calculation of Pre Deal Data
                Database.executebatch(new SC_DD_ProcessPreDealData_Batch(null),100);
            }
            else{
                
                currentBatchDet.Status__c = 'Processed';
                Update currentBatchDet;
                
                // Calling one more time
                Database.executebatch(new SC_DD_ProcessODIDataJob(true),2000);
            }
        }
        else{
            
            // Step - 2 : Updating Custom Setting to display Data in UI
            SC_DD_Utility__c DDSetting = [select Id,UI_Status__c from SC_DD_Utility__c where Name = 'DD Setting' limit 1];
            DDSetting.UI_Status__c = 'New';
            Update DDSetting;

            //Step - 3 : Update Back SC QM Filer Record
            SC_QM_USER_FILTER__C qmUser = [SELECT Id, User_Id__c, Status__c FROM SC_QM_USER_FILTER__C WHERE USER_ID__C = 'Deal_Desk' LIMIT 1];
            qmUser.Status__c = 'New';
            Update qmUser;

        }
    }
    
    // Method for Calculating Delete & Update Data Set
    public void processData(List<sObject> allIncomingData){
    
         // List for Update (Inactive -> Active)
        List<SObject> sObjectsToUpdate = new List<SObject>();
        
        // List for Delete (Active records)
        List<SObject> sObjectsToDelete = new List<SObject>();
        
        // Loop for all Sobject records
        for (sObject eachrec : allIncomingData) {
            
            if(eachrec.get('Status__c') == 'Active')
                sObjectsToDelete.add(eachrec);
            else 
                sObjectsToUpdate.add(eachrec);
        }
        
       // Deleteing data 
       if(sObjectsToDelete.size() > 0)
            delete sObjectsToDelete;
     
       // Calling Update Method
       if(sObjectsToUpdate.size() > 0)          
            genericsObjectUpdate(sObjectsToUpdate, 'Status__c', 'Active');
    }
    
    // Method for Dynamic Update
    public void genericsObjectUpdate(List<sObject> recToUpdate, string fieldApiName, string value){
    
        List<SObject> sObjectsToUpdate = new List<SObject>();
        SObject eachUpdatesObject;
        
            for (sObject eachrec : recToUpdate) {
                
                eachUpdatesObject = eachrec.Id.getSObjectType().newSObject(eachrec.Id); // Get Obj API Name
                eachUpdatesObject.put(fieldApiName, value); // Set the Name field dynamically
                sObjectsToUpdate.add(eachUpdatesObject);
            }

        update sObjectsToUpdate;
    }
}