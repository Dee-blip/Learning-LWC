/*
 * NAPNewsSubscriptionBatchClass - This class is used to send nap news subscription related notifications
*/
global class NAPNewsSubscriptionBatchClass implements Database.Batchable<sObject> {

	global final String frequency;

	global Messaging.SendEmailResult[] results;

	global NAPNewsSubscriptionBatchClass(String freq) {
		frequency = freq;
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {

		/*
		 * Check whether the job is a daily job or weekly and query accordingly
		*/
		Datetime systemDate = System.today();
		Datetime dateToUseInQuery;
		
		String systemDateVal;
		String dateValue;

		if (frequency.equalsIgnoreCase('Daily')) {
			dateToUseInQuery = systemDate;
		} else if (frequency.equalsIgnoreCase('Weekly')) {
			dateToUseInQuery = systemDate.addDays((-1)*7);
		}
		//System.debug('Date :'+dateToUseInQuery);
		systemDateVal = String.valueOf(systemDate).replace(' ','T') + 'z';
		dateValue = String.valueOf(dateToUseInQuery).replace(' ','T') + 'z';
		dateValue = dateValue.substring(0, dateValue.indexOf('T')) + 'T00:00:00z';
		System.debug('Date string value :'+dateValue);

		String query = 'Select id,name,Title__c,Urgency__c,LastModifiedDate,RAW_HTML__c,Publish_Status__c,'+
								'Published_On__c,News_Type__c, Events_Type__c, Item_Type__c, Attribute__c,Attribute_Value__c '+
								'From NAP_News_Item__c Where (lastModifiedDate >='+dateValue + ' OR (lastModifiedDate = '+systemDateVal+' AND Urgency__c = true)) Order By lastModifiedDate Desc';
		System.debug('Job Query :'+query); 
		return Database.getQueryLocator(query);

	}

	global void execute(Database.BatchableContext BC, List<sObject> scope){

		/*
		 * Declearing map of User Email id to the list of news that needs to be sent to the user
		 * based upon their user preferences
		 */
		 MAP<String,Map<Datetime,List<NewsItem>>> userEmailToNAPNewsMap = new Map<String,Map<Datetime,List<NewsItem>>>();
		 //MAP<String,Map<Datetime,List<NewsItem>>> userEmailToNAPEventsMap = new Map<String,Map<Datetime,List<NewsItem>>>();

		/*
		 * Query the news subscription records based on the frequency and enable/disabled flag
		*/
		List<NAP_News_Subscription__c> subscriptions = [Select id,name,Type__c, Event_Types__c, Only_receive_OT_content_news__c,Frequency__c,frequency_override__c,
																Partner_Email__c, Partner_User__c, Partner_User__r.NAP_Area__c 
														 From NAP_News_Subscription__c
														 Where Enable_Disable__c = true /*AND Frequency__c =:frequency*/ ];
		//If n subscription found in the system, return
		if (subscriptions.size()==0) return;

		/*
		 * Creating a Map of News type to list of NAP news 
		 * This Map will be used to send notification to the user based upon their prefernece in the respective
		 * NAP subscription record.
		*/
		Map<String,List<NAP_News_Item__c>> typeAndListOfUpdateNewForType = new Map<String,List<NAP_News_Item__c>>();
		//Map<String,List<NAP_News_Item__c>> typeAndListOfUpdateEventType = new Map<String,List<NAP_News_Item__c>>();

		List<NAP_News_Item__c> newsWithOTAttribute = new List<NAP_News_Item__c>();
		List<NAP_News_Item__c> newsWithFrequencyOverride = new List<NAP_News_Item__c>();

		Boolean eligibleOTUser = false;

		for(sObject s : scope){

			NAP_News_Item__c news = (NAP_News_Item__c)s;

			if(news.Item_Type__c.equalsIgnoreCase('News')){
				if (news.Attribute__c != null && news.Attribute__c.equalsIgnoreCase('User Type') && news.Attribute_Value__c!= null && news.Attribute_Value__c.equalsIgnoreCase('OTP')) {
					newsWithOTAttribute.add(news);

				} else {
					if (typeAndListOfUpdateNewForType.get(news.News_Type__c) != null) {
						List<NAP_News_Item__c> newsListForType = typeAndListOfUpdateNewForType.get(news.News_Type__c);
						newsListForType.add(news);
						typeAndListOfUpdateNewForType.put(news.News_Type__c, newsListForType);
					} else {
						List<NAP_News_Item__c> newsListForType = new List<NAP_News_Item__c>();
						newsListForType.add(news);
						typeAndListOfUpdateNewForType.put(news.News_Type__c, newsListForType);
					}
				}
			}else if(news.Item_Type__c.equalsIgnoreCase('Events')){
				if(typeAndListOfUpdateNewForType.get(news.Events_Type__c) != null){
					List<NAP_News_Item__c> EventListByType = typeAndListOfUpdateNewForType.get(news.Events_Type__c);
					EventListByType.add(news);
					typeAndListOfUpdateNewForType.put(news.Events_Type__c, EventListByType);
				}else{
					List<NAP_News_Item__c> EventListByType = new List<NAP_News_Item__c>();
					EventListByType.add(news);
					typeAndListOfUpdateNewForType.put(news.Events_Type__c, EventListByType);
				}
			}
		}

		/*
		 * Creating list of eligible news items based on subscription preferences
		 * Also if user selects only recieve OTP news - only OT news will be added to eligible list
		*/
		System.debug('debug 1::'+typeAndListOfUpdateNewForType);
		for (NAP_News_Subscription__c subscription:subscriptions) {
			Id userId = subscription.Partner_User__c;
			String emailid = subscription.Partner_Email__c;

			if (userId == null || emailid == null) continue;

			Set<NewsItem> eligibleNewsItems = new Set<NewsItem>();
			//Set<NewsItem> eligibleEventItems = new Set<NewsItem>();

			String NAPArea = subscription.Partner_User__r.NAP_Area__c;
			if (NAPArea != null && NAPArea.equalsIgnoreCase('OTP') && userHasOTPermissionSet(userId)) {
				eligibleOTUser = true;
			}

			if (subscription.Only_receive_OT_content_news__c) {
				System.debug('User wants to get only OT content');
				
				/*Check OTP eligiblity
				 */
				if (eligibleOTUser) {

					List<NewsItem> newsItemToAddBasedOnFrequency = addNews(newsWithOTAttribute,subscription,true);
					if (newsItemToAddBasedOnFrequency != null && newsItemToAddBasedOnFrequency.size() > 0)
						eligibleNewsItems.addAll(newsItemToAddBasedOnFrequency);
				}
			} else {
				System.debug('Subscription type :'+subscription.Type__c);
				
				/* Add nap news based on the NAP Subscription record's selected types
				 */
				if(subscription.Type__c != null){
					for (String type:subscription.Type__c.split(';')) {
						//System.debug('Subscription news type :'+type);
						
						/*
						 * If subscription type contains OTP, check to the news access
						 * If user has access and news is nap news add to eligible news list
						 * Else add the NAP news for the other subscription types
						 */
						if ((type.equalsIgnoreCase('OTP') || type.equalsIgnoreCase('OT')) &&  eligibleOTUser && (newsWithOTAttribute != null && newsWithOTAttribute.size() > 0)) {
							
							//System.debug('Adding OT news as subscription type includes OT');
							List<NewsItem> newsItemToAddBasedOnFrequency = addNews(newsWithOTAttribute,subscription,true);
							if (newsItemToAddBasedOnFrequency != null && newsItemToAddBasedOnFrequency.size() > 0)
								eligibleNewsItems.addAll(newsItemToAddBasedOnFrequency);
						}
						else if (typeAndListOfUpdateNewForType.get(type) != null){
							//System.debug('Adding '+type + ' news, as user subscription type contains '+type);
							//eligibleNewsItems.addAll(typeAndListOfUpdateNewForType.get(type));
							List<NewsItem> newsItemToAddBasedOnFrequency = addNews(typeAndListOfUpdateNewForType.get(type),subscription,false);
							if (newsItemToAddBasedOnFrequency != null && newsItemToAddBasedOnFrequency.size() > 0) {
								eligibleNewsItems.addAll(newsItemToAddBasedOnFrequency);
							}
						}
						
					}
				}
			}
			if(subscription.Event_Types__c != null){
				for(String EventType : subscription.Event_Types__c.split(';')){
					if(typeAndListOfUpdateNewForType.get(EventType) != null){
						List<NewsItem> eventItemToAddBasedOnFrequency = addNews(typeAndListOfUpdateNewForType.get(EventType), subscription, false);
						if(eventItemToAddBasedOnFrequency != null && eventItemToAddBasedOnFrequency.size() > 0){
							eligibleNewsItems.addAll(eventItemToAddBasedOnFrequency);
						}
					} 

				}
			}



			System.debug('User :'+emailid + '  :::: Eligible news items :'+eligibleNewsItems);
			//System.debug('User :'+emailid + '  :::: Eligible Event items :'+eligibleEventItems);
			/*
			 * Add the eligible news item by date
			*/
			if (eligibleNewsItems.size() > 0) {
				Map<Datetime,List<NewsItem>> dateWiseEligibleJobs = new Map<Datetime,List<NewsItem>>();

				for (NewsItem news:eligibleNewsItems) {
					Date lastUpdatedDate = date.newinstance(news.news.lastModifiedDate.year(), news.news.lastModifiedDate.month(), news.news.lastModifiedDate.day());
					if (dateWiseEligibleJobs.get(lastUpdatedDate) != null) {
						List<NewsItem> newsForDate = dateWiseEligibleJobs.get(lastUpdatedDate);
						newsForDate.add(news);
						dateWiseEligibleJobs.put(lastUpdatedDate,newsForDate);
					} else {
						List<NewsItem> newsForDate = new List<NewsItem>();
						newsForDate.add(news);
						dateWiseEligibleJobs.put(lastUpdatedDate,newsForDate);
					}
				}
				userEmailToNAPNewsMap.put(emailid,dateWiseEligibleJobs);
			}

		}

		//userEmailToNAPEventsMap
		//userEmailToNAPNewsMap


		

		if(userEmailToNAPNewsMap.size()>0)
        createSubscriptionMails(userEmailToNAPNewsMap);
	}

	global void finish(Database.BatchableContext BC){
		if(results!=null)
	    {

	        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

		    for(Messaging.SendEmailResult sendEmailResult: results){
		            
		          if(!sendEmailResult.isSuccess())
		          {
		            for (Messaging.Sendemailerror sendEmailError : sendEmailResult.getErrors())
		            { 

		              Error_Log__c el = new Error_Log__c(Name='NAPFileSubscriptionDigestBatchClass', Class__c='NAPFileSubscriptionDigestBatchClass', Error_Message__c=sendEmailError.Message);
		                  errorLogs.add(el);
		            }
		          }
		      }

	        if(errorLogs.size()>0)
	            Database.insert(errorLogs, false);

    	}
	}

	private class NewsItems {

		List<NAP_News_Item__c> nonOTNews;
		List<NAP_News_Item__c> OTNews;
	}

	private void createSubscriptionMails(Map<String,Map<Datetime,List<NewsItem>>> userEmailToNAPNewsByDateMap)
  {
        System.debug('Map Of Email To ContentVersion while sending mail:'+userEmailToNAPNewsByDateMap);
        EmailTemplate template =[select Body,Subject,HtmlValue from EmailTemplate where DeveloperName='News_Subscription_Email'][0];
        
        String emailTextBody, emailHTMLBody;
        String newsLink;
        String urlPrefix;
        String eventLink;
        String NewsSubscriptionSettinglink;
        String Footer;
        
        if(System.URL.getSalesforceBaseUrl().getHost().contains('qa'))
            urlPrefix = NAPSettings.getValue('PartnerCommunityURL_QA');
        else
            urlPrefix = NAPSettings.getValue('PartnerCommunityURL_Prod');

        String newsPageBuilder = NAPSettings.getValue('News_Page_Builder_Record');
        String OTnewsPageBuilder = NAPSettings.getValue('News_OT_Page_builder_record');
        String EventsPageBuilder = NAPSettings.getValue('Event_Page_Builder_Record');
        String NewsSubscriptionSettingPageBuilder = NAPSettings.getValue('News_Subscription_Setting_Builder_Record');
        String NewsSubscriptionSettingFooter = NAPSettings.getValue('Nap_News_and_Event_Subscription_footer');

		List<Messaging.SingleEmailMessage> listOfEmails = new List<Messaging.SingleEmailMessage>();
		Document logo = [SELECT Id, Name from Document where name = 'Generic Netalliance Logo' LIMIT 1];
		String urlFileRef = '<image src = "'+ System.URL.getSalesforceBaseUrl().toExternalForm()+
			'/servlet/servlet.ImageServer?id=' + logo.Id + '&oid=' + UserInfo.getOrganizationId()+
			+ '" alt = "akamai_netalliance_logo" /> ';  //SDFC 7172
        
        for(String email : userEmailToNAPNewsByDateMap.keySet())
        {
            if (!userEmailToNAPNewsByDateMap.get(email).isEmpty()) 
            {
                String tableBody = '';
                String tableBody2 = '';
                System.debug('Email for user :'+email);
                Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                message.setToAddresses (new String[]{ email });
                message.setSubject (template.Subject);   
                //System.debug('News for '+email +' :::'+userEmailToNAPNewsMap.get(email));

                Map<Datetime,List<NewsItem>> dateWiseNews = userEmailToNAPNewsByDateMap.get(email);

                Boolean hasAnyUrgentNews = false;

                for(Datetime dateVal:dateWiseNews.keySet())
                {
                	System.debug('debug 2:'+dateVal);
                    List<NewsItem> napsNews = dateWiseNews.get(dateVal);
                    Date dateValue = date.newinstance(dateVal.year(), dateVal.month(), dateVal.day());
                    String dateValString = String.valueOf(dateVal);
					dateValString = dateValString.substring(0, dateValString.indexOf(' '));
					Boolean news1 = false;
					Boolean events1 = false;
					for(NewsItem newsItemVal:napsNews){
						if(newsItemVal.news.Item_Type__c.equalsIgnoreCase('News'))
							news1 = true;
						if(newsItemVal.news.Item_Type__c.equalsIgnoreCase('Events'))
							events1 = true;
					}
					if(news1)
                    	tableBody += '<div style = "font-family : verdana;background-color: #87cefa;color: #000000;padding: 8px; font-size :13px;">'+dateValString+'</div></br>';
                    if(events1)
                    	tableBody2 += '<div style = "font-family : verdana;background-color: #87cefa;color: #000000;padding: 8px; font-size :13px;">'+dateValString+'</div></br>';
                    //tableBody += '<p><b>'+dateValString+'</p></br>';

                    
                    for (NewsItem newsItemVal:napsNews) {
                    	NAP_News_Item__c news = newsItemVal.news;
                    	Boolean isOTP = newsItemVal.isOTPNews;
                    	if(news.Item_Type__c.equalsIgnoreCase('News')){
                    		//tableBody += '</br><div style = "font-family : verdana;background-color: LightGray;color: white;padding: 8px; font-size :13px;">'+dateValString+'</div></br>';
	                    	if (news.Urgency__c)
	                    		hasAnyUrgentNews = true;

	                    	if (isOTP)
	                    		newsLink = urlPrefix + '/' +'apex/APP?page_id='+OTnewsPageBuilder+'&news_id='+news.name;
	                		else
	                			newsLink = urlPrefix + '/' +'apex/APP?page_id='+newsPageBuilder+'&news_id='+news.name;

	                    	//System.debug('News url :'+newsLink);
	                    	tableBody += '<li style = "font-size : 12px; font-family: verdana;">';
	                    	
	                    	if (news.Urgency__c ==true)
	                    		tableBody += '<span style="color:red;">*</span><b>';
	                    		tableBody += '<b>'+news.Title__c + '</b> | <a href="' + newsLink + '"> News Link</a></br>';
	                    		tableBody += '</li></b>';
	                    }else if(news.Item_Type__c.equalsIgnoreCase('Events')){
	                    	
	                    	//tableBody2 += '</br><div style = "font-family : verdana;background-color: LightGray;color: white;padding: 8px; font-size :13px;">'+dateValString+'</div></br>';
	                    	eventLink = urlPrefix + '/' +'apex/APP?page_id='+EventsPageBuilder+'&news_id='+news.name;
	                		tableBody2 += '<li style = "font-size : 12px; font-family: verdana;">';
	                		tableBody2 += '<b>'+news.Title__c + '</b> | <a href="' + eventLink + '"> Event Link</a></br>';
	                    	tableBody2 += '</li>';

	                    	}
	                 }
	                 if(!String.isBlank(tableBody))
                    	tableBody += '<br>';
                     if(!String.isBlank(tableBody2))
                     	tableBody2 += '<br>';
                }

                if(String.isBlank(tableBody))
                	tableBody = '<br>' + NAPSettings.getValue('No_Nap_News_Avaialble') + '<br/>';

                if(String.isBlank(tableBody2))
                	tableBody2 = '<br>' + NAPSettings.getValue('No_Nap_Events_Avaialble') + '<br/>';

                if (hasAnyUrgentNews)
                	tableBody += '<br><span style="color:red;">*</span><span>Urgent news items</span>';

                
                NewsSubscriptionSettinglink = urlPrefix + '/' + 'apex/APP?page_id=' + NewsSubscriptionSettingPageBuilder;
                footer = NewsSubscriptionSettingFooter.replace('here:xxxxx' , '<a href="'+NewsSubscriptionSettinglink+'"> HERE</a>');
                tableBody2 += '<p><br/>Note: ' + footer;

                // Document logo = [SELECT Id, Name from Document where name = 'Generic Netalliance Logo' LIMIT 1];
                // String url_file_ref = '<image src = "'+ System.URL.getSalesforceBaseUrl().toExternalForm()+
                //     '/servlet/servlet.ImageServer?id=' + logo.Id + '&oid=' + UserInfo.getOrganizationId()+
                //     + '" alt = "akamai_netalliance_logo" /> ';
                emailTextBody = template.Body.replace('#body#', tableBody).replace('#body2#', tableBody2).replace('#akamailogo#',urlFileRef);
                emailHTMLBody = template.HtmlValue.replace('#body#', tableBody).replace('#body2#', tableBody2).replace('#akamailogo#',urlFileRef);
                listOfEmails.add(GsmUtilClass.createSingleEmail(email,'',template.Subject,emailTextBody,emailHTMLBody));
            }
      
      	}
		System.debug('List of emails :'+listOfEmails);

		results = Messaging.sendEmail(listOfEmails); 
  }

	public static List<NAP_News_Item__c> getOTNews() {

		List<NAP_News_Item__c> napOTNews = new List<NAP_News_Item__c>();

		return napOTNews;
	}

	private Boolean userHasOTPermissionSet(Id userId) {
		
		Boolean user_has_permission = false;

		List<PermissionSetAssignment> currentUserPerSet = [select Assignee.Name, PermissionSet.Name 
															from PermissionSetAssignment
															where Assignee.Id = :userId];
		
		if (currentUserPerSet.size() == 0) return user_has_permission;

		for ( PermissionSetAssignment psa : currentUserPerSet ) {
			System.debug('PermissionSet.Name' + psa.PermissionSet.Name);
			if ( psa.PermissionSet.Name.equals('OTP') ) {
				user_has_permission = true;
			}
		}
		return user_has_permission;
  	}

  	/*
  	 * Add News item for the eligible list based on certain conditions
  	 * 1) If subscription freqquency is same as job frequency OR
  	 * 2) News item is urgent
  	*/
  	private List<NewsItem> addNews(List<NAP_News_Item__c> eligibleNews,NAP_News_Subscription__c subscription, Boolean OTNews) {
		List<NewsItem> results = new List<NewsItem>(); // SDFC 7172

		  //if (eligibleNews.size()==null) return results; // SDFC 7172
		  // return null;

  		//List<NewsItem> results = new List<NewsItem>();
		if (eligibleNews!= null && eligibleNews.size()!= 0 ){
			for (NAP_News_Item__c news:eligibleNews) {
				if (subscription.Frequency__c.equalsIgnoreCase(frequency) || (subscription.frequency_override__c && news.Urgency__c)) {
					NewsItem newsItem = new NewsItem(news,OTNews);
					results.add(newsItem);
				}
			}
	  	}
	  	return results;
  	}

  	/*private List<EventsItem> addEvents(List<NAP_News_Item__c> eligibleEvents,NAP_News_Subscription__c subscription) {

  		if (eligibleEvents.size()==null) return null;

  		List<EventsItem> results = new List<EventsItem>();

  		for (NAP_News_Item__c Events:eligibleEvents) {
	  		if (subscription.Frequency__c.equalsIgnoreCase(frequency) || (subscription.frequency_override__c && Events.Urgency__c)) {
	  			NewsItem EventsItem = new EventsItem(Events);
	  			results.add(EventsItem);
	  		}
	  	}
	  	return results;
  	}*/

  	class NewsItem {
  		public Boolean isOTPNews;
  		public NAP_News_Item__c news;
  		//public Boolean isEvent;

  		public NewsItem(NAP_News_Item__c newsItem,Boolean isOTPNews) {
  			this.isOTPNews = isOTPNews;
  			this.news = newsItem;
  		}
  	}

  	/*class EventsItem{
  		public NAP_News_Item__c Events;

  		public EventsItem(NAP_News_Item__c Event){
  			this.Events = Event;
  		}
  	}*/
	
}