/*
* File Name: HD_RequestDefinitionManager
* Description : Factory class used for the building of Service Requests
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 					Modification
* Jan 20th, 2020	Arihant Jain			PRTORES-1593 - Create an App to host P2R Dev tools
* Nov 29th, 2021    Aneesh Budnar           PRTORES-2358 - HD Code Scanner 1 fixes
*/
public with sharing class HD_RequestDefinitionManager
{   
    //Template generator for Requestdefinition
    //This is step one.
    //fields are Template for , Name, Description, Keywords
    private Map<String,BMCServiceDesk__SYSTemplate__c> SRM_Template_Generator(String rdName)
    {
        //return map
        Map<String,BMCServiceDesk__SYSTemplate__c> returnedMap = new Map<String,BMCServiceDesk__SYSTemplate__c>();
        
        BMCServiceDesk__SYSTemplate__c incidentTemplate =  new BMCSYSTemplateWrapper(rdName+'-INC')
            .withName(rdName+'-INC')
            .withTemplateFor('Incident')
            .withDescription('Incident Template for '+ rdName)
            .withKeyWords(rdName)
            .buildAndSave();
        system.debug('Inserted ---> '+incidentTemplate);
        
        BMCServiceDesk__SYSTemplate__c requestDetailTemplate = new BMCSYSTemplateWrapper(rdName+'-RD')
            .withName(rdName+'-RD')
            .withTemplateFor('Request Detail')
            .withDescription('Request Detail Template for '+ rdName)
            .withKeyWords(rdName)
            .buildAndSave();
        system.debug('Inserted ---> '+requestDetailTemplate);
        
        //Creating the template linkage 
        BMCServiceDesk__SYSTemplateLink__c templateLinkage = new BMCTemplateLinkWrapper(incidentTemplate.Id,requestDetailTemplate.Id)
            .buildAndSave();
        System.debug('Inserted ---> '+templateLinkage);
        
        //adding the incident and Request details Ids and data in to the MAp
        returnedMap.put('Incident',incidentTemplate);
        returnedMap.put('Request Detail',requestDetailTemplate);
        
        return returnedMap;
    }//
    
    
    //Method for creating request definition
    //This is step two
    public BMCServiceDesk__SRM_RequestDefinition__c SRM_Requestdefinition(BMCServiceDesk__SRM_RequestDefinition__c rdc)
    {  
        //Map for Inserted Template
        Map<String,BMCServiceDesk__SYSTemplate__c> processtemplateMap = SRM_Template_Generator(rdc.Name);
        
        rdc = new BMCRequestDefnWrapper(rdc, false)
            .withBusinessService(false)
            .withServiceOffering(false)
            .withCategory(false)
            .buildAndSave();
        system.debug('Inserted ---> '+rdc);
        
        BMCServiceDesk__SRM_ProcessTemplate__c pt = new BMCProcessTemplateWrapper(rdc.id, processtemplateMap.get('Request Detail').id)
            .buildAndSave();
        System.debug('Inserted ---> '+pt);
        
        if( rdc.BMCServiceDesk__Fulfillment_Inputs__r.size() >  0 )
        {
            //building fulfillment Inputs fields
            List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffiListParameter = new BMCFulfillmentIPsWrapper(rdc.Id,pt,rdc.BMCServiceDesk__Fulfillment_Inputs__r)
                .withLookupFilters()
                .withFFInputs(false)
                .withConditionalInputs(false)
                .withMappings()
                .buildAndSave();
        }            
        
        return rdc;
        
    }//
    
    /**
     * API exposed to UI to pass the JSON in the form of a string from with a Request Definition is to be created.
     */
    @AuraEnabled
    public static void upsertServiceRequest(String fileContents) {
        Savepoint sp = Database.setSavepoint();
        try {
            HD_RequestDefinitionManager factory = new HD_RequestDefinitionManager();
            BMCServiceDesk__SRM_RequestDefinition__c rfc ;
            if(fileContents != null)
            {
                rfc = (BMCServiceDesk__SRM_RequestDefinition__c)JSON.deserialize(fileContents, BMCServiceDesk__SRM_RequestDefinition__c.class);
            }
            
            if(rfc.BMCServiceDesk__Fulfillment_Inputs__r != null) {
                System.debug('FF Input:'+rfc.BMCServiceDesk__Fulfillment_Inputs__r[0]);
            }
            BMCServiceDesk__SRM_RequestDefinition__c inserted_REQ_DEF = factory.SRM_Requestdefinition(rfc);
        }
        catch(Exception ex) {
            Database.rollback(sp);
            throw new AuraHandledException(ex.getMessage());
        }
    }//
    
    /**
     * API that reads the sample JSON(Request Definition) stored as a static resource
     * Added by Arihant Jain for PRTORES-1593
     */
    @AuraEnabled
    public static BMCServiceDesk__SRM_RequestDefinition__c readSampleJSON(String filename){
        StaticResource sr= [Select Id,Body from StaticResource Where Name = :filename];
		String inputJSON = sr.body.toString();
        BMCServiceDesk__SRM_RequestDefinition__c jsonDeSerialized = 
            (BMCServiceDesk__SRM_RequestDefinition__c)JSON.deserialize(inputJSON, BMCServiceDesk__SRM_RequestDefinition__c.class);
        return jsonDeSerialized;
    }
    
    /**
     * API that returns all the request definitions in the org
     */
    @AuraEnabled(cacheable=true)
    public static List<BMCServiceDesk__SRM_RequestDefinition__c> getAllRequestDefinitions() {
        return [SELECT Id,Name FROM BMCServiceDesk__SRM_RequestDefinition__c ORDER BY Name LIMIT 5000];
    }
    
    /**
     * API that is used to generate the JSON representation of the request definition
     */
    @AuraEnabled
    public static BMCServiceDesk__SRM_RequestDefinition__c generateJSON(String requestDefnId) {
        String query = new BMCRequestDefnWrapper().getQueryString(Id.valueOf(requestDefnId));
      
        //return query;
        BMCServiceDesk__SRM_RequestDefinition__c rdc = (BMCServiceDesk__SRM_RequestDefinition__c)Database.query(query);
        BMCServiceDesk__SRM_RequestDefinition__c processedRDC = new BMCRequestDefnWrapper(rdc, true)
                              .withBusinessService(true)
                              .withServiceOffering(true)
                              .withCategory(true)
                              .getRecord();
        
        new BMCFulfillmentIPsWrapper(rdc.BMCServiceDesk__Fulfillment_Inputs__r)
            .withFFInputs(true)
            .withConditionalInputs(true)
            .getRecords();
        
        return processedRDC;
    }
    
    public static List<String> requestDefinitionFieldsForAssert() {
        return new BMCRequestDefnWrapper().fieldsToBeGenerated;
    }
    
    
    
    public static List<String> fulFillmentInputFieldsForAssert() {
        return new BMCFulfillmentIPsWrapper().fieldsToBeGenerated;
    }
    
    private abstract class BMCObjectWrapper {
        protected SObject record;
        protected List<SObject> records;
        public BMCObjectWrapper(String type, String fields, String searchCriteria) {
			records = loadRecord(type, fields, searchCriteria);
            if(records != null && records.size() > 0) {
                record = records[0];
            }
        }
        
        public BMCObjectWrapper(String type) {
            record = Schema.getGlobalDescribe().get(type).newSObject();
        }
        
        public BMCObjectWrapper() {}
        
        protected List<SObject> loadRecord(String type, String fields, String searchCriteria) {
            String query = String.isEmpty(fields) ?
                'SELECT '+ String.join(new List<String>(Schema.getGlobalDescribe().get(type).getDescribe().fields.getMap().keySet()), ',') +
                ' FROM ' + type :
            	'SELECT '+ fields + ',' +String.join(new List<String>(Schema.getGlobalDescribe().get(type).getDescribe().fields.getMap().keySet()), ',') +
                ' FROM ' + type;
            if(!String.isEmpty(searchCriteria)) {
                query += ' WHERE '+searchCriteria;
            }
            return Database.query(query);
        }
    }
    
    private class BMCSYSTemplateWrapper extends BMCObjectWrapper {
        public BMCSYSTemplateWrapper(String name) {
            super('BMCServiceDesk__SYSTemplate__c','','Name =\''+name+'\'');
            if(record == null) {
                record = new BMCServiceDesk__SYSTemplate__c();
            }
        } 
        
        public BMCServiceDesk__SYSTemplate__c getRecord() {
            return (BMCServiceDesk__SYSTemplate__c)record;
        }
        
        public BMCSYSTemplateWrapper withTemplateFor(String templateFor) {
            record.put('BMCServiceDesk__TemplateFor__c', templateFor);
            return this;
        }
        
        public BMCSYSTemplateWrapper withName(String name) {
            record.put('Name',name);
            return this;
        }
        
        public BMCSYSTemplateWrapper withDescription(String description) {
            record.put('BMCServiceDesk__Description__c', description);
            return this;
        }
        
        public BMCSYSTemplateWrapper withKeywords( String keywords) {
            record.put('BMCServiceDesk__Keywords__c', keywords);
            return this;
        }
        
        public BMCServiceDesk__SYSTemplate__c buildAndSave() {
            upsert record;
            return (BMCServiceDesk__SYSTemplate__c)record;
        }
    }
    
    private class BMCTemplateLinkWrapper extends BMCObjectWrapper {
        private Boolean exists;
        public BMCTemplateLinkWrapper(Id incidentTemplate, Id requestDetailTemplate) {
            super('BMCServiceDesk__SYSTemplateLink__c', '',
                  'BMCServiceDesk__LinkedTemplateId__c=\'' +incidentTemplate +'\' AND '
                  +'BMCServiceDesk__ParentTemplateId__c = \''+requestDetailTemplate+'\'');
            exists = record != null;
            if(record == null) {
                record = new BMCServiceDesk__SYSTemplateLink__c(
                BMCServiceDesk__LinkedTemplateId__c = incidentTemplate,
                BMCServiceDesk__ParentTemplateId__c = requestDetailTemplate);
            }
        }
        
        public BMCServiceDesk__SYSTemplateLink__c buildAndSave() {
            if(!exists) {
                insert record;
            }
            
            return (BMCServiceDesk__SYSTemplateLink__c)record;
        }
    }
    
    private class BMCRequestDefnWrapper extends BMCObjectWrapper {
        public List<String> fieldsToBeGenerated = new List<String>{
            	'Name',
                'BMCServiceDesk__ServiceRequestTitle__c',
                'BMCServiceDesk__FKCategory__c',
                'BMCServiceDesk__Description__c',
                'BMCServiceDesk__FKBusinessService__c',
                'BMCServiceDesk__FKServiceOffering__c',
                'BMCServiceDesk__Online__c'};
        private Map<String,BMCServiceDesk__BMC_BaseElement__c> baseElementMap = new Map<String,BMCServiceDesk__BMC_BaseElement__c>();
        private Map<Id,String> baseElementNameToIdMap = new Map<Id,String>();
        public BMCRequestDefnWrapper(BMCServiceDesk__SRM_RequestDefinition__c rdc, Boolean convertBack) {
            if(convertBack) {
                record = rdc;
                //Logic for finding the BUsiness services and Service Offeing id Via Name
                List<BMCServiceDesk__BMC_BaseElement__c> bslist = 
                    (List<BMCServiceDesk__BMC_BaseElement__c>) loadRecord('BMCServiceDesk__BMC_BaseElement__c','',
                                                                          'Id IN (\''+rdc.BMCServiceDesk__FKBusinessService__c+'\',\''+rdc.BMCServiceDesk__FKServiceOffering__c+'\')');
                for(BMCServiceDesk__BMC_BaseElement__c bso : bslist)
                {
                    baseElementNameToIdMap.put(bso.Id, bso.Name);
                }
            }
            else {
                super('BMCServiceDesk__SRM_RequestDefinition__c','BMCServiceDesk__FKCategory__r.Name',
                      'Name =\''+rdc.Name+'\' AND BMCServiceDesk__FKCategory__r.Name =\''+rdc.BMCServiceDesk__FKCategory__c+'\'');
                if(record != null) {
                    rdc.Id = record.Id;
                }
                record = rdc;
                record.put('BMCServiceDesk__AllAccounts__c', true);
                record.put('BMCServiceDesk__Profiles__c', 'ALL');
                record.put('BMCServiceDesk__Status__c', 'Deployed');
                record.put('BMCServiceDesk__ProvideInformation__c', 'Attachment__c');
                
                //Logic for finding the BUsiness services and Service Offeing id Via Name
                List<BMCServiceDesk__BMC_BaseElement__c> bslist = 
                    (List<BMCServiceDesk__BMC_BaseElement__c>) loadRecord('BMCServiceDesk__BMC_BaseElement__c','',
                                                                          'Name IN (\''+rdc.BMCServiceDesk__FKBusinessService__c+'\',\''+rdc.BMCServiceDesk__FKServiceOffering__c+'\')');
                for(BMCServiceDesk__BMC_BaseElement__c bso : bslist)
                {
                    baseElementMap.put(bso.Name, bso);
                }
                
            }
        }
        public BMCRequestDefnWrapper(){}
        public BMCRequestDefnWrapper withBusinessService(Boolean convertBack) {
            if(convertBack) {
            	record.put('BMCServiceDesk__FKBusinessService__c', baseElementNameToIdMap.get((Id)record.get('BMCServiceDesk__FKBusinessService__c')));                                
            }
            else {
            	record.put('BMCServiceDesk__FKBusinessService__c', baseElementMap.get((String)record.get('BMCServiceDesk__FKBusinessService__c')).Id);                
            }
            return this;
        }
        
        public BMCRequestDefnWrapper withServiceOffering(Boolean convertBack) {
            if(convertBack) {
            	record.put('BMCServiceDesk__FKServiceOffering__c', baseElementNameToIdMap.get((Id)record.get('BMCServiceDesk__FKServiceOffering__c')));                                                
            }
            else {
            	record.put('BMCServiceDesk__FKServiceOffering__c', baseElementMap.get((String)record.get('BMCServiceDesk__FKServiceOffering__c')).Id);                
            }
            return this;
        }
        
        public BMCRequestDefnWrapper withCategory(Boolean convertBack) {
            if(convertBack) {
                List<BMCServiceDesk__Category__c> categories = 
                    (List<BMCServiceDesk__Category__c>)loadRecord('BMCServiceDesk__Category__c','',
                                                                  'Id =\'' +record.get('BMCServiceDesk__FKCategory__c') +'\'');
                if(categories.size() > 0) {
                    record.put('BMCServiceDesk__FKCategory__c',categories[0].Name);
                }
            }
            else {
                List<BMCServiceDesk__Category__c> categories = 
                    (List<BMCServiceDesk__Category__c>)loadRecord('BMCServiceDesk__Category__c','',
                                                                  'Name =\'' +record.get('BMCServiceDesk__FKCategory__c') +'\'');
                if(categories.size() > 0) {
                    record.put('BMCServiceDesk__FKCategory__c',categories[0].Id);
                }
            }
            return this;
        }
        
        public BMCServiceDesk__SRM_RequestDefinition__c getRecord() {
            return (BMCServiceDesk__SRM_RequestDefinition__c)record;
        }  
        
        public String getQueryString(Id requestDefnId) {
            return 'SELECT '+ String.join(fieldsToBeGenerated, ',')
                			+ ',('+new BMCFulfillmentIPsWrapper().getQueryString()+')'
            	            +' FROM BMCServiceDesk__SRM_RequestDefinition__c WHERE Id =\''+requestDefnId+'\'';
        }
        
        public BMCServiceDesk__SRM_RequestDefinition__c buildAndSave() {
            upsert record;
            return (BMCServiceDesk__SRM_RequestDefinition__c)record;
        }
    }
    
    private class BMCProcessTemplateWrapper extends BMCObjectWrapper {
        private Boolean exists;
        public BMCProcessTemplateWrapper(Id requestDefnId, Id requestDetailTempId) {
            super('BMCServiceDesk__SRM_ProcessTemplate__c', '',
                  'BMCServiceDesk__FKRequestDefinition__c=\'' +requestDefnId +'\' AND '
                  +'BMCServiceDesk__FKTemplate__c = \''+requestDetailTempId+'\'');
            exists = record != null;
            if(record == null) {
                record = new BMCServiceDesk__SRM_ProcessTemplate__c(
                    BMCServiceDesk__FKRequestDefinition__c = requestDefnId,
                    BMCServiceDesk__FKTemplate__c = requestDetailTempId);
            }
        }
        
        public BMCServiceDesk__SRM_ProcessTemplate__c buildAndSave() {
            if(!exists) {
            	insert record;
            }
            return (BMCServiceDesk__SRM_ProcessTemplate__c)record;
        }
    }
    
    private class BMCFulfillmentIPsWrapper extends BMCObjectWrapper {
        public List<String> fieldsToBeGenerated = new List<String>{
            	'BMCServiceDesk__Order__c',
                'BMCServiceDesk__ResponseType__c',
                'BMCServiceDesk__Prompt__c',
                'BMCServiceDesk__Required__c',
                'BMCServiceDesk__InputValues__c',
                'BMCServiceDesk__Conditional__c',
                'BMCServiceDesk__ConditionsPostfix__c',
                'BMCServiceDesk__AdditionalInfo__c',
                'HD_Input_Key__c'};
        private Map<String, BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap;
        private Map<Id, BMCServiceDesk__SRM_FulfillmentInputs__c> idToffIPMap = new Map<Id, BMCServiceDesk__SRM_FulfillmentInputs__c>();
        private Id rdcId;
        private BMCServiceDesk__SRM_ProcessTemplate__c pt;
        private List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffIPsToUpdate;
        
        public BMCFulfillmentIPsWrapper(Id rdcId, BMCServiceDesk__SRM_ProcessTemplate__c pt, List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffIPsToUpdate) {
            super('BMCServiceDesk__SRM_FulfillmentInputs__c', '','BMCServiceDesk__FKRequestDefinition__c = \''+rdcId+'\'');
            this.rdcId = rdcId;
            this.pt = pt;
            this.ffIPsToUpdate = ffIPsToUpdate;
            promptToffIPMap = new Map<String, BMCServiceDesk__SRM_FulfillmentInputs__c>();
            for(SObject ffIP : records) {
                promptToffIPMap.put(
                    getKey(ffIP), 
                    (BMCServiceDesk__SRM_FulfillmentInputs__c)ffIP);
            }
        }
        
        public BMCFulfillmentIPsWrapper(List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffIPs) {
            records = ffIPs;
            for(SObject ffIP : records) {
                idToffIPMap.put(
                    ffIP.Id, 
                    (BMCServiceDesk__SRM_FulfillmentInputs__c)ffIP);
            }
        }
        
        public BMCFulfillmentIPsWrapper(){}
        
        public BMCFulfillmentIPsWrapper withFFInputs(Boolean convertBack) {
            if(convertBack) {
                
            }
            else {
                if(records != null) {
                    for(BMCServiceDesk__SRM_FulfillmentInputs__c ffIP : ffIPsToUpdate) {
                        if(promptToffIPMap.containsKey(getKey(ffIP))) {
                            ffIP.Id = promptToffIPMap.get(getKey(ffIP)).Id;
                        }
                        else {
                            ffIP.BMCServiceDesk__FKRequestDefinition__c = this.rdcId;
                        }
                        promptToffIPMap.put(getKey(ffIP), ffIP);
                    }
                    records = promptToffIPMap.values();
                    upsert records;
                }
            }

            return this;
        }
        
        public BMCFulfillmentIPsWrapper withConditionalInputs(Boolean convertBack) {   
            if(convertBack){
                for(SObject ip : records) {
                    String conditionalExpression = (String)ip.get('BMCServiceDesk__ConditionsPostfix__c');
                    if(!string.isEmpty(conditionalExpression)) {
                        idToffIPMap.get(ip.Id).BMCServiceDesk__ConditionsPostfix__c = 
                            replaceConditionalValues(conditionalExpression, convertBack);
                    }
                }
            }
            else {
                List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffsToUpdate = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>();
                for(SObject ip : records) {
                    String conditionalExpression = (String)ip.get('BMCServiceDesk__ConditionsPostfix__c');
                    if(!string.isEmpty(conditionalExpression)) {
                        promptToffIPMap.get(getKey(ip)).BMCServiceDesk__ConditionsPostfix__c = 
                            replaceConditionalValues(conditionalExpression, convertBack);
                        ffsToUpdate.add(promptToffIPMap.get(getKey(ip)));
                    }
                }
            }
            
            //update ffsToUpdate;
            return this;
        }

        public BMCFulfillmentIPsWrapper withLookupFilters() {
            List<BMCServiceDesk__LookupFilter__c> existingFilters = (List<BMCServiceDesk__LookupFilter__c>)loadRecord('BMCServiceDesk__LookupFilter__c','','');
            Map<String, BMCServiceDesk__LookupFilter__c> filterMap = new Map<String, BMCServiceDesk__LookupFilter__c>();
            for(BMCServiceDesk__LookupFilter__c filter : existingFilters) {
                filterMap.put(filter.Name, filter);
            }
            
            for(BMCServiceDesk__SRM_FulfillmentInputs__c ffIP : ffIPsToUpdate) {
                if(ffIP.BMCServiceDesk__FKLookupFilter__r != null && 
                   !filterMap.containsKey(ffIP.BMCServiceDesk__FKLookupFilter__r.Name)) {
                    	filterMap.put(ffIP.BMCServiceDesk__FKLookupFilter__r.Name, ffIP.BMCServiceDesk__FKLookupFilter__r);
                }
            }
        	upsert filterMap.values();
        
            for(BMCServiceDesk__SRM_FulfillmentInputs__c ffIP : ffIPsToUpdate) {
                if(ffIP.BMCServiceDesk__FKLookupFilter__r != null) {
                    BMCServiceDesk__LookupFilter__c lkpFilter = ffIP.BMCServiceDesk__FKLookupFilter__r;
                    ffIP.BMCServiceDesk__FKLookupFilter__r = null;
                    ffIP.BMCServiceDesk__FKLookupFilter__c = filterMap.get(lkpFilter.Name).Id;
                }
            }
        
            return this;
        }
        
        public BMCFulfillmentIPsWrapper withMappings() {
            if(pt == null) {
                return null;
            }
                
            List<BMCServiceDesk__SRM_FulfillmentMappings__c> existingMappings = 
                (List<BMCServiceDesk__SRM_FulfillmentMappings__c>) getFulfillmentMappings('BMCServiceDesk__SRM_FulfillmentMappings__c', 
                                                                              'BMCServiceDesk__FKProcessTemplate__c = \''+pt.Id+'\'');
            
            Map<String, BMCServiceDesk__SRM_FulfillmentMappings__c> promptToMappingMap = new Map<String,BMCServiceDesk__SRM_FulfillmentMappings__c>();
            for(BMCServiceDesk__SRM_FulfillmentMappings__c mapping : existingMappings) {
                promptToMappingMap.put(getKey(mapping.BMCServiceDesk__FKFulfillmentInputs__r), mapping);
            }
            
            List<BMCServiceDesk__SRM_FulfillmentMappings__c> mappingsToUpsert = new List<BMCServiceDesk__SRM_FulfillmentMappings__c>();
            for(BMCServiceDesk__SRM_FulfillmentInputs__c ffIP : promptToffIPMap.values()) {
                if(ffIP.BMCServiceDesk__Fulfillment_Mappings__r != null && 
                   ffIP.BMCServiceDesk__Fulfillment_Mappings__r.size() > 0) {
                       BMCServiceDesk__SRM_FulfillmentMappings__c mapping = promptToMappingMap.containsKey(getKey(ffIP)) 
                           ? promptToMappingMap.get(getKey(ffIP))
                           :new BMCServiceDesk__SRM_FulfillmentMappings__c();
                       if(mapping.BMCServiceDesk__FKFulfillmentInputs__c == null) {
                            mapping.BMCServiceDesk__FKFulfillmentInputs__c = ffIP.Id;                       
                       }
                       mapping.BMCServiceDesk__FKProcessTemplate__c = pt.Id;
                       mapping.BMCServiceDesk__ProcessVariable__c = ffIP.BMCServiceDesk__Fulfillment_Mappings__r[0].BMCServiceDesk__ProcessVariable__c;
                       mapping.BMCServiceDesk__FKTemplate__c = pt.BMCServiceDesk__FKTemplate__c;
                       mappingsToUpsert.add(mapping);
                   }
            }
            
            upsert mappingsToUpsert;
            return this;
        }
        
        public List<BMCServiceDesk__SRM_FulfillmentInputs__c> buildAndSave() {
            upsert records;
            return (List<BMCServiceDesk__SRM_FulfillmentInputs__c>)records;
        }
        
        private String getKey(SObject input) {
            if(input instanceof BMCServiceDesk__SRM_FulfillmentInputs__c) {
                BMCServiceDesk__SRM_FulfillmentInputs__c ip = (BMCServiceDesk__SRM_FulfillmentInputs__c)input;
                if(ip.get('HD_Input_Key__c') != null) {
                	return (String)ip.get('BMCServiceDesk__Prompt__c')+'_'+Integer.valueOf(ip.get('HD_Input_Key__c'));
                }
                else {
                    return (String)ip.get('BMCServiceDesk__Prompt__c');
                }
            }
            else {
                return '';
            }
        }
        
        private String replaceConditionalValues(String conditionValuesHolder, Boolean convertBack) {
            if(convertBack) {
                for(Id id : idToffIPMap.keySet()) {
                    if(conditionValuesHolder.contains(id)) {
                        conditionValuesHolder = conditionValuesHolder.replace(id, '[' + getKey(idToffIPMap.get(id))+ ']');
                    }
                }
            }
            else {
                for(String prompt : promptToffIPMap.keySet()) {
                    if(conditionValuesHolder.contains('['+prompt+']')) {
                        conditionValuesHolder = conditionValuesHolder.replace('['+prompt+']', promptToffIPMap.get(prompt).Id);
                    }
                }
            }
        	return conditionValuesHolder;
        }    
        
        private List<BMCServiceDesk__SRM_FulfillmentMappings__c> getFulfillmentMappings(String type, String whereCondition) { 
            String query = 'SELECT BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Prompt__c,BMCServiceDesk__FKFulfillmentInputs__r.HD_Input_Key__c,' + 
                String.join(new List<String>(Schema.getGlobalDescribe().get(type).getDescribe().fields.getMap().keySet()), ',') +
                ' FROM ' + type +' WHERE '+whereCondition;
            return Database.query(query);
        }
        
        public String getQueryString() {
            return 'SELECT '+ String.join(fieldsToBeGenerated, ',') 
                //+ ',('+new FulfillmentMappingWrapper().getQueryString()+')'
                + ' FROM BMCServiceDesk__Fulfillment_Inputs__r ORDER BY BMCServiceDesk__Order__c';
        }
        
        public List<BMCServiceDesk__SRM_FulfillmentInputs__c> getRecords() {
            return (List<BMCServiceDesk__SRM_FulfillmentInputs__c>)records;
        }
    }
    
    private class FulfillmentMappingWrapper extends BMCObjectWrapper {
        private List<String> fieldsToBeGenerated = new List<String>{
            	'BMCServiceDesk__ProcessVariable__c'};
                    
        public FulfillmentMappingWrapper() {
                        
        }
        
        public String getQueryString() {
            return 'SELECT '+ String.join(fieldsToBeGenerated, ',') 
                + ' FROM BMCServiceDesk__Fulfillment_Mappings__r';
        }
    }
}//CLASS END