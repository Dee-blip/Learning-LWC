/*
_________________________________________________________________________________________________________
Author				: Vandhana Krishnamurthy
DESCRIPTION 		: Support class for SC_Autogen_Order_Form_Batch
Frequency of run 	: Every 3 hours     
Test Class 			: SC_Autogen_Order_Form_Batch_Test
Changes for			: ESESP-646
_________________________________________________________________________________________________________*/

public class SC_Autogen_Order_Form_Support
{
    Map<Id, Order_Approval__c> mOARecords = new Map<Id, Order_Approval__c>();
    Map<Id, String> mOATaskowner = new Map<Id, String>();
    
    List<Order_Approval__c> validOAList = new List<Order_Approval__c>();
    
	Set<Id> sOpportunityWithCase = new Set<Id>();
    
    Id OAActivityRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Order Approval Activity').getRecordTypeId();
    List<Case> lCase = new List<Case>();
    
    public void orderFormSupportMethod(List<Order_Approval__c> lReturnOA)
    {    
        SC_AutogenJob__c autogenRecord = [SELECT Autogen_UseCase_Name__c, Use_Case_Implementation_Date__c, Active__c, Subject__c, Description__c, 
                                          Service__c, Request_Type__c, Severity__c, Do_not_Show_in_Portal__c, Origin__c, Case_Record_Type__c, 
                                          IS_Case_Routing_Required__c 
                                          FROM SC_AutogenJob__c 
                                          WHERE Autogen_UseCase_Name__c = 'AMG-OFR'
                                          AND Active__c = TRUE
                                          LIMIT 1];
        if(autogenRecord == NULL)
            return;
        
        System.debug('SC OFR Autogen Job Record : ' + autogenRecord);
        
        Set<Id> oppId = new Set<Id>();
        Set<Id> oppWithAMGCase = new Set<Id>();
        
        for(Order_Approval__c oa : lReturnOA)
            oppId.add(oa.Associated_Opportunity__c);
        
        List<Case> amgCaseWithOpp = [SELECT Id, Opportunity__c, Opportunity__r.Name
                                     FROM Case 
                                     WHERE Recordtype.Name = 'AMG' 
                                     AND Origin = 'Autogen'
                                     AND Autogen_UseCase__c = 'AMG-OFR'
                                     AND Opportunity__r.Id IN :oppId
                                    ];
        
        for(Case c: amgCaseWithOpp)
        {
            System.debug('Case with Opp : ' + c);
            System.debug('Opp with Case : ' + c.Opportunity__r.Name);
            sOpportunityWithCase.add(c.Opportunity__c);
        }   
        
        oppId.removeAll(sOpportunityWithCase);
        
        System.debug('Valid List of Opp : ' + oppId);
        System.debug('Size of valid opp list : ' + oppId.size());
        
        for(Order_Approval__c eachrec: lReturnOA)
        {
            if(oppId.contains(eachrec.Associated_Opportunity__c))
            {
                System.debug('Opp in process : ' + eachrec.Associated_Opportunity__r.Name);
                
                if(!eachrec.Tasks.isEmpty())
                {
                    System.debug('OA considered : ' + eachrec);
                    System.debug('Tasks considered : ' + eachrec.Tasks);
                    //mOARecords.put(eachrec.Id, eachrec);
                    validOAList.add(eachRec);
                }
                
                /*
                for(task eachTask: eachrec.Tasks)
                {
                    if(eachTask.RecordTypeId == OAActivityRecordTypeId && eachTask.Status != 'Completed' 
                       && (eachTask.Task_Type__c == 'OM' || eachTask.Task_Type__c == 'OA' || eachTask.Task_Type__c == 'SA')) 
                    {
                        System.debug('Task considered : ' + eachTask.Subject);
                        mOARecords.put(eachrec.Id, eachrec);
                        mOATaskowner.put(eachrec.Id,eachTask.Owner.Name);
                    }   
                }
				*/
            }
        }
        
        if(!validOAList.isEmpty())
        {
            System.debug('Order Approvals for Processing : ' + validOAList);
            createCase(autogenRecord);
        }	
          
    }
    
    public void createCase(SC_AutogenJob__c autogenRecord)
    {
        System.debug('Entered case create function');
        
        for(Order_Approval__c oa: validOAList)
        {
            Case c = new Case();
            c.AccountId = oa.Associated_Opportunity__r.AccountId;
            c.Opportunity__c = oa.Associated_Opportunity__c;
            c.Subject = autogenRecord.Subject__c.replace('[insert opportunity name]',oa.Associated_Opportunity__r.Name);
            
            String Description = autogenRecord.Description__c;
            Description = Description.replace('[insert Opportunity name]', oa.Associated_Opportunity__r.Name);
            Description = Description.replace('[Insert Account ID]', oa.Associated_Opportunity__r.Account.AKAM_Account_ID__c );
            Description = Description.replace('[insert AKAM OrderApprovalID]', oa.AKAM_OrderApproval_ID__c);
            Description = Description.replace('[insert Order Approval Link]', System.URL.getSalesforceBaseUrl().toExternalForm() + '/'+ oa.Id);
            if(!oa.Tasks.isEmpty() && oa.Tasks[0] != NULL && !String.isBlank(oa.Tasks[0].Owner.Name))
                Description = Description.replace('[insert OM Owner name]', oa.Tasks[0].Owner.Name);
            Description = Description.replace('[insert MRR]', String.valueOf(oa.Associated_Opportunity__r.Dollar_MRR__c));
            c.Description = Description;
            
            c.Autogen_UseCase__c = 'AMG-OFR';
            c.Service__c = autogenRecord.Service__c;
            c.Request_Type__c = autogenRecord.Request_Type__c;
            c.Severity__c = autogenRecord.Severity__c;
            c.Origin = autogenRecord.Origin__c;
            c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(autogenRecord.Case_Record_Type__c).getRecordTypeId();
            c.Case_Assignment_Using_Active_Rules__c = autogenRecord.IS_Case_Routing_Required__c;
            
            lCase.add(c);
        }
        if(!lCase.isEmpty())
        {
            System.debug('AMG case list for Insert : ' + lCase);
            try
            {
                insert lCase;  
            }
            catch(Exception e)
            {
                String errorMessage = e.getCause()+'..'+ e.getLineNumber()+'..'+
                    				  e.getMessage()+'..'+e.getTypeName()+'..'+
                    				  e.getStackTraceString();
                String setEmailSub = 'Exception: Case Insert - SC_Autogen_Order_Form_Batch :: ';
                // Calling Send Email Method for Errors
                SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
                sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
            }
        }
    }
    
}