global class ContentDownloadBlocker implements Sfc.ContentDownloadHandlerFactory {
	global static Boolean OverrideFlag = false;
    public Sfc.ContentDownloadHandler getContentDownloadHandler(List<ID> ids, Sfc.ContentDownloadContext c) {

        System.Debug(LoggingLevel.Error, 'AGH_D sfc ids '+ids);
        // block multifile download for partners

        //SFDC-6925 Adding check to allow blocker functionality only if logged in community is Partner Community
        if(NAPSettings.getValue('SecureFileDownload').equalsIgnoreCase('true') && Userinfo.getUserType().contains('Partner') && !OverrideFlag && ( (Network.getNetworkId() != null && NAPSettings.getValue('communitiesForContentDownloadBlocker').contains(String.valueOf(Network.getNetworkId()))) || Test.isRunningTest())) {
            if(ids.size()>1)
            {
                // block download if attributes dont match
                return insufficientDownloadAccess();
            }
            else
            {
                // get latest id
                Id latestCVId = NAPUtilClass.getLatestVersion(ids[0]);

                if(!CurrentUser.hasFileAccess(latestCVId))
                    return insufficientDownloadAccess();
                else{
                    if(latestCVId!=ids[0])
                        return insufficientDownloadAccess(NAPSettings.getValue('File_Download_Link')+latestCVId+'?operationContext=CHATTER');}
            }
        }
        return hasAccess();
    }

    public Sfc.ContentDownloadHandler insufficientDownloadAccess()
    {
        return insufficientDownloadAccess('/apex/APPLandingPage?error_code=403');
    }

    public Sfc.ContentDownloadHandler insufficientDownloadAccess(String retURL)
    {
        Sfc.ContentDownloadHandler cdh = new Sfc.ContentDownloadHandler(); 
        cdh.redirectUrl = retURL;
        cdh.isDownloadAllowed = false;
        return cdh;
    }

    public Sfc.ContentDownloadHandler hasAccess()
    {
        Sfc.ContentDownloadHandler cdh = new Sfc.ContentDownloadHandler(); 
        cdh.isDownloadAllowed = true;
        return cdh;
    }

}