/*=====================================================================================================+
|	Name 		: MergeContractDetail_bi_bu_trigger
|	Test Class	: SC_CaseIssueClass_Test
=======================================================================================================
| 	HISTORY  |                                                                            
|  	DATE           	DEVELOPER       CR/Jira         	DESCRIPTION                               
|	===========    	=========       ============    	=========== 
|   17-JUN-2016    	Himanshu Kar    3333321(16.6)   	Create BOCC Entitlement
|	17-Apr-2020		Vamsee S		ESESP-1342(20.5)	BOCC Lightning Migration
 +=====================================================================================================*/
 
trigger MergeContractDetail_bi_bu_trigger on Merge_Contract_Detail__c (before insert, before update,After Insert, After Update) 
{
  List<Merge_Contract_Detail__c> contractHeaderForeignKeyResolveList=new List<Merge_Contract_Detail__c>();
  List<Merge_Contract_Detail__c> akamFieldPopulationList=new List<Merge_Contract_Detail__c>();
  
  // Getting BOCC Product Id from custom setting
  string boccProducts = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Technical_BOCC_Product_Ids' AND Active__c = True LIMIT 1].Value_Text__c;
  
  //Set to store all BOCC Line Item Ids
  set<Id> boccContractLnIds = new set<Id>();
  
  for(Merge_Contract_Detail__c con : trigger.New)
   {
       	if((trigger.isInsert && con.CI_Original_Contract_Id__c != null) && Trigger.isBefore){
			contractHeaderForeignKeyResolveList.add(con);
		}
       	else if(!Trigger.isInsert && Trigger.isBefore && trigger.oldMap.get(con.Id).CI_Original_Contract_Id__c!=null && con.CI_Original_Contract_Id__c != trigger.oldMap.get(con.Id).CI_Original_Contract_Id__c){
			con.addError('Original Contract Id can not be updated after insert');
		}
       	// BOCC Trigger has to fire both Insert and Update (After)
       	else if(Trigger.isAfter && con.Product_Id__c !=null && boccProducts.contains(con.Product_Id__c) && con.Effective_End_Date__c >= System.today()){
			boccContractLnIds.add(con.Id);
		}
    //SFDC-7449
    if(Trigger.isBefore && con.AKAM_Created_By_Id__c != null && con.AKAM_Modified_By_Id__c != null)
    {
      akamFieldPopulationList.add(con);
    }
   }
   
   if(contractHeaderForeignKeyResolveList.size()>0){
   		CastIronClass.Resolve_Contract_Detail_ContractHeaderForeignKeys(contractHeaderForeignKeyResolveList);
   }

   //SFDC-7449
   if(akamFieldPopulationList.size() > 0)
   {
      CastIronClass.populateAKAMFields(akamFieldPopulationList);
   }
   
   try{
       	// If any Bocc Line Item is added then call the BOCC Method
   		if(boccContractLnIds.size() > 0){
   			SC_CaseIssueClass cls = new SC_CaseIssueClass();
   			cls.createBOCCEntitlement(boccContractLnIds);
   		}
   } 
   catch(Exception e){
       string errHdr = ' ******* ';
       string errSubject = 'Exception: In Technical (BOCC) Entitlement Creation';
       string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
        							'Trigger Name = MergeContractDetail_bi_bu_trigger\n' + 
                            		'Support Class Name = SC_CaseIssueClass\n' +
                            		'Method Name = createBOCCEntitlement\n';
     	errorMessage += errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
       
       // Calling Send Email Method
       SC_Autogen_COB_Support sendEmailCls = new SC_Autogen_COB_Support();
       sendEmailCls.senEmailForError(errSubject,errorMessage);
   }
}