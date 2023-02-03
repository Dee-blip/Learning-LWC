public without sharing class SC_Jarvis_Case_Provision_Queue implements Finalizer, Queueable
{
    public List<String> caseIds; 
    public Map<String,Set<String>> casesToSetGroups;
    public SC_Jarvis_Case_Provision_Queue() 
    {
        caseIds= new List<String>();
        casesToSetGroups = new Map<String,Set<String>>();
    }

    public void execute(QueueableContext context) 
    {
        if(caseIds.size() > 0)
        {
            casesToSetGroups = SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(caseIds);

            SC_Jarvis_Case_Provision_Queue finalizerQueue = new SC_Jarvis_Case_Provision_Queue();
            finalizerQueue.caseIds = caseIds;
            finalizerQueue.casesToSetGroups = casesToSetGroups;
            System.attachFinalizer(finalizerQueue);        

        }
    }
    public void execute(FinalizerContext ctx) 
    {
        if(caseIds.size() > 0)
        {

             Map<String,Case> caseIdtoRec= new Map<String,Case>([Select Id, Policy_Domain__c,RecordType.Name,Case_Product__r.Name,Contract_ID__c,
             AccountId,Account.AKAM_Account_id__c, Service__c,Service_Contract_Id__c,Community_Sharing_Set_Account_Lookup__c from Case where Id in :caseIds]);
             SC_Jarvis_CoreSecurityController.assignCaseAndCommentShares(casesToSetGroups,caseIdtoRec);
        }
    }

}