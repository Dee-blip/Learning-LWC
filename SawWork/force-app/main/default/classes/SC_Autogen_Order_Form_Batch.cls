/*
_________________________________________________________________________________________________________

DESCRIPTION 		: This batch class is used to create Autogen AMG Cases for Existing Customers 
Frequency of run 	: Every 3 hours     
Test Class 			: SC_Autogen_Order_Form_Batch_Test
_________________________________________________________________________________________________________*/

global class SC_Autogen_Order_Form_Batch implements Database.Batchable<SObject>, Database.Stateful 
{  
    public String batchQuery = NULL;
    global Integer noOfErrors = 0;
    
    // Setting Error Message
    public string errorMessage = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                                 'Batch Class Name = SC_Autogen_Order_Form_Batch\n' + 
                                 'Support Class Name = SC_Autogen_Order_Form_Support\n' +
                                 'Method Name = orderFormSupportMethod\n';
    
    // Constructor of Batch Class
    public SC_Autogen_Order_Form_Batch()
    { }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {    
        System.debug('OFR Autogen entered start : ');
        
        String taskTypes = [SELECT Value__c 
                            FROM SC_Utility__mdt 
                            WHERE MasterLabel = 'AMG OFR Task Type' limit 1].Value__c;
        
        List<SC_Utility__mdt> amgMetDat = [SELECT Value__c,Active__c 
                                           FROM SC_Utility__mdt 
                                           WHERE MasterLabel in ('AMG OFR Dollar MRR','AMG OFR Opportunity CloseDate')];
        
        String orderAppQuery = 'SELECT Associated_Opportunity__c,AKAM_OrderApproval_ID__c,CCG_Owner__r.Name,Associated_Opportunity__r.MRR__c,' +
            				   ' Associated_Opportunity__r.Name, Associated_Opportunity__r.Dollar_MRR__c, Associated_Opportunity__r.Momentum_Order_Form_Initiated__c,' +
                               ' Associated_Opportunity__r.AccountId, Associated_Opportunity__r.Account.Account_Status__c,Associated_Opportunity__r.Account.AKAM_Account_ID__c,' +
                               ' (Select CreatedDate, Task_type__c, Status, RecordtypeId,Subject,OwnerId,Owner.Name from Tasks WHERE Status != \'Completed\' AND RecordType.Name = \'Order Approval Activity\' AND Task_Type__c in (' + taskTypes + ') limit 1 )' +
                               ' FROM Order_Approval__c' +
                               ' WHERE Associated_Opportunity__r.Account_Status__c != \'Lead\' ' +
                               ' AND Associated_Opportunity__r.RecordType.Name = \'Akamai Opportunity\' ' +
                               ' AND Associated_Opportunity__r.Momentum_Order_Form_Initiated__c = TRUE'
                               ;
        
        for(SC_Utility__mdt eachMDT : amgMetDat)
		{
            if(eachMDT.Active__c)
            	orderAppQuery = orderAppQuery + ' ' + eachMDT.Value__c;
        }
        
        String test_orderAppQuery = orderAppQuery + ' ORDER BY CreatedDate DESC LIMIT 10';
        
        batchQuery = (System.Test.isRunningTest()) ? test_orderAppQuery : orderAppQuery; 
        System.debug('Query : ' + batchQuery);
        return Database.getQueryLocator(batchQuery);
    }
    
    global void execute(Database.BatchableContext BC, list<SObject> scope)
    {
        System.debug('Entered Execute : ');
        string errHdr = ' ******* ';
        
        List<Order_Approval__c> allReturnOA = (Order_Approval__c[]) scope;    

        System.debug('Order Approvals Picked : ' + allReturnOA);
        System.debug('Number of Order Approvals : ' + allReturnOA.size());
        try
        {
            System.debug('Entered Try Block');
            SC_Autogen_Order_Form_Support sc_OFRSuppCls = new SC_Autogen_Order_Form_Support();
            sc_OFRSuppCls.orderFormSupportMethod(allReturnOA);
        }
        
        catch(Exception e) 
        {
            noOfErrors += 1;
            errorMessage += errHdr + noOfErrors + errHdr + '\n' 
                + e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString()
                + '\n' + errHdr + '\n';
        }
    }
    
    /*@Method 
	* This method gets executed automatically when the batch job finishes
	* @param <Database.BatchableContext BC - Batchable context>
	*/    
    global void finish(Database.BatchableContext BC)
    {
        // Calling Send Email Method for Errors
        if(noOfErrors > 0)
        {
            System.debug('ERROR');
            String setEmailSub = 'Exception: In Batch Job - SC_Autogen_Order_Form_Batch :: # Of Errors : '+noOfErrors;
        
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        }       
    }   
                               
 }