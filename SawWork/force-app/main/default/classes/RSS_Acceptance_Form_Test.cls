/*
 * CR: 3147531
 * Release: 16.5
 * Developer: Sharath Prasanna
 * Summary: Test class for RSS_Acceptance_Form_Controller
 */
@isTest(SeeAllData=false)
private class RSS_Acceptance_Form_Test
{
	@isTest
	static void AcceptanceFormTest()
	{
		//creating a ERSS_Acceptance_Form__c record
		ERSS_Acceptance_Form__c AcceptanceForm = new ERSS_Acceptance_Form__c();
		insert AcceptanceForm;		
        Test.startTest();

        //create a pagereference for AcceptanceForm and set the parameter ID to the form ID

        ApexPages.StandardController sc = new ApexPages.StandardController(new ERSS_Acceptance_Form__c());                               
        PageReference pageRef = Page.RSS_Acceptance_Form;
        pageRef.getParameters().put('id',AcceptanceForm.id);
        Test.setCurrentPage(pageRef);

        //Create a controller for the page with pagereference pageRef
        RSS_Acceptance_Form_Controller controller = new RSS_Acceptance_Form_Controller(sc);

		//covering the functions: stringToSelectOptionsList and  stringToListOFString        
        controller.stringToSelectOptionsList('1,2,3,4,5');
        controller.stringToListOFString('1,2,3,4,5');

        //set the AcceptanceForm variable	
        controller.AcceptanceForm = AcceptanceForm;
        
        //set the first response to NO
        controller.AcceptanceForm.Response1__c = 'NO';
        controller.CheckForNo();

        //set the first response to YES
        controller.AcceptanceForm.Response1__c = 'YES';
        controller.CheckForNo();       

        //save the form 
        controller.UpdateForm();                

        //set the first choice 
        controller.AcceptanceForm.Choices1__c = '1,2,3';
        List<SelectOption> testChoices = controller.Choices1;

        //set the second choice
        controller.AcceptanceForm.Choices2__c = '1,2,3';
        testChoices = controller.Choices2;
        controller.Choices2 = testChoices;
        
        //set the third choice
        controller.AcceptanceForm.Choices3__c = '1,2,3';
        testChoices = controller.Choices3;
        controller.Choices3 = testChoices;
        
        //set response2 and get CheckBoxValues2
        controller.AcceptanceForm.Response2__c = '1,2,3';      
        List<String> testResponses = controller.CheckBoxValues2;        

        //set response3 and get CheckBoxValues3
        controller.AcceptanceForm.Response3__c = '1,2,3';        
        testResponses = controller.CheckBoxValues3;
        
        //get the first response
        String response = controller.answer;
        
        //set the first response to NO and submit the form
        controller.AcceptanceForm.Response1__c = 'NO';
        controller.SubmitForm();
        
        //set the first response to YES and submit the form
        controller.AcceptanceForm.Response1__c = 'YES';
        controller.SubmitForm();
        
        //populate the RSS Form look-up and call the ReturnToForm function
        RSS_Form__c form = new RSS_Form__c();
        insert form;
        controller.AcceptanceForm.RSS_Form__c = form.id;         
        controller.ReturnToForm();
		
		Test.stopTest();		

	}
}