global with sharing class SC_CommunityVideoPlayer {
    public String videoTitle {get;set;}
    public String videoDownloadURL {get;set;}
    public String videoURLWithoutHost {get;set;}
    public String errorMessage {get;set;}
    public String videoTypeForAMP {get;set;}
    //public List<ContentDocument> contentList {get;set;}
    public String videoId{get;set;}

    private void showInvalidIdError()
    {
        errorMessage = 'Invalid video id';
    }
    public SC_CommunityVideoPlayer()
    {
        string CurrentContentDocumentid=null;
        boolean isLatest=true;
        string idParameter=Apexpages.currentPage().getParameters().get('id');
        System.Debug(LoggingLevel.Error, 'AGH_D first');
        String sObjectTiep;
        try
        {
            sObjectTiep = String.valueOf(((Id)idParameter).getSObjectType());
        }
        catch(Exception ex)
        {
            system.debug('inside ex : '+ex.getMessage());
            showInvalidIdError();
            return;
        }
        if(sObjectTiep.equalsIgnoreCase('ContentVersion') || sObjectTiep.equalsIgnoreCase('ContentDocument'))
        {
            List<ContentDocument> cdList=  [select LatestPublishedVersionId,Title, FileExtension from ContentDocument where id in (select ContentDocumentId from ContentVersion where Id=:idParameter or ContentDocumentId=:idParameter) limit 1];
            if(cdList!=null && cdList.size()==1)
            {
                populateVideoAttributes(cdList);
            }
            else
            {
                showInvalidIdError();
            }
        }
        else if(sObjectTiep.equalsIgnoreCase('Community_Video__c'))
        {
            List<Community_Video__c> nvList = [select id, Name, Download_URL__c from Community_Video__c where id=:idParameter];
            if(nvList!=null && nvList.size()>0)
            {
                videoTitle = (nvList[0].Name!=null)?nvList[0].Name:'Placeholder Title';
                String videoURL = [select Value__c from SC_CommunityUtility__mdt where MasterLabel=: 'VideoPlayerURL' limit 1].Value__c;
                //videoDownloadURL = NAPSettings.getValue('NetStorageDomain')+nvList[0].Download_URL__c;
                //videoDownloadURL = 'https://netalliance.akamaized.net'+nvList[0].Download_URL__c;
                videoDownloadURL = videoURL+nvList[0].Download_URL__c;
                //videoDownloadURL = 'https://netalliance.akamaized.net/delivery/58/b5/58b50868-dd9c-469e-9ce7-514361a3ce8a/Bootcamp_Video_02_Pitch_deck_CBR_insertsd910b797-d41d-336d-6c63-e1be13160f48.m3u8';
                videoURLWithoutHost = nvList[0].Download_URL__c;
                videoTypeForAMP = 'application/x-mpegURL';
            }
            else
            {
                showInvalidIdError();
            }
        }
        else
        {
            showInvalidIdError();
        }
        /*
           if(!CurrentUser.hasFileAccess(idParameter))
           {
           errorMessage = 'You do not have access to that video';
           }
         */
    }
    @AuraEnabled
    public static List<Community_Video__c> fetchContentList(String topicId){
        List<Community_Video__c> contentList = new List<Community_Video__c>();
        //String videoFormats = [select Video_Fromats__c from SC_CommunityBlog__mdt where MasterLabel=: 'VideoFormats' limit 1].Video_Fromats__c;
        String videoFormats = [select Value__c from SC_CommunityUtility__mdt where MasterLabel=: 'CommunityVideoFormats' limit 1].Value__c;
        //contentList = [SELECT Id, Title, ParentId, ContentSize, FileType, FileExtension,CreatedBy.name, CreatedDate FROM ContentDocument where FileType IN:(videoFormats.split(','))];
        contentList = [Select Id,Name, Topic_Id__c, Download_URL__c, CreatedDate, CreatedBy.Name from Community_Video__c where Topic_Id__c =: id.valueOf(topicId)];
        return contentList;
    }
    @AuraEnabled
    public static String fetchdownLoadURL(String videoId){
        String videoPlayURL;
        String videoURL = [select Value__c from SC_CommunityUtility__mdt where MasterLabel=: 'VideoPlayerURL' limit 1].Value__c;
    	List<Community_Video__c> nvList = [select id, Name, Download_URL__c, Youtube_Video__c  from Community_Video__c where id=:id.valueOf(videoId)];
        if(!nvList[0].Youtube_Video__c)
        	videoPlayURL = videoURL+nvList[0].Download_URL__c;
        else
            videoPlayURL = 'https://'+nvList[0].Download_URL__c;
        return videoPlayURL;
    }
    @AuraEnabled
    public static String generateVideoLink(String videoId){
        String videoURL;
        String domainName = [select Value__c from SC_CommunityUtility__mdt where DeveloperName = :'DomainName'].Value__c;
        if(!String.isEmpty(domainName))
        	videoURL = domainName+'/apex/SC_CommunityVideoPlayer?Id='+videoId;
        return videoURL;
    }
    private void populateVideoAttributes(List<ContentDocument> cdList)
    {
        videoTitle = cdList[0].Title;
        videoDownloadURL = 'https://akamai--scdev.cs19.my.salesforce.com/sfc/servlet.shepherd/version/download/'+cdList[0].LatestPublishedVersionId;//+ 06829000000GAzScdList[0].LatestPublishedVersionId);
        videoTypeForAMP = getVideoType(cdList[0].FileExtension);
    }

    public static String convertToCommunityURL(String rawURL)
    {
        if(Network.getNetworkId()!=null)
        {
            rawURL = '/'+Label.Partner_Community_Name + rawURL;
        }
        return rawURL;
    }
    
    private String getVideoType(String fileExtension)
    {
        Set<String> mp4Family = new Set<String>{'mp4', 'm4v', 'm4s', 'm4v'};
        if(mp4Family.contains(fileExtension))
            return 'video/mp4';

        Set<String> f4mFamily = new Set<String>{'f4m', 'f4f', 'f4x'};
        if(f4mFamily.contains(fileExtension))
            return 'video/f4m';

        if('webm'.equalsIgnoreCase(fileExtension))
            return 'video/webm';

        if('flv'.equalsIgnoreCase(fileExtension))
            return 'video/x-flv';

        if('mkv'.equalsIgnoreCase(fileExtension))
            return 'video/mkv';

        return 'video/mp4';
  }
}