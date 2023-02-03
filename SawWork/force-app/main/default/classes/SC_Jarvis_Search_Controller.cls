public with sharing class SC_Jarvis_Search_Controller {
    public SC_Jarvis_Search_Controller() 
    {

    }
    public static List<list<SObject>> searchKnowledge(String subject, String caseProduct,String searchObject)
    {
        if(subject == null && caseProduct == null)
        {
            return null;
        }

        String searchString = subject != null && caseProduct != null? 
        '"' + subject + '" AND"' + caseProduct + '"' : 
        subject != null ? '"' + subject + '"' : 
        '"' + caseProduct + '"';

        system.debug('searchString: ' + searchString);
        List<list<SObject>> searchList = new List<list<SObject>>();
        String searchquery = 'FIND :searchString IN ALL Fields RETURNING';

        String articleQuery = 'Knowledge__kav (Id, AKAM_Article_Number__c, Title, Summary,ArticleTotalViewCount';
        articleQuery+= ' Where IsLatestVersion = true and PublishStatus = \'Online\'';
        articleQuery+= ' ORDER by ArticleTotalViewCount desc limit 5 )';

        String feedQuery = 'FeedItem (Id, title,CommentCount,BestCommentId';
        feedQuery+= ' Where Visibility = \'AllUsers\' and Type = \'QuestionPost\'';
        feedQuery+= ' ORDER by BestCommentId nulls last, CommentCount desc limit 5 )';

        switch on searchObject
        {
            when 'Article' 
            {		
                searchquery += ' ' + articleQuery;
            }	
            when 'Feed' 
            {		
                searchquery += ' ' + feedQuery;

            }
            when 'Both'
            {
                searchquery += ' ' + articleQuery + ' , ' + feedQuery;
            }
        }
        system.debug('searchquery: ' + searchquery);
        searchList = search.query(searchquery);

        return searchList;
    }

}