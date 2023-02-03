public with sharing class SurveyTestingUtil {
 public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
 public String        surveyId       {get; set;}
 public List<String>  questionIds    {get; set;}
 public List<Survey_Question__c> surveyQuestions   {get; set;}
 public String        contactId      {get; set;}
 public String        surveyTakerId  {get; set;}
 public String        contactId2     {get; set;}
 public String paId        {get;set;}
  public SurveyTestingUtil(){
   questionIds = new List<String>();
   surveyQuestions = new List<Survey_Question__c>();
   createTestSurvey();
   createTestQuestions();
   //createTestContact();
   createSurveyTaker();
   createTestResponses();
   createProductApproval();
 }
 //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
 //private static TestMethod void testConstructor(){
 //  SurveyTestingUtil tu = new SurveyTestingUtil();
 //  System.assert(tu.surveyId != null);
 //}
  private void createSurveyTaker(){
   SurveyTaker__c st = new SurveyTaker__c();
   st.Contact__c = contactId;
   st.Survey__c = surveyId;
   st.Taken__c = 'false';
   insert st;
   surveyTakerId = st.Id;
 }
  public void createTestSurvey(){
   Survey__c s = new Survey__c();
   s.Name = 'Testing Survey';
   s.Submit_Response__c = 'empty';
   s.Show_Entry_Question__c = true;
   insert s;
   surveyId = s.Id;
 }
  public void createTestQuestions(){
   questionIds.add(createQuestion(0));
   questionIds.add(createQuestion(1));
   questionIds.add(createQuestion(2));
   questionIds.add(createQuestion(3));
   surveyQuestions.add(createQuestion1(4));
   surveyQuestions.add(createQuestion1(5));
   surveyQuestions.add(createQuestion1(6));
   surveyQuestions.add(createQuestion1(7));
 }
 
 private Survey_Question__c createQuestion1(Integer i){
   Survey_Question__c q = new Survey_Question__c();
   q.Name = 'Testing Question';
   q.Survey__c = surveyId;
   q.Type__c = getType(i);
   q.Choices__c = getChoices();
   q.Question__c = 'Testing Question question';
   q.OrderNumber__c = i;
   q.Required__c = true;
   insert q;
   return q;     
 }
  private String createQuestion(Integer i){
   Survey_Question__c q = new Survey_Question__c();
   q.Name = 'Testing Question';
   q.Survey__c = surveyId;
   q.Type__c = getType(i);
   q.Choices__c = getChoices();
   q.Question__c = 'Testing Question question';
   q.OrderNumber__c = i;
   q.Required__c = true;
   insert q;
   return q.id;     
 }
 
 private void createTestContact() {
  
   /*Account a  = new Account();
  
   a.name = 'Test Acct 12345abc';
   a.billingcountry = 'India';*/
   Account a = utilTestClass.CreateAccount('Test Acct 12345abc');
   insert a;
  
   /*Contact c = new Contact();
   c.LastName = 'Doe';
   c.FirstName = 'John';
   c.Email = 'surveyAppUser@hotmail.com';*/
 Contact c = utilTestClass.CreateContact('John','Doe');
   c.AccountId = a.id;
   insert c;
   contactId = c.Id;  
  
   /*Contact c2 = new Contact();
   c2.LastName = 'Doe2';
   c2.FirstName = 'John2';
   c2.Email = 'surveyAppUser2@hotmail.com';*/
 Contact c2 = utilTestClass.CreateContact('John2', 'Doe2');
   c2.AccountId = a.id;
   insert c2;
   contactId2 = c2.Id;  
 }
  private String createTestResponses() {
   SurveyQuestionResponse__c r = new SurveyQuestionResponse__c();
   r.Response__c = 'two';
   Survey_Question__c sq = [Select id from Survey_Question__c where id=: questionIds[1] limit 1];
   r.Survey_Question__c = sq.id;
   r.SurveyTaker__c = surveyTakerId;
   insert r;
   return 'true';
 }
  private String getType(Integer i){
   if      (i==1)
    return 'Multi-Select--Vertical';
   else if (i==2)
    return 'Single Select--Vertical';
   else if (i==3)
    return 'Free Text';
   else
    return 'Single Select--Horizontal';
 }
 private String getChoices(){
   return 'one\ntwo\nthree\n';
 }
   // Create Account reuse function
 private static User CreateUser()
 {
   //Account newAccount = new Account();
   //newAccount.Name = pAccName;
   // PDRA contd 2 fix...
     // Acc Reassignment Rule for acc.Owner
       /*Profile pr = [select id from profile where name='Sales Operations'][0];
     UserRole role = [select id, Name from UserRole where name=:testcaseCustomSettings.get('User_Role').Value__c][0];
     User accOwner;
     accOwner = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );*/
    
     User accOwner = utilTestClass.CreateUser('newUser', testcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
     insert accOwner;   
     return accOwner;
     // Create a rule
     //Account_Reassignment_Rule__c rule = createAccountReassignmentRule(accOwner, role.Name);    
     //insert rule;
   // ALI KM
   /*newAccount.OwnerId = accOwner.Id;
   newAccount.BillingCountry = 'India';
   return newAccount;*/
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
   return [select  Id,
               AKAM_Opportunity_ID__c
       from Opportunity where Id=:OppId];
         
 }
 private String createProductApproval(){
  
     //Account acc = CreateAccount('__Test Account');
     User owner = CreateUser();
   Account acc = utilTestClass.CreateAccount('__Test Account');
   acc.OwnerId = owner.Id;
       insert acc;
       Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
       opp.AccountId = acc.Id;
       opp.CloseDate = Date.today().addDays(30);
       //opp.AKAM_Opportunity_ID__c = 'F-'
      
     insert opp;
    
     //OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
    
     Order_Approval__c newOrder = new Order_Approval__c();
   newOrder.Associated_Opportunity__c = opp.id;
   newOrder.CCG_Status__c='Open';
   insert newOrder;
    
     Order_Approval__c oa_r = [select  Id,
               AKAM_Opportunity_ID__c
       from Order_Approval__c where Id=:newOrder.id];
    
     system.debug(oa_r.AKAM_Opportunity_ID__c);
     Opportunity opp_r = RefreshOpportunity(opp.id);
     system.debug(opp_r.AKAM_Opportunity_ID__c);
   paId = ProductApprovalHandler.initiateApproval( 'F-PA-001',opp_r.AKAM_Opportunity_ID__c);
     //find existing approval
   Product_Approvals__c currentApproval;
   for(Product_Approvals__c pa:[select id, Survey_Taken__c from Product_Approvals__c where id = :paId])
       currentApproval = pa;
   if(currentApproval != null) {
     //currentApproval.Survey_Taken__c = surveyTakerId;
   //  update currentApproval;
   //  return 'true';
   }
     return 'true';
 }
}
