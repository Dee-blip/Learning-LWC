/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 01-24-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   12-27-2021   Vishnu Vardhan   Initial Version
**/
public with sharing class ScJarvisPrechatController {
    
    static final String AMG_INVALID_CASEID = 'We are unable to find that Case ID. Please enter the ID for an existing Client Services / Business Support case, or clear the field and start your chat.';

    public class Category {
        @auraEnabled public String label;
        @auraEnabled public String value;
        @auraEnabled public Boolean hasEditAccess;
        public Category(String label, String value, Boolean hasEditAccess) {
            this.label = label;
            this.value = value;
            this.hasEditAccess = hasEditAccess;
        }
    }

    public class PreChatWrapper {
        @auraEnabled public String accountId;
        @auraEnabled public String contactId;
        @auraEnabled public String firstName;
        @auraEnabled public String lastName;
        @auraEnabled public String origin;
        @auraEnabled public String akatecButtonId;
        @auraEnabled public String amgButtonId;
        @auraEnabled public Boolean hasCaseCreateAccess;
        @auraEnabled public List<String> availableButtons;
        @auraEnabled public List<SC_Select_Options> productList = new List<SC_Select_Options>();
        @auraEnabled public Map<String, String> productToButtonMapping = new Map<String, String>();
        @auraEnabled public List<Category> categoryList = new List<Category>();
    }
    
    @AuraEnabled(cacheable=true)
    public static PreChatWrapper getPreChatInfo(String deploymentId){

        
        PreChatWrapper wrap = new PreChatWrapper();
        wrap.origin = 'AkaChat Community';
        User currUser = [select id, contactid, contact.firstName, contact.lastname,
                                contact.AccountId from User where Id = :UserInfo.getUserId()];
        wrap.accountId = currUser.contact.AccountId;
        wrap.contactid = currUser.contactid;
        wrap.firstName = currUser.Contact.FirstName;
        wrap.lastName = currUser.Contact.LastName;
        wrap.hasCaseCreateAccess = SC_Jarvis_utility.hasCreateAccess(currUser.contactid);
        Map<String, String> buttonNameIdMap = new Map<String, String>();
        List<String> buttonIds = new List<String>();

        for( SC_Utility__mdt dp: [SELECT MasterLabel,Value__c FROM SC_Utility__mdt where Active__c = true and MasterLabel like 'JV_%']) {
            if(!dp.Value__c.startsWith('573')) {
                continue;
            }
            buttonNameIdMap.put(dp.MasterLabel, dp.Value__c);
            if(!buttonIds.contains(dp.Value__c)) {
                buttonIds.add(((Id)dp.Value__c).to15());
            }
        }
        wrap.akatecButtonId = ((id)buttonNameIdMap.get('JV_Akatech_Button')).to15();
        wrap.amgButtonId = ((id)buttonNameIdMap.get('JV_AMG_Button')).to15();

        
        Map<String, String> productIdMap = new Map<String, String>();

        for( EB_AccountProductMap__c pdt: [Select  Id, EB_Product__c from EB_AccountProductMap__c where EB_MarkedForDeletion__c = false 
                     and EB_Account__c = :currUser.contact.AccountId])                      //  and EB_Product__c IN :productToButtonMapping.values() 
        {
            productIdMap.put(pdt.EB_Product__c, pdt.Id);
        }

        wrap.availableButtons = getAvailability(deploymentId, buttonIds);

        String productQueryParam = JSON.serialize(new Map<String, String> { 'accountId' => currUser.Contact.AccountId, 'category' => 'Technical'});
        SC_Jarvis_Create_Case_Controller.CaseCreateWrapper techProdInfo = SC_Jarvis_Create_Case_Controller.getProducts(productQueryParam);

        if(techProdInfo.products != null) {
            for(SC_Select_Options pdt: techProdInfo.products.options) {
                SC_Akachat_Product_Mapping__c pm = SC_Akachat_Product_Mapping__c.getInstance(pdt.label);
                String productId = productIdMap.get(pdt.label);
    
                if(pm ==  null || productId == null) {
                    continue;
                }
                String buttonId = buttonNameIdMap.get('JV_Akatech_Button_' + pm.Skill__c);
                wrap.productList.add(new SC_Select_Options(pdt.label, productId));
                wrap.productToButtonMapping.put(productId, buttonId);
                
            }
        }

        SC_Jarvis_utility.getCategoriesAccounts(wrap.contactid, new List<String>{wrap.accountId});

        Map<String, Schema.RecordTypeInfo> caseRtInfo = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();

        wrap.categoryList.add(new Category('Technical Support', caseRtInfo.get('Technical').getRecordTypeId(), true));
        wrap.categoryList.add(new Category('Business Support', caseRtInfo.get('AMG').getRecordTypeId(), true));

        return wrap;
    }

   
    
    static final String endPointTempl = '/chat/rest/Visitor/Availability?Availability.ids=[{0}]&deployment_id={1}&org_id={2}'; //&version=48
  
    /**
    * @description Get agent availability for list of buttons
    * @author Vishnu Vardhan | 12-28-2021 
    * @param String deploymentId 
    * @param List<String> buttonIds 
    * @return List<String> 
    **/
    public static List<String> getAvailability(String deploymentId, List<String> buttonIds) {
        String buttonIdsStr = String.join(buttonIds, ','); 
        String orgId = ((Id)UserInfo.getOrganizationId()).to15();
        String endPoint = String.format(endPointTempl, new List<String>{buttonIdsStr, deploymentId, orgId});

        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:SalesforceChat'+endPoint);
        req.setMethod('GET');
        req.setHeader('X-LIVEAGENT-API-VERSION', '53');

        Http http = new Http(); 
        HTTPResponse res = http.send(req);
        System.debug('res.getBody' + res.getBody());
        Map<String, Object> resObj = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
        System.debug('res.resObj' + resObj);

        List<Object> messageList = (List<Object>)resObj.get('messages');
        Map<String, Object> message = (Map<String, Object>)((Map<String, Object>)messageList[0]).get('message');

        List<Object> resultsList = (List<Object>)message.get('results');

        List<String> availableIds = new List<String>();

        for(Object resultObj: resultsList) {
            Map<String, Object> rslt = (Map<String, Object>)resultObj;
            if(rslt.containsKey('isAvailable') && (boolean)rslt.get('isAvailable')) {
                availableIds.add((String)rslt.get('id'));
            }
        }
        
        return availableIds;
    }

    @AuraEnabled(cacheable=true)
    public static Id getCaseId(String akamCaseId) {
        User currUser = [select id, contactid, contact.firstName, contact.lastname,
        contact.AccountId from User where Id = :UserInfo.getUserId()];

        
        List<Case> csList = [select id from Case where akam_case_id__c = :akamCaseId 
                                                    AND recordtype.developername = 'AMG'
                                                    AND AccountId = :currUser.contact.AccountId];
        if(csList.isEmpty()) {
            throw new AuraHandledException(AMG_INVALID_CASEID);
        }

        return csList[0].id;
    }
}