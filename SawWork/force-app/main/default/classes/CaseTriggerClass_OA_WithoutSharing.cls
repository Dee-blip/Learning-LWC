public without sharing class CaseTriggerClass_OA_WithoutSharing {
    public static Case reopenCase(Case caseR,String reason)
    {
        Case caseRec = new Case(); 
        caseRec.Id = caseR.Id;
        caseRec.Status = 'Reopened'; 
        caseRec.Reopened__c = true; 
        caseRec.AKAM_Closed_Date__c = null; 
        //caseRec.Re_open_Comments__c = comments; 
        caseRec.Re_open_Reason_Code__c = reason;
        caseRec.AutoClose__c = false; 
        
        try
        {
            update caseRec;
        }
        catch(Exception e)
        {
            system.debug('Exception while reopening : '+e.getMessage());
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));   
        }
        return caseRec;
    }
    
    public static Boolean areAnyRelatedOACasesPending(String caseId)
    {
        Id orderApprovalId = [SELECT Order_Approval__c FROM Case Where Id = :caseId].Order_Approval__c;
        if(orderApprovalId == null)
            return false;
        return [SELECT (SELECT Id
                        FROM Cases__r
                        WHERE RecordType.DeveloperName != 'Order_Approval_Order_Management'
                        AND Status NOT IN ('Closed-Approved', 'Closed-Approval Not Needed', 'Closed-Auto Approved',
                                           'Closed-Quote Term Updated', 'Closed-Quote Approved'))
                FROM Order_Approval__c
                WHERE Id = :orderApprovalId].Cases__r.size() > 0;
    }
}