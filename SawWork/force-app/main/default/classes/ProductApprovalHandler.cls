global class ProductApprovalHandler {


	
	global class ProductApprovalStatus {

		webservice Boolean isLockable;

		webservice Boolean isDraftable;

		webservice String statusText;

	}





	/**

	The return codes (type is String, not Integers) are:

	-1 cannot find opportunity

	-2 cannot find workflow

	-3 Other Salesforce error



	Any other value is a valid Product Approval id.

	If sales force finds a existing approval for the provided wf_id and opp_id, 

	it returns the id of that record, otherwise it creates a new record and returns that.

	

	**/

	webservice static String initiateApproval(String workflow_id, String opportunity_id){

		

		return initiateApprovalWithOrderInfo(workflow_id,opportunity_id,'','muser','');

		

	}



	/**

		

		the statusText can be

		"INVALID" - did not find the record

		"PENDING-TECHNICAL" - Record was created and waiting for TSP to come and fill in the questionaire.

		"PENDING-APPROVAL" - TSP has filled the questionaire submitted for approval

		"APPROVED" - Approved

		"REJECTED" - rejected

		The flags are isLockable and isDraftable which will be set based on the status for each workflow

	

	*/



	webservice static ProductApprovalStatus getApprovalStatusById(String approval_id) {

		

		//find existing approval

		Product_Approvals__c currentApproval;

		

		for(Product_Approvals__c pa:[select id, status__c,Approval_Workflow__c,Approval_Workflow__r.isDraftable__c,Approval_Workflow__r.isLockable__c from Product_Approvals__c where id = :approval_id])

    		currentApproval = pa;

		

			ProductApprovalStatus status = new ProductApprovalStatus();

		

		if(currentApproval == null) {

			

			status.isDraftable = false;

			status.isLockable = false;

			status.statusText = 'INVALID';

			

		} else if(currentApproval.status__c == 'APPROVED') {

			

			status.isDraftable = true;

			status.isLockable  = true;

			status.statusText = currentApproval.status__c;

			

		}else{

			

			status.isDraftable = currentApproval.Approval_Workflow__r.isDraftable__c;

			status.isLockable  = currentApproval.Approval_Workflow__r.isLockable__c;

			status.statusText = currentApproval.status__c;

		}

		

		return status; 

		

	}



	webservice static ProductApprovalStatus getApprovalStatus(String workflow_id, String opportunity_id, String OrderType){

	

		//find existing approval

		Product_Approvals__c currentApproval;
		ProductApprovalCS__c pals= ProductApprovalCS__c.getInstance('LegacyStreamingWF');
		if(workflow_id==pals.Value__c && OrderType!='New service order' && OrderType!='Trial service order' && OrderType!='Beta Service Order')
            workflow_id='F-PAR-0100';

		for(Product_Approvals__c pa:[select id, status__c,Approval_Workflow__c,Approval_Workflow__r.isDraftable__c,Approval_Workflow__r.isLockable__c  from Product_Approvals__c where Approval_Workflow__r.AKAM_Workflow_ID__c = :workflow_id and AKAM_Opportunity_ID__c = :opportunity_id])

    		currentApproval = pa;

		

			ProductApprovalStatus status = new ProductApprovalStatus();

		

		if(currentApproval == null){

			

			status.isDraftable = false;

			status.isLockable = false;

			status.statusText = 'INVALID';

			

		}else if(currentApproval.status__c == 'APPROVED'){

			

			status.isDraftable = true;

			status.isLockable  = true;

			status.statusText = currentApproval.status__c;

				

		}else{

			

			status.isDraftable = currentApproval.Approval_Workflow__r.isDraftable__c;

			status.isLockable  = currentApproval.Approval_Workflow__r.isLockable__c;

			status.statusText = currentApproval.status__c;

		}

		

		return status;

	

	}

	



/* Test Classses */





   // Create Account reuse function

 	private static Account CreateAccount(String pAccName)

	{

		/*Account newAccount = new Account();

		

		newAccount.Name = pAccName;*/
		Account newAccount = utilTestClass.CreateAccount(pAccName);

		

		Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
		

		

		// PDRA contd 2 fix...

			// Acc Reassignment Rule for acc.Owner

	    	Profile pr = [select id from profile where name='Sales Operations'][0];

			UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];

			User accOwner; 

			accOwner = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );

			insert accOwner;		

			// Create a rule

			//Account_Reassignment_Rule__c rule = createAccountReassignmentRule(accOwner, role.Name);			

			//insert rule;

		

		// ALI KM

		newAccount.OwnerId = accOwner.Id;

				

		//newAccount.BillingCountry = 'India';

		

		return newAccount;

	} 

	// Create Opportunity reuse function

	/*private static Opportunity CreateOpportunity(String stageName)

	{

		Opportunity opp = new Opportunity();

        opp.Name = '__Test Oppty';

        opp.StageName = '1-Create';

        

        return opp;

	} */

	// Create Opportunity Refresh function

	private static Opportunity RefreshOpportunity(String OppId)

	{

		return [select	Id, 

        				AKAM_Opportunity_ID__c

				from Opportunity where Id=:OppId];

        	 

	} 

  private static String createProductApproval(){

  	

  		Account acc = CreateAccount('__Test Account');

        insert acc;

        //Opportunity opp = CreateOpportunity('1-Create');
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty', '1-Create');

        opp.AccountId = acc.Id;

        opp.CloseDate = Date.today().addDays(30);

        //opp.AKAM_Opportunity_ID__c = 'F-'

        

  		insert opp;

  		

  		//OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);

  		

  		Order_Approval__c newOrder = new Order_Approval__c();

		newOrder.Associated_Opportunity__c = opp.id;

		newOrder.CCG_Status__c='Open';

		insert newOrder;

  		

  		Order_Approval__c oa_r = [select	Id, 

        				AKAM_Opportunity_ID__c

				from Order_Approval__c where Id=:newOrder.id];

  		

  		system.debug(oa_r.AKAM_Opportunity_ID__c);

  		

  		Opportunity opp_r = RefreshOpportunity(opp.id);

  		system.debug(opp_r.AKAM_Opportunity_ID__c);

  		

  		

  		String paId = ProductApprovalHandler.initiateApproval( 'F-PA-001',opp_r.AKAM_Opportunity_ID__c);

  		

  		

  		//find existing approval

		Product_Approvals__c currentApproval;

		

		for(Product_Approvals__c pa:[select id, Survey_Taken__c from Product_Approvals__c where id = :paId])

    		currentApproval = pa;

		

		if(currentApproval != null) {

  		//currentApproval.Survey_Taken__c = surveyTakerId;

  	//	update currentApproval;

  	//	return 'true';

  	

  		ProductApprovalHandler.approvalOverride(paId);

		}

  		return paId;

  		

  }





	private static TestMethod void testInitiateApproval(){

		
		User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
		System.runAs(thisUser) {
		String paId = createProductApproval();

		
		System.debug(paId);
		System.assert(paId <> '-1');

		

		ProductApprovalStatus status = getApprovalStatusById(paId);

		ProductApprovalStatus status_b = getApprovalStatusById('abc');

		}

	/*	Product_Approvals__c currentApproval = new Product_Approvals__c();		

		for(Product_Approvals__c pa:[select id, Status__c,Last_Reminder_Date__c from Product_Approvals__c where id=:paid])

    		currentApproval = pa;

    	

    	currentApproval.Last_Reminder_Date__c = system.today().addDays(-5);

    		

		invokeTSPReminderEmail();*/

	}


	private static TestMethod void testInitiateApproval2(){
		invokeTSPReminderEmail();
	}





	/**

	The return codes (type is String, not Integers) are:

	-1 cannot find opportunity

	-2 cannot find workflow

	-3 Other Salesforce error

	-4 Cannot find Order Approval.

	-5 cannot find user



	Any other value is a valid Product Approval id.

	If sales force finds a existing approval for the provided wf_id and opp_id, 

	it returns the id of that record, otherwise it creates a new record and returns that.

	

	**/

    webservice static String initiateApprovalWithOrderInfo(String workflow_id, String opportunity_id, String mom_order_id, String created_by_alias,String OrderType){

		

		//find existing approval

		Product_Approvals__c currentApproval;

		workflow_id=workflow_id;
		
      
       ProductApprovalCS__c pals= ProductApprovalCS__c.getInstance('LegacyStreamingWF');
		if(workflow_id==pals.Value__c && OrderType!='New service order' && OrderType!='Trial service order' && OrderType!='Beta Service Order')
            workflow_id='F-PAR-0100';
		for(Product_Approvals__c pa:[select id, Status__c,Approval_Workflow__c from Product_Approvals__c where Approval_Workflow__r.AKAM_Workflow_ID__c = :workflow_id and AKAM_Opportunity_ID__c = :opportunity_id])

    		currentApproval = pa;

		

		if(currentApproval != null){

			return currentApproval.id;

		}

		

		

		//Create a new Approval

		

		Product_Approvals__c newApproval = new Product_Approvals__c();

		

		

		//newApproval.AKAM_Workflow_ID__c = workflow_id;

		

		//Find user first.

		User creator;

		for(User us:[Select alias,name,id from User where alias = :created_by_alias]) {

			creator = us;

		}

		

		if(creator == null){

			return '-5'; // Cannot find a user by this name

		}else

		{

			newApproval.creator__c = creator.id;
		}

		

		//Set Order Id

		newApproval.order_id__c = mom_order_id;

		

		

		//Find Order Approval

		

		Order_Approval__c orderApproval;

		for(Order_Approval__c oa: [select id from Order_Approval__c where AKAM_Opportunity_ID__c = :opportunity_id])

			orderApproval = oa;

		

		if(orderApproval == null){

			return '-4'; //cannot find order approval

		}else{

			newApproval.Order_Approval__c = orderApproval.id;

		}

		

		

		//Find Approval Workflow;

		//Find Survey To Take

		Approval_Workflow__c workflow;

		for(Approval_Workflow__c wf:[select id, Survey__c, name,primary_contact__c from Approval_Workflow__c where AKAM_Workflow_ID__c = :workflow_id])

			workflow = wf;

		

		if(workflow == null){

			return '-2'; //cannot find workflow

		}else {

			newApproval.Approval_Workflow__c = workflow.id;

			newApproval.Survey__c = workflow.Survey__c;

		}

		

		

		/*

		//Find Survey To Take

		Survey__c survey;

		for(Survey__c sy:[select id from Survey__c where AKAM_Workflow_ID__c = :workflow_id])

			survey = sy;

		

		if(survey == null){

			return '-2'; //cannot find survey

		}else {

			newApproval.Survey__c = survey.id;

		}

		*/

		

		

		//Set TSP to trigger email.

		//Find account_id

		Opportunity opp;

		for(Opportunity o:[select id,AccountId,OwnerId,Name from Opportunity where AKAM_Opportunity_ID__c= :opportunity_id ])

			opp = o;

			

			

		if(opp == null){

			return '-1';

		}	

		

		newApproval.Opportunity__c = opp.id;

		newApproval.Opportunity_Owner__c = opp.OwnerId;

		newApproval.Account__c=opp.AccountId;

		//who is the primary contact ?

		String primary = workflow.primary_contact__c;

		

		

		

		if (primary == 'Opportunity Owner') {

			

			newApproval.User_Technical__c = opp.OwnerId;

						
		}else if (primary == 'Momentum Order Creator') {

			

			newApproval.User_Technical__c = creator.id;

			
		} else {

			//Pick TSP

			

			//Find Technical Person on Account Team

			AccountTeamMember tsp;

			for(AccountTeamMember atm:[select AccountId, Id, TeamMemberRole, UserId FROM AccountTeamMember where AccountId = :opp.AccountId and TeamMemberRole= 'Technical Sales - Primary' ])

				tsp = atm;

				

				

			if (tsp != null){

				newApproval.User_Technical__c = tsp.UserId;

			}

			else

			{

				//Find the Rep on the Opportunity

				newApproval.User_Technical__c = opp.OwnerId;	

				

			}	
		}

		

		

		newApproval.Status__c='PENDING-TECHNICAL';

		newApproval.Escalation_Status__c='NEW';

		String ref = workflow.name + ' Approval for ' + opp.name;

		Integer len = ref.length();

		if (len > 79) {

			len = 79;
		} 

		newApproval.name = ref.substring(0,len);

		

		newApproval.Last_Reminder_Date__c = DateTime.now();

		

		insert newApproval;

		

		

		return newApproval.id;		

		

	}



webservice static String approvalOverride(String approvalId){



	Product_Approvals__c p_approval;	

	for(Product_Approvals__c pa: [select Id,Survey_Taken__c from Product_Approvals__c where id=:approvalId])

            p_approval = pa;

            

           	if(p_approval == null){

                return 'We could not find your approval request object';

            }

        

   //Pull the latest approval instance.     

    ProcessInstance pp;

	for(ProcessInstance pi: [SELECT CreatedById, IsDeleted, LastModifiedById, LastModifiedDate, Id,

     Status, SystemModstamp, TargetObjectId, CreatedDate FROM ProcessInstance 

     where targetobjectid=:p_approval.id order by createddate desc limit 1]) {

		pp = pi;

	}

    if (pp == null || pp.status == 'Rejected')

    {

    	// we need to submit this for approval first and then approve it.

    	p_approval.Skip_Approval__c = true;

        p_approval.Approval_Overridden_by_SA__c = true;

     	p_approval.Approval_Overriden_By_User__c = UserInfo.getUserId();

         update p_approval;

        

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();

            req.setComments('Overridden and Approved by Sales Analyst');

            req.setObjectId(p_approval.id);

            // submit the approval request for processing

            Approval.ProcessResult result = Approval.process(req);

			

			

			return 'This Request has been submitted and approved';			
    }    

        

      if(pp.status == 'Approved')

      	return 'This request has already been approved';

   

   

   	 p_approval.Approval_Overridden_by_SA__c = true;

     p_approval.Approval_Overriden_By_User__c = UserInfo.getUserId();

	 update p_approval;

   

   	 ProcessInstanceWorkitem piw;

	for(ProcessInstanceWorkitem pw:[Select p.Id, p.ProcessInstanceId, p.ProcessInstance.TargetObjectId 

		from ProcessInstanceWorkitem p where p.ProcessInstance.TargetObjectId = :p_approval.id]){

		piw = pw;

	}



	Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();

	pwr.setWorkitemId(piw.id);



	pwr.setAction('Approve');

	pwr.setComments('Approved by Sales Analyst Override');

	Approval.ProcessResult rs = Approval.Process(pwr);

     

    

        

	return 'Request has been Successfully Approved';
}



public static String invokeTSPReminderEmail() {

	String result='';

		Boolean HasError=false;

		Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();

		Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();	

		

	

	String freqStr = GSM_Custom_Settings__c.getValues('ProductApprovals#TSPReminderFreq').Value__c;
	Date cutoff = Date.valueOf(GSM_Custom_Settings__c.getValues('ProductApprovals#TSPReminderCutoff').Value__c);
		

	Integer freqInt = Integer.valueOf(freqStr);

	date d = system.today().addDays(freqInt);

	Test.startTest();	

	List<Product_Approvals__c> approvals = [Select name, workflow_id__c, Last_Reminder_Date__c,

											user_Technical__C, User_technical__r.email , 

											opportunity_owner__c, opportunity_owner__r.email,

											creator__c, creator__r.email,

											status__c,CreatedDate

											from product_approvals__c

											where status__c = 'PENDING-TECHNICAL' 

											and (Last_Reminder_Date__c = NULL

											OR Last_Reminder_Date__c < :d) 

											and createdDate > :cutoff

											and user_technical__c <> NULL limit 20];		

	



	for(Product_Approvals__c approval: approvals){

		

		sendEmailList.add(PRMScheduledJobs.createSingleEmail(approval.id,

											approval.User_Technical__c,

											approval.Opportunity_Owner__r.email + ',' + approval.Creator__r.email,

											GSM_Custom_Settings__c.getValues('ProductApprovals#TSPReminderTemplate').Value__c));

			

		approval.Last_Reminder_Date__c = DateTime.now();

		//update approval;
	}

	update approvals;

	Test.stopTest();

	if (sendEmailList.size()>0)

		{

			result+='\nSending Email started:';

			integer count=0;

			integer failedcount=0;

			sendEmailResultList = Messaging.sendEmail(sendEmailList, false);

			for(Messaging.SendEmailResult sr:sendEmailResultList){

			if(!sr.isSuccess())

			      {

			      	//string err = sr.getErrors();//[0];

			      	result+='\nError getMessage:'+sr.getErrors()[0].getMessage();

			      	result+='##getFields:'+sr.getErrors()[0].getFields();

			      	result+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();

			      	result+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();

			      	result+='##record count:'+count;

			      	failedcount++;

			      	HasError=true;

			      }

				count++;

			}

			result+='\nNo. Of emails sent:'+(count-failedcount);

		}

	

	

	if(HasError==true)

			return '0:'+result;

		else

			return '1:'+result;

	
}



}