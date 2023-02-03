global class ChatterEmailHandler implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

        //create result for email operation
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
           // try{
               //User user = [select id from User where email = :email.fromAddress and contactid=''][0];
               FeedItem f = new FeedItem();
               f.ParentId = Userinfo.getUserId();//user.id;
               
               boolean IsGroupUpdateEmail=false;
               string GroupTag='';
               map<string,string> EmailGroupMap=new map<string,string>();
               string prefix='E2Chatter:';
               for(GSM_Settings__mdt gsm : [select Value__c, Label from GSM_Settings__mdt where Label like : prefix+'%']){
                  EmailGroupMap.put(gsm.Label.tolowercase().replace(prefix.tolowercase(),''), gsm.Value__c);
               }
               if(EmailGroupMap.size()>0)
               {
                    for(string st:EmailGroupMap.keyset())
                    {
                      //if group email is already found end the loop
                      if(IsGroupUpdateEmail==true)
                      break;
                      //check if to email is custom setting email
                        if(email.toaddresses!=null && email.toaddresses.size() > 0)
                    {
                       for (integer i = 0 ; i < email.toaddresses.size() ; i++) {
                          if(email.toaddresses[i].contains(st))
                          {
                            string groupIdtag=EmailGroupMap.get(st);
                            if(groupidtag.contains(':'))
                            {
                              f.ParentId=groupIdtag.split(':')[0];
                              GroupTag=groupIdtag.split(':')[1];
                            }
                            else
                              f.ParentId=groupIdtag;
                            IsGroupUpdateEmail=true;
                          }
                    }
                    }
                    //check if cc email is custom setting email
                    if ( email.ccAddresses!=null && email.ccAddresses.size() > 0){
                      
                      for (integer i = 0 ; i < email.ccAddresses.size() ; i++) {
                          if(email.ccAddresses[i].contains(st))
                          {
                            string groupIdtag=EmailGroupMap.get(st);
                            if(groupidtag.contains(':'))
                            {
                              f.ParentId=groupIdtag.split(':')[0];
                              GroupTag=groupIdtag.split(':')[1];
                            }
                            else
                              f.ParentId=groupIdtag;
                            IsGroupUpdateEmail=true;
                          }
                    }
                   
                   }
                    }
               }
               String bodytext;
               
               if ( email.plainTextBody != null)
                  bodytext = email.plainTextBody;
               String subjecttext = email.subject;
               
               String match;
               Integer s;
               Integer l;
               String query;
               String errormessage;
               if(IsGroupUpdateEmail==true)
               {
                 subjecttext=GroupTag+'\n'+subjecttext;
                 User user = null;
                 User CurrentUser=null;
                 for(User u:[select id from User where (email = :email.fromAddress and contactid='' and IsActive=True) or id=:UserInfo.getUserId()])
                  {
                    if(u.id!=Userinfo.getUserId())
                      user=u;
                    else 
                      CurrentUser=u;
                  }
                 if(user==null)
                 user=CurrentUser;
                 
                 if(user!=null)
                 {
                  Boolean IsInGroup=false;
                  for(CollaborationGroupMember cgm:[select memberid from CollaborationGroupMember where CollaborationGroupId=:f.ParentId and memberid=:user.id])
                  IsInGroup=true;
                  if(IsInGroup==false)
                  {
                    CollaborationGroupMember cgminsert=new CollaborationGroupMember();
                    cgminsert.CollaborationGroupId=f.ParentId;
                    cgminsert.memberid=user.id;
                    insert cgminsert;
                  }
                  f.CreatedById=user.id;
                 }
                  
                 
               }
               if (subjecttext.lastindexof('#account') != -1)
               { 

                 s = subjecttext.lastindexof('#account');
                 s += 9;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 9;
                 subjecttext = subjecttext.substring (0,s);
                 
                 match = match.trim();
                 
                query = 'select Id from Account where name = \'' + match + '\' limit 1'; 
                                  
                 Account a = new Account();
                 try {
                        a = Database.query(query);
                        f.ParentId = a.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find an account named: '+match;
                    } 
               }
                
                if (subjecttext.lastindexof('#contact') != -1)
               { 

                 s = subjecttext.lastindexof('#contact');
                 s += 9;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 9;
                 subjecttext = subjecttext.substring (0,s);
                 
                 match = match.trim();
                 
                 Contact c = new Contact();
                 try {
                        c = [Select Id from Contact where email = :match limit 1];
                        f.ParentId = c.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find a contact with email address: '+match;
                    } 
               }
               
               if (subjecttext.lastindexof('#opportunity') != -1)
               { 

                 s = subjecttext.lastindexof('#opportunity');
                 s += 13;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 13;
                 subjecttext = subjecttext.substring (0,s);

                 match = match.trim();

                 query = 'select Id from Opportunity where name = \'' + match + '\' limit 1'; 
                 
                 Opportunity o = new Opportunity();
                 try {
                        o = Database.query(query);
                        f.ParentId = o.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find an opportunity named: '+match;
                    } 
               }
               
               if (subjecttext.lastindexof('#case') != -1)
               { 

                 s = subjecttext.lastindexof('#case');
                 s += 6;
                 l = subjecttext.length();
                 match = subjecttext.substring(s,l);
                 s = s - 6;
                 subjecttext = subjecttext.substring (0,s);

                 Case ca = new Case();
                 try {
                        ca = [Select Id from Case where CaseNumber = :match limit 1];
                        f.ParentId = ca.Id;
                        f.Type = 'TextPost';
                 } catch (Exception e) {
                        errormessage ='Sorry, your chatter status has not been set.  We could not find case number: '+match;
                    } 
               }
              

               if (email.binaryAttachments != null)
               {
                   f.body = subjecttext;
                   f.Type = 'ContentPost';
                   f.ContentData = email.binaryAttachments[0].body;
                   
                   f.ContentFileName = email.binaryAttachments[0].filename;
                   //Sonali Tandon- CR 2788797 - Chatter Email handler bug- Increased from limit 1000 to 5000.
                   if (bodytext.length() > 5000)
                   {
                      f.body = bodytext.substring (0,4950);
                      f.ContentDescription = bodytext.substring (0,150)+'....';
                   }
                   else
                   {
                      f.ContentDescription = email.plainTextBody;
                   }

               }
               else
               {
                 if (bodytext != null)
                     bodytext= subjecttext +'\n\n'+bodytext;
                 else
                     bodytext= subjecttext;
                  //Sonali Tandon- CR 2788797 - Chatter Email handler bug- Increased from limit 1000 to 5000.
                 if (bodytext.length() > 5000)
                   {
                      f.body = bodytext.substring (0,4950)+'\n\n(Please check the attachment for more)';
                      f.ContentDescription = bodytext.substring (0,150)+'....';
                      if(email.htmlBody!=null)
                      {
                        
                        f.ContentData = blob.valueOf(email.htmlBody);
                        f.ContentFileName = subjecttext+'.html';
                        
                      }
                      else{
                        
                        f.ContentData = blob.valueOf(bodytext);
                        f.ContentFileName = subjecttext+'.txt';
                        
                      }
                   }
                   else
                   {
                      f.body = bodytext;
                   }

               }
               
                if (errormessage == null)
                {
                   insert f;
                   //I'm saying that it worked, and that a new status was created.
                    result.message='Your Chatter status has been successfully set to: ' + f.body;
                    result.success = true;                    
                }
                else
                {
                    result.message=errormessage;
                    result.success = false;                    
                }
               if(IsGroupUpdateEmail!=true)
                 return result;
               else
                 return null;
            //} catch (Exception e) {
              // result.message='Sorry, your Chatter status could not be set.  Please make sure you are sending from the email address associated with your salesforce login.';
              // result.success = true;
              //  return result;
              //}

    }
    
     //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
 //   static testMethod void testChatterEmailHandler1(){
      
 //      // Create a new email and envelope object
 //      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
 //      Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
 //      String userName = UserInfo.getUserName();
 //      User activeUser = [Select Email From User where Username = :userName limit 1];
 //      String userEmail = activeUser.Email;
      
      
 //      // Create a new test Account and insert it in the Test Method        
 //      //Account a = new account(Name='Test Account');
 //      Account a = utilTestClass.CreateAccount('Test Account');
 //      insert a;
    
 //   // Create a new test Contact and insert it in the Test Method  
 //      /*Contact c = new Contact( accountid = a.id, 
 //                   lastName='Test Contact', 
 //                   Email='testc@mailop.com');*/
 //      Contact c = utilTestClass.CreateContact('Test', 'Test Contact');
 //      c.AccountId = a.Id;
 //      insert c;
       
 //      // test with subject that matches the unsubscribe statement
 //      email.subject = 'test #contact testc@mailop.com';
 //      email.fromAddress = userEmail;
       
 //      // call the class and test it with the data in the testMethod
 //      ChatterEmailHandler ChatterEmailHandlerTest1 = new ChatterEmailHandler();
       
 //      Test.starttest();
 //      ChatterEmailHandlerTest1.handleInboundEmail(email, env );
 //      Test.stoptest(); 
       
  //  /*List<ContactFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from ContactFeed where ParentId =:c.Id Order By CreatedDate DESC];
  //  ContactFeed updatedPost = posts[0];
  //  System.assertEquals(updatedPost.FeedPost.Body, 'test'); */
 //   }
 
 // static testMethod void testChatterEmailHandler2(){
      
 //      // Create a new email and envelope object
 //      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
 //      Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
 //      String userName = UserInfo.getUserName();
 //      User activeUser = [Select Email From User where Username = :userName limit 1];
 //      String userEmail = activeUser.Email;
      
 //      // Create a new test Case and insert it in the Test Method  
 //      Case ca = new Case( Status = 'new', 
 //                   Origin ='Phone' );
 //      insert ca;
       
 //      Case testc = [Select case.CaseNumber from Case where case.Id = :ca.Id];
 //      email.subject = 'test2 #case '+testc.CaseNumber;       
 //      email.fromAddress = userEmail;
       
       
 //      // call the class and test it with the data in the testMethod
 //      ChatterEmailHandler ChatterEmailHandlerTest2 = new ChatterEmailHandler();
       
 //      Test.starttest();
 //      ChatterEmailHandlerTest2.handleInboundEmail(email, env );  
 //      Test.stoptest(); 
       
 //     /* List<CaseFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from CaseFeed where ParentId =:ca.Id Order By CreatedDate DESC];
 //      CaseFeed updatedPost2 = posts[0];
 //      System.assertEquals('test2', updatedPost2.FeedPost.Body); */
       
       
 //   }
    
 //   static testMethod void testChatterEmailHandler3(){
      
 //     // Create a new email and envelope object
 //      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
 //      Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
 //      String userName = UserInfo.getUserName();
 //      User activeUser = [Select Email From User where Username = :userName limit 1];
 //      String userEmail = activeUser.Email;
      
      
 //      // Create a new test Account and insert it in the Test Method        
 //      //Account a = new account(Name='Test Account');
 //      Account a = utilTestClass.CreateAccount('Test Account');
 //      insert a;
       
 //      // Create a new test Opportunity and insert it in the Test Method  
 //      /*Opportunity o = new Opportunity( account = a, 
 //                   Name='Test Opportunity', 
 //                   StageName='Prospecting');*/
 //      Opportunity o = utilTestClass.CreateOpportunity('Test opportunity','Prospecting');
 //      o.CloseDate=Date.today();
 //      insert o;    
       
 //      // test with subject that matches the unsubscribe statement
 //      email.subject = 'test3 #opportunity Test Opportunity';
 //      email.fromAddress = userEmail;
       
 //      // call the class and test it with the data in the testMethod
 //      ChatterEmailHandler ChatterEmailHandlerTest3 = new ChatterEmailHandler();
       
 //      Test.starttest();
 //      ChatterEmailHandlerTest3.handleInboundEmail(email, env );
 //      Test.stoptest(); 
       
       
  //  /*List<OpportunityFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from OpportunityFeed where ParentId =:o.Id Order By CreatedDate DESC];
  //  OpportunityFeed updatedPost3 = posts[0];
    
 //       System.assertEquals('test3', updatedPost3.FeedPost.Body); */
 //   }    
    
 //   static testMethod void testChatterEmailHandler4(){
      
 //      // Create a new email and envelope object
 //      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
 //      Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
 //      String userName = UserInfo.getUserName();
 //      User activeUser = [Select Email From User where Username = :userName limit 1];
 //      String userEmail = activeUser.Email;
      
 //      // Create a new test Account and insert it in the Test Method        
 //      //Account a = new account(Name='Test Account');
 //      Account a = utilTestClass.CreateAccount('Test Account');
 //      insert a;
       
 //      // test with subject that matches the account
 //      email.subject = 'test4 #account Test Account';
 //      email.fromAddress = userEmail;
       
 //      // call the class and test it with the data in the testMethod
 //      ChatterEmailHandler ChatterEmailHandlerTest4 = new ChatterEmailHandler();
      
       
 //      Test.starttest();
 //      ChatterEmailHandlerTest4.handleInboundEmail(email, env );
 //      Test.stoptest(); 
       
  //  /*List<AccountFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from AccountFeed where ParentId =:a.Id Order By CreatedDate DESC]; 
  //  AccountFeed updatedPost = posts[0];
  //  System.assertEquals(updatedPost.FeedPost.Body, 'test4');  */
 //   }
  //static testMethod void testChatterEmailHandler5(){
      
 //      // Create a new email and envelope object
 //      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
 //      Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
       
 //      String userName = UserInfo.getUserName();
 //      User activeUser = [Select Email From User where Username = :userName limit 1];
 //      String userEmail = activeUser.Email;
      
       
 //      // test with subject that matches the account
 //      email.subject = 'test4 ';
 //      email.fromAddress = userEmail;
 //      email.plainTextBody= '1234567889';
  //      for(integer i=0;i<3205;i++)
  //      email.plainTextBody= email.plainTextBody+'01234567889';
       
 //      // call the class and test it with the data in the testMethod
 //      ChatterEmailHandler ChatterEmailHandlerTest4 = new ChatterEmailHandler();
      
       
 //      Test.starttest();
 //      ChatterEmailHandlerTest4.handleInboundEmail(email, env );
 //      Test.stoptest(); 
       
  //  /*List<AccountFeed> posts = [select FeedPost.Id, FeedPost.Body, FeedPost.Title from AccountFeed where ParentId =:a.Id Order By CreatedDate DESC]; 
  //  AccountFeed updatedPost = posts[0];
  //  System.assertEquals(updatedPost.FeedPost.Body, 'test4');  */
 //   }
  
    

    
}