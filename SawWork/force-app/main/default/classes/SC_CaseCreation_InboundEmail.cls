/*=====================================================================================================+
    Class name                :   SC_CaseCreation_InboundEmail 
    Author                    :   Himanshu Kar
    Created                   :   04-Jul-13
    Purpose                   :   This class is called from Sibel system and is used to Create Case and related Tasks. It is Related to below reqs.
                                        1. AutoGen Cases
                                        2. Alert Case Maker
                                        3. NIE
    Last Modified   Developer   Purpose            
    =============   =========   =======
    04-Dec-13       Himanshu    Initial Development
    04-Feb-14       Himanshu    1. Handled Duplicate COB and TCR Cases(CR#2501337,2537886)
                            	  2. Added Geography Calculation for TCR cases(CR#2499087)
                                3. Handled exception for case creation(CR#2503677)
                                4. Modified Select Query for Record Type and for PO Type 
    22-May-14       Himanshu    1. Added Logic for NIE for Contact and AkamCreatedBy Derivation(3.42)
    11-Mar-2016     Sonia       CR# 3320211: GDRAT-to-DGRAT reorg: AMG functionality fixes - Replaced all Geography checks to use the custom setting
+=====================================================================================================*/

global class SC_CaseCreation_InboundEmail implements Messaging.InboundEmailHandler {

    // Retrieving the Whole Email Body
    public static String emailBody;
    
    // Checking whether the Incoming Email from AutoGen or Not
    public static boolean checkAutoGen = false;
    
    // Checking whether the Incoming Email from NIE or Not.
    public static boolean checkNIE = false;
    
    public static SC_DGRAT_Reorg_Mapping__c DGRATMapping =  SC_DGRAT_Reorg_Mapping__c.getInstance();    

     /*Standard Method for Handling Inbound Email
        @Paramter - Messaging.inboundEmail, Messaging.InboundEnvelope
        @Return Type - Messaging.InboundEmailResult
        @Called From - Automatically Called from system
        */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
        
        // Setting Up the Env variable(For DR)
        Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
        
        // If Org is Active, then process the Logic(For DR)
        if(environmentSetup.Active_Org__c)
        {
            Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

            // Retrieving the Whole Email Body
            emailBody = email.plainTextBody.substringBetween( '$$START$$', '$$END$$');
        
            // Retrieving the UseCaseType from Subject Part of Email
            String UseCaseType = email.subject.substringBetween( 'UseCase#', '#EndUseCase');

              // Checking whether the Incoming Email from AutoGen or Not. If it is Autogen the flag = true , else False.
            checkAutoGen = email.subject.containsIgnoreCase('AutoGen');
            
            // Checking whether the Incoming Email from NIE or Not. If it is Autogen the flag = true , else False.
            checkNIE = email.subject.containsIgnoreCase('NIE');
            
            
            // Retrieving the Case Fields
            string ParentCaseDet ;
             if(checkAutoGen)
                ParentCaseDet = emailBody.substringBetween( '##Case##', '##EndCase##');  
            else
                ParentCaseDet = emailBody.substringBetween( '##CASE##', '##ENDCASE##');  
            
            // Creating List to store all Case Fields
            List<string> allCaseFieldList = new List<string>();
            
              // 1. For Account Ext Id Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'AccountId#', '#EndAccountId'));            // Index 0 stores Account Ext Id
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'AKAMACCOUNTID#', '#ENDAKAMACCOUNTID'));   // Index 0 stores Account Ext Id
            
            
            // 2. For Type Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Type#', '#EndType'));                   // Index 1 stores Type
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'SUBTYPE#', '#ENDSUBTYPE'));            // Index 1 stores Type
            
             // 3. For Case Product Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'CaseProduct#', '#EndCaseProduct'));    // Index 2 stores Product
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'CASEPRODUCT#', '#ENDCASEPRODUCT'));   // Index 2 stores Product
                
            // 4. For Service Field. 
            if(checkAutoGen && UseCaseType <> Null && !(UseCaseType.equalsIgnoreCase('COB')))
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Service#', '#EndService'));          // Index 3 stores Service
            
            else if(checkAutoGen && UseCaseType <> Null && UseCaseType.equalsIgnoreCase('COB'))
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Service#', '#EndProduct/Service'));
            
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'SERVICE#', '#ENDSERVICE'));         // Index 3 stores Service
            
            // 5. For Request Type Field. 
            if(checkAutoGen)    
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'RequestType#', '#EndRequestType'));    // Index 4 stores Request Type
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'REQUESTTYPE#', '#ENDREQUESTTYPE'));   // Index 4 stores Request Type
            
            // 6. For Problem Field. 
            if(checkAutoGen)        
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Problem#', '#EndProblem'));          // Index 5 stores Problem
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'PROBLEM#', '#ENDPROBLEM'));         // Index 5 stores Problem
            
            // 7. For Case Origin Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Source#', '#EndSource'));             // Index 6 stores Source / Origin
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'CASEORIGIN#', '#ENDCASEORIGIN'));    // Index 6 stores Source / Origin
            
            // 8. For Severity Field. 
            if(checkAutoGen)        
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Severity#', '#EndSeverity'));       // Index 7 stores Severity
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'SEVERITY#', '#ENDSEVERITY'));      // Index 7 stores Severity
            
             // 9. For Status Field.    
            allCaseFieldList.add(ParentCaseDet.substringBetween( 'Status#', '#EndStatus'));    // Index 8 stores Status
            
            // 10. For Do not show in Portal Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Do not show in Portal#', '#EndDo not show in Portal'));  // Index 9 stores Do not show in Portal
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'DONOTSHOWINPORTAL#', '#ENDDONOTSHOWINPORTAL'));   // Index 9 stores Do not show in Portal
            
            
            // 11. For Original Contract Id Field.  
            allCaseFieldList.add(ParentCaseDet.substringBetween( 'Original Contract Id#', '#EndOriginal Contract Id'));    // Index 10 stores Original Contract Id
            
            // 12. For Case Subject Field. 
            if(checkAutoGen)
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Title#', '#EndTitle'));     // Index 11 stores Title / Subject
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'SUBJECT#', '#ENDSUBJECT')); // Index 11 stores Title / Subject
                
             // 13. For Case Description Field. 
            if(checkAutoGen)    
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Description#', '#EndDescription'));   // Index 12 stores Description
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'DESCRIPTION#', '#ENDDESCRIPTION'));  // Index 12 stores Description
            
            // 14. For Owner Field. 
            if(checkAutoGen)    
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'Owner#', '#EndOwner'));           // Index 13 stores Owner Name
            else
                allCaseFieldList.add(ParentCaseDet.substringBetween( 'OWNER#', '#ENDOWNER'));          // Index 13 stores Owner Name
                
            // 15. For RecordType Field.   
            allCaseFieldList.add(ParentCaseDet.substringBetween( 'RECORDTYPE#', '#ENDRECORDTYPE'));     // Index 14 stores RecordType
            
            //16. For Portal Login Field
            allCaseFieldList.add(ParentCaseDet.substringBetween( 'PORTALLOGIN#', '#ENDPORTALLOGIN'));  // Index 15 stores Portal Login
            
            //17. For From Email address
            allCaseFieldList.add(email.fromAddress);            // Index 16 stores Email Address
            
           
            try{                
                // Call to Case Creation Method by passing allCaseFieldList and UseCaseType as parameter
                createCase(allCaseFieldList, UseCaseType, checkAutoGen, checkNIE, emailBody);
                
            } catch (Exception e)
                {
                    system.debug('...In Exception...'+ e.getmessage());
                    
                    // Calling Send Email Method
                    sendMail(false,null,e.getmessage(), checkAutoGen, checkNIE,emailBody);
                    
                }
            
            result.success = true;
            return result;
        }
        return null;
    }
    
    /*Method for creating case 
    @Paramter - List<string>, string
    @Return Type - Id 
    @Called From - handleInboundEmail Method
    */
    @future
    static public void createCase(List<string>  allCaseFieldList, string UseCaseType, boolean checkAutoGen_Fu, 
                            boolean checkNIE_Fu, string emailBody_Fu){
    
         /*.......Variables Declaration For Below Derivations..........*/
        AssignmentRule assgnrule                = new AssignmentRule();
        List<Account> accList                           = new List<Account>();                   // For Account
        List<Merge_Contract_Header__c> contractRec      = new List<Merge_Contract_Header__c>(); // For Contract
        List<EB_AccountProductMap__c> prodRec           = new List<EB_AccountProductMap__c>();  // For Product
        List<Case> caseList                             = new List<Case>();                 // For Case
        
        // For setting Owner Id
        Id getOwner  = null;
        
        // For setting RecordType Id
        Id selectedRecTypeId;
        
        // For Setting Service Field value for AMG record tYpe
        string setServiceval = null;
        
        // For Setting RequestType Field value for AMG record tYpe
        string setReqTypeval = null;
        
        // For Checking Duplicate Case
        boolean isExistDuplicate = false;
        
        // ******** Derivation - 1 ... For Account from external Id  ***********
        if(allCaseFieldList.get(0) <> Null && allCaseFieldList.get(0) <> '' )
            accList = [select Id,Geography_Formula__c from Account where 
                    AKAM_Account_ID__c = :allCaseFieldList.get(0) limit 1];
        
        // ******** Derivation -2 ... For Record Type ******** 
        /*
            // For Autogen
            1. For PO           -   Billing(Index 1)
            2. For COB      -   AMG(Index 0)
            3. For Rest         -   Professional Service (Default)(Index 2)
            4. For Technical  (Index 3)
            
            // For Other Cases
            1. Default - Technical
            2. Other can be anything
        */
        // Map for storing RecordType Name - Id
        Map<string, RecordType > caseRecTypeMap = new Map<string, RecordType >();
        
       for(RecordType eachRecType : [select Name,Id from RecordType where SobjectType = 'Case' 
                                                and IsActive = True order by Name]){
              caseRecTypeMap.put(eachRecType.Name,eachRecType) ;                                 
      		
       }
          
        
        // If it is Autogen Case, then derive the corresponding Record Type , otherwise write Query for Rec Type derivation.
        // For Autogen TCR UseCaseType, if Account Geography=APJ/EMEA then Recordtype will be AMG else PS.
        if(checkAutoGen_Fu){
        
          if (UseCaseType <> Null && UseCaseType.equalsIgnoreCase('PO'))
            selectedRecTypeId = caseRecTypeMap.get('Billing').Id;
          else if (UseCaseType <> Null && (UseCaseType.equalsIgnoreCase('COB') || UseCaseType.equalsIgnoreCase('QBR')) )
            selectedRecTypeId = caseRecTypeMap.get('AMG').Id;
          else
          {
            if(accList.size() > 0 && accList[0].Geography_Formula__c <> NULL && UseCaseType.equalsIgnoreCase('TCR') && 
             (DGRATMapping.Geography_APJ__c.containsIgnoreCase(accList[0].Geography_Formula__c) || DGRATMapping.Geography_EMEA__c.containsIgnoreCase(accList[0].Geography_Formula__c)))                
                selectedRecTypeId = caseRecTypeMap.get('AMG').Id;
            else
                selectedRecTypeId = caseRecTypeMap.get('Professional Services').Id;
          }
        }
        else
        {
            selectedRecTypeId = (allCaseFieldList.get(14) <> Null && caseRecTypeMap.get(allCaseFieldList.get(14)) <> Null) ?  
                            caseRecTypeMap.get(allCaseFieldList.get(14)).Id : 
                            caseRecTypeMap.get('Technical').Id;
            
        }
        /******* End of record Type Derivation ********/
            
            
        // ******** Derivation - 3 ... For Assignment Rule - Setting the Owner Field ******** 
        assgnrule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        
             
        // ******** Derivation - 4 ... For Contract from Contract Id ******** 
        if(allCaseFieldList.get(10) <> Null && allCaseFieldList.get(10) <> '')
            contractRec = [select id,Account_Name__c from Merge_Contract_Header__c where Original_Contract_Id__c = :allCaseFieldList.get(10) limit 1];
        
        // ******** Derivation - 5 ... For Product(Case Product) ******** 
        if (allCaseFieldList.get(2) <> null && allCaseFieldList.get(2) <> ''){
            prodRec =   [select Id from EB_AccountProductMap__c where EB_Product__c = : allCaseFieldList.get(2) and EB_MarkedForDeletion__c = false limit 1];
        }
        
        // ******** Derivation - 6 ... For Owner Field .. 1st check in User Object, then check in Group Object ******** 
        // Name field of Group ---> Label of Queue 
        if(allCaseFieldList.get(13) <> NULL && allCaseFieldList.get(13) <> ''){
            List<User> getUserRec   =   new List<User>();
            getUserRec = [select Id from User where Alias =  :allCaseFieldList.get(13) limit 1];
            
            if(getUserRec.size() > 0 )
                getOwner = getUserRec[0].Id;
            else
            {
                List<Group> grpRec = new List<Group>();
                grpRec = [select id from Group where Name = :allCaseFieldList.get(13) and Type = 'Queue' limit 1];  
                
                getOwner = (grpRec.size() > 0) ? grpRec[0].Id : Null;
                
            }
        }
        
         // ******** Derivation - 7... For Akam Created By based on FromAddress  ******** 
        List<Contact> cntRec = new List<Contact>();
        if(allCaseFieldList.get(16) <> NULL && allCaseFieldList.get(16) <> ''){
            cntRec = [Select Id, login__C from Contact where Email = :allCaseFieldList.get(16) limit 1];
        }
        
      // ********  Derivation - 8...  For Contact Id based on incoming PortalLogin ******** 
      List<Contact> cntIdRec = new List<Contact>();
      if(allCaseFieldList.get(15) <> NULL && allCaseFieldList.get(15) <> ''){
        cntIdRec = [Select Id,login__C,AccountId from Contact where login__C = :allCaseFieldList.get(15) and 
                  No_Longer_with_Company__c = false limit 1];
      }
        
     // ******** Derivation - 9...For setting Service and request Type
     // If UseCase = TCR and recordType = AMG then set Service and ReqType Value
     if(selectedRecTypeId == caseRecTypeMap.get('AMG').Id && UseCaseType <> Null && UseCaseType.equalsIgnoreCase('TCR')){
     
            setServiceval = SC_Serv_ReqTyp_value__c.getValues('AMG').ServiceVal__c;
            setReqTypeval = SC_Serv_ReqTyp_value__c.getValues('AMG').RequestTypeVal__c;
     }
     else
     {
            setServiceval = (allCaseFieldList.get(3) <> Null) ? allCaseFieldList.get(3) : Null;
            setReqTypeval = (allCaseFieldList.get(4) <> Null) ? allCaseFieldList.get(4) : Null;
     }
     
     /******* Checking Duplicate Cases **************/
      
      // UseCase-1 : To stop duplicate Case Creation for COB cases
      if(contractRec.size() > 0 && UseCaseType <> Null && UseCaseType.equalsIgnoreCase('COB')){
        
        caseList = [select Id from Case where Contract__c = :contractRec[0].Id and
                Origin          = 'Proactive' and
                Request_Type__c     = 'Customer Onboarding' and
                RecordTypeId        = :caseRecTypeMap.get('AMG').Id and
                AKAM_Created_By__c  = 'CRMOPS' and
                Service__c      = 'Accounts Audits'
                limit 1];
                
        isExistDuplicate = (caseList.size() > 0) ? True : False;
      }
      
      // UseCase-2 : To stop duplicate Case Creation for TCR cases
      else if(contractRec.size() > 0 && UseCaseType <> Null && UseCaseType.equalsIgnoreCase('TCR')){
        
        string getTCR_RecTypeVal    = null;
        string getTCR_SerVal        = null;
        string getTCR_ReqTypeVal    = null;
        
        // Condition-1 for TCR cases which falls Geography Calculation
        If(selectedRecTypeId == caseRecTypeMap.get('AMG').Id){
        
            getTCR_RecTypeVal = caseRecTypeMap.get('AMG').Id;
            getTCR_SerVal   = setServiceval;
            getTCR_ReqTypeVal = setReqTypeval;
        }
        // Condition-2 for TCR Cases with Service = SMP (Non-Security)
        else if(selectedRecTypeId == caseRecTypeMap.get('Professional Services').Id && setServiceval == 'SMP (Non-Security)'){
        
            getTCR_RecTypeVal = caseRecTypeMap.get('Professional Services').Id;
            getTCR_SerVal   = SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').ServiceVal__c;
            getTCR_ReqTypeVal = SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').RequestTypeVal__c;
        }
        // Condition-3 for TCR Cases with Service = SMP (Security)
        else if(selectedRecTypeId == caseRecTypeMap.get('Professional Services').Id && setServiceval == 'SMP (Security)'){
        
            getTCR_RecTypeVal = caseRecTypeMap.get('Professional Services').Id;
            getTCR_SerVal   = SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').ServiceVal__c;
            getTCR_ReqTypeVal = SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').RequestTypeVal__c;
        }
        
        // Query on Case by passing below parameters
        if(getTCR_RecTypeVal <> null && getTCR_SerVal <> null && getTCR_ReqTypeVal <> null){
        
            caseList = [select Id,createdDate from Case where Contract__c = :contractRec[0].Id and
                    RecordTypeId = :getTCR_RecTypeVal and
                    Service__c = :getTCR_SerVal and
                    Request_Type__c = :getTCR_ReqTypeVal and
                    AKAM_Created_By__c = 'CRMOPS'
                    Order by createdDate desc
                        limit 1];
                        
            if(caseList.size() > 0 && caseList[0].createdDate.date() == system.today())
                isExistDuplicate = true;
        }
      
      } // End of Usecase-2
     
        // Create a Case 
        Case newParentCase = new Case();
        
            // Setting Derivation Fields
            newParentCase.RecordTypeId                          =   selectedRecTypeId;                                                                      // stores RecordType
            
            // Setting Assignment Rule Only If Owner is Null.
            if(getOwner == Null)        
                newParentCase.setOptions(dmo);
            else
                newParentCase.OwnerId                           =   getOwner;                                                                   // Stores Owner Field
                
            newParentCase.AccountId                             =   (accList.size() > 0) ? accList[0].Id : Null;                                        // stores AccountId
            newParentCase.Contract__c                           =   (contractRec.size() > 0) ? contractRec[0].Id : Null;                        // stores Original Contract Id
            newParentCase.Case_Product__c                       =   (prodRec.size() > 0) ? prodRec[0].Id : Null;                            // stores Product
            
         // Setting Other Field Values   
            newParentCase.Sub_Type__c                           =   (allCaseFieldList.get(1) <> Null) ? allCaseFieldList.get(1) : Null;         // stores Type ????????
            newParentCase.Service__c                            =    setServiceval  ;      // stores Service
            newParentCase.Request_Type__c                       =    setReqTypeval  ;      // stores Request Type
            //newParentCase.Problem__c                            =   (allCaseFieldList.get(5) <> Null) ? allCaseFieldList.get(5) : Null;         // stores Problem
            newParentCase.Origin                                =   (allCaseFieldList.get(6) <> Null) ? allCaseFieldList.get(6) : Null;          // stores Source
            newParentCase.Severity__c                           =   (allCaseFieldList.get(7) <> Null) ? allCaseFieldList.get(7) : Null;         // stores Severity
            newParentCase.Do_Not_Show_in_Portal__c              =   (allCaseFieldList.get(9) <> Null && allCaseFieldList.get(9).equalsIgnoreCase('Y')) ? True : False;           // stores Do not show in Portal
            newParentCase.Subject                               =   allCaseFieldList.get(11);                                                               // stores Title - Subject in Case
            newParentCase.Description                           =   allCaseFieldList.get(12);                                                               // stores Description
             
             // Setting AKAM Created By     
            newParentCase.AKAM_Created_By__c             =   (cntRec.size() > 0) ? cntRec[0].login__C : Null;        //stores Akam Created By
            newParentCase.AKAM_Created_Date__c           =   system.today();
            newParentCase.AKAM_System__c                 =   'FORCE';
            
            //If UseCaseType = PO, then derive the Account Id from Contract
            if(UseCaseType <> Null && UseCaseType.equalsIgnoreCase('PO') && contractRec.size() > 0){
            	newParentCase.AccountId		= contractRec[0].Account_Name__c;
            }
            
            //Specific for NIE users
            if(checkNIE_Fu)
            {  
                newParentCase.Is_Incoming_NIE__c      = True;
                
                // Setting Akam Created by: If Contact Present then Populate Login field Else populate Incoming From Add
                newParentCase.AKAM_Created_By__c = (cntIdRec.size() > 0) ? cntIdRec[0].login__C : allCaseFieldList.get(16);
                
                // Setting Contact Id: 
                newParentCase.ContactId = (cntIdRec.size() > 0 && newParentCase.AccountId <> null && newParentCase.AccountId == cntIdRec[0].AccountId) ?
                					cntIdRec[0].Id : Null;
                
            } 
            
            
            // Check any case is exist for COB or TCR Cases. If No then Create Case else do not create case.
            if(isExistDuplicate == false){
                
                try{
                        // Insert The Case record
                        Insert newParentCase;
                        
                        // If the UseCaseType = Customer On Boarding, then only create Task
                        if(newParentCase.Id <> Null && UseCaseType <> Null && UseCaseType.contains('COB')){
        
                            // Call the Method for Task Creation
                            createTask(allCaseFieldList.get(10), newParentCase.Id);   
                        }
                }
                catch(exception e){
                    
                        // Calling Send Email Method
                        sendMail(false,null,e.getmessage(), checkAutoGen_Fu, checkNIE_Fu,emailBody_Fu);
                }
            }
                      
        
    }
    
    /*Method for creating Task
    @Paramter - string , Id
    @Return Type - void 
    @Called From - handleInboundEmail Method
    */
    static public void createTask(string ContractId, Id caseId){
    
        // Fetch the Data from Custom Setting - AutoGencase - Activity
        List<SC_AutoGencase_Activity__c>  allActivityValues = SC_AutoGencase_Activity__c.getall().values();
        
        // Fetch Default Task Owner from Custom Setting - SC_SupportEmail__c
        string getOwnerAlias = SC_SupportEmail__c.getValues('1').Default_Task_Owner__c;
        
        // Fetch User Id from User Alias
        List<User> userRec = new  List<User>();
        userRec = [select Id from user where alias = :getOwnerAlias limit 1];
        
        // Derivation -for getting Revision Effective Start Date from Contract Id
        List<Merge_Contract_Header__c> contractRec = new List<Merge_Contract_Header__c>();
        if(ContractId <> null && ContractId != '')
        contractRec = [select Revision_Effective_Start_Date__c from Merge_Contract_Header__c where Contract_Id__c = :ContractId];
        
        // Derivation For Record Type
        List<RecordType> taskRecType = [select Id,Name from RecordType where name = 'Service Activity'
                                                and SobjectType = 'Task' 
                                                and IsActive = True limit 1];
        
        
        // List of Task which are going to create
        List<Task> allTaskInsertList = new List<Task>();
        
        // Task record used inside Loop for each Record
        Task newtask;
        
        // Variable to store Activity Date
        Date setActdate;
        
        // Loop for each Task Record from Custom setting
        for(integer i =0 ; i < allActivityValues.size() ; i ++){
        
            // Derivation for Activity Date
            setActdate      =   system.today();
            if(contractRec.size() > 0){
                setActdate  =   (allActivityValues[i].Activity_Due_date__c == NULL) ? contractRec[0].Revision_Effective_Start_Date__c : 
                                    system.today().addDays( Integer.valueOf(allActivityValues[i].Activity_Due_date__c));
            }
            else
            {
                setActdate  =   (allActivityValues[i].Activity_Due_date__c == NULL) ? system.today() : 
                                system.today().addDays( Integer.valueOf(allActivityValues[i].Activity_Due_date__c));
            }
            
            newtask = new Task();
            newtask.Subject                  =   allActivityValues[i].Activity_Name__c;
            newtask.Description              =   allActivityValues[i].Activity_Details__c;
            newtask.ActivityDate             =   setActdate;
                                          
            newtask.Type__c                  =   'Task';
            newtask.Status                   =   'Not Started';
            newtask.WhatId                   =   caseId;
            newtask.OwnerId                  =   userRec[0].Id;
            newtask.RecordTypeId             =   taskRecType[0].Id;
            
            allTaskInsertList.add(newtask);
            
        }
        
        // Create Task
        Insert allTaskInsertList;
    
    }
    
    /*Method for Sending Email
    @Paramter - boolean, string , string
    @Return Type - void 
    @Called From - handleInboundEmail Method,createCase Method
    */
    static public void sendMail(boolean isNIEContctNtExst, string fromAdd, string exceptionMsg, boolean checkAutoGen_Fu,
                         boolean checkNIE_Fu, string emailBody_Fu){
    
    // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
    SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');

    // Setting To Address
    String[] toAdd = new String[] {};

    String SerName = 'Email Service Name : SC_EmailService_CaseCreation \n '+
                    'Apex Class Name : SC_CaseCreation_InboundEmail \n '+
                    'Method Name : createCase \n';

    // Setting Subject
    string setSubject = 'Exception: In Email Service For - ';

    // If Autogen, then Pick support Add for Autogen Else Pick Support Address for AMS
    if(checkAutoGen_Fu){   
        toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        setSubject += 'AutoGen Cases';
      }
    else if(checkNIE_Fu){
        toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        setSubject += 'NIE Cases';
    }
    else
    {
        toAdd.add(supEmailValues.Support_Email_AMS__c); 
        setSubject += 'Alert Case Maker Cases';
    }

    // Setting Email Body
    string body = 'Exception: in Email service with below Details:\n' + 
                SerName +
                '..............Original Email Body................\n' +
                    emailBody_Fu + '\n..............End Of Original Email Body................\n\n' + '...........Exception Details...............\n' +
                    exceptionMsg;
      
      if(checkNIE_Fu == True && isNIEContctNtExst == True){
      
        toAdd.add(fromAdd);
        body = 'Error: The Associated Contact does not Exist in Salesforce for the given Portal Login.\n' +
             '..............Original Email Body................\n' + emailBody_Fu;
      
      }
      
      // Sending Email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = setSubject;
        mail.plainTextBody = body;
    Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 

    }
    
    
}