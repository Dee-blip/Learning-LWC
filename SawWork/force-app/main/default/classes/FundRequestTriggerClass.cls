public without sharing class FundRequestTriggerClass
{
public static boolean markPMAInProgressFirstRunFlag=true;
/**Begin Rajesh Kumar JIRA# SFDC-5779 */
public static boolean markPMAApprovedFirstRunFlag=true;
/**End Rajesh Kumar JIRA# SFDC-5779 */

    public static void markPMAInProgress(List<SFDC_MDF__c> approvedFRs)
    {

        if(!markPMAInProgressFirstRunFlag)
            return;

        Set<Id> pmaIds = new Set<Id>();
        for(SFDC_MDF__c fr: approvedFRs)
        {
            pmaIds.add(fr.Partner_Marketing_Activity__c);
        }

        List<Partner_Marketing_Activity__c> pmas = [select id from Partner_Marketing_Activity__c where Activity_Status__c='Approved' and Id in :pmaIds];

        if(!pmas.isEmpty())
        {
            DMLResults results=new DMLResults();
            for(Partner_Marketing_Activity__c pma: pmas)
            {
                pma.Validation_Override__c=true;
                pma.Activity_Status__c='In Progress';
            }

            results.dmlUpdate(pmas);
            results.withJobName('Partner Marketing In Progress Update').withClassName('FundRequestTriggerClass').insertRecordsInErrorLog();
        }

    markPMAInProgressFirstRunFlag=false;
}

/**Begin Rajesh Kumar JIRA# SFDC-5779 */
// Below method handle changing PMA status to Approved if all associated FRs are cancelled
public static void handleCancelledFRonPMA(List < Id > cancelledFRsPMAIds) {
    if (!markPMAApprovedFirstRunFlag)
        return;
    List < Partner_Marketing_Activity__c > updateListApprPMA = new List < Partner_Marketing_Activity__c > ();
    Boolean isUpdatable;
    List < Partner_Marketing_Activity__c > pmas = [Select id, Activity_Status__c, (select Id, Cancelled__c from Fund_Requests__r) from Partner_Marketing_Activity__c where Id in: cancelledFRsPMAIds and Activity_Status__c = 'In Progress'];

    if (!pmas.isEmpty()) {
        for (Partner_Marketing_Activity__c pma: pmas) {
                isUpdatable = true;
                for (SFDC_MDF__c fr: pma.Fund_Requests__r) {
                    if (!fr.Cancelled__c) {
                        isUpdatable = false;
                        break;
                    }
                }
                if (isUpdatable) {
                    pma.Activity_Status__c = 'Approved';
                    pma.Validation_Override__c = true;
                    updateListApprPMA.add(pma);
                }

        }

        if (updateListApprPMA.size() > 0)
            GsmUtilClass.doDatabaseUpdate(updateListApprPMA,'FundRequestTriggerClass','handleCancelledFRonPMA');
   }
    markPMAApprovedFirstRunFlag = false;
}
/**End Rajesh Kumar JIRA# SFDC-5779 */
}