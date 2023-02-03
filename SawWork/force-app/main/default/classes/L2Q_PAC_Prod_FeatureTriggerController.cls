/*
Author          : Himanshu, Vishnu, Sujay
Description     : Helper Class for Product & Feature Trigger Logic
Called From     : PAC Product Trigger, Feature Trigger
Test Class      : L2Q_LOE_Utility_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
12 Jun 2020         Himanshu               ESESP-5155            Initial Version 
------------------------------------------------------------------------------------------------------------------

*/
public  class L2Q_PAC_Prod_FeatureTriggerController {

    

/************** Product Trigger Logic  Start *********************/

    // Method - 1 : 1. update Review Required to True
    //              2. Send Email to LOE Admin when Available for Chime = true
    //              3. Make Is_Available_For_Chime = false when product became Inactive
    public static void beforeUpdateLogic(Map<Id,PAC_Product_Catalog__c> oldMap,List<PAC_Product_Catalog__c> newList){
        
        // Set to store all Product Ids for which Available for Chime is checked 
        set<ID> allProductIds = new set<ID>();
        
        // Set to store all Product Ids for Active = False & Phase = EoL
        set<ID> allProductIdsDelete_EoL = new set<ID>();
        
        // Set to store all Product Ids for Active = False & Phase = EoS
        set<ID> allProductIdsDelete_EoS = new set<ID>();

        // List to store all Product Ids if they become Phase = EoS
        Set<Id> eosProducts = new Set<Id>();

        // List to store all Product Ids if they become Phase = EoL
        Set<Id> eolProducts = new Set<Id>();
        
        for(PAC_Product_Catalog__c iteratedPACProduct : newList){
          
              // Use Case 1 + 2
              if(iteratedPACProduct.Is_Available_For_Chime__c && !oldMap.get(iteratedPACProduct.Id).Is_Available_For_Chime__c){
            
                iteratedPACProduct.Review_Required__c = true;
                allProductIds.add(iteratedPACProduct.Id);
              }
              
              // 
              if(iteratedPACProduct.Phase__c != oldMap.get(iteratedPACProduct.Id).Phase__c && 
                (iteratedPACProduct.Phase__c == 'EoS' || iteratedPACProduct.Phase__c == 'EoL')
                ){
                if(iteratedPACProduct.Phase__c == 'EoL'){
                    iteratedPACProduct.Is_Available_For_Chime__c = false;
                }
                if(iteratedPACProduct.Phase__c == 'EoS'){
                    eosProducts.add(iteratedPACProduct.Id); 
                }
                else if(iteratedPACProduct.Phase__c == 'EoL'){
                    eolProducts.add(iteratedPACProduct.Id); 
                }
              }
              
        }
        
        // Calling Method to Send Email to LOE Admin Team
        if(allProductIds.size() > 0){
            sendEmailtoLOEAdmin_Prod(allProductIds);
        }    
        // ESESP-6136 Calling Method to Send Email to LOE Admin Team for Products becoming EoS
        if(eosProducts.size() > 0){ 
            sendEmailtoLOEAdminForEOSProducts(eosProducts);
        }    
        // ESESP-6136 Calling Method to Send Email to LOE Admin Team for Products becoming EoL 
        if(eolProducts.size() > 0){
            sendEmailtoLOEAdminForEOLProducts(eolProducts);
        }    
    }
    
    // Method - 2 : Send Email to Question Admin Team
    //@future
    public static void sendEmailtoQunAdmin(set<ID> filteredProdIDs){ 

        string emailSubject = 'Chime Questionnaire Setup for New Product';
        string emailBody = 'Hi Team , <br/> The products given below have been newly created in SFDC. If you would like to make the Products available in CHIME, please navigate to the CHIME Admin interface using this '+'<a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/n/Chime_Admin_Wizard'+'">link</a>'+' and setup Questions for the corresponding products:<br/><br/>';
        List<String> toAddresses    = new List<String>();
        toAddresses.add(CHIME_GSS_Settings__c.getall().values().Question_Admin_Email__c);
        //toAddresses.add('visharm@akamai.com');
        // Get Product Details
        List<PAC_Product_Catalog__c> filteredList = [select Id,Product_Name__c from PAC_Product_Catalog__c where ID IN :filteredProdIDs];
        
        // Loop for Designing Email Body
        for(integer i=0; i< filteredList.size() ; i++){
        
            emailBody += i+1 + '. ' + filteredList[i].Product_Name__c
                        + '<br/>';
        }
        emailBody += '<br/> Thanks <br/> SFDC Team';
             
        L2Q_LOE_Utility.sendEmail_allUseCases(null, null, toAddresses,emailSubject,emailBody) ;
    
    }
    
    
    // Method - 3 : Send Email to LOE Admin Team
     //@future
     public static void sendEmailtoLOEAdmin_Prod(set<ID> allProductIds){
     
        List<PAC_Product_Catalog__c> allProdDetails = [select Id,Product_Name__c from PAC_Product_Catalog__c where ID IN :allProductIds];
        
        string emailSubject = 'Chime LOE Data Configuration for New Product';
        string emailBody = 'Hi Team , <br/> Below products have been marked available for Chime Form. If you would like to configure Products and their associated Features LOE Data, please navigate to Admin interface:<br/><br/>';
        List<String> toAddresses    = new List<String>();
        //toAddresses.add(CHIME_GSS_Settings__c.getall().values().Question_Admin_Email__c);
        //toAddresses.add('visharm@akamai.com');
        toAddresses = getLOEAdminsEmailId();
        
        // Loop for Designing Email Body
        for(integer i=0; i< allProdDetails.size() ; i++){
        
            emailBody += i+1 + '. ' + allProdDetails[i].Product_Name__c + ' : ' +
                        System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/PAC_Product_Catalog__c/' + allProdDetails[i].Id + '/view'
                        + '<br/>';
        }
        emailBody += '<br/> Thanks <br/> SFDC Team';
             
        L2Q_LOE_Utility.sendEmail_allUseCases(null, null, toAddresses,emailSubject,emailBody) ;
        
     
     }

/************** Feature Trigger Logic  Start*********************/
   

    // Method - 4 : to stamp Activated On date/time on features
    public static void stampActivatedOnValue(Map<Id,PAC_Product_Features__c> oldMap,List<PAC_Product_Features__c> newList,String event){
        for(PAC_Product_Features__c iteratedPACfeature : newList){
            if(
                iteratedPACfeature.Active__c && 
                (event == 'Insert' || (event == 'Update' && !oldMap.get(iteratedPACfeature.Id).Active__c))
                ){
                    iteratedPACfeature.Activated_On__c = datetime.now();
             }
        }
    }

      // Method - 5 : to update Review Required on PAC Product
      public static void updateProductReviewRequired(Map<Id,PAC_Product_Features__c> oldMap,List<PAC_Product_Features__c> newList){
        List<Id> targetPACProductList = new List<Id>();  
        List<PAC_Product_Catalog__c> productRecs = new List<PAC_Product_Catalog__c>();
        for(PAC_Product_Features__c iteratedPACfeature : newList){
           if(iteratedPACfeature.Review_Required__c && iteratedPACfeature.Review_Required__c != oldMap.get(iteratedPACfeature.Id).Review_Required__c && iteratedPACfeature.Active__c){
            targetPACProductList.add(iteratedPACfeature.Product__c);
           }
        }
        productRecs = [Select Id,Review_Required__c from PAC_Product_Catalog__c where Id IN:targetPACProductList];
        for(PAC_Product_Catalog__c iteratedPACProduct : productRecs){
            iteratedPACProduct.Review_Required__c = true;
        }
        update productRecs;
    }
    
    // Method - 6 : Calculation on Feature Insert
    public static void calcOnFeatureInsert(List<PAC_Product_Features__c> newList){
    
        set<Id> filteredFeatures = new set<Id>();
        
        // Loop for all the Features
        for(PAC_Product_Features__c iteratedPACfeature : newList){
        
            if(iteratedPACfeature.Is_Parent_Prod_Active__c){
                
                filteredFeatures.add(iteratedPACfeature.ID);
            }
        }
        
        if(filteredFeatures.size() > 0)
            sendEmailtoLOEAdmin(filteredFeatures);
    }
    
    
    
    // Method - 8 : Send Email to LOE Admin for Feature Insert
    @future
    public static void sendEmailtoLOEAdmin(set<Id> filteredFeatures){ 
    
        List<PAC_Product_Features__c> getFeatureDetails = [select Id,Feature_Name__c,Product__r.Product_Name__c 
                                                            from PAC_Product_Features__c 
                                                            where ID IN :filteredFeatures 
                                                            ];

        string emailSubject = 'Chime LOE Data Configuration for New Features';
        string emailBody = 'Hi Team , <br/> Below Features have been added for below Products. If you would like to configure Features LOE Data, please navigate to Admin interface:<br/><br/>';
        List<String> toAddresses    = new List<String>();
        //toAddresses.add(CHIME_GSS_Settings__c.getall().values().Question_Admin_Email__c);
        //toAddresses.add('visharm@akamai.com');
        toAddresses = getLOEAdminsEmailId();
        
        for(integer i=0; i< getFeatureDetails.size() ; i++){
    
            emailBody += i+1 + '. ' + getFeatureDetails[i].Feature_Name__c + ' : ' + 
                        getFeatureDetails[i].Product__r.Product_Name__c + ' ( ' +
                        System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/PAC_Product_Features__c/' + getFeatureDetails[i].Id + '/view )'
                        + '\n';
        }
        emailBody += '<br/> Thanks <br/> SFDC Team';
        
        L2Q_LOE_Utility.sendEmail_allUseCases(null, null, toAddresses,emailSubject,emailBody) ;

    }
    
    // Method - 11 : to return all LOE Admin Emails
    public static List<string> getLOEAdminsEmailId(){
        List<string> adminsId = new List<string>();
        
        for(User eachUsr : [select Email from User where isActive = true and ID IN 
                                (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'Chime_Admin_Permission_Set') ]){
            adminsId.add(eachUsr.Email);                        
        }
        
        adminsId = Test.isRunningTest() ? new List<String>{'test@akamai.com'} : adminsId;
        
        return adminsId;
    }
    
    /************** Chime Trigger Logic  Start *********************/
    // 1. If Chime Status = Accepted, Update Case + Send Email to Case Owner / Chime Creator
    public static void actionOnChimeUpdate(List<CHIME__c> newList, Map<ID,CHIME__c> oldMap){
        CHIME__c chimeRec;
        set<ID> filteredChimeIds_AcceptedStatus = new set<ID>();
        set<ID> caseIdList = new set<ID>();
        string ret;
            
        // Loop for all Incoming chime Records
        for(CHIME__c eachChimeRec : newList){
            
            // 1. If status changed to Accepted
            if(eachChimeRec.Status__c != oldMap.get(eachChimeRec.Id).Status__c && eachChimeRec.Status__c == 'Accepted'){
            
                filteredChimeIds_AcceptedStatus.add(eachChimeRec.Id);
                
                if(eachChimeRec.Integration_Case_ID__c != null)
                    caseIdList.add(eachChimeRec.Integration_Case_ID__c);
            }
                
        }
        
        // call SendEmail Method
    //  if(filteredChimeIds_AcceptedStatus.size() > 0)
    //      sendEmailBatch(filteredChimeIds_AcceptedStatus, caseIdList);
            
            // Calling Update Case Method for - Accepted Chime Forms
            for(Id eachChimeId : filteredChimeIds_AcceptedStatus){
        
                ret = L2Q_LOE_Utility.create_updateCase(eachChimeId, null, 'Integration_Case', null, true);
                if(ret.Contains('Error in Case Creation/Update :')){
                    chimeRec = new CHIME__c(Id=eachChimeId);
                    chimeRec.addError('Case update failed , Please contact admnistrator');
                }
            }
        
    }
    
    /*@future
    public static void sendEmailBatch( set<Id> filteredChimeIds_AcceptedStatus, set<Id> caseIdList){ 
    
        CHIME__c chimeRec;
        string ret;
        
        // Calling Update Case Method for - Accepted Chime Forms
        for(Id eachChimeId : filteredChimeIds_AcceptedStatus){
        
            ret = L2Q_LOE_Utility.create_updateCase(eachChimeId, null, 'Integration_Case', null, true);
            
            if(ret.Contains('Error in Case Creation/Update :')){
                chimeRec = new CHIME__c(Id=eachChimeId);
                chimeRec.addError('Case update failed , Please contact admnistrator');
            }
        }
        
        // List for Each SingleEmailMessage
        List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email ;
        ID getOrgWideId = CHIME_GSS_Settings__c.getall().values().From_Email_Add_OrgId__c;
        List<String> toAddresses;
        
        // 1. Getting Case Owner
        Map<ID,string> caseId_OwnerEmailMap = new Map<ID,string>();
        if(caseIdList.size() > 0){
        
            for(Case eachCaseRec : [select Id, owner.Email from case where ID IN :caseIdList and Owner.type ='User']){
            
                caseId_OwnerEmailMap.put(eachCaseRec.Id, eachCaseRec.owner.Email);
            }
        }
        
        // 2. Iterate each Chime Form
        for(CHIME__c eachChimeForm : [select Id,createdBy.Email,Integration_Case_ID__c,CHIME_Name__c 
                                        from CHIME__c 
                                        where ID IN :filteredChimeIds_AcceptedStatus]){
        
            // Designing To Add
            toAddresses = new List<String>();
            toAddresses.add(eachChimeForm.createdBy.Email);
            
            if(caseId_OwnerEmailMap.get(eachChimeForm.Integration_Case_ID__c) != null)
                toAddresses.add(caseId_OwnerEmailMap.get(eachChimeForm.Integration_Case_ID__c));
            
            // Setting Email Parameter
            email = new Messaging.SingleEmailMessage();
            email.setOrgWideEmailAddressId(getOrgWideId); 
            email.setUseSignature(false); 
            email.setSaveAsActivity(false);
            email.setToAddresses(toAddresses);
            email.subject = 'Update on Chime Form : [ ' + eachChimeForm.CHIME_Name__c + ' ]';
            email.HtmlBody = ' Chime Form has been updated. Please review the Form and Case from below Link <br/><br/>' +
                             'Link to navigate Chime Form - ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/CHIME__c/' + eachChimeForm.Id + '/view <br/><br/>'
                             + 'Link to navigate Integration Case - ' + System.URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Case/' + eachChimeForm.Integration_Case_ID__c + '/view <br/><br/>' 
                             + 'Please take appropriate action.<br/><br/>' +
                             'Thanks <br/>SFDC Team';
                             
            emailsToBeSent.add(email);
        }
        
        // Sending Email
        Messaging.SendEmail(emailsToBeSent);
    }*/
    
     
    //  public static void stampDeActivatedOnValue(Map<Id,PAC_Product_Features__c> oldMap,List<PAC_Product_Features__c> newList){
    //  if(UserInfo.getProfileId() == CHIME_GSS_Settings__c.getall().values().MI_Profile_Id__c){
    //      for(PAC_Product_Features__c iteratedPACfeature : newList){
    //          if(!iteratedPACfeature.Active__c && iteratedPACfeature.Active__c != oldMap.get(iteratedPACfeature.Id).Active__c){
    //                  iteratedPACfeature.De_activated_On__c = datetime.now();
    //          }
    //      }
    //  }
    // }


    //this method is called when changes are made from sys admin/mule profile user to get the additional param from its Original Marketing ProductId if its an Addon 
    public static void syncAdditionalAttributesforAddOns(List<PAC_Product_Catalog__c> newList, Map<Id, PAC_Product_Catalog__c> oldMap, Boolean isInsert)
    {
        Set<String> originalMPIds                           = new Set<String>();
        Set<String> realMPIds                               = new Set<String>();
        Map<String, PAC_Product_Catalog__c> oMPIdtoProduct  = new Map<String, PAC_Product_Catalog__c>();
        
        
        if(!isInsert)
        {
            for(PAC_Product_Catalog__c eProd : newList)
            {
                if(eProd.Base_Product__c)
                {
                    realMPIds.add(eProd.Marketing_Product_Id__c);
                }
            }  
        }
        

        for(PAC_Product_Catalog__c eProd : newList)
        {
            if(eProd.Original_Marketing_Product_Id__c != null && eProd.Marketing_Product_Id__c != eProd.Original_Marketing_Product_Id__c && ((!isInsert && eProd.Add_On__c && !oldMap.get(eProd.Id).Add_On__c) || (isInsert && eProd.Add_On__c)) )
            {
                originalMPIds.add(eProd.Original_Marketing_Product_Id__c);
            }
        }
        

        System.debug('originalMPIds :: ' + originalMPIds);
        if(! originalMPIds.isEmpty())
        {
            for(PAC_Product_Catalog__c originalProd : [SELECT Id, Marketing_Category__c, PAC_Is_Stand_Alone_Prod__c, PAC_Show_On_UI__c, Phase__c, Business_Unit__c, Version__c, Short_Description__c,Marketing_Product_Id__c FROM PAC_Product_Catalog__c WHERE Marketing_Product_Id__c IN :originalMPIds])
            {
                oMPIdtoProduct.put(originalProd.Marketing_Product_Id__c, originalProd);
            }
            
            System.debug('oMPIdtoProduct :: ' + oMPIdtoProduct);

            for(PAC_Product_Catalog__c eProd : newList)
            {

                if(originalMPIds.contains(eProd.Original_Marketing_Product_Id__c) && eProd.Add_On__c)
                {
                    PAC_Product_Catalog__c updateParamOfProdcut     = oMPIdtoProduct.get(eProd.Original_Marketing_Product_Id__c);

                    eProd.Marketing_Category__c      = updateParamOfProdcut.Marketing_Category__c;
                    eProd.PAC_Is_Stand_Alone_Prod__c = updateParamOfProdcut.PAC_Is_Stand_Alone_Prod__c;
                    eProd.PAC_Show_On_UI__c          = updateParamOfProdcut.PAC_Show_On_UI__c;
                    eProd.Phase__c                   = updateParamOfProdcut.Phase__c;
                    eProd.Business_Unit__c           = updateParamOfProdcut.Business_Unit__c;
                    eProd.Version__c                 = updateParamOfProdcut.Version__c;
                    eProd.Short_Description__c       = updateParamOfProdcut.Short_Description__c;
                    
                    System.debug('updateParamOfProdcut :: ' + eProd);
                } 
            }
        }
        
        if(!realMPIds.isEmpty())
        {
            //call a future method to correct all its Addons where Original Marketing Product Id = Real Marketing product Ids
            syncAddonsFromRealProducts(realMPIds);
        }
    }
    
    
    @future
    public static void syncAddonsFromRealProducts(Set<String> mpIds)
    {
        List<PAC_Product_Catalog__c>              prodsToUpdate             = new List<PAC_Product_Catalog__c>();
        Map<String, List<PAC_Product_Catalog__c>> realProdToContextProds    = new Map<String, List<PAC_Product_Catalog__c>>();
        Map<String,PAC_Product_Catalog__c>          realProducts            = new Map<String,PAC_Product_Catalog__c>();
        
        for(PAC_Product_Catalog__c eProd : [SELECT Id, Marketing_Category__c,PAC_Is_Stand_Alone_Prod__c,PAC_Show_On_UI__c, Phase__c,Business_Unit__c,Version__c, Short_Description__c,Marketing_Product_Id__c,Original_Marketing_Product_Id__c,Base_Product__c,Add_On__c FROM PAC_Product_Catalog__c WHERE (Original_Marketing_Product_Id__c IN :mpIds OR Marketing_Product_Id__c IN :mpIds)])
        {
            
            if(eProd.Original_Marketing_Product_Id__c != null && eProd.Add_on__c && !eProd.Base_product__c )
            {
               if( !realProdToContextProds.containsKey(eProd.Original_Marketing_Product_Id__c))
                {
                    realProdToContextProds.put(eProd.Original_Marketing_Product_Id__c, new List<PAC_Product_Catalog__c>());
                    realProdToContextProds.get(eProd.Original_Marketing_Product_Id__c).add(eProd);
                }
                else
                {
                    realProdToContextProds.get(eProd.Original_Marketing_Product_Id__c).add(eProd);
                } 
            }
            
            System.debug('realProdToContextProds :: ' + realProdToContextProds );
            if(eProd.Base_Product__c && !realProducts.containsKey(eProd.Marketing_Product_Id__c))
            {
                realProducts.put(eProd.Marketing_Product_Id__c, eProd);
            }
            
            System.debug('realProducts :: ' + realProducts );
            
        }
        
        System.debug('realProdToContextProds after Loop :: ' + realProdToContextProds );
        System.debug('realProdToContextProds after Loop :: ' + realProdToContextProds.size() );
        System.debug('realProducts after Loop :: ' + realProducts );
        System.debug('realProducts after Loop :: ' + realProducts.size() );
        
        for(String eRealMPId : realProdToContextProds.keySet())
        {
            System.debug('eRealMPId :: ' + eRealMPId); 
            for(PAC_Product_Catalog__c eProd : realProdToContextProds.get(eRealMPId))
            {
                System.debug('eProd :: ' + eProd); 
                PAC_Product_Catalog__c updateParamOfProdcut = realProducts.get(eRealMPId);
                
                System.debug('updateParamOfProdcut :: ' + updateParamOfProdcut + ' :: eProd ' + eProd);
                
                eProd.Marketing_Category__c      = updateParamOfProdcut.Marketing_Category__c;
                eProd.PAC_Is_Stand_Alone_Prod__c = updateParamOfProdcut.PAC_Is_Stand_Alone_Prod__c;
                eProd.PAC_Show_On_UI__c          = updateParamOfProdcut.PAC_Show_On_UI__c;
                eProd.Phase__c                   = updateParamOfProdcut.Phase__c;
                eProd.Business_Unit__c           = updateParamOfProdcut.Business_Unit__c;
                eProd.Version__c                 = updateParamOfProdcut.Version__c;
                eProd.Short_Description__c       = updateParamOfProdcut.Short_Description__c;
                
                System.debug('updateParamOfProdcut :: ' + updateParamOfProdcut + ' :: eProd ' + eProd);
                
                prodsToUpdate.add(eProd);
            }
        }
        
        try
        {
            if(!prodsToUpdate.isEmpty())
            {
                update prodsToUpdate; 
            }
           
        }
        catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In upating Addons with Real Product Params.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = L2Q_PAC_Prod_FeatureTriggerController\n' +'Method Name = syncAddonsFromRealProducts\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);  
        }
        
    }
    

    //this method is called when changes are made from sys admin/mule profile user for creating/modifying/soft deleting the Junction Object records.
    public static void addorModifyJunctionObject(List<PAC_Product_Catalog__c> newList, Map<Id, PAC_Product_Catalog__c> oldMap)
    {
        // to filter and load mkProdId and its Addons
        Map<String, List<String>>                       prodToAddons    = new Map<String,List<String>>();
        // to store all prod Ids of mkProdId and Addons
        Set<String>                                     prodAndAddons   = new Set<String>();
        // to store all mkProd Id and its SF Id
        Map<String, String>                             mkProdToProdId  = new Map<String, String> ();
        // to store all mkProd and its Mapping from Juntion Obj
        Map<String, PAC_Product_to_Add_on__c> mkProdIdToProdAddon = new Map<String, PAC_Product_to_Add_on__c>();
        // to store all mkProd and its Mapping from Juntion Obj
        // Map<String, List<PAC_Product_to_Add_on__c>> mkProdIdToIProdAddon = new Map<String, List<PAC_Product_to_Add_on__c>>();
        
        
        // to filter and load mkProdId and its Addons
        for(PAC_Product_Catalog__c eProd : newList)
        {
            if(eProd.Base_Product__c && eProd.Product_Add_on_Mapping__c != oldMap.get(eProd.Id).Product_Add_on_Mapping__c)
            {
                if(eProd.Product_Add_on_Mapping__c != '' && eProd.Product_Add_on_Mapping__c != null )
                {
                    List<String> addOns = (eProd.Product_Add_on_Mapping__c).split(':');
                    prodToAddons.put(eProd.Marketing_Product_Id__c, addOns);
                    prodAndAddons.addAll(addOns);
                }
                else if (eProd.Product_Add_on_Mapping__c == '' || eProd.Product_Add_on_Mapping__c == null )
                {
                    prodToAddons.put(eProd.Marketing_Product_Id__c,NULL);
                }
                
                prodAndAddons.add(eProd.Marketing_Product_Id__c);
            }
        }
        
        // to store all mkProd Id and its SF Id
        for(PAC_Product_Catalog__c eProd : [SELECT Id, Marketing_Product_Id__c FROM PAC_Product_Catalog__c WHERE Marketing_Product_Id__c =:prodAndAddons ])
        {
            if(! mkProdToProdId.containsKey(eProd.Marketing_Product_Id__c))
            {
                mkProdToProdId.put(eProd.Marketing_Product_Id__c,eProd.Id);
            } 
        }
        
        // to store all mkProd and its Mapping from Juntion Obj
        for(PAC_Product_to_Add_on__c prodToAddon : [SELECT Id, PAC_Product__c, Add_on__c, PAC_Product__r.Marketing_Product_Id__c, Active__c, Add_on__r.Marketing_Product_Id__c FROM PAC_Product_to_Add_on__c WHERE PAC_Product__r.Marketing_Product_Id__c =: prodToAddons.keySet()])
        {
            String key = prodToAddon.PAC_Product__r.Marketing_Product_Id__c + '-' + prodToAddon.Add_on__r.Marketing_Product_Id__c;
            if(! mkProdIdToProdAddon.containsKey(key))
            {
                mkProdIdToProdAddon.put(key, prodToAddon);
            }

            // if(! mkProdIdToIProdAddon.containsKey(prodToAddon.PAC_Product__r.Marketing_Product_Id__c))
            // {
            //     mkProdIdToIProdAddon.put(prodToAddon.PAC_Product__r.Marketing_Product_Id__c, new List<PAC_Product_to_Add_on__c>());
            //     mkProdIdToIProdAddon.get(prodToAddon.PAC_Product__r.Marketing_Product_Id__c).add(prodToAddon);
            // }
            // else
            // {
            //     mkProdIdToIProdAddon.get(prodToAddon.PAC_Product__r.Marketing_Product_Id__c).add(prodToAddon);
            // }
        }

        List<PAC_Product_to_Add_on__c> prodToAddonsUpsert = new List<PAC_Product_to_Add_on__c>();
        
        for(String eProd : prodToAddons.keySet())
        {
            if(prodToAddons.get(eProd) != NULL)
            {
                for(String eAddon : prodToAddons.get(eProd))
                {
                    String key = eProd + '-'+ eAddon;

                    if(mkProdIdToProdAddon.containsKey(key))
                    {
                        PAC_Product_to_Add_on__c prodAddon = mkProdIdToProdAddon.get(key);
                        prodAddon.Active__c = true;
                        prodToAddonsUpsert.add(prodAddon);
                        mkProdIdToProdAddon.remove(key);
                        
                    }
                    else
                    {
                        PAC_Product_to_Add_on__c prodAddon = new PAC_Product_to_Add_on__c();
                        prodAddon.Active__c         = true;
                        prodAddon.PAC_Product__c    = mkProdToProdId.get(eProd);
                        prodAddon.Add_on__c         = mkProdToProdId.get(eAddon);
                        prodToAddonsUpsert.add(prodAddon);

                    }

                }

                // for(PAC_Product_to_Add_on__c eAddon : mkProdIdToProdAddon.get(key))
                // {
                //     eAddon.Active__c    = false;
                //     prodToAddonsUpsert.add(eAddon);
                // }

            }
            // else
            // {
            //     if(mkProdIdToIProdAddon.containsKey(eProd))
            //     {
            //         for(PAC_Product_to_Add_on__c eProdToAddon: mkProdIdToIProdAddon.get(eProd))
            //         {
            //             eProdToAddon.Active__c    = false;
            //             prodToAddonsUpsert.add(eProdToAddon);
            //         }
            //     }
            // }
            
        }

        for(String eJunc : mkProdIdToProdAddon.keySet())
        {
            PAC_Product_to_Add_on__c juncObj = mkProdIdToProdAddon.get(eJunc);
            juncObj.Active__c = false;
            prodToAddonsUpsert.add(juncObj);
        }

        upsert prodToAddonsUpsert;
            
    }

     // Method to send email to Chime Governance team for Products becomg EoS
     //@future
     public static void sendEmailtoLOEAdminForEOSProducts(Set<Id> eosProducts){
     
        List<PAC_Product_Catalog__c> allProdDetails = [select Id,Product_Name__c,Base_Product__c from PAC_Product_Catalog__c where ID IN :eosProducts];
        List<PAC_Product_Catalog__c> baseProducts = new List<PAC_Product_Catalog__c>();
        List<PAC_Product_Catalog__c> addOnProducts = new List<PAC_Product_Catalog__c>();
        string emailSubject = 'Products marked End of Sale ';
        string emailBody = 'Hi Team , <br/> This is to inform that these products mentioned below have reached End of Sale. However , you can still continue to select \'End of Sale\' products on new / existing Chime forms: <br/><br/>';
        List<String> toAddresses    = new List<String>();
        string productType = '';
       
        toAddresses = getLOEAdminsEmailId();
        //toAddresses.add('vishnu11111@gmail.com');
        for(integer i=0; i< allProdDetails.size() ; i++){
            if(allProdDetails[i].Base_Product__c){
                baseProducts.add(allProdDetails[i]);
            }else{
                addOnProducts.add(allProdDetails[i]);
            }
        } 
        
        if(baseProducts.size() > 0){
            emailBody += '<b>Base Products</b><br/>';
            for(integer j =0;j< baseProducts.size();j++){
                emailBody += j+1 + '. ' + baseProducts[j].Product_Name__c
                        + '<br/>';
            }
        }

        if(addOnProducts.size() > 0){
            emailBody += '<b>Add-On Products</b><br/>';
            for(integer j =0;j< addOnProducts.size();j++){
                emailBody += j+1 + '. ' + addOnProducts[j].Product_Name__c
                        + '<br/>';
            }
        }
        // Loop for Designing Email Body
       /* for(integer i=0; i< eosProducts.size() ; i++){
            if(allProdDetails[i].Base_Product__c)
            productType = 'Base Product';
            else
            productType = 'Add-On Product';
            emailBody += i+1 + '. ' + allProdDetails[i].Product_Name__c+' ( '+ productType+' )'
                        + '<br/>';
        }*/
        emailBody += '<br/> Thanks <br/> SFDC Team';
        try{     
        L2Q_LOE_Utility.sendEmail_allUseCases(null, null, toAddresses,emailSubject,emailBody) ;
        }catch(Exception e){
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In Email method when products becomes EOS.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = L2Q_PAC_Prod_FeatureTriggerController\n' +'Method Name = syncAddonsFromRealProducts\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        }
        
     
     }

      // Method to send email to Chime Governance team for Products becomg EoL
      //@future
      public static void sendEmailtoLOEAdminForEOLProducts(Set<Id> eolProducts){
      
         List<PAC_Product_Catalog__c> allProdDetails = [select Id,Product_Name__c,Base_Product__c from PAC_Product_Catalog__c where ID IN :eolProducts];
         List<PAC_Product_Catalog__c> baseProducts = new List<PAC_Product_Catalog__c>();
         List<PAC_Product_Catalog__c> addOnProducts = new List<PAC_Product_Catalog__c>();
         string emailSubject = 'Products marked End of Life ';
         string emailBody = 'Hi Team , <br/>  This is to inform that these products mentioned below have reached End of Life. You will not be able to select \'End of Life\' products on new Chime forms: <br/><br/>';
         List<String> toAddresses    = new List<String>();
         string productType = '';
        
         toAddresses = getLOEAdminsEmailId();
         for(integer i=0; i< allProdDetails.size() ; i++){
            if(allProdDetails[i].Base_Product__c){
                baseProducts.add(allProdDetails[i]);
            }else{
                addOnProducts.add(allProdDetails[i]);
            }
        } 
        
        if(baseProducts.size() > 0){
            emailBody += '<b>Base Products</b><br/>';
            for(integer j =0;j< baseProducts.size();j++){
                emailBody += j+1 + '. ' + baseProducts[j].Product_Name__c
                        + '<br/>';
            }
        }

        if(addOnProducts.size() > 0){
            emailBody += '<b>Add-On Products</b><br/>';
            for(integer j =0;j< addOnProducts.size();j++){
                emailBody += j+1 + '. ' + addOnProducts[j].Product_Name__c
                        + '<br/>';
            }
        }
         
         
         // Loop for Designing Email Body
         /*for(integer i=0; i< eolProducts.size() ; i++){
             if(allProdDetails[i].Base_Product__c)
             productType = 'Base Product';
             else
             productType = 'Add-On Product';
             emailBody += i+1 + '. ' + allProdDetails[i].Product_Name__c+' ( '+ productType+' )'
                         + '<br/>';
         }*/
         emailBody += '<br/> Thanks <br/> SFDC Team';
         try{     
         L2Q_LOE_Utility.sendEmail_allUseCases(null, null, toAddresses,emailSubject,emailBody) ;
         }
         catch(Exception e){
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In Email method when products becomes EOL.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = L2Q_PAC_Prod_FeatureTriggerController\n' +'Method Name = syncAddonsFromRealProducts\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage); 
         }
         
      
      }
    
}