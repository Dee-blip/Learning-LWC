/***
    @History
    --Developer           --Date            --Change
	Lisha Murthy		05/July/2012		Created the class
											CR 1761167 Customer Save Program - Chatter for Renewal Opportunities
												-> Pick Opptys with contract effective end date is 9, 6, 3, and 1 months away if the opportunity is not closed lost or closed won and create Chatter updates.
													Emails to be sent to Oppty.Owner and Oppty.Owner's manager.
													When renewal Oppty has not been worked on for given number of days, send email to Oppty.Owner's manager.
	Ali KM				11/July/2012		CR 1757947 Optimize SOQL queries in code to avoid System.Query Exceptions.
												-> Query optimization, added CreatedDate >= LAST_90_DAYS to the query in sendEmailForRenewalOppty() method.												 
*/

global class OpportunityScheduledJobsClass 
{
	public static String res;
    public static Set<Opportunity> oppSet;
    public static List<Opportunity> selectedOpptyList;
    public static List<Opportunity> finalNotificationOpptyList;
    public static Map<Id,Id> opptyIdOwnerIdMap;
    public static Map<Id,User> userIdUserMap;
	public static List<User> emailRecipientsList;
	public static Messaging.SingleEmailMessage[] sendEmailForRenewalOpptyList;
	public static Messaging.SendEmailResult[] sendEmailResultList;
	public static List<FeedItem> chatterList;
    public static List<String> checkMonthsList;
    public static String finalNotificationMonth;
    public static String chatterRecurringMessage;
	public static String chatterFinalNotificationMessage;
	public static Date todayDate;
	public static Date indexCheckDate;
    public static Boolean isRunningForecastCountJob=false;
		
	
	public static void init()
	{
		res = '1:Successfully completed';
		oppSet = new Set<Opportunity>();
		selectedOpptyList = new List<Opportunity>();
		finalNotificationOpptyList = new List<Opportunity>();
		opptyIdOwnerIdMap = new Map<Id,Id>();
		userIdUserMap = new Map<Id,User>();
		emailRecipientsList = new List<User>();
		sendEmailForRenewalOpptyList = new List<Messaging.SingleEmailMessage>();
		sendEmailResultList = new List<Messaging.SendEmailResult>();
		chatterList = new List<FeedItem>();
		checkMonthsList = GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_checkMonths').split(',');
		finalNotificationMonth = GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck');
		chatterRecurringMessage = GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOppty_recEmailMsg');
		chatterFinalNotificationMessage = GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalEmailMsg');
		todayDate = Date.Today();
		indexCheckDate = Date.ValueOf(todayDate.addDays(-(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_IndexFilterDays')))));
	}
	
	//Changes for CR 1761167 Customer Save Program - Chatter for Renewal Opportunities
    public static String createChatterForRenewalOppty()
    {
    	try
    	{
	    	init();
	    	Boolean HasError=false;
	    	checkMonthsList.sort();
	    	System.debug('Check months List '+checkMonthsList);
	    	//Select all the renewal Opportunities based on Oppty Type and within the required max and min Time frames (custom setting)
	    	for(Opportunity o: [SELECT Id, Name, BED_Change__c, Contract_Extension__c, StageName, Account.Name, CloseDate, OwnerId, Contract_Effective_End_Date__c, Renew_Contract_Id_Text__c FROM Opportunity 
	    		WHERE (Contract_Effective_End_Date__c >=:Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date() OR Contract_Effective_End_Date__c <:Datetime.now().addMonths(Integer.ValueOf(checkMonthsList[checkMonthsList.size()-1])+1).date().toStartOfMonth())
	    			AND (StageName != 'Closed Won' AND StageName != 'Closed Lost') 
	    			AND (Opportunity_Type__c != null AND Opportunity_Type__c != '' AND Opportunity_Type__c LIKE '%Renewal%')
	    			AND (Contract_Effective_End_Date__c > :Date.Today())
	    			AND (createdDate >= :indexCheckDate)])
	            oppSet.add(o);
	    	
	    	System.debug('Start date for query '+Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date());
	    	System.debug('End Date for query '+Datetime.now().addMonths(Integer.ValueOf(checkMonthsList[checkMonthsList.size()-1])+1).date().toStartOfMonth());
	    	System.debug('Opp set '+oppSet);
	    	
			if(oppSet.size() > 0)
			{
				for(Opportunity o: oppSet)
				{
					//Seperate the Selected oppty to choose the required Opptys of required months in future.(either recurring or final notification oppty)
					Date oppCloseDate = o.Contract_Effective_End_Date__c;
					for(Integer i=0;i<checkMonthsList.size();i++)
					{
						if(o.Contract_Effective_End_Date__c.month() == Datetime.now().addMonths(Integer.ValueOf(checkMonthsList[i])).month())
						{
							selectedOpptyList.add(o);
							break;
						}
					}	
					if(o.Contract_Effective_End_Date__c.month() == Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).month())
						finalNotificationOpptyList.add(o);
				}
				
				System.debug('Selected oppty list '+selectedOpptyList);
				System.debug('Selected oppty list size '+selectedOpptyList.size());
				
				//For recurring oppty in the SelectedOpptyList, add the chatter feed with relevant message (custom setting)
				if(selectedOpptyList.size() > 0)
				{
					for(Opportunity o: selectedOpptyList)
					{
						opptyIdOwnerIdMap.put(o.Id,o.OwnerId);
						String body = chatterRecurringMessage;
						body = body.replaceAll('##o.OpptyName##',o.Name);
						body = body.replaceAll('##o.AccName##',o.Account.Name);
						body = body.replaceAll('##o.EffContractEndDate##',String.ValueOf(o.Contract_Effective_End_Date__c));
						//if(o.Renew_Contract_Id_Text__c != null || o.Renew_Contract_Id_Text__c != '')
							body = body.replaceAll('##o.RenewalContractID##',o.Renew_Contract_Id_Text__c);
						//else
							//body = body.replaceAll('##o.RenewalContractID##','');
						
						FeedItem fi = new FeedItem();
						fi.ParentId = o.Id;
						fi.Body = body;
						chatterList.add(fi);
					}
				}
				
				System.debug('Final notification oppty list '+finalNotificationOpptyList);
				System.debug('Final notification oppty list size '+finalNotificationOpptyList.size());
				
				//For final notification oppty in the finalNotificationOpptyList, add the chatter feed with relevant message (custom setting)
				if(finalNotificationOpptyList.size() > 0)
				{
					for(Opportunity o: finalNotificationOpptyList)
					{
						opptyIdOwnerIdMap.put(o.Id,o.OwnerId);
						String body = chatterFinalNotificationMessage; 
						body = body.replaceAll('##o.OpptyName##',o.Name);
						body = body.replaceAll('##o.AccName##',o.Account.Name);
						body = body.replaceAll('##o.EffContractEndDate##',String.ValueOf(o.Contract_Effective_End_Date__c));
						//if(o.Renew_Contract_Id_Text__c != null || o.Renew_Contract_Id_Text__c != '')
							body = body.replaceAll('##o.RenewalContractID##',o.Renew_Contract_Id_Text__c);
						//else
							//body = body.replaceAll('##o.RenewalContractID##','');
						
						FeedItem fi = new FeedItem();
						fi.ParentId = o.Id;
						fi.Body = body;
						chatterList.add(fi);
					}
				}
				
				System.debug('chatter list '+chatterList);
				System.debug('chatter list size '+chatterList.size());
				
				//Insert all the chatter feeds
				if(chatterList.size() > 0)
				{
					insert chatterList;
					/*try
					{
						insert chatterList;
						res = res + 'Number of Chatter feeds inserted is ' + chatterList.size();
					}
					catch (exception e)
					{
						res = '0:'+e.getMessage();
					}*/
				}
			
				//Send email to Oppty Owner and Owner.Manager
				/*if(opptyIdOwnerIdMap.size() > 0)
				{
					for(User u: [SELECT Id, Name, Email, Manager.Id, Manager.Name, Manager.Email, IsActive, Manager.IsActive FROM User 
								WHERE Id IN :opptyIdOwnerIdMap.values()
								AND (Profile.UserType = 'Standard') 
								AND (ContactId = null OR ContactId = '' OR Manager.ContactId = null OR Manager.ContactId = '')
								AND (IsActive = true OR (ManagerId != null AND Manager.IsActive = true))])
						emailRecipientsList.add(u);
					
					System.debug('Email Recipients List size '+emailRecipientsList.size());
					System.debug('Email Recipients List values '+emailRecipientsList);
					
					//Create the emails to be sent to the owner and manager (if present)
					if(emailRecipientsList.size() > 0)
					{					
						for(User u: emailRecipientsList)
							userIdUserMap.put(u.Id,u);
					
						if(userIdUserMap.size() > 0)
						{
							for(Opportunity o: selectedOpptyList)
							{
								if (!userIdUserMap.containsKey(opptyIdOwnerIdMap.get(o.Id)))
								{
									System.debug('##UserId not present in UserIdUserMap for selected Oppty');
									continue;
								}
								User u = userIdUserMap.get(opptyIdOwnerIdMap.get(o.Id));
								
								if(u.IsActive && u.Manager != null && u.Manager.IsActive == true)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Id,u.Manager.Email,GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
								
								else if(!u.IsActive && u.Manager != null && u.Manager.IsActive)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Manager.Id,'',GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
									
								else if(u.IsActive && u.Manager == null)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Id,'',GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
							}
							
							for(Opportunity o: finalNotificationOpptyList)
							{
								if (!userIdUserMap.containsKey(opptyIdOwnerIdMap.get(o.Id)))
								{
									System.debug('##UserId not present in UserIdUserMap for Final notification oppty list');
									continue;
								}
								User u = userIdUserMap.get(opptyIdOwnerIdMap.get(o.Id));
								
								if(u.IsActive && u.Manager != null && u.Manager.IsActive == true)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Id,u.Manager.Email,GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
								
								else if(!u.IsActive && u.Manager != null && u.Manager.IsActive)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Manager.Id,'',GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
									
								else if(u.IsActive && u.Manager == null)
									sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Id,'',GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_emailTempl').Value__c));
							}
						}
					}
				}
				
				System.debug('Email List '+sendEmailForRenewalOpptyList);
				System.debug('Email List size '+sendEmailForRenewalOpptyList.size());
				
				//Send the emails created.
				if(sendEmailForRenewalOpptyList.size() > 0)
			    {
			    	res+='\nSending Email started:';
			      	integer count=0;
				    integer failedcount=0;
				    sendEmailResultList = Messaging.sendEmail(sendEmailForRenewalOpptyList, false);
			    	for(Messaging.SendEmailResult sr:sendEmailResultList){
				    if(!sr.isSuccess())
			        {
			      		HasError=true;       
			            res+='\nError getMessage:'+sr.getErrors()[0].getMessage();
			            res+='##getFields:'+sr.getErrors()[0].getFields();
			            res+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
			            res+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
			            res+='##record count:'+count;
			            failedcount++;
			        }
			        count++;
			      }
			      res+='\nNo. Of emails sent:'+(count-failedcount);
			    }*/
			}
		}
		catch (exception e)
		{
			res = '0:'+e.getMessage();
		}
		System.debug('Result is '+res);
    	return res;
    }
    
    /* Commenting out code for sending email notification for renewal Opportunities which have not been worked on for given period of time
    
    //Send emails to manager of the Oppty.Owner when the renewal Oppty has not be worked on for a certain period of time (defined in custom settings)
    public static String sendEmailForRenewalOppty()
    {
    	init();
    	Boolean HasError=false;
    	for(Opportunity o: [SELECT Id, Name, BED_Change__c, Contract_Extension__c, StageName, Account.Name, CloseDate, OwnerId, AKAM_Modified_Date__c, Contract_Effective_End_Date__c FROM Opportunity 
    		WHERE (StageName != 'Closed Won' AND StageName != 'Closed Lost')
    			AND (AKAM_Modified_Date__c < :Date.Today().addDays(-(Integer.ValueOf(GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOpp_NoActivityDays').Value__c))))
    			AND (Opportunity_Type__c != null AND Opportunity_Type__c != '' AND Opportunity_Type__c LIKE '%Renewal%')
    			AND CreatedDate >= LAST_N_YEARS:1]) 
            oppSet.add(o);
        
    	System.debug('Opp set '+oppSet);
    	
		if(oppSet.size() > 0)
		{
			for(Opportunity o: oppSet)
				opptyIdOwnerIdMap.put(o.Id,o.OwnerId);
		
			//Send email to Owner.Manager
			if(opptyIdOwnerIdMap.size() > 0)
			{
				for(User u: [SELECT Id, Name, Email, Manager.Name, Manager.Email, Manager.Id, IsActive, Manager.IsActive FROM User 
							WHERE Id IN :opptyIdOwnerIdMap.values() 
							AND Manager.IsActive = true
							AND (Manager.Profile.UserType = 'Standard') 
							AND (Manager.ContactId = null OR Manager.ContactId = '')
							AND ManagerId != null])
					emailRecipientsList.add(u);
					
				System.debug('Email Recipients List size '+emailRecipientsList.size());
				System.debug('Email Recipients List values '+emailRecipientsList);
				
				if(emailRecipientsList.size() > 0)
				{					
					for(User u: emailRecipientsList)
						userIdUserMap.put(u.Id,u);
				
					if(userIdUserMap.size() > 0)
					{
						for(Opportunity o: oppSet)
						{
							if (!userIdUserMap.containsKey(opptyIdOwnerIdMap.get(o.Id)))
							{
								System.debug('##UserId not present in UserIdUserMap');
								continue;
							}
							User u = userIdUserMap.get(opptyIdOwnerIdMap.get(o.Id));
							
							sendEmailForRenewalOpptyList.add(createSingleEmail(o.Id,u.Manager.Id,'',GSM_Custom_Settings__c.getInstance('OppSchCls#RenewalOppty_finalEmail').Value__c));
						}
					}
				}
			}
			
			System.debug('Emails List '+sendEmailForRenewalOpptyList);
			System.debug('Emails List size '+sendEmailForRenewalOpptyList.size());
			
			if(sendEmailForRenewalOpptyList.size() > 0)
		    {
		    	res+='\nSending Email started:';
		      	integer count=0;
			    integer failedcount=0;
			    sendEmailResultList = Messaging.sendEmail(sendEmailForRenewalOpptyList, false);
		    	for(Messaging.SendEmailResult sr:sendEmailResultList){
			    if(!sr.isSuccess())
		        {
		      		HasError=true;        
		            res+='\nError getMessage:'+sr.getErrors()[0].getMessage();
		            res+='##getFields:'+sr.getErrors()[0].getFields();
		            res+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
		            res+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
		            res+='##record count:'+count;
		            failedcount++;
		        }
		        count++;
		      }
		      res+='\nNo. Of emails sent:'+(count-failedcount);
		    }
		}
		if(HasError==False)
		return '1:'+res;
		else
    	return '0:'+res;
    }
    
    //End of changes for CR 1761167 Customer Save Program - Chatter for Renewal Opportunities
    */
	
    //Method to create an email
	
	//CR 2379738.
 	 public static Messaging.SingleEmailMessage createSingleEmail(Id oppid, Id UserId, string ccEmailAddressList, string emailTemplate)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] ccAddresses = ccEmailAddressList.split(',');
        mail.setWhatId(oppid);
        mail.setTargetObjectId(UserId);        
        mail.setTemplateId(emailTemplate);
        mail.setSaveAsActivity(false);
        
        if(ccEmailAddressList != '')
            mail.setCcAddresses(ccAddresses);
        return mail;
    }
   
    
     public static String sendMailforOpptyPastDue()
    {
        init();
        
        date today = date.Today();
        date dueDate = today.addDays(-14);
        //List<Opportunity> Oppty_Records = new List<Opportunity>();
        
        try{
		//SFDC-3261
		List<Opportunity> oppList=[SELECT Name,CloseDate,Owner__r.email,Owner__r.manager.email,Owner__r.name from Opportunity where CloseDate<=:(dueDate)and probability<>0 and probability<>100 and (NOT StageName like 'Closed%') AND CreatedDate >= LAST_N_DAYS:120 and Account.OwnerIDAlt__c!=:GsmUtilClass.getGSMSettingValue('OppSchCls_NetOpsId') and (RecordType.Name=:GsmUtilClass.getGSMSettingValue('OppSchCls_RecordType') OR RecordType.Name=:GsmUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type'))];
           
        calculateduedate(oppList);
            
        return res;
        
        }
        catch(Exception e)
        {
            return '0:duedate is '+dueDate+e.getMessage();
        }
        
    }
    
    public static String calculateduedate(List<Opportunity> Oppty_Records)
    {
        init();
        String send='no';
        
       
        Integer difference_of_days=0;
        Integer isPastSeven=0;
    	try{
            for(Opportunity Opp:Oppty_Records)  
            {    
                difference_of_days=math.abs(date.Today().daysBetween(Opp.CloseDate));//get number of days between current and closed date
                isPastSeven=math.abs(math.mod(difference_of_days,integer.valueof(GsmUtilClass.getGSMSettingValue('OppSchCls_NumberOfDays'))));//check if it is divisible by 7
                if(difference_of_days==integer.valueof(GsmUtilClass.getGSMSettingValue('OppSchCls_DaysPastforOwner'))||difference_of_days>integer.valueof(GsmUtilClass.getGSMSettingValue('OppSchCls_DaysPastforOwner'))&&isPastSeven==0)//due past 14 days
                {
                //send a mail to owner
                   
                                    if(Opp.Owner__r.email!=null)
                                        {
                                        
                                       
                                        sendEmailForRenewalOpptyList.add(createSingleEmail(Opp.Id,Opp.Owner__r.Id,'',GsmUtilClass.getGSMSettingValue('OppSchCls_OppPastDue14')));

                                        
                                         }
                                         send='yes';
                                                       
                }
              
                if(difference_of_days==integer.valueof(GsmUtilClass.getGSMSettingValue('OppSchCls_DaysPastforManager'))||(difference_of_days>integer.valueof(GsmUtilClass.getGSMSettingValue('OppSchCls_DaysPastforManager'))&&isPastSeven==0))
                {
                            if(Opp.Owner__r.manager.email!=null)
                                {
                                
                                sendEmailForRenewalOpptyList.add(createSingleEmail(Opp.Id,Opp.Owner__r.manager.Id,'',GsmUtilClass.getGSMSettingValue('OppSchCls_OppPastDue21')));
                                
                                }
                                send='yes';
                  
                 }
                 if(send=='no')
                 {
                                res='1:Not past due DATE';
                                
                 }
                 
                 
                 
                                 
            }//end of for
            
            if(sendEmailForRenewalOpptyList.size() > 0)
                {
                   // res+='\nSending Email started:';
                    integer count=0;
                    integer failedcount=0;
                    sendEmailResultList = Messaging.sendEmail(sendEmailForRenewalOpptyList, false);
                    for(Messaging.SendEmailResult sr:sendEmailResultList){
                    if(!sr.isSuccess())//if there was error sending the mail
                    {
                        Boolean HasError=true;       
                        res+='\nError getMessage:'+sr.getErrors()[0].getMessage();
                        res+='##getFields:'+sr.getErrors()[0].getFields();
                        res+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
                        res+='##getTargetObjectId:'+sr.getErrors()[0].getTargetObjectId();
                        res+='##record count:'+count;
                        failedcount++;
                    }
                    count++;
                  }
                  }

            return res;
        }//end of try
        catch(Exception e)
        {
        res= '0:exception in calculateduedate'+e.getMessage();
        return res;
        }
    }
		
}