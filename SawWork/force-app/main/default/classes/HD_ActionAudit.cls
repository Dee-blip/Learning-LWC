public class HD_ActionAudit {

    @AuraEnabled
    public static void addActionAudit(String recordId,String actionName,Datetime startTime,Datetime endTime,Integer idleTime,String status)
    {
        try
        {
            if(startTime!=null && String.isNotBlank(actionName) )
            {
                HD_Action_Audit__c a = new HD_Action_Audit__c();
                a.Name = actionName;
                a.User__c = UserInfo.getUserId();
                a.Incident__c = recordId;
                a.startDateTime__c = startTime;
                a.endDateTime__c = endTime;
            	System.debug(idleTime);
                a.Idle_Time_Spent__c = Integer.valueOf(idleTime);
                a.Error_Status__c = status;
				insert(a);
            }
            
        }
        catch(Exception e)
        {
            	HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),recordId);
        }
    }
}