/*
* File Name: HD_RequestDefinitionManager_Test
* Description : Test class for HD_RequestDefinitionManager
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				Author 					Modification
* Jan 20th, 2020	Aneesh Budnar			PRTORES-1604 - Hyperion Cost Center changes to be pushed to QA and Prod
* Feb 5th, 2020		Arihant Jain			PRTORES-1593 - Create an App to host P2R Dev tools
*/
@isTest(SeeAllData = false)
public class HD_RequestDefinitionManager_Test {
    private static String inputJSON;
    
    static {
        StaticResource sr= [select Id,Body from StaticResource Where Name = 'Test_Service_Request_Defn'];
		inputJSON = sr.body.toString();
    }
    
    @testSetup
    public static void setup() {
        BMCServiceDesk__BMC_BaseElement__c parentElement = new BaseElementBuilder()
            .withServiceDeskName('Test Parent Service')
            .withServiceType('BusinessService')
            .buildAndSave();
        
        BMCServiceDesk__BMC_BaseElement__c childElement = new BaseElementBuilder()
            .withServiceDeskName('Test Child Service')
            .withParentService(parentElement.Id)
            .withServiceType('Offering')
            .buildAndSave();
        BMCServiceDesk__CategoryTypes__c categoryType = 
            new BMCServiceDesk__CategoryTypes__c(Name='Test Category Type');
        insert categoryType;
        insert new BMCServiceDesk__Category__c(BMCServiceDesk__FKCategoryType__c = categoryType.Id, Name='Test Category');
    }
    
    @isTest
    public static void when_readSampleJSONInvoked_Expect_RequestDefObjectReturned(){
        BMCServiceDesk__SRM_RequestDefinition__c rd = HD_RequestDefinitionManager.readSampleJSON('Test_Service_Request_Defn');
        System.assertEquals(rd, (BMCServiceDesk__SRM_RequestDefinition__c)JSON.deserialize(inputJSON, BMCServiceDesk__SRM_RequestDefinition__c.class));
    }
    
    @isTest
    public static void when_NewRequestDefnUploaded_Expect_RequestDefnIsCreated() {

        Test.startTest();
        HD_RequestDefinitionManager.upsertServiceRequest(inputJSON);
        Test.stopTest();
        
        verifyRequestDefinition();
        Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap = verifyFulfillmentInputs();
        verifyLookupFilters(promptToffIPMap);
        verifyMappings(promptToffIPMap);
    }
    
    @isTest
    public static void when_ExistingRequestDefnUploaded_Expect_RequestDefnIsUpdated() {
        HD_RequestDefinitionManager.upsertServiceRequest(inputJSON);

        Test.startTest();
        HD_RequestDefinitionManager.upsertServiceRequest(inputJSON);
        Test.stopTest();
        
        verifyRequestDefinition();
        Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap = verifyFulfillmentInputs();
        verifyLookupFilters(promptToffIPMap);
        verifyMappings(promptToffIPMap);
    }
    
    @isTest
    public static void when_GenerateJSONIsInvoked_Expect_ReqestDefnJSONCreated() {
        HD_RequestDefinitionManager.upsertServiceRequest(inputJSON);
        List<BMCServiceDesk__SRM_RequestDefinition__c> rdcs = 
            (List<BMCServiceDesk__SRM_RequestDefinition__c>)queryObject('BMCServiceDesk__SRM_RequestDefinition__c');
        
        Test.startTest();
        BMCServiceDesk__SRM_RequestDefinition__c processedRDC = HD_RequestDefinitionManager.generateJSON(rdcs[0].Id);
        Test.stopTest();
        
        BMCServiceDesk__SRM_RequestDefinition__c expectedRDC = (BMCServiceDesk__SRM_RequestDefinition__c)JSON.deserialize(inputJSON, BMCServiceDesk__SRM_RequestDefinition__c.class);
        for(String prop : HD_RequestDefinitionManager.requestDefinitionFieldsForAssert()) {
            System.assertEquals(prop+' : '+String.valueOf(expectedRDC.get(prop)), prop+' : '+String.valueOf(processedRDC.get(prop)));
        }
        
        for(Integer i=0; i < expectedRDC.BMCServiceDesk__Fulfillment_Inputs__r.size(); i++){
            BMCServiceDesk__SRM_FulfillmentInputs__c expectedffIP = expectedRDC.BMCServiceDesk__Fulfillment_Inputs__r[i];
            BMCServiceDesk__SRM_FulfillmentInputs__c actualffIP = processedRDC.BMCServiceDesk__Fulfillment_Inputs__r[i];
            for(String prop : HD_RequestDefinitionManager.fulFillmentInputFieldsForAssert()) {
                if(expectedffIP.get(prop) != null && expectedffIP.get(prop) != '') {
                	System.assert(String.valueOf(expectedffIP.get(prop)).contains(String.valueOf(actualffIP.get(prop))));
                }
            }
        }
    }

    private static void verifyRequestDefinition() {
        Map<String, BMCServiceDesk__BMC_BaseElement__c> baseElements = new Map<String, BMCServiceDesk__BMC_BaseElement__c>();
        for(BMCServiceDesk__BMC_BaseElement__c element : (List<BMCServiceDesk__BMC_BaseElement__c>)queryObject('BMCServiceDesk__BMC_BaseElement__c')){            
            baseElements.put(element.Name, element);
        }
        
        BMCServiceDesk__Category__c category = [Select Id,Name from BMCServiceDesk__Category__c WHERE Name = 'Test Category' LIMIT 1];

        Map<String, Object> requestDefnExpectedResults = new Map<String, Object>{
            'Name' => 'Test Service Request',
            'BMCServiceDesk__serviceRequestTitle__c' => 'Test Service Request',
            'BMCServiceDesk__FKCategory__c' => category.Id,
            'BMCServiceDesk__Description__c' => 'Test Service Request',
            'BMCServiceDesk__FKBusinessService__c' => baseElements.get('Test Parent Service').Id,
            'BMCServiceDesk__FKServiceOffering__c' => baseElements.get('Test Child Service').Id,
            'BMCServiceDesk__Online__c' => True
        };
            
        List<BMCServiceDesk__SRM_RequestDefinition__c> rdcs = 
            (List<BMCServiceDesk__SRM_RequestDefinition__c>)queryObject('BMCServiceDesk__SRM_RequestDefinition__c');
        System.assert( rdcs != null && rdcs.size() ==1 );
        for(String fieldName : requestDefnExpectedResults.keySet()) {
            System.assertEquals(requestDefnExpectedResults.get(fieldName), rdcs[0].get(fieldName));
        }
    }

    private static Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> verifyFulfillmentInputs() {
        List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffIPs = 
            (List<BMCServiceDesk__SRM_FulfillmentInputs__c>)queryObject('BMCServiceDesk__SRM_FulfillmentInputs__c');
        Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap = new Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c>();
        for(BMCServiceDesk__SRM_FulfillmentInputs__c ffIP : ffIPs) {
            if(ffIP.get('HD_Input_Key__c') != null) {
            	promptToffIPMap.put(ffIP.BMCServiceDesk__Prompt__c+'_'+ffIP.get('HD_Input_Key__c'), ffIP);
            }
            else {
            	promptToffIPMap.put(ffIP.BMCServiceDesk__Prompt__c, ffIP);
            }
        }
        Map<String, Map<String, Object>> ffIPsExpectedResults = new Map<String, Map<String, Object>> {
            'Fulfillment Input 1' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 1,
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 1',
                'BMCServiceDesk__ResponseType__c' => 'Picklist',
                'BMCServiceDesk__Required__c' => True,
                'BMCServiceDesk__InputValues__c' => 'Picklist Value 1фPicklist Value 1фfalseПPicklist Value 2фPicklist Value 2фfalseПPicklist Value 3фPicklist Value 3фfalse'
            },
            'Fulfillment Input 2' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 2,
                'BMCServiceDesk__ResponseType__c' => 'Text Field',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 2',
                'BMCServiceDesk__Conditional__c' => True,
                'BMCServiceDesk__ConditionsPostfix__c' => '1П'+promptToffIPMap.get('Fulfillment Input 1').Id+'ПTFulfillment Input 1П=ПPicklist Value 1ПPicklist¬'+
                    									  '2П'+promptToffIPMap.get('Fulfillment Input 1').Id+'ПFulfillment Input 1П=ПPicklist Value 2ПPicklist¬OR'                   
            },
            'Fulfillment Input 3' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 3,
                'BMCServiceDesk__ResponseType__c' => 'Text Area',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 3',
                'BMCServiceDesk__Required__c' => True
            },
            'Fulfillment Input 4' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 4,
                'BMCServiceDesk__ResponseType__c' => 'Lookup',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 4',
                'BMCServiceDesk__Required__c' => True,
                'BMCServiceDesk__InputValues__c' => 'User'
            },
            'Fulfillment Input 5_1' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 5,
                'BMCServiceDesk__ResponseType__c' => 'Picklist',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 5',
                'BMCServiceDesk__Required__c' => true,
                'BMCServiceDesk__InputValues__c' => 'Option1фOption1фfalseПOption2фOption2фfalseПOption3фOption3фfalse'
            },
            'Fulfillment Input 5_2' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 6,
                'BMCServiceDesk__ResponseType__c' => 'Picklist',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 5',
                'BMCServiceDesk__Required__c' => true,
                'BMCServiceDesk__InputValues__c' => 'Option4фOption4фfalseПOption5фOption5фfalseПOption6фOption6фfalse'
            },
            'Fulfillment Input 6' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 7,
                'BMCServiceDesk__ResponseType__c' => 'Picklist',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 6',
                'BMCServiceDesk__Required__c' => true,
                'BMCServiceDesk__InputValues__c' => 'Highф3фfalseПStandardф4фfalse'
            },
            'Fulfillment Input 7' => new Map<String, Object> {
                'BMCServiceDesk__Order__c' => 8,
                'BMCServiceDesk__ResponseType__c' => 'Text Field',
                'BMCServiceDesk__Prompt__c' => 'Fulfillment Input 7',
                'BMCServiceDesk__Required__c' => true
            }
        };
        
        for(String prompt : ffIPsExpectedResults.keySet()) {
            for(String prop : ffIPsExpectedResults.get(prompt).keySet()) {
                System.assertEquals(ffIPsExpectedResults.get(prompt).get(prop), promptToffIPMap.get(prompt).get(prop));
            }
        }
        
        return promptToffIPMap;
    }

    private static void verifyLookupFilters(Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap) {
		List<BMCServiceDesk__LookupFilter__c> lookupFilters = 
            (List<BMCServiceDesk__LookupFilter__c>)queryObject('BMCServiceDesk__LookupFilter__c');
        
        Map<String, Object> lookupFilterExpected = new Map<String, Object>{
            'Name' => 'Fulfillment Input 4',
            'BMCServiceDesk__Console__c' => 'SRM_Fulfillmentinput__c',
            'BMCServiceDesk__FilterFor__c' => 'User',
            'BMCServiceDesk__FilterLogic__c' => '1',
            'BMCServiceDesk__FilterType__c' => 'Required',
            'BMCServiceDesk__QueryCondition__c' => '(IsActive = True)'
        };
        System.assert( lookupFilters != null && lookupFilters.size() ==1 );
        for(String filterProp : lookupFilterExpected.keySet()) {
            System.assertEquals(lookupFilterExpected.get(filterProp), lookupFilters[0].get(filterProp));
        }        
        System.assertEquals(promptToffIPMap.get('Fulfillment Input 4').BMCServiceDesk__FKLookupFilter__c,lookupFilters[0].Id);
    }

    private static void verifyMappings( Map<String,BMCServiceDesk__SRM_FulfillmentInputs__c> promptToffIPMap) {
        
		List<BMCServiceDesk__SRM_FulfillmentMappings__c> mappings = 
            (List<BMCServiceDesk__SRM_FulfillmentMappings__c>)queryObject('BMCServiceDesk__SRM_FulfillmentMappings__c');
        Map<Id, BMCServiceDesk__SRM_FulfillmentMappings__c> ffIPToMapping = new Map<Id,BMCServiceDesk__SRM_FulfillmentMappings__c>();
            for(BMCServiceDesk__SRM_FulfillmentMappings__c mapping : mappings) {
                ffIPToMapping.put(mapping.BMCServiceDesk__FKFulfillmentInputs__c ,mapping);
            }
        BMCServiceDesk__SYSTemplate__c requestDetailTemplate = 
            [Select Id, BMCServiceDesk__TemplateFor__c FROM BMCServiceDesk__SYSTemplate__c WHERE BMCServiceDesk__TemplateFor__c = 'Request Detail' LIMIT 1];
        System.assert( mappings != null && mappings.size() == 2 );
		List<BMCServiceDesk__SRM_ProcessTemplate__c> processTemplate = 
            (List<BMCServiceDesk__SRM_ProcessTemplate__c>)queryObject('BMCServiceDesk__SRM_ProcessTemplate__c');
        System.assert( processTemplate != null && processTemplate.size() == 1 ); 
        Map<Id, Map<String, Object>> mappingsExpectedResults = new Map<Id, Map<String, Object>> {
            promptToffIPMap.get('Fulfillment Input 6').Id => new Map<String,Object> {
                'BMCServiceDesk__FKProcessTemplate__c' => processTemplate[0].Id,
                'BMCServiceDesk__ProcessVariable__c' => 'Incident__c:HD_Ticket_Priority__c',
                'BMCServiceDesk__FKTemplate__c' => requestDetailTemplate.Id
             },
             promptToffIPMap.get('Fulfillment Input 7').Id => new Map<String,Object> {
                'BMCServiceDesk__FKProcessTemplate__c' => processTemplate[0].Id,
                'BMCServiceDesk__ProcessVariable__c' => 'Incident__c:CCText__c',
                'BMCServiceDesk__FKTemplate__c' => requestDetailTemplate.Id
             }
        };
        
            
        for(Id ffIPId : mappingsExpectedResults.keySet()) {
            for(String prop : mappingsExpectedResults.get(ffIPId).keySet()) {
                System.assertEquals(mappingsExpectedResults.get(ffIPId).get(prop), ffIPToMapping.get(ffIPId).get(prop));
            }
        }
		
    }
    
    private static List<SObject> queryObject(String type) { 
        String query = 'SELECT '+ String.join(new List<String>(Schema.getGlobalDescribe().get(type).getDescribe().fields.getMap().keySet()), ',') +
            ' FROM ' + type;
        //System.debug('Dynamic query :'+ query);
        return Database.query(query);
    }
    
    private class BaseElementBuilder {
        private BMCServiceDesk__BMC_BaseElement__c record;
        
        public BaseElementBuilder() {
            record = new BMCServiceDesk__BMC_BaseElement__c(
                BMCServiceDesk__Name__c = 'Test Service Ofering'
            );
        }
        
        public BaseElementBuilder withServiceDeskName(String serviceDeskName) {
            record.BMCServiceDesk__Name__c = serviceDeskName;
            return this;
        }
        
        public BaseElementBuilder withParentService(Id parentServiceId) {
            record.BMCServiceDesk__FKBusinessService__c = parentServiceId;
        	return this;
    	}
        
        public BaseElementBuilder withServiceType(String serviceType) {
            record.BMCServiceDesk__ServiceType__c = serviceType;
            return this;
        }
        
        public BMCServiceDesk__BMC_BaseElement__c buildAndSave() {
            upsert record;
            return record;
        }
    }
}