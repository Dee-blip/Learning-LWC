global class PACE_Review_Calendar {

    public static Id prbReviewRecordType = Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('PRB Review').getRecordTypeId();
    public static Id exceptionReviewRecordType = Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('Exception Review').getRecordTypeId();
    public static Id sirMeetingRecordType = Schema.SObjectType.PACE_Review_Calendar__c.getRecordTypeInfosByName().get('SIR Meeting').getRecordTypeId();

    // This is for prepopulating teh program page
    Webservice static String Create_PRBReview()
    {

        // Initialize static variables
        String prefix = '/' + PACE_Review_Calendar__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        PageReference returnURL = new Pagereference (prefix);   

        returnURL.getParameters().put('RecordType', prbReviewRecordType);       
        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }


    // This is for prepopulating teh program page
    Webservice static String Create_ExceptionReview()
    {

        // Initialize static variables
        String prefix = '/' + PACE_Review_Calendar__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        PageReference returnURL = new Pagereference (prefix);   

        returnURL.getParameters().put('RecordType', exceptionReviewRecordType);     
        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }
    
    //This is to populate sir page
    Webservice static String Create_SIRMeeting()
    {

        // Initialize static variables
        String prefix = '/' + PACE_Review_Calendar__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        PageReference returnURL = new Pagereference (prefix);   

        returnURL.getParameters().put('RecordType', sirMeetingRecordType);     
        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }
    
    public List<PACE_Review_Calendar__c> sortedList(){
        
        return [Select p.SystemModstamp, p.Review_Month__c, p.Review_Date__c, p.RecordTypeId, p.OwnerId, p.Name, p.LastModifiedDate, p.LastModifiedById, p.IsDeleted, p.Id, p.CurrencyIsoCode, p.CreatedDate, p.CreatedById From PACE_Review_Calendar__c p order by p.Review_Month__c limit 50000];
        
    }
    
    
    

}