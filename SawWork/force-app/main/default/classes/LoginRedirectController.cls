public class LoginRedirectController {

    public PageReference RedirectPage() {
        String startUrl = System.currentPageReference().getParameters().get('url');
        if(startUrl==null || startUrl=='')
        startUrl='/home/home.jsp';
        //if(Userinfo.getOrganizationId().contains('00DA0000000Hu5a'))
            //return new PageReference('https://netalliance.akamai.com'+startUrl);
        //else
        //CR 1504522 PRM: Partner Content URL should always redirect to the latest document version
        
       	if(startUrl.startsWith('/'+Schema.Sobjecttype.ContentVersion.getKeyPrefix())) 
       	{
       		string CurrentContentDocumentid=null;
       		//Get the version id from the url
       		string ContentVersionId=startUrl.substring(1,16);
       		for(ContentVersion cv:[select ContentDocumentid from ContentVersion where id=:ContentVersionId])
       			CurrentContentDocumentid=cv.ContentDocumentid;
       		if(CurrentContentDocumentid!=null)
       			return new PageReference('/'+CurrentContentDocumentid);
       	}
       
            return new PageReference(startUrl);
    }
    public LoginRedirectController () {
    }
     //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
    //static testmethod void TestLoginRedirect(){
    //    Test.setCurrentPageReference(Page.LoginRedirect);
    //    LoginRedirectController fruc = new LoginRedirectController();
    //    fruc.RedirectPage();
    //}
}