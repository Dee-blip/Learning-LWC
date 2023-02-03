public class TrackGovLimitsDMLChain implements Promise.Deferred
{
    public TrackGovLimitsDMLChain(){}

    public static Object resolve(Object incomingObject)
    {
        String returnStatus = 'res';
        if(incomingObject!= null)
        {
            System.Debug(LoggingLevel.Error, 'CMP_Audit incomingObject:'+incomingObject);
            List<NewCMP_Audit_Object__c> cmpToSyncList = (List<NewCMP_Audit_Object__c>)incomingObject;
            if(!cmpToSyncList.isEmpty())
            {
                insert cmpToSyncList;
                return (Object)cmpToSyncList;
            }
        }
        return incomingObject;
    }
}