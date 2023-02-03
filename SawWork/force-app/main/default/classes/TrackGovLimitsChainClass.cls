/***
   trackGovChain
   @author         Ranjith Poolapally(ranreddy@akamai.com)
   @description    This class will run a schedule job which check for the newly created Components (Lookup fields, ..) in Salesforce
                   and create an corresponding audit record into CMP Audit History Object if not exists already.
                   
   @History 
   
        Date                 Developer               Description
     11/12/2019            Ranjith Reddy P      Created the Class and added folowing methods 
                                                     createAuditRecord     : Will be called from a scheduled Job and create NewCMP_Audit_Object__c record
                                                     makeCallout           :
                                                     setObjectLimit        :
                                                     returnApprovalProcess : 
                                                     returnLookupFields    : 
                                                     returnNewComponents   : 
*/
public class TrackGovLimitsChainClass implements Promise.Deferred
{
    private String objName;
    
    public TrackGovLimitsChainClass(){}
    
    public TrackGovLimitsChainClass(String objName)
    {
        this.objName = objName;
    }
    
    public Object resolve(Object incomingObject)
    {
        String returnStatus = 'res';
        System.Debug(LoggingLevel.Error, 'CMP_Audit incomingObject:'+incomingObject);
        List<NewCMP_Audit_Object__c> cmpToSyncList = (List<NewCMP_Audit_Object__c>)incomingObject;

        Integer daysToSubtract = 1;

        returnNewComponents('ValidationRule', daysToSubtract, cmpToSyncList);
        returnNewComponents('WorkflowRule', daysToSubtract,cmpToSyncList);
        returnNewComponents('LookupFilter', daysToSubtract,cmpToSyncList);
        returnNewComponents('WorkflowAlert', daysToSubtract,cmpToSyncList);
        returnNewComponents('CustomField', daysToSubtract,cmpToSyncList);
        returnApprovalProcess(objName, daysToSubtract,cmpToSyncList);

        if(!cmpToSyncList.isEmpty())
            return (Object)cmpToSyncList;
        return incomingObject;
    }

    public String returnNewComponents(String component, Integer daysToSubtract,List<NewCMP_Audit_Object__c> cmpToSyncList)
    {
        String returnStatus;
        component = String.escapeSingleQuotes(component);
        objName = String.escapeSingleQuotes(objName);
        List<componentType> listOfNewCMP = new List<componentType>();
        String query = '';

        if(component == 'CustomField')
            query = 'Select+Id,+DeveloperName,+CREATEDDATE+From+' + component + '+where+EntityDefinition.DeveloperName+=+\'' + objName + '\'';//+AND+DeveloperName+=+\'' + eachField + '\'';
        else if(component == 'WorkflowAlert')
            query = 'Select+Id,+DeveloperName,+CREATEDDATE+From+' + component + '+where+EntityDefinition.DeveloperName+=+\'' + objName + '\'';
        else if(component == 'WorkflowRule')
            query = 'Select+Id,+NAME,+CREATEDDATE+From+' + component + '+where+TableEnumOrId+=+\'' + objName + '\'';
        else if(component == 'ValidationRule')
            query = 'Select+Id,+ValidationName,+CREATEDDATE+From+' + component + '+where+EntityDefinition.DeveloperName+=+\'' + objName + '\'';
        else if(component == 'LookupFilter')
            query = 'Select+Id,+Active,+SourceFieldDefinitionId,+CREATEDDATE+From+' + component;// + '+where+TargetEntityDefinitionId+=+\'' + objName + '\'';
        
        HttpResponse response = makeCallout(query);

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
                            componentType cmp = (componentType)parser.readValueAs(componentType.class);
                            cmp.objName = objName;
                            cmp.component = component;
                            if(cmp.createdDate > System.now() - daysToSubtract)
                               listOfNewCMP.add(cmp);
                            parser.skipChildren();
                        }
                    }
                }
            }
        }
        if(component == 'CustomField' && !listOfNewCMP.isEmpty())
            returnLookupFields(listOfNewCMP);
        
        returnStatus = createAuditRecord(listOfNewCMP,cmpToSyncList);
        return returnStatus;
    }

    public String returnLookupFields(List<componentType> listOfNewCMP)
    {
        String returnStatus;
        List<String> lookupFieldNames = new List<String>();
        Map<String, Schema.SObjectField> objectFields = new Map<String, Schema.SObjectField>();
        if(objName == 'Activity')
            objectFields = Schema.getGlobalDescribe().get('Task').getDescribe().fields.getMap();
        else
            objectFields = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
        for(Schema.SObjectField fld :objectFields.values())
        {
            schema.describeFieldResult dfield = fld.getDescribe();
            String fldName = String.valueOf(dfield.getName());
            string fldType = string.valueOf(dfield.getType());   
            if (fldType == 'REFERENCE')
                lookupFieldNames.add(fldName);
        }
        for(componentType eachNewCMP : listOfNewCMP)
        {
            if(lookupFieldNames.contains(eachNewCMP.DeveloperName + '__c'))
               eachNewCMP.component += ' (Lookup Field)';
        }
        return returnStatus;
    }

    public static String returnApprovalProcess(String objName, Integer daysToSubtract,List<NewCMP_Audit_Object__c> cmpToSyncList)
    {
        String returnStatus;
        
        DateTime d = System.now() - daysToSubtract;
        Set<Id> listOfOldCMP = new Set<Id>();
        for(NewCMP_Audit_Object__c eachOldCMP : [Select Component_Id__c from NewCMP_Audit_Object__c])
            listOfOldCMP.add(eachOldCMP.Component_Id__c);
        List<ProcessDefinition> newProcDef = [SELECT Id,Name,State,CreatedDate,TableEnumOrId FROM ProcessDefinition Where TableEnumOrId = :objName AND CreatedDate > :d];
        if(!newProcDef.isEmpty())
        {
            for(ProcessDefinition procDef : newProcDef)
            {
                NewCMP_Audit_Object__c newCMPAudit = new NewCMP_Audit_Object__c();
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

                newCMPAudit.Corresponding_Object__c = procDef.TableEnumOrId;
                newCMPAudit.Component_Type__c = 'Approval Process';
                newCMPAudit.Component_Id__c = procDef.Id;
                newCMPAudit.Component_Name__c = procDef.Name;
                newCMPAudit.Component_Created_Date__c = DateTime.parse(procDef.createdDate.format());
                if(!listOfOldCMP.contains(newCMPAudit.Component_Id__c))
                    cmpToSyncList.add(newCMPAudit);
            }
            returnStatus = 'Message successfully sent.';
            return returnStatus;
        }
        returnStatus = 'There are no new components.';
        return returnStatus;
    }

    public static String createAuditRecord(List<componentType> listOfNewCMP,List<NewCMP_Audit_Object__c> cmpToSyncList)
    {
        String returnStatus;
        Set<Id> listOfOldCMP = new Set<Id>();
        Set<String> sourceFieldDefinitionIdSet = new Set<String>();
        if(!listOfNewCMP.isEmpty())
        {
            //SFORCE-80
            Map<String,String> mapFieldDefinitionToDeveloperNAme = new Map<String,String>();
            for(NewCMP_Audit_Object__c eachOldCMP : [Select Component_Id__c from NewCMP_Audit_Object__c])
                listOfOldCMP.add(eachOldCMP.Component_Id__c);
            for(componentType cmp : listOfNewCMP)
            {  
                if(cmp.sourceFieldDefinitionId != null)
                sourceFieldDefinitionIdSet.add(cmp.sourceFieldDefinitionId);
            }           
            if(sourceFieldDefinitionIdSet != null){
                for(FieldDefinition tempFD : [Select DeveloperName,DurableId FROM FieldDefinition WHERE DurableId in : sourceFieldDefinitionIdSet]){
                    mapFieldDefinitionToDeveloperNAme.put(tempFD.DurableId , tempFD.DeveloperName);
                }
            }
            for(componentType cmp : listOfNewCMP)
            {
                NewCMP_Audit_Object__c newCMPAudit = new NewCMP_Audit_Object__c();
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();

                newCMPAudit.Corresponding_Object__c = cmp.objName;
                newCMPAudit.Component_Type__c = cmp.component;
                newCMPAudit.Component_Id__c = cmp.Id;
                newCMPAudit.Component_Created_Date__c = DateTime.parse(cmp.createdDate.format());
                
                if(cmp.component == 'CustomField' || cmp.component == 'CustomField (Lookup Field)')
                    newCMPAudit.Component_Name__c = cmp.DeveloperName;
                else if(cmp.component == 'WorkflowAlert')
                    newCMPAudit.Component_Name__c = cmp.DeveloperName;
                else if(cmp.component == 'WorkflowRule')
                    newCMPAudit.Component_Name__c = cmp.Name;
                else if(cmp.component == 'ValidationRule')
                    newCMPAudit.Component_Name__c = cmp.ValidationName;
                //The SourceFieldDefinitionId field on LookupFilter API will have two components seperated by a dot.
                //If the LookupFilter is created on a standard object then SourceFieldDefinitionId will mention the object name else it will mention the ID of object.
                //If the LookupFilter is created on a standard field then SourceFieldDefinitionId will mention the field name else it will  mention the ID of field.
                else if(cmp.component == 'LookupFilter' && cmp.SourceFieldDefinitionId !=null)
                {
                    String SFDBeforeDot = cmp.SourceFieldDefinitionId.SubstringBefore('.');
                    String SFDAfterDot = cmp.SourceFieldDefinitionId.SubstringAfter('.');
                    try
                    {
                        Id fieldId = SFDAfterDot;
                        newCMPAudit.Component_Id__c = fieldId;
                        String developerName = mapFieldDefinitionToDeveloperNAme.get(cmp.sourceFieldDefinitionId);
                        if(developerName != null)
                            newCMPAudit.Component_Name__c = DeveloperName;
                    }
                    catch(StringException e)
                    {
                        newCMPAudit.Component_Name__c = SFDAfterDot;
                    }
                    try
                    {
                        Id objId = SFDBeforeDot;
                        if(objId.getSObjectType().getDescribe().getName() == cmp.objName && !listOfOldCMP.contains(newCMPAudit.Component_Id__c))
                            cmpToSyncList.add(newCMPAudit);
                    }
                    catch(StringException e)
                    {
                        if(SFDBeforeDot == cmp.objName && !listOfOldCMP.contains(newCMPAudit.Component_Id__c))
                            cmpToSyncList.add(newCMPAudit);
                    }
                }
                if(cmp.component != 'LookupFilter' && !listOfOldCMP.contains(newCMPAudit.Component_Id__c))
                {
                    cmpToSyncList.add(newCMPAudit);
                }
            }
            returnStatus = 'Message successfully sent.';
            return returnStatus;
        }
        returnStatus = 'There are no new components.';
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
    
    public class componentType
    {
        public String Id;
        public Boolean Active;
        public String SourceFieldDefinitionId;
        public DateTime createdDate;
        public String Name;
        public String ValidationName;
        public String DeveloperName;
        public String objName;
        public String component;
        public cmp_attribute attributes;
        public componentType(cmp_attribute constr_attributes)
        {
            attributes.type = constr_attributes.type;
            attributes.url = constr_attributes.url;
        }
    }

    public class cmp_attribute
    {
        public String type;
        public String url;
    }
}