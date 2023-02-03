/*=============================================================================================================+  
CaseTriggerClass
@version 1.0
@author : Karteek Mekala <kmekala@akamai.com>
@Description : This class implements functions that are called by Trigger events on 'Case'.
The following functionality is implemented :
- Update the Case.ContactId with the Case.CreatedById when Case.ContactId = null
- Add the Case.Created By User to the Case Team with Role = 'Reporter'  

@History
--Developer           --Date            --Change
Karteek Kumar M       18/03/2010        Created the class.
Vinayendra T N        22/12/2010        Added 2 functions for Momentum Cases
1.public static void updateAssociatedEmail(Case[] cases)
Updates AssociatedEmail field if case is created in UI
2.public static void EmailToCaseSendEmail(Case[] cases,Email_to_Case__c CustomSettings,String[] ccAddress)
Sends email to Created and CC list wih case and attachments.  
Ali KM                10/03/2013        CR 2068273 - Adding flag to bypass CaseTrigger code for IR Case Creation.      
Pitamber Sharma       09/05/2013        Added a method to update Case Entitlement and also updated the api version to 27.
Vinod Kumar           13/06/2013        Add a Function to update the Case-Entitlement if case is a Stability Engineering
Pitamber Sharma       05/07/2013        Added a Function to Change case owner based on avaialability of user, if Case owner is Primary/Secondary Assignment Queue.
Pitamber Sharma       11/07/2013        Added a Function to update the Case.ContactPhone if contact is updated on the case.
Pitamber Sharma       26/07/2013        Added a Function to add a record in Case Update History object when Case.Last_Case_Update is updated.
Pitamber Sharma       03/08/2013        Added a function to send new Case Email to Primary/Secondary Account Team Members.
Vijetha Vijayendran   27/03/2013      Added routing logic for GSS CSAT cases in the method ChangeCaseOwner
Kunal Sharma          05/21/2014      Commented out the method 'sendEmailToContact' as this is now included in WF's. Modified methods for 
record type check.
Akhila Vidapanapati   19/05/2014      Added sendEmailToCaseNotificationSubscription method to send notifications to manual subscribers on Account.
Commented out SendEmailToAccountTeam method by replacing it with workflow.
Himanshu            27-Jun-14       Replace Business Hour Query by custom setting   
Akhila Vidapanapati 28-Jun-14     Added ChangePSCaseOwner method for PS Case Routing
Himanshu            01-Aug-14       Added Active Condition to all User and AccountTeamMember Query
Kunal Sharma        08/22/14        CR# 2638839: Added Verivue functionality.
Akhila Vidapanapati 10/28/14        Added Impacted Accounts functionality - UpdateAccountsProductsonSI
Akhila Vidapanapati 24-11-14        CR# 2804070: Changed Case Routing For geo APJ/EMEA
Akhila Vidapanapati 24/02/2015    CR 2921691 - Emails not sent when using 'Send Notification Email' check box
Himanshu            02-Mar-15       CR# 2863524: Added method - setCaseOwnerWithStatus to remove redundancy code
Akhila Vidapanapati 27-04-15        CR# 2919657: IR Milestone for AMG customer onboarding Cases
Akhila              25-06-15      CR# 3024056: Modified ChangePSCaseOwner method, this will be called in before trigger 
Kunal Sharma        27 JUL 2015     CR# 3077331: Added New Parameter  in setCaseOwnerWithStatus method to stamp User Detail on Case
Akhila              22 Sep 2015     CR#3142911 : Bug: Production issue"SMP Cases going to wrong queue"
Deepak Saxena       07-Jan-2016       CR#3098331 :Commented ChangePSCaseOwner in 16.1
Sonia               11-Mar-2016     CR# 3320211 - GDRAT-to-DGRAT reorg: AMG functionality fixes - Replaced all Geography checks to use the custom setting
Aditya Sonam:       25-04-2016    : CR:3290661 - CCare Technical Escalation Automation
Aditya Sonam        31-05-2016      CR 3418331 - Routing Fix and User Query Optimization
Himanshu Kar        17-JUN-2016       3333321(16.6)     Create BOCC Entitlement
Vamsee S            09-Jun-2016     3378851       Modification of AMG Case Routing
Himanshu Kar        17-AUG-2016       3183601(16.8)     Create BOCC Entitlement
Pinkesh Rathore     23-SEP-2016       3511751       Updated Case Notification Subscription
Vamsee Surya        26-SEp-2016       3366861       Milestones for AMG Cases irrespective of Support Level
Vamsee Surya        24-Nov-2016       3564721       Automate Billing case assignment to team members
Pinkesh Rathore     29-JAN-2016       3626351       Remove DGRAT values that have been deleted with 2017 DGRAT realignment
Vandhana K.         27-May-2017     JIRA ESESP-551      Cases for Specialist Pre-Sales - Part 2
Aditya Sonam        21-Jun-2017     ESESP-574   Create Standard SLA override for Enterprise products
Vandhana            27-June-2017    JIRA ESESP-389      Better logging for field "Living Summary/Next Steps"
Aditya Sonam        21-Sept-2017    ESESP-435 : NQLB Connector Setup -> Community Response Milestone Setup
Vandhana            04-Oct-2017     ESESP-354 : Service Entitlement enablement
Vandhana            23-Nov-2017     ESESP-820 : Policy Domain association on Managed Security Cases
Vandhana            02-Jan-2018     ESESP-791 : AMG case routing 2.0  
Vikas               23-Jan-2018     ESESP-958 : Case sensitive check for PD linking
Vamsee              28-Feb-2018     ESESP-1059  Case Notification Subscription Fix
Sumanth             10-March-2018   ESESP-1004  External Dependency JIRA check for Solution Code - Nominum
Vandhana            12-April-2018   ESESP-834   Octoshape Escalation process
Sumanth             17-April-2018   ESESP-1086  Soasta Support Transition to Akatech -2
Vandhana            20-April-2018   ESESP-603   Specifying Support Advocacy (SDM) + Time Based Escalations for Premium_2.0 accounts
Sumanth             16-May-2018     ESESP-1204  Send Ownership Change Email to Old/New Owner & Case Creator
Vandhana            29-May-2018     ESESP-1027  Disable auto-creation of CCare Escalation ER for Enterprise Case Products
Vandhana            21 June 2018    ESESP-692 : Force close activities before closing ECOB/NCOB AMG cases
Vandhana            19 Sep 2018     ESESP-430 : Close activities as invalid when case is closed as invalid
Vandhana            19 Sep 2018     ESESP-688 : Ownership of tasks included in a case should always reflect the case owner
Pinkesh             22 Oct 2018     ESESP-502 : Update "Impacted Accounts" section on the Service Incident for all the cases except the ones with case recordType = Invalid Case
Vandhana            24 Oct 2018     ESESP-1409: AMG Case Mgmt Improvement
Sumanth             13 Dec 2018     ESESP-1861   Correction on Jira pushed on ESESP-1409
Vandhana            19 Dec 2018     ESESP-1891   Xiphos Email Notifications to Customers
Aditya              18-Jan-2019     ESESP-1402: Creation of a queue for AMP
Sumanth             26-Feb-2019     ESESP-1916  Attachment Mandatory before closing AMG Migration Case
Aditya              28-Feb-2019     ESESP-1901  Non AMG user assigned as AMG Case owner when case record type changed from Non AMG to AMG
Vishnu              02-Jul-2019     ESESP-758   AMG Case Mgmt Improvement: AMG SLA improvements 

Vishnu              14-Aug-2019     ESESP-2362  CMG Team Case Management System from E-mails
Vandhana            22-Aug-2019     ESESP-1937  AMG Case Routing Update   
Sumanth             26-Aug-2019     ESESP-1117  SOCC Related Changes...
Vandhana            26-Sept-2019    ESESP-2635 AMG : AMG cases to be assigned ONLY to AMG queues (or AMG agents)
Sheena              05-Feb-2020     ESESP-3075 AMG : Partner Account and Indirect Customer functionality for AMG cases
Sheena              05-Feb-2020     ESESP-2872 :Related Cases functionality for AMG Cases
Sheena              10-Feb-2020     ESESP-3152: Method for populating Account Owner and AMG Aligned Rep fields for AMG cases   
Harshil             26-Feb-2020     ESESP-2917  Exceda: Entitlement assigned for corresponding support levels as in Exceda Migration
Vamsee              13-May-2020     ESESP-1432 BOCC to Technical Lightning Migration 
                                               Moved updateCaseEntitlement method to SC_CaseTriggerHelperClass
Sheena              08-Feb-2020     ESESP-2347 Akachat: Added Automated Process check in UpdateContactName.                                     
Vandhana            20-July-2020    ESESP-2597 New "instant Engagement Request" flag for Sev 1 cases for support advocacy services    
Sharath             22-july-2020    ESESP-3659 Billing case Lightning migration
Sheena              11-Sep-2020     ESESP-3809  IRAPT: Commenting the functionality of Impacted Accounts for BMC_objects

Tejaswini           09-Dec-2020     ESESP-3944 Removing the dependency of Remove Priority Expiry Date, Priority Type and Checkbox fields
Tejaswini           06-Jan-2020     ESEP- 4606 Added new custom setting value for AMG Dgrat changes
Vandhana            22-02-2020      ESESP-2346 Carrier LX Migration
Aravind             23-03-2020      ESESP-4941 AMG case routing logic updated to use GRAZT fields
Vikas 				23-07-2021		ESESP-5442 Added Escalation Emails also for Xiphos Email Notifications to Customers
Sujay               11-10-2021      ESESP-5981 : to ensure to have product check case insensitive while a task is auto created.

+=====================================================================================================

List of Test Classes -
* CaseTriggerTestClass
* Test_EmailToCaseHandler
* SC_Case_Trgr_EmlServc_Class_TC
* SC_Case_Trgr_EmlServc_Class_TC2
* SC_Billing_Configuration_Test
* SC_Autogen_ExistingCOB_TC
* SC_BOCC_Sync_Contract_Eng_MrktgProd_TC
* SC_AMG_Lightning_Test
* SC_PolicyDomain_Test
* TestEmailMessageTriggerHandler

*/

public class CaseTriggerClass 
{
    private static string CaseCreateTemplate;
    public static Boolean isOneTimeRun = True;
    private static string OrgWideAdd;
    Public static Boolean irCaseEscalOwnerFirstRunFlag=true;
    public static Boolean isIRCaseCreationInprogress=false;
    private static Boolean addCaseHistoryFirstRun = true;
    private static Boolean isEmailToCaseFirstRun = false;
    private static Boolean isEmailToAccountTeamFirstRun = false;
    public static Boolean scPSUpdateFlag = true;
    public static SC_DGRAT_Reorg_Mapping__c DGRATMapping=  SC_DGRAT_Reorg_Mapping__c.getInstance();
    
    /**Variable to avoid recursion**/
    public static boolean isFirstTime = true; 
    /**Variables used as part of ESESP 934 **/
    public static boolean avoidAssignment = false;
    public static boolean avoidRecurrsionms = true;
    /**Variables used for ESESP-1204**/
    public static boolean avoidRecurrsionpresales = true;
    //Variables added by Vamsee : Recursion Check - ESESP-1514
    public static boolean avoidRecursionBusinessHours = true;
    public static boolean avoidRecursionUpdateEntitlement = true;
    public static boolean avoidRecursionSOCCLogic = true;
    
    /**
UpdateContactName()
- Update the Case.ContactId with the Case.CreatedById when Case.ContactId = null
- This is achieved in the following steps :
1. Get the 'User.AKAM_User_ID' of the UserId of user.
2. Get the 'Contact.Id' of the Contact where 'Contact.AKAM_Contact_Id' = 'User.AKAM_User_Id'
3. If 'Case.ContactId' == null, then stamp the 'Contact.Id' field from the previous step.
*/
    // Changes by Sheena: Moved it to SC_CaseTriggerHelperClass2 Class
   /* public static void UpdateContactName(Case[] cases)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User') && !UserInfo.getName().equalsIgnoreCase('Automated Process'))
        {
            // Get the User Records
            List<User> users = [select Id, AKAM_User_ID__c from User where Id = :UserInfo.getUserId()];
            
            // Get a map of UserId -> AKAM User Id
            Map<Id, String> usrId_akamIdMap = new Map<Id,String>();
            
            for(User u:users)
            {
                usrId_akamIdMap.put(u.Id, u.AKAM_User_ID__c);
            }   
            
            List<Contact> contacts = [select Id, AKAM_Contact_ID__c from Contact where AKAM_Contact_ID__c IN :usrId_akamIdMap.values()];
            Map<String, Id> conMap = new Map<String, Id>();
             
            for(Contact con:contacts)
                conMap.put(con.AKAM_Contact_ID__c, con.Id);
            
            for(Case c:cases)
            {                
                if(c.ContactId == null && usrId_akamIdMap.containskey(UserInfo.getUserId()) && conMap.containsKey(usrId_akamIdMap.get(UserInfo.getUserId())))
                    c.ContactId = conMap.get(usrId_akamIdMap.get(UserInfo.getUserId()));
            }
        }  
    }*/
    
    /**
AddUserToCaseTeam(Id p_CaseId, Id p_UserID, String p_Role)
- Add the user to the Case Team as per the arguments passed.
-) Case
-) User
-) Role
*/
    public static CaseTeamMember AddUserToCaseTeam(Id p_CaseId, Id p_UserID, Id p_RoleId)
    {
        CaseTeamMember ctm = new CaseTeamMember();
        ctm.ParentId = p_CaseId;
        ctm.MemberId = p_UserID;
        ctm.TeamRoleId = p_RoleId;
        return ctm;
    }
    /**
AddCreatedByToCaseTeam(Case[] cases)
- Add the Case.Created By User to the Case Team
*/
    
    public static void AddCreatedByToCaseTeam(Case[] cases)
    {
        // Get the Team Role Id
        Id reporterTeamRoleId;
        Id createdById;
        
        for(CaseTeamRole ctr: [select Id from CaseTeamRole where Name='Reporter'])
            reporterTeamRoleId = ctr.Id;
        system.assertNotEquals(reporterTeamRoleId, null);
        
        // Add the Created by user to the Case team with Role = 'Reporter'
        List<CaseTeamMember> ctmInsertList = new List<CaseTeamMember>(); 
        
        set<string> userAliases = new set<string>();
        map<string, Id> caseUserMap = new map<string, Id>();
        for(Case cs:cases)
        {
            userAliases.add(cs.AKAM_Created_By__c);
        }
        list<User> caseUsers = [SELECT Id, Alias FROM User WHERE Alias in :userAliases and UserType = 'Standard' and UserRoleId != null and IsActive = true];
        for(User u:caseUsers)
        {
            caseUserMap.put(u.Alias, u.Id);
        }
        for(Case cs:cases)
        {
            if(cs.Email_to_case__c==false && !(!String.isBlank(cs.Origin) && cs.Origin.containsIgnoreCase('AkaChat')))// Dont add if its email to case and Akachat
            {
                if(UserInfo.getName().equalsIgnoreCase('Connection User'))
                {
                    if(caseUserMap.containsKey(cs.AKAM_Created_By__c))
                        createdById = caseUserMap.get(cs.AKAM_Created_By__c);
                }
                else
                {
                    createdById = cs.CreatedByID;
                }
                if(createdById != null)
                    ctmInsertList.add(AddUserToCaseTeam(cs.Id, createdById, reporterTeamRoleId));
            }
        }
        insert ctmInsertList;
    }
    /**
public static void updateAssociatedEmail(Case[] cases)
- Update Associated email field with userid`s email
*/
    /* Commented by Vamsee - ESESP-1604
public static void updateAssociatedEmail(Case[] cases)
{
if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
{
// Get CurrentUser
User currentUser = [select Id, Email from user where Id=:UserInfo.getUserId()][0];

for(Case c:cases)
{
c.Associated_Email__c = currentUser.Email;//Add user id to Associated Email field.
}
}          
}*/
    /**
public static void EmailToCaseSendEmail(Case[] cases,Email_to_Case__c CustomSettings,String[] ccAddress)
- Send email to user about the new case for momentum Record type.
*/
    public static void EmailToCaseSendEmail(Case[] cases,Email_to_Case__c CustomSettings,String[] ccAddress)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            //New email Message
            List<Messaging.Singleemailmessage> emailList = new List<Messaging.Singleemailmessage>();
            
            //Template Id
            caseCreateTemplate=CustomSettings.EmailTemplate__c;
            
            // Organisation wide email address
            OrgWideAdd=CustomSettings.OrgWide__c;
            
            // A map of case id and list of attachment
            Map<Id, List<Attachment>> CaseId_ListAttachMap = new Map<Id,List<Attachment>>();
            Set<Id> caseIdSet = new Set<Id>();
            for(Case c:cases)
            {
                caseIdSet.add(c.Id);
                CaseId_ListAttachMap.put(c.Id,new List<Attachment>());
            }
            // Get attachment of the partucular case
            List<Attachment> Attachments = [select Id, ParentId,Name,Body from Attachment where ParentId IN :caseIdSet];
            //throw new CustomException('Attachment Size : '+Attachments.size() + 'Case Set Size : ' + caseIdSet.size());
            // add the attachment to the list correspionding to the case
            for(Attachment a:Attachments)
            {
                CaseId_ListAttachMap.get(a.ParentId).add(a);
            }
            
            // get only address and remove name from emails
            String[] ccAddresses =new String[] {};
                if(ccAddress!=null && ccAddress.size()>0)
            {
                for (String address : ccAddress) 
                {
                    Matcher matcher = Pattern.compile('<.+>').matcher(address);
                    string tempemail;
                    
                    if (matcher.find())
                    {
                        String[] nameParts = address.split('[ ]*<.+>')[0].replace('"', '').split('[ ]+');
                        tempemail=matcher.group().replaceAll('[<>]', '');
                        if(tempemail!=CustomSettings.Queue_Email__c)
                            ccAddresses.add(tempemail);
                    } 
                    else
                    {
                        tempemail=address;
                        if(tempemail!=CustomSettings.Queue_Email__c)
                            ccAddresses.add(tempemail);
                    }
                }
            }
            
            for(Case c:cases)
            {
                List<Messaging.Emailfileattachment> efaList = new List<Messaging.Emailfileattachment>();
                // convert Attachment to Emailfileattachment
                for(Attachment a:CaseId_ListAttachMap.get(c.id))
                {
                    Messaging.Emailfileattachment efa = new Messaging.Emailfileattachment();
                    efa.setFileName(a.Name);
                    efa.setBody(a.Body);
                    efaList.add(efa);
                }
                //Send Email
                Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
                email.setTemplateId(CaseCreateTemplate);
                //Not able to set Queue as Set Target Object Id . Using custom setting to store the group address
                email.setTargetObjectId(CustomSettings.Contact__c);
                email.setWhatId(c.id);
                // Add Associated Email to cc
                ccAddresses.add(c.Associated_Email__c);
                //String[] ccAddresses =new String[] {c.Associated_Email__c};
                if(ccAddresses!=null)
                    email.setCcAddresses(ccAddresses);
                email.setOrgWideEmailAddressId(OrgWideAdd);
                email.setSaveAsActivity(true);
                //Add the attachments
                email.setFileAttachments(efaList);
                emailList.add(email);
                //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
            if(!Test.isRunningTest())
                Messaging.sendEmail(emailList);
        }  
    } 
    
    /*
*   Function to add/update Entitlement Name on case based on Account.SupportLevel and Custom setting values.
*   Related Task : T-140779
*   Added By : Pitamber Sharma
*/
    /*public static void updateCaseEntitlement(List<Case> lstCase, Map<Id, string> rTypes) {
        Map<String, Web_Entitlements__c> webEntitlements = Web_Entitlements__c.getAll();
        Map<String,EntitlementID__c> entitlementIds = EntitlementID__c.getAll();
        Set<String> entitlementNames = new Set<String>();
        
        // List to store BOCC case records
        List<Case> BOCCcaseList = new List<Case>();
        
        for(Web_Entitlements__c we : webEntitlements.values())
        {
            entitlementNames.add(we.Entitlement_Name__c);
        }
        
        Set<Id> accIds = new Set<Id>();
        Map<Id, Account> accMap;
        
        for(Case c : lstCase) 
        {
            accIds.add(c.AccountId);
            
            // Condition for BOCC Use Case
            if(rTypes.get(c.RecordTypeId) != null && (rTypes.get(c.RecordTypeId).equals('BOCC')) && c.AccountId != null)
            {    
                BOCCcaseList.add(c);
            }
        }
        
        //Commented by ssawhney, merged both queries into one to reduce the number of queries getting fired
        /*if(accIds.size() > 0) {
accMap = new Map<Id, Account>([Select Id, Support_Level__c from Account where Id IN : accIds]); 
}

Map<String, Entitlement> entitlementMap;
if(entitlementNames.size() > 0) { 
entitlementMap = new Map<String, Entitlement>();
for(Entitlement e : [Select Id, Name, AccountId from Entitlement Where Name IN : entitlementNames AND  AccountId IN : accIds AND  Status = 'Active']) {
entitlementMap.put(e.Name+e.AccountId, e); 
//Akhila - Changed the key to Name_AcctId to make it unique
}
}
        
        if(accIds.size() > 0) 
        {
            accMap = new Map<Id, Account>([Select Id, Support_Level__c, (Select Id, Name, AccountId from Entitlements Where Name IN : entitlementNames AND Status = 'Active') from Account where Id IN : accIds]); 
        }
        
        Map<String, Entitlement> entitlementMap;
        if(entitlementNames.size() > 0 && accMap.size() > 0) 
        { 
            entitlementMap = new Map<String, Entitlement>();
            for(Account acc : accMap.values()){
                if(acc.Entitlements != null && acc.Entitlements.size()>0)
                {
                    for(Entitlement e : acc.Entitlements)
                    {
                        entitlementMap.put(e.Name+e.AccountId, e); 
                    }
                }
            }
        }
        
        String key;
        Web_Entitlements__c we;
        Id CommunityResponseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
        
        for(Case c : lstCase) 
        {
            if(accMap.containsKey(c.accountId) && accMap.get(c.accountId).Support_Level__c != null && c.RecordTypeId != CommunityResponseRTId) {
                
                //Adding condition to seperate case with Legacy Type Null
                if(c.Legacy_Type__c == Null || c.Legacy_Type__c == '' || c.Legacy_Type__c=='SOASTA')
                {
                    key = rTypes.get(c.RecordTypeId).substring(0,3) + accMap.get(c.accountId).Support_Level__c;
                    if(webEntitlements.containsKey(key)) 
                    {
                        we = webEntitlements.get(key);
                        if(entitlementMap.containsKey(we.Entitlement_Name__c+c.AccountId)) 
                        {
                            c.EntitlementId = entitlementMap.get(we.Entitlement_Name__c+c.AccountId).Id;
                        }
                    }
                }
                //Applying standard Entitlement when Legacy Type is populated
                else
                {
                    if(c.Legacy_Type__c!='SOASTA')
                    {
                        key = rTypes.get(c.RecordTypeId).substring(0,3) + 'Standard';
                        if(entitlementIds.containsKey(key)) 
                        {
                            c.EntitlementId = entitlementIds.get(key).EntitlementID__c;
                        }
                    } 
                }
            }
            else if(c.RecordTypeId == CommunityResponseRTId)
            {
                c.EntitlementId = entitlementIds.get('Community Response').EntitlementID__c;
            }
        }
        
        // Calling BOCC Calculation for BOCC Entitlement setup
        if(BOCCcaseList.size() > 0)
        {    
            SC_CaseIssueClass scCls = new SC_CaseIssueClass();
            scCls.BOCC_Calculation(BOCCcaseList, entitlementMap);
        }
    }*/
    
    /** 
*   Function to update the business hour on case based on various conditions
*   Related Task : T-140865
*       Added By : Pitamber Sharma
*/
    public static void updateBusinessHours(List<Case> lstCase, Map<Id, string> rTypes, Boolean isUndelete) 
    {
        //Remove this code for Technical and Stability Engineering case and use AMG Support Hours for AMG & Billing Support Hours for Billing Cases.
        // Added this code back as per T-206784
        
        // Map to store Business Hour Name - ID
        Map<String, ID> businessHoursMap = new Map<String, ID>();
        
        /* for(BusinessHours bh : [Select Id, Name from BusinessHours where name IN ('Service Business Hours - 24x7', 'Service Business Hours - 24x5')]) {
businessHoursMap.put(bh.Name, bh);
} */
        
        // Loop for Business Hour Custom Setting
        for (SC_BusinessHour_Value__c eachBusinessHourRec : SC_BusinessHour_Value__c.getall().values())
        {    
            businessHoursMap.put(eachBusinessHourRec.Name,eachBusinessHourRec.BusinessHour_Id__c);
        }
        
        Set<Id> accIds = new Set<Id>();
        Map<Id, Account> accMap;
        
        for(Case c : lstCase) 
        {
            accIds.add(c.AccountId);
        }
        
        if(accIds.size() > 0) 
        {
            accMap = new Map<Id, Account>([Select Id, Support_Level__c from Account where Id IN : accIds]); 
        } 
        
        List<Case> updateableCases = new List<Case>();
        Id busHoursId;
        for(Case c : lstCase) 
        { 
            if(rTypes.get(c.RecordTypeId).equals('Technical')) 
            {
                if(c.Sub_Type__c != null && c.Sub_Type__c.equals('CMP Alerts')) 
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x7');
                }
                else if(c.Severity__c != null && (c.Severity__c.equals('1') || c.Severity__c.equals('2')))
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x7');
                } 
                else if(accMap.get(c.AccountId) != null && accMap.get(c.AccountId).Support_Level__c != null 
                        && accMap.get(c.AccountId).Support_Level__c.equals('Premium_EnhancedSLA'))
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x7');
                } 
                else if(c.Severity__c != null && c.Severity__c.equals('3')) 
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x5');
                }
            } 
            else if(rTypes.get(c.RecordTypeId).equals('Stability Engineering'))
            {
                if(c.Severity__c != null && c.Severity__c.equals('1'))
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x7');
                } 
                else
                {
                    busHoursId = businessHoursMap.get('Service Business Hours - 24x5');
                }
            }
            
            if(isUndelete) 
            {
                updateableCases.add(new Case(Id = c.Id, BusinessHoursId = busHoursId));
            }
            else
            {
                c.BusinessHoursId = busHoursId;
            }
        }
        
        if(updateableCases.size() > 0)
        {
            update updateableCases;
        }
    }
    
    
    //IR Case related code.
    public static void updateCaseShare(Boolean pIsInsert, Boolean pIsUpdate, List<Case> pCaseList, Map<Id,Case> pOldMap)
    {
        if (!irCaseEscalOwnerFirstRunFlag)
            return;
        
        List<CaseShare> cShareList = new List<CaseShare>();
        for (Case c : pCaseList)
        {   
            if (c.IR_Escal_Owner__c!=null && c.OwnerId!=c.IR_Escal_Owner__c)    
                cShareList.add(new CaseShare(CaseId=c.Id,UserOrGroupId=c.IR_Escal_Owner__c,CaseAccessLevel='Edit'));
        }
        
        if(cShareList.size()>0)
            database.insert(cShareList,false);
        
        if (pIsUpdate) // remove the old user
        {
            Map<Id,Id> caseIdOldEscalOwnerIdMap = new Map<Id,Id>();
            for (Case c : pCaseList)
            {
                If(pOldMap.get(c.Id).IR_Escal_Owner__c!=null)
                    caseIdOldEscalOwnerIdMap.put(c.Id,pOldMap.get(c.Id).IR_Escal_Owner__c);
            }
            
            if (caseIdOldEscalOwnerIdMap.size()>0)
            {
                List<CaseShare> toDeleteCaseShareList = new List<CaseShare>();
                for (CaseShare cs : [Select Id, CaseId, RowCause,UserOrGroupId FROM CaseShare 
                                     WHERE RowCause='Manual' AND CaseId IN :caseIdOldEscalOwnerIdMap.keySet() AND UserOrGroupId IN :caseIdOldEscalOwnerIdMap.values()])
                {
                    if (caseIdOldEscalOwnerIdMap.containsKey(cs.CaseId) && cs.UserOrGroupId==caseIdOldEscalOwnerIdMap.get(cs.CaseId))
                        toDeleteCaseShareList.add(cs);
                }
                if (toDeleteCaseShareList.size()>0)
                    Database.delete(toDeleteCaseShareList,false);
            }
        }
        irCaseEscalOwnerFirstRunFlag=false;
    }
    
    /* Moved this method to SC_CaseTriggerHelperClass class
    // Function to update the Case-Entitlement if case is a Stability Engineering
    // Related task: T-151317
    //Created By: Vinod Kumar
    public static void UpdateCaseEntitlement(boolean isInsert, list<Case> newList, map<ID,Case> oldmap,Map<Id, string> rTypes)
    {
        // get the Entitlement ID from the custome setting
        string entitlementIdForStabEngg = null;
        string entitlementIdForEmergingProd = null;
        map<string,string> mEntitleNameAndId = new map<string,string>();
        Map<String,Case> newMap = new Map<String,Case>();
        List<string> lSupportLevelValues = new List<string>();
        for(EntitlementID__c varEntitlementId: EntitlementID__c.getAll().values()){
            //[Select EntitlementID__c, Case_Record_Type__c From EntitlementID__c where Case_Record_Type__c ='Stability Engineering' limit 1]){
            entitlementIdForStabEngg = varEntitlementId.EntitlementID__c;
            mEntitleNameAndId.put(varEntitlementId.Case_Record_Type__c, varEntitlementId.EntitlementID__c);
            if(varEntitlementId.Name.equals('Exceda')){
                lSupportLevelValues = varEntitlementId.Support_Level__c.split(',');    
            }
        }
        Set<String> sSupportLevelValues = new Set<String>(lSupportLevelValues);
        
        // get case recordtype
        
        if(mEntitleNameAndId != null && mEntitleNameAndId.keySet().size()>0){
            
            for(Case cs:newList){
                newMap.put(cs.Id,cs);
                
                if(rTypes.get(cs.RecordTypeId).equals('Stability Engineering')){
                    
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Stability Engineering');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Stability Engineering')){
                        cs.EntitlementId = mEntitleNameAndId.get('Stability Engineering');
                    }
                }
                
                else if(rTypes.get(cs.RecordTypeId).equals('Emerging Products Engineering')){
                    
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Emerging Products Engineering');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Emerging Products Engineering')){
                        cs.EntitlementId = mEntitleNameAndId.get('Emerging Products Engineering');
                    }
                } 
                
                else if(rTypes.get(cs.RecordTypeId).equals('AMG'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('AMG');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('AMG')){
                        cs.EntitlementId = mEntitleNameAndId.get('AMG');
                    }
                } 
                
                // changes by Vandhana for Carrier LX Migration
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && cs.Sub_Type__c == 'Carrier' )
                {
                    cs.EntitlementId = mEntitleNameAndId.get('Carrier Products');
                }
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && (cs.Sub_Type__c == 'Security Event' || cs.Sub_Type__c == 'SSL Support'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                    else if(cs.Sub_Type__c == 'SSL Support' && cs.EntitlementId != mEntitleNameAndId.get('Technical')){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Technical')){
                        cs.EntitlementId = mEntitleNameAndId.get('Technical');
                    }
                }
                //Setting ENtitlement Id for Customer onboarding Cases of AMG record type
                else if((isInsert || (cs.EntitlementId != mEntitleNameAndId.get('Technical'))) 
                        && 
                        rTypes.get(cs.RecordTypeId).equals('AMG') && (cs.Service__c == 'Accounts Audits' && cs.Request_Type__c == 'Customer Onboarding' && 
                                                                      cs.Work_Type__c == 'Proactive' && cs.Severity__c == '3' && cs.Do_Not_Show_in_Portal__c))
                {
                    cs.EntitlementId = mEntitleNameAndId.get('Technical');
                }   
                
                // ESESP-2362 CMG Team Case Management System from E-mails
                else if(rTypes.get(cs.RecordTypeId).equals('CMG'))
                {
                    if(isInsert){
                        cs.EntitlementId = mEntitleNameAndId.get('CMG');
                    }
                    else if(!rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('CMG')){
                        cs.EntitlementId = mEntitleNameAndId.get('CMG');
                    }
                }
                // Changes by Harshil:
                // ESESP - 2917 Exceda support level Entitlement assignment
                else if(rTypes.get(cs.RecordTypeId).equals('Technical') && sSupportLevelValues.contains(cs.Support_Level__c))
                {
                    System.debug('In technical');                    
                    
                    //Added Record Type change check - ESESP-5341
                    if(isInsert || oldmap.get(cs.ID).Support_Level__c != newMap.get(cs.Id).Support_Level__c || oldmap.get(cs.ID).RecordTypeId != newMap.get(cs.Id).RecordTypeId)
                    {
                        cs.EntitlementId = mEntitleNameAndId.get('TechnicalAll');
                    }
                }

                // Changes by Sharath for ESESP-3659 Billing Case migration: Check for the Billing record type
                else if(rTypes.get(cs.RecordTypeId).equals('Billing') && 
                        (isInsert || !rTypes.get(oldmap.get(cs.ID).RecordTypeId).equals('Billing')))
                {
                     cs.EntitlementId = mEntitleNameAndId.get('Billing');
                }
                System.debug(cs.EntitlementId);
            }
        }
    }*/
    
    /** 
*   Function to set Recent_Update__c = true if fields Subject, Severity or Description 
*       are updated by a user who is not case owner
*   Related Task : T-157179
*       Added By : Pitamber Sharma
*/
    public static void setRecentUpdateTrue(List<Case> newCases, Map<Id, Case> oldCaseMap)
    {
        for(Case c : newCases) 
        {
            if(isChanged(c.Subject, oldCaseMap.get(c.Id).Subject) || isChanged(c.Description, oldCaseMap.get(c.Id).Description) 
               || isChanged(c.Severity__c, oldCaseMap.get(c.Id).Severity__c)) 
            {
                c.Recent_Update__c = true;
            }
        }
    }
    
    /** 
*   Private function to check for a field is changed or not
*   Related Task : T-157179
*       Added By : Pitamber Sharma
*/
    private static Boolean isChanged(String newVal, String oldVal) 
    {
        if(newVal == null) 
        {
            if(oldVal != null) 
            {    return true;    }
            return false;
        } 
        else 
        {
            if(oldVal == null) 
            {    return true;    }
            return (!newVal.equals(oldVal));
        }
    }
    
    
    //This flag is to avoid recursion of setting Primary/Secondary Available flag. 
    //This is done at the beginning of the transcation
    public static Boolean isPrimarySecondaryFlagSet = False;
    //This flag is to avoid recursion of executing the logic of setting owner after Assignment rule
    public static Boolean isAccountTeamMemberLogicExecuted = False;
    
    //Function to Change PS Case owner
    public static void changePSCaseOwner(List<Case> newCases,Set<Id> accIds,Map<Id, Case> oldCaseMap, Boolean isInsert, Map<Id, String> rTypesMap)
    {                
        /*
Map<Id, Account> accountMap;
Id psqueueID = SCUserIdCustomSetting__c.getValues('Primary/SecondaryAssignmentQueue').UserId__c;
Map<Id, List<AccountTeamMember>> accountTeamMembersMap = new Map<Id, List<AccountTeamMember>>();        
Account acct;
Id psPrimId = null;
String psPrimManagerName;
Id serPrimId = null;
String serPrimManagerName;
Id serSecId = null;
String serSecManagerName;
//Boolean userPSAssigned = false;
Id acctId;

if(accIds.size()>0)
{    
//fetching account details
accountMap = new Map<Id, Account>([Select Id, Support_Level__c, Geography_Formula__c, Division_Formula__c, Area__c From Account Where Id IN : accIds]);        

//fetching account team members details
for(AccountTeamMember atm : [Select AccountId, UserId, TeamMemberRole, User.Manager.Name From AccountTeamMember 
Where AccountId IN : accIds AND (TeamMemberRole = 'Services - Secondary' OR TeamMemberRole = 'Services - Primary' OR TeamMemberRole = 'PS - Primary') AND User.IsActive = true]) {
if(!accountTeamMembersMap.containsKey(atm.AccountId)) 
{
accountTeamMembersMap.put(atm.AccountId, new List<AccountTeamMember>());
}
accountTeamMembersMap.get(atm.AccountId).add(atm);
}

for(Case cs: newCases)   
{
psPrimId = null;
serPrimId = null;
serSecId = null;

if(accountTeamMembersMap.containsKey(cs.Indirect_Customer__c) || accountTeamMembersMap.containsKey(cs.AccountId)) {           

acctId = accountTeamMembersMap.containsKey(cs.Indirect_Customer__c) ? cs.Indirect_Customer__c : cs.AccountId; 
acct=accountMap.get(acctId);

for(AccountTeamMember atm : accountTeamMembersMap.get(acctId)) {

if(atm.TeamMemberRole == 'PS - Primary')
{
if(!isPrimarySecondaryFlagSet)
{
cs.PrimarySecondaryUnavailable__c = False;
}
psPrimId = atm.UserId;
psPrimManagerName = atm.User.Manager.Name;
//break the loop when ps primary is available as this is of the highest priority.
break;
}
//Services - Prim/Sceondary check when geo=Americas  
else if(acct.Geography_Formula__c != null && DGRATMapping.Geography_AMERICAS__c.containsIgnoreCase(acct.Geography_Formula__c) && cs.Service__c!=null && (cs.Service__c == 'Premium' || cs.Service__C == 'Luna-generated request'))
{
if(serSecId == null && atm.TeamMemberRole == 'Services - Secondary'){
if(!isPrimarySecondaryFlagSet)
{
cs.PrimarySecondaryUnavailable__c = False;
}                        
serSecId = atm.UserId;
serSecManagerName = atm.User.Manager.Name;
}

else if(serPrimId == null && atm.TeamMemberRole == 'Services - Primary'){
if(!isPrimarySecondaryFlagSet)
{
cs.PrimarySecondaryUnavailable__c = False;
}                        
serPrimId = atm.UserId;
serPrimManagerName = atm.User.Manager.Name;
}
}
}

if(isPrimarySecondaryFlagSet && !isInsert && cs.OwnerId == psqueueID && oldCaseMap.get(cs.Id).OwnerId != cs.OwnerId ){
isAccountTeamMemberLogicExecuted = true;
if(psPrimId!=null)
{
cs.OwnerId = psPrimId;
cs.Status = 'Assigned';
cs.SC_Manager__c = psPrimManagerName;
}
else if(serSecId!=null)
{
cs.OwnerId = serSecId;
cs.Status = 'Assigned';
cs.SC_Manager__c = serSecManagerName;
}
else if(serPrimId!=null)
{
cs.OwnerId = serPrimId;
cs.Status = 'Assigned';
cs.SC_Manager__c = serPrimManagerName;
}  
}  
}    

//To avoid setting the flag multiple times  and to set PrimarySecondaryUnavailable__c to true if no AccountTeamMember is available               
if(!isPrimarySecondaryFlagSet && psPrimId==null && serPrimId== null && serSecId==null)
{
cs.PrimarySecondaryUnavailable__c = True;
}
} 
isPrimarySecondaryFlagSet = true;
}
*/
    }                
    
    /** 
*   Funtion to Change case owner based on avaialability of user, if Case owner is Primary/Secondary Assignment Queue.
*   Related Task : T-159839
*       Added By : Pitamber Sharma
*       Updates:
*   Added logic to check for indirect customers also as per T-162206 (Pitamber Sharma) 7/18/2013
*   Added logic to bypass avaialbility if subtype contains certain vaules as per T-163514 (Pitamber Sharma) 7/19/2013
*   Added logic to assign case to correct queue if not primary/secondary user found available, based on Geo values.
*   changes by Vandhana : Added profile check for AMG ESESP-791
*   changes by Vandhana : added Backup User for AMG user who is unavailable ESESP-734
*   changes by Vandhana : AMG Case Routing Revamp ESESP-1937
*   changes by Aravind : AMG Routing Changes for DGRAT changing to GRAZT ESESP-4941
*/
    public static void changeCaseOwner(List<Case> newCases, Map<Id, Case> oldCaseMap, Boolean isInsert, Map<Id, String> rTypesMap) 
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            Set<Id> accIds = new Set<Id>();
            List<Case> selectedCases = new List<Case>();
            Set<Id> caseIds = new Set<Id>();
            
            Id primarySecondaryQId;
            Map<String, Id> queueMap = new Map<String, Id>();
            for(Group g : [Select Id, Name From Group Where Type = 'Queue' 
                           And Name IN ('Primary/Secondary Assignment Queue',
                                        'AMG APJ Hotseat Queue', 
                                        'AMG EMEA Hotseat Queue',
                                        'AMG NA Hotseat Queue',
                                        'AMG Orphan Queue',
                                        'PS Orphan Queue'/*,
                                        'AMG ECG Queue'*/) ]) 
            {
                queueMap.put(g.Name, g.Id);
                if(g.Name.equals('Primary/Secondary Assignment Queue')) {
                    primarySecondaryQId = g.Id;
                }
            }
            
            for(Case cs : newCases)
            {
                if(isInsert && cs.OwnerId == primarySecondaryQId && rTypesMap.containsKey(cs.RecordTypeId)) 
                {
                    accIds.add(cs.Indirect_Customer__c != null ? cs.Indirect_Customer__c : cs.AccountId);
                    selectedCases.add(cs);
                } 
                else 
                    if(cs.OwnerId == primarySecondaryQId && oldCaseMap.get(cs.Id).OwnerId != cs.OwnerId && rTypesMap.containsKey(cs.RecordTypeId)) 
                {
                    System.debug('Case Owner' + cs.OwnerId);
                    System.debug('Case Indirect_Customer__c ' + cs.Indirect_Customer__c);
                    System.debug('Case cs.AccountId ' + cs.AccountId); 
                    System.debug('Account' + cs.Indirect_Customer__c != null ? cs.Indirect_Customer__c : cs.AccountId);
                    accIds.add(cs.Indirect_Customer__c != null ? cs.Indirect_Customer__c : cs.AccountId);                                               //Add Correct Account Id here
                    selectedCases.add(cs);
                     System.debug( 'accIds ' +  accIds);
                }
            }
            
            Map<Id, List<AccountTeamMember>> accontTeamMembersMap;
            Map<Id, Account> accountMap;
            Set<Id> userIds;
            Map<id, User> userMap;
            Set<Id> backupUserIds = new Set<Id>();
            Map<Id, User> backupUserMap = new Map<Id,User>();
            Map<Id, Id> usrBkpUsrMap = new Map<Id,Id>();
            
            if(accIds.size() > 0)
            {
                //Modified the query to fetch the Region (Division__c) field from Account to define the new DGRAT Structure
                //Adding Finance Region as part of Jira 1861
                accountMap = new Map<Id, Account>([SELECT Id, TERR_HIER_1__c, TERR_HIER_5__c, Finance_Region__c 
                                                   FROM Account 
                                                   WHERE Id IN : accIds]);
                userIds = new Set<Id>();
                accontTeamMembersMap = new Map<Id, List<AccountTeamMember>>();
                
                for(AccountTeamMember atm : [Select AccountId, UserId, TeamMemberRole 
                                             From AccountTeamMember 
                                             Where AccountId IN : accIds 
                                             AND (TeamMemberRole = 'Services - Secondary' OR TeamMemberRole = 'Services - Primary') 
                                             and User.IsActive = true]) 
                {
                    if(!accontTeamMembersMap.containsKey(atm.AccountId)) 
                    {
                        accontTeamMembersMap.put(atm.AccountId, new List<AccountTeamMember>());
                    }
                    userIds.add(atm.UserId);
                    accontTeamMembersMap.get(atm.AccountId).add(atm);
                }
                userMap = new Map<Id, User>([Select Id, Availability__c, Manager.Name, Support_Role__c, Shift__c,
                                             Owner_Support_Department__c, Office_Location__c, Team__c,
                                             Profile.Name, Backup_User__c,Name
                                             From User 
                                             Where Id IN :userIds and IsActive = true]);  

                for(User eachUser : userMap.values())
                {
                    if(String.isNotBlank(eachUser.Backup_User__c))
                    {
                        backupUserIds.add(eachUser.Backup_User__c);
                        usrBkpUsrMap.put(eachUser.Id,eachUser.Backup_User__c);
                    }   
                }
                
                backupUserMap = new Map<Id,User>([Select Id, Availability__c, Manager.Name, Support_Role__c, Shift__c,
                                                  Owner_Support_Department__c, Office_Location__c, Team__c,
                                                  Profile.Name
                                                  From User 
                                                  Where Id IN :backupUserIds and IsActive = true]);
            }
            
            //Set DMLOption to set case back to assignment rule if no user found
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            
            List<Case> userFoundCases = new List<Case>();
            Boolean userAssigned = false;
            //Change as part of CR #2804070 to route differently when Geo is APJ/EMEA
            Boolean ServicesUserListed = false;
            Case ca;
            Account acct;
            Id acctId;
            
            //Set<String> amgProfile = new Set<String>{'Support - AMG Agent','Support AMG Agent - Restricted Country'};
            Set<String> amgProfile = new Set<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'AMG Agent Profile List' limit 1].Value_Text__c.split(','));    
            
            for(Case cs : selectedCases)
            {
                // Setting to False to do calculation for each case
                userAssigned = false;
                //Setting to False for all and to true only if Geo is APJ/EMEA with Services member listed
                ServicesUserListed = false;
                
                if(accontTeamMembersMap.containsKey(cs.Indirect_Customer__c) || accontTeamMembersMap.containsKey(cs.AccountId)) 
                {           //Check for indirect customer here too
                    acctId = accontTeamMembersMap.containsKey(cs.Indirect_Customer__c) ? cs.Indirect_Customer__c : cs.AccountId;  
                    //Assign Id of correct account
                    
                    if(rTypesMap.get(cs.RecordTypeId).equals('AMG') || rTypesMap.get(cs.RecordTypeId).equals('GSS CSAT')) 
                    {
                        for(AccountTeamMember atm : accontTeamMembersMap.get(acctId)) 
                        {
                            // changes by Vandhana - added Profile check for AMG
                            if(atm.TeamMemberRole == 'Services - Secondary' && userMap.containsKey(atm.UserId) && amgProfile.contains(userMap.get(atm.UserId).Profile.Name)){
                              
                                ServicesUserListed = true;
                                String accId;
                                if(String.isNotBlank(cs.Indirect_Customer__c))
                                    accId = cs.Indirect_Customer__c ;
                                else
                                    accId = cs.AccountId;
                                
                                if(userMap.get(atm.UserId).Availability__c 
                                   || cs.Subject.containsIgnoreCase('Auto-provisioned CP Code')
                                   || 
                                   (
                                       (
                                           accountMap.containsKey(accId) &&
                                           DGRATMapping.Geography_EMEA__c.containsIgnoreCase(accountMap.get(accId).TERR_HIER_1__c) ||
                                           DGRATMapping.Territory_EMEA_AMG__c.containsIgnoreCase(accountMap.get(accId).TERR_HIER_5__c)
                                       )
                                       && 
                                    (cs.Request_Type__c == 'Order Form Review' || cs.Request_Type__c == 'Quarterly Business Review')
                                   ))
                                {
                                    setCaseOwnerWithStatus(cs.Id, atm.UserId, userFoundCases, userMap);
                                    userAssigned = true;
                                    break;
                                }
                                else
                                {
                                    if(usrBkpUsrMap.containsKey(atm.UserId))
                                    {
                                        if(backupUserMap.containsKey(usrBkpUsrMap.get(atm.UserId)) && backupUserMap.get(usrBkpUsrMap.get(atm.UserId)).Availability__c)
                                        {
                                            setCaseOwnerWithStatus(cs.Id, usrBkpUsrMap.get(atm.UserId), userFoundCases, new Map<Id,User>{usrBkpUsrMap.get(atm.UserId) => backupUserMap.get(usrBkpUsrMap.get(atm.UserId))});
                                            userAssigned = true;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                        
                        if(!userAssigned && !ServicesUserListed) 
                        {
                            for(AccountTeamMember atm : accontTeamMembersMap.get(acctId)) 
                            {
                                // changes by Vandhana - added Profile check for AMG
                                if(atm.TeamMemberRole == 'Services - Primary' 
                                   && userMap.containsKey(atm.UserId) 
                                   && amgProfile.contains(userMap.get(atm.UserId).Profile.Name))
                                {
                                    String accId;
                                    if(String.isNotBlank(cs.Indirect_Customer__c))
                                        accId = cs.Indirect_Customer__c ;
                                    else
                                        accId = cs.AccountId;
                                    
                                    if(userMap.get(atm.UserId).Availability__c || cs.Subject.containsIgnoreCase('Auto-provisioned CP Code')
                                       || 
                                       ((
                                           accountMap.containsKey(accId) &&
                                           DGRATMapping.Geography_EMEA__c.containsIgnoreCase(accountMap.get(accId).TERR_HIER_1__c) ||
                                           DGRATMapping.Territory_EMEA_AMG__c.containsIgnoreCase(accountMap.get(accId).TERR_HIER_5__c)
                                       )
                                        && 
                                        (cs.Request_Type__c == 'Order Form Review' || cs.Request_Type__c == 'Quarterly Business Review')
                                       ))  
                                    {
                                        // Calling setCaseOwnerWithStatus method
                                        setCaseOwnerWithStatus(cs.Id, atm.UserId, userFoundCases,userMap);
                                        userAssigned = true;    
                                        break;
                                    } 
                                    // changes by Vandhana - added Profile check for AMG
                                    else
                                    {
                                        if(usrBkpUsrMap.containsKey(atm.UserId))
                                        {
                                            if(backupUserMap.containsKey(usrBkpUsrMap.get(atm.UserId)) && backupUserMap.get(usrBkpUsrMap.get(atm.UserId)).Availability__c)
                                            {
                                                setCaseOwnerWithStatus(cs.Id, usrBkpUsrMap.get(atm.UserId), userFoundCases, new Map<Id,User>{usrBkpUsrMap.get(atm.UserId) => backupUserMap.get(usrBkpUsrMap.get(atm.UserId))});
                                                userAssigned = true;
                                                break;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    } 
                    /*
                    else 
                    {
                        System.debug('ENTERED OTHER SELECTED CASES');
                        for(AccountTeamMember atm : accontTeamMembersMap.get(acctId)) 
                        {
                            if(atm.TeamMemberRole == 'Services - Primary' && userMap.containsKey(atm.UserId)) 
                            {
                                // Calling setCaseOwnerWithStatus method
                                setCaseOwnerWithStatus(cs.Id, atm.UserId, userFoundCases,userMap);
                                userAssigned = true;    
                                break;
                            }
                        }
                        
                        if(!userAssigned) 
                        {
                            for(AccountTeamMember atm : accontTeamMembersMap.get(acctId)) 
                            {
                                if(atm.TeamMemberRole == 'Services - Secondary' && userMap.containsKey(atm.UserId)) 
                                {
                                    // Calling setCaseOwnerWithStatus method
                                    setCaseOwnerWithStatus(cs.Id, atm.UserId, userFoundCases,userMap);
                                    userAssigned = true;
                                    break;
                                }
                            }
                        }
                    }
                    */
                }
                
                if(!userAssigned) 
                {
                    ca = new Case(Id = cs.Id);
                    if(acctId == null) 
                    {
                        acctId = cs.Indirect_Customer__c != null ? cs.Indirect_Customer__c : cs.AccountId; 
                    }
                    acct = accountMap.get(acctId);  
                    
                    if(rTypesMap.get(cs.RecordTypeId).equals('AMG') || rTypesMap.get(cs.RecordTypeId).equals('GSS CSAT'))
                    {
                        //Added by Sonia for DRGAT changes to support mixed mode
                        /*if(rTypesMap.get(cs.RecordTypeId).equals('GSS CSAT') 
                           && ((acct.Area__c != null && acct.Area__c.containsIgnoreCase('ECG')) 
                               ||(acct.Area__c != null && acct.Area__c.containsIgnoreCase('Tele'))
                              )
                          )
                        {
                            ca.ownerId = queueMap.get('AMG ECG Queue');
                        }
                        else */if(acct.TERR_HIER_1__c != null)
                        {
                            //Changes by Tejaswini ESEP- 4606 Added new custom setting value for AMG Dgrat changes
                            if(DGRATMapping.Geography_AMERICAS__c.containsIgnoreCase(acct.TERR_HIER_1__c))
                            {
                                ca.ownerId = queueMap.get('AMG NA Hotseat Queue');
                            } 
                            else if(DGRATMapping.Geography_Americas_AMG__c.containsIgnoreCase(acct.TERR_HIER_5__c))
                            {
                                ca.ownerId = queueMap.get('AMG NA Hotseat Queue');
                            }
                            else if(DGRATMapping.Geography_APJ__c.containsIgnoreCase(acct.TERR_HIER_1__c))
                            {
                                ca.ownerId = queueMap.get('AMG APJ Hotseat Queue');
                            }
                            else if(DGRATMapping.Territory_APJ_AMG__c.containsIgnoreCase(acct.TERR_HIER_5__c))
                            {
                                ca.ownerId = queueMap.get('AMG APJ Hotseat Queue');
                            }
                            else if(DGRATMapping.Geography_EMEA__c.containsIgnoreCase(acct.TERR_HIER_1__c))
                            {
                                ca.ownerId = queueMap.get('AMG EMEA Hotseat Queue');
                            }
                            else if(DGRATMapping.Territory_EMEA_AMG__c.containsIgnoreCase(acct.TERR_HIER_5__c))
                            {
                                ca.ownerId = queueMap.get('AMG EMEA Hotseat Queue');
                            }
                            
                            /*else if(acct.Division__c.containsIgnoreCase('ECG') || acct.Division__c.containsIgnoreCase('Tele') || acct.Division__c.containsIgnoreCase('ISR')
                                    || acct.Area__c.containsIgnoreCase('ECG') || acct.Area__c.containsIgnoreCase('Tele') || acct.Area__c.containsIgnoreCase('ISR')
                                   )
                            {
                                ca.ownerId = queueMap.get('AMG ECG Queue');
                            }*/
                            else if(acct.Finance_Region__c=='N. America')
                            {
                                ca.ownerId = queueMap.get('AMG NA Hotseat Queue');
                            } 
                            else
                            {
                                ca.ownerId = queueMap.get('AMG Orphan Queue');
                            }
                        } 
                        else 
                        {
                            ca.ownerId = queueMap.get('AMG Orphan Queue');
                        }
                    } 
                    else 
                    {
                        ca.ownerId = queueMap.get('PS Orphan Queue');
                    }
                    userFoundCases.add(ca);
                }
            }
            
            if(userFoundCases.size() > 0) {
                Database.upsert(userFoundCases);
            }
        }    
    }
    
    // Called from - changePSCaseOwner, changeCaseOwner
    // It sets Case Owner and Status
    // Added new Parameter in the the method to stamp User Details on Case
    public static void setCaseOwnerWithStatus (Id caseId, Id OwnerId, List<Case> updateUserFoundCases, Map<Id,User> userMap)
    {
        
        // Creating Case Instance with Parameters
        Case ca = new Case(Id = caseId);
        ca.OwnerId = OwnerId;
        ca.Status = 'Assigned';
        
        ca.SC_Manager__c = userMap.get(OwnerId).Manager.Name;
        ca.Office_Location__c = userMap.get(OwnerId).Office_Location__c;
        ca.Shift__c = userMap.get(OwnerId).Shift__c;
        ca.Support_Role__c = userMap.get(OwnerId).Support_Role__c;
        ca.Team__c = userMap.get(OwnerId).Team__c;
        ca.Support_Department__c = userMap.get(OwnerId).Owner_Support_Department__c;    
        
        updateUserFoundCases.add(ca);
    }
    
    
    /** 
*   Funtion to update ContactPhone field on Case if Case Contact have been changed.
*   Related Task : T-157806
*       Added By : Pitamber Sharma
*/
    public static void updateCaseContactPhone(List<Case> newCases, Map<Id, Case> oldMap, Boolean isInsert) {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            Set<Id> contactIds = new Set<Id>();
            
            for(Case cs : newCases) {
                if(isInsert || isChanged(cs.ContactId, oldMap.get(cs.Id).ContactId)) {
                    contactIds.add(cs.ContactId);
                }
            }
            
            if(contactIds.size()>0){
                Map<Id, Contact> contactMap = new Map<Id, Contact>([Select Id, Phone From Contact Where Id IN : contactIds]);
                
                for(Case cs : newCases) {
                    if(cs.ContactId != null && contactMap.containsKey(cs.ContactId)) {
                        cs.Contact_Phone__c = contactMap.get(cs.ContactId).Phone;
                    }
                }
            }
        }  
    }    
    /** 
*   Funtion to add a record in Case Update History object when Case.Last_Case_Update is updated.
*   Related Task : T-165897
*       Added By : Pitamber Sharma
*/
    public static void addCaseHistory(List<Case> newCases, Map<Id, Case> oldMap) {
        if((!addCaseHistoryFirstRun && !Test.isRunningTest()) || UserInfo.getName().equalsIgnoreCase('Connection User')){
            return;
        }
        List<Case_Update_History__c> caseHistories = new List<Case_Update_History__c>();
        List<Case> lstCase = new List<Case>();
        for(Case c : newCases) {
            if(c.Last_Case_Update__c != null && c.Last_Case_Update__c != oldMap.get(c.Id).Last_Case_Update__c) {
                lstCase.add(c);
                if(c.Next_Case_Update_Due__c != null && c.Next_Case_Update_Due__c < System.Now())
                    caseHistories.add(new Case_Update_History__c(Case__c = c.Id, Case_Update_Time__c = c.Last_Case_Update__c,Violation__c = True));
                else
                    caseHistories.add(new Case_Update_History__c(Case__c = c.Id, Case_Update_Time__c = c.Last_Case_Update__c));
                
            }
        }
        
        if(caseHistories.size() > 0) {
            insert caseHistories;
        }
        addCaseHistoryFirstRun = false;
        if(lstCase.size() > 0)
            updateNextCaseUpdateDue(lstCase,oldMap);
    }
    
    // changes by Vandhana - moved sendEmailToCaseNotificationSubscription and sendEmailToCaseNotificationSubscription_future out to SC_CaseTriggerHelperClass2
    // changes by Vishnu - moved createEmailBody out to SC_CaseTriggerHelperClass2
    /** A method to send case notifications to manual subscribers(Notification Team)
Added By: Akhila
*/
    /*
    public static void sendEmailToCaseNotificationSubscription(List<Case> newCases)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            
            //OrgWideEmailAddress noReply = [Select Id From OrgWideEmailAddress Where Address = :SC_FromEmailAddress__c.getValues('Noreply').FromAddress__c Limit 1];
            Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
            
            Set<Id> accIds = new Set<Id>();
            Set<Id> conIds = new Set<Id>();         
            Map<Id, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();
            Map<Id,List<Case_Notification_Subscription__c>> Acc_Subscribers = new Map<Id,List<Case_Notification_Subscription__c>>();
            
            for(Case c : newCases)
            {
                if(c.AccountId != null)  
                    accIds.add(c.AccountId);
                
                if(c.ContactId != null)
                    conIds.add(c.ContactId);
            }
            
            Map<Id, Account> actMap = new Map<Id, Account>();
            if(accIds.size() > 0){
                for(Account eachAccount : [Select Id, Name From Account Where Id IN : accIds])
                    actMap.put(eachAccount.Id, eachAccount);
            } 
            
            Map<Id, Contact> conMap = new Map<Id, Contact>(); 
            if(conIds.size() > 0){
                for(Contact eachContact : [Select Id, Name From Contact Where Id IN : conIds])
                    conMap.put(eachContact.Id, eachContact);
            }
            //Creating Map of Account-CaseNotificationSubscription
            if(accIds.size()>0)
            {
                for(Case_Notification_Subscription__c  subscriber : [Select Account__c,Case_Record_Type__c,Portal_Visibility__c,Case_Origin__c,Sub_Type__c,Email__c from Case_Notification_Subscription__c where Account__c IN : accIds])
                {
                    if(!Acc_Subscribers.containsKey(subscriber.Account__c))
                    {
                        Acc_Subscribers.put(subscriber.Account__c,new list<Case_Notification_Subscription__c>());
                    }
                    Acc_Subscribers.get(subscriber.Account__c).add(subscriber);
                }
            }
            
            Messaging.Singleemailmessage email;
            List<Messaging.Singleemailmessage> emailList;
            
            emailList = new List<Messaging.Singleemailmessage>();
            
            if(Acc_Subscribers.size()>0)
            {  
                for(Case c : newCases)
                {
                    if(c.AccountId != null && Acc_Subscribers.get(c.AccountId)!=null)
                    {
                        List<String> toAddrs = new List<String>();
                        //List of subscribers for the case
                        for(Case_Notification_Subscription__c subscriber : Acc_Subscribers.get(c.AccountId))
                        {
                            if(((rtMap.get(c.RecordTypeId).getName() == subscriber.Case_Record_Type__c) && (subscriber.Portal_Visibility__c == 'All'||(c.Do_not_show_in_portal__c == false)) && 
                                ((c.Sub_Type__c == 'CMP Alerts' && subscriber.Sub_Type__c == 'CMP Alerts')||subscriber.Sub_Type__c == 'N/A' || subscriber.Sub_Type__c == 'All' || (c.Sub_Type__c!= 'CMP Alerts' && subscriber.Sub_Type__c == 'Non-CMP Alerts')) && 
                                (subscriber.Case_Origin__c == 'All' || subscriber.Case_Origin__c == 'N/A' || (c.Origin != 'Proactive' && c.Work_Type__c != 'Proactive')))
                               || (rtMap.get(c.RecordTypeId).getName() == subscriber.Case_Record_Type__c && subscriber.Case_Record_Type__c == 'Managed Security')){
                                   
                                   toAddrs.add(subscriber.EMail__c);
                                   
                               }
                        }
                        
                        //creating email notification
                        if(toAddrs.size()>0)
                        {
                            email = new Messaging.Singleemailmessage();
                            email.setHtmlBody(createEmailBody(c, actMap.get(c.AccountId), conMap.get(c.ContactId)));
                            email.setSaveAsActivity(false);
                            email.setToAddresses(toAddrs);
                            email.setOrgWideEmailAddressId(noReply);
                            email.setSubject('[AKAM-CASE #'+c.Akam_Case_Id__c+'] New '+rtMap.get(c.RecordTypeId).getName()+' Case Created for ' + actMap.get(c.AccountId).Name + (c.Subject != null ? (' - ' + c.Subject) : ''));
                            emailList.add(email);
                            
                        }
                    } 
                }
                
                //sending the list of email notifications
                if(emailList.size() > 0) {
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
                }
            }
        }
    }
    

    
    //Future method of sendEmailToCaseNotificationSubscription 
    @future
    public static void sendEmailToCaseNotificationSubscription_future(List<Id> newCaseIds)
    {
        List<Case> newCases = new List<Case>([Select Id,AccountId,ContactId,Do_not_show_in_portal__c,Sub_Type__c,
                                              RecordTypeId,Akam_Case_Id__c,Severity__c,Origin,AKAM_Created_Date__c,
                                              Subject,Description,CaseAutoId__C,Work_Type__c from Case where Id IN :newCaseIds]);
        sendEmailToCaseNotificationSubscription(newCases);
    }
    
    
    private static String createEmailBody(Case c, Account acct, Contact cont)
    {
        String emailBody = '';
        Map<Id, Schema.RecordTypeInfo> rTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();
        emailBody += 'A new '+rTypeMap.get(c.RecordTypeId).getName()+' case has been created for Account: ' + acct.Name + '. <br /><br />';
        emailBody += '<table width=80% border=1 cellpadding=5 style=border-collapse:collapse;>';
        emailBody += '<tr><td>Case #: </td><td>' + c.Akam_Case_Id__c + ' </td></tr>';
        emailBody += '<tr><td>Type: </td><td>' + rTypeMap.get(c.RecordTypeId).getName() + ' </td></tr>';
        emailBody += '<tr><td>Opened Date: </td><td>' + c.AKAM_Created_Date__c + '</td></tr>';
        emailBody += '<tr><td>Severity: </td><td>' + (c.Severity__c != null ? c.Severity__c : '') + '</td></tr>';
        emailBody += '<tr><td>Case Contact: </td><td>' + (cont != null ? cont.Name : '') + '</td></tr>';
        emailBody += '<tr><td>Subject: </td><td>' + (c.Subject != null ? c.Subject : '') + '</td></tr>';
        emailBody += '<tr><td>Description: </td><td>' + (c.Description != null ? c.Description : '') + '</td></tr></table><br /><br />';
        emailBody += 'For the latest status, go to: <a href=' + Environment_Setup__c.getOrgDefaults().CName_Url__c + c.Akam_Case_Id__c + '>Case</a>';
        return emailBody;
    }*/
    
    /** 
*   Funtion to add a update 'Next Case Update Due' when Case.Last_Case_Update is updated.
*   Related Task : T-166982
*   Added By : Satyanarayan
*/
    private static void updateNextCaseUpdateDue(List<Case> newCases, Map<Id, Case> oldMap) {
        List<Case> caseUpdateList = new List<Case>();
        
        Map<String,Map<String,Integer>> minutesMapForTech = new Map<String,Map<String,Integer>>{
            'Premium' => new Map<String, Integer>{'1'=>60, '2'=> 1440,'3'=> 1440}, 
                'Premium_EnhancedSLA' =>new Map<String, Integer> {'1'=>30, '2'=> 1440,'3'=> 1440}, 
                    'Priority' => new Map<String, Integer>{'1'=> 240, '2'=> 1440,'3'=> 1440}, 
                        'Priority_EnhancedSLA' =>new Map<String, Integer> {'1'=> 240, '2'=> 1440,'3'=> 1440}, 
                            'NetAlliance_Priority' =>new Map<String, Integer> {'1'=> 240, '2'=> 1440,'3'=> 1440} 
        };
            Map<String,Map<String,Integer>> minutesMapForAmg = new Map<String,Map<String,Integer>>{
                'Premium' => new Map<String, Integer>{'3'=> 1440}, 
                    'Premium_EnhancedSLA' =>new Map<String, Integer> {'3'=> 1440}, 
                        'Priority' => new Map<String, Integer>{'3'=> 1440}, 
                            'Priority_EnhancedSLA' =>new Map<String, Integer> {'3'=> 1440}, 
                                'NetAlliance_Priority' =>new Map<String, Integer> {'3'=> 1440} 
            };
                
                Map<String,Integer> minutesMapForStabilityEng = new Map<String,Integer>{ '1' => 60,'2' => 1440, '3' => 1440};
                    //Pass from trigger
                    //Map<Id,RecordType> recordTypeMap = new Map<Id,RecordType>([SELECT Id,Name FROM RecordType WHERE SObjectType = 'Case' and (Name = 'Stability Engineering' or Name = 'AMG' or Name = 'Technical')]);
                    
                    for(case cs : [SELECT Id,BusinessHoursId,Last_Case_Update__c,RecordType.Name,Entitlement.Name,Support_Level__c,Severity__c,Next_Case_Update_Due__c,Sub_Type__c FROM Case WHERE Id in :newCases]){
                        
                        if(cs.BusinessHoursId != null){
                            DateTime lastUpdate = cs.Last_Case_Update__c;
                            if(cs.RecordType.Name == 'Technical'){
                                if(minutesMapForTech.containsKey(cs.Entitlement.Name)){
                                    if(minutesMapForTech.get(cs.Entitlement.Name).containsKey(cs.Severity__c)){
                                        cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,minutesMapForTech.get(cs.Entitlement.Name).get(cs.Severity__c) * 60 * 1000L);
                                    }else{
                                        cs.Next_Case_Update_Due__c = null;    
                                    }
                                }else{
                                    cs.Next_Case_Update_Due__c = null;
                                }
                                if(cs.Sub_Type__c == 'CMP Alerts'){
                                    if(cs.Entitlement.Name == 'Premium' || cs.Entitlement.Name == 'Premium_EnhancedSLA'){
                                        if(cs.Severity__c == '1'){
                                            cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,15 * 60 * 1000L);
                                        }
                                        else if(cs.Severity__c == '2'){
                                            cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,30 * 60 * 1000L);
                                        }
                                        else if(cs.Severity__c == '3'){
                                            cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,240 * 60 * 1000L);
                                        }
                                    }
                                }
                            }else if(cs.RecordType.Name == 'AMG'){
                                if(minutesMapForAmg.containsKey(cs.Entitlement.Name)){
                                    if(minutesMapForAmg.get(cs.Entitlement.Name).containsKey(cs.Severity__c)){
                                        cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,minutesMapForAmg.get(cs.Entitlement.Name).get(cs.Severity__c) * 60 * 1000L);
                                    }else{
                                        cs.Next_Case_Update_Due__c = null;    
                                    }
                                }else{
                                    cs.Next_Case_Update_Due__c = null;
                                }
                            }
                            else if(cs.RecordType.Name == 'Stability Engineering'){
                                if(minutesMapForStabilityEng.containsKey(cs.Severity__c)){
                                    cs.Next_Case_Update_Due__c = BusinessHours.add(cs.BusinessHoursId,lastUpdate,minutesMapForStabilityEng.get(cs.Severity__c) * 60 * 1000L);
                                }else{
                                    cs.Next_Case_Update_Due__c = null;    
                                }   
                            }
                        }
                        
                        
                        if(cs.Next_Case_Update_Due__c != oldMap.get(cs.Id).Next_Case_Update_Due__c){
                            caseUpdateList.add(cs);
                        }                  
                    }
        
        if(caseUpdateList.size() > 0)
            Database.update(caseUpdateList,false);               
    }  
    
    // Changes by Sheena : This functionality is not needed as it is referencing BMC_objects.
/*
    public static Boolean Check = true;
    public static void UpdateAccountsProductsonSI(List<Case> lNewCases,Map<Id,Case> oldMap,Boolean isInsert)
    {
        if(Check)
        {
            Check=false;
            SI_ServiceIncidentImpactedCustomers__c SIAcc;
            List<SI_ServiceIncidentImpactedCustomers__c> lSIAccounts = new List<SI_ServiceIncidentImpactedCustomers__c>();
            
            //Id TechrecId = (Case.sObjectType.getDescribe().getRecordTypeInfosByName()).get('Technical').getRecordTypeId();
            //Pinkesh - ESESP-502
            String invalidRecordTypeNames = [SELECT Id, Active__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = True AND DeveloperName = 'SI_Case_RecordType_Names_For_Imp_Acc'].Value_Text__c;
            Id SIrecId = (BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName()).get('Service Incident').getRecordTypeId();
            List<Case> lNewTechSICases = new List<Case>();
            List<Case> lNewTechSICasestoAddAcc = new List<Case>();
            //List of SI Ids on updated Cases
            List<Id> lNewSIIds = new List<Id>();        
            //List of Old SI Ids on Updated Cases
            List<Id> lOldSIIds = new List<Id>();
            //List of Cases which should be processed to delete Acc on SI
            List<case> lDeleteCases = new List<case>();
            Map<String,SI_ServiceIncidentImpactedCustomers__c> mSI_ImpAcc = new Map<String,SI_ServiceIncidentImpactedCustomers__c>();
            Map<String,List<Case>> mSI_Cases = new Map<String,List<Case>>();
            List<SI_ServiceIncidentImpactedCustomers__c> lDeleteImpAccts;
            Set<SI_ServiceIncidentImpactedCustomers__c> setDeleteImpAccts = new Set<SI_ServiceIncidentImpactedCustomers__c>();      
            
            for(Case c: lNewCases)
            {
                String newCaseRecTypeName = (Case.sObjectType.getDescribe().getRecordTypeInfosById()).get(c.RecordTypeId).getName();
                String oldCaseRecTypeName;
                if(!isInsert)
                    oldCaseRecTypeName = (Case.sObjectType.getDescribe().getRecordTypeInfosById()).get(oldMap.get(c.Id).RecordTypeId).getName();
                if(!invalidRecordTypeNames.contains(newCaseRecTypeName) && c.Incident__c != null && c.AccountId != null && c.Work_Type__c != 'Proactive' &&
                   ((isInsert) || (!isInsert && (c.Incident__c != oldMap.get(c.Id).Incident__c|| c.AccountId != oldMap.get(c.Id).AccountId ||
                                                 (c.RecordTypeId != oldMap.get(c.Id).RecordTypeId && invalidRecordTypeNames.contains(oldCaseRecTypeName)) ||
                                                 c.Work_Type__c != oldMap.get(c.Id).Work_Type__c))))
                {
                    lNewSIIds.add(c.Incident__c);
                    lNewTechSICases.add(c);
                }
                 
                if(!isInsert && oldMap.get(c.Id).AccountId!=null && 
                   oldMap.get(c.Id).Incident__c !=null &&  !invalidRecordTypeNames.contains(oldCaseRecTypeName) &&
                   (c.AccountId!=oldMap.get(c.Id).AccountId || oldMap.get(c.Id).Incident__c != c.Incident__c ||
                    (oldMap.get(c.Id).RecordTypeId != c.RecordTypeId && invalidRecordTypeNames.contains(newCaseRecTypeName)) ||
                    (oldMap.get(c.Id).Work_Type__c != c.Work_Type__c && c.Work_Type__c == 'Proactive')))
                {
                    //To delete impacted accounts which is auto created and is not tied by any Case
                    //If Account is changed on Case, delete account on old SI
                    //If SI# no is changed on Case, delete account on old SI        
                    //If Record type on Case is changed from Technical to other, delete account on old SI        
                    lOldSIIds.add(oldMap.get(c.Id).Incident__c);
                    lDeleteCases.add(c); 
                }
            }
            Map<Id,BMCServiceDesk__Incident__c> CaseSIId_recMap =new Map<Id,BMCServiceDesk__Incident__c>();
            if(lNewSIIds.size()>0)
            {
                CaseSIId_recMap =new Map<Id,BMCServiceDesk__Incident__c>([Select Id,RecordTypeId from BMCServiceDesk__Incident__c where Id IN: lNewSIIds]);
            }
            
            if(!isInsert)
            { 
                if(lOldSIIds.size()>0)
                {
                    //Create Map of Old SI Ids and Impacted Accounts
                    for(SI_ServiceIncidentImpactedCustomers__c SI_acc : [Select Id,SI_Service_Incident__c,SI_AccountName__c from SI_ServiceIncidentImpactedCustomers__c where 
                                                                         SI_Service_Incident__c IN:lOldSIIds and AutoCreatedRecord__c=true])
                    {
                        mSI_ImpAcc.put(SI_acc.SI_Service_Incident__c+'##'+SI_acc.SI_AccountName__c ,SI_acc);
                    }
                    for(Case SI_c : [Select Id,Incident__c,RecordTypeId,RecordType.Name,AccountId,Work_Type__c from Case where Incident__c IN: lOldSIIds])
                    {
                        if(!invalidRecordTypeNames.contains(SI_c.RecordType.Name) && SI_c.Incident__c != null && SI_c.AccountId != null && SI_c.Work_Type__c != 'Proactive')
                        {               
                            if(!mSI_Cases.containsKey(SI_c.Incident__c+'##'+SI_c.AccountId))                
                                mSI_Cases.put(SI_c.Incident__c+'##'+SI_c.AccountId,new List<Case>());
                            (mSI_Cases.get(SI_c.Incident__c+'##'+SI_c.AccountId)).add(SI_c);
                        }
                    }
                }
                
                //Iterating through cases which should be considered for their account deletion
                for(Case c: lDeleteCases)
                {
                    if(mSI_ImpAcc.containsKey(oldMap.get(c.Id).Incident__c+'##'+oldMap.get(c.Id).AccountId)
                       && !mSI_Cases.containsKey(oldMap.get(c.Id).Incident__c+'##'+oldMap.get(c.Id).AccountId)
                      )
                    {
                        setDeleteImpAccts.add(mSI_ImpAcc.get(oldMap.get(c.Id).Incident__c+'##'+oldMap.get(c.Id).AccountId));             
                    }    
                }
                
                if(setDeleteImpAccts.size()>0)
                {
                    lDeleteImpAccts = new List<SI_ServiceIncidentImpactedCustomers__c>(setDeleteImpAccts);
                    delete lDeleteImpAccts;
                }
            }
            
            if(lNewTechSICases.size() > 0)
            {
                for(Case c: lNewTechSICases){
                    if(CaseSIId_recMap.get(c.Incident__c).RecordTypeId==SIrecId)
                    {
                        SIAcc = new SI_ServiceIncidentImpactedCustomers__c();
                        SIAcc.SI_AccountName__c = c.AccountId;
                        SIAcc.SI_Service_Incident__c = c.Incident__c;
                        SIAcc.AutoCreatedRecord__c = true;
                        lSIAccounts.add(SIAcc);
                    }
                }
                if(lSIAccounts.size() > 0)
                {
                    try{
                        insert lSIAccounts;
                    }
                    catch(DmlException ex)
                    {
                        if(ex.getDmlStatusCode(0)!='FIELD_CUSTOM_VALIDATION_EXCEPTION') 
                            lNewTechSICases[0].Incident__c.AddError(ex);
                    }
                }
            }
        }
    }
    
*/
    //CR:3290661 - CCare Technical Escalation Automation
    //Method to Update Technical_Esclation_Date__c to trigger technical Escalation on Aging Case
    //called from CaseTrigger_bi_bu
    // changes by Vandhana for ESESP-1027 (Exclude CCare Tech Esclation for ETP/EAA Case Products)
    public static void updateTechnicalEscalationDate(List<Case> newCaseList,Boolean isUpdate,Boolean isInsert)
    {
        Id setTechnicalRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId(); 
        Id setERTechnicalRecordTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId(); 
        String supportLevelAndSeverity = '';
        String caseSupportLevelAndSeverity = '';
        Map<String,Integer> mapEscalationAgingTime = new Map<String,Integer>();
        Map<String,Boolean> mapWeekendEscalation = new Map<String,Boolean>();
        
        Set<Id> setCaseER = new Set<Id>();
        List<Case> caseListforERCreation = new List<Case>();
        datetime tiggerDate;
        Boolean isNotNull = false;
        
        // flag to exclude cases with Enterprise Application Access OR Enterprise Threat Protector added as Case Product
        Boolean skipEAA_ETP = false;
        Set<Id> accountId = new Set<Id>();
        
        for(case caseItr :newCaseList)
        {
            if(caseItr.RecordTypeId == setTechnicalRecordTypeId && caseItr.Sub_Type__c == 'Product Support' && 
               caseItr.Work_Type__c != 'Proactive' && caseItr.Do_Not_Show_in_Portal__c == False && caseItr.Resolved_Date__c == Null
               && (caseItr.Status != 'Closed' || caseItr.Status != 'Resolved'
                   || caseItr.Status != 'Rejected' || caseItr.Status != 'Closed - Duplicate'))
            {  
                accountId.add(caseItr.AccountId);    
            }
        }
        
        if(!accountId.isEmpty())
        {
            Map<Id,Account> accountSupportMap = new Map<Id,Account>([Select Id,Support_Level__c from Account where Id IN:accountId]);       
            
            for(Technical_Escalation_Config_Interface__c eachTECI :[Select Support_Level__c,Severity__c,Time_Hours__c,Include_Weekend__c from Technical_Escalation_Config_Interface__c])
            {
                supportLevelAndSeverity = eachTECI.Support_Level__c + eachTECI.Severity__c;
                
                if(eachTECI.Time_Hours__c != Null)
                {
                    mapEscalationAgingTime.put(supportLevelAndSeverity,eachTECI.Time_Hours__c.intValue());
                }
                mapWeekendEscalation.put(supportLevelAndSeverity,eachTECI.Include_Weekend__c);
            }
            
            for(Engagement_Request__c forEachER : [Select id,Case__c from Engagement_Request__c where Case__c IN :newCaseList and recordtypeid = : setERTechnicalRecordTypeId])
            {
                setCaseER.add(forEachER.Case__c);    
            } 
            
            for(Case eachCase : newCaseList)
            {
                if(accountSupportMap.containskey(eachCase.AccountId))
                    caseSupportLevelAndSeverity = accountSupportMap.get(eachCase.AccountId).Support_Level__c + eachCase.Severity__c;
                
                if( (eachCase.Case_Prod_Name__c == 'Enterprise Application Access' || eachCase.Case_Prod_Name__c == 'Enterprise Threat Protector')
                   && (accountSupportMap.get(eachCase.AccountId).Support_Level__c.containsIgnoreCase('Premium')
                       || accountSupportMap.get(eachCase.AccountId).Support_Level__c.containsIgnoreCase('Named_Enhanced')
                       || accountSupportMap.get(eachCase.AccountId).Support_Level__c.containsIgnoreCase('Priority')
                      )
                  )
                {
                    skipEAA_ETP = true;
                }
                
                //checking if the map is null
                isNotNull = mapEscalationAgingTime.get(caseSupportLevelAndSeverity) == Null ? False : True;
                
                //Condition is true when case is created 
                if(isInsert && isNotNull && eachCase.RecordTypeId == setTechnicalRecordTypeId && eachCase.Sub_Type__c == 'Product Support' &&
                   eachCase.Work_Type__c != 'Proactive' && eachCase.Do_Not_Show_in_Portal__c == False && eachCase.Resolved_Date__c == Null &&
                   eachCase.Technical_Esclation_Date__c == Null && (eachCase.Status != 'Closed' || eachCase.Status != 'Resolved'
                                                                    || eachCase.Status != 'Rejected' || eachCase.Status != 'Closed - Duplicate') 
                   && !setCaseER.contains(eachCase.Id)
                   && eachCase.Escalate_Technical_Case__c == False
                   && !skipEAA_ETP
                  )
                {
                    if(mapEscalationAgingTime.get(caseSupportLevelAndSeverity) != 0){
                        //adding hours fetched from map to current time 
                        tiggerDate = (system.now() + (mapEscalationAgingTime.get(caseSupportLevelAndSeverity)/24.0)) - (5/(24.0*60));
                    }
                    else
                    {
                        tiggerDate = system.now();
                    }
                    
                    //Calling method dayOfWeek for actual triggertime
                    if(mapWeekendEscalation.get(caseSupportLevelAndSeverity))
                    {    
                        eachCase.Technical_Esclation_Date__c = tiggerDate;
                    }
                    else
                    {
                        eachCase.Technical_Esclation_Date__c = dayOfWeek(tiggerDate); 
                    }
                    System.debug('£££££££££££££££££ updateTechnicalEscalationDate');
                }
                
                //Condition is true when case is updated with Technical_Esclation_Date__c and Time Trigger Workflow Rule sets Escalate_Technical_Case__c == True
                else if(isUpdate && isNotNull && eachCase.RecordTypeId == setTechnicalRecordTypeId && eachCase.Sub_Type__c == 'Product Support' &&
                        eachCase.Work_Type__c != 'Proactive' && eachCase.Do_Not_Show_in_Portal__c == False && eachCase.Resolved_Date__c == Null &&
                        eachCase.Technical_Esclation_Date__c != Null && (eachCase.Status != 'Closed' || eachCase.Status != 'Resolved'
                                                                         || eachCase.Status != 'Rejected' || eachCase.Status != 'Closed - Duplicate') && !setCaseER.contains(eachCase.Id)
                        && eachCase.Escalate_Technical_Case__c == True
                        && !skipEAA_ETP
                       )
                {
                    caseListforERCreation.add(eachCase);
                }
            } 
        }   
        //Calling createERForTechnicalEscalation Method
        if(caseListforERCreation.size() > 0)
        {
            createERForTechnicalEscalation(caseListforERCreation);
        }
        caseListforERCreation.clear();    
    }
    
    //Method to identify day of week, called from updateTechnicalEscalationDate
    public static datetime dayOfWeek(datetime triggerDate)
    {
        Datetime triggerDateForWeekend;
        Datetime todaydate = triggerDate;
        Datetime dt = (DateTime)todaydate;
        String dayOfWeek = dt.format('EEEE');
        
        //Incrementing TriggerDate by 2 days if Saturday
        
        if(dayOfWeek == 'Saturday')
        {
            triggerDateForWeekend = triggerDate + 2;
        }
        //Incrementing TriggerDate by 1 days if Saturday
        else if(dayOfWeek == 'Sunday')
        {
            triggerDateForWeekend = triggerDate + 1;
        }   
        else 
        {
            triggerDateForWeekend = triggerDate;
        }  
        return  triggerDateForWeekend;  
        
    }   
    
    //Method to create ER for Technical Case Escalation
    //called from updateTechnicalEscalationDate method
    public static void createERForTechnicalEscalation(List<Case> newCaseList)
    {
        System.debug('£££££££££££££££££ createERForTechnicalEscalation');
        Id setERTechnicalRecordTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId(); 
        List<Engagement_Request__c> listERForUpdate = new List<Engagement_Request__c>();
        Engagement_Request__c newEngagamentRequest;
        Map<Id,String> caseProdMap = new Map<Id,String>();
        
        for(case forRelatedProd : [Select id,case_product__r.name,owner.name from case where id IN : newCaseList])
        {
            caseProdMap.put(forRelatedProd.Id,forRelatedProd.Case_Product__r.name);
        }
        
        //Creating ER Record for the Techincal Escalation Case
        for(case forEachCase :newCaseList)
        {
            if(forEachCase.Escalate_Technical_Case__c == True)
            {
                newEngagamentRequest = new Engagement_Request__c();
                newEngagamentRequest.case__c = forEachCase.id;
                newEngagamentRequest.RecordTypeId = setERTechnicalRecordTypeId;
                newEngagamentRequest.ER_Severity__c = forEachCase.Severity__c;
                newEngagamentRequest.Auto_Escalation__c  = True;
                newEngagamentRequest.Description__c  = forEachCase.Subject + ' (AUTO-ESCALATION: Contact case owner and assist with diagnosis and mitigation. For more information:'+'\n'+'https://ac.akamai.com/docs/DOC-7088)'+'\n'+
                    'Case Description : '+'\n'+forEachCase.Description;
                
                //Case with Product 
                if(forEachCase.Case_Product__c != Null)
                {
                    //Fetching values from CS SC_Case_Product_ER_Mapping__c
                    SC_Case_Product_ER_Mapping__c productMappingCS = SC_Case_Product_ER_Mapping__c.getInstance(caseProdMap.get(forEachCase.id));
                    
                    //Condition to check if CS has the product and Routing Rule is same as case owner name                    
                    newEngagamentRequest.Area__c = productMappingCS != Null ? productMappingCS.Business_Unit__c : 'Web Experience';
                }
                else
                {
                    newEngagamentRequest.Area__c = 'Web Experience';      
                }                
                listERForUpdate.add(newEngagamentRequest);                         
            }
        }
        
        insert  listERForUpdate;
    }
    
    //ESESP - 603 create CCare Tech Mgmt Escalation ER for Cases with Support Advocacy Accounts
    //Method to Update Technical_Mgmt_Escalation_Date__c to trigger Technical Mgmt Escalation ER creation on Aging Case
    //called from CaseTrigger_bi_bu
    //changes by Vandhana for ESESP-2597 : added Support_Advocacy_Special_Escalation__c to take precedence over Support Advocacy
    public static void updateTechnicalMgmtEscalationDate(List<Case> newCaseList,Boolean isInsert)
    {    
        Id setTechnicalRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId(); 
        
        Id mgmtERRecordTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CCare Mgmt Escalation').getRecordTypeId(); 
        
        Map<String,Integer> mapEscalationAgingTime = new Map<String,Integer>();
        Map<String,Boolean> mapWeekendEscalation = new Map<String,Boolean>();
        
        Set<Id> setCaseER = new Set<Id>();
        
        List<Case> caseListforERCreation = new List<Case>();
        
        datetime triggerERDate;
        Boolean isNotNull = false;
        Map<Id,Account> mapIdAccount = new Map<Id,Account>();
        
        //Loop to iterate through all Technical_Escalation_Config_Interface__c and populate Maps
        for(Technical_Escalation_Config_Interface__c eachTECI :[SELECT Support_Level__c,Severity__c,Time_Hours__c,Include_Weekend__c 
                                                                FROM Technical_Escalation_Config_Interface__c
                                                                WHERE Support_Advocacy__c = true AND Severity__c != null AND Time_Hours__c != null
                                                               ])
        {
            //if(String.isNotBlank(String.valueOf(eachTECI.Time_Hours__c)) && String.isNotBlank(String.valueOf(eachTECI.Severity__c)) )
            //{    
            mapEscalationAgingTime.put(eachTECI.Severity__c.toPlainString(),eachTECI.Time_Hours__c.intValue());
            //}
            mapWeekendEscalation.put(eachTECI.Severity__c.toPlainString(),eachTECI.Include_Weekend__c);
        }
        
        //Loop to iterate through ER realted to case to populate setCaseER   
        for(Engagement_Request__c forEachER : [Select Id,Case__c 
                                               from Engagement_Request__c 
                                               where Case__c IN :newCaseList 
                                               and recordtypeid = : mgmtERRecordTypeId])
        {
            setCaseER.add(forEachER.Case__c);
        } 
        
        
        Set<Id> setAccId = new Set<Id>();
        for(Case c : newCaseList)
        {
            setAccId.add(c.AccountId);
        }
        mapIdAccount = new Map<Id,Account>([SELECT Id,Support_Advocacy_Special_Escalation__c FROM Account WHERE Id IN :setAccId]);
        
        //Loop to iterate through trigger.new
        for(Case eachCase : newCaseList)
        {
            //checking if the map is null
            isNotNull = mapEscalationAgingTime.get(eachCase.Severity__c) == Null ? False : True;
            
            //Condition is true when case is created 
            if(isInsert && isNotNull && eachCase.RecordTypeId == setTechnicalRecordTypeId 
               && eachCase.Sub_Type__c == 'Product Support' 
               && eachCase.Work_Type__c != 'Proactive' 
               && eachCase.Do_Not_Show_in_Portal__c == False 
               && eachCase.Resolved_Date__c == Null &&
               eachCase.Technical_Mgmt_Escalation_Date__c == Null 
               && (eachCase.Status != 'Closed' || eachCase.Status != 'Resolved'
                   || eachCase.Status != 'Rejected' || eachCase.Status != 'Closed - Duplicate') 
               && !setCaseER.contains(eachCase.Id)
               && eachCase.Escalate_Technical_Mgmt_Case__c == False
               && (eachCase.Account_Support_Advocate__c && mapIdAccount.containsKey(eachCase.AccountId) && !mapIdAccount.get(eachCase.AccountId).Support_Advocacy_Special_Escalation__c)
              )
            {
                if(mapEscalationAgingTime.get(eachCase.Severity__c) != 0)
                {
                    triggerERDate = (System.now() + (mapEscalationAgingTime.get(eachCase.Severity__c)/24.0)) - (5/(24.0*60));
                }
                else
                {
                    triggerERDate = System.now();
                }
                
                //Calling method dayOfWeek for actual triggertime
                if(mapWeekendEscalation.get(eachCase.Severity__c))
                {    
                    eachCase.Technical_Mgmt_Escalation_Date__c = triggerERDate;
                }
                else
                {
                    eachCase.Technical_Mgmt_Escalation_Date__c = dayOfWeek(triggerERDate); 
                }
            }
            
            //Condition is true when case is updated with Technical_Esclation_Date__c and Time Trigger Workflow Rule sets Escalate_Technical_Case__c == True
            else if(!isInsert && isNotNull && eachCase.RecordTypeId == setTechnicalRecordTypeId 
                    && eachCase.Sub_Type__c == 'Product Support' 
                    && eachCase.Work_Type__c != 'Proactive' 
                    && eachCase.Do_Not_Show_in_Portal__c == False 
                    && eachCase.Resolved_Date__c == Null 
                    && eachCase.Technical_Mgmt_Escalation_Date__c != Null 
                    && (eachCase.Status != 'Closed' 
                        || eachCase.Status != 'Resolved'
                        || eachCase.Status != 'Rejected' 
                        || eachCase.Status != 'Closed - Duplicate') 
                    && !setCaseER.contains(eachCase.Id)
                    && eachCase.Escalate_Technical_Mgmt_Case__c
                    && (eachCase.Account_Support_Advocate__c && mapIdAccount.containsKey(eachCase.AccountId) && !mapIdAccount.get(eachCase.AccountId).Support_Advocacy_Special_Escalation__c)
                   )
            {            
                caseListforERCreation.add(eachCase);        
            }
        } 
        
        //Calling createERForTechnicalEscalation Method
        if(caseListforERCreation.size() > 0)
        {
            System.debug('£££££££££££££££££ updateTechnicalMgmtEscalationDate ' + caseListforERCreation.size());
            createERForSupportAdvocacyEscalation(caseListforERCreation, new Map<Id,Account>());
        }
        caseListforERCreation.clear();    
    }
    
    // Create CCare Tech Mgmt ER for Support Advocacy Cases
    // called from updateTechnicalMgmtEscalationDate method
    public static void createERForSupportAdvocacyEscalation(List<Case> newCaseList, Map<Id,Account> mapAcc)
    {
        Id erMgmtEscTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CCare Mgmt Escalation').getRecordTypeId(); 
        
        List<Engagement_Request__c> listERForUpdate = new List<Engagement_Request__c>();
        
        Map<Id,String> caseProdMap = new Map<Id,String>();
        
        for(case forEachCase : newCaseList)
        {
            if(forEachCase.Escalate_Technical_Mgmt_Case__c 
               && (forEachCase.Account_Support_Advocate__c || (!mapAcc.isEmpty() && mapAcc.get(forEachCase.AccountId).Support_Advocacy_Special_Escalation__c)))
            {
                Engagement_Request__c newEngagamentRequest = new Engagement_Request__c();
                newEngagamentRequest.case__c = forEachCase.id;
                newEngagamentRequest.RecordTypeId = erMgmtEscTypeId;
                newEngagamentRequest.ER_Severity__c = forEachCase.Severity__c;
                newEngagamentRequest.Auto_Escalation__c  = true;
                newEngagamentRequest.Validation_Override__c  = true;
                
                newEngagamentRequest.Description__c  = forEachCase.Subject + '\nAUTO-ESCALATION:\nContact case owner and assist with diagnosis and mitigation. For more information:'+
                    '\n'+'(https://ac.akamai.com/docs/DOC-7088)'+'\n\n'+
                    'Case Description:'+'\n'+forEachCase.Description;
                
                //Inserting records to ER List
                listERForUpdate.add(newEngagamentRequest);                         
            }
        }
        //Inserting ER
        //System.assertEquals(99, listERForUpdate.size());
        insert listERForUpdate;
    }
    
    // changes by Vandhana for ESESP-834
    // Below Code commented for JIRA:ESESP-3430, By Bhavesh
    /*@future
    public static void createERForOctoshape_future(Set<Id> octoCaseListFuture)
    {
        List<Case> caseList = [SELECT Subject,Description,Severity__c,AKAM_Case_Id__c
                               FROM Case
                               WHERE Id in :octoCaseListFuture
                              ];
        createERForOctoshape(caseList);
    }
    
    //Create ER for Octoshape Escalation
    public static void createERForOctoshape(List<Case> octoCaseList)
    {
        Id octoERRecTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Octoshape Engineering').getRecordTypeId(); 
        Set<Id> casesWithAutoER = new Set<Id>();
        
        for(Engagement_Request__c autogenOctoER : [SELECT Id,Case__c,Case__r.Subject 
                                                   FROM Engagement_Request__c 
                                                   WHERE Case__c IN :octoCaseList 
                                                   AND RecordType.Name = 'Octoshape Engineering'
                                                   AND Octoshape_auto_escalation__c = TRUE
                                                  ])
        {
            casesWithAutoER.add(autogenOctoER.Case__c);
        }
        
        Engagement_Request__c newEngagamentRequest;
        List<Engagement_Request__c> listER = new List<Engagement_Request__c>();
        
        //Map to store Case Id and Case Product Name
        Map<Id,String> caseProdMap = new Map<Id,String>();
        
        //Creating ER Record for the Techincal Esclation Case
        for(Case eachCase : octoCaseList)
        {
            if(!casesWithAutoER.contains(eachCase.Id))
            {
                newEngagamentRequest = new Engagement_Request__c();
                newEngagamentRequest.Case__c = eachCase.Id;
                newEngagamentRequest.Octoshape_auto_escalation__c = true;
                newEngagamentRequest.PSG_Action__c = true;
                newEngagamentRequest.RecordTypeId = octoERRecTypeId;
                newEngagamentRequest.ER_Severity__c = '1';
                newEngagamentRequest.Description__c  = 'Sev 1 Octoshape Auto-Escalation : ' + eachCase.Subject + ' - ' + eachCase.Description;                
                //Inserting records to ER List
                listER.add(newEngagamentRequest);
            }
        }
        
        //Inserting ER
        insert listER;
    }*/
    
    
    /*  Changes done by Vamsee Surya for CR 3564721
Method to Automate Billing case assignment to team members
Called from CaseTrigger_ai Trigger
*/
    public Static void UpdateOwnerForBilling(List<Case> BillingCaseList){
        //List to store the Available Resource info
        List<Billing_Case_Resource_Configuration__c>  rcList = new List<Billing_Case_Resource_Configuration__c>();
        
        //To Store the current date and time in the IST time zone.
        DateTime currentDateTime = System.now().addHours(5).addMinutes(30);
        String dayOfWeek=currentDateTime.format('EEEE');
        
        //Checking for weekend scenario i.e.. Saturday 7AM to Monday 6AM
        if(!((dayofWeek == 'Saturday' && currentDateTime.hour() > 7) ||
             (dayofWeek == 'Sunday') ||
             (dayofWeek == 'Monday' && currentDateTime.hour() < 6)))
        {    
            //Loop through the Resource configuration and get all available Resource
            for(Billing_Case_Resource_Configuration__c rc: [SELECT Assignment_Order__c,User__c, Shift_Start_IST__c, Shift_End_IST__c  FROM Billing_Case_Resource_Configuration__c WHERE Is_Out_of_Office__c = FALSE ORDER BY Assignment_Order__c]){
                
                //Shift start date in IST
                DateTime shiftStart = system.now();
                shiftStart = shiftStart.dateGmt();
                shiftStart = shiftStart.addHours(Integer.valueOf(rc.Shift_Start_IST__c.split(':')[0]));
                if(rc.Shift_Start_IST__c.contains('PM') && !rc.Shift_Start_IST__c.contains('12'))
                    shiftStart = shiftStart.addHours(12);
                
                //Shift end date in IST
                DateTime shiftEnd = system.now();
                shiftEnd = ShiftEnd.dateGmt();
                shiftEnd = shiftEnd.addHours(Integer.valueOf(rc.Shift_End_IST__c.split(':')[0]));
                if(rc.Shift_End_IST__c.contains('PM') && !rc.Shift_End_IST__c.contains('12'))
                    shiftEnd = shiftEnd.addHours(12);
                else if(rc.Shift_End_IST__c.contains('AM') && rc.Shift_Start_IST__c.contains('PM'))
                    shiftEnd = shiftEnd.addHours(24);
                
                //Adding all the available resources to the List
                if(shiftStart < currentDateTime && shiftEnd > currentDateTime )
                    rcList.add(rc);
                
            }
        }
        
        try
        {
            //Get the Last case assigned details from custom setting
            SC_Resource_Configuration__c RCcustomsetting = [SELECT Assignment_Order__c from SC_Resource_Configuration__c for UPDATE];
            integer lastAssignment = (integer)RCcustomsetting.Assignment_Order__c;
            integer nextIndex = 0;
            
            //To get the index of the resource to which last case is assigned 
            for(integer i =0; i<rcList.size();i++){
                if(rcList[i].Assignment_Order__c > lastAssignment){
                    nextIndex = i;
                    break;
                }
            }
            
            List<Id> idList = new List<Id>();
            for(Case c: BillingCaseList)
                idList.add(c.Id);
            
            //List of cases where owner need to be updated
            List<Case> caseListToUpdate;
            if(idList.size() > 0)
                caseListToUpdate = new List<Case>([SELECT Id,OwnerId,Status from CASE where Id in :idList]);
            
            //If there are no resource available do not change the owner
            if(rcList.size() > 0){
                for(Case c: caseListToUpdate){
                    c.OwnerId = rcList[nextIndex].User__c;
                    c.Status = 'Assigned';
                    lastAssignment = (integer)rcList[nextIndex].Assignment_Order__c;
                    nextIndex++;
                    
                    //If it is last resource then index need to be changed to first resource
                    if(nextIndex > rcList.size() - 1)
                        nextIndex = 0;
                    
                } 
                //Update the custom setting to the resource to which last case is assigned 
                RCcustomsetting.Assignment_Order__c = lastAssignment;
                UPDATE RCcustomsetting;
                
                //Changing the owner of the Case and setting dmo to fire case assignment email
                Database.DMLOptions dmlo = new Database.DMLOptions();
                dmlo.EmailHeader.triggerUserEmail = true;
                Database.update(caseListToUpdate, dmlo);
                
            }
        }
        catch(QueryException qe)
        {
            //No assignments should fire
            //This is to handle Concurrent case creation scenario
        }
        catch(DmlException ex)
        {
            //No assignments should fire
            //This is to handle Concurrent update of Custom setting from other client        
        }
    }
    
    // changes by Vandhana for JIRA ESESP-551 : Cases for Specialist Pre-Sales - Part 2
    // for all Pre-Sales cases, add Case Owner (if User) to corresponding Opportunity Team with role based on case request type
    public static void preSalesCaseOwnerOppTeam(List<Case> lstCases)
    {
        List<Id> oppIDs = new List<Id>();
        List<Opportunity> lstOpp = new List<Opportunity>();
        List<Id> caseOwnerIds = new List<Id>();
        
        Map<Case,Id> mapCaseOpp = new Map<Case,Id>();
        
        for(Case eachCase : lstCases)
        {
            oppIDs.add(eachCase.Opportunity__c);
            mapCaseOpp.put(eachCase,eachCase.Opportunity__c);
            caseOwnerIds.add(eachCase.OwnerId);
        }
        
        // get list of Opportunity Teams for each Opportunity of incoming pre-sales case
        List<OpportunityTeamMember> lstOTM = [Select Id,OpportunityId,UserId,TeamMemberRole,OpportunityAccessLevel from OpportunityTeamMember where OpportunityId in :oppIDs];
        
        // Map that stores Opportunity :: Set of Team Members mapping
        Map<Id,Set<Id>> oppOtmMap = new Map<Id,Set<Id>>();
        
        for(OpportunityTeamMember otm : lstOTM)
        {
            if(oppOtmMap.containsKey(otm.OpportunityId))
            {
                oppOtmMap.get(otm.OpportunityId).add(otm.UserId);
            }
            else
            {
                oppOtmMap.put(otm.OpportunityId, new Set<Id>{otm.UserId});
            }
        }
        
        lstOTM.clear();
        
        // iterate over each case and if corresponding opportunity does NOT have the case owner added as Opportunity Team Member, then add.
        
        for(Case theCase : mapCaseOpp.keySet())
        {
            // Case's Opportunity has an Opportunity Team with member(s)
            if(oppOtmMap.containsKey(theCase.Opportunity__c))
            {
                // add Case Owner to Opportunity Team only if not present already
                if(!oppOtmMap.get(theCase.Opportunity__c).contains(theCase.OwnerId))
                {
                    OpportunityTeamMember newOTM = new OpportunityTeamMember(OpportunityId = theCase.Opportunity__c,UserId = theCase.OwnerId,TeamMemberRole = theCase.Request_Type__c);
                    lstOTM.add(newOTM);
                }
            }
            
            // Case's Opportunity does not have an Opportunity Team, so add new Opportunity Team Member
            else
            {
                OpportunityTeamMember newOTM = new OpportunityTeamMember(OpportunityId = theCase.Opportunity__c,UserId = theCase.OwnerId,TeamMemberRole = theCase.Request_Type__c);
                lstOTM.add(newOTM);
            }
        }    
        
        
        // insert new Opportunity Team Members
        if(lstOTM != NULL && lstOTM.size() > 0)
            insert lstOTM;
        
        // As sharing settings for Opportunity is private, query sharing records of user and opportunity and update their access level to Read/Write
        
        List<OpportunityShare> oppShareRecords = [SELECT Id, OpportunityAccessLevel, RowCause FROM OpportunityShare WHERE OpportunityId IN :mapCaseOpp.values() AND RowCause = 'Team' AND UserOrGroupId IN :caseOwnerIds];
        List<OpportunityShare> oppshareRecId = new List<OpportunityShare>();
        for(OpportunityShare eachRec : oppShareRecords)
        {
            eachRec.OpportunityAccessLevel = 'Edit';
            oppshareRecId.add(eachRec);
        }
        
        // update Opportunity Team Members' (Case Owners') sharing records
        if(oppshareRecId != NULL && oppshareRecId.size() > 0)
            update oppshareRecId;
    }
    
    // Update Legay Type on Case based on the Product in Custom Metadata Type 'SC Legacy Type Corresponding Product Detail'
    // Called From CaseTrigger_bi_bu
    // JIRA : ESESP-574
    // Added By : Aditya- 19th June,2017
    
    public static void updateLegacyType(List<case> caseListLT, Boolean isProductPopulated){
        
        //Map to store Legacy Type and Its Product,coming from Custom Metadata Type
        Map<String,String> legacyTypeAndProductMap = new Map<String,String>();
        
        //Query to get data from SC_Legacy_Type_Corresponding_Product__mdt
        List<SC_Legacy_Type_Corresponding_Product__mdt> legacyProductsList = new List<SC_Legacy_Type_Corresponding_Product__mdt>([SELECT Legacy_Type__c,Legacy_Products__c FROM SC_Legacy_Type_Corresponding_Product__mdt]);
        
        //Adding values to the Map
        for(integer i=0;i<legacyProductsList.size();i++){
            legacyTypeAndProductMap.put(legacyProductsList[i].Legacy_Type__c,legacyProductsList[i].Legacy_Products__c);
        }
        
        //Updating Case Legacy_Type__c based on case product
        if(isProductPopulated){
            for(case eachCase :caseListLT){
                for(string eachLegacyType : legacyTypeAndProductMap.keySet()){
                    boolean isMatch = false;
                    for(string eachProduct : legacyTypeAndProductMap.get(eachLegacyType).split(',')){
                        if(eachCase.Case_Prod_Name__c.trim() == eachProduct.trim()){
                            eachCase.Legacy_Type__c = eachLegacyType;
                            isMatch = true;
                            break;
                        }
                        else{
                            eachCase.Legacy_Type__c = ''; 
                        }
                    }
                    if(isMatch){
                        break;
                    }
                }
            }
        }
        //Removing legacy type if product is Null
        else{
            for(case eachCase :caseListLT){
                eachCase.Legacy_Type__c = '';
            }
        }
    }
    
    
    // changes by Vandhana
    //ESESP-389 - Better logging for field "Living Summary/Next Steps"
    public static void livingSummaryCaseFeed(List<Case> newMSCase)
    {
        List<FeedItem> lPost = new List<FeedItem>();
        Database.SaveResult[] dbSRList;
        //FeedItem fItem;
        //List<FeedItem> fiList = new List<FeedItem>();
        try
        {  
            for(Case eachCase : newMSCase)
            {
                FeedItem post = new FeedItem();
                String removeBreaks = eachCase.Living_Summary_Next_Steps__c.replaceAll('<br>','<p>&nbsp;</p>');
                
                Pattern patternString = Pattern.compile('<a[^>]+>|</a>|<strike>|</strike>|<div[^>]+>|</div>');
                Matcher pm = patternString.matcher(removeBreaks);
                String feedBody = pm.replaceAll('');
                
                patternString = Pattern.compile('style="[^"]+"|alt="[^"]+"');
                pm = patternString.matcher(feedBody);
                feedBody = pm.replaceAll('');
                
                ContentVersion cVersion;
                List<ContentVersion> cvList = new List<ContentVersion>();
                
                if(feedBody.contains('&amp;'))
                    feedBody = feedBody.replace('&amp;','&');
                
                patternString = Pattern.compile('<img[^>]+></img>');
                pm = patternString.matcher(feedBody);
                while(pm.find())
                {
                    String imgRef = pm.group().substringBetween('src="', '"');
                    feedBody = feedBody.replaceAll('<img[^>]+></img>','');
                    feedBody = feedBody + '<p>&nbsp;</p> Click here to view image : ' + imgRef;
                    //PageReference pageRef = new PageReference(imgRef);
                    //ContentVersion cVersion = new ContentVersion (title = 'title', VersionData = pageRef.getContent(), PathOnClient = 'my.png');
                    //cVersion = new ContentVersion (title = 'Image', VersionData = new PageReference(imgRef).getContent());
                    //cvList.add(cVersion);
                    //fItem = new FeedItem(RelatedRecordId = cVersion.id, type = 'ContentPost', parentId = eachCase.Id);
                    //fiList.add(fItem);
                }
                
                post.Body = UserInfo.getName() + ' changed Living Summary to ' + feedBody;
                if(post.Body.length() > 10000)
                    post.Body = post.Body.left(10000);
                post.IsRichText = true; 
                post.Type = 'ContentPost';
                post.ParentId = eachCase.Id;
                lPost.add(post);
                
                //PageReference pageRef = new PageReference('https://akamai--gssmaint--c.cs64.content.force.com/servlet/rtaImage?eid=5000q000000dzOj&feoid=00NG000000A1cQt&refid=0EM0q0000004DMv');
                //insert cVersion;
                //FeedItem fItem = new FeedItem(RelatedRecordId = cVersion.id, type = 'ContentPost', parentId = '5000q000000dzOj');
                //insert fItem;
                
                //<img alt="User-added image" src="https://akamai--GSSMaint--c.cs64.content.force.com/servlet/rtaImage?eid=5000q000000dzOj&amp;feoid=00NG000000A1cQt&amp;refid=0EM0q0000004DMv" style="height: 254px; width: 500px;"></img>
            }
            
            //insert lPost;
            dbSRList = Database.insert(lPost, false);
            
            List<Id> caseIDs = new List<Id>();
            for(Integer i=0;i<lPost.size();i++)
            {
                if(!dbSRList[i].isSuccess())
                {
                    caseIDs.add(lPost[i].ParentId);
                }
            }
            
            lPost.clear();
            dbSRList.clear();
            //List<FeedItem> genericFeed = new List<FeedItem>();
            for(Id caseID : caseIDs)
            {
                FeedItem fi = new FeedItem();
                fi.ParentId = caseId;
                fi.Body = UserInfo.getName() + ' changed the Living Summary.';
                fi.Type = 'ContentPost';
                lPost.add(fi);
            }
            
            dbSRList = Database.insert(lPost, false);
            
            for(Database.SaveResult eachDBSR : dbSRList)
            {
                if(!eachDBSR.isSuccess())
                {
                    for(Database.Error err : eachDBSR.getErrors()) 
                    {
                        System.debug('Feed Item error : ' + err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Feed Item fields : ' + err.getFields());
                    }
                }
            }
        }
        
        catch(Exception e)
        {
            System.debug('Exception in CaseTriggerClass::livingSummaryCaseFeed ' + e);
        }
    }
    
    // changes by Vandhana for ESESP-354 
    // changes by Vandhana for ESESP-354 
    // changes by Sujay on : ESESP-5891 - converting the product name check to case insensitive.
    public static void validateServiceEntitlement(List<Case> lstCases, Set<Id> accIds)
    {
        List<Account> accList = [Select Id,
                                 (Select Marketing_Product_Name__c 
                                  from SC_BOCC_CONTRACT_ENG_MRKTG_PRODUCT_DETLS__r 
                                  where Area__c like '%Professional_Services%') 
                                 from Account 
                                 where Id IN :accIds];
        
        Map<Id,Set<String>> accProdMap = new Map<Id,Set<String>>();
        Map<Id,String> accProdValueMap = new Map<Id,String>();
        
        for(Account acc : accList)
        {
            if(acc.SC_BOCC_CONTRACT_ENG_MRKTG_PRODUCT_DETLS__r.size() > 0)
            {
                Set<String> prodSet = new Set<String>();
                String prodValue = '';
                for(SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c prod : acc.SC_BOCC_CONTRACT_ENG_MRKTG_PRODUCT_DETLS__r) 
                {
                    if(!prodSet.contains(prod.Marketing_Product_Name__c))
                    {
                        //ESESP-5891 : converting the incoming data to lower case and store in map
                        prodSet.add((prod.Marketing_Product_Name__c).toLowerCase());   
                        prodValue += ', ' + prod.Marketing_Product_Name__c;
                    }
                }
                accProdMap.put(acc.Id,prodSet);
                accProdValueMap.put(acc.Id, prodValue);
            }
        }
        
        
        String errorMessageServ = 'The selected Service does not exist for this Account. Please select one of the valid values: ';
        Case_Service_Value__mdt serviceValues = [Select Service__c from Case_Service_Value__mdt where DeveloperName = 'Professional_Services'];        
        List<String> defaultServices = serviceValues.Service__c.split('\n');
        String defServString = '';        
        for(String s : defaultServices)
            defServString = defServString + s.trim() + ', ';
        
        defServString = defServString.substring(0,defServString.length() - 2);
        errorMessageServ = errorMessageServ + defServString;
        
        // changes by Vandhana for ESESP-1230 : display error message with set of Product values
        for(Case eachCase : lstCases)
        {
            //ESESP-5891 : converting to lower case just before the check thats happening
            String service = (eachCase.Service__c).toLowerCase();
            
            if(!defServString.containsIgnoreCase(eachCase.Service__c) && 
               !(accProdMap.containsKey(eachCase.AccountId) && (accProdMap.get(eachCase.AccountId).contains(service))) )
            {
                if(accProdValueMap.get(eachCase.AccountId) != NULL){
                    eachCase.addError(errorMessageServ + accProdValueMap.get(eachCase.AccountId));
                }
                    
                else{
                    eachCase.addError(errorMessageServ);
                }
                    
            }
        }
    }
    
    
    // changes by Vandhana for Managed Security Cases PD - ESESP 820
    public static void managedSecPolDomCheck(List<Case> lstCases, List<Id> polDomId)
    {
        Map<Id,Policy_Domain__c> polDomMap = new Map<Id,Policy_Domain__c>([Select Account_Name__c,Product__c,Additional_Product__c from Policy_Domain__c where Id in :polDomId ]);
        
        for(Case c : lstCases)
        {
            //ESESP-5571
            String prod = '';
            if(polDomMap != null && polDomMap.get(c.Policy_Domain__c) != null && String.isNotBlank(polDomMap.get(c.Policy_Domain__c).Product__c))
            	prod = polDomMap.get(c.Policy_Domain__c).Product__c;
            Set<String> addProd = new Set<String>();
            if(polDomMap != null && polDomMap.get(c.Policy_Domain__c) != null && String.isNotBlank(polDomMap.get(c.Policy_Domain__c).Additional_Product__c))
                addProd = new Set<String>((polDomMap.get(c.Policy_Domain__c).Additional_Product__c).toLowerCase().split(';'));//ESESP-958
            if(String.isNotBlank(prod) && c.Case_Prod_Name__c !=null && !prod.equalsIgnoreCase(c.Case_Prod_Name__c) && (addProd.isEmpty() || (!addProd.isEmpty() && !addProd.contains(c.Case_Prod_Name__c.toLowerCase()))))//ESESP-958
            { 
                c.addError('Invalid Account, Case Product and Policy Domain association');
            }
        }
    }
    
    // changes by Vandhana for Xiphos Email Notifications to Customers ESESP-1891
    @future
    public static void msAttackReportCaseEmailNotif(Set<Id> setCase)
    {
        list<Messaging.SingleEmailMessage> lEmails = new list<Messaging.SingleEmailMessage>();
        List<Case> caseList = [SELECT Contact.Email,Alternate_Contact_Email__c,AuthorizedContacts__c,ContactId,Owner.Name,Owner.Title,
                               Attack_Report_Link__c,OwnerId,Contact.Name,
                               AKAM_Case_ID__c,AccountId,Account.Name,CreatedDate,Subject,Case_Situation_Handler__r.Handler__r.Escalation_List__c
                               FROM Case
                               WHERE ID in :setCase
                              ];
        Set<String> emailIdSet = new Set<String>();
        Set<String> additionalEmailIdSet = new Set<String>();
        
        //ESESP-5442
        Map<Id,Id> caseEscListMap = new Map<Id,Id>();
		Map<Id,Set<String>> caseEscalationEmailMap = new Map<Id,Set<String>>();
        Map<Id,Set<String>> escListEmailMap = new Map<Id,Set<String>>();
        
        for(Case eachCase : caseList)
        {
            caseEscListMap.put(eachCase.Id, eachCase.Case_Situation_Handler__r.Handler__r.Escalation_List__c);
        }
        if(caseEscListMap.size() > 0){
            for(SC_SOCC_Escalation_via_Case_Email__c escEmail : [Select id,Authorized_Contact__r.Contact_Name__r.email,Escalation_List__c from SC_SOCC_Escalation_via_Case_Email__c where Escalation_List__c in:(caseEscListMap.values())]){
                if(!escListEmailMap.containsKey(escEmail.Escalation_List__c)){
                    escListEmailMap.put(escEmail.Escalation_List__c, new Set<String>());
                }
                Set<String> escEmailSet = escListEmailMap.get(escEmail.Escalation_List__c);
                escEmailSet.add(escEmail.Authorized_Contact__r.Contact_Name__r.email);
                escListEmailMap.put(escEmail.Escalation_List__c, escEmailSet);
            }
        }
        //End of ESESP-5442
        
        for(Case eachCase : caseList)
        {
            if(String.isNotBlank(eachCase.Contact.Email))
            {
                emailIdSet.add(eachCase.Contact.Email);
            }
            if(String.isNotBlank(eachCase.Alternate_Contact_Email__c))
            {
                emailIdSet.add(eachCase.Alternate_Contact_Email__c);
            }
            
            if(String.isNotBlank(eachCase.AuthorizedContacts__c))
            {    
                additionalEmailIdSet = new Set<String>(eachCase.AuthorizedContacts__c.replace(';',',').split(','));
            }
            
            //ESESP-5442
            if(caseEscListMap.get(eachCase.id) != null && escListEmailMap.size() > 0){
                caseEscalationEmailMap.put(eachCase.id, escListEmailMap.get(caseEscListMap.get(eachCase.id)));
            }
            if(caseEscalationEmailMap.size() > 0 && caseEscalationEmailMap.get(eachCase.id) != null){ 
                emailIdSet.addAll(caseEscalationEmailMap.get(eachCase.id)); 
            }
            //End of ESESP-5442
            
            emailIdSet.addAll(additionalEmailIdSet);
            
            List<String> lEmailIds = new List<String>();
            if(!emailIdSet.isEmpty())
            {
                lEmailIds.addAll(emailIdSet);
                
                Date d = eachCase.CreatedDate.date();
                String emailSubject = '[AKAM-CASE #' + eachCase.AKAM_Case_ID__c + '] | INFORMATIONAL | ' + eachCase.Subject;
                String emailBody = '<b>ACCOUNT:</b> ' + eachCase.Account.Name + '<br/><b>DATE OPENED:</b> ' + eachCase.CreatedDate.format('dd/MM/yyyy') + '<br/>';
                emailBody += '<b>RE:</b> Akamai Support Case #' + eachCase.AKAM_Case_ID__c + '<br/><b>TITLE:</b> ' + eachCase.Subject + '<br/><br/>';
                if(String.isNotBlank(eachCase.ContactId))
                {
                    emailBody += 'Hello ' + eachCase.Contact.Name + ',<br><br>';
                }
                else
                {
                    emailBody += 'Hello,<br><br>';
                }
                emailBody += 'Please use the following link to access the report for Attack Event ID: <a href= "'+ eachCase.Attack_Report_Link__c + '">' + eachCase.Attack_Report_Link__c + '</a>';
                emailBody += '<br>In order to access the attack event report, you must be logged into the Control Center and have the appropriate account access. We will continue to update you throughout the length of this event.';
                emailBody += ' Once it has subsided, we will send a final summary, verify the attack does not resume for 4 hours, and then request authorization to resolve this case.';
                emailBody += '<br><br/>Please send a new email to managedsecurity@akamai.com if you have any further questions or concerns.';
                emailBody += '<br><br/>Regards,<br>';
                if(String.valueOf(eachCase.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()))
                    emailBody += eachCase.Owner.Name + '<br>' + eachCase.Owner.Title + '<br>';
                emailBody += 'Security Operations Command Center<br>';
                emailBody += 'Akamai Technologies<br> (+1) 617-444-4955<br> Toll Free (US Only): 855-662-5662<br>APJ:   (+65) 657-693-50<br/>';
                emailBody += 'EMEA:  (+48) 123-847-924<br/>Japan: (+81) 345-207-530<br/>International Dialing Instructions: https://www.akamai.com/us/en/support/global-support-phone-numbers.jsp';
                emailBody += '<br/><br/>This email and any files transmitted with it are intended solely for the use of the individual or entity to which they are addressed and may contain confidential and/or privileged information. ';
                emailBody += 'If you are not the intended recipient, please delete this message and all attachments from your system and notify me immediately.';
                
                Messaging.SingleEmailmessage email = new Messaging.SingleEmailMessage();
                //email.setTemplateId(emailTempId);
                email.setToAddresses(lEmailIds);
                email.setHtmlBody(emailBody);
                email.setWhatId(eachCase.Id);
                email.setSubject(emailSubject);
                //email.setSaveAsActivity(true);
                email.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('managedsecurity').OrgAddressId__c);
                lEmails.add(email); 
            }
        }
        
        if(!lEmails.isEmpty())
            Messaging.sendEmail(lEmails);
    }
    
    /*  Changes by Vandhana Krishnamurthy
AMG cases should get routed automatically if not created by AMG agents - ESESP-791 and changes for ESESP-1901
changes by Vandhana for ESESP-2634
*/
    
    public static void routeAMGCases(List<Case> amgCases,List<Id> amgCaseOwnerId,Boolean isInsert)
    {
        System.debug('ROUTEAMG CALL');
        Set<String> amgProfile = new Set<String>([SELECT Value_Text__c 
                                                  FROM SC_Utility__mdt 
                                                  WHERE MasterLabel = 'AMG Agent Profile List' LIMIT 1].Value_Text__c.split(','));
        
        Map<Id,User> ownerMap = new Map<Id,User>([SELECT Profile.Name 
                                                  FROM User WHERE Id in :amgCaseOwnerId]);
        
        List<Group> lstAMGGroup = [SELECT Id,Name 
                                   FROM Group 
                                   WHERE Type = 'Queue'
                                   AND (Name like '%AMG%' or Name like '%Primary/Secondary%')];
        
        Set<Id> lstAMGQueueId = new Set<Id>();
        for(Group grp : lstAMGGroup)
            lstAMGQueueId.add(grp.Id);
        
        for(Case eachCase : amgCases)
        {
            if(isInsert)
            {
                if(String.valueOf(eachCase.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()) 
                   && !ownerMap.isEmpty()&& !amgProfile.contains(ownerMap.get(eachCase.OwnerId).Profile.Name))
                    eachCase.Case_Assignment_Using_Active_Rules__c = true;
            }
            else
            {
                if((String.valueOf(eachCase.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()) 
                    && !ownerMap.isEmpty()&& !amgProfile.contains(ownerMap.get(eachCase.OwnerId).Profile.Name) && !eachCase.Validation_Override__c)
                   ||
                   (String.valueOf(eachCase.OwnerId).startsWith(Schema.SObjectType.Group.getKeyPrefix()) &&
                    !lstAMGQueueId.contains(eachCase.OwnerId) && !eachCase.Validation_Override__c)
                  )
                    eachCase.addError('Please select an AMG representative/AMG Queue as Case owner or flag Assign Using Routing Rules to route the Case');
            } 
        }
    }
    
    // changes by Vandhana for ESESP-692 (Force close activities before closing ECOB/NCOB AMG cases)
    public static void checkActCOBCases(Map<Id,Case> amgCases)
    {
        List<Task> taskList = new List<Task>();
        List<SC_Utility__mdt> scUtil = [Select Value_Text__c,DeveloperName
                                        FROM SC_Utility__mdt 
                                        WHERE DeveloperName IN ('COB_Case_Task_Status_Values','COB_Case_Task_Error_Mssg')];
        List<String> s = new List<String>();
        String err = '';
        for(SC_Utility__mdt eachMDT : scUtil)
        {
            if(eachMDT.DeveloperName == 'COB_Case_Task_Status_Values')
            {
                s = eachMDT.Value_Text__c.split(',');
            }
            else
                if (eachMDT.DeveloperName == 'COB_Case_Task_Error_Mssg')
            {
                err = eachMDT.Value_Text__c;
            }
        }
        
        Map<Id,Case> incompleteCase = new Map<Id,Case>([SELECT Id,
                                                        (SELECT Id FROM Tasks WHERE IsClosed = FALSE AND Status NOT IN :s)
                                                        FROM CASE
                                                        WHERE ID IN :amgCases.keySet()
                                                       ]);
        for(Case c : amgCases.values())
        {
            if(incompleteCase.containsKey(c.Id) && incompleteCase.get(c.Id).Tasks.size() > 0)
            {
                c.addError(err);
            }
        }
    }
    
    // changes by Vandhana for ESESP-430 (Close activities for Close-Invalid ECOB AMG cases)
    public static void closeAMGTasks(Map<Id,Case> amgCases)
    {
        List<Task> updateTaskLst = new List<Task>();
        List<Task> closeTaskList = [SELECT Status from Task
                                    WHERE WhatId in :amgCases.keyset()
                                   ];
        for(Task t : closeTaskList)
        {
            t.Status = 'Completed';
            updateTaskLst.add(t);
        }
        if(!updateTaskLst.isEmpty())
        {
            update updateTaskLst;
        }
    }
    
    // changes by Vandhana for ESESP-692 (Force close activities before closing ECOB/NCOB AMG cases)
    public static void changeCOBTaskOwnerAMG(Map<Id,Case> amgCOBCases)
    {
        System.debug('Entered TaskOwnerFunction');
        
        Set<Id> ownerIdSet = new Set<Id>();
        Map<Id,User> userMap = new Map<Id,User>();
        
        for(Id caseId : amgCOBCases.keySet())
        {
            ownerIdSet.add(amgCobCases.get(caseId).OwnerId);
        }
        userMap = new Map<Id,User>([Select Id,ProfileId,Profile.Name 
                                    from User 
                                    where Id in :ownerIdSet]);
        
        Set<String> profId = new Set<String>([Select Value_Text__c 
                                              from SC_Utility__mdt 
                                              where DeveloperName = 'AMG_Agent_Profile_List'].Value_Text__c.split(','));
        
        List<Task> taskList = new List<Task>();
        
        String getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        User userRec = new User();
        userRec = [SELECT Id from user where alias = :getOwnerAlias limit 1];
        
        Map<Id,Task> tasksForUpdate = new Map<Id,Task>([SELECT WhatId,OwnerId,Subject,Status,IsClosed
                                                        FROM Task
                                                        WHERE WhatId IN :amgCOBCases.keySet()
                                                        AND Status NOT IN ('Completed','Not Applicable')
                                                        AND IsClosed = FALSE
                                                        limit 50000
                                                       ]);
        for(Task t : tasksForUpdate.values())
        {
            System.debug('----- New Owner for Task : ' + amgCOBCases.get(t.WhatId).OwnerId);
            
            if(String.valueOf(amgCOBCases.get(t.WhatId).OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
               && profId.contains(userMap.get(amgCOBCases.get(t.WhatId).OwnerId).Profile.Name)
              )
                t.OwnerId = amgCOBCases.get(t.WhatId).OwnerId;
            else
            {
                t.OwnerId = userRec.Id;
            }
            taskList.add(t);
        }
        
        if(!taskList.isEmpty())
        {
            update taskList;
        }
    }
    
   //Changes by Vandhana : Moved it to SC_CaseTriggerHelperClass2
   /* public static void createCaseHistoryTrackerRec(Map<Id,Case> oldCase,Map<Id,Case> newCase)
    {
        List<Case_History_Tracker__c> chList = new List<Case_History_Tracker__c>();
        
        Case_History_Tracker__c ch = new Case_History_Tracker__c();
        List<SC_Case_History_Tracker__mdt> histTrackMDT = [Select Tracked_Field_Name__c, Tracked_Field_API_Name__c,
                                                           Duration_Field_API__c , Value_stored_in_Case_Field__c  
                                                           from SC_Case_History_Tracker__mdt];
        
        Map<String,SC_Case_History_Tracker__mdt> histTrackMDTMap = new Map<String,SC_Case_History_Tracker__mdt>();
        
        for(SC_Case_History_Tracker__mdt eachMDT : histTrackMDT)
        {
            histTrackMDTMap.put(eachMDT.Tracked_Field_API_Name__c,eachMDT);
        }
        
        for(Case c : newCase.values())
        {
            for(String caseFieldAPI : histTrackMDTMap.keySet())
            {
                if(oldCase.get(c.Id).get(caseFieldAPI) != newCase.get(c.Id).get(caseFieldAPI))
                {
                    ch = new Case_History_Tracker__c(Case__c=c.Id,
                                                     Case_Field__c = histTrackMDTMap.get(caseFieldAPI).Tracked_Field_Name__c,
                                                     Duration__c = String.valueOf(Trigger.oldMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Duration_Field_API__c)),
                                                     Old_Value__c = String.valueOf(Trigger.oldMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Value_stored_in_Case_Field__c)),
                                                     New_Value__c = String.valueOf(Trigger.newMap.get(c.Id).get(histTrackMDTMap.get(caseFieldAPI).Value_stored_in_Case_Field__c))
                                                    );
                    if(caseFieldAPI == 'OwnerId')
                    {
                        ch.Old_Case_Owner_Team__c = oldCase.get(c.Id).Case_Owner_Team__c;
                    }
                    ch.Case_Owner_Team__c = newCase.get(c.Id).Case_Owner_Team__c;
                    chList.add(ch);
                }    
            }
        }    
        
        try
        {
            if(!chList.isEmpty())
            {
                insert chList;
            }   
        }
        catch(Exception e)
        {
            System.debug('Case History Tracker records insert failed :');
            System.debug('Message : ' + e.getMessage());
            System.debug('Stack Trace : ' + e.getStackTraceString());
        }
    }*/ 
    
    /** Added by Sumanth For JIRA ESEP 1004 **/
    // changes by Vandhana for Carrier LX Migration
    public static void checkEDDependency(List<Case> carrierCases)
    {
        /**Variable to store custom metadata data **/
        /*
        String subjValue = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE MasterLabel = 'Nominum External Dependency Check' LIMIT 1].Value_Text__c;
        List<String> EdType = new List<String>();
        for(String Key:subjValue.split(','))
        {   EdType.add(Key);    }
        
        List<External_Dependency__c> externalDependencies = new List<External_Dependency__c>();
        Map<Id,Id> caseEDmap = new Map<Id,Id>();
        externalDependencies =[Select Name,Case__c from External_Dependency__c where Type__c in :EdType and Case__c in :carrierCases];
        
        for(External_Dependency__c E : externalDependencies)
        {
            caseEDmap.put(E.Case__c,E.Id);
        }
        */
        
        List<Engagement_Request__c> lstExtTeamEsc = new List<Engagement_Request__c>();
        Map<Id,Id> mapCaseExtTeam = new Map<Id,Id>();
        
        lstExtTeamEsc = [SELECT Id,Case__c FROM Engagement_Request__c 
                         WHERE RecordType.Name = 'External Team' AND Case__c in :carrierCases];
        
        for(Engagement_Request__c eachEscRec : lstExtTeamEsc)
        {
            mapCaseExtTeam.put(eachEscRec.Case__c,eachEscRec.Id);
        }

        for(Case eachCase : carrierCases)
        {
            if(!mapCaseExtTeam.containsKey(eachCase.Id))
            {
                eachCase.addError('New Software Failure OR Pre-existing Software Failure Case requires atleast 1 External Team Escalation');
            }
        }
    }
    
    /**Added By Sumanth as part of ESESP 934 **/
    public Static void sendemailMS(List<Case> MSCases,Map<Id,Case> CaseOldMap)
    {
        
        //Get Org Wide Email address 
        //List<OrgWideEmailAddress> OrgWideID = [select Id from OrgWideEmailAddress where Address = 'sf-no-reply@akamai.com'];
        String subjValue = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE MasterLabel = 'Org Wide Address MS' LIMIT 1].Value_Text__c;
        
        //Get the environment  custom  setting
        Environment_Setup__c  E = Environment_Setup__c.getOrgDefaults();
        
        //Get a list of Previous Owner ids
        List<Id> OwnerIds = new List<Id>();
        Map<Case,Id> CaseIdMap = new Map<Case,Id>();
        
        for(Case C:MSCases)
        {
            
            OwnerIds.add(CaseOldMap.get(C.id).OwnerId);
            CaseIdMap.put(C,CaseOldMap.get(C.id).OwnerId);
            
        }
        
        //Fetch Owner Email for all  owner Id
        List<User> UserList = [Select Id, Email,Name from User where Id in :OwnerIds];
        
        //Construct a map of Cases and Email
        Map<Id,String> OwnerEmailMap = new Map<Id,String>();
        for(User U : UserList)
        {            
            OwnerEmailMap.put(U.Id,U.Email);
        }
        
        Map<Case,String> CaseEmailMap = new Map<Case,String>();
        for(Case C:MSCases)
        {
            CaseEmailMap.put(C,OwnerEmailMap.get(CaseIdMap.get(C)));
        }
        
        
        //Get Account.Name,Contact.Name,RecordType.Name,LastModifiedBy.Name for filling in template
        List<Case> CaseDetails = [Select Account.Name,Contact.Name,RecordType.Name,LastModifiedBy.Name From Case where id in :MSCases];
        Map<Id,Case> CaseDetailsMap = new Map<Id,Case>();
        For(Case C:CaseDetails)
        {
            CaseDetailsMap.put(C.id,C);
        }
        
        List<Messaging.SingleEmailMessage> EmailList = new List<Messaging.SingleEmailMessage>();
        
        for(Case C: MSCases)
        {
            List<String> toemail = new List<String>();
            toemail.add(CaseEmailMap.get(C));
            String CaseContact;
            if(CaseDetailsMap.get(C.id).Contact.Name != null)
            {
                CaseContact=CaseDetailsMap.get(C.id).Contact.Name;
            }
            else
            {
                CaseContact = '';
            }
            
            String body = 'Go to Case: '+E.CName_Url__c+C.AKAM_Case_ID__c;
            body+='<br><br>';
            body+='<table border="1" style="border-collapse:collapse;"><tr><td>Case #: </td><td>'+C.AKAM_Case_ID__c+'</td></tr>';
            body+='<tr><td> Account: </td><td>'+CaseDetailsMap.get(C.id).Account.Name+'</td></tr>';
            body+='<tr><td> Type:  </td><td>'+CaseDetailsMap.get(C.id).RecordType.Name+'</td></tr>';
            body+='<tr><td> Opened Date: </td><td>'+C.AKAM_Created_Date__c+'</td></tr>';
            body+='<tr><td> Severity: </td><td>'+C.Severity__c+'</td></tr>';
            body+='<tr><td> Case Contact: </td><td>'+CaseContact+'</td></tr>';
            body+='<tr><td> Subject: </td><td>'+C.Subject+'</td></tr>';
            body+='<tr><td> Description: </td><td>'+C.Description+'</td></tr>';
            body+='<tr><td> Ownership Changed By: </td><td>'+UserInfo.getName()+'</td></tr>';
            body+='<tr><td> New Owner: </td><td>'+C.Case_Owner_Name__c+'</td></tr></table>';
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toemail);
            mail.setOrgWideEmailAddressId(subjValue);
            mail.setSubject('[AKAM-CASE #'+C.AKAM_Case_ID__c+']'+' '+'has been assigned to'+' '+ C.Case_Owner_Name__c );
            mail.setHtmlBody(body);
            mail.setUseSignature(false);
            EmailList.add(mail);
        }
        
        if(EmailList.size() > 0) 
        {
            Messaging.SendEmailResult [] r = Messaging.sendEmail(EmailList);
        }
    }
    
    //ESESP-1402 : AMP Case product Update
    //
    public static void addAMPCaseProduct(List<Case> caseList){
        //List of Account Id with AMP Cases
        List<Id> accList = new List<Id>();
        
        for(Case eachCase : caseList){
            accList.add(eachCase.AccountId);
        }
        //List of AMP Prod
        List<String> AMPProdList = new List<String>();
        String AMPProdStr = [Select Value_Text__c,DeveloperName FROM SC_Utility__mdt WHERE DeveloperName = 'AMP_Products'].Value_Text__c;
        AMPProdList.addAll(AMPProdStr.split(','));
        
        //Set of Account Ids which has product AMP as one of their line item
        Set<String> accountWithAMPProdSet = new Set<String>(); 
        
        for(Merge_Contract_Detail__c eachDetail :[Select Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c,Original_Contract_Id__r.Account_Name__c,
                                                  Original_Detail_Id__c,Product_Id__c, Product__c from Merge_Contract_Detail__c where Original_Contract_Id__r.Account_Name__c IN :accList 
                                                  and Effective_End_Date__c != Null and Effective_Start_Date__c != Null and Effective_Start_Date__c <= Today and Effective_End_Date__c >= Today 
                                                  and Original_Contract_Id__r.Active__c = true and Original_Contract_Id__r.Locked__c = true and Product_Id__c IN :AMPProdList])
        {
            accountWithAMPProdSet.add(eachDetail.Original_Contract_Id__r.Account_Name__c);
        } 
        
        //Map to store Account Id and AMP Case Product Id
        Map<Id,Id> accountCaseProdMap = new Map<Id,Id>();
        
        for(EB_AccountProductMap__c eachCaseProd : [Select id, EB_Account__c, EB_Product__c,EB_Account__r.Name from EB_AccountProductMap__c where EB_Product__c ='Adaptive Media Player' and EB_Account__c IN:accountWithAMPProdSet]){
            accountCaseProdMap.put(eachCaseProd.EB_Account__c,eachCaseProd.id);
        } 
        
        Map<String,EntitlementID__c> entitlementIds = EntitlementID__c.getAll();
        //List of cases for which case product need to be set as AMP
        for(Case eachCase : caseList){
            if(accountWithAMPProdSet.contains(eachCase.accountId)){
                if(!accountCaseProdMap.isEmpty() && accountCaseProdMap.containsKey(eachCase.accountId)){
                    system.debug('----accountCaseProdMap---'+accountCaseProdMap);
                    eachCase.Case_Product__c = accountCaseProdMap.get(eachCase.accountId);
                    if(entitlementIds.get('AMPStandard').EntitlementID__c != Null)
                        eachCase.EntitlementId = entitlementIds.get('AMPStandard').EntitlementID__c;
                } 
            }
        }
    }
    //End of change ESESP-1402 : AMP Case product Update
    
    //ESESP-1204 Changes
    public Static void sendEmailPreSales(List<Case> PreSalesCases,Map<Id,Case> CaseOldMap,Map<Id,Case> CaseNewMap)
    {
        List<Id> OwnerIds = new List<Id>();
        List<Id> OwnerIdNew = new List<Id>();
        List<Id> OwnerIdCreator = new List<id>();
        Map<Case,Id> CaseOldOwnerIdMap = new Map<Case,Id>();
        Map<Case,Id> CaseNewOwnerIdMap = new Map<Case,Id>();
        Map<Case,Id> CaseCreatedByIdMap = new Map<Case,Id>();
        List<Id> AllUserId = new List<Id>();
        List<Id> AllQueueId = new List<Id>();
        Map<Id,String> GenericUserEmailMap = new Map<Id,String>();
        Map<Id,String> GenericQueueEmailMap = new Map<Id,String>();
        Map<Case,String> CaseOldEmailMap = new Map<Case,String>();
        Map<Case,String> CaseNewEmailMap = new Map<Case,String>();
        Map<Case,String> CaseCreatorEmailMap = new Map<Case,String>();
        
        String subjValue = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE MasterLabel = 'Org Wide Address MS' LIMIT 1].Value_Text__c;
        
        Environment_Setup__c  E = Environment_Setup__c.getOrgDefaults();
        
        for(Case C:PreSalesCases)
        {
            OwnerIds.add(CaseOldMap.get(C.id).OwnerId);
            OwnerIdNew.add(C.OwnerId);
            OwnerIdCreator.add(C.CreatedById);
            CaseOldOwnerIdMap.put(C,CaseOldMap.get(C.id).OwnerId);
            CaseNewOwnerIdMap.put(C,C.OwnerId);
            CaseCreatedByIdMap.put(C,C.CreatedById);
        }
        
        for(Id OwnerId:OwnerIds)
        {
            if(OwnerId.getsobjecttype()==User.getsobjecttype())
            {
                AllUserId.add(OwnerId);   
            }
            
            if(OwnerId.getsobjecttype()==Group.getsobjecttype())
            {
                AllQueueId.add(OwnerId);
            }
        }
        
        for(Id OwnerId:OwnerIdNew)
        {
            if(OwnerId.getsobjecttype()==User.getsobjecttype())
            {
                AllUserId.add(OwnerId);
            }
            
            if(OwnerId.getsobjecttype()==Group.getsobjecttype())
            {
                AllQueueId.add(OwnerId);
            }
        }
        
        for(Id OwnerId:OwnerIdCreator)
        {   
            AllUserId.add(OwnerId);   
        }
        
        List<User> UserList = [Select Id, Email,Name from User where Id in :AllUserId];
        List<Group> GroupList = [Select Id,Name,Email from Group where Id in :AllQueueId];
        
        for(User U : UserList)
        {
            GenericUserEmailMap.put(U.Id,U.Email);
        }
        
        for(Group G:GroupList)
        {
            GenericQueueEmailMap.put(G.Id,G.Email);
        }
        
        for(Case C:PreSalesCases)
        {
            if(CaseOldOwnerIdMap.get(C).getsobjecttype()==User.getsobjecttype())
            {
                CaseOldEmailMap.put(C,GenericUserEmailMap.get(CaseOldOwnerIdMap.get(C)));
            }
            
            if(CaseOldOwnerIdMap.get(C).getsobjecttype()==Group.getsobjecttype())
            {
                CaseOldEmailMap.put(C,GenericQueueEmailMap.get(CaseOldOwnerIdMap.get(C)));   
            }
        }
        
        //Construct a map of Case and associated New Owner Email Map
        for(Case C:PreSalesCases)
        {
            if(CaseNewOwnerIdMap.get(C).getsobjecttype()==User.getsobjecttype())
            {
                CaseNewEmailMap.put(C,GenericUserEmailMap.get(CaseNewOwnerIdMap.get(C)));   
            }
            
            if(CaseNewOwnerIdMap.get(C).getsobjecttype()==Group.getsobjecttype())
            {
                CaseNewEmailMap.put(C,GenericQueueEmailMap.get(CaseNewOwnerIdMap.get(C)));
            }
        }
        
        for(Case C:PreSalesCases)
        {    
            CaseCreatorEmailMap.put(C,GenericUserEmailMap.get(CaseCreatedByIdMap.get(C)));
        }
        
        List<Case> CaseDetails = [Select Account.Name, Account.Geography_Formula__c,Opportunity__c,Account.Division_Formula__c,Account.Division__c,Account.Region__c,Account.Area__c,CreatedBy.Name,Request_Type__c,Request_Sub_Type__c,Pre_Sales_Product__c,Owner.Name,Contact.Name,RecordType.Name,LastModifiedBy.Name From Case where id in :PreSalesCases];
        Map<Id,Case> CaseDetailsMap = new Map<Id,Case>();
        Map<Id,Id> CaseOpportunityMap = new Map<Id,Id>();
        Map<Id,String> OppIdNameMap = new Map<Id,String>();
        List<Id>  CaseOppId = new List<Id>();
        
        for(Case C:CaseDetails)
        {
            CaseDetailsMap.put(C.id,C);
            CaseOppId.add(C.Opportunity__c);
            CaseOpportunityMap.put(C.Id,C.Opportunity__c);
        }
        
        List<Opportunity> OpportunityNames =[Select Name from Opportunity where id in :CaseOppId];
        
        for(Opportunity O:OpportunityNames)
        {
            OppIdNameMap.put(O.id,O.Name);
        }
        
        //Code to send email to old owner, new owner,Creator
        List<Messaging.SingleEmailMessage> EmailList = new List<Messaging.SingleEmailMessage>();
        for(Case C:PreSalesCases)
        {
            List<String> toemail = new List<String>();
            toemail.add(CaseOldEmailMap.get(C));
            toemail.add(CaseNewEmailMap.get(C));
            toemail.add(CaseCreatorEmailMap.get(C));
            
            String body = '<table border="1" style="border-collapse:collapse;"><tr><td>Case #: </td><td>'+E.CName_Url__c+C.AKAM_Case_ID__c+'</td></tr>';
            body+='<tr><td> Account Name: </td><td>'+'<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+c.AccountId+' >'+CaseDetailsMap.get(C.id).Account.Name+'</a></td></tr>';
            body+='<tr><td> Account Geography: </td><td>'+CaseDetailsMap.get(C.id).Account.Geography_Formula__c+'</td></tr>';
            body+='<tr><td> Account Division: </td><td>'+CaseDetailsMap.get(C.id).Account.Division_Formula__c+'</td></tr>';
            body+='<tr><td> Account Region: </td><td>'+CaseDetailsMap.get(C.id).Account.Division__c+'</td></tr>';
            body+='<tr><td> Account Area: </td><td>'+CaseDetailsMap.get(C.id).Account.Region__c+'</td></tr>';
            body+='<tr><td> Account Territory: </td><td>'+CaseDetailsMap.get(C.id).Account.Area__c+'</td></tr>';
            body+='<tr><td> Opportunity Name: </td><td>'+'<a href=' +System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+c.Opportunity__c+' >'+OppIdNameMap.get(CaseOpportunityMap.get(C.Id))+'</a></td></tr>';
            body+='<tr><td> Created By: </td><td>'+CaseDetailsMap.get(C.id).CreatedBy.Name+'</td></tr>';
            body+='<tr><td> Request Type: </td><td>'+C.Request_Type__c+'</td></tr>';
            body+='<tr><td> Request Sub Type: </td><td>'+C.Request_Sub_Type__c +'</td></tr>';
            body+='<tr><td> Product: </td><td>'+C.Pre_Sales_Product__c +'</td></tr>';
            body+='<tr><td> Subject: </td><td>'+C.Subject+'</td></tr>';
            body+='<tr><td> Description: </td><td>'+C.Description+'</td></tr>';
            body+='<tr><td> Owner: </td><td>'+C.Case_Owner_Name__c+'</td></tr></table>';
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toemail);
            mail.setOrgWideEmailAddressId(subjValue);
            mail.setSubject('[AKAM-CASE #'+C.AKAM_Case_ID__c+']'+' '+'has been reassigned to '+' '+C.Case_Owner_Name__c);
            mail.setHtmlBody(body);
            mail.setUseSignature(false);
            EmailList.add(mail);
        }
        
        if(EmailList.size() > 0) 
        {
            Messaging.SendEmailResult [] r = Messaging.sendEmail(EmailList);
        }
    }

    //Method for Jira 1916
    // changes by Vandhana for AMG Lightning Migration : added ContentDocument for Lightning Attachments on AMG Cases
    public static void checkAMGAttachments(Map<Id,Case> caseList)
    {
        //Make a map of Case id and attachments.If for any Case attachment count is zero throw an error
        Boolean errorAttach = FALSE;
        Boolean errorFile = FALSE;
        
        Map<Id,Case> CaseAttachments = new Map<Id,Case>([Select Id,(Select Id,Name from Attachments) from Case where Id in :CaseList.keySet()]);
        
        Map<Id,Integer> caseContDocCountMap = new Map<Id,Integer>();
        
        Map<Id,ContentDocumentLink> contDocMap =  new Map<Id,ContentDocumentLink>([SELECT Id, LinkedEntityId,ContentDocument.Title 
                                                                                   FROM ContentDocumentLink 
                                                                                   WHERE LinkedEntityId IN :caseList.keySet()
                                                                                   AND ContentDocument.FileExtension LIKE '%xls%'
                                                                                  ]);
        
        //Select Id, LinkedEntityId,ContentDocument.Title from ContentDocumentLink where LinkedEntityId = '5000f00001Wfwp9AAB'
        
        for(ContentDocumentLink contDocLink : contDocMap.values())
        {
            if(caseContDocCountMap.containsKey(contDocLink.LinkedEntityId))
            {
                caseContDocCountMap.put(contDocLink.LinkedEntityId,caseContDocCountMap.get(contDocLink.LinkedEntityId) + 1);
            }
            else
                  {
                caseContDocCountMap.put(contDocLink.LinkedEntityId,1);
            }
        }
                  
        for(Case C : caseList.values())
        {
            if(CaseAttachments.containsKey(C.Id))
            {
                if((CaseAttachments.get(C.id).Attachments == null || CaseAttachments.get(C.id).Attachments.size() == 0)){errorAttach = TRUE;}

                  //Checking for file extension
                  if(CaseAttachments.get(C.id).Attachments.size()>0){
                      Boolean Flag = false;
                      
                      //Check for Attachment Name
                      for(Attachment A:CaseAttachments.get(C.id).Attachments){
                            if(A.Name.endsWithIgnoreCase('.xls') || A.Name.endsWithIgnoreCase('.xlsx')){errorAttach = FALSE; break;}
                      }
                }
            }
            if(!caseContDocCountMap.containsKey(c.Id)){errorFile = TRUE;}
                      
            if(errorAttach && errorFile){C.addError('Cases cannot be closed without a peer review file');}
            }
        
        
    }
    
    // ESESP-758 AMG SLA improvements - On Case transition to AMG update Case Fields (Transitiona and AMG Received Date) 
    public static void caseTransitionToAMG(List<Case> newCases, Map<Id, Case> odlCaseMap, Map<Id, String> recTypeMap) {
        // Update Transition anf AMG Received Date fields
        for(Case cs: newCases) {
            if( recTypeMap.get(cs.RecordTypeId) == 'AMG' && recTypeMap.get(odlCaseMap.get(cs.Id).RecordTypeId) != 'AMG') {
                cs.AMG_Transition__c = true;
                cs.AMG_Received_Date__c = System.now();
            }
        }
    }

    // ESESP-758 AMG SLA improvements - Cases with open milestones should not be closed
    public static void rejectCasesWithOpenMs(List<Case> lCases, List<String> mileStones) {
        Map<Id, Case> caseMap = new Map<Id, Case>(lCases);
        for(CaseMilestone cm: [select Id, MilestoneType.Name, completionDate, CaseId from CaseMilestone where CaseId in :lCases 
                               and completionDate = null and MilestoneType.Name IN :mileStones]) {
               caseMap.get(cm.CaseId).addError('Please send out "'+ cm.MilestoneType.Name +'" to the customer before closing the case');
        }
    }
    
    /*********** Case dispatcher method for SOCC Related Changes **********/
    public static void soccCaseTriggerDispatcher(List<Case> caseNewList,Map<Id,Case> caseNewMap,Map<Id,Case> caseOldMap,Boolean isInsert,Boolean isUpdate,map<Id, string> mRecordType)
    {
        /*** For Populating SOCC Priority fields & Has Instruct flag during Case Creation ***/
        If(isInsert)
        {
            List<Case> CaseList = new List<Case>();
            List<Case> casePopulateFlag = new List<Case>(); //Populate Instruct Flag during creation -- during creation
            set<Id> accIdListForPriorityIn = new set<Id>();
            
            for(Case varCase:caseNewList)
            {
                if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && varCase.AccountId != null)
                {
                    accIdListForPriorityIn.add(varCase.AccountId);
                    CaseList.add(varCase);
                }
                
                
                //To Calculate Instruct Flag
                if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && varCase.Policy_Domain__c!=null && varCase.ContactId!=null)
                {
                    casePopulateFlag.add(varCase);
                }
                
            }
            If(!CaseList.isEmpty())
            {
                CaseTriggerClass.populateSOCCPriorityFields(CaseList, accIdListForPriorityIn);
            }
            
            /**************************** 
            //To Calculate Instruct Flag
            if(!casePopulateFlag.isEmpty())
            {
                CaseTriggerClass.populateIsInsturctFlag(casePopulateFlag,caseNewMap);
            }
            ****************************/
        }
        /*** End of block For Populating SOCC Priority fields & Has Instruct flag during Case Creation ***/
        
        /**************************************************************************************************************************/
        
        /*** Code block for Populating Instruct flag during Case Update *****/
        If(isUpdate)
        {
            List<Case> CaseList = new List<Case>();
            List<Case> caseListForBlankContact = new List<Case>();
            List<Case> CaseListPriority = new List<Case>();
            List<Case> CaseListTaskCheck = new List<Case>();
            set<Id> accIdListForPriority = new set<Id>();
              
            for(Case varCase:caseNewList)
            {
                // resetting to Default Null or No Value
                if(varCase.Is_SOCC_Priority__c!=true && mRecordType.get(varCase.RecordTypeId).equals('Managed Security'))
                {
                 varCase.Is_SOCC_Priority__c = false;
                 varCase.Priority_Expiry_Date__c = null;
                 varCase.Priority_Type__c = null;
                }
                 
                // Condition - 1 : For Instruct Flag - for setting to True
                if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && 
                ((caseOldMap.get(varCase.Id).ContactId!=caseNewMap.get(varCase.Id).ContactId && caseNewMap.get(varCase.Id).ContactId!=Null) || 
                caseOldMap.get(varCase.Id).Policy_Domain__c!=caseNewMap.get(varCase.Id).Policy_Domain__c && caseNewMap.get(varCase.Id).Policy_Domain__c!=Null)
                ){
                    CaseList.add(varCase);
                }
                
                /*** For Transition Scenario ***/
                 if(caseOldMap.get(varCase.Id).RecordTypeId!=caseNewMap.get(varCase.Id).RecordTypeId && mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && 
                    caseNewMap.get(varCase.Id).AccountId != null)
                 {
                   
                    CaseListPriority.add(varCase);
                    accIdListForPriority.add(varCase.AccountId);
                 }
                 
                 /*** Scenario when Account is added later -Email to Case ****/
                 if(caseOldMap.get(varCase.Id).AccountId!=caseNewMap.get(varCase.Id).AccountId && mRecordType.get(varCase.RecordTypeId).equals('Managed Security'))
                 {
                    
                    CaseListPriority.add(varCase);
                     accIdListForPriority.add(varCase.AccountId);
                 }
                 
                 // FOR Checking no of Open Task
                 if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && caseNewMap.get(varCase.Id).Status=='Closed' && 
                    caseOldMap.get(varCase.Id).Status!=caseNewMap.get(varCase.Id).Status )
                 {  
                        CaseListTaskCheck.add(varCase);
                    
                 }
                
            }
            
            
            //system.debug('Case List11'+CaseList);
            if(CaseList.size() > 0)
            {
                CaseTriggerClass.populateIsInsturctFlag(CaseList,caseNewMap);
            }
            if(CaseListPriority.size() > 0){
                 
                    //system.debug('CaseListPriority '+CaseListPriority);
                    CaseTriggerClass.populateSOCCPriorityFields(CaseListPriority,accIdListForPriority);
            }
            if(CaseListTaskCheck.size() > 0)
            {
                //system.debug('Case List'+CaseList);
                CheckforOpenTasksMS(CaseListTaskCheck);
            }   
            
        }
      
      // Setting Recursion Flag to False  
      avoidRecursionSOCCLogic = false;  
    }
   /*********** End of Case dispatcher method for SOCC Related Changes *****/
    
    
    //SOCC related changes
    public static void populateSOCCPriorityFields(List<Case> CaseList,set<Id> accIdListForPriority)
    {
          
         //Create a map of Account Id + Account
         Map<Id,Account> AccountMap = new map<Id,Account>();
         
         for(Account accRec : [Select Id,High_Priority_SOCC_Customer__c,Priority_Expiry_Date_SOCC__c, Priority_Type_SOCC__c 
                                from Account 
                                where Id=:accIdListForPriority])
         {
         
             AccountMap.put(accRec.Id,accRec);
         
         }
         
         
         for(Case C:CaseList)
         {
             
             if(C.Is_SOCC_Priority__c != true)
             {
                C.Is_SOCC_Priority__c      = AccountMap.get(C.AccountId).High_Priority_SOCC_Customer__c;
                C.Priority_Expiry_Date__c  = AccountMap.get(C.AccountId).Priority_Expiry_Date_SOCC__c;
                C.Priority_Type__c         = AccountMap.get(C.AccountId).Priority_Type_SOCC__c;
             }
         
         }
    }
    
    
    //SOCC related changes 2
    public static void populateIsInsturctFlag(List<Case> CaseList, Map<Id,Case> caseNewMap)
    {
         //Create a Map of Case and Policy Domain Id
         Map<Id,Id> CasePolicyDomainId = new Map<Id,Id>();
         //Create a Map of Case Id & Contact
         Map<Id,Id> CaseContactId = new Map<Id,Id>();
         set<string> allFilterCaseId = new set<string>();
         
         
         for(Case C: CaseList)
         {
                 CasePolicyDomainId.put(C.Id,C.Policy_Domain__c);
                 CaseContactId.put(C.Id,C.ContactId);
                 
                 // resetting to Default Null or No Value
                 C.Instruct__c = null;
                 
                 allFilterCaseId.add(C.Id);
         }
         
         //Query All Authorized Contact for PD that have Instruct flag set to true
         
         List<Authorized_Contact__c> relevantAuthCont = [SELECT Id, Contact_Name__c, Instruct__c,Policy_Domain__c FROM Authorized_Contact__c where Policy_Domain__c in:CasePolicyDomainId.Values() and Instruct__c = true ];
      
         //Create a map of PD, and List of Auth Contact
         Map<Id,set<string>> PDAuthContList = new  Map<Id,set<string>>();
         for(Authorized_Contact__c ac : relevantAuthCont)
         {
             
             if(PDAuthContList.containsKey(ac.Policy_Domain__c)){
                 set<string> Tempauthlist = PDAuthContList.get(ac.Policy_Domain__c);Tempauthlist.add(ac.Contact_Name__c);PDAuthContList.put(ac.Policy_Domain__c,Tempauthlist);
             
             }
             else{
                 PDAuthContList.put(ac.Policy_Domain__c,new set<string> {ac.Contact_Name__c});
             }
              
         
         }
         
       //Finally update the Case List to be updated
       
       for(Case C: caseNewMap.values())
       {
            if(allFilterCaseId.contains(C.Id)){
            
                if(PDAuthContList.get(C.Policy_Domain__c) != null && PDAuthContList.get(C.Policy_Domain__c).Contains(C.ContactId))
                    C.Instruct__c  = 'Yes';
                else
                    C.Instruct__c  = 'No';
            }
       }
       
    }
    
    
    //SOCC Related Changes 3
    public static void CheckforOpenTasksMS(List<Case> CaseList)
    {
        //Declare a map
        map<id,integer> caseId_noOfTask_map=new map<id,integer>();
        
        //Aggregate query
        List<AggregateResult> taskresult = [Select whatid,count(id) from task where what.type ='Case' and what.recordtype.name='Managed Security' and whatid in:CaseList and status NOT IN ('Completed', 'Completed Important')
                                            group by whatid];
        
        for(AggregateResult ar : taskresult){
            caseId_noOfTask_map.put((string)ar.get('whatid'), (integer)ar.get('expr0'));
        }
        
        //Check Task count and throw error
        for(Case C:CaseList)
        {
            
            if(caseId_noOfTask_map .get(C.Id)>0)
            {
                C.addError('You cannot close a Managed Security Case with one or more Open Tasks');
            } 
            
        }
        
        
    }
     
    //ESESP-3075 : Method for populating partner Account for AMG Cases
    public static void addPartnerAccount(Set<Id> accountIds, List<Case> caseList)
    {
        Map<id, Current_Sales_Channel__c> AccCurrMap = new Map<id, Current_Sales_Channel__c>();
        List<Account> Acclst = new List<Account>();
        
        Acclst = [select id, Indirect_Customer__c, (select id, Partner_Account__c from Current_Sales_Channels__r) from Account where id =: accountIds];
        
        for(Account acc : Acclst)
        {
            if(acc.Current_Sales_Channels__r.size() == 1 && acc.Indirect_Customer__c==true)
            {
                AccCurrMap.put(acc.id, acc.Current_Sales_Channels__r);
            }
        }
        
        for(Case c : caseList)
        {
            If(AccCurrMap.containsKey(c.AccountId))
            {
                c.Partner_Account__c = AccCurrMap.get(c.AccountId).Partner_Account__c;
            }
            else
            {
                c.Partner_Account__c = null;
            }
        }
    }
    
    //ESESP-3075 : Method for validating partner Account for AMG Cases
    public static void validatePartnerAccount(Set<Id> accIds, List<Case> caseList)
    {
        Set<Id> partnerCaseIds = new Set<Id>();
        String accountId;
        Set<Id> partIds = new Set<Id>();
        Set<Id> partIds2 = new Set<Id>();
        
        Map<Id,Set<Id>> mCustPartIdMap = new  Map<Id,Set<Id>>();
        
        List<Current_Sales_Channel__c> currSalesList = [select id, Customer_Account__c,Partner_Account__c from Current_Sales_Channel__c where Customer_Account__c =: accIds];
        
        
        for(Current_Sales_Channel__c cuSales : currSalesList)
        {
            if(!mCustPartIdMap.containsKey(cuSales.Customer_Account__c)){
                mCustPartIdMap.put(cuSales.Customer_Account__c, new Set<Id>());                
            }
            mCustPartIdMap.get(cuSales.Customer_Account__c).add(cuSales.Partner_Account__c);
            
        }
    
        for(Case cs :caseList)
        {
            if(mCustPartIdMap.containsKey(cs.AccountId) && !mCustPartIdMap.get(cs.AccountId).contains(cs.Partner_Account__c))
            {
                cs.addError('Add relevant Partner Account');
            }
            if(!mCustPartIdMap.containsKey(cs.AccountId))
            {
                cs.addError('There is no Partner Account associated with the Account');
            }
        }
        
    }
    
    //ESESP-3075 : Method for populating Indirect Customer for AMG Cases
    public static void addIndirectCustomer(Set<Id> accIds, List<Case> caseList)
    {
        map<Id,Set<Id>> mPartCustIds = new map<Id,Set<Id>>();
        List<Current_Sales_Channel__c> currSalesList = [select id, Customer_Account__c,Partner_Account__c from Current_Sales_Channel__c where Partner_Account__c =: accIds];
        
        for(Current_Sales_Channel__c currSales: currSalesList){
            if(!mPartCustIds.containsKey(currSales.Partner_Account__c)){
                mPartCustIds.put(currSales.Partner_Account__c, new Set<Id>());                
            }
            mPartCustIds.get(currSales.Partner_Account__c).add(currSales.Customer_Account__c);
        }
        
        for(Case cs :caseList)
        {
            if(mPartCustIds.containsKey(cs.AccountId) && mPartCustIds.get(cs.AccountId).size()==1)  
            {
                cs.Indirect_Customer__c =(new list<Id>(mPartCustIds.get(cs.AccountId))[0]);
            }
            else{
                cs.Indirect_Customer__c = null;
            }
        }
    }    
    
    
    //ESESP-3075 :Method for validating partner Account for AMG Cases
    public static void validateIndirectCustomer(Set<Id> accIds, List<Case> caseList)
    {
        
        
        map<Id,Set<Id>> mPartCustIds = new map<Id,Set<Id>>();
        List<Current_Sales_Channel__c> currSalesList = [select id, Customer_Account__c,Partner_Account__c from Current_Sales_Channel__c where Partner_Account__c =: accIds];
        
        for(Current_Sales_Channel__c currSales: currSalesList){
            if(!mPartCustIds.containsKey(currSales.Partner_Account__c)){
                mPartCustIds.put(currSales.Partner_Account__c, new Set<Id>());                
            }
            mPartCustIds.get(currSales.Partner_Account__c).add(currSales.Customer_Account__c);
        }
        
        for(Case cs :caseList)
        {
            if(mPartCustIds.containsKey(cs.AccountId) && !mPartCustIds.get(cs.AccountId).contains(cs.Indirect_Customer__c))
            {
                cs.addError('Add relevant Indirect Customer');
            }
            if(!mPartCustIds.containsKey(cs.AccountId))
            {
                cs.addError('No Indirect Customer is associated with the Account');
            }
        }
        
        
    } 
    
    //ESESP-2872 :Related Cases functionality for AMG Cases    
    
    public static void createRelatedRecs(map<Id,Id> mcaseRecIds)
    {
        system.debug('In createRelatedRecs Triiger Handler');
        system.debug('mcaseRecIds.keySet()//'+mcaseRecIds.keySet());
        //List<Id> lCaseIds = new List<Id>();
       // lCaseIds.addAll(mcaseRecIds.keySet());
        Id caseId = new list<Id>(mcaseRecIds.keySet())[0];
        List<CaseArticle> caseArticlesToCreate = new List<CaseArticle>();
        List<ContentDocumentLink> conDocLinkstoCreate = new List<ContentDocumentLink>();
        List<Engagement_Request__c> escalationLstToCrt = new List<Engagement_Request__c>();
        
        list<CaseArticle> caseArticles = [SELECT Id, KnowledgeArticleId, CaseId FROM CaseArticle WHERE CaseId =: mcaseRecIds.keySet()];
        system.debug('caseArticles//'+caseArticles);
        System.debug('### caseId ' + caseId);
        List<ContentDocumentLink> contentDocLinks = [SELECT ContentDocumentId, sharetype, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:caseId];
        system.debug('contentDocLinks//'+contentDocLinks);
        
        for(CaseArticle caseArt : caseArticles)
        {
            CaseArticle newArticle = new CaseArticle();
            newArticle.CaseId = mcaseRecIds.get(caseArt.CaseId);
            newArticle.KnowledgeArticleId = caseArt.KnowledgeArticleId;
            caseArticlesToCreate.add(newArticle);
        }
        system.debug('caseArticlesToCreate//'+caseArticlesToCreate);
        for(ContentDocumentLink conDoclinks : contentDocLinks)
        {
            ContentDocumentLink con = new ContentDocumentLink();
            con.ContentDocumentId = conDoclinks.ContentDocumentId;
            system.debug('mcaseRecIds.get(conDoclinks.LinkedEntityId)//'+mcaseRecIds.get(conDoclinks.LinkedEntityId));
            con.LinkedEntityId = mcaseRecIds.get(conDoclinks.LinkedEntityId);
            con.sharetype = conDoclinks.ShareType;
            conDocLinkstoCreate.add(con);
        }
        system.debug('conDocLinkstoCreate//'+conDocLinkstoCreate);
        
        
        List<Engagement_Request__c> engagementList = new List<Engagement_Request__c>();
        String engQuery = 'Select Id,';
        
        Map<String, Schema.Sobjectfield> engFieldMap = Engagement_Request__c.sObjectType.getDescribe().fields.getMap();
        system.debug('engFieldMap//'+engFieldMap);
        for(String caseFlds : engFieldMap.keySet()){
            //system.debug('caseFlds//'+caseFlds);
            Schema.DescribeFieldResult caseField = engFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable()){
                engQuery += caseFlds + ',';
            }
        }
        engQuery = engQuery.substring(0, engQuery.length()-1);
        
        system.debug('engQuery///'+engQuery);
        
        Set<Id> parentCaseIds = new Set<Id>();
        parentCaseIds = mcaseRecIds.keySet();
        engQuery += ' From Engagement_Request__c Where Case__c =: parentCaseIds';
        system.debug('engQuery222//'+engQuery);
        
        List<Engagement_Request__c> originalEngReq = Database.query(engQuery);
        system.debug('originalEngReq//'+originalEngReq);
        
        for(Engagement_Request__c eng : originalEngReq)
        {
            Engagement_Request__c newEngReq = eng.clone(false,true);
            system.debug('mcaseRecIds.get(eng.Case__c)//'+mcaseRecIds.get(eng.Case__c));
            newEngReq.Id = null;
            newEngReq.AKAM_Engagement_Request_ID__c = null;
            newEngReq.Case__c = mcaseRecIds.get(eng.Case__c);
            escalationLstToCrt.add(newEngReq);
            
        }
        system.debug('escalationLstToCrt//'+escalationLstToCrt);
        system.debug('escalationLstToCrt.size() beforeee//'+escalationLstToCrt.size());
        try{
            if(!caseArticlesToCreate.IsEmpty())
            {
                insert caseArticlesToCreate;
                system.debug('caseArticlesToCreate.size()//'+caseArticlesToCreate.size());
            }
            if(!escalationLstToCrt.IsEmpty())
            {
                insert escalationLstToCrt;
                system.debug('escalationLstToCrt.size() afterr//'+escalationLstToCrt.size());
            }
            if(!conDocLinkstoCreate.IsEmpty())
            {
                insert conDocLinkstoCreate;
                system.debug('conDocLinkstoCreate.size()//'+conDocLinkstoCreate.size());
            }
            
        }
        catch (exception e) 
        {
            System.debug('Message : ' + e.getMessage());
            System.debug('Stack Trace : ' + e.getStackTraceString());
        }
        
        
    }
    
    //ESESP-3152: Method for populating Account Owner and AMG Aligned Rep fields for AMG cases    
    
    public static void addPathFields(set<Id> accIds, List<Case> caseList)
    {
        map<Id, String> mAccIdName = new map<Id, String>();
        map<Id, List<String>> mAccIdUsrName = new map<Id, List<String>>();
        List<Account> accList = [select id, owner.name from account where id =: accIds];
        List<AccountTeamMember> accTeamList = [SELECT Id,TeamMemberRole,User.Name,User.Profile.Name,AccountId FROM AccountTeamMember WHERE AccountId = :accIds];
        
        for(AccountTeamMember accTeam: accTeamList)
        {
            if((accTeam.TeamMemberRole == 'Services - Secondary' || accTeam.TeamMemberRole == 'Services - Primary')&& (accTeam.User.Profile.Name.contains('AMG') && accTeam.User.Profile.Name != 'Support - AMG Agent $ Sales') )
            {
                if(!mAccIdUsrName.containsKey(accTeam.AccountId)){
                    mAccIdUsrName.put(accTeam.AccountId, new List<String>());                
                }
                mAccIdUsrName.get(accTeam.AccountId).add(accTeam.User.Name);
            }
        }
        
        
        for(Account acc: accList)
        {
            mAccIdName.put(acc.Id, acc.owner.name);
        }
        system.debug('mAccIdName//'+mAccIdName);
        
        for(Case cs:caseList)
        {
            if(cs.AccountId != null)
            {
                cs.Account_Owner__c = mAccIdName.get(cs.AccountId);
                if(mAccIdUsrName.get(cs.AccountId)!=null && mAccIdUsrName.get(cs.AccountId).size()==1)
                {
                    cs.AMG_Aligned_Rep__c = mAccIdUsrName.get(cs.AccountId)[0];
                }
                if(mAccIdUsrName.get(cs.AccountId)!=null && mAccIdUsrName.get(cs.AccountId).size()>1)
                {
                    cs.AMG_Aligned_Rep__c = 'Multiple AMG Users listed in Account Team';
                }
                if( mAccIdUsrName.get(cs.AccountId)==null)
                {
                    cs.AMG_Aligned_Rep__c = 'No AMG user is listed in the Account Team';
                }
            }
        }
        
    }

 
}