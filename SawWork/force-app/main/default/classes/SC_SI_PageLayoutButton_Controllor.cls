/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Controllor Class Page Layout Button on SI Detail Page
Called From		: 
Test Class		: SC_SI_AllTestCases_TC

Date                Developer             JIRA #                            Description                                                       
-----------------------------------------------------------------------------------------------------------------------------
14 Aug 2020       	Sheena               ESESP-3795               		  Initial Version
28 Oct 2021         Jay                  ESESP-6265                       Added limit 50000 to unbounded SOQLs
21 Apr 2022			Sheena				 ESESP-5433						  Excluded RCA Cases from showing up under Impaced Cases on SI							
------------------------------------------------------------------------------------------------------------------------------

*/
public class SC_SI_PageLayoutButton_Controllor {
    
    // Instantiating the Inner Class
    public static SC_SI_PageLayoutButton_Controllor.CommunityPostFunctionality comCls = new SC_SI_PageLayoutButton_Controllor.CommunityPostFunctionality();
    public static SC_SI_PageLayoutButton_Controllor.AddCasesFunctionality addCaseCls = new SC_SI_PageLayoutButton_Controllor.AddCasesFunctionality();
    public static SC_SI_PageLayoutButton_Controllor.TransitionFunctionality transnCls = new SC_SI_PageLayoutButton_Controllor.TransitionFunctionality();
    public static SC_SI_PageLayoutButton_Controllor.deLinkCaseFunctionality deLinkCaseCls = new SC_SI_PageLayoutButton_Controllor.deLinkCaseFunctionality(); 
    public static SC_SI_PageLayoutButton_Controllor.AccountChartFunctionality accChartCls = new SC_SI_PageLayoutButton_Controllor.AccountChartFunctionality(); 
    public static SC_SI_PageLayoutButton_Controllor.AddProductFunctionality addProductCls = new SC_SI_PageLayoutButton_Controllor.AddProductFunctionality(); 
    
    
    // Method - 1 : (Community Sync) - To get Transformed data
    @AuraEnabled
    Public static string getDataForCommunity(String SIrecordId, String buttonLabel){  	
        
        return comCls.getDefaultValues(SIrecordId, buttonLabel);
    }
    
    // Method - 2 : (Community Sync) - Syncing Feed
    @AuraEnabled
    Public static string syncFeedItem(String htmlData, String SIrecordId, String buttonLabel){
        
        return comCls.createFeedItem(htmlData , SIrecordId, buttonLabel);
    }
    
    // Method - 3 : (Link Case) - Validate Case for SI
    @AuraEnabled
    Public static string updateCaseWithSI(String siId,String caseId){
        
        return addCaseCls.validateCase(siId,caseId); 	
    }
    
    // Method - 4 : (Link Case) - Add Case to SI
    @AuraEnabled
    Public static string addCaseToSI(String siId,String caseId){
        
        return addCaseCls.addCaseToSI(siId,caseId);
    }
    
    // Method - 4 : (Transition) - Get Current Shift
    @AuraEnabled(cacheable=true)
    Public static string getCurrentShiftDetails(){
        
        return transnCls.getCurrentShiftDetails();	
    }
    
    // Method - 5 : (Transition) - Get Current Shift
    @AuraEnabled
    Public static string wakeUpTimeMethod(String targetShiftTime){
        
        return transnCls.wakeUpTimeMethod(targetShiftTime);	
    }
    
    // Method - 6 : (Transition) - Save Transition
    @AuraEnabled
    Public static string saveTransition(String currentRecId, String notes, String currentShift, String newShift,
                                        String wakeUpTime, Id suggestedBIL, Id previousOwner){
                                            
                                            return transnCls.saveTransition(currentRecId, notes, currentShift, newShift, wakeUpTime, suggestedBIL, previousOwner);	
                                        }
    
    // Method - 7 : (DeLink Case) - Fetch All Cases
    @AuraEnabled( cacheable=true )
    Public static string fetchAllRelatedCases(String SIrecordId){        
        return deLinkCaseCls.fetchAllRelatedCases(SIrecordId);	
    }
    
    // Method - 8 : (DeLink Case) - Update Case
    @AuraEnabled
    Public static string deLinkSIRecords(String CaserecordId){
        
        return deLinkCaseCls.deLinkSIRecords(CaserecordId);	
    }
    
    // Method - 9 : (Account Chart) - Get Account Tier Details
    @AuraEnabled
    Public static Map<string, integer> getAccChartMap(String SIrecId){
        
        return accChartCls.getChartMap(SIrecId);	
    }
    
    // Method - 10 : (Impaced Account) - Fetch EB Products
    @AuraEnabled(cacheable=true)
    Public static list<productWrapper> getGridData(){
        
        return addProductCls.getGridData();	
    }
    
    // Method - 11 : (Impaced Account) - Save EB Products
    @AuraEnabled
    Public static String saveImpactedProducts(String IncidentId, list<Items> prodWrap){
        
        return addProductCls.saveImpactedProducts(IncidentId, prodWrap);	
    }
    
    // Wrapper - 1 : Used for return output for Community Sync
    Public Class IncidentWrapper_Community{      
        @AuraEnabled public String timeValue,status,customer_Advisory;        
    }
    
    // Wrapper -2 Used for the Main Impacted Product
    public Class productWrapper{
        @AuraEnabled
        public String productId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String entitledId {get;set;}
        @AuraEnabled
        public List<Items> items {get;set;}
    }
    
    // Wrapper -2 Used for the Child Products
    public Class Items{
        @AuraEnabled
        public String productId {get;set;}
        @AuraEnabled
        public String name {get;set;}
        @AuraEnabled
        public String parentModuleName {get;set;}
        @AuraEnabled
        public String parentModProdId {get;set;}
        @AuraEnabled
        public String parentProductName {get;set;}
        @AuraEnabled
        public String parentProdId {get;set;}
        @AuraEnabled
        public String entitledId {get;set;}
        @AuraEnabled
        public List<Items> items {get;set;}
        
    }
    
    
    
    // Wrapper - 4 : for the Button Visibility
    public Class buttonVisibilityWrapper{
        
        @AuraEnabled public Boolean isIraptUser {get;set;}
        
        @AuraEnabled public Boolean isCommunityAuthorized {get;set;}
        @AuraEnabled public String communityButtonLabel{get;set;} 
        
        @AuraEnabled public Boolean isTransitionAuthorized {get;set;}
        @AuraEnabled public String previousOwnerId {get;set;}
        
        @AuraEnabled public Boolean isAddproductAuthorized {get;set;}
        @AuraEnabled public Boolean isLinkCaseAuthorized {get;set;}
        @AuraEnabled public String incidentName {get;set;}
        @AuraEnabled public Boolean isExtDependencyAuthorized {get;set;}
        
        
        // Constructor for assigning the default value
        buttonVisibilityWrapper(){
            isIraptUser = False;
            previousOwnerId = '';
            isCommunityAuthorized = False;
            isTransitionAuthorized = False;
            isAddproductAuthorized = False;
            isLinkCaseAuthorized = False;
            isExtDependencyAuthorized = False;
            communityButtonLabel = 'Create Community Post';
        }
        
    }
    
    
    // Method - 3 : (Button visibility) - Called from Init Method
    @AuraEnabled
    Public static string getButtonAccess(String SIrecordId){
        
        // Status Values for for Disabling the Butons
        List<String> siStatus = new List<String>{'Rejected', 'Canceled'};
            
            // Get the Value for IRAPT User Checkbox
            User u = [select Id, SC_SI_IRAPT_User__c from User where Id = :UserInfo.getUserId()];
        
        // Get SI Details
        SC_SI_Service_Incident__c siRec = [Select id, Name, OwnerId, Status__c , External__c, Community_Post_Id__c , Cannot_link_cases_to_this_incident__c from SC_SI_Service_Incident__c where id =: SIrecordId];
        
        // Instantiating Wrapper record
        buttonVisibilityWrapper btnWrp = new buttonVisibilityWrapper();
        
        // 1. Logic for - LoggedIn User is Irapt or not
        btnWrp.isIraptUser = u.SC_SI_IRAPT_User__c ? True : False;
        
        // Return false if Status is Rejected / Canceled / Closed
        if (siStatus.contains(siRec.Status__c))
            return JSON.serialize(btnWrp);
        
        
        // 2. Logic for - Community Button
        list<CollaborationGroupMember> collabMemberList = new list<CollaborationGroupMember>();     
        collabMemberList = [SELECT Id, MemberId from CollaborationGroupMember where CollaborationGroup.name='Service Incident Notifications' and CollaborationRole='Admin' and MemberId=:UserInfo.getUserId() limit 1];
        btnWrp.isCommunityAuthorized = (!collabMemberList.isEmpty() && siRec.External__c==true) ? True : False;       
        
        if(siRec.Community_Post_Id__c!=''){
            List<FeedItem> feedRec = new  List<FeedItem>();
            feedRec = [Select id, Body from FeedItem where id =: siRec.Community_Post_Id__c];
            btnWrp.communityButtonLabel  = (!feedRec.isEmpty()) ? 'Update Community Post' : 'Create Community Post';
            if(feedRec.isEmpty()){
                siRec.Community_Post_Id__c = '';
                update siRec;
            }
            

            
        }
        
        
        // 3. Logic for External Dependency button visibility
        btnWrp.isExtDependencyAuthorized = true;
        
        // 4. Logic for - Add Impacted Product Button
        btnWrp.isAddproductAuthorized = ( u.SC_SI_IRAPT_User__c  || 
                                         (!u.SC_SI_IRAPT_User__c && siRec.Status__c=='Incident Request') ) ? True : False;
        
        // 5. Logic for transition button visibility       
        btnWrp.isTransitionAuthorized =  siRec.ownerId.getSObjectType().getDescribe().getName() == 'User' ? True : False;
        btnWrp.previousOwnerId = siRec.ownerId;
        
        // 6. Logic for Link Case button visibility
        btnWrp.isLinkCaseAuthorized = !(siRec.Cannot_link_cases_to_this_incident__c);
        btnWrp.incidentName = siRec.Name;
        
        return JSON.serialize(btnWrp);
        
    }
    
    // ******************** Inner Class - 1 : For Community Post Sync Functionality **************************************
    public class CommunityPostFunctionality {
        
        // Method 1 : For Data Transformation
        Public string getDefaultValues(String SIrecordId, String buttonLabel){
            
            // Get SI Details
            SC_SI_Service_Incident__c siRec = [Select id, Status__c, Customer_Advisory__c, Community_Post_Id__c, 
                                               Content_Reference_and_Document__c from SC_SI_Service_Incident__c 
                                               where id =: SIrecordId];
            
            // Geting the Default Values from SI if the COmmunity Post needs to be created
            if(buttonLabel=='Create Community Post'){
                // For Storing Status Values
                List<String> siStatus = new List<String>{'1: In Progress', '2: Impact Mitigated', '3: Resolved'};
                    
                    // Instantiating Wrapper to return
                    IncidentWrapper_Community retWrp = new IncidentWrapper_Community();
                retWrp.status= siStatus.contains(siRec.Status__c) ? siRec.Status__c.substring(3) : siRec.Status__c;
                retWrp.customer_Advisory = siRec.Customer_Advisory__c ;
                retWrp.timeValue = system.now().formatGMT('d MMM yyyy HH:mm');
                return JSON.serialize(retWrp);
            }
            // Geting the Default Values from Community Post if the COmmunity Post needs to be updated
            else{
                String postBody='';
                if(siRec.Community_Post_Id__c!=''){
                    List<FeedItem> feedRec = [Select id, Body from FeedItem where id =: siRec.Community_Post_Id__c];
                    Map<String, Object> mDocIdImg;
                    if(siRec.Content_Reference_and_Document__c!=null){
                        mDocIdImg = (Map<String, Object>)JSON.deserializeUntyped(siRec.Content_Reference_and_Document__c);
                    }
                    if(!feedRec.isEmpty())
                    {
                        postBody=feedRec[0].Body;
                        Pattern myPattern = Pattern.compile('<img[^>]+></img>');
                        Matcher myMatcher = myPattern.matcher(postBody);
                        while(myMatcher.find()){
                            String contentDocId = myMatcher.group().substringBetween('img src="sfdc://', '">');
                            postBody = postBody.replaceFirst('<img[^>]+></img>',String.valueOf(mDocIdImg.get(contentDocId)));
                        }
                    }
                }
                return postBody;
            }   
        }
        
        
        // Method 2 : For Syncing Post to Community + Stamp Feed Details on SI	
        Public string createFeedItem(String htmlData, String recordId, String buttonLabel){
            
            // Map to Store Image Tag ID + Image Tag
            map<string,string> mDocIdImage = new map<string,string>();
            
            // Map to Store Image Tag  + ContentVersion
            map<String,ContentVersion> mImageTagVer = new map<String,ContentVersion>();
            
            //variable to store Community Network ID and SI Space ID
            map<string,string> networkAndSpaceIds = new map<string,string>();
            
            // Storing the Content on SI in JSON format
            String jsonValues='';
            
            // For populating networkAndSpaceIds from Metadata
            for(SC_SI_Service_Incident_Utility__mdt data:[Select DeveloperName,Value__c from SC_SI_Service_Incident_Utility__mdt LIMIT 50000]){
                networkAndSpaceIds.put(data.DeveloperName, data.Value__c);
            }
            
            // Removing the tags which are not supported in FeedItem body.
            String replaceBreaks = htmlData.replaceAll('<br>','<p>&nbsp;</p>');
            
            // Compiling with Patterns and find how many images are there
            Pattern patternString = Pattern.compile('<span[^>]+>|</span>|<strike>|</strike>|<div[^>]+>|</div>|style="[^"]+"|alt="[^"]+"');
            Matcher patMatcher = patternString.matcher(replaceBreaks);
            String body = patMatcher.replaceAll(''); 
            patternString = Pattern.compile('<img[^>]+>');
            patMatcher = patternString.matcher(body);
            
            // Variables for images
            String imageTag,imageLink;
            ContentVersion contVerFile;
            
            // Loop for number of Images found
            while(patMatcher.find())
            {
                // Getting Image Tag & Link
                imageTag = String.valueOf(patMatcher.group());
                imageLink = patMatcher.group().substringBetween('src="', '">');
                
                
                // Instantiating ContentVersion
                contVerFile = new ContentVersion();
                if(!Test.isRunningTest()){
                    contVerFile.VersionData = new PageReference(imageLink).getContent();
                }
                else{
                   contVerFile.VersionData = Blob.valueOf('UNIT.TEST');
                }
                contVerFile.Title = 'SI Image'; 
                contVerFile.ContentLocation= 's';
                contVerFile.PathOnClient='SI Image.JPG';
                contVerFile.NetworkId=networkAndSpaceIds.get('Customer_Community_Network_ID');
                mImageTagVer.put(imageTag, contVerFile);
            }
            
            // Processing for each Image
            if(!mImageTagVer.isEmpty()){
                
                // Inserting contents
                insert mImageTagVer.values();
                
                // Map to store ContentVersion ID + ContentVersion Rec
                Map<String,ContentVersion> mIds = new Map<String,ContentVersion>([SELECT Id, ContentDocumentId 
                                                                                  FROM ContentVersion 
                                                                                  WHERE Id  IN :mImageTagVer.values()]);
                
                // Loop for each Image
                for(String eachImgtag: mImageTagVer.keySet()){
                    
                    body = body.replace(eachImgtag,'<img src="sfdc://'+mIds.get(mImageTagVer.get(eachImgtag).Id).ContentDocumentId+'"></img>');
                    mDocIdImage.put(mIds.get(mImageTagVer.get(eachImgtag).Id).ContentDocumentId,eachImgtag);
                }
                jsonValues= JSON.serialize(mDocIdImage);
            }
            
            // Deallocating memory
            mDocIdImage.clear();
            mImageTagVer.clear();
            
            // Getting SI Details
            SC_SI_Service_Incident__c siRec = [Select id, Status__c, Customer_Advisory__c, Community_Post_Id__c  from SC_SI_Service_Incident__c where id =: recordId];
            FeedItem upsertFeedItem;
            
            // If Community_Post_Id__c is null then Insert Feed else Update Feed.
            upsertFeedItem = (buttonLabel=='Update Community Post') ? 
                new FeedItem(Id = siRec.Community_Post_Id__c,Body = body) :
            new FeedItem(Body = body,IsRichText = True,
                         NetworkScope = networkAndSpaceIds.get('Customer_Community_Network_ID'),
                         ParentId = networkAndSpaceIds.get('Service_Incident_Space_Id'),
                         Type='ContentPost');
            
            try{
                networkAndSpaceIds.clear();
                // Upserting Feed Item
                upsert upsertFeedItem;
                
                // Updating Service Incident
                siRec.Community_Post_Id__c = upsertFeedItem.Id;
                siRec.Validation_Override__c=true;
                siRec.TimeStamp_of_Community_post__c=system.now();
                siRec.Content_Reference_and_Document__c=jsonValues;
                update siRec;
                
                return 'Success';
            }
            catch(exception e){
                return 'Error while Syncing to Community : '+ e.getMessage();
            } 
            
        }
        
    } // End of Community class
    
    
    // ******************** Inner Class - 2 : For Add Case Functionality **************************************
    public without sharing class AddCasesFunctionality {
        
        // Method for Updating Case
        public String addCaseToSI(String siId,String caseId) {
            
            Case c = new Case(Id=caseId, Service_Incident__c = siId);
            try{
                update c;
                return 'Success';
                
            }catch(exception e){
                // if(e.getDmlStatusCode(0)!='FIELD_CUSTOM_VALIDATION_EXCEPTION') 
                return 'Error while Updating Case : '+ e.getMessage();
            } 
            
        }
        
        // Method for Validating Case
        public string validateCase(String siId,String caseId) {
            
            Case c = [Select Id,Service_Incident__c,Service_Incident__r.Name from Case where Id=: caseId];
            if(c.Service_Incident__c != null && c.Service_Incident__c != siId){
                return 'Already Linked Case';
            }
            else if(c.Service_Incident__c != null && c.Service_Incident__c == siId){
                return 'Duplicate';
            }
            else {
                // Update the Case
                return addCaseToSI(siId,caseId);
            }
            
            
        }
    }
    
    // ******************** Inner Class - 3 : For Transition Functionality **************************************
    Public class TransitionFunctionality{
        
        // Method for getting Current Shift
        public String getCurrentShiftDetails(){
            return SC_SI_TransitionHelper.getCurrentShiftDetails('Incident Management');
            
        }
        
        // Method to get wakeuptime based on target shift opted
        public  String wakeUpTimeMethod(String targetShiftTime)
        {
            String wakeUpTime = '';
            wakeUpTime = (targetShiftTime.equalsIgnoreCase('transition now')) ? String.valueOf(System.now().format()) : 
            String.ValueOf(SC_SI_TransitionHelper.getShiftDateTime(targetShiftTime,'Incident Management').format()) ;
            
            return wakeUpTime;
            
        }
        
        
        // Method to create transition record
        public String saveTransition(String currentRecId, String notes, String currentShift, String newShift,
                                     String wakeUpTime, Id suggestedBIL, Id previousOwner){     
                                         
                                         // For Updating SI rec
                                         SC_SI_Service_Incident__c updateSIRec = new SC_SI_Service_Incident__c(
                                             ID=currentRecId, Validation_Override__c = true);
                                         updateSIRec.OwnerId = (newShift == 'Transition Now') ?
                                             [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE' and Type = 'Queue'].Id : 
                                         [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue'].Id;
                                         
                                         // For Creating Transition Record
                                         SC_SI_Transition_Request__c insertTransition= new SC_SI_Transition_Request__c();
                                         insertTransition.SC_SI_Service_Incident__c = currentRecId;
                                         insertTransition.SC_SI_Notes__c = notes;
                                         insertTransition.SC_SI_Previous_Owner__c = previousOwner;
                                         insertTransition.SC_SI_Previous_Shift__c = currentShift;
                                         insertTransition.SC_SI_Target_Shift__c = newShift;
                                         insertTransition.SC_SI_Future_Trigger_Time__c = Datetime.parse(wakeUpTime);
                                         insertTransition.SC_SI_Suggested_BIL__c = suggestedBIL; 
                                         insertTransition.SC_SI_Completed__c = (newShift == 'Transition Now') ? true : false;
                                         insertTransition.SC_SI_Completed_Date__c = (newShift == 'Transition Now') ? Datetime.parse(wakeUpTime) : null;
                                         
                                         try{
                                             
                                             Update updateSIRec;
                                             insert insertTransition;
                                             return 'Success';
                                             
                                         }catch(exception e){
                                             return 'Error while Creating Transition : '+ e.getMessage();
                                         } 
                                         
                                         
                                     }
        
    } // End OF Transition Class 
    
    // ******************** Inner Class - 4 : For DeLink Case Functionality **************************************
    Public class deLinkCaseFunctionality{
        
        // Method to get all Cases
        public string fetchAllRelatedCases(String SIrecordId){
            // Changes by Sheena for ESESP-5433: Excluded RCA Cases from showing up under Impaced Cases on SI
            return JSON.serialize([Select id,AKAM_Case_Ref__c,AKAM_Case_ID__c,AccountId,Account.Name,Support_Level__c,
                                   Customer_Tier__c,Case_Prod_Name__c, Case_Product__c  ,Subject,AKAM_Created_Date__c,
                                   Status,Case_Owner_Name__c,OwnerId,Case_Linked_Date__c, Service_Incident__c,
                                   Service_Incident__r.Name  
                                   from Case 
                                   where Service_Incident__c=: SIrecordId and RecordType.Name != 'RCA Request']);
        }
        
        // Method to Update case
        public String deLinkSIRecords(String CaserecordId){ 
            
            Case caseToUpdate = new Case(Id=CaserecordId, Service_Incident__c=null);
            try{
                update caseToUpdate;
                return 'Success';
            }
            catch(DmlException ex)
            {
                return 'Error while Delinking the Case: ' + ex.getMessage();
            }
            
        }
        
    } // End of DeLink Case Class SC_SI_ChartController
    
    // ******************** Inner Class - 5 : For Account Chart Functionality **************************************
    Public class AccountChartFunctionality{
        
        // Method for Preparing Data for Account Chart
        public Map<string, integer> getChartMap(String SIrecId){
            
            // Map to Store Account Tier Name + Count
            Map<string, integer> tierName_countMap = new Map<string, integer>{'A+' => 0, 'A' => 0, 'B' => 0,'C' => 0,'D' => 0};  
                
                // Aggregate Query on Impacted Account
                AggregateResult[] groupedResults = [select Account_Name__r.Customer_Tier__c Tier, count(id) 
                                                    from SC_SI_Impacted_Account__c 
                                                    where Service_Incident__c = :SIrecId and Account_Name__r.Customer_Tier__c != null 
                                                    group by Account_Name__r.Customer_Tier__c];
            
            // Iterate the Result
            for (AggregateResult ar : groupedResults)  {
                
                tierName_countMap.put(string.valueOf(ar.get('Tier')), Integer.valueOf(ar.get('expr0')));
            }
            return tierName_countMap;
        }
    } // End Of Account Chart  Class
    
    // ******************** Inner Class - 6 : Adding Impacted Products Functionality **************************************
    Public class AddProductFunctionality{
        
        
        // Fetching the entire Impacted Products Grid
        Public list<productWrapper> getGridData(){
            
            //Map to store parent Product Id and modules
            map<string,list<EB_Product__c>> mModules = new map<string,list<EB_Product__c>>();
            //Map to store parent Module Id and submodules
            map<string,list<EB_Product__c>> mSubModules = new map<string,list<EB_Product__c>>();
            // Main wrapper for all products, modules and submoduels
            List<productWrapper> mainWrap = new List<productWrapper>();
            // Product wrapper
            productWrapper pWrap;
            // Module wrapper
            Items mWrap;
            // Submodule wrapper
            Items smWrap;
            // List of modules for a product
            List<Items> pItems;
            // List of submodules for a product
            List<Items> mItems;
            
            
            // Looping on the EB Products and adding values in the map 
            for(EB_Product__c prod: [Select Id,EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductId__c !='' and EB_ParentId__c!='']){
                //For Submodules
                if(prod.EB_ProductType__c=='Submodule' && prod.EB_ParentId__c!=''){
                    if(!mSubModules.containsKey(prod.EB_ParentId__c)){
                        mSubModules.put(prod.EB_ParentId__c, new List<EB_Product__c>());    
                    }
                    mSubModules.get(prod.EB_ParentId__c).add(prod); 
                }
                
                // For Modules
                if(prod.EB_ProductType__c=='Module' && prod.EB_ParentId__c!=''){
                    if(!mModules.containsKey(prod.EB_ParentId__c)){
                        mModules.put(prod.EB_ParentId__c, new List<EB_Product__c>());    
                    }
                    mModules.get(prod.EB_ParentId__c).add(prod);
                } 
                
            }
            
            
            // Logic to make the product structure 
            for(EB_Product__c prod: [Select Id,EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Product'  and EB_ProductId__c !='' ])
            {
                // Adding Products in the wrapper
                pWrap = new productWrapper();
                pWrap.name=prod.Product_Name__c;
                pWrap.productId=prod.EB_ProductId__c;
                pWrap.entitledId=prod.id;
                pItems = new List<Items>();
                
                // Checking if the modules exist for the product
                if(mModules.keySet().contains(prod.EB_ProductId__c)){
                    
                    // Adding Modules in the wrapper
                    for(EB_Product__c mod: mModules.get(prod.EB_ProductId__c)){
                        mWrap = new Items();
                        mWrap.name=mod.Product_Name__c;
                        mWrap.productId=mod.EB_ProductId__c;
                        mWrap.entitledId=mod.id;
                        mWrap.parentProductName=prod.Product_Name__c;
                        mWrap.parentProdId=prod.EB_ProductId__c;
                        
                        
                        mItems = new List<Items>();
                        // Checking if the submodules exist for the module
                        if(mSubModules.keySet().contains(mod.EB_ProductId__c)){
                            // Adding Submodules in the wrapper
                            for(EB_Product__c subMod: mSubModules.get(mod.EB_ProductId__c)){
                                smWrap = new Items();
                                smWrap.name=subMod.Product_Name__c;
                                smWrap.productId=subMod.EB_ProductId__c;
                                smWrap.entitledId=subMod.id;
                                smWrap.parentProductName=prod.Product_Name__c;
                                smWrap.parentProdId=prod.EB_ProductId__c;
                                smWrap.parentModuleName=mod.Product_Name__c;
                                smWrap.parentModProdId=mod.EB_ProductId__c;
                                mItems.add(smWrap);
                            }
                            
                        }
                        mWrap.items =  mItems;  
                        pItems.add(mWrap);
                    }
                }
                pWrap.items= pItems;  
                mainWrap.add(pWrap);
            }
            return mainWrap;
        }
        
        // Method to create Impacted Products' records
        Public String saveImpactedProducts(String IncidentId, list<Items> prodWrap){
            
            // Set of Entitled/EB Product Ids
            set<Id> existingEntitledIds = new set<Id>();
            // List of Impacted Products to be created
            List<SC_SI_Impacted_Product__c> ImpactProdList = new List<SC_SI_Impacted_Product__c>();
            // List of existing Impacted Products on the Incident
            List<SC_SI_Impacted_Product__c> existingImpactedProds = [Select Product_Name__c from SC_SI_Impacted_Product__c where Service_Incident__c =: IncidentId];
            SC_SI_Impacted_Product__c impactedProd;
            // Adding the Entitled Id in the Set
            for(SC_SI_Impacted_Product__c prod: existingImpactedProds){
                existingEntitledIds.add(prod.Product_Name__c);
            }
            
            // Creating Impacted Product records
            for(Items eachProduct: prodWrap){
                // Checking if the product already exists
                if(!existingEntitledIds.contains(eachProduct.entitledId)){
                    
                    impactedProd = new SC_SI_Impacted_Product__c();
                    
                    // Checking if the selected record is of type Product
                    if( eachProduct.parentModProdId == null && eachProduct.parentProdId == null){
                        impactedProd.Product_Name__c = eachProduct.entitledId;
                        impactedProd.ParentProductName__c = eachProduct.name;
                        impactedProd.Service_Incident__c = IncidentId;
                    }
                    // Checking if the selected record is of type Module
                    if(eachProduct.parentModProdId == null && eachProduct.parentProdId != null){
                        impactedProd.ParentProductName__c = eachProduct.parentProductName;
                        impactedProd.Product_Name__c  = eachProduct.entitledId;
                        impactedProd.Service_Incident__c = IncidentId;
                        impactedProd.ParentModuleName__c = eachProduct.Name;
                    }
                    
                    // Checking if the selected record is of type Submodule
                    if(eachProduct.parentModProdId != null && eachProduct.parentProdId != null){
                        impactedProd.ParentProductName__c = eachProduct.parentProductName;
                        impactedProd.Product_Name__c  = eachProduct.entitledId;
                        impactedProd.Service_Incident__c = IncidentId;
                        impactedProd.ParentModuleName__c=eachProduct.parentModuleName;
                        impactedProd.SubModuleName__c=eachProduct.Name;
                    }
                    ImpactProdList.add(impactedProd);
                }
            }
            
            // Inserting the list
            if(ImpactProdList.size()>0){
                try{
                    insert ImpactProdList;
                    return 'Success';
                }
                catch(exception e){
                    return 'Error while Adding the Impacted Products: ' + e.getMessage(); 
                }
            }
            else{
                return 'The selected products are already added.';
            }
            
        }
        
    }
}