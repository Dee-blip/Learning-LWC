/*=====================================================================================================+
    Class name                :   SC_SiebelCaseCreation_InboundEmail 
    Author                    :   Akhila Vidapanapati
    Created                   :   24-Nov-13
    Purpose                   :   This class is called from the Siebel system for Case creation and updation requests.
    Last Modified             :   27-Nov-13
    Purpose                   :   Initial Development
 
+=====================================================================================================*/

global class SC_SiebelCaseCreation_InboundEmail implements Messaging.InboundEmailHandler {
	
    // Retrieving the Whole Email Body
    public static String emailBody;
    
    // Variabls to check whether the Incoming Email is for Create Case or Update Case
    public static boolean checkCreateCase = false;
   
    /*Standard Method for Handling Inbound Email
        @Paramter - Messaging.inboundEmail, Messaging.InboundEnvelope
        @Return Type - Messaging.InboundEmailResult
        @Called From - Automatically Called from system
        */
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, Messaging.InboundEnvelope env){
		Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
        if(environmentSetup.Active_Org__c)
        {
			Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

			// Retrieving the Whole Email Body
			emailBody = email.plainTextBody.substringBetween( '$$START$$', '$$END$$');
		
			// Checking whether the Incoming Email is for Create Case or Update Case
			checkCreateCase = emailBody.containsIgnoreCase('##CCASE##');
			
			// Retrieving the Case Fields
			string ParentCaseDet ;
			
			if(checkCreateCase)
			 ParentCaseDet = emailBody.substringBetween( '##CCASE##', '##ENDCCASE##');  
			else
			 ParentCaseDet = emailBody.substringBetween( '##UCASE##', '##ENDUCASE##');
				  
			
			// Creating List to store all Case Fields
			List<string> allCaseFieldList = new List<string>();
			
			  // 1. For AKAMCaseId Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'AKAMCASEID#', '#ENDAKAMCASEID'));   // Index 0 stores AKAMCaseId
			
			// 2. For ParentId Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'PARENTID#', '#ENDPARENTID'));            // Index 1 stores ParentId
			
			 // 3. For AccountId Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'ACCOUNTID#', '#ENDACCOUNTID'));   // Index 2 stores AccountId
				
			// 4. For RecordType Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'TYPE#', '#ENDTYPE'));         // Index 3 stores RequestType
			
			// 5. For Service Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'PRODUCTSERVICE#', '#ENDPRODUCTSERVICE'));   // Index 4 stores Service
			
			// 6. For Request Type Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'PROBLEMREQUESTTYPE#', '#ENDPROBLEMREQUESTTYPE'));         // Index 5 stores Request Type
			
			// 7. For Severity Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'SEVERITY#', '#ENDSEVERITY'));    // Index 6 stores Severity
			
			// 8. For Source Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'SOURCE#', '#ENDSOURCE'));      // Index 7 stores Source
			
			 // 9. For Status Field.    
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'STATUS#', '#ENDSTATUS'));    // Index 8 stores Status
			
			// 10. For Subject Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'TITLE#', '#ENDTITLE'));   // Index 9 stores Subject
			
			// 11. For Description Field.  
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'DESCRIPTION#', '#ENDDESCRIPTION'));    // Index 10 stores Description
			
			// 12. For Owner Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'OWNER#', '#ENDOWNER')); // Index 11 stores Owner
				
			 // 13. For Created Field. 
			allCaseFieldList.add(ParentCaseDet.substringBetween( 'CREATED#', '#ENDCREATED'));  // Index 12 stores Created
				   
		   
			try{                
			
			List<Case> caseList = new List<Case>();                                         
			
			//To check if Case with incoming AkamCaseId exists
			if(allCaseFieldList.get(0) <> null)
				caseList = [Select Id from Case where AKAM_Case_ID__c = :allCaseFieldList.get(0) limit 1];
				
			Boolean checkAKCaseId = (caseList.size() > 0) ? true : false;
			
				// Call to Case Creation Method by passing allCaseFieldList
				if(checkCreateCase && allCaseFieldList.get(12) != '_ALERT_TO_CASE' && !checkAKCaseId)
					createCase(allCaseFieldList);
				
				if(!checkCreateCase && allCaseFieldList.get(4)=='SSL Certificate Validation' && allCaseFieldList.get(5)=='Renew Existing Certificate' && checkAKCaseId && allCaseFieldList.get(12) != '_ALERT_TO_CASE') 
					updateCase(allCaseFieldList);
				
				
			} catch (Exception e)
				{
					system.debug('...In Exception...'+ e.getmessage());
					
					// Calling Send Email Method
					sendMail(null,e.getmessage(),checkCreateCase,emailBody);
					
				}
			
			result.success = true;
			return result;
		}
		return null;
    }
    
    /*Method for creating case 
    @Paramter - List<string>
    @Return Type - void 
    @Called From - handleInboundEmail Method
    */
    @future
    static public void createCase(List<string>  allCaseFieldList){
    
        // Derivation -1 ... For Record Type 
       
        //    1. Billing Support - AMG
        
        List<RecordType> caseRecTypeList = [select Id,Name from RecordType where name In ('AMG') 
                                                and SobjectType = 'Case' 
                                                and IsActive = True];
          Id selectedRecTypeId;
          selectedRecTypeId = caseRecTypeList[0].Id;
        
        /******* End of record Type Derivation ********/
            
        /*.......Variables Declaration For Below Derivations..........*/
        
        AssignmentRule assgnrule = new AssignmentRule();
        List<Account> accList = new List<Account>();                   // For Account
        
        // For setting Owner Id
        Id getOwner  = null;
      
         
        // Derivation - 2 ... For Assignment Rule - Setting the Owner Field
        assgnrule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        
        // Derivation - 3 ... For Account from Account Id
        if(allCaseFieldList.get(2) <> Null)
            accList = [select Id from Account where AKAM_Account_ID__c = :allCaseFieldList.get(2) limit 1];
        if(accList.size() <= 0)
            accList = [select Id from Account where Name =: 'Akamai Technologies - Assets' limit 1];
        
        //Derivation - 4 ... For Parent Case from Parent
        List<Case> caseList = new List<Case>(); 
        if(allCaseFieldList.get(1) <> Null)
            caseList = [Select Id from Case where AKAM_Case_ID__c = :allCaseFieldList.get(1) limit 1];
               
        
        // Derivation - 5 ... For Owner Field .. first check in User Object, then check in Group Object
        // Name field of Group ---> Label of Queue 
        if(allCaseFieldList.get(11) <> NULL){
            List<User> getUserRec   =   new List<User>();
            getUserRec = [select Id from User where IsActive = True and Alias =  :allCaseFieldList.get(11) limit 1];
            
            if(getUserRec.size() > 0 )
                getOwner = getUserRec[0].Id;
            else
            {
                List<Group> grpRec = new List<Group>();
                grpRec = [select id from Group where Name = :allCaseFieldList.get(11) and Type = 'Queue' limit 1];  
                
                getOwner = (grpRec.size() > 0) ? grpRec[0].Id : Null;
                
            }
        }
       
           
        //Derivation - 6 ... For Service field
        String service;
        if(allCaseFieldList.get(4) <> NULL && allCaseFieldList.get(4)=='CP Codes')
                service = 'CP Code Management';
            else if(allCaseFieldList.get(4) <> NULL &&  allCaseFieldList.get(4).containsIgnoreCase('User Admin'))
                service = 'User Admin';
            else if(allCaseFieldList.get(4) <> NULL && allCaseFieldList.get(4).containsIgnoreCase('SSL Certificate Validation'))
                service='SSL Certificate Validation';
            else
                service='Other Support Type';

        //Derivation - 7 ... To check if incoming Request Type is valid
        
        String ReqType = Null;
       
        List<Schema.PicklistEntry> pickValues  = Case.Request_Type__c.getDescribe().getPicklistValues();
        
        if(allCaseFieldList.get(5) <> NULL)  {  
          for( Schema.PicklistEntry pickVal : pickValues)
          {
            if(allCaseFieldList.get(5) == pickVal.getValue()) {
                
                ReqType=allCaseFieldList.get(5);
                break;
            }   
        
          } 
        }
        
        
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
            newParentCase.ParentId                              =   (caseList.size()> 0) ? caseList[0].Id : Null;
            
         // Setting Other Field Values   
            newParentCase.AKAM_Case_ID__c                       =   (allCaseFieldList.get(0) <> Null) ? allCaseFieldList.get(0) : Null;         //stores Akam Case Id
            newParentCase.Request_Type__c                       =   ReqType;                                                                     // stores Request Type
            newParentCase.Origin                                =   'Proactive';                                                              // stores Source
            newParentCase.Severity__c                           =   '3';                                                                     // stores Severity
            newParentCase.Subject                               =   allCaseFieldList.get(9);                                                               // stores Title - Subject in Case
            newParentCase.Description                           =   allCaseFieldList.get(10);                                                               // stores Description
            newParentCase.Service__c                            =   service ;                                                                        //stores Service
            
            
            // Insert The Case record
                Insert newParentCase;
            
            
          
    }
    
    
    /*Method for Updating case 
    @Paramter - List<string>
    @Return Type - void 
    @Called From - handleInboundEmail Method
    */
     @future
    static public void updateCase(List<string>  allCaseFieldList){
    
       //Fetching the Case that is to be updated        
       List<Case> caseList = new List<Case>();
       caseList = [Select Id from Case where AKAM_Case_ID__c = :allCaseFieldList.get(0) limit 1];
       caseList[0].Subject = allCaseFieldList.get(9);

       //Update the Case record 
       update caseList;
       
    }
    
    
    /*Method for Sending Email
    @Paramter - string, string, boolean, string 
    @Return Type - void 
    @Called From - handleInboundEmail Method,createCase Method
    */
     static public void sendMail(string fromAdd, string exceptionMsg,boolean checkCaseCreate_Fu,string emailBody_Fu){
    
    // Fetch Support Email Address from Custom Setting - SC_SupportEmail__c
    SC_SupportEmail__c supEmailValues = SC_SupportEmail__c.getValues('1');

    // Setting To Address
    String[] toAdd = new String[] {};

    String SerName = Null;
    if(checkCaseCreate_Fu)
        SerName = 'Email Service Name : Siebel_Email_to_Case \n '+
                    'Apex Class Name : SC_SiebelCaseCreation_InboundEmail \n '+
                    'Method Name : createCase \n';
    else
        SerName = 'Email Service Name : Siebel_Email_to_Case \n '+
                    'Apex Class Name : SC_SiebelCaseCreation_InboundEmail \n '+
                    'Method Name : updateCase \n';

    // Setting Subject
    string setSubject = 'Exception: In Siebel Bridge Email Service  ';

        toAdd.add(supEmailValues.Support_Email_AutoGen__c);
        if(checkCaseCreate_Fu)
        setSubject += 'for - Case creation';
        else
        setSubject += 'for - Case updation';
   
    // Setting Email Body
    string body = 'Exception: in Email service with below Details:\n' + 
                SerName +
                '..............Original Email Body................\n' +
                    emailBody_Fu + '\n..............End Of Original Email Body................\n\n' + '...........Exception Details...............\n' +
                    exceptionMsg;
      
          
      // Sending Email
      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = setSubject;
        mail.plainTextBody = body;
    Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 

    }
    
    
}