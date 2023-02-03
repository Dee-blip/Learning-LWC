/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR          DESCRIPTION                               

|  ===========      =========       =======         =========== 
                                                       
|  16-MAR-2017      Himanshu Kar    3281921(17.3)     It will recalculate the Engg Product
+=====================================================================================================*/


trigger RecalculateEnggProductSync on CONTRACT_ENGINEERING_PRODUCT_DETAIL__c (after delete) {

    // Set to store Contract Id + Product Id which are going to be deleted
    set<string> contractIdProductIdFordelete = new set<string>();
    
    // Map to store BOCC Engg Product Name + Display Name
    public Map<string,string> BOCCProdmap = new Map<string,string>();
    for (SC_BOCC_Entitlement_Product__mdt eachRec : [select Mapping_Prod_Name__c,MasterLabel  from 
												SC_BOCC_Entitlement_Product__mdt]){
		BOCCProdmap.put(eachRec.Mapping_Prod_Name__c, eachRec.MasterLabel);											
	}
    
    // List to store all CPED Rec which are going to be recalculated
    List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c> allCPEDRec = new List<CONTRACT_ENGINEERING_PRODUCT_DETAIL__c>();
    
    for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c eachCPEDRec : Trigger.Old){
        
        // If Engg Product= Services_and_Support then delete the data from Target Object
        // Else Recalculate
        if(eachCPEDRec.ENGINEERING_PRODUCT_NAME__c != null && BOCCProdmap.keyset().contains(eachCPEDRec.ENGINEERING_PRODUCT_NAME__c)){
            
           if(eachCPEDRec.ENGINEERING_PRODUCT_NAME__c.contains ('Services_and_Support')){
        	
             contractIdProductIdFordelete.add(eachCPEDRec.CONTRACT_ID__c + ':' + eachCPEDRec.MARKETING_PRODUCT_ID__c);  
        	}
        	else
        	{
            	allCPEDRec.add(eachCPEDRec);
            }
        }
    }
    
    if(contractIdProductIdFordelete.size() > 0){
        delete [select Id from SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c where Unique_Key__c = :contractIdProductIdFordelete];
    }
    
    if(allCPEDRec.size() > 0){
        try{
    		SC_Sync_Contract_Eng_MrktgProd_Batch syncJob = new SC_Sync_Contract_Eng_MrktgProd_Batch();
        	syncJob.processingLayer(allCPEDRec,true);
        }
        catch(Exception e){
            string setEmailSub = 'Exception: In Delete Trigger - RecalculateEnggProductSync';
            string errorMessage = e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
                				
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
			sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
        }
    }
}