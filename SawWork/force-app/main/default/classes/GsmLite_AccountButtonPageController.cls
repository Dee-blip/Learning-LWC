public class GsmLite_AccountButtonPageController
{
    PageReference pageRef;
    
    public static Id recordId, recordTypeId,accId;
    public static String userProfile ;
    
    public PageReference init()
    {
        String fromButton;
        
        fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
        userProfile  = ApexPages.currentPage().getParameters().get('userProfile');
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        accId = ApexPages.currentPage().getParameters().get('accId');
        
        
        
        
        
        
        if(!String.isBlank(fromButton))
        {
            if(fromButton == 'PartnerUsers')
            {
                pageRef = partnerUsers();
                return pageRef;
            }
        }
        
        return null;
    }
    
    public PageReference partnerUsers()
    {
        String result;
        String accIdTrimmed = Id.valueOf(accId);
        accIdTrimmed = accIdTrimmed.substring(0,15);
        String theme= UserInfo.getUiThemeDisplayed();
        System.debug('theme : '+theme);
        
        if(userProfile=='Partner Community User' || userProfile=='Partner Community Admin')
            {
                if(theme=='Theme4d' || theme=='Theme4u')
                {
                    pageRef = new PageReference('/partners/00OG0000004AJQZ');
                    // /one/one.app?source=aloha#/sObject/00OG0000004DofKMAS/view?fv0={!Account.Id}
                    pageRef.setRedirect(true);
                    pageRef.getParameters().put('fv0', accIdTrimmed);
                    pageRef.getParameters().put('fv3', accIdTrimmed);
                }
                else
                {
                    pageRef = new PageReference('/partners/00OG0000004AJQZ');
                    pageRef.setRedirect(true);
                    pageRef.getParameters().put('pv0', accIdTrimmed);
                    pageRef.getParameters().put('pv3', accIdTrimmed);
                }
            }
        
        else
            {
                if(theme=='Theme4d' || theme=='Theme4u')
                {
                    String pagereff = '/one/one.app?source=aloha#/sObject/00OG0000004AJQZ/view?fv0='+accIdTrimmed+'&fv3='+accIdTrimmed;
                    pageRef = new PageReference(pagereff); 
                    pageRef.setRedirect(true);

                }
                else
                {
                    pageRef = new PageReference('/00OG0000004AJQZ');
                    pageRef.setRedirect(true);
                    pageRef.getParameters().put('pv0', accIdTrimmed);
                    pageRef.getParameters().put('pv3', accIdTrimmed);
                }
            }
        
        System.debug('pageref url : '+pageRef.getUrl());
        System.debug('accIdTrimmed : '+accIdTrimmed);
        System.debug('accId : '+accId);
        return pageRef;
    }
    
   
}