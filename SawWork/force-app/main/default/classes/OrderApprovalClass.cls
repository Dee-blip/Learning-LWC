/*** 
    OrderApprovalClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class implements the logic for :
                    - Order Approval creation (from "Create Order Approval" Butotn on the Oppty detail page).
                    - Updating the "Record Type" according to values entered in the "Approvals Required".
                    - Updating the Owners according to the "Record Type".
                    - Promoting "CCG#"","Deal Desk#" and "Legal#" fields from "Order Approval" to the realted "Opportunity".
                    - Updating Task when "Task.RecordType" = "Order Approval Activity"
                    - Updating Order when "Task.RecordType" = "Order Approval Activity"
                    - Send a notification email to the "Task.Created By" User when the "Status/Owner" of the Task changes.
                    
    @History
    --Developer           --Date            --Change
    Karteek Kumar M       16/02/10          Default "Task.Reminder" checkbox through "URL" and on "Save".
    Karteek Kumar M       17/02/10          Incorporated new field "OrderApproval.CCG_Owner__c".
    Karteek Kumar M       18/02/10          Optimized to reduce SOQL Queries no.
    Karteek Kumar M       22/02/10          Send Emails when "Order Approval Task.Status/Owner" changes.
                                            Optimized by Adding more static variables and Init functions
    Karteek Kumar M       04/03/10          Incorporated ADS functionality into the existing CDN System
    Karteek Kumar M       10/03/10          Promoting oa.DD_CCG_Expiration_Date__c and opp.CCG_Approved_Date__c from Order Approval to Opportunity.
    Karteek Kumar M       17/03/10          Treating 'ADS Account Manager' as a ADS Deal Desk Profile. ( updated from 'Acerno' to 'ADS' as part of CR 734005 )
    Karteek Kumar M       17/03/10          Treating 'ADS Sales Manager' as a ADS Deal Desk Profile.    ( updated from 'Acerno' to 'ADS' as part of CR 734005 )
    Karteek Kumar M       25/03/10          Put some error handling around making sure "Order Approval Activity.Related to" is an Order Approval
    Karteek Kumar M       29/03/10          Added firstRunFlag logic to all the "Update" functions.
    Karteek Kumar M       06/04/10          Removed "Oppty.Type = Churn" check for Create Order Approval
                                            Removed firstRunLogic from UpdateRecType and DefaultOwner funcs.
    Karteek Kumar M       12/04/10          While initializing Users, search by Alias and not Full Name.
                                            This is because, Full Name is not consistent over Locale.
    Karteek Kumar M       26/05/10          CR 610624  When OA.DD # is updated update Oppty.DD # (vs Oppty.ADS DD #) for ADS OA
    Karteek Kumar M       27/05/10          Changes alias for lower case to upper case for ADS Queues.
    Karteek Kumar M       28/06/10          CR 568963  Yitong Data Visibility
                                            Making the relationship between Opportunity and Order Approval a "Master-Detail".
                                            Removed the function Update_CCG_Owner().
    Karteek Kumar M       08/07/10          CR 700534  Order Approval
                                            Removing check for existing Order, because this will be handled in the OnClick JavaScript.
    Mohammed Ali          09/07/10          Testing Perforce Process.
    Karteek Kumar M       13/07/10          CR 692956  Create button Order Form on opportunity
                                            Create_OrderApproval() now returns "Boolean:String"
    Karteek Kumar M       13/07/10          CR 694234  China CDN, TAPP, EdgeSuite transition team, PS, Aproval Process
                                            Updated Create_Task() to default the following tasks for China CDN, TAPP, EdgeSuite transition team, PS, Aproval Process
                                                - the AssignedTo of the new task to the Oppty Owner
                                                - Subject of the new task to "XXXXX Approval Required for Order Approval : XXXXX"
    Karteek Kumar M       14/07/10          Overloading function Create_OrderApproval()
    Karteek Kumar M       04/08/10          CR 694234 China CDN, TAPP, EdgeSuite transition team, PS, Aproval Process
                                            Update Requirements : 
                                            The new approval buttons should now have default owners as following
                                            •       PS --> Oppty.Owner 
                                            •       TAPP and ES Transition --> Product Ops Queue, 
                                            •       CDN – New user like CDN Queue
                                            Send an email to the Task Owner if it is a PS Approval Activity
                                            - Added a new function for this : SendOrderApprovalTaskCreationNotifications()
    Karteek Kumar M       10/08/10          SendOrderApprovalTaskCreationNotifications function sends email when Task_Type is 'PS' or 'China CDN' or 'TAPP' or 'EdgeSuite Transition'
                                            Renamed CDN Queue to China Queue
    Ali KM                23/08/10          CR 734005 Change profile names and supporting code/WF/FV where appropriate from Acerno to ADS
                                            - Replacing 'Acerno' keyword with 'ADS' part of cleanup efforts.
    Karteek Kumar M       20/09/10          CR 694234 China CDN, EdgeSuite Transition , PS Approval Process
                                            Update OrderApproval.Approvals Required when Special Approval Tasks are created - similar to CCG, Deal Desk and Legal.
    Karteek Kumar M       18/10/10          CR 837498 Change the default user for Edgesuite Transition Tasks
                                            Edgesuite Transition tasks are now assigned to Edgesuite Transition Queue user. 
    Ali KM                20/10/10          CR 833205 Times Reviewed field in Order Approval
                                            - Initializing Order Approval.Validation Override to true on OA inserts. 
                                            - To avoid exception in new CCG validation for making Times Reviewed field mandatory.
    Ali KM                20/10/10          CR 833205 Times Reviewed field in Order Approval
                                            - Reverting Code change for this CR, as this is achieved in Validation Rule - Order Approval.Times_Reviewed_is_mandatory    
    Vinayendra T N        12/11/10          CR 844778 Order Approval Enhancements (see attached)
                                            - When order approval is created, CCG status is set to Open
                                            - When task owner is changed for CCG/DD/Legal/Prod ops/ES/China CDN corresponding status in order approval is set to 'In Process'
    Vinayendra T N        12/11/10          CR 867611 update Order Approval CCG Owner when CCG task Owner is updated.(Bug Fix)
                                            - Bug fixed
    Vinayendra T N         6/12/10          CR 878780 Email should be sent if the Task assigned to is Sales-Channel Rep
                                            Made changes to class SendOrderApprovalActivityEmails
                                            - If task Owner has profile Like Sales% and a task is assigned to him. A email will be sent 
    Vinayendra T N        28/12/10          CR 837723 Use custom settings on Order Approval class
                                            - Moved frequently used hard coded values to Custom Settings                            
    Ali KM                17/08/11          CR 1210198 Internal - Remove fields from Contract: (Contract Merge Header) that are no longer used
                                            - Removed code that was updating field - Merge_Contract_Header__c.X1Click_Extension_Status__c, thats no longer used.    
    Ali KM                12/Jan/12         CR 1445842 Salesforce field enhancement request for team Sales Productivity
                                            - Added a new field 'SA Owner on Opportunity', synching it everytime SA Owner on Order Approval is updated.
    Lisha Murthy          06/Jan/12         CR 1498591: Create new DD# Modified field
                                            - Added a new function to set the DD# and DD modified at field when DD Status is changed to Completed.
    Sujan                 17/Apr/14         CR 2613504 - Follow up CR to SA# locking the Agreement                                                                                                                                                              
    Ali KM                16/Aug/15         QTOO-2112 - Added code to handle exception on Agreement update gracefully.
    Hitesh Chawda         26/Jan/2016       CR 3286341 - Disqualify/auto-reject Deal Desk approval requests for small deals

    Shubham Richhariya    25/Jul/2017       CR 3807291 - Updated CREATE_TASK method ,added Create_Task_GetPageReference method


*/   

global class OrderApprovalClass
{
    //public static Order_approval_class_settings__c customSettings = Order_approval_class_settings__c.getInstance('v1.0'); //SFDC-2304
    public static Map<string,string> gsmMap = GsmUtilClass.getGsmSettingKeyValue('OA_'); //SFDC-2304
    private static Boolean oaTaskRecTypeInitialized = false;
    private static Boolean oaUsersInitialized = false;
    private static Boolean oaProfilesInitialized = false;
    private static Boolean oaRecordTypesInitialized = false;
    private static Boolean oaTaskNotificationTemplatesInitialized = false;
    private static Boolean oppRecordTypesInitialized = false;
    private static Id oaTaskRecTypeId ;
    private static User prodOpsQueueUsr;
    private static User cdnQueueUser;
    private static User edgeSuiteQueueUsr;
    private static User dealDeskQueueUsr;
    private static User legalQueueUsr;
    private static User ccgQueueUsr;
    private static User ads_dealDeskQueueUsr;
    private static User ads_legalQueueUsr;
    private static User ads_ccgQueueUsr;            
    private static User currentUsr;
    private static Profile currentUsrProfile;
    private static Id ddesk_prId;
    private static Id legal_prId;
    private static Set<Id> ads_ddesk_prIds;
    private static Set<Id> ccg_prIds;
    private static Id oppAkamaiRecTypeId;
    // CR 734005 update start
    // private static Id oppAcernoRecTypeId;
    private static Id oppAdsRecTypeId;
    // CR 734005 update end     
    //private static Map<String,Id> oaRecTypeMap; 
    private static string oaTaskChangeTemplate;
    private static string oaTaskCreateTemplate;
    public static Boolean SendOrderApprovalActivityEmailsfirstRunFlag = true;   
    public static Boolean UpdateOpptyFirstRunFlag = true;
    public static Boolean OrderApprovalActivity_UpdateOrderFirstRunFlag = true;
    public static Boolean Update_CCG_OwnerFirstRunFlag = true;
    public static Boolean OrderApprovalActivity_UpdateTaskFirstRunFlag = true;
    public static Boolean updateDealDeskDetailsFirstRunFlag = true;
    public static Boolean DealDeskActivity_UpdateTaskFirstRunFlag = true;
    /**
       InitAll()
       - Intiailizes all the static variables
       - Not Recommended
       - Returns true if Intialization was done, else returns false.
    */  
    /*public static Boolean InitAll()
    {
         // Dont intialize if already intialized
        if(oaTaskRecTypeInitialized && oaUsersInitialized && oaProfilesInitialized )
            return false;      
        oaTaskRecTypeInit();
        oaUsersInit();
        oaProfilesInit();
        return true;
    }*/  
    /**
       oaTaskRecTypeInit()
       - Get the Order Approval Task Record Type
       - Set oaTaskRecTypeInitialized to prevent duplicate calls.
       - Returns true if Intialization was done, else returns false.
    */
    //CR 2770464 - rsharma: Changing visibility
    /* SFDC-4178
    public static Boolean oaTaskRecTypeInit()
    {     // Dont intialize if already intialized
         if(oaTaskRecTypeInitialized)
            return false;
         // Get the Order Approval Task Record Type
         oaTaskRecTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(gsmMap.get('OA_order_approval_record_type_name')).getRecordTypeId(); //SFDC-2304
         system.assertNotEquals(oaTaskRecTypeId,null);
         oaTaskRecTypeInitialized = true;
         return true;
    }
    */
    /**
       oaUsersInit()
       - Get the Queue User and the Current User Records
       - Set oaUsersInitialized to prevent duplicate calls.
       - Returns true if Intialization was done, else returns false.
    */  
   //CR 2770464 - rsharma: Changing visibility
   //SFDC-4178
   /*
    public static Boolean oaUsersInit()
    {
         // Dont intialize if already intialized
         if(oaUsersInitialized)
            return false;
         String currentUserId = Userinfo.getUserId();
         // Get the Queue User and the Current User Records
         for(User usr :[select Id, 
                               Alias, 
                               Name, 
                               Receive_email_when_OA_Status_changes__c, 
                               Receive_email_when_OA_Owner_changes__c 
                        from User 
                        where Alias = :gsmMap.get('OA_ccg_queue') or 
                              Alias = :gsmMap.get('OA_Deal_desk_queue') or 
                              Alias = :gsmMap.get('OA_legal_queue') or 
                              Alias = :gsmMap.get('OA_ads_ccg_queue') or 
                              Alias = :gsmMap.get('OA_ads_deal_desk_queue') or 
                              Alias = :gsmMap.get('OA_ads_legal_queue') or                        
                              Alias = :gsmMap.get('OA_Product_ops_queue') or 
                              Alias = :gsmMap.get('OA_china_queue') or
                              Alias = :gsmMap.get('OA_edge_queue') or
                              Id=:currentUserId]) //SFDC-2304
         {
            if(usr.Alias == gsmMap.get('OA_ccg_queue')) //SFDC-2304
                ccgQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_Deal_desk_queue')) //SFDC-2304
                dealDeskQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_legal_queue')) //SFDC-2304
                legalQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_ads_ccg_queue')) //SFDC-2304
                ads_ccgQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_ads_deal_desk_queue')) //SFDC-2304
                ads_dealDeskQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_ads_legal_queue')) //SFDC-2304
                ads_legalQueueUsr = usr;                
            else if(usr.Alias ==  gsmMap.get('OA_Product_ops_queue')) //SFDC-2304
                prodOpsQueueUsr = usr;
            else if(usr.Alias ==  gsmMap.get('OA_china_queue')) //SFDC-2304
                cdnQueueUser = usr;
            else if(usr.Alias ==  gsmMap.get('OA_edge_queue')) //SFDC-2304
                edgeSuiteQueueUsr = usr;
            else if(usr.Id == currentUserId)
                currentUsr = usr;
         }
         system.assertNotEquals(ccgQueueUsr,null);      
         system.assertNotEquals(dealDeskQueueUsr,null);
         system.assertNotEquals(legalQueueUsr,null);
         system.assertNotEquals(ads_ccgQueueUsr,null);      
         system.assertNotEquals(ads_dealDeskQueueUsr,null);
         system.assertNotEquals(ads_legalQueueUsr,null);         
         system.assertNotEquals(prodOpsQueueUsr,null);
         system.assertNotEquals(cdnQueueUser,null);
         system.assertNotEquals(edgeSuiteQueueUsr,null);             
         system.assertNotEquals(currentUsr,null);  
         oaUsersInitialized = true;
         return true;
    }
    */
    /**
       oaProfilesInit()
       - Get the Deal Desk, Legal and CCG profile Ids
       - Set oaProfilesInitialized to prevent duplicate calls.
       - Returns true if Intialization was done, else returns false.
    */  
    //CR 2770464 - rsharma: Changing visibility

    //SFDC - 4178
    /*
    public static Boolean oaProfilesInit()
    {
        // Dont intialize if already intialized
        if(oaProfilesInitialized)
            return false;
        // Get the Deal Desk, Legal and CCG profile Ids
        ccg_prIds = new Set<Id>();
        string likeCCG='%'+gsmMap.get('OA_CCG_profile')+'%'; //SFDC-2304
        ads_ddesk_prIds = new Set<Id>();
        for(Profile pr:[select Id,
                               Name 
                        from Profile 
                        where Name=:gsmMap.get('OA_deal_desk_profile') or 
                              Name=:gsmMap.get('OA_legal_profile') or 
                              Name like :likeCCG or 
                              // CR 734005 update start
                              // Name = 'Acerno Sales Manager'
                              Name = :gsmMap.get('OA_ADS_Sales_Manager_profile') 
                              // CR 734005 update end 
                              or Id=:Userinfo.getProfileId()]) //SFDC-2304
        {
            if(pr.Name == gsmMap.get('OA_deal_desk_profile')) //SFDC-2304
                ddesk_prId = pr.Id;
            else if(pr.Name == gsmMap.get('OA_legal_profile')) //SFDC-2304
                legal_prId = pr.Id;
            else if(pr.Name.contains(gsmMap.get('OA_CCG_profile'))) //SFDC-2304
                ccg_prIds.add(pr.Id);       
            // CR 734005 update start
            // else if(pr.Name == 'Acerno Sales Manager')   // ADS Deal Desk
            else if(pr.Name == gsmMap.get('OA_ADS_Sales_Manager_profile') )    //SFDC-2304 // ADS Deal Desk
            // CR 734005 update end 
                ads_ddesk_prIds.add(pr.Id);         // Using a Set, so we can accomodate more such profiles in the future.
            // Current User Profile
            if(pr.Id == Userinfo.getProfileId())
                currentUsrProfile = pr;
        }
        system.assertNotEquals(ddesk_prId,null);
        system.assertNotEquals(legal_prId,null);
        system.assertNotEquals(currentUsrProfile,null);
        system.assertEquals(ccg_prIds.size()>0,true);
        system.assertEquals(ads_ddesk_prIds.size()>0,true);
        oaProfilesInitialized = true;
        return true;
    }
    */
    // 3 methods removed to reduce the number of function calls
    /**
       Create_OrderApproval(Id p_OppId,String p_RecTypeId, String p_Stage, String p_GetField)
       - This function is called by the OnClick JavaScript for the "Create Order Approval" Button in the Opportunity detail page.
       - An "Order Approval" is created if the following criteria is met.
         -) An "Order Approval" for the "Opportunity" already exists.
         -) The "Opportunity.RecordType" is "Akamai Opportunity" 
       - A success message / error message is returned in` the form of a "Boolean:String", which is processed by the OnClick JavaScript.
    */  
    WebService static String Create_OrderApproval(Id p_OppId, String p_RecTypeId, String p_Stage, String p_GetField)
    {
        // Check if Order Approval Already exists
        Order_Approval__c existingOrderApproval;
        for(Order_Approval__c oa : [select Id,
                                           Order_Form_Url__c,
                                           Small_Deal__c
                                    from Order_Approval__c 
                                    where Associated_Opportunity__c=:p_OppId])
            existingOrderApproval = oa;
        if(existingOrderApproval != null)
        {
            if(p_GetField == 'Order_Form_Url__c')
                return '1:' + Momentum_Link__c.getInstance('Production').Link__c + existingOrderApproval.Order_Form_Url__c;
            else
                return '1:' + existingOrderApproval.Id;
        }
        // Initialize static variables  
        //oppAdsRecTypeId=gsmMap.get('OA_ADS_Record_Type_id'); //SFDC-2304
        //oppAkamaiRecTypeId=gsmMap.get('OA_Akamai_Opportunity_id'); //SFDC-2304
        //String closedOpptyRecordTypeId = GsmUtilClass.getGSMSettingValue('Oppty_Closed_Oppty_Rec_Type_Id'); //SFDC-3261
        
        // CR 734005 update start
        // system.assertNotEquals(oppAcernoRecTypeId,null);
        //system.assertNotEquals(oppAdsRecTypeId,null);
        // CR 734005 update end
        //system.assertNotEquals(oppAkamaiRecTypeId,null);        
        
        //oaProfilesInit();       
        // -------------- Errors ---------------------
        // Check if the criteria is met.    
        // CR 734005 update start
        // if(p_RecTypeId == oppAcernoRecTypeId && (!currentUsrProfile.Name.contains('Acerno') && !currentUsrProfile.Name.contains('ADS')) && currentUsrProfile.Name!='System Administrator')
        //if(p_RecTypeId == oppAdsRecTypeId && (!currentUsrProfile.Name.contains('ADS')) && currentUsrProfile.Name!='System Administrator')
        // CR 734005 update end
        //    return '0:You do not have the sufficient previliges to create an ADS Order Approval.';
        // CR 734005 update start
        // if(p_RecTypeId == oppAkamaiRecTypeId && currentUsrProfile.Name.contains('Acerno') && currentUsrProfile.Name!='System Administrator')
        //if(p_RecTypeId == oppAkamaiRecTypeId && currentUsrProfile.Name.contains('ADS') && currentUsrProfile.Name!='System Administrator')
        // CR 734005 update end
        //    return '0:You do not have the sufficient previliges to create a CDN Order Approval.';       
        //if([select Id from Order_Approval__c where Associated_Opportunity__c = :p_oppId].size()>0)
            //return 'An Order Approval for this Opportunity already exists.';
        //if(p_Stage.contains('Closed'))
        //    return '0:Order Approval cannot be created for Closed Opportunities.';  
        // ------------- Success ----------------------
        // Create the order approval with Owner defaulted to "CCG Queue" and RecordType defaulted to "CCG Only Approval".        
        Order_Approval__c newOrder = new Order_Approval__c();
        Opportunity opp = new Opportunity(id = p_OppId);
        newOrder.Associated_Opportunity__c = p_oppId;
        newOrder.CurrencyIsoCode = opp.CurrencyIsoCode;
        newOrder.CCG_Owner__c = opp.OwnerId;
        newOrder.CCG_Status__c='Not Started';
        newOrder.RecordTypeId = Order_Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval').getRecordTypeId();
        //CR 1410
        newOrder.Unique_Identier__c = p_oppId;
        //CR 844778 Make CCG status default Open
        // CR 734005 update start
        // if(p_RecTypeId == oppAcernoRecTypeId)
        //if(p_RecTypeId == oppAdsRecTypeId)
        // CR 734005 update end
        //    newOrder.Type__c =  gsmMap.get('OA_ADS_type'); //SFDC-2304
        //else if(p_RecTypeId == oppAkamaiRecTypeId || p_RecTypeId == closedOpptyRecordTypeId)
        //    newOrder.Type__c =  gsmMap.get('OA_CDN_type'); //SFDC-2304
        try
        {
            insert newOrder;
        }
        catch(Exception e)
        {
            //System.debug('Exception is:::'+e);
            if(e.getMessage().containsIgnoreCase('DUPLICATE_VALUE')){
                Order_Approval__c oa = [select Id from Order_Approval__c where Associated_Opportunity__c=:p_OppId];
                return '1:' + oa.Id;
            }

            return e.getMessage();
        }
        if(p_GetField == 'Order_Form_Url__c')
        {
            // Refresh New Order Approval
            for(Order_Approval__c oa : [select Id, Order_Form_Url__c from Order_Approval__c where Id = :newOrder.Id])
                newOrder = oa;
            return '1:' + Momentum_Link__c.getInstance('Production').Link__c + newOrder.Order_Form_Url__c;
        }
        else
            return '1:' + newOrder.Id;// This String is used in the "Create Order Approval" button, to check if the Order has been created.
    }
    //Saket More
    //SFDC-4178
    public static void CreateOrderApproval(List<opportunity> opp){

        List<Order_Approval__c> orderApproval = new List<Order_Approval__c>();
        List<Order_Approval__c> orderApprovalCaseCreation = new List<Order_Approval__c>();
        
        for(opportunity opp1 : opp){
            Order_Approval__c oa = new Order_Approval__c();
            oa.CCG_Owner__c = opp1.OwnerId;
            oa.Associated_Opportunity__c = opp1.id;
            oa.Unique_Identier__c = opp1.id;
            oa.CurrencyIsoCode = opp1.CurrencyIsoCode;
            oa.CCG_Status__c = 'Not Started';
            oa.RecordTypeId = Order_Approval__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval').getRecordTypeId();
            orderApproval.add(oa);
        }

            if(orderApproval.size()>0){

            GsmUtilClass.doDatabaseInsert(orderApproval,'OrderApprovalClass','CreateOrderApproval',True);
            CreateCases(orderApproval);
        }


    }

    //Saket More
    //SFDC-4178

    public static void CreateCases(List<Order_Approval__c> OAList){

        //System.debug('OrderApprovallist:'+OAList[0].Associated_Opportunity__r.Opportunity_Type__c);
        //System.debug('OrderApprovallist:'+OAList[0].Associated_Opportunity__r.Auto_Renewal__c);
        //System.debug('OrderApprovallist1:'+OAList);

        List<Case> caseListToInsert = new List<Case>();
        String mulesoftIntegrationIds = GsmUtilClass.getGSMSettingValue('ProfileIdMulesoftIntegration');
        List<String> OpportunityType = GsmUtilClass.getGSMSettingValue('Opportunity_Type_From_Dash').split(';');
        System.debug('OpportunityType:'+OpportunityType);
        Id CaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        List<order_approval__c> orderApprovalList = new List<order_approval__c>();
        //SFDC-8146
        Id adminRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Administrative Opportunity').getRecordTypeId();


        for(Order_Approval__c oa : [Select id, CCG_Status__c, Associated_Opportunity__c,Associated_Opportunity__r.AccountId ,Associated_Opportunity__r.Opportunity_Type__c, Associated_Opportunity__r.Auto_Renewal__c ,Associated_Opportunity__r.createdby.alias, Associated_Opportunity__r.createdby.ProfileId, Associated_Opportunity__r.Bed_Change__c, Associated_Opportunity__r.Contract_Extension__c,Associated_Opportunity__r.Partner_Involved__c, Associated_Opportunity__r.Source__c,Associated_Opportunity__r.StageName,Associated_Opportunity__r.oc_source__c,Associated_Opportunity__r.RecordTypeId from Order_Approval__c where Associated_Opportunity__r.Opportunity_Type__c IN :OpportunityType and id IN :OAList]){
                Case cs = new Case();
                cs.Order_Approval__c = oa.id;
                cs.Opportunity__c = oa.Associated_Opportunity__c;
                cs.AccountId = oa.Associated_Opportunity__r.AccountId;
                cs.RecordTypeId = CaseRecordTypeId;
                cs.Status = 'Closed-Auto Approved';
                cs.Origin = 'Autogen';
                cs.Validation_Override__c = True;
                //cs.AutoClose__c = True;
                cs.AKAM_Closed_Date__c = datetime.now();
                cs.OwnerId = GsmUtilClass.getGSMSettingValue('OM_Queue');
                System.debug('Inside For Loop'+oa);
            if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Automated Purchase' && mulesoftIntegrationIds.contains(oa.Associated_Opportunity__r.createdby.ProfileId) && !(oa.Associated_Opportunity__r.RecordTypeId == adminRecTypeId && oa.Associated_Opportunity__r.oc_source__c == 'Marketplace')){             
                cs.Order_Type__c = 'In Addition';
                cs.Final_Approval_Notes__c = 'Online_Channel_Opportunity Automated Purchase - Auto-approved.';
                caseListToInsert.add(cs);
            }
            //SFDC-6398
            else if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Auto-Renewal' && oa.Associated_Opportunity__r.Auto_Renewal__c  == true && oa.Associated_Opportunity__r.StageName == '6. Signed' ){             
                cs.Order_Type__c = 'Auto Renewal';
                cs.Final_Approval_Notes__c = 'Auto_Renewal_Opportunity - Auto-approved.';
                caseListToInsert.add(cs);
            }

            else if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Automated Trial' && mulesoftIntegrationIds.contains(oa.Associated_Opportunity__r.createdby.ProfileId)){
                cs.Order_Type__c = 'Trial Order';
                cs.Final_Approval_Notes__c = 'Online_Channel_Opportunity Automated Trial - Auto-approved';
                caseListToInsert.add(cs);
                
            }

            else if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Contract Change' && mulesoftIntegrationIds.contains(oa.Associated_Opportunity__r.createdby.ProfileId)){        
                cs.Order_Type__c = 'Trial Order';
                cs.Final_Approval_Notes__c = 'Online_Channel_Opportunity Contract Change - Auto Approved';
                caseListToInsert.add(cs);
            }
                /*SFDC-6394
                Stop Auto-Creation of Auto-Approved case so that Opportunity does not surpass the gating criteria for stage 6. signed.
                else if(oa.Associated_Opportunity__r.Bed_Change__c){
                    cs.Final_Approval_Notes__c = 'Deferment of billing effective date - Auto Approved';
                    caseListToInsert.add(cs);
                    
                }
                else if(oa.Associated_Opportunity__r.Contract_Extension__c){
                    cs.Final_Approval_Notes__c = 'Contract Extension - Auto Approved';
                    caseListToInsert.add(cs);
                    
                }
                */
            else if(oa.Associated_Opportunity__r.Source__c == 'Azure Marketplace' ){
                System.debug('Inside Azure Marketplace'+oa.Associated_Opportunity__r.Source__c);
                System.debug('Inside Azure Marketplace type:'+oa.Associated_Opportunity__r.Opportunity_Type__c);
                cs.Final_Approval_Notes__c = 'AZURE Marketplace Automated Purchase - Auto-approved.';
                cs.Paper_Source__c = 'Azure Marketplace'; 
                if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Non-Renewal: Add-On')
                    cs.Order_Type__c = 'In Addition';
                else if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'New Logo')
                    cs.Order_Type__c = 'New Service Order';
                else if(oa.Associated_Opportunity__r.Opportunity_Type__c == 'Churn')
                    cs.Order_Type__c = 'Cancellation';
                
                caseListToInsert.add(cs);
                }
                System.debug('Case:'+cs);
        }
        if(caseListToInsert.size()>0){
                System.debug('Inside Case insertion:'+caseListToInsert);
                GsmUtilClass.doDatabaseInsert(caseListToInsert,'OrderApprovalClass','CreateCases',True);

                CreateApprovalDetails(caseListToInsert);
            }

        for(Case c : caseListToInsert){
            Order_Approval__c orderApp = new Order_Approval__c(id = c.Order_Approval__c);
            orderApp.CCG_Status__c = 'In Progress';
            orderApp.Validation_Override__c = true;
            orderApprovalList.add(orderApp);

        }
        if(orderApprovalList.size()>0){
                GsmUtilClass.doDatabaseUpdate(orderApprovalList,'OrderApprovalClass','CreateCases');
            }

    }

    //SFDC-6398 - Update existing OM case for auot approval ,create Approval request to auto close.
    public static void UpdateCases(List<Case> caseList){
        System.debug('UpdateCasesMethod:'+caseList);
        List<Case> caseListToUpdate = new List<Case>();
        Id CaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        List<Case> caseUpdateList= new List<Case>();
        List<Case> CreateApprovalDetailsforCase = new List<Case>();
        List<Id> UpdateApprovalDetailsforCase = new List<Id>();
        List<Approval_Details__c> UpdateApprovalDetail = new List<Approval_Details__c>();
        //List<Order_Approval__c> orderApprovalList= new List<Order_Approval__c>();
        for(Case autoCase : [Select Id,Status,Origin,Order_Type__c,Validation_Override__c,AKAM_Closed_Date__c,Final_Approval_Notes__c,Order_Approval__c,(select id, Approval_Status__c from Approval_Details__r ), AutoClose__c From Case Where RecordTypeId = :CaseRecordTypeId AND Id In :caseList])
        {
            System.debug('Inside For Update Cases');
            autoCase.Status = 'Closed-Auto Approved';
            autoCase.Validation_Override__c = True;
            autoCase.Customer_Segment_Order_Treatment__c = 'N/A';
            autoCase.AKAM_Closed_Date__c = datetime.now();
            autoCase.Final_Approval_Notes__c = 'Auto_Renewal_Opportunity - Auto-approved.';
            autoCase.Order_Type__c = 'Auto Renewal';

            //autoCase.AutoClose__c = True;
            caseUpdateList.add(autoCase);
            if(autoCase.Approval_Details__r.size() == 0){
                CreateApprovalDetailsforCase.add(autoCase);
            }
            else{
                List<Approval_Details__c> ApprovalDetail = autoCase.Approval_Details__r;
                for(Approval_Details__c approvaldetails : ApprovalDetail)
                    UpdateApprovalDetailsforCase.add(approvaldetails.id);
            }
        } 
        
        if(CreateApprovalDetailsforCase.size()>0){
            CreateApprovalDetails(caseUpdateList);
        }
        
        if(UpdateApprovalDetailsforCase.size()>0){
            for(Id ADId : UpdateApprovalDetailsforCase){
                Approval_Details__c approvalDetailRecord = new Approval_Details__c(id = ADId);
                approvalDetailRecord.Approval_Status__c = 'Auto-approved';
                approvalDetailRecord.AKAM_Approved_Date__c = datetime.now();
                approvalDetailRecord.Validation_Override__c = True;
                UpdateApprovalDetail.add(approvalDetailRecord);
            }
        }
        
        if(UpdateApprovalDetail.size()>0){
            GsmUtilClass.doDatabaseUpdate(UpdateApprovalDetail,'OrderApprovalClass','UpdateCases-Update Approval detail');
        }
        
        if(caseUpdateList.size()>0){
                System.debug('Inside Case update:'+caseUpdateList);
                GsmUtilClass.doDatabaseUpdate(caseUpdateList,'OrderApprovalClass','UpdateCases');
                //CreateApprovalDetails(caseUpdateList);
            }
        
        
        /*
        for(Case c : caseUpdateList){
            Order_Approval__c orderApp = new Order_Approval__c(id = c.Order_Approval__c);
            orderApp.CCG_Status__c = 'In Progress';
            orderApp.Validation_Override__c = true;
            orderApprovalList.add(orderApp);

        }
        if(orderApprovalList.size()>0){
                GsmUtilClass.doDatabaseUpdate(orderApprovalList,'OrderApprovalClass','UpdateCases');
            }
        */

    }
    
    
    //Saket More
    //SFDC-4178

    public static void CreateApprovalDetails(List<Case> CaseList){
        System.debug('Inside Approval Details Method');
        List<Approval_Details__c> approvalDetailsList = new List<Approval_Details__c>();
        String mulesoftIntegrationIds = GsmUtilClass.getGSMSettingValue('ProfileIdMulesoftIntegration');
        for(Case cs : [Select id,Opportunity__c,Opportunity__r.Opportunity_Type__c, Order_Approval__c, Opportunity__r.createdby.alias, Opportunity__r.createdby.ProfileId, Opportunity__r.Bed_Change__c, Opportunity__r.Contract_Extension__c from Case where id IN :CaseList]){
            
            if(cs.Opportunity__r.Opportunity_Type__c == 'Automated Purchase' && mulesoftIntegrationIds.contains(cs.Opportunity__r.createdby.ProfileId)){
                approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'Automated Purchase Marketplace','Auto-approved','Online_Channel_Opportunity','Automated Purchase - Auto-approved'));                 
                
            }

            else if(cs.Opportunity__r.Opportunity_Type__c == 'Automated Trial' && mulesoftIntegrationIds.contains(cs.Opportunity__r.createdby.ProfileId)){
                approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'Automated Trial BA/Marketplace','Auto-approved','Online_Channel_Opportunity','Automated Trial - Auto-approved'));                 
                
            }

            else if(cs.Opportunity__r.Opportunity_Type__c == 'Contract Change' && mulesoftIntegrationIds.contains(cs.Opportunity__r.createdby.ProfileId)){
                    approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'Contract Change BA/Marketplace','Auto-approved','Online_Channel_Opportunity','Contract Change - Auto-approved'));                 
                
                }
                /*SFDC-6394
                Not creating approval details record since we are not creating auto-approved case.
                else if(cs.Opportunity__r.Bed_Change__c){
                    approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'BED Deferment','Auto-approved','Auto-BED Deferment','Deferment of billing effective date - Auto Approved'));                 
                
                }
                else if(cs.Opportunity__r.Contract_Extension__c){
                    approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'Extend Contract','Auto-approved','Auto-Extend Contract','Contract Extension - Auto Approved'));                 
                
                }
                */
            else if(cs.Opportunity__r.Opportunity_Type__c == 'Non-Renewal: Add-On' || cs.Opportunity__r.Opportunity_Type__c == 'New Logo' || cs.Opportunity__r.Opportunity_Type__c == 'Churn'){
                approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'AZURE Marketplace Automated Purchase','Auto-approved','Online_Channel_Opportunity','AZURE Marketplace Automated Purchase - Auto-approved.'));                 
            }
            else if(cs.Opportunity__r.Opportunity_Type__c == 'Auto-Renewal'){
                approvalDetailsList.add(CreateApprovalDetailsReference(cs, 'Auto-Renwal Opportunity','Auto-approved','Auto_Renewal_Opportunity','Auto_Renewal_Opportunity - Auto-approved.'));                 
            }

        }
        if(approvalDetailsList.size()>0){
            GsmUtilClass.doDatabaseInsert(approvalDetailsList,'OrderApprovalClass','CreateApprovalDetails',True);
        }

    }

    //Saket More
    //SFDC-4178

    public static Approval_Details__c CreateApprovalDetailsReference(Case cse, String request, String status, String reason, String notes){
        Approval_Details__c approvalDetailRecord = new Approval_Details__c();
        approvalDetailRecord.Approval_Request__c = request;
        approvalDetailRecord.Approval_Status__c = status;
        approvalDetailRecord.Approver_Notes__c = notes;
        //approvalDetailRecord.Approval_Reason_Code__c = reason;
        approvalDetailRecord.Related_To__c = cse.id;
        approvalDetailRecord.Opportunity__c = cse.Opportunity__c; // SFDC-6837
        approvalDetailRecord.Order_Approval__c = cse.Order_Approval__c;
        approvalDetailRecord.AKAM_Approved_Date__c = datetime.now();
        approvalDetailRecord.Validation_Override__c = True;

        return approvalDetailRecord;
    } 

    

    //Saket More
    //SFDC-4178
    public static void changeOAStatus(List<Id> opp){

        System.debug('Inside changeOAStatus function');

        List<Order_Approval__c> OrderApprovalListToUpdate = new List<Order_Approval__c>();

        for(Order_Approval__c oa : [Select id, CCG_Status__c from Order_Approval__c where Associated_Opportunity__c in :opp]){

            System.debug('order approval record'+oa);
            oa.CCG_Status__c = 'Closed';
            oa.AKAM_Closed_Date__c = datetime.now();
            oa.Validation_Override__c = true;
            OrderApprovalListToUpdate.add(oa);

        }
        System.debug('OrderApprovallist'+OrderApprovalListToUpdate);
        Update OrderApprovalListToUpdate;
    }

    //Saket More
    //SFDC-4178
    public static void UpdateCaseAutoCloseField(List<Order_Approval__c> OAList){

        List<Case> cseList = new List<Case>();

        For(Case cse : [Select id, AutoClose__c from Case where Order_Approval__c in :OAList and IsClosed = false]){
            cse.AutoClose__c = true;
            cse.Validation_Override__c = true;
            cseList.add(cse);
        }
        if(cseList.size()>0){
            update cseList;
        }
    } 
    
    public static void CheckAndCreateCase(List<Id> AzureOpportunityList){
        System.debug('Inside CheckAndCreateCase');
        System.debug('AzureOpportunityList:'+AzureOpportunityList);
        List<Order_Approval__c> OAList = new List<Order_Approval__c>();
        List<Case> caseUpdateList = new List<Case>();
        //SFDC-6398 - If Oppty has open OM case then update the case else create an auto close the case

        for(Opportunity opp : [Select Id,Opportunity_Type__c,Auto_Renewal__c, (Select Id, CCG_Status__c from Order_Approvals__r), (Select id from Related_Cases__r where RecordType.Name = 'Order Approval-Order Management' limit 1) from Opportunity where id in:AzureOpportunityList]){
            if(opp.Related_Cases__r.size() == 0){
                OAList.add(opp.Order_Approvals__r);
            }
            else if(opp.Opportunity_Type__c == 'Auto-Renewal' && opp.Auto_Renewal__c && opp.Related_Cases__r.size() > 0 )
            {
                caseUpdateList.add(opp.Related_Cases__r);
            }
        }
        if(OAList.size()>0){
            CreateCases(OAList);
        }
        
        //SFDC-6398
        if(caseUpdateList.size() >0)
        {
            UpdateCases(caseUpdateList);
        }
        
    }


    /**
      Method : Update_Oppty_Create_Order_Approval
      - This is a webservice method and will be called from 'Create MP Quote' button
      - It will update opportunity.isMPOpportunity field and then create order approval.
      - Added by Chandra for MP 2.0 - QTOO-1973
    */
    Webservice static String Update_Oppty_Create_Order_Approval(Id p_OppId, String p_RecTypeId, String p_Stage, String p_GetField,String p_type)
    {
     Boolean isMPOpportunity=false;
        if(p_type=='Marketplace')
         isMPOpportunity=true;

        Opportunity opp= new Opportunity(Id=p_OppId,Validation_Override__c=true,isMPOpportunity__c=isMPOpportunity);       
        try
        {
          update opp;  
        }
        catch(Exception e)
        {
            return e.getMessage();
        } 
        String result = Create_OrderApproval(p_OppId, p_RecTypeId, p_Stage, p_GetField);
        return result;
    }
    /**
       Create_OrderApproval(Id p_OppId,String p_RecTypeId, String p_Stage)
       - Overloading func Create_OrderApproval()
    */
    public static String Create_OrderApproval(Id p_OppId, String p_RecTypeId, String p_Stage)
    {
        return Create_OrderApproval(p_OppId, p_RecTypeId, p_Stage, 'Id');
    }
    /**
       Create_Task(Id p_orderId,String p_TaskType)
       - This function is called by the "Create Task" Buttons on the "OrderApproval detail page -> Open Activities related list"
       - A Edit Task page is opened and the following fields are prepopulated by passing parameters to the URL :
            -) assignedTo
            -) relatedTo
            -) recordType
            -) subject (for China CDN, PS, TAPP, EdgeSuite Transition)
    */
    //SFDC-4178
    /*
    Webservice static String Create_Task(Id p_orderId,String p_TaskType){
      PageReference pr =  Create_Task_GetPageReference(p_orderId,p_TaskType);
      return pr.getUrl();
    }
    
    public  static PageReference Create_Task_GetPageReference(Id p_orderId,String p_TaskType)
    {
        List<String> OARegionlist=new List<String>();
        // Initialize static variables
        List<User_To_Sales_Region_Mapping__c> User_Region_list=[Select SA_user__c,Region__c from User_To_Sales_Region_Mapping__c];
        oaTaskRecTypeInit();
        oaUsersInit();
        Order_Approval__c order;
        for(Order_Approval__c o : [select Id,
                                          Name,
                                        //  CCG_Owner__c,
                                        //  Deal_Desk_Owner__c,
                                        //  Legal_Owner__c,
                                        //  Type__c,
                                          Account_Territory__c,
                                          Associated_Opportunity__r.OwnerId
                                   from Order_Approval__c 
                                   where Id=:p_orderId])
                       order = o;
        User ccg_Owner;
        User dd_Owner;
        User legal_Owner;
        User oppty_Owner;
        Id SA_Id;
        for(User_To_Sales_Region_Mapping__c Usr_Region:User_Region_list){
        //check if there is a mapping present in the User to Sales Region Mapping object
        if(Usr_Region.Region__c.contains(order.Account_Territory__c)){
          if(order.Account_Territory__c=='-'){
          //if account territory is not present,SA_Id is null hence assigned to SA Queue user
             break;}
          else{
            SA_Id=Usr_Region.SA_user__c;
            break;}
           }
        }
                           
       
        // Get the User records for the "CCG Owner", "Deal Desk Owner" and the "Legal Owner".
        for(User usr: [select Id,
                              Name 
                       from User 
                       where Id=:SA_Id or 
                             //Id=:order.CCG_Owner__c or
                             //Id=:order.Deal_Desk_Owner__c or 
                             //Id=:order.Legal_Owner__c or 
                             Id=:order.Associated_Opportunity__r.OwnerId])
        {
            if(usr.Id == SA_Id)
                ccg_Owner = usr;//if there is a record present for user,assign the user
            //else if(usr.Id == order.CCG_Owner__c){
            //if(ccg_owner==null){
            //    ccg_Owner = usr;}}//if there are multiple matches(SA Queue and user),skip the Queue user if the mapping is already present }
            //SFDC-4178
            //else if(usr.Id == order.Deal_Desk_Owner__c)
            //    dd_Owner = usr;
            //else if(usr.Id == order.Legal_Owner__c)
            //    legal_Owner = usr;  
            else if(usr.Id == order.Associated_Opportunity__r.OwnerId)      
                oppty_Owner = usr;                                              
        }
        // If the owners are null, then update them to the appropriate queue
        //if(dd_Owner == null)
        //{
        //    if(order.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
        //        dd_Owner = dealDeskQueueUsr;
        //    else if(order.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
        //        dd_Owner = ads_dealDeskQueueUsr;
        //}
        //SFDC-4178
        //if(legal_Owner == null)
        //{
        //    if(order.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
        //        legal_Owner = legalQueueUsr;
        //    else if(order.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
        //        legal_Owner = ads_legalQueueUsr;                
        //}
        User task_owner;
        // Set the Task Owner according to the "p_TaskType". This will be sent as parameter for prepoulating the "Assigned To" field
        if(p_TaskType == gsmMap.get('OA_Task_Type_CCG')) //SFDC-2304
            task_owner = ccg_Owner;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_Deal_Desk') || p_TaskType == gsmMap.get('OA_Task_Type_Deal_Desk')+'/'+gsmMap.get('OA_Task_Type_Legal')) //SFDC-2304
            task_owner = dd_Owner;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_Legal')) //SFDC-2304
            task_owner = legal_Owner;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_Product_Ops') || p_TaskType == gsmMap.get('OA_Task_type_TAPP')) //SFDC-2304
            task_owner = prodOpsQueueUsr;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_PS')) //SFDC-2304
            task_owner = oppty_Owner;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_China_CDN')) //SFDC-2304
            task_owner = cdnQueueUser;
        else if(p_TaskType == gsmMap.get('OA_Task_Type_EdgeSuite_Transition')) //SFDC-2304
            task_owner = edgeSuiteQueueUsr;
        else if (p_TaskType == gsmMap.get('OA_Task_Type_Swiss_Finance')) //SFDC-2304
        {
            String userId = gsmMap.get('OA_Swiss_Finance_Queue'); //SFDC-2304
            List<User> swissQueueUserList = [Select id,Name From User where id=:userId];
            task_owner = swissQueueUserList[0];
        }
        
        PageReference returnURL = new Pagereference ('/00T/e?');            
        // Set the "Record Type" to "Order Approval Activity"   
        returnURL.getParameters().put('RecordType', oaTaskRecTypeId);       
        // Set the "Task Owner" according to "p_TaskType"   
       if(p_TaskType == 'Revenue Alignment Waiver'){
         returnURL.getParameters().put('tsk1',UserInfo.getName());
         returnURL.getParameters().put('tsk1_lkid',UserInfo.getUserId());
        }
        else{
        returnURL.getParameters().put('tsk1',task_owner.Name);
        returnURL.getParameters().put('tsk1_lkid',task_owner.Id);
        }
        // Set the "Task.Related To" to the Order
        returnURL.getParameters().put('what_id', order.Id);
        if(p_TaskType == gsmMap.get('OA_Task_Type_China_CDN')) //SFDC-2304
            returnURL.getParameters().put('tsk5', gsmMap.get('OA_subject_china_cdn') + order.Name); //SFDC-2304
        else if(p_TaskType == gsmMap.get('OA_Task_type_TAPP')) //SFDC-2304
            returnURL.getParameters().put('tsk5', gsmMap.get('OA_subject_Tapp') + order.Name); //SFDC-2304
        else if(p_TaskType == gsmMap.get('OA_Task_Type_PS')) //SFDC-2304
            returnURL.getParameters().put('tsk5', gsmMap.get('OA_subject_PS') + order.Name); //SFDC-2304
        else if(p_TaskType == gsmMap.get('OA_Task_Type_EdgeSuite_Transition')) //SFDC-2304
            returnURL.getParameters().put('tsk5',gsmMap.get('OA_subject_edge') + order.Name); //SFDC-2304            
        else if(p_TaskType == gsmMap.get('OA_Task_Type_Product_Ops')) //SFDC-2304
            returnURL.getParameters().put('tsk5',gsmMap.get('OA_subject_prod_ops') + order.Name);   //SFDC-2304                                                   
        // Done at the button itself.
        // If Deal Desk/Legal, check Legal Followup checkbox
        //if(p_TaskType == 'Deal Desk/Legal')
        //    returnURL.getParameters().put('00NS0000000edzO', '1');
        // "Reminder = false"
        returnURL.getParameters().put('IsReminderSet', '0');
        // Set the navigation parameters for the URL
        returnURL.getParameters().put('cancelURL', order.Id);
        returnURL.getParameters().put('retURL', order.Id);  
        returnURL.getParameters().put('nooverride', '1');
        returnURL.setRedirect(true);
        return returnURL;      
    }
    */
    /**
       UpdateRecType(Order_Approval__c[] order_approvals)
       - This function udpates the "Record Type" of the Order Approval according to the values selected in "Approvals Required".
       - The default "Record Type" is "CCG Only Approval"
    */
    //SFDC-4178
    //public static void UpdateRecType(Order_Approval__c[] order_approvals)
    //{
        // Initialize static variables
        // Get the Order Approval Record Type Ids
     //   oaRecTypeMap = new Map<String,Id>();
        /*for(RecordType r:[select Name,
                                 Id 
                          from RecordType 
                          where Name=:customSettings.Full_Approval_record_type__c or 
                                Name=:customSettings.Deal_Desk_Approval__c or 
                                Name=:customSettings.Legal_Approval__c or 
                                Name=:customSettings.CCG_Only_Approval__c])
            oaRecTypeMap.put(r.Name,r.Id);*/
         //    oaRecTypeMap.put(gsmMap.get('OA_Full_Approval_record_type'),gsmMap.get('OA_Full_Approval_record_type_id')); //SFDC-2304
         //   oaRecTypeMap.put(gsmMap.get('OA_Deal_Desk_Approval'),gsmMap.get('OA_Deal_Desk_Approval_Id')); //SFDC-2304
         //   oaRecTypeMap.put(gsmMap.get('OA_Legal_Approval'),gsmMap.get('OA_Legal_Approval_id')); //SFDC-2304
         //   oaRecTypeMap.put(gsmMap.get('OA_CCG_Only_Approval'),gsmMap.get('OA_CCG_Only_Approval_Id')); //SFDC-2304
        //system.assertEquals(oaRecTypeMap.keySet().size(),4);
        //SFDC-4178
        //for(Order_Approval__c o:order_approvals)
        //{
        //    //Udpate the "Record Type" of the Order Approval according to the values selected in "Approvals Required".
        //    if(o.Approvals_Required__c!=null)
        //    {
        //        if(o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal')) && !o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk'))) //SFDC-2304
        //            o.RecordTypeId=oaRecTypeMap.get(gsmMap.get('OA_Legal_Approval')); //SFDC-2304
        //        else if(!o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal')) && o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk'))) //SFDC-2304
        //            o.RecordTypeId=oaRecTypeMap.get(gsmMap.get('OA_Deal_Desk_Approval'));  //SFDC-2304
        //        else if(o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal')) && o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk'))) //SFDC-2304
        //            o.RecordTypeId=oaRecTypeMap.get(gsmMap.get('OA_Full_Approval_record_type')); //SFDC-2304
        //    }   
        //    else
        //        o.RecordTypeId=oaRecTypeMap.get(gsmMap.get('OA_CCG_Only_Approval')); //SFDC-2304
        //}
   // }
    /**
       DefaultOwners(Order_Approval__c[] order_approvals)
       - This function updates the 3 owner fields (CCG Owner, Deal Desk Owner, Legal Owner) according to the Record Type.
       - If the owner fields are empty, they are defaulted to there respective queues.
       - If a group approval is no longer required, then the respective Owner field is nulled.
    */
    //SFDC - 4178
    /*
    public static void DefaultOwners(Order_Approval__c[] order_approvals)
    {
        // Initialize static variable
        oaUsersInit();  
        for(Order_Approval__c o:order_approvals)
        {
            // Type must be CDN/ADS
            //if(o.Type__c != gsmMap.get('OA_ADS_type') && o.Type__c != gsmMap.get('OA_CDN_type')) //SFDC-2304
            //    o.Type__c.addError(gsmMap.get('OA_type_error')); //SFDC-2304
            // Default to CCG Queue on Insert               
            //if(Trigger.isInsert)
            //{
            //    if(o.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304 
            //        o.CCG_Owner__c = ccgQueueUsr.Id;
            //    else if(o.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
            //        o.CCG_Owner__c = ads_ccgQueueUsr.Id;
            //}
            //CR 844778 Make CCG status 'In Process' IF owner is not Queue owner
            //SFDC-4178
            //if(Trigger.isupdate && (o.CCG_Owner__c!=ccgQueueUsr.Id && o.CCG_Owner__c!= ads_ccgQueueUsr.id) && o.CCG__c==null)       
            //{
            //    o.CCG_Status__c= gsmMap.get('OA_In_Process'); //SFDC-2304
            //}   
            //- If the owner fields are empty, they are defaulted to there respective queues.
            //- If a group approval is no longer required, then the respective Owner field is nulled.
            //if(o.Approvals_Required__c!=null)
            //{
            //    if(o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk')) && o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal'))) //SFDC-2304
            //    {
                    //if(o.Deal_Desk_Owner__c == null)
                    //{
                    //    if(o.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
                    //        o.Deal_Desk_Owner__c = dealDeskQueueUsr.Id;
                    //    else if(o.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
                    //        o.Deal_Desk_Owner__c = ads_dealDeskQueueUsr.Id;
                    //}
                    //if(o.Legal_Owner__c == null)
                    //{
                    //    if(o.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
                    //        o.Legal_Owner__c = legalQueueUsr.Id;
                    //    else if(o.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
                    //        o.Legal_Owner__c = ads_legalQueueUsr.Id;                            
                    //}
            //    }
            //    else if(o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk')) && !o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal'))) //SFDC-2304
            //    {
                    //if(o.Deal_Desk_Owner__c == null)
                    //{
                    //    if(o.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
                    //        o.Deal_Desk_Owner__c = dealDeskQueueUsr.Id;
                    //    else if(o.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
                    //        o.Deal_Desk_Owner__c = ads_dealDeskQueueUsr.Id;                         
                    //}
                    //o.Legal_Owner__c=null;              
            //    }
            //    else if(!o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk')) && o.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal'))) //SFDC-2304
            //    {
                    //if(o.Legal_Owner__c == null)
                    //{
                    //    if(o.Type__c == gsmMap.get('OA_CDN_type')) //SFDC-2304
                    //        o.Legal_Owner__c = legalQueueUsr.Id;
                    //    else if(o.Type__c == gsmMap.get('OA_ADS_type')) //SFDC-2304
                    //        o.Legal_Owner__c = ads_legalQueueUsr.Id;
                    //}
            //        o.Deal_Desk_Owner__c = null;                
            //    }   
            //}       
            //else    // Default to CCG Only
            //{
            //    o.Deal_Desk_Owner__c = null;
            //    //o.Legal_Owner__c = null;
            //}
        }
    }
    */



    /**
    SFDC-4178
       UpdateOppty(Order_Approval__c[] order_approvals)
       - This function promotes the values of the following fields to the respective fields in the Associated Oppty:
         =) CCG# (SA#)
         =) SA Owner
         =) DD/CCG Expiration Date
         =) CCG Approved Date
         =) Deal Desk#
         =) Legal#
       - This function bypasses the Opportunity "Validation Rules".
    */
    /*
    public static void UpdateOppty(Order_Approval__c[] order_approvals)
    {       
        if(!UpdateOpptyFirstRunFlag)
            return;

        
            
        //-------------BULKAFYING -------------
        Set<Id> opptyIds = new Set<Id>(); 
        for(Order_Approval__c oa:order_approvals)
            opptyIds.add(oa.Associated_Opportunity__c);
        Map<Id,Opportunity> opptysMap = new Map<Id,Opportunity>();
        for(Opportunity opp:[select Id,
                                    CCG__c,
                                    SA_Owner__c,
                                    Deal_Desk__c,
                                    Legal_Control__c,
                                    DD_CCG_Expiration_Date__c,
                                    CCG_Approved_Date__c,
                                    Compliance_Issue_Type__c,
                                    Gross_Margin__c
                             from Opportunity 
                             where Id IN :opptyIds])                                    
            opptysMap.put(opp.Id,opp);
        //--------------------------------------
        List<Opportunity> updateOpptys = new List<Opportunity>();
        Opportunity opp;
        for(Order_Approval__c oa:order_approvals)
        {
            opp = opptysMap.get(oa.Associated_Opportunity__c);
            // Disable Validation Rules
            opp.Validation_Override__c = true;
            /* 
                    Promote the values of the following fields if any 1 of them are changed.
                     =) CCG# (SA#)
                     =) SA Owner
                     =) Deal Desk#
                     =) Legal#
                     =) DD CCG_Expiration_Date
                     =) CCG Approved_Date
                     =) Compliance Issue Type
                     =) Commission Exception
                     =) Gross Margin
            */
            /*
            if(opp.CCG__c!=oa.CCG__c || opp.Manual_Invoice__c != oa.Manual_Invoice__c || opp.Order_Level__c != oa.Order_Level__c  || opp.SA_Owner__c!=oa.CCG_Owner__c || opp.Deal_Desk__c!=oa.Deal_Desk__c || opp.Legal_Control__c!=oa.Legal__c || opp.DD_CCG_Expiration_Date__c != oa.DD_CCG_Expiration_Date__c || opp.CCG_Approved_Date__c != oa.CCG_Approved_Date__c || opp.Compliance_Issue_Type__c != oa.Compliance_Issue_Type__c || opp.Commission_Exception__c != oa.Commission_Exception__c || opp.Gross_Margin__c != oa.Gross_Margin__c)
            {
                opp.CCG__c = oa.CCG__c;
                opp.SA_Owner__c = oa.CCG_Owner__c;
                opp.Deal_Desk__c = oa.Deal_Desk__c;
                opp.Legal_Control__c = oa.Legal__c;
                opp.Manual_Invoice__c = oa.Manual_Invoice__c;
                opp.Order_Level__c = oa.Order_Level__c;
                opp.DD_CCG_Expiration_Date__c = oa.DD_CCG_Expiration_Date__c;
                opp.CCG_Approved_Date__c = oa.CCG_Approved_Date__c;
                opp.Compliance_Issue_Type__c = oa.Compliance_Issue_Type__c;
                opp.Commission_Exception__c = oa.Commission_Exception__c;
                opp.Gross_Margin__c = oa.Gross_Margin__c;
                updateOpptys.add(opp);
            }
        }
        if(updateOpptys.size()>0){
            try{
                update updateOpptys;
            }
            catch(DMLException e){
                if(e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                    for(Order_Approval__c oa : order_approvals)
                        oa.addError('Unable to obtain exclusive access to this record. Please try again later or contact your system administrator if the issue persists.');
                }
                else
                    throw e;
            }
        }
        UpdateOpptyFirstRunFlag = false;

    }
    */



    /**
       OrderApprovalActivity_UpdateTask(Task[] tasks)
       -) This is called by trigger events "before insert/before update" on Task
       -) It is called only when  "Task.Record Type" = "Order Approval Activity"
       -) The "Task.Task Type" is stamped based on the profile of the "User" that the task is "Assigned To" or the Subject in case of TAPP, China CDN, PS or EdgeSuite Transition Approvals
    */
    //SFDC-4178
    /*
    public static void OrderApprovalActivity_UpdateTask(Task[] tasks)
    {
        if(!OrderApprovalActivity_UpdateTaskFirstRunFlag)
            return;
        // Initialize static variable
        oaTaskRecTypeInit();
        oaProfilesInit();
        oaUsersInit();  
        // -----------Bulkaying--------------
        Set<Id> ownerIds = new Set<Id>();
        for(Task tsk:tasks)
            ownerIds.add(tsk.OwnerId);      
        Map<Id,Id> usr_pr_Map = new Map<Id,Id>();
        for(User usr:[select Id,ProfileId from User where Id IN :ownerIds])
            usr_pr_Map.put(usr.Id, usr.ProfileId);
        String wId;
        // ----------------------------------
        for(Task tsk:tasks)
        {
            //Update the "Task Type" according to the Profile of the "Task Owner"
            if(tsk.RecordTypeId == oaTaskRecTypeId)
            {
                wId = tsk.WhatId;
                if(wId == null || !wId.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()))
                    tsk.WhatId.addError('This task must be related to an Order Approval.');
                else
                {
                    //Start of SFDC-2304
                    if(usr_pr_Map.get(tsk.OwnerId) == ddesk_prId || ads_ddesk_prIds.contains(usr_pr_Map.get(tsk.OwnerId)) || gsmMap.get('OA_Deal_Desk_Queue_UserIds').contains(tsk.OwnerId)) // CDN || ADS Deal Desk
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_Deal_Desk'); 
                    else if(usr_pr_Map.get(tsk.OwnerId) == legal_prId || gsmMap.get('OA_Legal_Queue_UserIds').contains(tsk.OwnerId))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_Legal');
                    else if(ccg_prIds.contains(usr_pr_Map.get(tsk.OwnerId)) || gsmMap.get('OA_SA_Queue_UserIds').contains(tsk.OwnerId))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_CCG');
                    else if(tsk.Subject.contains(gsmMap.get('OA_subject_contains_china_cdn')))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_China_CDN');
                    else if(tsk.Subject.contains(gsmMap.get('OA_subject_contains_tapp')))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_type_TAPP');
                    else if(tsk.Subject.contains(gsmMap.get('OA_subject_contains_PS_Approval')))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_PS');
                    else if(tsk.Subject.contains(gsmMap.get('OA_subject_contains_edge')))
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_EdgeSuite_Transition');        
                    else if(tsk.Subject.contains(gsmMap.get('OA_subject_contains_Product_Ops_Approval')))//CR 844778 tie task to subject instead of queue.
                        tsk.Task_Type__c = gsmMap.get('OA_Task_Type_Product_Ops'); 
                    else if(tsk.Subject=='Revenue Alignment Waiver')
                        tsk.Task_Type__c = 'Revenue ALignment Waiver'; 
                    else if(tsk.OwnerId==gsmMap.get('OA_Swiss_Finance_Queue')) //End of SFDC-2304
                        tsk.Task_Type__c = 'Revenue Alignment';                                                                                   
                    else
                        tsk.Task_Type__c = 'Other';
                }
            }
            // Uncheck the Reminder flag
            tsk.IsReminderSet = false;  
        }   
        OrderApprovalActivity_UpdateTaskFirstRunFlag = false;
    }
    */
    /**
       OrderApprovalActivity_UpdateOrder(Task[] tasks)
       - This function is called on trigger events "after insert/after update" on Tasks.
       - It is called only when  "Task.Record Type" = "Order Approval Activity"
       - Based on the combination of "Task.Task Type"/"Task.Legal Followup Needed", the Order.Approvals Required is updated.
    */
    //public static void OrderApprovalActivity_UpdateOrder(Task[] tasks)
    //{
        /*
        if(!OrderApprovalActivity_UpdateOrderFirstRunFlag)
        {
            return;
        }           
        // Initialize static variables
        oaTaskRecTypeInit();    
        Set<Id> orderSet = new Set<Id>();
        Map<Id,Order_Approval__c> orderMap = new Map<Id,Order_Approval__c>();
        Set<Id> OrdersIds = new Set<Id>();
        List<Order_Approval__c> updateOrders = new List<Order_Approval__c>();
        for(Task tsk:tasks)
            orderSet.add(tsk.whatId);   
        for(Order_Approval__c oa:[select Id, 
                                         CCG_Owner__c 
                                        // Approvals_Required__c,
                                        //Deal_Desk_Status__c
                                        // Legal_Owner__c, 
                                        // Deal_Desk_Owner__c 
                                  from Order_Approval__c 
                                  where Id IN :orderSet])
            orderMap.put(oa.Id, oa);
        Order_Approval__c order;
        Boolean isUpdate = false;
        for(Task tsk:tasks)
        {
            if(tsk.RecordTypeId == oaTaskRecTypeId && orderMap.containsKey(tsk.whatId))
            {
                order = orderMap.get(tsk.whatId);
                isUpdate = false;
                // If Task Type is Deal Desk, then add Deal Desk to Order.Approvals Required
                //if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Deal_Desk')) //SFDC-2304
                //{
                    //If a new deal desk task is created, set the deal desk status to Open.
                //    if(trigger.isInsert)
                  //  {
                    //    order.Deal_Desk_Status__c='Open';
                      //  isUpdate=true;
                     //}
                    //if(order.Approvals_Required__c == null)
                    //{
                    //    order.Approvals_Required__c = gsmMap.get('OA_AR_Deal_Desk'); //SFDC-2304
                    //    isUpdate = true;
                    //}                       
                    //else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_Deal_Desk'))) //SFDC-2304
                    //{
                    //    order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_Deal_Desk'); //SFDC-2304
                    //    isUpdate = true;
                    //}
                }
                // If Task Type is Legal or Legal Followup Needed is checked, add Legal to Order.Approvals Required
                //if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Legal') || tsk.Legal_Followup_Needed__c == true) //SFDC-2304
                //{
                    //if(order.Approvals_Required__c == null)
                    //{
                    //    order.Approvals_Required__c = gsmMap.get('OA_AR_Legal'); //SFDC-2304
                    //    isUpdate = true;
                    //}                       
                    //else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_Legal'))) //SFDC-2304
                    //{
                    //    order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_Legal'); //SFDC-2304
                    //    isUpdate = true;
                    //}
                //}
                /* 
                SFDC-4178          
                if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_PS')) //SFDC-2304
                {
                    if(order.Approvals_Required__c == null)
                    {
                        order.Approvals_Required__c = gsmMap.get('OA_AR_Professional_Services'); //SFDC-2304
                        isUpdate = true;
                    }                       
                    else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_Professional_Services'))) //SFDC-2304
                    {
                        order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_Professional_Services'); //SFDC-2304
                        isUpdate = true;
                    }
                }
                else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_China_CDN')) //SFDC-2304
                {
                    if(order.Approvals_Required__c == null)
                    {
                        order.Approvals_Required__c = gsmMap.get('OA_AR_China_CDN'); //SFDC-2304
                        isUpdate = true;
                    }                       
                    else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_China_CDN'))) //SFDC-2304
                    {
                        order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_China_CDN'); //SFDC-2304
                        isUpdate = true;
                    }
                }           
                else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_EdgeSuite_Transition')) //SFDC-2304
                {
                    if(order.Approvals_Required__c == null)
                    {
                        order.Approvals_Required__c = gsmMap.get('OA_AR_EdgeSuite_Transition'); //SFDC-2304
                        isUpdate = true;
                    }                       
                    else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_EdgeSuite_Transition'))) //SFDC-2304
                    {
                        order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_EdgeSuite_Transition'); //SFDC-2304
                        isUpdate = true;
                    }
                }
                else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Product_Ops')) //SFDC-2304
                {
                    if(order.Approvals_Required__c == null)
                    {
                        order.Approvals_Required__c = gsmMap.get('OA_AR_Product_Ops'); //SFDC-2304
                        isUpdate = true;
                    }                       
                    else if(!order.Approvals_Required__c.contains(gsmMap.get('OA_AR_Product_Ops'))) //SFDC-2304
                    {
                        order.Approvals_Required__c = order.Approvals_Required__c + '; '+gsmMap.get('OA_AR_Product_Ops'); //SFDC-2304
                        isUpdate = true;
                    }
                } 
                */  
                // CR 844778 
                // If   : 1. The "CCG Owner" is "CCG Queue"
                //        2. The new "Task Owner" is not "CCG Queue"
                //        3. The "Task Type" is "CCG"  
                // Then : Update the "CCG Owner" with the "Task Owner" 
                // and Make CCG Status 'In Process'
                /*
                if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_CCG') && (tsk.OwnerId != ccgQueueUsr.Id && tsk.OwnerId != ads_ccgQueueUsr.Id) && (order.CCG_Owner__c == ccgQueueUsr.Id || order.CCG_Owner__c == ads_ccgQueueUsr.Id)) //SFDC-2304
                {
                    order.CCG_Owner__c = tsk.OwnerId;
                    order.CCG_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                    isUpdate = true;
                }                               
                // If   : 1. The "Deal Desk Owner" is "Deal Desk Queue"
                //        2. The new "Task Owner" is not "Deal Desk Queue"
                //        3. The "Task Type" is "Deal Desk"  
                // Then : Update the "Deal Desk Owner" with the "Task Owner" 
                //CR 844778 Make Desl Desk Status 'In Process'
                //SFDC-4178
                //else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Deal_Desk') && (tsk.OwnerId != dealDeskQueueUsr.Id && tsk.OwnerId != ads_dealDeskQueueUsr.Id) && (order.Deal_Desk_Owner__c == dealDeskQueueUsr.Id || order.Deal_Desk_Owner__c == ads_dealDeskQueueUsr.Id)) //SFDC-2304
                //{
                //    order.Deal_Desk_Owner__c = tsk.OwnerId;
                //    order.Deal_Desk_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                //    isUpdate = true;
                //}
                // If   : 1. The "Legal Owner" is "LegalQueue"
                //        2. The new "Task Owner" is not "Legal Queue"
                //        3. The "Task Type" is "Legal"
                // Then : Update the "Legal Owner" with the "Task Owner" 
                //CR 844778 Make Legal Status 'In Process'  
                //SFDC-4178            
                //else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Legal') && (tsk.OwnerId != legalQueueUsr.Id && tsk.OwnerId != ads_legalQueueUsr.Id) && (order.Legal_Owner__c == legalQueueUsr.Id || order.Legal_Owner__c == ads_legalQueueUsr.Id)) //SFDC-2304
                //{
                //    order.Legal_Owner__c = tsk.OwnerId;
                //    order.Legal_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                //    isUpdate = true;
                //}
                //CR 844778 Make Product Status 'In Process' when owner is not queue owner
                //else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_Product_Ops') && (tsk.OwnerId != prodOpsQueueUsr.Id )) //SFDC-2304
                //{ SFDC-4178
                //    order.Product_Ops_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                //    isUpdate = true;
                //}
                //CR 844778 Make China CDN Status 'In Process' when owner is not queue owner
                //else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_China_CDN') && (tsk.OwnerId != cdnQueueUser.Id )) //SFDC-2304
                //{ SFDC-4178
                //    order.China_CDN_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                //    isUpdate = true;
                //}
                //CR 844778 Make EdgeSuite Transition Status 'In Process' when owner is not queue owner
                //else if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_EdgeSuite_Transition') && (tsk.OwnerId != edgeSuiteQueueUsr.Id )) //SFDC-2304
                //{ SFDC-4178
                //    order.EdgeSuite_Transition_Status__c=gsmMap.get('OA_In_Process'); //SFDC-2304
                //    isUpdate = true;
                //}
                if(isUpdate == true)
                {
                    order.Validation_Override__c=true;
                    if(!OrdersIds.contains(order.id)){
                    OrdersIds.add(order.id);
                    updateOrders.add(order);
                    }
                }                                       
            }
        }
        //if(updateOrders.size()>0)
        //    update updateOrders;
        OrderApprovalActivity_UpdateOrderFirstRunFlag = false;
        */
    //}   
    /**
       SendOrderApprovalActivityEmails(Task[] oldTasks,Task[] newTasks)
       - Sends a notification email to the "Task.Created By" user when the Status/Owner of the Task changes.
       - The template used is a VisualForce Email Template -> "OA Task change notification"
       - Users can opt-in or opt-out of these notifications by using the Receive_email_when_OA_Status_changes__c/Receive_email_when_OA_Owner_changes__c checkboxes on the User layouts.
    */
    /* SFDC-4178
    public static void SendOrderApprovalActivityEmails(Task[] oldTasks,Task[] newTasks)
    {
        if(!SendOrderApprovalActivityEmailsfirstRunFlag)
            return;
        // Initialize static variables
        oaTaskRecTypeInit();
        oaTaskChangeTemplate=gsmMap.get('OA_Task_change_notification_id'); //SFDC-2304
        oaTaskCreateTemplate=gsmMap.get('OA_Activity_Creation_Notification_id'); //SFDC-2304
        system.assertNotEquals(oaTaskChangeTemplate,null);
        system.assertNotEquals(oaTaskCreateTemplate,null);
        Boolean statusChangeNotify = false;
        Boolean ownerChangeNotifty = false;
        //Added Email Message List to send mail in bulk :
        List<Messaging.SingleEmailMessage> emailMessageList=new List<Messaging.SingleEmailMessage>();
        //Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
        //Start Modified By Chandra CR 1270741
        Set<Id> orderApprovalIds=new Set<Id>();
        Set<Id> paeUserIdSet=new Set<Id>();
        Map<Id,Id> oaIdOpptyIdMap=new Map<Id,Id>();
         for(Integer i=0;i<newTasks.size();i++)
        {
            if(newTasks[i].RecordTypeId == oaTaskRecTypeId)
            {
                 orderApprovalIds.add(newTasks[i].WhatId);
            }
        }
        
        List<Order_Approval__c> oaList=[select Id,Associated_Opportunity__c from Order_Approval__c where ID IN : orderApprovalIds];
        Set<Id> opptyIdSet=new Set<Id>();
        for(Order_Approval__c oa: oaList)
        {
            opptyIdSet.add(oa.Associated_Opportunity__c);
            for(Id oaId : orderApprovalIds)
            {
                if(oaId==oa.Id)
                {
                    oaIdOpptyIdMap.put(oa.Id,oa.Associated_Opportunity__c);
                }
            }
        }
        List<OpportunityTeamMember> opptySalesTeamPAEUserList=[select UserId
                                                                     ,User.UserType
                                                                     ,User.Receive_email_when_OA_Owner_Changes__c
                                                                     ,User.Receive_email_when_OA_Status_changes__c
                                                                     ,OpportunityId
                                                                from OpportunityTeamMember 
                                                               where OpportunityId IN :opptyIdSet 
                                                                 and TeamMemberRole ='Channel - Primary'];
        Map<Id,List<OpportunityTeamMember>> oaIdOpptyTeamMemberMap=new Map<Id,List<OpportunityTeamMember>>();
        
        for(Id oaId: orderApprovalIds)
        {
            Id opptyId=oaIdOpptyIdMap.get(oaId);
            List<OpportunityTeamMember> opptyTeamList=new List<OpportunityTeamMember>();
            for(OpportunityTeamMember opptyTeamMember: opptySalesTeamPAEUserList)
            {
                if(opptyId==opptyTeamMember.OpportunityId)
                {
                    opptyTeamList.add(opptyTeamMember);
                }
            }
            oaIdOpptyTeamMemberMap.put(oaId,opptyTeamList);
        }
        End Modified By Chandra CR 1270741  
        //CR 878780 Email should be sent if the Task to is Sales-Channel Rep : Vinay
        //This contains set of Owner ids
        set<id> Owneridset=new set<id>();
        //This contains map of owner id and Task id
        Map<id,id> OwnerTaskMap=new Map<id,id>();
        for(Integer i=0;i<newTasks.size();i++)
        {
            if(newTasks[i].RecordTypeId == oaTaskRecTypeId)
            { 
                Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();                
                // Order Approval Status/Owner change Notification
                statusChangeNotify = ((oldTasks[i].Status != newTasks[i].Status) && (newTasks[i].Send_email_when_Status_changes__c == 'Yes'));
                ownerChangeNotifty = ((oldTasks[i].OwnerId != newTasks[i].OwnerId) && (newTasks[i].Send_email_when_Owner_changes__c == 'Yes'));
                Start Modified By Chandra CR 1270741
                List<OpportunityTeamMember> taskSalesTeamList=oaIdOpptyTeamMemberMap.get(newTasks[i].WhatId);
                for(OpportunityTeamMember opptyMember: taskSalesTeamList)
                {
                    if((ownerChangeNotifty && opptyMember.User.Receive_email_when_OA_Owner_Changes__c)
                        ||(statusChangeNotify && opptyMember.User.Receive_email_when_OA_Status_changes__c))
                      {
                        String userType=opptyMember.User.UserType;
                        if(!(userType != null && userType.contains('Partner')))
                       {
                        Messaging.SingleEmailMessage emailMessageToPAE=new Messaging.SingleEmailMessage();
                        emailMessageToPAE.setTemplateId(oaTaskChangeTemplate);
                        emailMessageToPAE.setTargetObjectId(opptyMember.UserId);
                        emailMessageToPAE.setWhatId(newTasks[i].Id);
                        emailMessageToPAE.setSaveAsActivity(false);
                        emailMessageList.add(emailMessageToPAE);
                        }
                      }
                }
                End Modified By Chandra CR 1270741
                if(statusChangeNotify || ownerChangeNotifty)
                {
                    email.setTemplateId(oaTaskChangeTemplate);
                    email.setTargetObjectId(newTasks[i].CreatedById);
                    email.setWhatId(newTasks[i].Id);
                    email.setSaveAsActivity(false);
                    emailMessageList.add(email);
                    //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });    Commented out to bukify send mail operation Modified by Chandra For CR 1270741
                }       
                // Check id Task owner is changed and owner is not same as created by
                if((oldTasks[i].OwnerId != newTasks[i].OwnerId) && (newTasks[i].OwnerId!=newTasks[i].CreatedById))
                {
                    
                    Owneridset.add(newTasks[i].OwnerId);    
                    OwnerTaskMap.put(newTasks[i].OwnerId,newTasks[i].Id);
                }
            }
        }   
        // Check if the owner has a profile like Sales%
        //Vikas: Remove the sales check, CR: 1396261 
        List<User> userset=new List<User>();
        for(User user:[select id,Receive_email_when_OA_Owner_Changes__c from User where id  IN :Owneridset ])
        {
            userset.add(user);
            
        }
        
        for(User u:userset)
        {
            //Check if the flag is set, else dont send email
            if(u.Receive_email_when_OA_Owner_Changes__c)
            {
                Messaging.SingleEmailmessage emailToOwner = new Messaging.SingleEmailmessage();
                emailToOwner.setTemplateId(oaTaskChangeTemplate);
                emailToOwner.setTargetObjectId(u.id);
                emailToOwner.setWhatId(OwnerTaskMap.get(u.id));//send email to the task owner corresponding to the task
                emailToOwner.setSaveAsActivity(false);
                emailMessageList.add(emailToOwner);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email }); Commented out to bukify send mail operation Modified by Chandra For CR 1270741
            }
        }
        if(emailMessageList.size()>0)
        {
        Messaging.sendEmail(emailMessageList);
        }   
        SendOrderApprovalActivityEmailsfirstRunFlag = false;
    }
    */
    /**
        SendOrderApprovalPSApporvalNotifications()
        - Send an email to the task owner notifying him that a new PS Approval is required
        - Is being done in code because it is not possible through a Workflow action
        - CR 694234 China CDN, TAPP, EdgeSuite transition team, PS, Aproval Process
        - This function sends email when Task_Type is 'PS' or 'China CDN' or 'TAPP' or 'EdgeSuite Transition'
    */
    //SFDC-4178
    /*  
    public static void SendOrderApprovalTaskCreationNotifications(Task[] tasks)
    {
        oaTaskChangeTemplate=gsmMap.get('OA_Task_change_notification_id'); //SFDC-2304
        oaTaskCreateTemplate=gsmMap.get('OA_Activity_Creation_Notification_id'); //SFDC-2304
        system.assertNotEquals(oaTaskChangeTemplate,null);
        system.assertNotEquals(oaTaskCreateTemplate,null);
        Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();        
        for(Task tsk:tasks)
        {
            if(tsk.Task_Type__c == gsmMap.get('OA_Task_Type_PS') || tsk.Task_Type__c == gsmMap.get('OA_Task_Type_China_CDN') || tsk.Task_Type__c == gsmMap.get('OA_Task_type_TAPP') || tsk.Task_Type__c == gsmMap.get('OA_Task_Type_EdgeSuite_Transition')) //SFDC-2304
            {
                    email.setTemplateId(oaTaskCreateTemplate);
                    email.setTargetObjectId(tsk.OwnerId);
                    email.setWhatId(tsk.Id);
                    email.setSaveAsActivity(false);
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });              
            }
        }
    }

    */
    
    /**
    // SFDC-4178
    CR 1498591: Create new DD# Modified field
    updateDealDeskDetails()
    - Sets the value of the DD# and DD Modified at field based on Deal Desk Status value
    - The DD# is updated as follows based on the Boolean passed as parameter:
        - "AKAM Order Approval" Id when the DD Status is changed to "Completed"
        - "Null" when DD Status is changed to "Not Needed"
    - The DD modified at field gets updated to NOW()
    
    public static void updateDealDeskDetails(List<Order_Approval__c> pOAList, Boolean setNull)
    {
        if(!updateDealDeskDetailsFirstRunFlag)
            return;
        if(!setNull)
        {
            for (Order_Approval__c oa: pOAList)
            {
                oa.Deal_Desk__c = oa.AKAM_OrderApproval_ID__c;
                oa.DD_Modified_at__c = DateTime.NOW();
            }
        }
        else
        {
            for (Order_Approval__c oa: pOAList)
            {
                oa.Deal_Desk__c = null;
                oa.DD_Modified_at__c = DateTime.NOW();
            }
        }
        
        updateDealDeskDetailsFirstRunFlag = false;
    }
    */

/*
SFDC-4178
    public static void DealDeskActivity_UpdateTask(Task[] ddTasks)
    {
        if(!DealDeskActivity_UpdateTaskFirstRunFlag)
            return;

        Set<Id> oaWhatIdSet = new Set<Id>();
        Map<Task,Order_Approval__c> taskToOrderApprovalMap = new Map<Task,Order_Approval__c>();
        List<Task> taskList = new List<Task>();
        List<Task> taskToUpdate = new List<Task>();
        List<Order_Approval__c> orderApptoUpdateList = new List<Order_Approval__c>();
       
        //Set<Id> approvalHistoryRecordsIDSet = new Set<Id>();
        //Get Order Approval Record via WhatId and Approval Request ID
        for(Task ddTask : ddtasks)
        {
            system.debug('Order Approval and Task '+ddTask.whatId +'Task '+ddTask);
            oaWhatIdSet.add(ddTask.whatId);
            //approvalHistoryRecordsIDSet.add(ddTask.Approval_Request_Id__c);

        }


        Set<Id> taskToUpdateSet = new Set<Id>();
        List<Order_Approval__c> ddOrderAppList = new List<Order_Approval__c>();
        List<Order_Approval__c> ddOrderAppListToUpdate = new List<Order_Approval__c>();
        //List<Apttus_Approval__Approval_Request__c> ddApprovalRequestList = new List<Apttus_Approval__Approval_Request__c>();
        
        //All Order Approval Records which are Small Deal
        if(oaWhatIdSet.size() > 0)
        {
            ddOrderAppList = [Select Id, Small_Deal__c,Deal_Desk_Approval_Notes__c,Deal_Desk_Status__c,Reason_Code_1__c From Order_Approval__c Where Id IN :oaWhatIdSet AND Small_Deal__c = True];
        }
        //All associated Approval request records
        //ddApprovalRequestList = [Select Id,Deal_Desk_Approvals_Required__c From Apttus_Approval__Approval_Request__c Where Id IN :approvalHistoryRecordsIDSet];

        system.debug('OA List '+ddOrderAppList);

        for(Task ddtask :ddTasks)
        {
            for(Order_Approval__c oa: ddOrderAppList)
            {
                if(ddtask.whatId == oa.Id)
                {
                    taskToOrderApprovalMap.put(ddtask,oa);
                }
        
            }


        }

        //Select the Tasks and Order Approval ,if Approval request id exists in Task then check for Discount Threshold Request else include the task and Order Approval
        for(Task tskRec : taskToOrderApprovalMap.keySet())
        {
            if(tskRec.Approval_Request_Id__c == null)

                /*{
                    for (Apttus_Approval__Approval_Request__c apprvlRec: ddApprovalRequestList)
                    {
                        if(tskRec.Approval_Request_Id__c == apprvlRec.Id && apprvlRec.Deal_Desk_Approvals_Required__c.contains(customSettings.ApprovalRequestSmallDealCheck__c))
                        {
                            taskToUpdateSet.add(tskRec.Id);
                            orderApptoUpdateList.add(taskToOrderApprovalMap.get(tskRec));
                        }
                    }
                }
            else*/
            /*
                {
                    taskToUpdateSet.add(tskRec.Id);
                    orderApptoUpdateList.add(taskToOrderApprovalMap.get(tskRec));
                }

        }


    if(taskToUpdateSet.size() > 0)
        {
            taskList = [Select Id, Status,Description,OwnerId,CreatedById From Task Where Id IN :taskToUpdateSet];
        }
        System.Debug('Task List '+taskList);
        for( Task task : taskList)

        {
            String existingComment ;

            task.Status = gsmMap.get('OA_smallDealTaskStatus');// 'Completed' ; //SFDC-2304
            if(task.Description != null)
                task.Description = task.Description + '   ' +gsmMap.get('OA_smallDealTaskDescription'); // Old Description + 'Auto rejected as Opportunity is a Small Deal' //SFDC-2304
            else
                task.Description = gsmMap.get('OA_smallDealTaskDescription'); // 'Auto rejected as Opportunity is a Small Deal' //SFDC-2304
            task.OwnerId = task.CreatedById;

            taskToUpdate.add(task);
        }

        for(Order_Approval__c oaRecord : orderApptoUpdateList)
        {
            oaRecord.Deal_Desk_Approval_Notes__c = gsmMap.get('OA_smallDealOANotes'); //'Auto rejected as Opportunity is a Small Deal'; //SFDC-2304
            oaRecord.Deal_Desk_Status__c = gsmMap.get('OA_smallDealOAStatus'); //'Not Needed'; //SFDC-2304
            oaRecord.Reason_Code_1__c = gsmMap.get('OA_smallDealOAReasonCode1'); //'Small Deal - Auto Reject'; //SFDC-2304
            oaRecord.Validation_Override__c = true;
            ddOrderAppListToUpdate.add(oaRecord);
        }

        if(ddOrderAppListToUpdate.size() > 0)
            update ddOrderAppListToUpdate;

        if(taskToUpdate.size()>0)
            update taskToUpdate;

        DealDeskActivity_UpdateTaskFirstRunFlag = false;
        

    }
    */
    
    /**
       TestIntitFuncs()
       - Tests the static variables intitialize functions
    */
     //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //public static testmethod void TestIntitFuncs()
    //{
    //    // Legit call
    //    system.assertEquals(InitAll(),true);
    //    // Duplicate call
    //    system.assertEquals(InitAll(),false);
    //    system.assertEquals(oaTaskRecTypeInit(),false);
    //    system.assertEquals(oaUsersInit(),false);
    //    system.assertEquals(oaProfilesInit(),false);
    //} 
 
 /*
 // CR 1088616 1Click Enhancement: Notify Rep of recent extension -- start --     
    public static void oneClickExtensionStatusUpdate(Map<Id, Order_Approval__c> oaMap)
    {   
        List<Merge_Contract_Header__c> mrgContractHeaderList = new List<Merge_Contract_Header__c>();
        for (Merge_Contract_Header__c mch : [Select Id,  Original_Contract_Id__c, X1Click_Last_Extended_OA_Id__c, X1Click_Extension_Status__c 
                                     from Merge_Contract_Header__c
                                     where X1Click_Last_Extended_OA_Id__c IN : oaMap.keySet()])
        {
            //if (oaMap.get(mch.X1Click_Last_Extended_OA_Id__c)!=null)
            //{
                if(oaMap.get(mch.X1Click_Last_Extended_OA_Id__c).Order_Form_Uploaded__c)
                    mch.X1Click_Extension_Status__c = 'Successful';
                else //if (!oaMap.get(mch.X1Click_Last_Extended_OA_Id__c).X1ClickUpdateContractCheck__c) 
                    mch.X1Click_Extension_Status__c = 'Failed';
                mrgContractHeaderList.add(mch);
            //}                                 
        }
        if (mrgContractHeaderList.size()>0)
            update  mrgContractHeaderList;
    }
// CR 1088616 1Click Enhancement: Notify Rep of recent extension -- end --
*/
}