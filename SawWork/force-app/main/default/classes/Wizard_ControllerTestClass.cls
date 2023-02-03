/* ========================================================================
    Author: Sonia Sawhney
    Description: Test class for Wizard_Controller
    Created Date : 23/06/2014
    ======================================================================== */
@isTest
private class Wizard_ControllerTestClass 
{
    static testMethod void test()
    {
        Wizard_Controller wizcont = new Wizard_Controller();
        List<Wizards_Idea_URL__c> ideaURL = wizcont.getURLs();
        List<Wizards_Slider_Image__c> sliderImage = wizcont.getImages();
        wizcont.RefreshIdeaCount();
        System.assertNotEquals(ideaURL, NULL);
        System.assertNotEquals(sliderImage, NULL);
        System.assertNotEquals(wizcont.TotalIdeas, NULL);
    }

}