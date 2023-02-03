public class ErrorPageController {
    public String ErrorMsg { get; set; }
    public String severity { get; set; }
    public PageReference Back() {
        return new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
    }
    public ErrorPageController(){
    	severity='error';
    	if(ApexPages.currentPage().getParameters().get('sev')!=null && ApexPages.currentPage().getParameters().get('sev')!='')
    	severity=ApexPages.currentPage().getParameters().get('sev');
        //SFDC-2686
        String eps = null;
        String metadataName = ApexPages.currentPage().getParameters().get('ErrorType');
           if(metadataName != null){
              if(metadataName.contains(' ')){
                  metadataName = metadataName.replaceAll(' ', '_');
              }
              if(metadataName.isNumeric()){
                  metadataName = 'X'+metadataName;
              }
            // ErrorMsg=Error_Page_Settings__c.getInstance(ApexPages.currentPage().getParameters().get('ErrorType')).value__c ;
             ErrorMsg = GsmUtilClass.getErrorPageSettingValue(metadataName);  //Error_Page_Settings__c.getInstance(ApexPages.currentPage().getParameters().get('ErrorType')).value__c ;
           }
       }

	 //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass

    //public static testMethod void ErrorPageControllerTest () {
 //       // Instantiate a new controller with all parameters in the page
 //       PageReference pageRef = Page.ErrorPage;
 //       pageRef.getParameters().put('ErrorType', '1');
 //       pageRef.getParameters().put('retURL', '/home/home.jsp');
 //       Test.setCurrentPageReference(pageRef);
 //       ErrorPageController controller = new ErrorPageController ();
 //       controller.back();                          
 //   }
}