global class PreChatController {
    public string areaSelectOption{get;set;}
    public string serviceSelectOption{get;set;}
    public string ctrlValues{get;set;}
    public string depValues{get;set;}
    public string akatechBtnId{get;set;}
    public string amgBtnId{get;set;}
    public string productList{get;set;}
    public string pNameStr{get;set;}
    public Id caseAccountId{get;set;}
    public Id caseContactId{get;set;}
    public String caseContactName{get;set;}
    public String caseAccountName{get;set;}
    public String userEmail{get;set;}
    public Id AMGRecordTypeId{get;set;}
    public Id technicalRecordTypeId{get;set;}
    public string orgId{get;set;}
    public static String errorMessage{get;set;}
    public static String buttonId{get;set;}
    public String ticketUrl{get;set;}
    public String chatBtnLabel{get;set;}
    public String akachatDeploymentJS{get;set;}
    public String akachatInitURL{get;set;}
    public String caseChatOrigin{get;set;}
    public String akachatPhone{get;set;}
    
    //Changes made by Pinkesh
    public String lunaDeploymentId{get;set;}
    public String attDeploymentId{get;set;}
    public String lunaSsoUrl{get;set;}
    public String attSsoUrl{get;set;}
    //end of changes
    
    public PreChatController() {
        try{
            //Changes by Pinkesh
            Map<String,String> PLValuesMap = new Map<String,String>();
            
            for(SC_Utility__mdt  liveChatMetadata : [SELECT MasterLabel,Value__c FROM SC_Utility__mdt where Active__c = true]){
                PLValuesMap.put(liveChatMetadata.MasterLabel,liveChatMetadata.Value__c);
            }
            lunaDeploymentId = PLValuesMap.get('Pre_Chat_Luna_DeploymentId');
            attDeploymentId = PLValuesMap.get('Pre_Chat_ATT_DeploymentId');
            orgId = PLValuesMap.get('Org_Id');
            chatBtnLabel = PLValuesMap.get('Chat_Button');
            akachatDeploymentJS = PLValuesMap.get('Akachat_Deployment_JS');
            akachatInitURL = PLValuesMap.get('Akachat_Init_URL');
            akachatPhone = PLValuesMap.get('Akachat_Phone');
            
            SFCommunity_NQLB_Topics__mdt loginMetadata = [Select id, SSO_Login_URL__c, ATT_Portal_SSO_Login_URL__c FROM SFCommunity_NQLB_Topics__mdt WHERE DeveloperName = 'CommunityNQLB' limit 1];
            lunaSsoUrl = loginMetadata.SSO_Login_URL__c;
            attSsoUrl = loginMetadata.ATT_Portal_SSO_Login_URL__c;
            caseChatOrigin = 'AkaChat Luna';
            //End of Changes
            
            if(userinfo.getUserType() != 'Guest'){
                Map<Id,String> productListMap = new Map<Id,String>();
                List<String> productNameList = new List<String>();
                Id accountId;
                String rtAMG;
                String rtTechnical;
                Schema.DescribeFieldResult fieldResult; 
                List<Schema.PicklistEntry> servicePLE;
                List<Schema.PicklistEntry> rtPLE;
                
                Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
                User loggedInUser = [Select AKAM_User_id__c,ContactId,email from user where id =: Userinfo.getUserId() limit 1];
                String AKAMUserId = loggedInUser.AKAM_User_id__c;
                Id userContactId = loggedInUser.ContactId;
                userEmail = loggedInUser.Email;
                if(AKAMUserId != null && userContactId == null){
                    Contact loggedInContact = [Select id,Name,AccountId,Account.Name from Contact where AKAM_Contact_ID__c =: AKAMUserId];
                    caseAccountId = loggedInContact.AccountId;
                    caseContactId = loggedInContact.Id;
                    caseContactName = loggedInContact.Name;
                    caseAccountName = loggedInContact.Account.Name;
                }
                else if(userContactId != null){
                    Contact loggedInContact = [Select id,Name,AccountId,Account.Name from Contact where id =: userContactId];
                    caseAccountId = loggedInContact.AccountId;
                    caseContactId = loggedInContact.Id;
                    caseContactName = loggedInContact.Name;
                    caseAccountName = loggedInContact.Account.Name;
                }
                
                // Changes by Sheena for ESESP-3596 : Added a condition to remove products that are not supported today by Akatec
                Set<String> setExcludedProducts = new Set<String>();
                SC_Utility__mdt  excludedProds = [SELECT Value__c FROM SC_Utility__mdt where DeveloperName  = 'Excluded_Products'];
                setExcludedProducts.addAll(excludedProds.Value__c.toLowerCase().split(','));
                List<EB_AccountProductMap__c> accountProductList = [Select id,name from EB_AccountProductMap__c where EB_Account__c =: caseAccountId and EB_MarkedForDeletion__c = false order by name asc];
                
                for(EB_AccountProductMap__c thisProduct : accountProductList){
                    if(!setExcludedProducts.contains(thisProduct.name.toLowerCase()))
                    {
                        productListMap.put(thisProduct.id,thisProduct.name);
                        productNameList.add(thisProduct.name);
                    }
                }
                
                productList = JSON.serialize(productListMap);
                productNameList.sort();
                pNameStr = JSON.serialize(productNameList);
                ctrlValues = PLValuesMap.get('Service_PL');
                depValues = PLValuesMap.get('Request_Type_PL');
                rtAMG = PLValuesMap.get('Pre_Chat_RT_AMG'); 
                rtTechnical = PLValuesMap.get('Pre_Chat_RT_Akatech'); 
                akatechBtnId = PLValuesMap.get('Pre_Chat_Akatech_Button');
                amgBtnId = PLValuesMap.get('Pre_Chat_AMG_Button');
                ticketUrl = PLValuesMap.get('Luna_URL')+'/apps/case-management/#/cases/create?category=Technical';
                AMGRecordTypeId = rtMap.get(rtAMG).getRecordTypeId();
                technicalRecordTypeId = rtMap.get(rtTechnical).getRecordTypeId();
                
                fieldResult = case.Service__c.getDescribe();
                servicePLE = fieldResult.getPicklistValues();
                areaSelectOption = json.serialize (servicePLE);
                
                fieldResult = case.Request_Type__c.getDescribe();
                rtPLE = fieldResult.getPicklistValues();
                serviceSelectOption = json.serialize (rtPLE); 
            }
        }
        catch (exception e)
        {
            system.debug('An exception '+e.getMessage() +'occured at line number '+e.getLineNumber());
        }
    }  
    @RemoteAction
    global static String validateCaseId(String existingCaseId){
        List<Case> existingCaseList = new List<Case>();
        errorMessage = '';
        if(!String.isEmpty(existingCaseId)){
            existingCaseList = [Select id,recordType.name from Case where AKAM_Case_Id__c =: existingCaseId];
            
            if(existingCaseList.size() <= 0){
                errorMessage = 'NO CASE';
            }
            
            else{
                for(Case existingCase: existingCaseList){
                    if(existingCase.recordType.name != 'AMG'){
                        errorMessage = 'NO AMG CASE';
                    }
                }
            }
        }
        return errorMessage;
    }
    //Added by Vikas for ESESP-1769
    @RemoteAction
    global static String setAkatecAgent(String selectedProduct){
        //Map to store Case Product - Skill Mapping from Custom Setting
        Map<string, string> caseProductSkillMap = new Map<string, string>();
        Map<String,String> PLValuesMap = new Map<String,String>();
        User loggedInUser = [Select AKAM_User_id__c,ContactId from user where id =: Userinfo.getUserId() limit 1];
        
        buttonId = '';
        for(SC_Utility__mdt  liveChatMetadata : [SELECT MasterLabel,Value__c FROM SC_Utility__mdt where Active__c = true]){
            PLValuesMap.put(liveChatMetadata.MasterLabel,liveChatMetadata.Value__c);
        }
        //Loop for each value from Custom Setting - SC Case Product ER Mapping
        for(SC_Akachat_Product_Mapping__c eachRec : SC_Akachat_Product_Mapping__c.getall().values()){
            caseProductSkillMap.put(eachRec.Name,eachRec.Skill__c);
        }
        buttonId = PLValuesMap.get('Pre_Chat_Akatech_Button_Web Experience');
        for(String productName: caseProductSkillMap.keySet())
        {
            if(selectedProduct.equalsIgnoreCase(productName)){
                String btnName = 'Pre_Chat_Akatech_Button_';
                buttonId = PLValuesMap.get(btnName+caseProductSkillMap.get(productName));
                break;
            }
            else if(selectedProduct.equalsIgnoreCase('Other')||selectedProduct.equalsIgnoreCase('Luna Control Center')||selectedProduct.equalsIgnoreCase('Control Center') || selectedProduct.equalsIgnoreCase('Coradiant Truesight Edge')){
                String AKAMUserId = loggedInUser.AKAM_User_id__c;
                Id userContactId = loggedInUser.ContactId;
                String accDiv = '';
                if(AKAMUserId != null && userContactId == null){
                    accDiv = [Select Account.Division_Formula__c from Contact where AKAM_Contact_ID__c =: AKAMUserId].Account.Division_Formula__c;
                }
                else if(userContactId != null){
                    accDiv = [Select Account.Division_Formula__c from Contact where id =: userContactId].Account.Division_Formula__c;
                }
                if(!String.isEmpty(accDiv) && accDiv.containsIgnoreCase('Media')){
                    buttonId = PLValuesMap.get('Pre_Chat_Akatech_Button_Media');  
                    break;
                }
            }
        }
        system.debug('buttonId: '+buttonId);
        return buttonId;
    }
}