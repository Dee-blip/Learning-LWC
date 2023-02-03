/*
Sales_ERSS_FormController : Controller for Sales_ERSS_NewForm component
Test class : Sales_ERSS_FormControllerTest

View/Create new RSS Forms, Publish, Update products, trasfer ownership etc

Developer Date         Comments
Saurabh   17/Jan/2020  SFDC-5820 Initial version for Lightning migration of ERSS

*/
public class Sales_ERSS_FormController {
    
    // Get Initial fields Like RecordType ID  
    @AuraEnabled
    public static String getInitFields(String rssFormId){
        Map<String,String> returnMap = new Map<String,String>();  
        List<RecordType> recordTypes = [select Id,Name from RecordType where sObjectType='RSS_Form__c'and name= 'default'];
        returnMap.put('recordtypeid',recordTypes[0].Id);
        return JSON.serialize(returnMap);
    }
    
    // Product list to be shown on New form Create/Edit
    @AuraEnabled
    public static List<Survey__c> getProductList(){
        return [select name,Id,Owner.Name,Version__c,UniqueName__c from Survey__c 
                where Id!=NULL and 
                RecordType.Name = 'RSS Template' and 
                Soft_Delete__c=false and 
                RSS_Published__c = true 
                and (NOT Name like 'HIDE%') 
                Order by Name Asc NULLS LAST limit 5000 ];
    }
    
    // Gets a list of already saved Products on a RSS Form
    @AuraEnabled
    public static List<String> getSelectedProductList(String newRSSFormId){
        
        
        Set<String> productSetIdNew = new  Set<String>();
        List<String> productIdList = new List<String>();
        for(SurveyTaker__c st : [select id,Survey__r.Name,Survey__r.UniqueName__c,OrderNumber__c,Survey__c,Survey__r.id 
                                 from SurveyTaker__c 
                                 where RSS_Form__c = :newRSSFormId  order by OrderNumber__c]){
                                     if(!productSetIdNew.contains(st.Survey__r.id)){
                                         productIdList.add(st.Survey__r.id);
                                         productSetIdNew.add(st.Survey__r.id);
                                     }
                                 }
        return productIdList;
    }
    
    // For a RSSForm and List of product ids, Creates downstream objects (aka Response) 
    // And associates with Form; Removes the old downstream objects that are deselected   
    @AuraEnabled
    public static void addProductsToRSSForm( String newRSSFormId, List<String> productListId){
        
        Set<String> oldProductSet= getProductIdsFromForm(newRSSFormId);
        
        List<String> productsToRemove = new List<String>();
        
        Set<String> newProductSet= new Set<String>();
        newProductSet.addAll(productListId);
        List<String> productsToAdd = new List<String>();
        
        for(String prod : productListId){
            if(!oldProductSet.contains(prod)){
                productsToAdd.add(prod);
            } 
        }
        
        if(oldProductSet != null && oldProductSet.size()>0){
            
            for(String oldProd : oldProductSet){
                if(!newProductSet.contains(oldProd)){
                    productsToRemove.add(oldProd);
                } 
            }
            deleteProductsFromForm(newRSSFormId,productsToRemove);
            
        }
        
        // creates Survey Taker records for Form
        if(productsToAdd!= null && productsToAdd.size()>0){
            RSSUtility.CreateRSSFromTemplate(productsToAdd, newRSSFormId);
        }
        
        
        
    }
    
    // Deletes SurveyTaker objects associated with a Form and list of products
    // Each product has a Survey Taker record , SurveytAker is Master to QuestionResponse objects
    // So no need to remove QuestionResponse objects explicitly
    private static void deleteProductsFromForm(String newRSSFormId, List<String> productsToRemove){
        if(productsToRemove.size() > 0){
            List<SurveyTaker__c> productRespDel = [select id from SurveyTaker__c where Survey__c in :productsToRemove 
                                                   and RSS_Form__c = :newRSSFormId];
            if(productRespDel.size()>0){
                delete productRespDel; 
            }
        }
    }
    
    // For a Given Form , Publishes it based on the stage of this Form
    // New aka 'Draft' : Publishes this one and makes a copy to be used later as 
    //                   Voided version for history tracking
    // Revised : Copies over all the fields and downstream objects of this Form 
    //           over to the published one and this is marked Voided
    
    @AuraEnabled
    public static String publishNewForm(String rSSFormId, String publishComments){
        
        try{
            String returnFormId = '';
            
            RSS_Form__c rSSForm = [select id,name,Version__c,Form_Stage__c,Parent_RSS_Form__c,
                                   Account__r.Name,Opportunity__r.Name,Opportunity__c
                                   from RSS_Form__c 
                                   where id=: rSSFormId];
            
            if(rSSForm.Form_Stage__c == 'Revised'){
                
                RSS_Form__c thisRSSForm = getRSSFormWithAllFields(rSSForm.Id);
                RSS_Form__c parentForm = thisRSSForm.clone();
                parentForm.Id = rSSForm.Parent_RSS_Form__c;
                parentForm.Published__c = true;
                parentForm.Published_Date__c  = Date.valueof(System.now());
                parentForm.Published_by__c  = UserInfo.getUserId();
                parentForm.Locked__c = true;   
                parentForm.Version__c  = rSSForm.Version__c;
                parentForm.Publisher_comments__c = publishComments;
                parentForm.Form_Stage__c = 'Published';
                parentForm.Parent_RSS_Form__c = null;
                update parentForm;
                //Clear existing questions on Published Form
                List<String> productsToRemove = new List<String>();
                productsToRemove.addAll(getProductIdsFromForm(parentForm.Id));
                deleteProductsFromForm( parentForm.Id,productsToRemove );
                //Add new ones from Revised
                copyRSSQuestionaire(rSSForm.Id, parentForm.Id);
                
                // Update this form to be voided and is a copy of published one
                thisRSSForm.Form_Stage__c = 'Voided';
                thisRSSForm.Locked__c = true;
                thisRSSForm.Version__c = rSSForm.Version__c;
                thisRSSForm.Published_Date__c  = Date.valueof(System.now());
                thisRSSForm.Published_by__c  = UserInfo.getUserId();
                thisRSSForm.Publisher_comments__c = publishComments;
                update thisRSSForm;
                // Copy attachments
                copyAttachments(rSSForm.Parent_RSS_Form__c, rSSFormId);
                returnFormId =  rSSForm.Parent_RSS_Form__c;
                
            }
            else{
                rSSForm.Published__c = true;
                rSSForm.Published_Date__c  = Date.valueof(System.now());
                rSSForm.Published_by__c  = UserInfo.getUserId();
                rSSForm.Locked__c = true;   
                rSSForm.Version__c  = rSSForm.Version__c + 1 ;
                rSSForm.Publisher_comments__c = publishComments;
                rSSForm.Form_Stage__c = 'Published';
                rSSForm.UniqueName__c = GuidUtil.NewGuid();
                update rSSForm; 
                // create copy of the published version to be used as Historical record for tracking
                createCopyOfRSSForm(rSSFormId);
                
                returnFormId = rSSForm.Id;
                
            }
            
            sendMailToTSPs(returnFormId,publishComments);            
            return returnFormId;
            
            
        }
        catch(Exception e){
            return e.getMessage()+' '+e.getStackTraceString(); 
        }
    }
    
    //  The form record that was created will go on to become published with multiple iterations
    //  Everytime a form is republished we first create a copy of this form to be shown as historical record
    //  Historical records are called "Voided" and are read only and are only for reference purpose 
    @AuraEnabled
    public static RSS_Form__c createCopyOfRSSForm(String rSSFormId){
        
        RSS_Form__c rSSForm = getRSSFormWithAllFields(rSSFormId);
        
        
        RSS_Form__c newForm = rSSForm.clone();
        newForm.Published__c = false;
        newForm.Locked__c = true;   
        newForm.Parent_RSS_Form__c = rSSFormId;
        newForm.Form_Stage__c = 'Voided';
        insert newForm;
        
        copyRSSQuestionaire(rSSFormId,  newForm.Id);
        
        
        
        return newForm;
    }
    // RSSQuestionaire is the Downstream Objects to Form that tracks transactional Data from
    // Product Templates and their Response.
    // This method copies over these Questionaire of this form to new one
    private static void copyRSSQuestionaire(String rSSFormId, String newFormId){
        // Clone Survey Taker
        Set<String> productSetIdNew = getProductIdsFromForm(rSSFormId);
        List<SurveyTaker__c> existingFormSTs = new List<SurveyTaker__c>();
        Map<Id,SurveyTaker__c> surveyToTakerMap = new Map<Id,SurveyTaker__c>();
        for(SurveyTaker__c  formST : [select id,name,OrderNumber__c,Survey__c,Survey__r.Id,Case__c, Contact__c,
                                      PM_Approved__c ,RSS_Form__c ,Survey_Taken_Auto_Id__c, Taken__c 
                                      from SurveyTaker__c 
                                      where RSS_Form__c = :rSSFormId])
        {
            existingFormSTs.add(formST);
            
            SurveyTaker__c newST = formST.clone();
            newST.RSS_Form__c = newFormId; 
            surveyToTakerMap.put(formST.Survey__r.id,newST);
        }
        
        insert surveyToTakerMap.values();
        
        // Clone Questionaire Response
        List<SurveyQuestionResponse__c> rssResponsesToCLone = new List<SurveyQuestionResponse__c>();
        for( SurveyQuestionResponse__c tempResponse : [select Id,Question__c, Response__c, SurveyTaker__c, 
                                                       SurveyTaker__r.Survey__r.Id, Survey_Question__c,Survey_Question_Response_Auto_ID__c,
                                                       Product_Approval__c, Lead__c, of_Time_Question_was_Responded_to__c 
                                                       
                                                       from SurveyQuestionResponse__c 
                                                       where SurveyTaker__c in :existingFormSTs ]){
                                                           SurveyQuestionResponse__c newResp =   tempResponse.clone();
                                                           newResp.SurveyTaker__c =  surveyToTakerMap.get(tempResponse.SurveyTaker__r.Survey__r.Id).Id; 
                                                           rssResponsesToCLone.add(newResp);
                                                       }
        insert rssResponsesToCLone;
    }
    
    // Handy method for Cloning related RSS Form fields
    private static RSS_Form__c getRSSFormWithAllFields(String rSSFormId){
        
        return [select id,name,Account__c,AEName__c,Parent_RSS_Form__c,
                Commitment_Type_Text__c,Commitment_Type__c,
                Commitment_Type_Internal__c ,CurrencyIsoCode,Customer_Business_Objective_text__c,
                Customer_Business_Objective__c,Customer_Risk__c,Ownership_comments__c,Form_Stage__c,
                Customer_Risk_text__c,DigitalProperty__c, Type_of_Integration_text__c ,Type_of_Integration__c ,
                Opportunity__c, OwnerId,Partner_Involved__c, Partner_Name__c, Partner__c, Products__c ,
                RecordTypeId ,TSP__c,Published_Date__c ,Published_by__c,contacts_json__c,
                Published__c,Version__c,Locked__c,Publisher_comments__c,LOE_Text__c,LOE__c
                from RSS_Form__c where id=: rSSFormId];
        
    }
    
    // Creates a new "Revised' form out of a Published form
    // This Revised form tracks all changes made to a Published form
    // A Published form can only have one Revised form at a time
    @AuraEnabled    
    public static String createRevisedForm(String rSSFormId){
        for(RSS_Form__c revisedform : [select id,name from RSS_Form__c 
                                       where Parent_RSS_Form__c=:rSSFormId and
                                       form_stage__c='Revised']){
                                           return revisedform.id;
                                       } 

        RSS_Form__c revisedForm = createCopyOfRSSForm(rSSFormId);
        
        revisedForm.Locked__c = false;
        revisedForm.Version__c = revisedForm.Version__c+1;
        revisedForm.Form_Stage__C = 'Revised';
        update revisedForm;
        copyAttachments(revisedForm.id,rSSFormId);
        return revisedForm.id;
    }
    
    // List of All RSSForms that are tied to this Published form
    // Removing the first one : As the first is the copy of latest version 
    // itself and hence is not 'History'
    @AuraEnabled
    public static List<RSS_Form__c> getPreviousVersionsOfRSSForm(String rSSFormId){
        
        List<RSS_Form__c> listOfForms =  new List<RSS_Form__c>(); 
        Boolean first = true;
        for(RSS_Form__c f : [select id,name,Version__c,CreatedDate,OwnerId,Owner.Name,
                             Published_by__c,Published_by__r.Name,Parent_RSS_Form__r.Version__c,
                             Publisher_comments__c
                             from RSS_Form__c 
                             where Parent_RSS_Form__c=: rSSFormId and 
                             id != :rSSFormId  and 
                             
                             form_stage__c = 'Voided' order by Version__c desc]){
                                 if( !first){
                                     listOfForms.add(f);
                                 }
                                 first = false;
                             }
        return listOfForms;
    }
    
    // Gets all Templates, Questions and Response of a RSS Form
    @AuraEnabled
    public static List<SurveyQuestionResponse__c> getRSSQuestionaire(String rSSFormId){
        
        List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__r.UniqueName__c,OrderNumber__c,Survey__c,Survey__r.id 
                                      from SurveyTaker__c 
                                      where RSS_Form__c = :rSSFormId  order by OrderNumber__c];
        
        Set<String> productSetIdNew = new  Set<String>();
        for(SurveyTaker__c st : forms){
            productSetIdNew.add(st.Survey__r.id);
        }
        
        List<Survey_Question_Group__c> questionGroups = [select name, Akam_Survey_Question_ID__c,Survey__c, Order_Number__c 
                                                         from Survey_Question_Group__c 
                                                         where Survey__c in :productSetIdNew order by Order_Number__c];
        
        List<SurveyQuestionResponse__c> tempResponses = [select Id,Question__c, Response__c, SurveyTaker__c, 
                                                         SurveyTaker__r.Survey__r.Name,SurveyTaker__r.Survey__r.RSS_Published__c, Survey_Question__c, 
                                                         Survey_Question__r.Question__c, Survey_Question__r.Required__c, 
                                                         Survey_Question__r.OrderNumber__c,Survey_Question__r.Type__c, 
                                                         Survey_Question__r.Choices__c,Survey_Question__r.QuestionDescription__c,
                                                         Survey_Question__r.Survey_Question_Group__c,Survey_Question__r.Survey_Question_Group__r.Name,
                                                         Survey_Question__r.UniqueName__c,
                                                         Survey_Question__r.Category__c  
                                                         from SurveyQuestionResponse__c 
                                                         where SurveyTaker__c in :forms and 
                                                         Survey_Question__r.Survey_Question_Group__c in :questionGroups 
                                                         ORDER BY Survey_Question__r.Survey_Question_Group__r.Order_Number__c, 
                                                         Survey_Question__r.OrderNumber__c];
        
        return tempResponses;
    }
    
    @AuraEnabled
    public static void saveRSSQuestionaire(List<SurveyQuestionResponse__c> response){
        update response;
    }
    
    
    private static Set<String> getProductIdsFromForm(String rSSFormId){
        List<SurveyTaker__c> forms = [select id,Survey__r.Name,Survey__r.UniqueName__c,
                                      OrderNumber__c,Survey__c,Survey__r.id 
                                      from SurveyTaker__c 
                                      where RSS_Form__c = :rSSFormId  order by OrderNumber__c];
        Set<String> productSetIdNew = new  Set<String>();
        for(SurveyTaker__c st : forms){
            productSetIdNew.add(st.Survey__r.id);
        }
        
        return productSetIdNew;
    }
    
    // This method is called by UI to fetch various Form fields that are needed to be shown or consumed
    @AuraEnabled
    public static String getOpportunityFieldsFromForm(String formId)
    {
        RSS_Form__c rSSForm = [select id,Opportunity__c, Published__c, contacts_json__c,
                               Version__c,Form_Stage__C,Owner.Title
                               from RSS_Form__c 
                               where id=: formId];
        Map<String, Object> m = new Map<String, Object>();
        
        if( rSSForm.Opportunity__c != null){
            m = (Map<String, Object>)JSON.deserializeUntyped(getOpportunityFields(rSSForm.Opportunity__c ));
        }
        m.put('published',rSSForm.Published__c );
        m.put('version',rSSForm.Version__c );
        m.put('stage',rSSForm.Form_Stage__C );
        m.put('ownerTitle',rSSForm.Owner.Title );
        
        if(rSSForm.published__c){
            m.put('revisePermission',true);
            for(RSS_Form__c revisedform : [select id,name from RSS_Form__c 
                                           where Parent_RSS_Form__c=:formId and
                                           form_stage__c='Revised']){
                                               m.put('revisePermission',false);
                                               m.put('reviseFormId',String.valueof(revisedform.Id));
                                               m.put('reviseFormName',revisedform.name);
                                               
                                               
                                               break;
                                           } 
        }       
        return JSON.serialize(m);
        
    }
    
    // This method is called on UI to show various fields when an Opportunity is selected
    // TSP is Opportunity Team Member, AE is Account Team Member and various Partner related fields
    @AuraEnabled
    public static String getOpportunityFields(String oppId)
    {
        Map<String,String> fieldMap = new Map<String,String>();
        //Query TSP(s) on select Opportunity
        Opportunity opp = [select Id,Name,Deal_Type__c,Partner_Involved__c,Partner_Involved__r.Id,
                           Partner_Involved__r.Name, Account.Id,Account.Name, 
                           Account.OwnerId,Account.Owner.Name,
                           (select User.Name,User.Email from OpportunityTeamMembers 
                            where TeamMemberRole = 'Technical Sales - Primary')
                           from Opportunity where Id = :oppId];
        fieldMap.put('accountId',opp.Account.Id);
        fieldMap.put('accountName',opp.Account.Name);
        fieldMap.put('ae',opp.Account.OwnerId);
        fieldMap.put('aeName',opp.Account.Owner.Name);
        
        if (opp.OpportunityTeamMembers != NULL)
        {
            // Populate TSP 
            if(opp.OpportunityTeamMembers.size()> 0){
                
                OpportunityTeamMember oppTeam =  opp.OpportunityTeamMembers.get(0);  
                fieldMap.put('tsp',oppTeam.UserId);
                fieldMap.put('tspName',oppTeam.User.Name);
            }
        }
        
        if(opp.Deal_Type__c == 'Indirect')
        {
            fieldMap.put('indirect','true');
            fieldMap.put('partnerInvolved','true');
            fieldMap.put('partnerId',opp.Partner_Involved__r.Id);
            fieldMap.put('partnerName',opp.Partner_Involved__r.Name);
            
        }
        
        return JSON.serialize(fieldMap);
    }
    
    
    
    @AuraEnabled    
    public static Map<String,Boolean> getFormWriteAccess(String rSSFormId){
        Map<String,Boolean> userPermissionMap =  formWriteAccessNew(UserInfo.getUserId());
        if(rSSFormId != null){
            RSS_Form__c form = [select id,ownerid,published__c from RSS_Form__c where id=:rSSFormId];
            Map<String,Boolean> ownerPermissionMap = formWriteAccessNew(form.ownerid);
            if((userPermissionMap.get('Pre-sales')== true && ownerPermissionMap.get('Pre-sales')== true) ||
               (userPermissionMap.get('Post-sales')== true && ownerPermissionMap.get('Post-sales')== true)){
                   userPermissionMap.put('profileAccess',true);
               }
            else{
                userPermissionMap.put('profileAccess',false);
            }
            
            
        }
        else{
            userPermissionMap.put('profileAccess',true);
        }
        return userPermissionMap;
        
    }
    
    // Changes Owner of this RSS Form to a new One
    // If New owner does not have create/read/edit access then an error is displayed on UI
    @AuraEnabled    
    public static void changeOwnerOfRSSForm(String rSSFormId, String newOwnerId, String ownershipComments){
        RSS_Form__c form = [select id,name,owner.name,Owner.Email from RSS_Form__c where Id=:rSSFormId];
        String oldOwnerName = form.owner.name;
        String oldOwnerEmail = form.Owner.Email;
        form.OwnerId = newOwnerId;
        form.Ownership_comments__c = ownershipComments;
        update form;
        sendEmailOnTransferOfOwnerShip(form,oldOwnerName,oldOwnerEmail );
    }
    
    // On RSS Form Contact JSOn tracks all contacts added 
    @AuraEnabled    
    public static void updateContactJson(String formId, String json){
        RSS_Form__c rSSForm = [select id, contacts_json__c    from RSS_Form__c where id=: formId];
        rSSForm.contacts_json__c = json;
        update rSSForm;
    }
    
    // To be shown on an Opportunity Pages
    // Displays only Publihsed forms tagged to this Opportunity
    @AuraEnabled    
    public static List<RSS_Form__c> getPublishedFormsUnderOpportunity(String oppId){
        
        return [select id,Version__c,name,Published__c,Published_by__c,Published_by__r.Name,
                Published_Date__c from RSS_Form__c where Opportunity__c=: oppId and Published__c = true];   
    }
    
    // Copy pasted old method from RSSutility and modified slightly(to fix a bug) 
    public static Map<String,Boolean> formWriteAccessNew(string userId)
    {
        //Changes by shprasan: Creating the map userPermissionMap and initialising the values
        Map<String,Boolean> userPermissionMap = new Map<String,Boolean>();
        userPermissionMap.put('Pre-sales',false);
        userPermissionMap.put('Post-sales',false);
        userPermissionMap.put('WriteAccessOfUser',false);
        userPermissionMap.put('SuperUser',false);
        userPermissionMap.put('CCare',false);
        Set<string> Psets = new Set<String>();
        Set<string> ProfilesPostSales = new Set<string>();
        Set<string> profilesReadOnly = new Set<string>();
        //Changes by Sharath for CR 3730732 
        //Creating the temp variables:
        List<String> tempListPreSales = new List<String>();
        List<String> tempListPostSales = new List<String>();
        List<String> tempListReadOnly = new List<String>();
        //Query the ERSS_Profile_Access__mdt custom metadata object. Fetch all the records
        List<ERSS_Profile_Access__mdt> profileAccessMetaData = new List<ERSS_Profile_Access__mdt>();
        profileAccessMetaData = [select Post_Sales__c,Pre_Sales__c,Read_Only__c from ERSS_Profile_Access__mdt];        
        try{
            eRSS__c objApp = eRSS__c.getInstance('eRSS');
            
            //Get the value from the custom setting. populate the temp lists.   
            tempListPreSales = String.valueOf(objApp.Permission_Set_Form__c).split(',',0);
            tempListPostSales = String.valueOf(objApp.Post_Sales__c).split(',',0);
            tempListReadOnly = String.valueOf(objApp.Read_Only__c).split(',',0);
            // Loop through the custom metadata records: populate the temp lists 
            for(ERSS_Profile_Access__mdt metaDataRec: profileAccessMetaData){
                if(metaDataRec.Pre_Sales__c != null && metaDataRec.Pre_Sales__c.length() > 14){
                    tempListPreSales.addAll(metaDataRec.Pre_Sales__c.split(',',0));
                }   
                if(metaDataRec.Post_Sales__c != null && metaDataRec.Post_Sales__c.length() > 14){
                    tempListPostSales.addAll(metaDataRec.Post_Sales__c.split(',',0));
                }   
                if(metaDataRec.Read_Only__c != null && metaDataRec.Read_Only__c.length() > 14){
                    tempListReadOnly.addAll(metaDataRec.Read_Only__c.split(',',0));
                }   
            }
            //trim the values in the list and add to the set
            for(String a:tempListPreSales){
                Psets.add(a.trim());
            }
            
            for(String a:tempListPostSales){
                ProfilesPostSales.add(a.trim());
            }
            
            for(String a:tempListReadOnly){
                profilesReadOnly.add(a.trim());
            }
        }
        catch(Exception e){
        }
        
        for(PermissionSetAssignment pas : [SELECT PermissionSet.label 
                                           FROM PermissionSetAssignment 
                                           where AssigneeId = :userId]){
                                               if(Psets.contains(pas.PermissionSet.label) || ProfilesPostSales.contains(pas.PermissionSet.label)){
                                                   
                                                   if (pas.PermissionSet.label == 'eRSS - System Administrator'){
                                                       userPermissionMap.put('SuperUser',true);
                                                       userPermissionMap.put('WriteAccessOfUser',true);                         
                                                   }
                                                   
                                                   return userPermissionMap;
                                               }
                                           }
        string userIdCheck = userId;
        //Changing the if condition: Profiles dont matter
        for(User objUser: [SELECT ProfileID,Profile.Name, ERSS_Service_Architect__c, ERSS_Super_User__c 
                           FROM User 
                           WHERE Id = :userIdCheck]){
                               String id = objUser.ProfileID;
                               if(objUser.ERSS_Super_User__c){
                                   //Changes by shprasan: Changing the return value
                                   
                                   userPermissionMap.put('SuperUser',true);
                                   userPermissionMap.put('WriteAccessOfUser',true);                         
                                   return userPermissionMap;
                               }
                               else if (Psets.contains(objUser.ProfileID) || Psets.contains(id.left(15))){                    
                                   userPermissionMap.put('Pre-sales',true);
                                   userPermissionMap.put('WriteAccessOfUser',true);                         
                                   return userPermissionMap;                
                               }
                               else if (ProfilesPostSales.contains(objUser.ProfileID) || ProfilesPostSales.contains(id.left(15))){
                                   userPermissionMap.put('Post-sales',true);
                                   userPermissionMap.put('WriteAccessOfUser',true);                         
                                   return userPermissionMap;                   
                               }
                               else if (profilesReadOnly.contains(objUser.ProfileID) || profilesReadOnly.contains(id.left(15))){                    
                                   userPermissionMap.put('CCare',true);
                                   return userPermissionMap;                                    
                               }
                           }
        
        return userPermissionMap;
    }  
    
    // For old(unpublished) Product templates on the form : This methods removes it 
    // and replaces with the newer published version based on Unique name
    @AuraEnabled
    public static void updateProductTemplates(String rssFormId){
        
        Map<String,String> mapQuestionCurrentResponse = new Map<String,String>();
        List<String> newPublishedTemplates = new List<String>();
        
        List<String> invalidSurveyTakerIds = new List<String>();
        List<String> invalidTemplateIds = new List<String>();
        List<String> invalidTemplateUniqueIds = new List<String>();
        
        for(SurveyTaker__c st : [select id, Survey__r.Name,Survey__r.ID,Survey__r.RSS_Published__c,Survey__c,
                                 Survey__r.UniqueName__c from SurveyTaker__c where RSS_Form__c =:rssFormId])
        {
            if(!st.Survey__r.RSS_Published__c)
            {
                
                invalidTemplateIds.add(st.Survey__r.ID);
                invalidSurveyTakerIds.add(st.id);
                invalidTemplateUniqueIds.add(st.Survey__r.UniqueName__c);   
            }
        }
        for(Survey__c ss : [select id from Survey__c 
                            where 
                            UniqueName__c in :invalidTemplateUniqueIds and 
                            RSS_Published__c = true and 
                            Soft_Delete__c=false 
                            and (NOT Name like 'HIDE%') ]){
                                newPublishedTemplates.add(ss.id);
                            }
        List<SurveyQuestionResponse__c > responses = getRSSQuestionaire(rssFormId);
        
        // Make a copy of responses on old template
        // We use it to populate response on same question on new Template response
        for(SurveyQuestionResponse__c sqr:responses){
            mapQuestionCurrentResponse.put(sqr.Survey_Question__r.UniqueName__c,sqr.Response__c);
        }
        
        
        // Delete invalid Survey Taker objects : This is master detail so related
        // SurveyQuestionResponse__c is automatically deleted
        delete [select id from SurveyTaker__c where id in :invalidSurveyTakerIds];
        
        RSSUtility.CreateRSSFromTemplate(newPublishedTemplates,rssFormId);
        
        
        responses = getRSSQuestionaire(rssFormId);
        // Populate response on same question on new Template response
        for(SurveyQuestionResponse__c sqr:responses){
            sqr.Response__c = mapQuestionCurrentResponse.get(sqr.Survey_Question__r.UniqueName__c);
        }
        update responses;
        
    }
    
    private static void sendEmailOnTransferOfOwnerShip(RSS_Form__c form, String oldOwnerName, String oldOwnerEmail){
        RSS_Form__c rSSForm = [select Id,Name,Owner.name,Account__r.Name,Opportunity__r.Name,
                               Ownership_comments__c,Owner.Email
                               from RSS_Form__c where Id=:form.id];
        String fromAddress = eRSS__c.getInstance('eRSS').From_Address__c;
        String orgWideEmailId;
        for(OrgWideEmailAddress owe : [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1]){
            orgWideEmailId = owe.Id;
        }
        
        String subject = 'eRSS Form Ownership change || ' + rSSForm.Name;
        String bodySalutation = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + rSSForm.Owner.Name;
        
        String body = '<br /><br />Please be advised that you are now assigned as the Owner of eRSS Form to perform further actions.<br /><br />'
            + '<b>Form Name:</b>&nbsp;&nbsp;&nbsp;<a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/cmp/c__Sales_ERSS_NewForm?c__id=' + rSSForm.id+'"> '+rSSForm.Name + ' </a><br />'
            + '<b>Previously Owned by:</b>&nbsp;&nbsp;&nbsp;' +oldOwnerName + '<br />'
            + '<b>Transfer Comments:</b>&nbsp;&nbsp;&nbsp;<i>' +rSSForm.Ownership_comments__c + '</i><br />'
            + '<b>Account Name:</b>&nbsp;&nbsp;&nbsp;' + rSSForm.Account__r.Name + '<br />'
            + '<b>Opportunity Name:</b>&nbsp;&nbsp;&nbsp;' + rSSForm.Opportunity__r.Name + '<br /><br />';
        
        
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();  
        email.setToAddresses(new List<String>{ rSSForm.Owner.Email}); 
        email.setCCAddresses(new List<String>{ oldOwnerEmail}); 
        
        if(orgWideEmailId != null && orgWideEmailId != ''){
            email.setOrgWideEmailAddressId(orgWideEmailId);
        }
        email.setSubject(subject);
        email.setHTMLBody(bodySalutation +body  + '</body></html>');
        
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email},false);
    }
    
    private static void sendMailToTSPs(String rSSFormId, String publishComments){
        RSS_Form__c rSSForm = [select id,name,Version__c,Form_Stage__c,Parent_RSS_Form__c,
                               Account__r.Name,Opportunity__r.Name,Opportunity__c
                               from RSS_Form__c 
                               where id=: rSSFormId];
        String fromAddress = eRSS__c.getInstance('eRSS').From_Address__c;
        
        String orgWideEmailId;
        for(OrgWideEmailAddress owe : [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1]){
            orgWideEmailId = owe.Id;
        }
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        String subject = 'eRSS Form Published || ' + rSSForm.Name;
        String bodySalutation;
        publishComments=(publishComments==null?'':publishComments);
        String body = '<br /><br />An eRSS Form has just been published with the below details:<br /><br />'
            + '<b>Form Name:</b>&nbsp;&nbsp;&nbsp;<a target="__blank" href = "' + URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/cmp/c__Sales_ERSS_NewForm?c__id=' + rSSForm.id+'"> '+rSSForm.Name + ' </a><br />'
            + '<b>Publisher Comments:</b>&nbsp;&nbsp;&nbsp;<i>' + publishComments + '</i><br />'
            + '<b>Account Name:</b>&nbsp;&nbsp;&nbsp;' + rSSForm.Account__r.Name + '<br />'
            + '<b>Opportunity Name:</b>&nbsp;&nbsp;&nbsp;' + rSSForm.Opportunity__r.Name + '<br /><br />';
        String changes = '';
        if(rssForm.Version__c >1){
            changes = getFormDiffFromPreviousVersionForEmail(rSSForm.id, rssForm.Version__c-1);
            
        }
        List<Opportunity> oppIdTeamMembers = [select Id, Account.Id,Account.Name, 
                                              (select User.Name,User.Email from OpportunityTeamMembers 
                                               where TeamMemberRole = 'Technical Sales - Primary')
                                              from Opportunity where Id = :rSSForm.Opportunity__c];
        if (oppIdTeamMembers.size() > 0){
            
            Opportunity opp = oppIdTeamMembers.get(0);
            if (opp.OpportunityTeamMembers != NULL){
                for (OpportunityTeamMember oppTeamMember : opp.OpportunityTeamMembers){  
                    bodySalutation = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + oppTeamMember.User.Name;
                    email = new Messaging.SingleEmailMessage();  
                    email.setToAddresses(new List<String>{ oppTeamMember.User.Email});   
                    if(orgWideEmailId != null && orgWideEmailId != ''){
                        email.setOrgWideEmailAddressId(orgWideEmailId);
                    }
                    
                    email.setSubject(subject);
                    email.setHTMLBody(bodySalutation + body + changes + '</body></html>');
                    mailsToBeSent.add(email);
                }
                
            }
            if(mailsToBeSent != null && mailsToBeSent.size()>0){
                Messaging.sendEmail(mailsToBeSent,false);
            }
            
        }
    }
    
    public static String getFormDiffFromPreviousVersionForEmail(String formId, Decimal oldVersion){
        try{
            RSS_Form__c form = [select Id from Rss_Form__c where Parent_RSS_Form__c = :formId and Version__C = :oldVersion];
            return '<strong>Form changes</strong><br/><br/>'+getFormFieldsDiff(formId,form.id)+'<br/><strong>Product changes</strong><br/>'+getFormTemplateFieldsDiff(formId,form.id);
        }
        catch(Exception ex){
            return '';
        }
        
    }
    
    @AuraEnabled
    public static String getFormDiffFromPreviousVersion(String formId, Decimal oldVersion){
        Map<String,String> returnValue = new Map<String,String>();
        try{
            RSS_Form__c form;
            RSS_Form__c thisForm = [select Id,published__c,Parent_RSS_Form__c,form_stage__c,version__c from Rss_Form__c where id = :formId];
            if(thisForm.form_stage__c == 'Published'){
                for(RSS_Form__c f: [select Id from Rss_Form__c where Parent_RSS_Form__c = :formId and Version__C = :oldVersion]){
                    form = f;
                }
            }
            else if(thisForm.form_stage__c == 'Voided'){
                for(RSS_Form__c f: [select Id from Rss_Form__c where Parent_RSS_Form__c = :thisForm.Parent_RSS_Form__c and Version__C = :oldVersion]){
                    form = f;
                }
            }
            else{
                JSON.serialize(returnValue);
            }
            if(form != null){
                returnValue.put('form',getFormFieldsDiff(formId,form.id));
                returnValue.put('products',getFormTemplateFieldsDiff(formId,form.id));
            }
            else{
                returnValue.put('error','Error occured for version='+oldVersion+' : Not sufficient data present in system');
            }
        }
        catch(Exception ex){
            
            returnValue.put('error','Error occured for version= '+oldVersion+' : '+ex.getMessage()+' '+ex.getStackTraceString());
        }
        return JSON.serialize(returnValue);
    }
    
    private static RSS_Form__c getRSSFormDiffFields(String rSSFormId){
        
        return [select id,name,Account__r.Name,AEName__r.Name,Parent_RSS_Form__c,
                Commitment_Type_Text__c,Customer_Business_Objective_text__c,
                Ownership_comments__c,Form_Stage__c,Customer_Risk_text__c,
                Type_of_Integration_text__c , Opportunity__r.Name, OwnerId, Partner_Name__r.Name, 
                Products__c ,TSP__r.Name, Published_Date__c ,Published_by__c,contacts_json__c,
                Published__c,Version__c,Publisher_comments__c,LOE_Text__c
                from RSS_Form__c where id=: rSSFormId];
        
    }
    
    private static String getFormFieldsDiff(String rSSFormIdNew, String rSSFormIdOld){
        Boolean changesPresent = false;
        String changes = '';
        List <String> fields = new List <String> {'Name','Version__c','Account__r.Name','Opportunity__r.Name','Partner_Name__r.Name',
            'AEName__r.Name','TSP__r.Name',
            'Contacts_JSON__c',
            'Commitment_Type_Text__c','Type_of_Integration_text__c',                          
            'Customer_Business_Objective_Text__c','Customer_Risk_Text__c',
            'LOE_text__C'
            };
                Map <String,String> FieldAPiToLabel = new Map <String,String> ();
        FieldAPiToLabel.put('Name','Form Name');
        FieldAPiToLabel.put('Version__c','Version');
        FieldAPiToLabel.put('Account__r.Name','Account');
        FieldAPiToLabel.put('Opportunity__r.Name','Opportunity');  
        FieldAPiToLabel.put('Partner_Name__r.Name','Partner Organisation Name');
        FieldAPiToLabel.put('Contacts_JSON__c','Customer Contacts');
        FieldAPiToLabel.put('Commitment_Type_Text__c','Commitment Type');
        FieldAPiToLabel.put('Type_of_Integration_text__c','Integration Management Type');
        FieldAPiToLabel.put('AEName__r.Name','AE Name');
        FieldAPiToLabel.put('TSP__r.Name','Technical Sales Primary Name');
        
        FieldAPiToLabel.put('Customer_Business_Objective_Text__c','Customer Business Objective');
        FieldAPiToLabel.put('Customer_Risk_Text__c','Customer Risk');
        
        FieldAPiToLabel.put('LOE_text__C','Level Of Effort');
        
        RSS_Form__c rSSFormNew = getRSSFormDiffFields(rSSFormIdNew);
        RSS_Form__c rSSFormOld = getRSSFormDiffFields(rSSFormIdOld);
        changes = '<table><tr><th> Field </th><th> Old value </th><th>Updated value</th></tr>';
        for (String field : fields){
            
            
            Object oldValue ;
            Object newValue;
            if(field.contains('__r')){
                if(field.split('\\.').size()>1){
                    String objectName = field.split('\\.')[0];
                    String fieldName = field.split('\\.')[1];
                    if(rSSFormOld.getSObject(objectName) != null){
                        oldValue = rSSFormOld.getSObject(objectName).get(fieldName);  
                    }
                    if(rSSFormNew.getSObject(objectName) != null){
                        newValue = rSSFormNew.getSObject(objectName).get(fieldName);  
                    }  
                }
                
            }
            else{
                oldValue = rSSFormOld.get(field);
                newValue = rSSFormNew.get(field);
            }
            
            if(newValue != oldValue){
                changes = changes+'<tr><td>'+ fieldAPiToLabel.get(field)+' </td> '+
                    '<td style="background-color:#ffcccb;"><strike>'+
                    oldValue+'</strike></td><td style="background-color:#d2f8d2;">'+
                    newValue+'</td></tr>';
                changesPresent = true;
            }
            
        }
        changes = changes+'</table>';
        
        
        return changesPresent?changes:'No Changes';
    }
    private static String getFormTemplateFieldsDiff(String rSSFormIdNew, String rSSFormIdOld){
        
        String changesComparison = '';
        List<SurveyTaker__c> oldSurveyTakers = [select id,Survey__c,Survey__r.Name,Survey__r.UniqueName__c,Survey__r.Version__c from SurveyTaker__c where RSS_Form__c =:rSSFormIdOld order by Survey__r.Name];
        List<SurveyTaker__c> newSurveyTakers = [select id,Survey__c,Survey__r.Name,Survey__r.UniqueName__c,Survey__r.Version__c from SurveyTaker__c where RSS_Form__c =:rSSFormIdNew order by Survey__r.Name];
        List<id> toCompare = new List<id>();
        Boolean notThere = true;
        String oldResponse = '';
        String newResponse = '';
        //Determining which templates were removed or added. 
        //We have to compare only those templates which are there in both 
        //the form versions and the which have been unchanged(Not the answers but the template version)
        for (SurveyTaker__c surveyTaker : oldSurveyTakers){   
            notThere = true;
            for(SurveyTaker__c newSurveyTaker: newSurveyTakers){
                if (newSurveyTaker.Survey__r.Name == surveyTaker.Survey__r.Name){
                    if (newSurveyTaker.Survey__r.Version__c != surveyTaker.Survey__r.Version__c){
                        changesComparison += '\nThe version of the Template ' +  surveyTaker.Survey__r.Name + ' has changed';          
                    }
                    else{
                        toCompare.add(surveyTaker.id);
                        toCompare.add(newSurveyTaker.id);
                    }
                    notThere = false;
                } 
            }
            if(notThere){
                changesComparison += '<br />The Product ' + surveyTaker.Survey__r.Name + ' has been removed';
            }
        }
        //The list toCompare stores the templates that have to be compared
        for (SurveyTaker__c newSurveyTaker: newSurveyTakers){   
            notThere = true;
            for(SurveyTaker__c surveyTaker : oldSurveyTakers){
                if (newSurveyTaker.Survey__r.Name == surveyTaker.Survey__r.Name){
                    notThere = false;
                } 
            }
            if(NotThere){
                changesComparison += '<br />The Product ' + newSurveyTaker.Survey__r.Name + ' has been added';
            }
        }
        if(toCompare.size() > 0){
            //Creating a map of Template Name to a Map of Questions to the answers to 
            //those questions in the two forms
            //every record in the map has a template name as the key. 
            //The value is a map of question to the answer in the previous 
            //version of the form and the answer in the current version of the form
            Map <String,Map<String,List<String>>> surveyToQuestionToResponses = new Map <String,Map<String,List<String>>>();
            List <SurveyQuestionResponse__c> questionResponses = [SELECT Id, Response__c, SurveyTaker__c, 
                                                                  SurveyTaker__r.Survey__r.Name,SurveyTaker__r.RSS_Form__c,
                                                                  SurveyTaker__r.RSS_Form__r.Submit_Version__c,
                                                                  SurveyTaker__r.RSS_Form__r.Version__c,
                                                                  Survey_Question__r.UniqueName__c,
                                                                  Survey_Question__r.Question__c,
                                                                  Survey_Question__r.OrderNumber__c,
                                                                  Survey_Question__r.Survey_Question_Group__r.Order_Number__c 
                                                                  FROM SurveyQuestionResponse__c 
                                                                  WHERE SurveyTaker__c IN :toCompare 
                                                                  order by SurveyTaker__r.RSS_Form__r.Version__c, 
                                                                  SurveyTaker__r.RSS_Form__r.Submit_Version__c,
                                                                  Survey_Question__r.Survey_Question_Group__r.Order_Number__c, 
                                                                  Survey_Question__r.OrderNumber__c];
            //Doing a order by the Form ID: The answers in the previous version come first; 
            //Order by Question group: The sections in the templates are arranged in ascending order; 
            //Order by Question order: The questions in a section are arranged in ascending order
            String questionChanges = '';
            for (SurveyQuestionResponse__c questionResponse : questionResponses){
                if( !surveyToQuestionToResponses.containsKey(questionResponse.SurveyTaker__r.Survey__r.Name)){
                    surveyToQuestionToResponses.put(questionResponse.SurveyTaker__r.Survey__r.Name, new Map<String,List<String>> ());
                }
                if(! surveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name).containsKey(questionResponse.Survey_Question__r.Question__c)){
                    surveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name).put(questionResponse.Survey_Question__r.Question__c,new List <String>());   
                }
                surveyToQuestionToResponses.get(questionResponse.SurveyTaker__r.Survey__r.Name)
                    .get(questionResponse.Survey_Question__r.Question__c)
                    .add(questionResponse.Response__c);
            }
            for (String surveyName: surveyToQuestionToResponses.keySet()){                    
                for (String questionName : surveyToQuestionToResponses.get(surveyName).keySet()){
                    if(surveyToQuestionToResponses.get(surveyName).get(questionName).get(0) != surveyToQuestionToResponses.get(surveyName).get(questionName).get(1)){
                        oldResponse = surveyToQuestionToResponses.get(surveyName).get(questionName).get(0) == null ? '' : surveyToQuestionToResponses.get(surveyName).get(questionName).get(0);
                        newResponse = surveyToQuestionToResponses.get(surveyName).get(questionName).get(1) == null ? '' : surveyToQuestionToResponses.get(surveyName).get(questionName).get(1);
                        questionChanges += '<tr><td>' + QuestionName + '</td><td style="background-color:#ffcccb;"><strike>' + OldResponse + '</strike></td><td style="background-color:#d2f8d2;">' + NewResponse + '</td></tr>';
                    }
                }
                if (questionChanges != ''){ 
                    changesComparison += '<br /><b>' + surveyName + '</b>';
                    changesComparison += '<br /><table><tr><th> Question </th><th> Old Response </th><th>Updated Response</th></tr>' ;
                    changesComparison += questionChanges;
                    changesComparison += '</table>';
                    questionChanges = '';
                }
            }
        }
        return changesComparison==''?'No Changes':changesComparison;
    }
    
    
    @AuraEnabled
    public static List<ContentDocumentLink> getAttachments(String formId){
        
        
        return  [SELECT id,ContentDocument.Title,ContentDocument.FileType,ContentDocument.FileExtension,
                 ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate, 
                 ContentDocument.CreatedById ,ContentDocument.CreatedBy.Name
                 FROM ContentDocumentLink WHERE LinkedEntityID =:formId];
        
        
        
    }
    
    
    private static void copyAttachments(String newFormId, String oldFormId){
        Set<String> contentIdsExistingonNew = new Set<String>();
        for(ContentDocumentLink doc :   [SELECT id,ContentDocument.Id,ContentDocument.Title,ContentDocument.FileType,ContentDocument.FileExtension,
                                         ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate, 
                                         ContentDocument.CreatedById ,ContentDocument.CreatedBy.Name
                                         FROM ContentDocumentLink WHERE LinkedEntityID =:newFormId]){
                                          contentIdsExistingonNew.add(doc.ContentDocument.id);   
                                         }
        List<ContentDocumentLink> newList = new List<ContentDocumentLink>();
        
        for(ContentDocumentLink doc :   [SELECT id,ContentDocument.Id,ContentDocument.Title,ContentDocument.FileType,ContentDocument.FileExtension,
                                         ContentDocument.LatestPublishedVersionId, ContentDocument.CreatedDate, 
                                         ContentDocument.CreatedById ,ContentDocument.CreatedBy.Name
                                         FROM ContentDocumentLink WHERE LinkedEntityID =:oldFormId]){
                                             if(!contentIdsExistingonNew.contains(doc.ContentDocument.id)){
                                              ContentDocumentLink newDoc = doc.clone();
                                              newDoc.LinkedEntityID = newFormId;
                                              newList.add(newDoc);
                                             }
                                         }
        if(newList.size()>0){
            insert newList;
        }
        
        
    }
    
}