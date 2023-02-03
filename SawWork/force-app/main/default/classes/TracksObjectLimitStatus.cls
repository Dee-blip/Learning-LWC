public class TracksObjectLimitStatus implements Promise.Deferred
{
    private String objName;

    public TracksObjectLimitStatus(){}

    public TracksObjectLimitStatus(String objName)
    {
        this.objName = objName;
    }

    public Object resolve(Object incomingObject)
    {
    	String returnStatus = 'res';
        System.Debug(LoggingLevel.Error, 'CMP_Audit incomingObject:'+incomingObject);
        List<sObject_Limit__c> newLimitsToSync = (List<sObject_Limit__c>)incomingObject;
        setObjectLimit(newLimitsToSync);
        if(!newLimitsToSync.isEmpty())
        {
        	return (Object)newLimitsToSync;
        }
    	return incomingObject;
    }

    public String setObjectLimit(List<sObject_Limit__c> newLimitsToSync)
    {
    	String returnStatus;
    	List<entityLimitClass> sObjectLimits = new List<entityLimitClass>();
        objName = String.escapeSingleQuotes(objName);
        String query = 'Select+EntityDefinitionId,+Type,+Remaining,+Max+from+entitylimit+where+EntityDefinitionId+=+\'' + objName + '\'';
        HttpResponse response = makeCallout(query);
        System.debug('from' + response.getBody());
        if (response.getStatusCode() == 200)
        {
            JSONParser parser = JSON.createParser(response.getBody());
            while(parser.nextToken()!= null)
            {
                if (parser.getCurrentToken() == JSONToken.START_ARRAY)
                {
                    while (parser.nextToken() != null) 
                    {
                        if (parser.getCurrentToken() == JSONToken.START_OBJECT) 
                        {
                            entityLimitClass sObjectLimit = (entityLimitClass)parser.readValueAs(entityLimitClass.class);
                            sObjectLimits.add(sObjectLimit);
                            parser.skipChildren();
                        }
                    }
                }
            }
        }
	    
        returnStatus = createAuditRecord(sObjectLimits, newLimitsToSync);
        return returnStatus;
    }

    public String createAuditRecord(List<entityLimitClass> sObjectLimits, List<sObject_Limit__c> newLimitsToSync)
    {
        String returnStatus;
        objName = String.escapeSingleQuotes(objName);
        if(!sObjectLimits.isEmpty())
        {
        	for(entityLimitClass elc : sObjectLimits)
            {
            	sObject_Limit__c newLimitRecord = new sObject_Limit__c();
            	newLimitRecord.Component_Type__c = elc.type;
            	newLimitRecord.Object_Name__c = objName;
            	newLimitRecord.Max_Limit__c = elc.max;
            	newLimitRecord.Remaining_Limit__c = elc.remaining;
            	newLimitRecord.Current_Usage_Count__c = elc.max - elc.remaining;
            	newLimitsToSync.add(newLimitRecord);
            }
        }
        return returnStatus;
    }
    
    public static HttpResponse makeCallout(String query)
    {
        HttpRequest req = new HttpRequest();
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionID());
        req.setHeader('Content-Type', 'application/json');
        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        req.setEndpoint(SFdomainUrl+'/services/data/v45.0/tooling/query/?q='+query);
        req.setMethod('GET');
        Http h = new Http();
        HttpResponse response = h.send(req);

        return response;
    }

    public class entityLimitClass
    {
    	public String EntityDefinitionId;
        public String type;
        public Integer remaining;
        public Integer max;
    }
}
/*Select Id, DeveloperName, CREATEDDATE From WorkflowAlert where EntityDefinition.DeveloperName='DMAPP__Insight_Competitor__c'*/