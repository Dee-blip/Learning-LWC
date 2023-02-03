/* Used to add or remove survey takers from the database */
global with sharing class AddUsersController {
	public List<Contact> allUsers	{get; set;}
	public String theList			{get; set;}
	public String surveyRef			{get; set;}
 
   /** Fills the list of contacts who are taking the survey
       specified in the url parameter.
    */ 
	public AddUsersController() {
		surveyRef = Apexpages.currentPage().getParameters().get('sId');
	}


//------------------------------------------------------------------------------//	
//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
  	//private static TestMethod void testAddUsersController(){
	  //SurveyTestingUtil tu = new SurveyTestingUtil();
   //   AddUsersController sc = new AddUsersController();
   //   System.assert(sc!=null);
  	//}   
//------------------------------------------------------------------------------//	

   /** Inserts a new Survey taker in the database
       param: userId	Contact ID as specified in the url parameter
       param: sId		Survey ID as specified in the url parameter
       return: boolean 	returns 'true' if no error
    */	
	static Webservice String addUser(String userId, String sId, String paId) {
		/*String CaseId;
	
		if(caId.toUpperCase() =='NONE'|| caId.length()<5)
		  caseId = null;
		else  
		  caseId = caId;  	
		*//*
		if(userId.toUpperCase() == 'NONE'|| userId.length()<5)
		  userId = null;
	*/
		
		String productApprovalId;
	
		if(paId.toUpperCase() =='NONE'|| paId.length()<5)
		  productApprovalId = null;
		else  
		  productApprovalId = paId;  	
	
		
		//Find Survery Taken
		
		Product_Approvals__c approval;
		for(Product_Approvals__c pa: [select Survey_Taken__c from Product_Approvals__c where id=:productApprovalId])
			approval = pa;
			
			
			if(approval == null || approval.Survey_Taken__c != null){
				return 'false';
			}
		
		
		/*	  
		List<SurveyTaker__c> check = [Select Contact__c, Survey__c, Case__c From SurveyTaker__c Where Contact__c=:userId and Survey__c=:sId and Case__c = :caseId];
		if(check != null && check.size()>0){
			return 'false';
			// Check to see if contact is not already in the database 
  		}*/
  		
		/* Add the contact to the database otherwise */
		
		/*List <Contact> c = [Select Id, FirstName, LastName, email From Contact Where Id=:userId];
		if(c == null || c.size()==0)
		  return 'false';
		  */
		
		SurveyTaker__c st = new SurveyTaker__c();
		
		//st.Contact__c = userId;
		st.Survey__c = sId;
		st.Taken__c = 'false';
		//st.Case__c = caseId;
		insert st;
		
		approval.Survey_Taken__c = st.id;		
		update approval;
		return 'true';
	}

//------------------------------------------------------------------------------//	
//CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
  	//private static TestMethod void testAddUser(){
   // 	SurveyTestingUtil tu = new SurveyTestingUtil();
    	
   // 	//System.assert(
   // 	AddUsersController.addUser(tu.contactId2, tu.surveyId, tu.paId);
   // 	// == 'true');
   // 	//System.assert(
   // 	AddUsersController.addUser('arf','arf','arf');
   // 	//== 'false');
   // 	//System.assert(
   // 	AddUsersController.addUser(tu.contactId, tu.surveyId, 'none');
   // 	// == 'false');
  	//}
//------------------------------------------------------------------------------//	


   /** Removes a survey taker from the database
       param: userId	Contact ID as specified in the url parameter
       return: boolean 	returns 'true' if no error
    */ 
    /* 	
	public static Webservice String removeUser(String userId) {
		List<SurveyTaker__c> st = [Select Id, Contact__c From SurveyTaker__c Where Contact__c=:userId];
		for(SurveyTaker__c s:st) 
			delete s;
		return 'true';
	}	
	*/
//------------------------------------------------------------------------------//	
	/*private static TestMethod void testRemoveUser() {
    	SurveyTestingUtil tu = new SurveyTestingUtil();
    	AddUsersController sc = new AddUsersController();	
    	//System.assert(AddUsersController.addUser(tu.contactId2, tu.surveyId, 'none') == 'true');
    	//System.assert(AddUsersController.removeUser(tu.contactId) == 'true');	
	}*/
//------------------------------------------------------------------------------//	
 /* public void InsertNewSurveyTaker(String contactId, String surveyId, String taken, String caseId){
    SurveyTaker__c st = new SurveyTaker__c();
    st.Contact__c = contactId;
    st.Survey__c = surveyId;
    st.Taken__c = taken;
    st.Case__c = caseId;
    insert st;
  }*/
  //------------------------------------------------------------------------------//
}