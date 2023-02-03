global class RSS2Chatter_ScheduleGetRSS implements Schedulable{
	public string getRSSQuery = '';
	
    global void execute(SchedulableContext SC) {
		RSS2Chatter_GetRSS newPosts = new RSS2Chatter_GetRSS() ;
		if (getRSSQuery != ''){
			newPosts.soql = getRSSQuery;
		}
		Database.executeBatch(newPosts,1);
	}
    global String getRssFeeds()
    {
    	String res='1:';
    	try
    	{
    	RSS2Chatter_GetRSS newPosts = new RSS2Chatter_GetRSS() ;
		if (getRSSQuery != ''){
			newPosts.soql = getRSSQuery;
		}
		Database.executeBatch(newPosts,1);
		res=res+'\nJob Completed Successfully';
    	}
    	catch(Exception e)
    	{
    		res='0#'+e.getMessage();
    	}
		return res;
    }
}