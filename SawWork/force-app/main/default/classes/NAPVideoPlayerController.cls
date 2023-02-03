/*
   Test class - ContentDownloadBlockerTestClass

 */

global with sharing class NAPVideoPlayerController 
{

    public String videoTitle {get;set;}
    public String videoDownloadURL {get;set;}
    public String videoURLWithoutHost {get;set;}
    public String errorMessage {get;set;}
    public String videoTypeForAMP {get;set;}

    private void showInvalidIdError()
    {
        errorMessage = 'Invalid video id';
    }


    public NAPVideoPlayerController()
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
        else if(sObjectTiep.equalsIgnoreCase('NAP_Video__c'))
        {
            List<NAP_Video__c> nvList = [select id, Video_Title__c, Video_URL__c from NAP_Video__c where id=:idParameter];
            if(nvList!=null && nvList.size()>0)
            {
                videoTitle = (nvList[0].Video_Title__c!=null)?nvList[0].Video_Title__c:'Placeholder Title';

                videoDownloadURL = NAPSettings.getValue('NetStorageDomain')+nvList[0].Video_URL__c;
                videoURLWithoutHost = nvList[0].Video_URL__c;
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

    private void populateVideoAttributes(List<ContentDocument> cdList)
    {
        videoTitle = cdList[0].Title;
        videoDownloadURL = URL.getSalesforceBaseUrl().toExternalForm() + GsmUtilClass.convertToCommunityURL(NAPSettings.getValue('File_Download_Link') + cdList[0].LatestPublishedVersionId);
        videoTypeForAMP = getVideoType(cdList[0].FileExtension);
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